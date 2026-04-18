import ULS_Transport
import XCTest
@testable import MessagesExtension

final class TurnIntentTransportRoleResolverTests: XCTestCase {
    func testDiscardIntentIsResponderMessage() {
        let intent = ULS_Transport.TurnIntentV1(
            submitDiscardFor: "guest",
            discarded: TransportResourceHandV1(wood: 2),
            gameId: "game-1",
            anchorRev: 3,
            anchorHash: "hash-3",
            actor: "guest"
        )

        XCTAssertEqual(
            TurnIntentTransportRoleResolver.resolve(intent),
            .responderMessage(.discardResponse)
        )
    }

    func testTradeResponseIntentIsResponderMessage() {
        let intent = ULS_Transport.TurnIntentV1(
            acceptTradePlayer: "guest",
            offerHash: "offer-1",
            gameId: "game-1",
            anchorRev: 3,
            anchorHash: "hash-3",
            actor: "guest"
        )

        XCTAssertEqual(
            TurnIntentTransportRoleResolver.resolve(intent),
            .responderMessage(.tradeResponse)
        )
    }

    func testCurrentPlayerTurnIntentIsLegacyTransportOnly() {
        let intent = ULS_Transport.TurnIntentV1(
            kind: .rollDice,
            gameId: "game-1",
            anchorRev: 3,
            anchorHash: "hash-3",
            actor: "host"
        )

        XCTAssertEqual(
            TurnIntentTransportRoleResolver.resolve(intent),
            .legacyIntent
        )
    }
}
