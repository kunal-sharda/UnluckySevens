import XCTest
import ULS_CoreGame
@testable import MessagesExtensionSupport

final class TranscriptBubbleCopyTests: XCTestCase {
    func testLobbyJoinUsesProductCaptionAndSummary() {
        let state = makeLobbyState(roster: ["host", "guest"], customNames: ["guest": "Kunal"])

        let copy = TranscriptBubbleCopyBuilder.lobbyJoin(to: state, joiningPlayer: "guest")

        XCTAssertEqual(copy.caption, "Unlucky Sevens: Kunal Joined")
        XCTAssertEqual(copy.summary, "2 players at the table.")
        guard case let .lobby(model) = copy.visual else {
            return XCTFail("Expected the updated lobby table visual.")
        }
        XCTAssertEqual(model.participants.count, 2)
        XCTAssertEqual(model.participants.last?.displayName, "Kunal")
    }

    func testLobbyVisualsTrackCurrentRosterAndNames() {
        let state = makeLobbyState(roster: ["host", "guest"], customNames: ["guest": "Kunal"])

        let inviteCopy = TranscriptBubbleCopyBuilder.invite(for: state)
        let renameCopy = TranscriptBubbleCopyBuilder.lobbyRename(
            from: state,
            to: state,
            player: "guest",
            previousDisplayName: "Kunal"
        )

        guard case let .lobby(inviteModel) = inviteCopy.visual else {
            return XCTFail("Expected an invite lobby table visual.")
        }
        guard case let .lobby(renameModel) = renameCopy.visual else {
            return XCTFail("Expected a renamed lobby table visual.")
        }
        XCTAssertEqual(inviteModel.participants.count, 2)
        XCTAssertEqual(renameModel.participants.last?.displayName, "Kunal")
    }

    func testStartGameUsesNumberlessBoardVisual() throws {
        let fromState = makeLobbyState(roster: ["A", "B"], customNames: [:])
        let toState = makeSetupState()

        let copy = TranscriptBubbleCopyBuilder.startGame(from: fromState, to: toState)

        let visual = try XCTUnwrap(boardVisual(from: copy))
        XCTAssertFalse(visual.showsNumberTokens)
    }

    func testSetupIntentUsesNumberlessBoardVisual() throws {
        let state = makeSetupState()

        let copy = TranscriptBubbleCopyBuilder.setupIntent(
            .placeSetupSettlement(node: 0),
            resultingState: state,
            actor: "A"
        )

        let visual = try XCTUnwrap(boardVisual(from: copy))
        XCTAssertFalse(visual.showsNumberTokens)
    }

    func testTurnEndUsesNextPlayerSummary() {
        let state = makeTurnState(currentPlayer: "B", customNames: ["B": "Kunal"])
        let intent = TurnIntentV1.endTurn

        let copy = TranscriptBubbleCopyBuilder.turnIntent(intent, actor: "A", resultingState: state)

        XCTAssertEqual(copy.caption, "Unlucky Sevens: Turn Ended")
        XCTAssertEqual(copy.summary, "Next turn: Kunal.")
        XCTAssertEqual(boardVisual(from: copy)?.showsNumberTokens, true)
    }

    func testGameOverUsesFinalScoreVisual() {
        let state = makeTurnState(
            currentPlayer: "A",
            customNames: ["A": "Avery"],
            phase: .gameOver,
            winnerPlayer: "A",
            winningVictoryPoints: 10,
            turnState: nil
        )

        let copy = TranscriptBubbleCopyBuilder.turnIntent(.endTurn, actor: "A", resultingState: state)

        XCTAssertEqual(copy.caption, "Unlucky Sevens: Avery Wins")
        guard case let .gameOver(visual) = copy.visual else {
            return XCTFail("Expected the final board and score visual.")
        }
        XCTAssertEqual(visual.winnerTitle, "Avery won")
        XCTAssertTrue(visual.scoreLine.contains("Avery"))
    }

    func testResignationReceiptSaysPlayContinues() throws {
        let active = makeTurnState(
            currentPlayer: "A",
            customNames: ["A": "Avery", "B": "Blake"]
        )
        let continued = try apply(
            intent: .resign(anchoredTo: active),
            to: active,
            actor: "A"
        )

        let copy = TranscriptBubbleCopyBuilder.resignation(
            resultingState: continued,
            actor: "A"
        )

        XCTAssertEqual(copy.caption, "Unlucky Sevens: Avery Resigned")
        XCTAssertEqual(copy.summary, "Avery left the game. Blake has the turn.")
        guard case .board = copy.visual else {
            return XCTFail("Expected the continuing board visual.")
        }
        XCTAssertEqual(continued.phase, .turn)
        XCTAssertEqual(continued.resignedPlayers, ["A"])
    }

    func testDrawProposalAndRejectionReceiptsKeepPlayActive() throws {
        let active = makeTurnState(
            currentPlayer: "A",
            customNames: ["A": "Avery", "B": "Blake"]
        )
        let proposed = try apply(
            intent: .proposeDraw(anchoredTo: active),
            to: active,
            actor: "A"
        )
        let proposalCopy = TranscriptBubbleCopyBuilder.drawProposed(
            resultingState: proposed,
            actor: "A"
        )

        XCTAssertEqual(proposalCopy.caption, "Unlucky Sevens: Draw Proposed")
        XCTAssertEqual(
            proposalCopy.summary,
            "Avery proposed a draw. Every active player must agree."
        )

        let rejected = try apply(
            intent: .voteDraw(approve: false, anchoredTo: proposed),
            to: proposed,
            actor: "B"
        )
        let rejectionCopy = TranscriptBubbleCopyBuilder.drawVote(
            resultingState: rejected,
            actor: "B",
            approved: false
        )

        XCTAssertEqual(rejectionCopy.caption, "Unlucky Sevens: Draw Declined")
        XCTAssertEqual(rejectionCopy.summary, "Blake declined the draw. Play continues.")
        XCTAssertEqual(rejected.phase, .turn)
        XCTAssertNil(rejected.drawVote)
    }

    func testUnanimousDrawAndHostEndReceiptsAreNeutral() throws {
        let active = makeTurnState(
            currentPlayer: "A",
            customNames: ["A": "Avery", "B": "Blake"]
        )
        let proposed = try apply(
            intent: .proposeDraw(anchoredTo: active),
            to: active,
            actor: "A"
        )
        let drawn = try apply(
            intent: .voteDraw(approve: true, anchoredTo: proposed),
            to: proposed,
            actor: "B"
        )
        let drawCopy = TranscriptBubbleCopyBuilder.drawVote(
            resultingState: drawn,
            actor: "B",
            approved: true
        )

        XCTAssertEqual(drawCopy.caption, "Unlucky Sevens: Draw Agreed")
        XCTAssertEqual(drawCopy.summary, "All active players agreed to a draw.")

        let ended = try apply(
            intent: .endGame(anchoredTo: active),
            to: active,
            actor: "A"
        )
        let endedCopy = TranscriptBubbleCopyBuilder.hostEnded(
            resultingState: ended,
            actor: "A"
        )

        XCTAssertEqual(endedCopy.caption, "Unlucky Sevens: Game Ended")
        XCTAssertEqual(
            endedCopy.summary,
            "Avery ended the game as host. No winner was declared."
        )
        XCTAssertTrue(ended.gameResult?.winnerPlayers.isEmpty == true)
    }

    func testRecoveryResendUsesUnchangedStateAndRestoredReceipt() {
        let state = makeTurnState(
            currentPlayer: "B",
            customNames: ["A": "Avery"]
        )

        let copy = TranscriptBubbleCopyBuilder.recoveryResend(
            state: state,
            actor: "A"
        )

        XCTAssertEqual(copy.caption, "Unlucky Sevens: Game Restored")
        XCTAssertEqual(copy.summary, "Avery resent the latest game state.")
        XCTAssertEqual(boardVisual(from: copy)?.showsNumberTokens, true)
    }

    func testLiveTradeToAllPlayersUsesSharedReceipt() {
        let state = makeTradeState(recipients: ["B", "C"])

        let copy = TranscriptBubbleCopyBuilder.turnIntent(
            .proposeTrade(
                give: ResourceHandV1(wheat: 2),
                receive: ResourceHandV1(ore: 1),
                recipients: ["B", "C"]
            ),
            actor: "A",
            resultingState: state
        )

        guard case let .trade(visual) = copy.visual else {
            return XCTFail("Expected the shared live-trade receipt.")
        }
        XCTAssertEqual(visual.offer.proposerDisplay, "Avery")
        XCTAssertEqual(visual.recipientScopeLabel, "To everyone")
    }

    func testPartialTradeDeclineKeepsSharedReceipt() {
        let state = makeTradeState(recipients: ["B", "C"])

        let copy = TranscriptBubbleCopyBuilder.turnIntent(
            .declineTrade(decliningPlayer: "B", offerHash: "offer"),
            actor: "B",
            resultingState: state
        )

        guard case .trade = copy.visual else {
            return XCTFail("Expected the live receipt while another recipient can respond.")
        }
    }

    func testResolvedTradeReturnsToBoard() {
        let state = makeTurnState(currentPlayer: "A", customNames: ["A": "Avery"])

        let accepted = TranscriptBubbleCopyBuilder.turnIntent(
            .acceptTrade(acceptingPlayer: "B", offerHash: "offer"),
            actor: "B",
            resultingState: state
        )
        let finalDecline = TranscriptBubbleCopyBuilder.turnIntent(
            .declineTrade(decliningPlayer: "B", offerHash: "offer"),
            actor: "B",
            resultingState: state
        )

        XCTAssertNotNil(boardVisual(from: accepted))
        XCTAssertNotNil(boardVisual(from: finalDecline))
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

    private func makeTradeState(recipients: [String]) -> CoreGameStateV1 {
        let roster = ["A", "B", "C"]
        let base = CoreGameStateV1(
            gameId: "bubble-copy-trade",
            rev: 4,
            prevHash: "prev",
            stateHash: "",
            roster: roster,
            currentPlayer: "A",
            playerDisplayNamesByPlayer: [
                "A": "Avery",
                "B": "Maya",
                "C": "Theo",
            ],
            phase: .turn,
            seed: 1,
            diceRngState: 2,
            robberRngState: 3,
            resourcesByPlayer: Dictionary(uniqueKeysWithValues: roster.map { ($0, .zero) }),
            activeTradeOffer: TradeOfferV1(
                offerHash: "offer",
                proposer: "A",
                give: ResourceHandV1(wheat: 2),
                receive: ResourceHandV1(ore: 1),
                recipients: recipients,
                createdRev: 4
            ),
            boardRules: BoardRulesV1(strategy: .randomV1),
            board: StandardBoardGeneratorV1.generate(
                boardSeed: SeedDeriver(masterSeed: 1).seed(for: .board),
                rules: BoardRulesV1(strategy: .randomV1)
            ),
            turnState: TurnStateV1(step: .afterRoll, lastRoll: DiceRollV1(d1: 4, d2: 2))
        )
        return base.rehashed()
    }

    private func boardVisual(from copy: TranscriptBubbleCopy) -> TranscriptBoardVisual? {
        guard case let .board(visual) = copy.visual else {
            return nil
        }
        return visual
    }
}
