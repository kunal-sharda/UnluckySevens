import XCTest
@testable import MessagesExtension

final class GameBoardCommitCoordinatorTests: XCTestCase {
    func testUnsupportedModeReturnsNilDecision() {
        let decision = GameBoardCommitCoordinator.decision(
            existingDraft: nil,
            normalizedTarget: .tile(2),
            mode: .robberMove
        )

        XCTAssertNil(decision)
    }

    func testInvalidSelectionReturnsFailureHint() {
        let decision = GameBoardCommitCoordinator.decision(
            existingDraft: nil,
            normalizedTarget: nil,
            mode: .buildSettlement
        )

        XCTAssertEqual(decision, .invalid("Tap node"))
    }

    func testFirstTapSelectsDraft() {
        let decision = GameBoardCommitCoordinator.decision(
            existingDraft: nil,
            normalizedTarget: .edge(5),
            mode: .buildRoad
        )

        XCTAssertEqual(
            decision,
            .selected(
                GameBoardCommitDraft(
                    mode: .buildRoad,
                    target: .edge(5)
                )
            )
        )
    }

    func testSecondTapOnSameTargetConfirmsDraft() {
        let draft = GameBoardCommitDraft(mode: .setup, target: .node(8))

        let decision = GameBoardCommitCoordinator.decision(
            existingDraft: draft,
            normalizedTarget: .node(8),
            mode: .setup
        )

        XCTAssertEqual(decision, .confirm(draft))
    }

    func testSelectingDifferentTargetReplacesDraft() {
        let draft = GameBoardCommitDraft(mode: .buildCity, target: .node(3))

        let decision = GameBoardCommitCoordinator.decision(
            existingDraft: draft,
            normalizedTarget: .node(7),
            mode: .buildCity
        )

        XCTAssertEqual(
            decision,
            .selected(
                GameBoardCommitDraft(
                    mode: .buildCity,
                    target: .node(7)
                )
            )
        )
    }
}
