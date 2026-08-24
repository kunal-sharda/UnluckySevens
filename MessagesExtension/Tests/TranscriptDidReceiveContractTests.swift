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
            .storeInLedgerOnly
        )
    }

    func testSelectionPollCannotReplaceBubbleBoundGameWithPreviousSelection() {
        XCTAssertEqual(
            TranscriptDidReceiveContract.disposition(
                trigger: .selectionPoll,
                incomingGameId: "previous-game",
                currentGameId: "bubble-bound-game"
            ),
            .storeInLedgerOnly
        )
    }

    func testSelectionPollCanRefreshCurrentGameWhenIdentifiersMatch() {
        XCTAssertEqual(
            TranscriptDidReceiveContract.disposition(
                trigger: .selectionPoll,
                incomingGameId: "current-game",
                currentGameId: "current-game"
            ),
            .applyToActiveContext
        )
    }

    func testBubbleBoundGameRejectsOtherUpdatesAndAcceptsMatchingUpdate() {
        let currentGame = "current-game"

        XCTAssertEqual(
            TranscriptDidReceiveContract.disposition(
                trigger: .selectionPoll,
                incomingGameId: "previously-selected-game",
                currentGameId: currentGame
            ),
            .storeInLedgerOnly
        )
        XCTAssertEqual(
            TranscriptDidReceiveContract.disposition(
                trigger: .didReceive,
                incomingGameId: currentGame,
                currentGameId: currentGame
            ),
            .applyToActiveContext
        )
        XCTAssertEqual(
            TranscriptDidReceiveContract.disposition(
                trigger: .didReceive,
                incomingGameId: "unrelated-game",
                currentGameId: currentGame
            ),
            .storeInLedgerOnly
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
