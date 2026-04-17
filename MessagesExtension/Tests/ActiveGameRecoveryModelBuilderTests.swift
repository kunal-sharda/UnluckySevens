import XCTest
import ULS_CoreGame
@testable import MessagesExtension

final class ActiveGameRecoveryModelBuilderTests: XCTestCase {
    func testBuildTurnSummaryUsesCurrentPlayerTurnCopy() {
        let state = makeState(phase: .turn, currentPlayer: "player-b", winnerPlayer: nil)

        let summary = ActiveGameRecoveryModelBuilder.build(
            from: state,
            isLastActive: true,
            isCurrentSelection: false
        )

        XCTAssertTrue(summary.title.contains("turn"))
        XCTAssertTrue(summary.subtitle.contains("rev 7"))
        XCTAssertTrue(summary.isLastActive)
        XCTAssertFalse(summary.isCurrentSelection)
    }

    func testBuildGameOverSummaryUsesWinnerCopy() {
        let state = makeState(phase: .gameOver, currentPlayer: "player-a", winnerPlayer: "player-c")

        let summary = ActiveGameRecoveryModelBuilder.build(
            from: state,
            isLastActive: false,
            isCurrentSelection: true
        )

        XCTAssertTrue(summary.title.contains("won"))
        XCTAssertTrue(summary.isCurrentSelection)
    }

    private func makeState(
        phase: PhaseV1,
        currentPlayer: String,
        winnerPlayer: String?
    ) -> CoreGameStateV1 {
        CoreGameStateV1(
            gameId: "game-1234567890",
            rev: 7,
            prevHash: "hash-6",
            stateHash: "",
            roster: ["player-a", "player-b", "player-c"],
            currentPlayer: currentPlayer,
            phase: phase,
            seed: 1,
            diceRngState: 10,
            robberRngState: 20,
            resourcesByPlayer: [
                "player-a": .zero,
                "player-b": .zero,
                "player-c": .zero,
            ],
            winnerPlayer: winnerPlayer,
            winningVictoryPoints: winnerPlayer == nil ? 0 : 10
        ).rehashed()
    }
}
