import XCTest
@testable import MessagesExtensionSupport

final class TranscriptDidReceiveContractTests: XCTestCase {
    func testDidReceiveAppliesWhenNoActiveGameExists() {
        XCTAssertEqual(
            TranscriptDidReceiveContract.disposition(
                trigger: .didReceive,
                incomingGameId: "game-2",
                currentGameId: nil
            ),
            .applyToActiveContext
        )
    }

    func testDidReceiveAppliesWhenIncomingMessageMatchesActiveGame() {
        XCTAssertEqual(
            TranscriptDidReceiveContract.disposition(
                trigger: .didReceive,
                incomingGameId: "game-1",
                currentGameId: "game-1"
            ),
            .applyToActiveContext
        )
    }

    func testDidReceiveStoresOtherGamesWithoutHijackingActiveContext() {
        XCTAssertEqual(
            TranscriptDidReceiveContract.disposition(
                trigger: .didReceive,
                incomingGameId: "game-2",
                currentGameId: "game-1"
            ),
            .storeForRecoveryOnly
        )
    }

    func testNonDidReceiveTriggersStillAllowExplicitContextSwitches() {
        XCTAssertEqual(
            TranscriptDidReceiveContract.disposition(
                trigger: .didSelect,
                incomingGameId: "game-2",
                currentGameId: "game-1"
            ),
            .applyToActiveContext
        )
    }
}
