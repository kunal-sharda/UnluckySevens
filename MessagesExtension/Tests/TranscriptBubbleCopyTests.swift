import XCTest
import ULS_CoreGame
@testable import MessagesExtension

final class TranscriptBubbleCopyTests: XCTestCase {
    func testLobbyJoinUsesProductCaptionAndSummary() {
        let state = makeLobbyState(roster: ["host", "guest"], customNames: ["guest": "Kunal"])

        let copy = TranscriptBubbleCopyBuilder.lobbyJoin(to: state, joiningPlayer: "guest")

        XCTAssertEqual(copy.caption, "Unlucky Sevens: Kunal Joined")
        XCTAssertEqual(copy.summary, "2 players are now in the lobby.")
    }

    func testTurnEndUsesNextPlayerSummary() {
        let state = makeTurnState(currentPlayer: "B", customNames: ["B": "Kunal"])
        let intent = TurnIntentV1.endTurn

        let copy = TranscriptBubbleCopyBuilder.turnIntent(intent, actor: "A", resultingState: state)

        XCTAssertEqual(copy.caption, "Unlucky Sevens: Turn Ended")
        XCTAssertEqual(copy.summary, "Next turn: Kunal.")
    }

    private func makeLobbyState(
        roster: [String],
        customNames: [String: String]
    ) -> CoreGameStateV1 {
        CoreGameStateV1(
            gameId: "bubble-copy-lobby",
            rev: 1,
            prevHash: "prev",
            stateHash: "",
            roster: roster,
            currentPlayer: roster[0],
            playerDisplayNamesByPlayer: customNames,
            phase: .lobby,
            seed: nil,
            diceRngState: nil,
            resourcesByPlayer: Dictionary(uniqueKeysWithValues: roster.map { ($0, .zero) }),
            boardRules: nil,
            board: nil
        ).rehashed()
    }

    private func makeTurnState(
        currentPlayer: String,
        customNames: [String: String]
    ) -> CoreGameStateV1 {
        let roster = ["A", "B"]
        return CoreGameStateV1(
            gameId: "bubble-copy-turn",
            rev: 4,
            prevHash: "prev",
            stateHash: "",
            roster: roster,
            currentPlayer: currentPlayer,
            playerDisplayNamesByPlayer: customNames,
            phase: .turn,
            seed: 1,
            diceRngState: 2,
            robberRngState: 3,
            resourcesByPlayer: Dictionary(uniqueKeysWithValues: roster.map { ($0, .zero) }),
            boardRules: BoardRulesV1(strategy: .randomV1),
            board: StandardBoardGeneratorV1.generate(
                boardSeed: SeedDeriver(masterSeed: 1).seed(for: .board),
                rules: BoardRulesV1(strategy: .randomV1)
            ),
            turnState: TurnStateV1(step: .needsRoll, lastRoll: nil)
        ).rehashed()
    }
}
