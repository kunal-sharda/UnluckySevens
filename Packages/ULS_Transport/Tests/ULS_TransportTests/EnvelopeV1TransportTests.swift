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

    func testJoinIntentPayloadRoundTrip() throws {
        let intent = JoinIntentV1(
            gameId: "game-123",
            anchorRev: 0,
            anchorHash: "abc123",
            actor: "player-1"
        )
        let intentPayload = try jsonString(intent)
        let envelope = EnvelopeV1(
            kind: .intent,
            body: .intent(payload: intentPayload)
        )

        let encoded = try encode(envelope)
        let decoded = try decode(encoded)

        guard case let .intent(payload) = decoded.body else {
            XCTFail("Expected INTENT body.")
            return
        }

        let decodedIntent = try JSONDecoder().decode(JoinIntentV1.self, from: Data(payload.utf8))
        XCTAssertEqual(decodedIntent, intent)
    }

    func testSetupSettlementIntentPayloadRoundTrip() throws {
        let intent = SetupPlacementIntentV1(
            gameId: "game-123",
            anchorRev: 1,
            anchorHash: "hash-1",
            actor: "player-1",
            node: 0
        )
        let payload = try jsonString(intent)
        let envelope = EnvelopeV1(kind: .intent, body: .intent(payload: payload))

        let encoded = try encode(envelope)
        let decoded = try decode(encoded)

        guard case let .intent(decodedPayload) = decoded.body else {
            XCTFail("Expected INTENT body.")
            return
        }

        let decodedIntent = try JSONDecoder().decode(SetupPlacementIntentV1.self, from: Data(decodedPayload.utf8))
        XCTAssertEqual(decodedIntent, intent)
    }

    func testSetupRoadIntentPayloadRoundTrip() throws {
        let intent = SetupPlacementIntentV1(
            gameId: "game-123",
            anchorRev: 1,
            anchorHash: "hash-1",
            actor: "player-1",
            edge: 0
        )
        let payload = try jsonString(intent)
        let envelope = EnvelopeV1(kind: .intent, body: .intent(payload: payload))

        let encoded = try encode(envelope)
        let decoded = try decode(encoded)

        guard case let .intent(decodedPayload) = decoded.body else {
            XCTFail("Expected INTENT body.")
            return
        }

        let decodedIntent = try JSONDecoder().decode(SetupPlacementIntentV1.self, from: Data(decodedPayload.utf8))
        XCTAssertEqual(decodedIntent, intent)
    }

    func testSetupPairIntentPayloadRoundTrip() throws {
        let intent = SetupPlacementIntentV1(
            gameId: "game-123",
            anchorRev: 1,
            anchorHash: "hash-1",
            actor: "player-1",
            settlementNode: 6,
            roadEdge: 12
        )
        let payload = try jsonString(intent)
        let envelope = EnvelopeV1(kind: .intent, body: .intent(payload: payload))

        let encoded = try encode(envelope)
        let decoded = try decode(encoded)

        guard case let .intent(decodedPayload) = decoded.body else {
            XCTFail("Expected INTENT body.")
            return
        }

        let decodedIntent = try JSONDecoder().decode(SetupPlacementIntentV1.self, from: Data(decodedPayload.utf8))
        XCTAssertEqual(decodedIntent, intent)
    }

    func testTurnRollDiceIntentPayloadRoundTrip() throws {
        let intent = TurnIntentV1(
            kind: .rollDice,
            gameId: "game-123",
            anchorRev: 7,
            anchorHash: "hash-7",
            actor: "player-1"
        )
        let payload = try jsonString(intent)
        let envelope = EnvelopeV1(kind: .intent, body: .intent(payload: payload))

        let encoded = try encode(envelope)
        let decoded = try decode(encoded)

        guard case let .intent(decodedPayload) = decoded.body else {
            XCTFail("Expected INTENT body.")
            return
        }

        let decodedIntent = try JSONDecoder().decode(TurnIntentV1.self, from: Data(decodedPayload.utf8))
        XCTAssertEqual(decodedIntent, intent)
    }

    func testTurnEndTurnIntentPayloadRoundTrip() throws {
        let intent = TurnIntentV1(
            kind: .endTurn,
            gameId: "game-123",
            anchorRev: 8,
            anchorHash: "hash-8",
            actor: "player-1"
        )
        let payload = try jsonString(intent)
        let envelope = EnvelopeV1(kind: .intent, body: .intent(payload: payload))

        let encoded = try encode(envelope)
        let decoded = try decode(encoded)

        guard case let .intent(decodedPayload) = decoded.body else {
            XCTFail("Expected INTENT body.")
            return
        }

        let decodedIntent = try JSONDecoder().decode(TurnIntentV1.self, from: Data(decodedPayload.utf8))
        XCTAssertEqual(decodedIntent, intent)
    }

    func testSetupIntentDecodeFailsWhenKindAndPayloadDoNotMatch() throws {
        let invalidIntentJSON = """
        {"kind":"placeSetupSettlement","gameId":"game-123","anchorRev":1,"anchorHash":"hash-1","actor":"player-1"}
        """
        let envelope = EnvelopeV1(kind: .intent, body: .intent(payload: invalidIntentJSON))

        let encoded = try encode(envelope)
        let decoded = try decode(encoded)

        guard case let .intent(payload) = decoded.body else {
            XCTFail("Expected INTENT body.")
            return
        }

        XCTAssertThrowsError(try JSONDecoder().decode(SetupPlacementIntentV1.self, from: Data(payload.utf8)))
    }

    func testSetupPairIntentDecodeFailsWhenNodeOrEdgeMissing() throws {
        let invalidPairJSON = """
        {"kind":"placeSetupPair","gameId":"game-123","anchorRev":1,"anchorHash":"hash-1","actor":"player-1","node":6}
        """
        let envelope = EnvelopeV1(kind: .intent, body: .intent(payload: invalidPairJSON))

        let encoded = try encode(envelope)
        let decoded = try decode(encoded)

        guard case let .intent(payload) = decoded.body else {
            XCTFail("Expected INTENT body.")
            return
        }

        XCTAssertThrowsError(try JSONDecoder().decode(SetupPlacementIntentV1.self, from: Data(payload.utf8)))
    }

    private func jsonString<T: Encodable>(_ value: T) throws -> String {
        let data = try JSONEncoder().encode(value)
        guard let json = String(data: data, encoding: .utf8) else {
            XCTFail("Expected UTF-8 JSON payload.")
            throw TransportError.invalidJSON
        }
        return json
    }
}
