import XCTest
@testable import ULS_Transport

final class ULS_TransportTests: XCTestCase {
    func testDebugPayloadRoundTrip() throws {
        let payload = DebugPayload(timestamp: 1_737_843_200, debugId: "00000000-0000-0000-0000-000000000000")

        let encoded = encodeDebugPayload(payload)
        let decoded = try decodeDebugPayload(from: encoded)

        XCTAssertEqual(decoded, payload)
    }

    func testInvalidBase64URLThrows() {
        XCTAssertThrowsError(try decodeDebugPayload(from: "%%%")) { error in
            guard let codecError = error as? DebugPayloadCodecError else {
                XCTFail("Unexpected error type: \(error)")
                return
            }

            switch codecError {
            case .invalidBase64URL:
                XCTAssertTrue(true)
            default:
                XCTFail("Expected invalidBase64URL, got \(codecError)")
            }
        }
    }

    func testEncodedPayloadSizeIsUnder2KB() {
        let payload = DebugPayload(timestamp: 1_737_843_200, debugId: UUID().uuidString)
        let encoded = encodeDebugPayload(payload)

        XCTAssertLessThan(encoded.utf8.count, 2048)
    }

    func testRoundTripThroughURLQueryItem() throws {
        let payload = DebugPayload(timestamp: 1_737_843_200, debugId: "11111111-1111-1111-1111-111111111111")
        let encoded = encodeDebugPayload(payload)

        var components = URLComponents()
        components.scheme = "https"
        components.host = "unluckysevens.app"
        components.path = "/msg"
        components.queryItems = [URLQueryItem(name: "payload", value: encoded)]

        let extractedPayload = components.queryItems?.first(where: { $0.name == "payload" })?.value
        XCTAssertNotNil(extractedPayload)

        let decoded = try decodeDebugPayload(from: extractedPayload!)
        XCTAssertEqual(decoded, payload)
    }

    func testUnsupportedPayloadVersionThrows() throws {
        let unsupportedPayload = DebugPayload(type: "debug", v: 2, timestamp: 1_737_843_200, debugId: "22222222-2222-2222-2222-222222222222")
        let data = try JSONEncoder().encode(unsupportedPayload)
        let encoded = data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")

        XCTAssertThrowsError(try decodeDebugPayload(from: encoded)) { error in
            guard let codecError = error as? DebugPayloadCodecError else {
                XCTFail("Unexpected error type: \(error)")
                return
            }

            switch codecError {
            case .unsupportedPayload:
                XCTAssertTrue(true)
            default:
                XCTFail("Expected unsupportedPayload, got \(codecError)")
            }
        }
    }

    func testLegacyNonceFieldStillDecodes() throws {
        let legacyJSON = #"{"type":"debug","v":1,"timestamp":1737843200,"nonce":"33333333-3333-3333-3333-333333333333"}"#
        let data = Data(legacyJSON.utf8)
        let encoded = data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")

        let payload = try decodeDebugPayload(from: encoded)
        XCTAssertEqual(payload.debugId, "33333333-3333-3333-3333-333333333333")
    }
}
