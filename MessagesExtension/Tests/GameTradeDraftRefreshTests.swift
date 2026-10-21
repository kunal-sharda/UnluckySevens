import XCTest
import ULS_CoreGame
@testable import MessagesExtensionSupport

final class GameTradeDraftRefreshTests: XCTestCase {
    func testCounterDraftIsDiscardedWhenOfferOrHandChanges() {
        let route = GameTradeOverlayRoute.playerDraft(.init(kind: .counter(originalProposerID: "A"),
                                                           give: .init(wood: 3), receive: .init(ore: 1), recipients: ["A"]))
        XCTAssertEqual(route.reconciled(hasTradePanel: true, hasOffer: true, draftContextChanged: true), .liveOffer)
        XCTAssertEqual(route.reconciled(hasTradePanel: true, hasOffer: false, draftContextChanged: true), .chooser)
        XCTAssertEqual(route.reconciled(hasTradePanel: true, hasOffer: true, draftContextChanged: false), route)
    }

    func testOfferDraftCannotRetainOldSelectedQuantitiesAfterStateChanges() {
        let route = GameTradeOverlayRoute.playerDraft(.init(kind: .offer, give: .init(wood: 3),
                                                           receive: .init(ore: 1), recipients: ["B"]))
        XCTAssertEqual(route.reconciled(hasTradePanel: true, hasOffer: false, draftContextChanged: true), .chooser)
        XCTAssertNil(route.reconciled(hasTradePanel: false, hasOffer: false, draftContextChanged: true))
        XCTAssertEqual(route.reconciled(hasTradePanel: true, hasOffer: false, draftContextChanged: false), route)
    }
}
