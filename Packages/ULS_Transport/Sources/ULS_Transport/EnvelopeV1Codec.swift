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
    case stateCompressed = 0x73 // s
    case intentCompressed = 0x69 // i

    init(kind: EnvelopeV1.Kind, compressed: Bool) {
        switch (kind, compressed) {
        case (.state, false):
            self = .state
        case (.intent, false):
            self = .intent
        case (.state, true):
            self = .stateCompressed
        case (.intent, true):
            self = .intentCompressed
        }
    }

    var kind: EnvelopeV1.Kind {
        switch self {
        case .state, .stateCompressed:
            return .state
        case .intent, .intentCompressed:
            return .intent
        }
    }

    var compressed: Bool {
        switch self {
        case .stateCompressed, .intentCompressed:
            return true
        case .state, .intent:
            return false
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

    let compressedPayloadData = bestCompressedPayload(from: payloadData)
    let useCompressedPayload = compressedPayloadData.count < payloadData.count
    let framedPayload = useCompressedPayload ? compressedPayloadData : payloadData

    var data = Data()
    data.append(UInt8(envelope.v))
    data.append(CompactEnvelopeKindCode(kind: envelope.kind, compressed: useCompressedPayload).rawValue)
    data.append(framedPayload)
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

    let framedPayloadData = data.dropFirst(2)
    let payloadData: Data
    if kindCode.compressed {
        payloadData = try decompressPayload(Data(framedPayloadData))
    } else {
        payloadData = Data(framedPayloadData)
    }

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

private func bestCompressedPayload(from data: Data) -> Data {
    guard data.count >= 256 else {
        return data
    }

    guard #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *) else {
        return data
    }

    let algorithms: [NSData.CompressionAlgorithm] = [.lzma, .lzfse, .zlib]

    return algorithms.reduce(data) { best, algorithm in
        guard
            let compressed = try? (data as NSData).compressed(using: algorithm) as Data,
            compressed.count < best.count
        else {
            return best
        }
        return compressed
    }
}

private func decompressPayload(_ data: Data) throws -> Data {
    guard #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *) else {
        throw TransportError.invalidJSON
    }

    let algorithms: [NSData.CompressionAlgorithm] = [.lzma, .lzfse, .zlib]

    for algorithm in algorithms {
        if let decompressed = try? (data as NSData).decompressed(using: algorithm) as Data {
            return decompressed
        }
    }

    throw TransportError.invalidJSON
}
