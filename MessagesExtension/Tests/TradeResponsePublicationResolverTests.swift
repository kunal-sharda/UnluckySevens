import ULS_CoreGame
import XCTest
@testable import MessagesExtension

final class TradeResponsePublicationResolverTests: XCTestCase {
    func testAcceptTradePublishesCanonicalState() {
        let intent = TurnIntentV1.acceptTrade(acceptingPlayer: "guest", offerHash: "offer-1")

        XCTAssertEqual(
            TradeResponsePublicationResolver.resolve(intent),
            .canonicalState
        )
    }

    func testDeclineAndCounterPublishCanonicalState() {
        let declineIntent = TurnIntentV1.declineTrade(decliningPlayer: "guest", offerHash: "offer-1")
        let counterIntent = TurnIntentV1.counterTrade(
            counteringPlayer: "guest",
            offerHash: "offer-1",
            give: ResourceHandV1(brick: 1),
            receive: ResourceHandV1(ore: 1)
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
        let intent = TurnIntentV1.rollDice

        XCTAssertNil(TradeResponsePublicationResolver.resolve(intent))
    }
}
