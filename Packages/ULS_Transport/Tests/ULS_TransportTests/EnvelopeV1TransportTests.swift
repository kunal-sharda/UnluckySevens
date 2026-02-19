import XCTest
@testable import ULS_Transport

final class EnvelopeV1TransportTests: XCTestCase {
    func testStateEnvelopeRoundTrip() throws {
        let envelope = EnvelopeV1(
            kind: .state,
            body: .state(payload: #"{"gameId":"g-1","rev":1}"#)
        )

        let encoded = try encode(envelope)
        let decoded = try decode(encoded)

        XCTAssertEqual(decoded, envelope)
    }

    func testIntentEnvelopeRoundTrip() throws {
        let envelope = EnvelopeV1(
            kind: .intent,
            body: .intent(payload: #"{"action":"acceptTrade","offerId":"o-1"}"#)
        )

        let encoded = try encode(envelope)
        let decoded = try decode(encoded)

        XCTAssertEqual(decoded, envelope)
    }

    func testDecodeBadBase64URLThrowsTransportError() {
        XCTAssertThrowsError(try decode("%%%")) { error in
            XCTAssertEqual(error as? TransportError, .invalidBase64URL)
        }
    }

    func testDecodeBadJSONThrowsTransportError() {
        let invalidJSONData = Data("not-json".utf8)
        let encoded = base64URLEncode(invalidJSONData)

        XCTAssertThrowsError(try decode(encoded)) { error in
            XCTAssertEqual(error as? TransportError, .invalidJSON)
        }
    }

    func testDecodeUnsupportedVersionThrowsTransportError() throws {
        let unsupported = EnvelopeV1(v: 2, kind: .state, body: .state(payload: "{}"))
        let unsupportedData = try JSONEncoder().encode(unsupported)
        let encoded = base64URLEncode(unsupportedData)

        XCTAssertThrowsError(try decode(encoded)) { error in
            XCTAssertEqual(error as? TransportError, .unsupportedVersion(2))
        }
    }

    func testEncodedSizeSanity() throws {
        let envelope = EnvelopeV1(
            kind: .state,
            body: .state(payload: String(repeating: "x", count: 128))
        )

        let length = try encodedStringLength(of: envelope)
        let bytes = try encodedByteCount(of: envelope)

        XCTAssertGreaterThan(length, 0)
        XCTAssertGreaterThan(bytes, 0)
        XCTAssertEqual(length, bytes)
        XCTAssertLessThan(bytes, 2048)
    }
}
