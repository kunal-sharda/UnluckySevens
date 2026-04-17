import Foundation

public func encode(_ envelope: EnvelopeV1) throws -> String {
    guard envelope.v == 1 else {
        throw TransportError.unsupportedVersion(envelope.v)
    }

    return base64URLEncode(try compactEnvelopeData(from: envelope))
}

public func decode(_ string: String) throws -> EnvelopeV1 {
    let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else {
        throw TransportError.emptyPayload
    }

    guard let data = base64URLDecode(trimmed) else {
        throw TransportError.invalidBase64URL
    }

    let envelope = try decodeEnvelope(from: data)

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

private enum CompactEnvelopeKindCode: UInt8 {
    case state = 0x53 // S
    case intent = 0x49 // I

    init(kind: EnvelopeV1.Kind) {
        switch kind {
        case .state:
            self = .state
        case .intent:
            self = .intent
        }
    }

    var kind: EnvelopeV1.Kind {
        switch self {
        case .state:
            return .state
        case .intent:
            return .intent
        }
    }
}

private func compactEnvelopeData(from envelope: EnvelopeV1) throws -> Data {
    let payload: String
    switch envelope.body {
    case let .state(payloadValue):
        payload = payloadValue
    case let .intent(payloadValue):
        payload = payloadValue
    }

    guard let payloadData = payload.data(using: .utf8) else {
        throw TransportError.invalidJSON
    }

    var data = Data()
    data.append(UInt8(envelope.v))
    data.append(CompactEnvelopeKindCode(kind: envelope.kind).rawValue)
    data.append(payloadData)
    return data
}

private func decodeEnvelope(from data: Data) throws -> EnvelopeV1 {
    if let firstByte = data.first, firstByte == 0x7B { // {
        do {
            return try JSONDecoder().decode(EnvelopeV1.self, from: data)
        } catch {
            throw TransportError.invalidJSON
        }
    }

    guard data.count >= 2 else {
        throw TransportError.invalidJSON
    }

    let version = Int(data[data.startIndex])
    guard let kindCode = CompactEnvelopeKindCode(rawValue: data[data.startIndex + 1]) else {
        throw TransportError.invalidJSON
    }

    let payloadData = data.dropFirst(2)
    guard let payload = String(data: payloadData, encoding: .utf8) else {
        throw TransportError.invalidJSON
    }

    let kind = kindCode.kind
    let body: EnvelopeV1.Body
    switch kind {
    case .state:
        body = .state(payload: payload)
    case .intent:
        body = .intent(payload: payload)
    }

    return EnvelopeV1(v: version, kind: kind, body: body)
}
