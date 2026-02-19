import Foundation

public struct DebugPayload: Codable, Equatable {
    public let type: String
    public let v: Int
    public let timestamp: Int
    public let debugId: String

    public init(type: String = "debug", v: Int = 1, timestamp: Int, debugId: String) {
        self.type = type
        self.v = v
        self.timestamp = timestamp
        self.debugId = debugId
    }

    private enum CodingKeys: String, CodingKey {
        case type
        case v
        case timestamp
        case debugId
        case nonce
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(String.self, forKey: .type)
        v = try container.decode(Int.self, forKey: .v)
        timestamp = try container.decode(Int.self, forKey: .timestamp)

        if let debugId = try container.decodeIfPresent(String.self, forKey: .debugId) {
            self.debugId = debugId
        } else {
            self.debugId = try container.decode(String.self, forKey: .nonce)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(v, forKey: .v)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(debugId, forKey: .debugId)
    }
}

public enum DebugPayloadCodecError: Error {
    case invalidBase64URL
    case invalidUTF8
    case jsonDecodingFailed
    case unsupportedPayload
}

extension DebugPayloadCodecError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidBase64URL:
            return "Payload was not valid base64url data."
        case .invalidUTF8:
            return "Payload data was not valid UTF-8 text."
        case .jsonDecodingFailed:
            return "Payload JSON was invalid."
        case .unsupportedPayload:
            return "Payload type or version is unsupported."
        }
    }
}

public func encodeDebugPayload(_ payload: DebugPayload) -> String {
    let encoder = JSONEncoder()
    guard let data = try? encoder.encode(payload) else {
        return ""
    }
    return base64URLEncode(data)
}

public func decodeDebugPayload(from base64url: String) throws -> DebugPayload {
    guard let decodedData = base64URLDecode(base64url) else {
        throw DebugPayloadCodecError.invalidBase64URL
    }

    guard String(data: decodedData, encoding: .utf8) != nil else {
        throw DebugPayloadCodecError.invalidUTF8
    }

    do {
        let payload = try JSONDecoder().decode(DebugPayload.self, from: decodedData)
        guard payload.type == "debug", payload.v == 1 else {
            throw DebugPayloadCodecError.unsupportedPayload
        }
        return payload
    } catch {
        if let codecError = error as? DebugPayloadCodecError {
            throw codecError
        }
        throw DebugPayloadCodecError.jsonDecodingFailed
    }
}
