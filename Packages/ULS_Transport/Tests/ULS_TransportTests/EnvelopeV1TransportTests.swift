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

    func testTurnSubmitDiscardIntentPayloadRoundTrip() throws {
        let intent = TurnIntentV1(
            submitDiscardFor: "player-2",
            discarded: TransportResourceHandV1(wood: 2, sheep: 1),
            gameId: "game-123",
            anchorRev: 8,
            anchorHash: "hash-8",
            actor: "player-2"
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

    func testTurnMoveRobberIntentPayloadRoundTrip() throws {
        let intent = TurnIntentV1(
            moveRobberTileID: 11,
            gameId: "game-123",
            anchorRev: 9,
            anchorHash: "hash-9",
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

    func testTurnSubmitDiscardDecodeFailsWithoutRequiredFields() {
        let invalidJSON = """
        {"kind":"submitDiscard","gameId":"game-123","anchorRev":8,"anchorHash":"hash-8","actor":"player-2"}
        """

        XCTAssertThrowsError(try JSONDecoder().decode(TurnIntentV1.self, from: Data(invalidJSON.utf8)))
    }

    func testTurnMoveRobberDecodeFailsWithoutTile() {
        let invalidJSON = """
        {"kind":"moveRobber","gameId":"game-123","anchorRev":9,"anchorHash":"hash-9","actor":"player-1"}
        """

        XCTAssertThrowsError(try JSONDecoder().decode(TurnIntentV1.self, from: Data(invalidJSON.utf8)))
    }

    func testTurnSelectStealVictimIntentPayloadRoundTrip() throws {
        let intent = TurnIntentV1(
            selectStealVictimPlayer: "player-2",
            gameId: "game-123",
            anchorRev: 10,
            anchorHash: "hash-10",
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

    func testTurnSelectStealVictimDecodeFailsWithoutVictim() {
        let invalidJSON = """
        {"kind":"selectStealVictim","gameId":"game-123","anchorRev":10,"anchorHash":"hash-10","actor":"player-1"}
        """

        XCTAssertThrowsError(try JSONDecoder().decode(TurnIntentV1.self, from: Data(invalidJSON.utf8)))
    }

    func testTurnBuildRoadIntentPayloadRoundTrip() throws {
        let intent = TurnIntentV1(
            buildRoadEdgeID: 12,
            gameId: "game-123",
            anchorRev: 11,
            anchorHash: "hash-11",
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

    func testTurnBuildSettlementIntentPayloadRoundTrip() throws {
        let intent = TurnIntentV1(
            buildSettlementNodeID: 24,
            gameId: "game-123",
            anchorRev: 11,
            anchorHash: "hash-11",
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

    func testTurnBuildCityIntentPayloadRoundTrip() throws {
        let intent = TurnIntentV1(
            buildCityNodeID: 24,
            gameId: "game-123",
            anchorRev: 11,
            anchorHash: "hash-11",
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

    func testTurnBuildRoadDecodeFailsWithoutEdgeID() {
        let invalidJSON = """
        {"kind":"buildRoad","gameId":"game-123","anchorRev":11,"anchorHash":"hash-11","actor":"player-1"}
        """

        XCTAssertThrowsError(try JSONDecoder().decode(TurnIntentV1.self, from: Data(invalidJSON.utf8)))
    }

    func testTurnProposeTradeIntentPayloadRoundTrip() throws {
        let intent = TurnIntentV1(
            proposeTradeGive: TransportResourceHandV1(wood: 1),
            receive: TransportResourceHandV1(brick: 1),
            targetPlayers: ["player-2"],
            gameId: "game-123",
            anchorRev: 12,
            anchorHash: "hash-12",
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

    func testTurnAcceptTradeIntentPayloadRoundTrip() throws {
        let intent = TurnIntentV1(
            acceptTradePlayer: "player-2",
            offerHash: "offer-hash",
            gameId: "game-123",
            anchorRev: 12,
            anchorHash: "hash-12",
            actor: "player-2"
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

    func testTurnProposeTradeDecodeFailsWithoutTradeHands() {
        let invalidJSON = """
        {"kind":"proposeTrade","gameId":"game-123","anchorRev":12,"anchorHash":"hash-12","actor":"player-1","tradeTargetPlayers":["player-2"]}
        """

        XCTAssertThrowsError(try JSONDecoder().decode(TurnIntentV1.self, from: Data(invalidJSON.utf8)))
    }

    func testTurnAcceptTradeDecodeFailsWithoutOfferHash() {
        let invalidJSON = """
        {"kind":"acceptTrade","gameId":"game-123","anchorRev":12,"anchorHash":"hash-12","actor":"player-2","tradeAcceptPlayer":"player-2"}
        """

        XCTAssertThrowsError(try JSONDecoder().decode(TurnIntentV1.self, from: Data(invalidJSON.utf8)))
    }

    func testTurnExecuteTradeIntentPayloadRoundTrip() throws {
        let intent = TurnIntentV1(
            executeTradePlayer: "player-2",
            offerHash: "offer-hash",
            gameId: "game-123",
            anchorRev: 13,
            anchorHash: "hash-13",
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

    func testTurnExecuteTradeDecodeFailsWithoutOfferHash() {
        let invalidJSON = """
        {"kind":"executeTrade","gameId":"game-123","anchorRev":13,"anchorHash":"hash-13","actor":"player-1","tradeAcceptPlayer":"player-2"}
        """

        XCTAssertThrowsError(try JSONDecoder().decode(TurnIntentV1.self, from: Data(invalidJSON.utf8)))
    }

    func testTurnMaritimeTradeIntentPayloadRoundTrip() throws {
        let intent = TurnIntentV1(
            maritimeTradeGive: TransportResourceHandV1(wood: 3),
            receive: TransportResourceHandV1(brick: 1),
            gameId: "game-123",
            anchorRev: 13,
            anchorHash: "hash-13",
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

    func testTurnMaritimeTradeDecodeFailsWithoutTradeHands() {
        let invalidJSON = """
        {"kind":"maritimeTrade","gameId":"game-123","anchorRev":13,"anchorHash":"hash-13","actor":"player-1"}
        """

        XCTAssertThrowsError(try JSONDecoder().decode(TurnIntentV1.self, from: Data(invalidJSON.utf8)))
    }

    func testTurnBuyDevCardIntentPayloadRoundTrip() throws {
        let intent = TurnIntentV1(
            kind: .buyDevCard,
            gameId: "game-123",
            anchorRev: 14,
            anchorHash: "hash-14",
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

    func testTurnPlayDevCardIntentPayloadRoundTrip() throws {
        let intent = TurnIntentV1(
            playDevCardKind: .knight,
            tileID: 5,
            victimPlayer: "player-2",
            gameId: "game-123",
            anchorRev: 15,
            anchorHash: "hash-15",
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

    func testTurnPlayDevCardDecodeFailsWithoutKind() {
        let invalidJSON = """
        {"kind":"playDevCard","gameId":"game-123","anchorRev":15,"anchorHash":"hash-15","actor":"player-1","devCardTileID":5}
        """

        XCTAssertThrowsError(try JSONDecoder().decode(TurnIntentV1.self, from: Data(invalidJSON.utf8)))
    }

    func testTurnPlayDevCardMonopolyDecodeFailsWithoutResource() {
        let invalidJSON = """
        {"kind":"playDevCard","gameId":"game-123","anchorRev":15,"anchorHash":"hash-15","actor":"player-1","devCardPlayKind":"monopoly"}
        """

        XCTAssertThrowsError(try JSONDecoder().decode(TurnIntentV1.self, from: Data(invalidJSON.utf8)))
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
