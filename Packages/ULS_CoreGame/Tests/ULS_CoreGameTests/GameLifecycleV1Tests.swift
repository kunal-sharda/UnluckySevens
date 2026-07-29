import XCTest
@testable import ULS_CoreGame

final class GameLifecycleV1Tests: XCTestCase {
    func testCurrentPlayerResignationContinuesWithNextActivePlayerAndReturnsHand() throws {
        let hand = ResourceHandV1(wood: 2, wheat: 1)
        let state = makeState(
            phase: .turn,
            currentPlayer: "A",
            resourcesByPlayer: ["A": hand],
            devCardsByPlayer: ["A": DevCardInventoryV1(knight: 1)],
            revealedVictoryPointsByPlayer: ["A": 1],
            settlementsByNode: [0: "A"]
        )

        let resigned = try apply(
            intent: .resign(anchoredTo: state),
            to: state,
            actor: "A"
        )

        XCTAssertEqual(resigned.phase, .turn)
        XCTAssertEqual(resigned.currentPlayer, "B")
        XCTAssertEqual(resigned.resignedPlayers, ["A"])
        XCTAssertEqual(resigned.activePlayers, ["B", "C"])
        XCTAssertEqual(resigned.resourcesByPlayer["A"], .zero)
        XCTAssertEqual(resigned.bankResources.wood, state.bankResources.wood + 2)
        XCTAssertEqual(resigned.bankResources.wheat, state.bankResources.wheat + 1)
        XCTAssertEqual(resigned.devCardsByPlayer["A"], .zero)
        XCTAssertEqual(resigned.revealedVictoryPointsByPlayer["A"], 0)
        XCTAssertEqual(resigned.settlementsByNode, state.settlementsByNode)
        XCTAssertEqual(resigned.turnState, TurnStateV1(step: .needsRoll, lastRoll: nil))
        XCTAssertNil(resigned.gameResult)
        XCTAssertNil(resigned.activeTradeOffer)
        XCTAssertTrue(resigned.tradeResponses.isEmpty)
        XCTAssertNoThrow(try validateTransition(from: state, to: resigned, actor: "A"))
        XCTAssertNoThrow(try validateCanonicalSnapshot(resigned))
    }

    func testOffTurnResignationPreservesCurrentTurnAndClearsOpenDrawAndTrade() throws {
        let state = makeState(
            phase: .turn,
            currentPlayer: "A",
            drawVote: DrawVoteV1(proposedBy: "A", approvals: ["A"]),
            hasAttemptedDrawVote: true,
            activeTradeOffer: TradeOfferV1(
                offerHash: "offer",
                proposer: "A",
                give: ResourceHandV1(wood: 1),
                receive: ResourceHandV1(brick: 1),
                recipients: ["B"],
                createdRev: 10
            )
        )

        let resigned = try apply(
            intent: .resign(anchoredTo: state),
            to: state,
            actor: "B"
        )

        XCTAssertEqual(resigned.currentPlayer, "A")
        XCTAssertEqual(resigned.turnState, state.turnState)
        XCTAssertEqual(resigned.resignedPlayers, ["B"])
        XCTAssertNil(resigned.drawVote)
        XCTAssertTrue(resigned.hasAttemptedDrawVote)
        XCTAssertNil(resigned.activeTradeOffer)
        XCTAssertNoThrow(try validateTransition(from: state, to: resigned, actor: "B"))
    }

    func testSetupResignationRemovesRemainingSlotsAndContinuesSetup() throws {
        let setup = SetupStateV1(
            order: ["A", "B", "C", "C", "B", "A"],
            turnIndex: 1,
            step: .placeSettlement,
            placements: ["A": PlayerSetupPlacementsV1(settlement1: 0, road1: 0)],
            lastPlacedSettlementNode: nil
        )
        let state = makeState(
            phase: .setup,
            currentPlayer: "B",
            setupState: setup
        )

        let resigned = try apply(
            intent: .resign(anchoredTo: state),
            to: state,
            actor: "B"
        )

        XCTAssertEqual(resigned.phase, .setup)
        XCTAssertEqual(resigned.currentPlayer, "C")
        XCTAssertEqual(resigned.setupState?.order, ["A", "C", "C", "A"])
        XCTAssertEqual(resigned.setupState?.turnIndex, 1)
        XCTAssertEqual(resigned.setupState?.step, .placeSettlement)
        XCTAssertNoThrow(try validateCanonicalSnapshot(resigned))
    }

    func testUnanimousDrawEndsWithoutWinner() throws {
        let state = makeState(phase: .turn, currentPlayer: "A")
        let proposed = try apply(
            intent: .proposeDraw(anchoredTo: state),
            to: state,
            actor: "B"
        )
        XCTAssertEqual(proposed.drawVote, DrawVoteV1(proposedBy: "B", approvals: ["B"]))
        XCTAssertTrue(proposed.hasAttemptedDrawVote)

        let secondVote = try apply(
            intent: .voteDraw(approve: true, anchoredTo: proposed),
            to: proposed,
            actor: "A"
        )
        XCTAssertEqual(secondVote.phase, .turn)
        XCTAssertEqual(secondVote.drawVote?.approvals, ["A", "B"])

        let ended = try apply(
            intent: .voteDraw(approve: true, anchoredTo: secondVote),
            to: secondVote,
            actor: "C"
        )
        XCTAssertEqual(ended.phase, .gameOver)
        XCTAssertEqual(ended.gameResult?.reason, .draw)
        XCTAssertEqual(ended.gameResult?.winnerPlayers, [])
        XCTAssertNil(ended.gameResult?.endedByPlayer)
        XCTAssertNil(ended.winnerPlayer)
        XCTAssertNil(ended.drawVote)
        XCTAssertNoThrow(try validateTransition(from: secondVote, to: ended, actor: "C"))
        XCTAssertNoThrow(try validateCanonicalSnapshot(ended))
    }

    func testRejectedDrawClearsProposalAndPlayContinues() throws {
        let state = makeState(phase: .turn, currentPlayer: "A")
        let proposed = try apply(
            intent: .proposeDraw(anchoredTo: state),
            to: state,
            actor: "A"
        )
        let rejected = try apply(
            intent: .voteDraw(approve: false, anchoredTo: proposed),
            to: proposed,
            actor: "B"
        )

        XCTAssertEqual(rejected.phase, .turn)
        XCTAssertNil(rejected.drawVote)
        XCTAssertTrue(rejected.hasAttemptedDrawVote)
        XCTAssertEqual(rejected.currentPlayer, "A")
        XCTAssertNoThrow(try validateTransition(from: proposed, to: rejected, actor: "B"))
    }

    func testOnlyOriginalHostCanEndGameAndHostEndHasNoWinner() throws {
        let state = makeState(phase: .turn, currentPlayer: "B")
        XCTAssertThrowsError(
            try apply(intent: .endGame(anchoredTo: state), to: state, actor: "B")
        ) {
            XCTAssertEqual($0 as? CoreGameError, .actorMismatch)
        }

        let ended = try apply(
            intent: .endGame(anchoredTo: state),
            to: state,
            actor: "A"
        )
        XCTAssertEqual(ended.phase, .gameOver)
        XCTAssertEqual(ended.gameResult?.reason, .hostEnded)
        XCTAssertEqual(ended.gameResult?.endedByPlayer, "A")
        XCTAssertEqual(ended.gameResult?.winnerPlayers, [])
        XCTAssertNil(ended.winnerPlayer)
        XCTAssertNil(ended.turnState)
        XCTAssertNoThrow(try validateTransition(from: state, to: ended, actor: "A"))
        XCTAssertNoThrow(try validateCanonicalSnapshot(ended))
    }

    func testResignedHostRetainsAdministrativeEndAuthority() throws {
        let state = makeState(phase: .turn, currentPlayer: "B")
        let resignedHost = try apply(
            intent: .resign(anchoredTo: state),
            to: state,
            actor: "A"
        )
        let ended = try apply(
            intent: .endGame(anchoredTo: resignedHost),
            to: resignedHost,
            actor: "A"
        )

        XCTAssertEqual(ended.gameResult?.reason, .hostEnded)
        XCTAssertEqual(ended.gameResult?.endedByPlayer, "A")
    }

    func testLifecycleIntentsRejectLobbyUnknownInactiveAndStaleActors() throws {
        let lobby = makeState(phase: .lobby, currentPlayer: "A")
        XCTAssertThrowsError(
            try apply(intent: .resign(anchoredTo: lobby), to: lobby, actor: "A")
        ) {
            XCTAssertEqual($0 as? CoreGameError, .gameLifecycleIntentInvalid)
        }

        let turn = makeState(phase: .turn, currentPlayer: "A")
        XCTAssertThrowsError(
            try apply(intent: .resign(anchoredTo: turn), to: turn, actor: "unknown")
        ) {
            XCTAssertEqual($0 as? CoreGameError, .actorMismatch)
        }

        let resigned = try apply(
            intent: .resign(anchoredTo: turn),
            to: turn,
            actor: "B"
        )
        XCTAssertThrowsError(
            try apply(intent: .proposeDraw(anchoredTo: resigned), to: resigned, actor: "B")
        ) {
            XCTAssertEqual($0 as? CoreGameError, .gameLifecycleIntentInvalid)
        }

        let stale = GameLifecycleIntentV1.resign(
            gameId: turn.gameId,
            rev: turn.rev - 1,
            stateHash: turn.stateHash
        )
        XCTAssertThrowsError(try apply(intent: stale, to: turn, actor: "A")) {
            XCTAssertEqual($0 as? CoreGameError, .gameLifecycleIntentInvalid)
        }
    }

    func testCanonicalSnapshotRejectsTamperedHashAndInactivePlayerResources() throws {
        let state = makeState(phase: .turn, currentPlayer: "A")
        let resigned = try apply(
            intent: .resign(anchoredTo: state),
            to: state,
            actor: "B"
        )
        XCTAssertThrowsError(try validateCanonicalSnapshot(copy(resigned, stateHash: "tampered"))) {
            XCTAssertEqual($0 as? CoreGameError, .invalidStateHash)
        }

        var resources = resigned.resourcesByPlayer
        resources["B"] = ResourceHandV1(wood: 1)
        let invalid = copy(resigned, resourcesByPlayer: resources).rehashed()
        XCTAssertThrowsError(try validateCanonicalSnapshot(invalid)) {
            XCTAssertEqual($0 as? CoreGameError, .gameResultInvalid)
        }
    }

    func testCanonicalSnapshotRejectsMissingPhaseStateEvenWhenRehashed() {
        let turn = makeState(phase: .turn, currentPlayer: "A")
        let turnWithoutTurnState = copy(turn, turnState: .some(nil)).rehashed()
        XCTAssertThrowsError(try validateCanonicalSnapshot(turnWithoutTurnState)) {
            XCTAssertEqual($0 as? CoreGameError, .turnStateMissing)
        }

        let setup = makeState(
            phase: .setup,
            currentPlayer: "A",
            setupState: initializeSetupState(roster: ["A", "B", "C"])
        )
        let setupWithoutSetupState = copy(setup, setupState: .some(nil)).rehashed()
        XCTAssertThrowsError(try validateCanonicalSnapshot(setupWithoutSetupState)) {
            XCTAssertEqual($0 as? CoreGameError, .setupStateMissing)
        }
    }

    private func makeState(
        phase: PhaseV1,
        currentPlayer: String,
        resourcesByPlayer: [String: ResourceHandV1] = [:],
        devCardsByPlayer: [String: DevCardInventoryV1] = [:],
        revealedVictoryPointsByPlayer: [String: Int] = [:],
        settlementsByNode: [NodeID: String] = [:],
        drawVote: DrawVoteV1? = nil,
        hasAttemptedDrawVote: Bool = false,
        activeTradeOffer: TradeOfferV1? = nil,
        setupState: SetupStateV1? = nil
    ) -> CoreGameStateV1 {
        CoreGameStateV1(
            gameId: "game-lifecycle",
            rev: 10,
            prevHash: "hash-9",
            stateHash: "",
            roster: ["A", "B", "C"],
            currentPlayer: currentPlayer,
            phase: phase,
            seed: phase == .lobby ? nil : 1,
            diceRngState: phase == .turn ? 2 : nil,
            resourcesByPlayer: resourcesByPlayer,
            devCardsByPlayer: devCardsByPlayer,
            revealedVictoryPointsByPlayer: revealedVictoryPointsByPlayer,
            drawVote: drawVote,
            hasAttemptedDrawVote: hasAttemptedDrawVote,
            activeTradeOffer: activeTradeOffer,
            settlementsByNode: settlementsByNode,
            setupState: setupState,
            turnState: phase == .turn
                ? TurnStateV1(step: .afterRoll, lastRoll: DiceRollV1(d1: 3, d2: 3))
                : nil
        ).rehashed()
    }

    private func copy(
        _ state: CoreGameStateV1,
        stateHash: String? = nil,
        resourcesByPlayer: [String: ResourceHandV1]? = nil,
        setupState: SetupStateV1?? = nil,
        turnState: TurnStateV1?? = nil
    ) -> CoreGameStateV1 {
        CoreGameStateV1(
            gameId: state.gameId,
            rev: state.rev,
            prevHash: state.prevHash,
            stateHash: stateHash ?? state.stateHash,
            roster: state.roster,
            currentPlayer: state.currentPlayer,
            playerDisplayNamesByPlayer: state.playerDisplayNamesByPlayer,
            phase: state.phase,
            seed: state.seed,
            diceRngState: state.diceRngState,
            robberRngState: state.robberRngState,
            resourcesByPlayer: resourcesByPlayer ?? state.resourcesByPlayer,
            bankResources: state.bankResources,
            devDeck: state.devDeck,
            devCardsByPlayer: state.devCardsByPlayer,
            newDevCardsByPlayer: state.newDevCardsByPlayer,
            revealedVictoryPointsByPlayer: state.revealedVictoryPointsByPlayer,
            devCardActionPlayedThisTurn: state.devCardActionPlayedThisTurn,
            knightsPlayedByPlayer: state.knightsPlayedByPlayer,
            largestArmyOwner: state.largestArmyOwner,
            largestArmySize: state.largestArmySize,
            longestRoadOwner: state.longestRoadOwner,
            longestRoadLength: state.longestRoadLength,
            winnerPlayer: state.winnerPlayer,
            winningVictoryPoints: state.winningVictoryPoints,
            gameResult: state.gameResult,
            resignedPlayers: state.resignedPlayers,
            drawVote: state.drawVote,
            hasAttemptedDrawVote: state.hasAttemptedDrawVote,
            auditLog: state.auditLog,
            lastTurnRecap: state.lastTurnRecap,
            activeTradeOffer: state.activeTradeOffer,
            tradeResponses: state.tradeResponses,
            settlementsByNode: state.settlementsByNode,
            citiesByNode: state.citiesByNode,
            roadsByEdge: state.roadsByEdge,
            boardRules: state.boardRules,
            board: state.board,
            setupState: setupState ?? state.setupState,
            turnState: turnState ?? state.turnState
        )
    }
}
