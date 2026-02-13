//
//  SSHTunnelManager.swift
//  OpenCodeClient
//

import Foundation
import Combine
import Citadel
import NIOCore
import Crypto
import NIOSSH
import Network

enum SSHConnectionStatus: Equatable {
    case disconnected
    case connecting
    case connected
    case error(String)
    
    static func == (lhs: SSHConnectionStatus, rhs: SSHConnectionStatus) -> Bool {
        switch (lhs, rhs) {
        case (.disconnected, .disconnected),
             (.connecting, .connecting),
             (.connected, .connected):
            return true
        case (.error(let a), .error(let b)):
            return a == b
        default:
            return false
        }
    }
}

struct SSHTunnelConfig: Codable, Equatable {
    var isEnabled: Bool = false
    var host: String = ""
    var port: Int = 22
    var username: String = ""
    var remotePort: Int = 18080
    
    var isValid: Bool {
        !host.isEmpty && !username.isEmpty && port > 0 && remotePort > 0
    }
    
    static let `default` = SSHTunnelConfig()
}

@MainActor
final class SSHTunnelManager: ObservableObject {
    @Published private(set) var status: SSHConnectionStatus = .disconnected
    @Published var config: SSHTunnelConfig {
        didSet { saveConfig() }
    }
    
    private var sshClient: SSHClient?
    private var listener: NWListener?
    private var tunnelTask: Task<Void, Never>?
    private let localPort: NWEndpoint.Port = 4096
    
    init() {
        if let data = UserDefaults.standard.data(forKey: "sshTunnelConfig"),
           let decoded = try? JSONDecoder().decode(SSHTunnelConfig.self, from: data) {
            self.config = decoded
        } else {
            self.config = .default
        }
    }
    
    private func saveConfig() {
        guard let data = try? JSONEncoder().encode(config) else { return }
        UserDefaults.standard.set(data, forKey: "sshTunnelConfig")
    }
    
    func connect() async {
        guard config.isValid else {
            status = .error("Invalid configuration")
            return
        }

        // Ensure key pair exists (first run auto-generates).
        _ = try? SSHKeyManager.ensureKeyPair()

        guard let privateKeyData = SSHKeyManager.loadPrivateKey() else {
            status = .error("No SSH key found. Please generate a key pair first.")
            return
        }
        
        status = .connecting
        
        do {
            try await establishTunnel(privateKeyData: privateKeyData)
            status = .connected
        } catch {
            disconnect()
            status = .error(error.localizedDescription)
        }
    }
    
    private func establishTunnel(privateKeyData: Data) async throws {
        #if DEBUG
        print("[SSH] Connecting to \(config.host):\(config.port) as \(config.username)")
        print("[SSH] Remote port: \(config.remotePort)")
        #endif
        
        guard let privateKey = try? Curve25519.Signing.PrivateKey(rawRepresentation: privateKeyData) else {
            throw SSHError.invalidKeyFormat
        }
        
        let username = config.username
        let settings = SSHClientSettings(
            host: config.host,
            port: config.port,
            authenticationMethod: { .ed25519(username: username, privateKey: privateKey) },
            hostKeyValidator: .acceptAnything()
        )
        
        let client = try await SSHClient.connect(to: settings)
        self.sshClient = client
        
        #if DEBUG
        print("[SSH] Connected successfully")
        #endif
        
        try startLocalListener(sshClient: client)
    }

    private func startLocalListener(sshClient: SSHClient) throws {
        if let listener {
            listener.cancel()
            self.listener = nil
        }

        let params = NWParameters.tcp
        params.allowLocalEndpointReuse = true
        params.requiredInterfaceType = .loopback

        let listener = try NWListener(using: params, on: localPort)
        self.listener = listener

        let queue = DispatchQueue(label: "com.opencode.ssh.tunnel.listener")
        listener.stateUpdateHandler = { [weak self] newState in
            guard let self else { return }
            switch newState {
            case .failed(let err):
                Task { @MainActor in
                    self.status = .error("Local listener failed: \(err.localizedDescription)")
                    self.disconnect()
                }
            default:
                break
            }
        }

        listener.newConnectionHandler = { [weak self] conn in
            guard let self else { return }
            Task { @MainActor in
                self.handleLocalConnection(conn, sshClient: sshClient)
            }
        }

        listener.start(queue: queue)
    }

    nonisolated private func handleLocalConnection(_ conn: NWConnection, sshClient: SSHClient) {
        let queue = DispatchQueue(label: "com.opencode.ssh.tunnel.conn")
        conn.stateUpdateHandler = { state in
            switch state {
            case .failed:
                conn.cancel()
            default:
                break
            }
        }
        conn.start(queue: queue)

        Task.detached { [weak self] in
            do {
                let originator = try SocketAddress(ipAddress: "127.0.0.1", port: Int(self?.localPort.rawValue ?? 4096))
                let targetPort = await MainActor.run { self?.config.remotePort ?? 18080 }

                let channel = try await sshClient.createDirectTCPIPChannel(
                    using: SSHChannelType.DirectTCPIP(
                        targetHost: "127.0.0.1",
                        targetPort: targetPort,
                        originatorAddress: originator
                    )
                ) { channel in
                    channel.pipeline.addHandler(NIOToNWConnectionHandler(nwConnection: conn))
                }

                self?.startReceiveLoop(from: conn, to: channel)
            } catch {
                conn.cancel()
                await MainActor.run {
                    if self?.status == .connected {
                        self?.status = .error(error.localizedDescription)
                    }
                }
            }
        }
    }

    nonisolated private func startReceiveLoop(from conn: NWConnection, to channel: Channel) {
        conn.receive(minimumIncompleteLength: 1, maximumLength: 16 * 1024) { data, _, isComplete, error in
            if let data, !data.isEmpty {
                channel.eventLoop.execute {
                    var buffer = channel.allocator.buffer(capacity: data.count)
                    buffer.writeBytes(data)
                    channel.writeAndFlush(buffer, promise: nil)
                }
            }

            if isComplete || error != nil {
                channel.close(promise: nil)
                conn.cancel()
                return
            }

            self.startReceiveLoop(from: conn, to: channel)
        }
    }
    
    func disconnect() {
        tunnelTask?.cancel()
        tunnelTask = nil

        listener?.cancel()
        listener = nil
        
        if let client = sshClient {
            Task {
                try? await client.close()
            }
        }
        sshClient = nil
        
        status = .disconnected
    }
    
    func getPublicKey() -> String? {
        SSHKeyManager.getPublicKey()
    }
    
    func generateOrGetPublicKey() throws -> String {
        try SSHKeyManager.ensureKeyPair()
    }
    
    func rotateKey() throws -> String {
        try SSHKeyManager.rotateKey()
    }
}

private final class NIOToNWConnectionHandler: ChannelInboundHandler {
    typealias InboundIn = ByteBuffer

    private let nwConnection: NWConnection

    init(nwConnection: NWConnection) {
        self.nwConnection = nwConnection
    }

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        var buffer = unwrapInboundIn(data)
        let bytes = buffer.readBytes(length: buffer.readableBytes) ?? []
        guard !bytes.isEmpty else { return }

        nwConnection.send(content: Data(bytes), completion: .contentProcessed { error in
            if let error {
                #if DEBUG
                print("[SSH Tunnel] send failed: \(error)")
                #endif
                context.close(promise: nil)
            }
        })
    }

    func errorCaught(context: ChannelHandlerContext, error: Error) {
        #if DEBUG
        print("[SSH Tunnel] channel error: \(error)")
        #endif
        context.close(promise: nil)
        nwConnection.cancel()
    }
}

enum SSHError: LocalizedError {
    case connectionFailed(String)
    case authenticationFailed
    case keyNotFound
    case invalidKeyFormat
    case tunnelFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .connectionFailed(let reason):
            return "Connection failed: \(reason)"
        case .authenticationFailed:
            return "Authentication failed. Please check your public key is added to the server."
        case .keyNotFound:
            return "SSH key not found. Please generate a key pair first."
        case .invalidKeyFormat:
            return "Invalid SSH key format."
        case .tunnelFailed(let reason):
            return "Tunnel failed: \(reason)"
        }
    }
}
