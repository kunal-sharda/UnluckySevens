import ULS_Transport
import XCTest
@testable import MessagesExtension

final class TradeResponsePublicationResolverTests: XCTestCase {
    func testAcceptTradePublishesCanonicalState() {
        let intent = ULS_Transport.TurnIntentV1(
            acceptTradePlayer: "guest",
            offerHash: "offer-1",
            gameId: "game-1",
            anchorRev: 3,
            anchorHash: "hash-3",
            actor: "guest"
        )

        XCTAssertEqual(
            TradeResponsePublicationResolver.resolve(intent),
            .canonicalState
        )
    }

    func testDeclineAndCounterPublishCanonicalState() {
        let declineIntent = ULS_Transport.TurnIntentV1(
            declineTradePlayer: "guest",
            offerHash: "offer-1",
            gameId: "game-1",
            anchorRev: 3,
            anchorHash: "hash-3",
            actor: "guest"
        )
        let counterIntent = ULS_Transport.TurnIntentV1(
            counterTradePlayer: "guest",
            offerHash: "offer-1",
            counterGive: TransportResourceHandV1(brick: 1),
            receive: TransportResourceHandV1(ore: 1),
            gameId: "game-1",
            anchorRev: 3,
            anchorHash: "hash-3",
            actor: "guest"
        )

        XCTAssertEqual(
            TradeResponsePublicationResolver.resolve(declineIntent),
            .canonicalState
        )
        XCTAssertEqual(
            TradeResponsePublicationResolver.resolve(counterIntent),
            .canonicalState
        )
    }

    func testNonTradeIntentHasNoTradePublicationMode() {
        let intent = ULS_Transport.TurnIntentV1(
            kind: .rollDice,
            gameId: "game-1",
            anchorRev: 3,
            anchorHash: "hash-3",
            actor: "host"
        )

        XCTAssertNil(TradeResponsePublicationResolver.resolve(intent))
    }
}
