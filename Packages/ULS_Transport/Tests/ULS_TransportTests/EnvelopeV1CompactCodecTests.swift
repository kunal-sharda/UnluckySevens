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
}
