import XCTest
import ULS_CoreGame
@testable import MessagesExtension

final class TranscriptBubbleCopyTests: XCTestCase {
    func testLobbyJoinUsesProductCaptionAndSummary() {
        let state = makeLobbyState(roster: ["host", "guest"], customNames: ["guest": "Kunal"])

        let copy = TranscriptBubbleCopyBuilder.lobbyJoin(to: state, joiningPlayer: "guest")

        XCTAssertEqual(copy.caption, "Unlucky Sevens: Kunal Joined")
        XCTAssertEqual(copy.summary, "2 players are now in the lobby.")
        XCTAssertEqual(copy.visual, .none)
    }

    func testLobbyVisualsKeepOnlyInitialInviteGraphic() {
        let state = makeLobbyState(roster: ["host", "guest"], customNames: ["guest": "Kunal"])

        let inviteCopy = TranscriptBubbleCopyBuilder.invite(for: state)
        let renameCopy = TranscriptBubbleCopyBuilder.lobbyRename(
            from: state,
            to: state,
            player: "guest",
            previousDisplayName: "Kunal"
        )

        XCTAssertEqual(inviteCopy.visual, .lobbyInvite)
        XCTAssertEqual(renameCopy.visual, .none)
    }

    func testStartGameUsesBoardVisual() throws {
        let fromState = makeLobbyState(roster: ["A", "B"], customNames: [:])
        let toState = makeSetupState()

        let copy = TranscriptBubbleCopyBuilder.startGame(from: fromState, to: toState)

        let visual = try XCTUnwrap(boardVisual(from: copy))
        XCTAssertEqual(visual.title, "Game Started")
        XCTAssertEqual(visual.detail, "2 players are entering setup.")
        XCTAssertEqual(visual.state.phase, .setup)
    }

    func testSetupIntentUsesBoardVisual() throws {
        let state = makeSetupState()

        let copy = TranscriptBubbleCopyBuilder.setupIntent(
            .placeSetupSettlement(node: 0),
            resultingState: state,
            actor: "A"
        )

        let visual = try XCTUnwrap(boardVisual(from: copy))
        XCTAssertEqual(visual.title, "Settlement Placed")
        XCTAssertEqual(visual.state.phase, .setup)
    }

    func testTurnEndUsesNextPlayerSummary() {
        let state = makeTurnState(currentPlayer: "B", customNames: ["B": "Kunal"])
        let intent = TurnIntentV1.endTurn

        let copy = TranscriptBubbleCopyBuilder.turnIntent(intent, actor: "A", resultingState: state)

        XCTAssertEqual(copy.caption, "Unlucky Sevens: Turn Ended")
        XCTAssertEqual(copy.summary, "Next turn: Kunal.")
        XCTAssertNotNil(boardVisual(from: copy))
    }

    func testGameOverUsesBoardVisual() throws {
        let state = makeTurnState(
            currentPlayer: "A",
            customNames: ["A": "Avery"],
            phase: .gameOver,
            winnerPlayer: "A",
            winningVictoryPoints: 10,
            turnState: nil
        )

        let copy = TranscriptBubbleCopyBuilder.turnIntent(.endTurn, actor: "A", resultingState: state)

        let visual = try XCTUnwrap(boardVisual(from: copy))
        XCTAssertEqual(copy.caption, "Unlucky Sevens: Avery Wins")
        XCTAssertEqual(visual.title, "Avery Wins")
        XCTAssertEqual(visual.state.phase, .gameOver)
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
        customNames: [String: String],
        phase: PhaseV1 = .turn,
        winnerPlayer: String? = nil,
        winningVictoryPoints: Int = 0,
        turnState: TurnStateV1? = TurnStateV1(step: .needsRoll, lastRoll: nil)
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
            phase: phase,
            seed: 1,
            diceRngState: 2,
            robberRngState: 3,
            resourcesByPlayer: Dictionary(uniqueKeysWithValues: roster.map { ($0, .zero) }),
            winnerPlayer: winnerPlayer,
            winningVictoryPoints: winningVictoryPoints,
            boardRules: BoardRulesV1(strategy: .randomV1),
            board: StandardBoardGeneratorV1.generate(
                boardSeed: SeedDeriver(masterSeed: 1).seed(for: .board),
                rules: BoardRulesV1(strategy: .randomV1)
            ),
            turnState: turnState
        ).rehashed()
    }

    private func makeSetupState() -> CoreGameStateV1 {
        let roster = ["A", "B"]
        return CoreGameStateV1(
            gameId: "bubble-copy-setup",
            rev: 2,
            prevHash: "prev",
            stateHash: "",
            roster: roster,
            currentPlayer: "A",
            playerDisplayNamesByPlayer: [:],
            phase: .setup,
            seed: 1,
            diceRngState: 2,
            robberRngState: 3,
            resourcesByPlayer: Dictionary(uniqueKeysWithValues: roster.map { ($0, .zero) }),
            boardRules: BoardRulesV1(strategy: .randomV1),
            board: StandardBoardGeneratorV1.generate(
                boardSeed: SeedDeriver(masterSeed: 1).seed(for: .board),
                rules: BoardRulesV1(strategy: .randomV1)
            ),
            setupState: initializeSetupState(roster: roster)
        ).rehashed()
    }

    private func boardVisual(from copy: TranscriptBubbleCopy) -> TranscriptBoardBubbleVisual? {
        guard case let .board(visual) = copy.visual else {
            return nil
        }
        return visual
    }
}
