import XCTest
@testable import ULS_Transport

final class EnvelopeV1CompactCodecTests: XCTestCase {
    func testDecodeSupportsLegacyJSONEnvelopeEncoding() throws {
        let envelope = EnvelopeV1(
            kind: .intent,
            body: .intent(payload: #"{"kind":"join","gameId":"game-1","anchorRev":0,"anchorHash":"hash-0","actor":"player-a"}"#)
        )

        let legacyData = try JSONEncoder().encode(envelope)
        let legacyEncoded = base64URLEncode(legacyData)
        let decoded = try decode(legacyEncoded)

        XCTAssertEqual(decoded, envelope)
    }

    func testCompactEncodingIsSmallerThanLegacyJSONEncoding() throws {
        let payload = String(repeating: #"{"gameId":"game-1","anchorRev":17,"anchorHash":"hash-17","actor":"player-a","kind":"acceptTrade","tradeOfferHash":"offer-1"}"#, count: 3)
        let envelope = EnvelopeV1(kind: .intent, body: .intent(payload: payload))

        let compactEncoded = try encode(envelope)
        let legacyEncoded = base64URLEncode(try JSONEncoder().encode(envelope))

        XCTAssertLessThan(compactEncoded.count, legacyEncoded.count)
    }

    func testLargePayloadUsesCompressedCompactEncoding() throws {
        let payload = String(
            repeating: #"{"gameId":"game-1","rev":91,"phase":"turn","currentPlayer":"player-a","audit":["roll","trade","build","endTurn"]}"#,
            count: 24
        )
        let envelope = EnvelopeV1(kind: .state, body: .state(payload: payload))

        let encoded = try encode(envelope)
        let decoded = try decode(encoded)

        let baselineCompact = try uncompressedCompactEncoding(of: envelope)

        XCTAssertEqual(decoded, envelope)
        XCTAssertLessThan(encoded.count, baselineCompact.count)
    }

    private func uncompressedCompactEncoding(of envelope: EnvelopeV1) throws -> String {
        let payload: String
        switch envelope.body {
        case let .state(value), let .intent(value):
            payload = value
        }

        guard let payloadData = payload.data(using: .utf8) else {
            throw TransportError.invalidJSON
        }

        var data = Data()
        data.append(UInt8(envelope.v))
        data.append(envelope.kind == .state ? 0x53 : 0x49)
        data.append(payloadData)
        return base64URLEncode(data)
    }
}
