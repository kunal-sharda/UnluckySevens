import Foundation

public func encode(_ envelope: EnvelopeV1) throws -> String {
    guard envelope.v == 1 else {
        throw TransportError.unsupportedVersion(envelope.v)
    }

    let data = try JSONEncoder().encode(envelope)
    return base64URLEncode(data)
}

public func decode(_ string: String) throws -> EnvelopeV1 {
    let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else {
        throw TransportError.emptyPayload
    }

    guard let data = base64URLDecode(trimmed) else {
        throw TransportError.invalidBase64URL
    }

    let envelope: EnvelopeV1
    do {
        envelope = try JSONDecoder().decode(EnvelopeV1.self, from: data)
    } catch {
        throw TransportError.invalidJSON
    }

    guard envelope.v == 1 else {
        throw TransportError.unsupportedVersion(envelope.v)
    }

    guard envelope.kind == envelope.body.kind else {
        throw TransportError.invalidJSON
    }

    return envelope
}

public func encodedStringLength(of envelope: EnvelopeV1) throws -> Int {
    try encode(envelope).count
}

public func encodedByteCount(of envelope: EnvelopeV1) throws -> Int {
    try encode(envelope).utf8.count
}
