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

    func testSelectionPollCannotRestorePreviouslySelectedGameOverRecoveredGame() {
        XCTAssertEqual(
            TranscriptDidReceiveContract.disposition(
                trigger: .selectionPoll,
                incomingGameId: "previous-game",
                currentGameId: "recovered-game"
            ),
            .storeForRecoveryOnly
        )
    }

    func testSelectionPollCanRefreshRecoveredGameWhenIdentifiersMatch() {
        XCTAssertEqual(
            TranscriptDidReceiveContract.disposition(
                trigger: .selectionPoll,
                incomingGameId: "recovered-game",
                currentGameId: "recovered-game"
            ),
            .applyToActiveContext
        )
    }

    func testYourGamesSwitchSequenceKeepsRecoveredGameLive() {
        let recoveredGame = "recovered-game"

        XCTAssertEqual(
            TranscriptDidReceiveContract.disposition(
                trigger: .selectionPoll,
                incomingGameId: "previously-selected-game",
                currentGameId: recoveredGame
            ),
            .storeForRecoveryOnly
        )
        XCTAssertEqual(
            TranscriptDidReceiveContract.disposition(
                trigger: .didReceive,
                incomingGameId: recoveredGame,
                currentGameId: recoveredGame
            ),
            .applyToActiveContext
        )
        XCTAssertEqual(
            TranscriptDidReceiveContract.disposition(
                trigger: .didReceive,
                incomingGameId: "unrelated-game",
                currentGameId: recoveredGame
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
