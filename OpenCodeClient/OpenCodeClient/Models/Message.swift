//
//  Message.swift
//  OpenCodeClient
//

import Foundation

struct Message: Codable, Identifiable {
    let id: String
    let sessionID: String
    let role: String
    let parentID: String?
    let model: ModelInfo?
    let time: TimeInfo
    let finish: String?

    struct ModelInfo: Codable {
        let providerID: String
        let modelID: String
    }

    struct TimeInfo: Codable {
        let created: Int
        let completed: Int?
    }

    var isUser: Bool { role == "user" }
    var isAssistant: Bool { role == "assistant" }
}

struct MessageWithParts: Codable {
    let info: Message
    let parts: [Part]
}

/// Part.state can be String (simple) or object (ToolState with status/title/etc)
struct PartStateBridge: Codable {
    let displayString: String

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let str = try? container.decode(String.self) {
            displayString = str
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            if let status = dict["status"]?.value as? String {
                displayString = status
            } else if let title = dict["title"]?.value as? String {
                displayString = title
            } else {
                displayString = "…"
            }
        } else {
            throw DecodingError.typeMismatch(PartStateBridge.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Part.state must be String or object"))
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(displayString)
    }
}

struct Part: Codable, Identifiable {
    let id: String
    let messageID: String
    let sessionID: String
    let type: String
    let text: String?
    let tool: String?
    let callID: String?
    let state: PartStateBridge?
    let metadata: PartMetadata?
    let files: [FileChange]?

    /// For UI display; handles both string and object state
    var stateDisplay: String? { state?.displayString }

    struct FileChange: Codable {
        let path: String
        let additions: Int
        let deletions: Int
        let status: String?
    }

    struct PartMetadata: Codable {
        let path: String?
        let title: String?
        let input: String?
    }

    var isText: Bool { type == "text" }
    var isReasoning: Bool { type == "reasoning" }
    var isTool: Bool { type == "tool" }
    var isPatch: Bool { type == "patch" }
}
