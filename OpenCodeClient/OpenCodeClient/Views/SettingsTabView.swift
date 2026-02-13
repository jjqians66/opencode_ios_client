//
//  SettingsTabView.swift
//  OpenCodeClient
//

import SwiftUI

struct SettingsTabView: View {
    @Bindable var state: AppState

    var body: some View {
        NavigationStack {
            Form {
                Section("Server Connection") {
                    let info = AppState.serverURLInfo(state.serverURL)

                    TextField("Address", text: $state.serverURL)
                        .textContentType(.URL)
                        .autocapitalization(.none)

                    TextField("Username", text: $state.username)
                        .textContentType(.username)
                        .autocapitalization(.none)

                    SecureField("Password", text: $state.password)
                        .textContentType(.password)

                    if let scheme = info.scheme {
                        HStack(spacing: 4) {
                            LabeledContent("Scheme", value: scheme.uppercased())
                                .foregroundStyle(scheme == "http" ? .orange : .secondary)
                            if scheme == "http" {
                                Image(systemName: "info.circle.fill")
                                    .foregroundStyle(.orange)
                                    .help("Use HTTPS for any non-LAN address. HTTP is insecure.")
                            }
                        }
                    }

                    if info.isLocal {
                        Text("LAN: HTTP allowed (recommended only on trusted networks)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("WAN: HTTPS required (HTTP will be blocked)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if info.scheme == "http" {
                        Text("Warning: HTTP is insecure. Use HTTPS for any non-LAN address.")
                            .font(.caption)
                            .foregroundStyle(info.isLocal ? .orange : .red)
                    }

                    HStack {
                        Text("Status")
                        Spacer()
                        if state.isConnected {
                            Label("Connected", systemImage: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        } else {
                            Label("Disconnected", systemImage: "xmark.circle.fill")
                                .foregroundStyle(.red)
                        }
                    }

                    if let error = state.connectionError {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }

                    Button("Test Connection") {
                        Task { await state.testConnection() }
                    }
                }

                Section("Appearance") {
                    Picker("Theme", selection: $state.themePreference) {
                        Text("Auto").tag("auto")
                        Text("Light").tag("light")
                        Text("Dark").tag("dark")
                    }
                }

                Section("Speech Recognition") {
                    TextField("AI Builder Base URL", text: $state.aiBuilderBaseURL)
                        .textContentType(.URL)
                        .autocapitalization(.none)

                    SecureField("AI Builder Token", text: $state.aiBuilderToken)
                        .textContentType(.password)

                    Text("Token is stored in Keychain and not committed to git.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Section("About") {
                    if let version = state.serverVersion {
                        LabeledContent("Server Version", value: version)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}
