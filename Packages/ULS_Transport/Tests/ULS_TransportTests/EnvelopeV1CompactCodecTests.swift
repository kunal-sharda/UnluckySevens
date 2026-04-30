import XCTest
@testable import ULS_Transport

final class EnvelopeV1CompactCodecTests: XCTestCase {
    func testDecodeRejectsJSONEnvelopeEncoding() throws {
        let envelope = EnvelopeV1(
            kind: .state,
            body: .state(payload: #"{"gameId":"game-1","rev":0}"#)
        )

        let jsonData = try JSONEncoder().encode(envelope)
        let jsonEncoded = base64URLEncode(jsonData)

        XCTAssertThrowsError(try decode(jsonEncoded))
    }

    func testCompactEncodingIsSmallerThanJSONEncoding() throws {
        let payload = String(repeating: #"{"gameId":"game-1","rev":17,"phase":"turn","currentPlayer":"player-a","stateHash":"hash-17"}"#, count: 3)
        let envelope = EnvelopeV1(kind: .state, body: .state(payload: payload))

        let compactEncoded = try encode(envelope)
        let jsonEncoded = base64URLEncode(try JSONEncoder().encode(envelope))

        XCTAssertLessThan(compactEncoded.count, jsonEncoded.count)
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
        case let .state(value):
            payload = value
        }

        guard let payloadData = payload.data(using: .utf8) else {
            throw TransportError.invalidJSON
        }

        var data = Data()
        data.append(UInt8(envelope.v))
        data.append(0x53)
        data.append(payloadData)
        return base64URLEncode(data)
    }
}
