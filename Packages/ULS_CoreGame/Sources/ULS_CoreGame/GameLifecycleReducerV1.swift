import Foundation

public enum GameLifecycleIntentV1: Codable, Equatable {
    case resign(gameId: String, rev: Int, stateHash: String)
    case proposeDraw(gameId: String, rev: Int, stateHash: String)
    case voteDraw(approve: Bool, gameId: String, rev: Int, stateHash: String)
    case endGame(gameId: String, rev: Int, stateHash: String)

    public static func resign(anchoredTo state: CoreGameStateV1) -> Self {
        .resign(gameId: state.gameId, rev: state.rev, stateHash: state.stateHash)
    }

    public static func proposeDraw(anchoredTo state: CoreGameStateV1) -> Self {
        .proposeDraw(gameId: state.gameId, rev: state.rev, stateHash: state.stateHash)
    }

    public static func voteDraw(approve: Bool, anchoredTo state: CoreGameStateV1) -> Self {
        .voteDraw(
            approve: approve,
            gameId: state.gameId,
            rev: state.rev,
            stateHash: state.stateHash
        )
    }

    public static func endGame(anchoredTo state: CoreGameStateV1) -> Self {
        .endGame(gameId: state.gameId, rev: state.rev, stateHash: state.stateHash)
    }

    public func matches(_ state: CoreGameStateV1) -> Bool {
        let anchor: (gameId: String, rev: Int, stateHash: String)
        switch self {
        case let .resign(gameId, rev, stateHash),
             let .proposeDraw(gameId, rev, stateHash),
             let .endGame(gameId, rev, stateHash):
            anchor = (gameId, rev, stateHash)
        case let .voteDraw(_, gameId, rev, stateHash):
            anchor = (gameId, rev, stateHash)
        }
        return anchor.gameId == state.gameId
            && anchor.rev == state.rev
            && anchor.stateHash == state.stateHash
    }
}

public func apply(
    intent: GameLifecycleIntentV1,
    to state: CoreGameStateV1,
    actor: String
) throws -> CoreGameStateV1 {
    guard intent.matches(state) else {
        throw CoreGameError.gameLifecycleIntentInvalid
    }
    guard state.phase != .gameOver else {
        throw CoreGameError.gameAlreadyOver
    }
    guard state.phase == .setup || state.phase == .turn else {
        throw CoreGameError.gameLifecycleIntentInvalid
    }
    guard state.roster.contains(actor) else {
        throw CoreGameError.actorMismatch
    }

    switch intent {
    case .resign:
        guard state.isActivePlayer(actor), state.activePlayers.count > 1 else {
            throw CoreGameError.gameLifecycleIntentInvalid
        }
        return stateByApplyingResignation(to: state, actor: actor)
    case .proposeDraw:
        guard state.isActivePlayer(actor), state.drawVote == nil else {
            throw CoreGameError.gameLifecycleIntentInvalid
        }
        return stateByProposingDraw(to: state, actor: actor)
    case let .voteDraw(approve, _, _, _):
        guard
            state.isActivePlayer(actor),
            let vote = state.drawVote,
            !vote.approvals.contains(actor)
        else {
            throw CoreGameError.gameLifecycleIntentInvalid
        }
        return stateByVotingOnDraw(to: state, actor: actor, approve: approve)
    case .endGame:
        guard actor == state.hostPlayer else {
            throw CoreGameError.actorMismatch
        }
        return stateByEndingGame(to: state, actor: actor)
    }
}

private func stateByApplyingResignation(
    to state: CoreGameStateV1,
    actor: String
) -> CoreGameStateV1 {
    let resignedPlayers = state.roster.filter {
        state.resignedPlayers.contains($0) || $0 == actor
    }
    let activePlayers = state.roster.filter { !resignedPlayers.contains($0) }
    var resources = state.resourcesByPlayer
    let returnedHand = resources[actor] ?? .zero
    resources[actor] = .zero

    var devCards = state.devCardsByPlayer
    var newDevCards = state.newDevCardsByPlayer
    var revealedVictoryPoints = state.revealedVictoryPointsByPlayer
    devCards[actor] = .zero
    newDevCards[actor] = .zero
    revealedVictoryPoints[actor] = 0

    let progression = progressionAfterResignation(
        state: state,
        actor: actor,
        activePlayers: activePlayers
    )
    let provisional = copiedState(
        state,
        currentPlayer: progression.currentPlayer,
        phase: progression.phase,
        resourcesByPlayer: resources,
        bankResources: addHands(state.bankResources, returnedHand),
        devCardsByPlayer: devCards,
        newDevCardsByPlayer: newDevCards,
        revealedVictoryPointsByPlayer: revealedVictoryPoints,
        largestArmyOwner: state.largestArmyOwner == actor ? nil : state.largestArmyOwner,
        largestArmySize: state.largestArmyOwner == actor ? 0 : state.largestArmySize,
        longestRoadOwner: state.longestRoadOwner == actor ? nil : state.longestRoadOwner,
        longestRoadLength: state.longestRoadOwner == actor ? 0 : state.longestRoadLength,
        resignedPlayers: resignedPlayers,
        drawVote: .some(nil),
        activeTradeOffer: .some(nil),
        tradeResponses: [],
        setupState: progression.setupState,
        turnState: progression.turnState
    )
    let awards = recomputeAwards(from: state, for: provisional)
    return copiedState(
        provisional,
        advanceRevision: false,
        largestArmyOwner: awards.largestArmyOwner,
        largestArmySize: awards.largestArmySize,
        longestRoadOwner: awards.longestRoadOwner,
        longestRoadLength: awards.longestRoadLength
    ).rehashed()
}

private func stateByProposingDraw(
    to state: CoreGameStateV1,
    actor: String
) -> CoreGameStateV1 {
    let vote = DrawVoteV1(proposedBy: actor, approvals: [actor])
    if state.activePlayers.count == 1 {
        return terminalState(
            from: state,
            result: GameResultV1(
                reason: .draw,
                winnerPlayers: [],
                finalScoresByPlayer: victoryPointsByPlayer(in: state)
            )
        )
    }
    return copiedState(
        state,
        drawVote: vote,
        hasAttemptedDrawVote: true
    ).rehashed()
}

private func stateByVotingOnDraw(
    to state: CoreGameStateV1,
    actor: String,
    approve: Bool
) -> CoreGameStateV1 {
    guard let vote = state.drawVote else {
        preconditionFailure("Draw vote validation must run before applying a vote.")
    }
    guard approve else {
        return copiedState(
            state,
            drawVote: .some(nil),
            hasAttemptedDrawVote: true
        ).rehashed()
    }

    let approvalSet = Set(vote.approvals + [actor])
    let approvals = state.activePlayers.filter(approvalSet.contains)
    if approvals == state.activePlayers {
        return terminalState(
            from: state,
            result: GameResultV1(
                reason: .draw,
                winnerPlayers: [],
                finalScoresByPlayer: victoryPointsByPlayer(in: state)
            )
        )
    }

    return copiedState(
        state,
        drawVote: DrawVoteV1(
            proposedBy: vote.proposedBy,
            approvals: approvals
        ),
        hasAttemptedDrawVote: true
    ).rehashed()
}

private func stateByEndingGame(
    to state: CoreGameStateV1,
    actor: String
) -> CoreGameStateV1 {
    terminalState(
        from: state,
        result: GameResultV1(
            reason: .hostEnded,
            winnerPlayers: [],
            endedByPlayer: actor,
            finalScoresByPlayer: victoryPointsByPlayer(in: state)
        )
    )
}

private func terminalState(
    from state: CoreGameStateV1,
    result: GameResultV1
) -> CoreGameStateV1 {
    copiedState(
        state,
        phase: .gameOver,
        winnerPlayer: nil,
        winningVictoryPoints: 0,
        gameResult: result,
        drawVote: .some(nil),
        hasAttemptedDrawVote: result.reason == .draw
            ? true
            : state.hasAttemptedDrawVote,
        activeTradeOffer: .some(nil),
        tradeResponses: [],
        setupState: .some(nil),
        turnState: .some(nil)
    ).rehashed()
}

private struct ResignationProgression {
    let phase: PhaseV1
    let currentPlayer: String
    let setupState: SetupStateV1?
    let turnState: TurnStateV1?
}

private func progressionAfterResignation(
    state: CoreGameStateV1,
    actor: String,
    activePlayers: [String]
) -> ResignationProgression {
    if state.phase == .setup, let setup = state.setupState {
        let priorOrder = Array(setup.order.prefix(setup.turnIndex))
        let filteredOrder = setup.order.filter { $0 != actor }
        let filteredTurnIndex = priorOrder.filter { $0 != actor }.count
        if filteredTurnIndex >= filteredOrder.count {
            return ResignationProgression(
                phase: .turn,
                currentPlayer: activePlayers[0],
                setupState: nil,
                turnState: TurnStateV1(step: .needsRoll, lastRoll: nil)
            )
        }
        let nextSetup = SetupStateV1(
            order: filteredOrder,
            turnIndex: filteredTurnIndex,
            step: actor == state.currentPlayer ? .placeSettlement : setup.step,
            placements: setup.placements,
            lastPlacedSettlementNode: actor == state.currentPlayer
                ? nil
                : setup.lastPlacedSettlementNode
        )
        return ResignationProgression(
            phase: .setup,
            currentPlayer: filteredOrder[filteredTurnIndex],
            setupState: nextSetup,
            turnState: nil
        )
    }

    guard actor == state.currentPlayer else {
        return ResignationProgression(
            phase: .turn,
            currentPlayer: state.currentPlayer,
            setupState: nil,
            turnState: turnStateAfterOffTurnResignation(state.turnState, actor: actor)
        )
    }

    return ResignationProgression(
        phase: .turn,
        currentPlayer: nextActivePlayer(after: actor, roster: state.roster, activePlayers: activePlayers),
        setupState: nil,
        turnState: TurnStateV1(step: .needsRoll, lastRoll: nil)
    )
}

private func turnStateAfterOffTurnResignation(
    _ turnState: TurnStateV1?,
    actor: String
) -> TurnStateV1? {
    guard let turnState else {
        return nil
    }
    var requirements = turnState.discardRequirementsByPlayer
    var submitted = turnState.submittedDiscardsByPlayer
    requirements.removeValue(forKey: actor)
    submitted.removeValue(forKey: actor)
    let victims = turnState.eligibleStealVictims.filter { $0 != actor }
    var step = turnState.step
    if step == .pendingDiscards, requirements.keys.allSatisfy({ submitted[$0] != nil }) {
        step = .needsRobberMove
    } else if step == .needsRobberSteal, victims.isEmpty {
        step = .afterRoll
    }
    return TurnStateV1(
        step: step,
        lastRoll: turnState.lastRoll,
        discardRequirementsByPlayer: requirements,
        submittedDiscardsByPlayer: submitted,
        eligibleStealVictims: victims
    )
}

private func nextActivePlayer(
    after actor: String,
    roster: [String],
    activePlayers: [String]
) -> String {
    guard let actorIndex = roster.firstIndex(of: actor) else {
        return activePlayers[0]
    }
    for offset in 1...roster.count {
        let candidate = roster[(actorIndex + offset) % roster.count]
        if activePlayers.contains(candidate) {
            return candidate
        }
    }
    return activePlayers[0]
}

private func addHands(_ lhs: ResourceHandV1, _ rhs: ResourceHandV1) -> ResourceHandV1 {
    ResourceHandV1(
        wood: lhs.wood + rhs.wood,
        brick: lhs.brick + rhs.brick,
        sheep: lhs.sheep + rhs.sheep,
        wheat: lhs.wheat + rhs.wheat,
        ore: lhs.ore + rhs.ore
    )
}

private func copiedState(
    _ state: CoreGameStateV1,
    advanceRevision: Bool = true,
    currentPlayer: String? = nil,
    phase: PhaseV1? = nil,
    resourcesByPlayer: [String: ResourceHandV1]? = nil,
    bankResources: ResourceHandV1? = nil,
    devCardsByPlayer: [String: DevCardInventoryV1]? = nil,
    newDevCardsByPlayer: [String: DevCardInventoryV1]? = nil,
    revealedVictoryPointsByPlayer: [String: Int]? = nil,
    largestArmyOwner: String?? = nil,
    largestArmySize: Int? = nil,
    longestRoadOwner: String?? = nil,
    longestRoadLength: Int? = nil,
    winnerPlayer: String?? = nil,
    winningVictoryPoints: Int? = nil,
    gameResult: GameResultV1?? = nil,
    resignedPlayers: [String]? = nil,
    drawVote: DrawVoteV1?? = nil,
    hasAttemptedDrawVote: Bool? = nil,
    activeTradeOffer: TradeOfferV1?? = nil,
    tradeResponses: [TradeResponseV1]? = nil,
    setupState: SetupStateV1?? = nil,
    turnState: TurnStateV1?? = nil
) -> CoreGameStateV1 {
    CoreGameStateV1(
        gameId: state.gameId,
        rev: advanceRevision ? state.rev + 1 : state.rev,
        prevHash: advanceRevision ? state.stateHash : state.prevHash,
        stateHash: "",
        roster: state.roster,
        currentPlayer: currentPlayer ?? state.currentPlayer,
        playerDisplayNamesByPlayer: state.playerDisplayNamesByPlayer,
        phase: phase ?? state.phase,
        seed: state.seed,
        diceRngState: state.diceRngState,
        robberRngState: state.robberRngState,
        resourcesByPlayer: resourcesByPlayer ?? state.resourcesByPlayer,
        bankResources: bankResources ?? state.bankResources,
        devDeck: state.devDeck,
        devCardsByPlayer: devCardsByPlayer ?? state.devCardsByPlayer,
        newDevCardsByPlayer: newDevCardsByPlayer ?? state.newDevCardsByPlayer,
        revealedVictoryPointsByPlayer:
            revealedVictoryPointsByPlayer ?? state.revealedVictoryPointsByPlayer,
        devCardActionPlayedThisTurn: state.devCardActionPlayedThisTurn,
        knightsPlayedByPlayer: state.knightsPlayedByPlayer,
        largestArmyOwner: largestArmyOwner ?? state.largestArmyOwner,
        largestArmySize: largestArmySize ?? state.largestArmySize,
        longestRoadOwner: longestRoadOwner ?? state.longestRoadOwner,
        longestRoadLength: longestRoadLength ?? state.longestRoadLength,
        winnerPlayer: winnerPlayer ?? state.winnerPlayer,
        winningVictoryPoints: winningVictoryPoints ?? state.winningVictoryPoints,
        gameResult: gameResult ?? state.gameResult,
        resignedPlayers: resignedPlayers ?? state.resignedPlayers,
        drawVote: drawVote ?? state.drawVote,
        hasAttemptedDrawVote: hasAttemptedDrawVote ?? state.hasAttemptedDrawVote,
        auditLog: state.auditLog,
        lastTurnRecap: state.lastTurnRecap,
        activeTradeOffer: activeTradeOffer ?? state.activeTradeOffer,
        tradeResponses: tradeResponses ?? state.tradeResponses,
        settlementsByNode: state.settlementsByNode,
        citiesByNode: state.citiesByNode,
        roadsByEdge: state.roadsByEdge,
        boardRules: state.boardRules,
        board: state.board,
        setupState: setupState ?? state.setupState,
        turnState: turnState ?? state.turnState
    )
}
