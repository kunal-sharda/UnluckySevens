import Foundation

private let validationTopology = StandardBoardTopologyV1.standard()

public enum CoreGameError: Error, Equatable {
    case revMismatch
    case prevHashMismatch
    case actorMismatch
    case rosterChanged
    case playerDisplayNamesChanged
    case seedChanged
    case boardRulesChanged
    case boardChanged
    case invalidBoardHash
    case setupStateMissing
    case setupTurnIndexOutOfRange
    case setupCurrentPlayerMismatch
    case setupStepMismatch
    case roadBeforeSettlement
    case setupPlacementSlotUnavailable
    case invalidNode
    case invalidEdge
    case nodeOccupied
    case edgeOccupied
    case distanceRuleViolation
    case roadNotAdjacentToLastSettlement
    case resourcesByPlayerInvalid
    case bankResourcesInvalid
    case settlementsByNodeInvalid
    case citiesByNodeInvalid
    case roadsByEdgeInvalid
    case turnStateMissing
    case turnStateUnexpected
    case turnStepMismatch
    case missingDiceRngState
    case turnCurrentPlayerNotInRoster
    case invalidStateHash
    case gameIdMismatch
    case discardSubmissionNotRequired
    case discardAlreadySubmitted
    case discardSubmissionOutOfOrder
    case discardCountMismatch
    case insufficientResourcesForDiscard
    case invalidRobberTile
    case robberTileUnchanged
    case missingRobberRngState
    case robberStealVictimNotEligible
    case buildInsufficientResources
    case buildPieceLimitReached
    case roadConnectionRequired
    case settlementConnectionRequired
    case cityRequiresOwnSettlement
    case tradeOfferAlreadyActive
    case tradeOfferMissing
    case tradeOfferInvalid
    case tradeOfferAnchorMismatch
    case tradeAcceptPlayerInvalid
    case tradeAcceptAlreadySubmitted
    case tradeExecutionInsufficientResources
    case maritimeTradeInvalid
    case maritimeTradeInsufficientResources
    case tradeStateInvalid
    case devDeckInvalid
    case devDeckEmpty
    case devCardPurchaseInsufficientResources
    case devCardAlreadyPlayedThisTurn
    case devCardNotOwned
    case devCardPayloadInvalid
    case victoryPointRevealNotWinning
    case awardStateInvalid
    case victoryStateInvalid
    case gameResultInvalid
    case gameLifecycleIntentInvalid
    case auditLogInvalid
    case gameAlreadyOver
}

private enum LobbyTransitionKind {
    case join(player: String)
    case rename
}

public func validateTransition(from: CoreGameStateV1, to: CoreGameStateV1, actor: String) throws {
    if from.phase == .gameOver {
        throw CoreGameError.gameAlreadyOver
    }

    guard to.gameId == from.gameId else {
        throw CoreGameError.gameIdMismatch
    }

    guard to.rev == from.rev + 1 else {
        throw CoreGameError.revMismatch
    }

    guard to.prevHash == from.stateHash else {
        throw CoreGameError.prevHashMismatch
    }

    if lifecycleStateChanged(from: from, to: to) {
        guard matchesLifecycleTransition(from: from, to: to, actor: actor) else {
            throw CoreGameError.gameResultInvalid
        }
        try validateCanonicalSnapshot(to)
        return
    }

    guard isAuthorizedActorForTransition(from: from, to: to, actor: actor) else {
        throw CoreGameError.actorMismatch
    }

    if let board = to.board {
        guard board.boardHash == board.rehashed().boardHash else {
            throw CoreGameError.invalidBoardHash
        }
    }

    if to.phase == .setup {
        guard let setupState = to.setupState else {
            throw CoreGameError.setupStateMissing
        }

        guard setupState.turnIndex >= 0, setupState.turnIndex < setupState.order.count else {
            throw CoreGameError.setupTurnIndexOutOfRange
        }

        guard to.currentPlayer == setupState.order[setupState.turnIndex] else {
            throw CoreGameError.setupCurrentPlayerMismatch
        }
    } else {
        guard to.setupState == nil else {
            throw CoreGameError.setupStateMissing
        }
    }

    if to.phase == .turn {
        guard to.turnState != nil else {
            throw CoreGameError.turnStateMissing
        }
    } else {
        guard to.turnState == nil else {
            throw CoreGameError.turnStateUnexpected
        }
    }

    if try validateLobbyTransitionIfNeeded(from: from, to: to, actor: actor) != nil {
        try validateStateHash(to)
        return
    }

    let isStartTransition = from.phase == .lobby && to.phase == .setup
    if !isStartTransition {
        guard to.roster == from.roster else {
            throw CoreGameError.rosterChanged
        }
        guard
            to.resignedPlayers == from.resignedPlayers,
            to.drawVote == from.drawVote,
            to.hasAttemptedDrawVote == from.hasAttemptedDrawVote
        else {
            throw CoreGameError.gameLifecycleIntentInvalid
        }

        guard to.seed == from.seed else {
            throw CoreGameError.seedChanged
        }

        guard to.boardRules == from.boardRules else {
            throw CoreGameError.boardRulesChanged
        }

        let boardTransitionAllowed =
            isRobberMoveBoardTransition(from: from, to: to) ||
            isKnightDevCardBoardTransition(from: from, to: to)
        if !boardTransitionAllowed {
            guard to.board == from.board else {
                throw CoreGameError.boardChanged
            }
        } else if !isOnlyRobberTileChanged(from: from.board, to: to.board) {
            throw CoreGameError.boardChanged
        }
    }

    if !(from.phase == .lobby && to.phase == .lobby) {
        guard to.playerDisplayNamesByPlayer == from.playerDisplayNamesByPlayer else {
            throw CoreGameError.playerDisplayNamesChanged
        }
    }

    try validateOwnershipTransition(from: from, to: to, actor: actor, isStartTransition: isStartTransition)
    try validateTurnStepTransition(from: from, to: to)
    try validateTradeTransition(from: from, to: to)
    try validateDevCardTransition(from: from, to: to, isStartTransition: isStartTransition)
    try validateAwardTransition(from: from, to: to, isStartTransition: isStartTransition)
    try validateVictoryTransition(from: from, to: to, isStartTransition: isStartTransition)
    try validateAuditTransition(from: from, to: to, actor: actor)

    let expectedEconomy = expectedEconomyAfterTransition(
        from: from,
        to: to,
        actor: actor,
        isStartTransition: isStartTransition
    )
    guard to.resourcesByPlayer == expectedEconomy.resourcesByPlayer else {
        throw CoreGameError.resourcesByPlayerInvalid
    }
    guard to.bankResources == expectedEconomy.bankResources else {
        throw CoreGameError.bankResourcesInvalid
    }

    try validateStateHash(to)
}

private func isAuthorizedActorForTransition(
    from: CoreGameStateV1,
    to: CoreGameStateV1,
    actor: String
) -> Bool {
    if from.phase == .lobby, to.phase == .lobby {
        return isAuthorizedActorForLobbyTransition(from: from, to: to, actor: actor)
    }

    guard from.isActivePlayer(actor) else {
        return false
    }

    guard let expectedAction = try? expectedAuditActionForTransition(from: from, to: to) else {
        return actor == from.currentPlayer
    }

    switch expectedAction {
    case .submitDiscard:
        guard
            from.phase == .turn,
            to.phase == .turn || to.phase == .gameOver,
            from.currentPlayer == to.currentPlayer,
            from.turnState?.step == .pendingDiscards,
            let fromSubmitted = from.turnState?.submittedDiscardsByPlayer,
            let toSubmitted = to.turnState?.submittedDiscardsByPlayer
        else {
            return false
        }

        let newPlayers = Set(toSubmitted.keys).subtracting(fromSubmitted.keys)
        guard newPlayers.count == 1, let submittedPlayer = newPlayers.first else {
            return false
        }

        return submittedPlayer == actor
    case .acceptTrade, .declineTrade, .counterTrade:
        guard
            from.phase == .turn,
            to.phase == .turn || to.phase == .gameOver,
            from.currentPlayer == to.currentPlayer,
            from.turnState?.step == .afterRoll,
            let offer = from.activeTradeOffer
        else {
            return false
        }

        let priorPlayers = Set(from.tradeResponses.map(\.respondingPlayer))
        let newResponses = to.tradeResponses.filter { !priorPlayers.contains($0.respondingPlayer) }
        guard newResponses.count == 1, let response = newResponses.first else {
            return false
        }

        return response.respondingPlayer == actor &&
            response.offerHash == offer.offerHash &&
            offer.recipients.contains(actor)

    default:
        return actor == from.currentPlayer
    }
}

private func lifecycleStateChanged(
    from: CoreGameStateV1,
    to: CoreGameStateV1
) -> Bool {
    from.resignedPlayers != to.resignedPlayers
        || from.drawVote != to.drawVote
        || from.hasAttemptedDrawVote != to.hasAttemptedDrawVote
        || (to.phase == .gameOver && to.gameResult?.reason != .victory)
}

private func matchesLifecycleTransition(
    from: CoreGameStateV1,
    to: CoreGameStateV1,
    actor: String
) -> Bool {
    let intents: [GameLifecycleIntentV1] = [
        .resign(anchoredTo: from),
        .proposeDraw(anchoredTo: from),
        .voteDraw(approve: true, anchoredTo: from),
        .voteDraw(approve: false, anchoredTo: from),
        .endGame(anchoredTo: from),
    ]
    return intents.contains { intent in
        (try? apply(intent: intent, to: from, actor: actor)) == to
    }
}

private func isAuthorizedActorForLobbyTransition(
    from: CoreGameStateV1,
    to: CoreGameStateV1,
    actor: String
) -> Bool {
    let addedPlayers = Set(to.roster).subtracting(from.roster)
    if addedPlayers.isEmpty {
        return from.roster.contains(actor)
    }

    return addedPlayers == [actor] && !from.roster.contains(actor)
}

private func validateLobbyTransitionIfNeeded(
    from: CoreGameStateV1,
    to: CoreGameStateV1,
    actor: String
) throws -> LobbyTransitionKind? {
    guard from.phase == .lobby, to.phase == .lobby else {
        return nil
    }

    guard to.currentPlayer == from.currentPlayer else {
        throw CoreGameError.actorMismatch
    }
    guard to.seed == from.seed else {
        throw CoreGameError.seedChanged
    }
    guard to.boardRules == from.boardRules else {
        throw CoreGameError.boardRulesChanged
    }
    guard to.board == from.board else {
        throw CoreGameError.boardChanged
    }
    guard to.settlementsByNode == from.settlementsByNode else {
        throw CoreGameError.settlementsByNodeInvalid
    }
    guard to.citiesByNode == from.citiesByNode else {
        throw CoreGameError.citiesByNodeInvalid
    }
    guard to.roadsByEdge == from.roadsByEdge else {
        throw CoreGameError.roadsByEdgeInvalid
    }
    guard to.bankResources == from.bankResources else {
        throw CoreGameError.bankResourcesInvalid
    }
    guard to.devDeck == from.devDeck,
          to.devCardActionPlayedThisTurn == from.devCardActionPlayedThisTurn
    else {
        throw CoreGameError.devDeckInvalid
    }
    guard to.largestArmyOwner == from.largestArmyOwner,
          to.largestArmySize == from.largestArmySize,
          to.longestRoadOwner == from.longestRoadOwner,
          to.longestRoadLength == from.longestRoadLength
    else {
        throw CoreGameError.awardStateInvalid
    }
    guard to.winnerPlayer == from.winnerPlayer,
          to.winningVictoryPoints == from.winningVictoryPoints
    else {
        throw CoreGameError.victoryStateInvalid
    }
    guard to.activeTradeOffer == from.activeTradeOffer,
          to.tradeResponses == from.tradeResponses
    else {
        throw CoreGameError.tradeStateInvalid
    }
    guard to.auditLog == from.auditLog,
          to.lastTurnRecap == from.lastTurnRecap,
          to.lastTurnRecap == computeLastTurnRecap(from: to.auditLog)
    else {
        throw CoreGameError.auditLogInvalid
    }

    let transitionKind: LobbyTransitionKind
    if to.roster == from.roster {
        guard from.roster.contains(actor) else {
            throw CoreGameError.actorMismatch
        }
        try validateLobbyRenameDisplayNames(from: from, to: to, actor: actor)
        transitionKind = .rename
    } else {
        guard !from.roster.contains(actor), to.roster == from.roster + [actor] else {
            throw CoreGameError.rosterChanged
        }
        try validateLobbyJoinDisplayNames(from: from, to: to, actor: actor)
        transitionKind = .join(player: actor)
    }

    try validateLobbyDefaultMaps(from: from, to: to, transitionKind: transitionKind)
    return transitionKind
}

private func validateLobbyJoinDisplayNames(
    from: CoreGameStateV1,
    to: CoreGameStateV1,
    actor: String
) throws {
    for player in from.roster {
        guard to.playerDisplayNamesByPlayer[player] == from.playerDisplayNamesByPlayer[player] else {
            throw CoreGameError.playerDisplayNamesChanged
        }
    }

    let allowedPlayers = Set(from.roster + [actor])
    guard Set(to.playerDisplayNamesByPlayer.keys).isSubset(of: allowedPlayers) else {
        throw CoreGameError.playerDisplayNamesChanged
    }
}

private func validateLobbyRenameDisplayNames(
    from: CoreGameStateV1,
    to: CoreGameStateV1,
    actor: String
) throws {
    var changedPlayers: [String] = []
    for player in from.roster {
        if to.playerDisplayNamesByPlayer[player] != from.playerDisplayNamesByPlayer[player] {
            changedPlayers.append(player)
        }
    }

    guard changedPlayers == [actor] else {
        throw CoreGameError.playerDisplayNamesChanged
    }
    guard to.playerDisplayNamesByPlayer[actor] != nil else {
        throw CoreGameError.playerDisplayNamesChanged
    }
    guard Set(to.playerDisplayNamesByPlayer.keys).isSubset(of: Set(from.roster)) else {
        throw CoreGameError.playerDisplayNamesChanged
    }
}

private func validateLobbyDefaultMaps(
    from: CoreGameStateV1,
    to: CoreGameStateV1,
    transitionKind: LobbyTransitionKind
) throws {
    switch transitionKind {
    case .join(let player):
        guard mapAppendingDefault(from.resourcesByPlayer, player: player, defaultValue: .zero) == to.resourcesByPlayer else {
            throw CoreGameError.resourcesByPlayerInvalid
        }
        guard mapAppendingDefault(from.devCardsByPlayer, player: player, defaultValue: .zero) == to.devCardsByPlayer,
              mapAppendingDefault(from.newDevCardsByPlayer, player: player, defaultValue: .zero) == to.newDevCardsByPlayer,
              mapAppendingDefault(from.revealedVictoryPointsByPlayer, player: player, defaultValue: 0) == to.revealedVictoryPointsByPlayer,
              mapAppendingDefault(from.knightsPlayedByPlayer, player: player, defaultValue: 0) == to.knightsPlayedByPlayer
        else {
            throw CoreGameError.devDeckInvalid
        }

    case .rename:
        guard from.resourcesByPlayer == to.resourcesByPlayer else {
            throw CoreGameError.resourcesByPlayerInvalid
        }
        guard from.devCardsByPlayer == to.devCardsByPlayer,
              from.newDevCardsByPlayer == to.newDevCardsByPlayer,
              from.revealedVictoryPointsByPlayer == to.revealedVictoryPointsByPlayer,
              from.knightsPlayedByPlayer == to.knightsPlayedByPlayer
        else {
            throw CoreGameError.devDeckInvalid
        }
    }
}

private func mapAppendingDefault<Value: Equatable>(
    _ values: [String: Value],
    player: String,
    defaultValue: Value
) -> [String: Value] {
    var result = values
    result[player] = defaultValue
    return result
}

private func validateStateHash(_ state: CoreGameStateV1) throws {
    let expectedStateHash = state.rehashed().stateHash
    guard state.stateHash == expectedStateHash else {
        throw CoreGameError.invalidStateHash
    }
}

private func validateAwardTransition(
    from: CoreGameStateV1,
    to: CoreGameStateV1,
    isStartTransition: Bool
) throws {
    if isStartTransition {
        guard to.largestArmyOwner == nil, to.largestArmySize == 0 else {
            throw CoreGameError.awardStateInvalid
        }
        guard to.longestRoadOwner == nil, to.longestRoadLength == 0 else {
            throw CoreGameError.awardStateInvalid
        }
        return
    }

    guard
        (to.largestArmyOwner == nil || to.isActivePlayer(to.largestArmyOwner ?? "")),
        (to.longestRoadOwner == nil || to.isActivePlayer(to.longestRoadOwner ?? ""))
    else {
        throw CoreGameError.awardStateInvalid
    }

    let shouldRecomputeAwards =
        from.phase == .turn &&
        (to.phase == .turn || to.phase == .gameOver) &&
        from.currentPlayer == to.currentPlayer
    if !shouldRecomputeAwards {
        guard to.largestArmyOwner == from.largestArmyOwner else {
            throw CoreGameError.awardStateInvalid
        }
        guard to.largestArmySize == from.largestArmySize else {
            throw CoreGameError.awardStateInvalid
        }
        guard to.longestRoadOwner == from.longestRoadOwner else {
            throw CoreGameError.awardStateInvalid
        }
        guard to.longestRoadLength == from.longestRoadLength else {
            throw CoreGameError.awardStateInvalid
        }
        return
    }

    let expected = recomputeAwards(from: from, for: to)
    guard to.largestArmyOwner == expected.largestArmyOwner else {
        throw CoreGameError.awardStateInvalid
    }
    guard to.largestArmySize == expected.largestArmySize else {
        throw CoreGameError.awardStateInvalid
    }
    guard to.longestRoadOwner == expected.longestRoadOwner else {
        throw CoreGameError.awardStateInvalid
    }
    guard to.longestRoadLength == expected.longestRoadLength else {
        throw CoreGameError.awardStateInvalid
    }
}

private func validateVictoryTransition(
    from: CoreGameStateV1,
    to: CoreGameStateV1,
    isStartTransition: Bool
) throws {
    if isStartTransition {
        guard to.winnerPlayer == nil, to.winningVictoryPoints == 0, to.gameResult == nil else {
            throw CoreGameError.victoryStateInvalid
        }
        return
    }

    if to.phase != .gameOver {
        guard to.winnerPlayer == nil, to.winningVictoryPoints == 0, to.gameResult == nil else {
            throw CoreGameError.victoryStateInvalid
        }
        return
    }

    guard from.phase == .turn else {
        throw CoreGameError.victoryStateInvalid
    }
    guard to.currentPlayer == from.currentPlayer else {
        throw CoreGameError.victoryStateInvalid
    }
    guard let winner = to.winnerPlayer, winner == from.currentPlayer else {
        throw CoreGameError.victoryStateInvalid
    }
    guard
        to.gameResult?.reason == .victory,
        to.gameResult?.winnerPlayers == [winner],
        to.gameResult?.endedByPlayer == nil
    else {
        throw CoreGameError.victoryStateInvalid
    }

    let computedPoints = victoryPoints(for: winner, in: to)
    guard computedPoints >= 10 else {
        throw CoreGameError.victoryStateInvalid
    }
    guard to.winningVictoryPoints == computedPoints else {
        throw CoreGameError.victoryStateInvalid
    }
}

public func validateCanonicalSnapshot(_ state: CoreGameStateV1) throws {
    try validateStateHash(state)

    if let board = state.board, board.boardHash != board.rehashed().boardHash {
        throw CoreGameError.invalidBoardHash
    }

    guard state.roster.contains(state.currentPlayer) else {
        throw CoreGameError.turnCurrentPlayerNotInRoster
    }

    switch state.phase {
    case .lobby:
        guard state.setupState == nil else {
            throw CoreGameError.setupStateMissing
        }
        guard state.turnState == nil else {
            throw CoreGameError.turnStateUnexpected
        }
    case .setup:
        guard let setupState = state.setupState else {
            throw CoreGameError.setupStateMissing
        }
        guard state.turnState == nil else {
            throw CoreGameError.turnStateUnexpected
        }
        guard setupState.turnIndex >= 0, setupState.turnIndex < setupState.order.count else {
            throw CoreGameError.setupTurnIndexOutOfRange
        }
        guard state.currentPlayer == setupState.order[setupState.turnIndex] else {
            throw CoreGameError.setupCurrentPlayerMismatch
        }
    case .turn:
        guard state.setupState == nil else {
            throw CoreGameError.setupStateMissing
        }
        guard state.turnState != nil else {
            throw CoreGameError.turnStateMissing
        }
    case .gameOver:
        guard state.setupState == nil else {
            throw CoreGameError.setupStateMissing
        }
        guard state.turnState == nil else {
            throw CoreGameError.turnStateUnexpected
        }
    }

    guard state.resignedPlayers == state.roster.filter(state.resignedPlayers.contains) else {
        throw CoreGameError.gameResultInvalid
    }
    guard state.resignedPlayers.allSatisfy({ player in
        state.resourcesByPlayer[player] == .zero
            && state.devCardsByPlayer[player] == .zero
            && state.newDevCardsByPlayer[player] == .zero
            && state.revealedVictoryPointsByPlayer[player, default: 0] == 0
    }) else {
        throw CoreGameError.gameResultInvalid
    }
    guard
        state.largestArmyOwner.map(state.isActivePlayer) ?? true,
        state.longestRoadOwner.map(state.isActivePlayer) ?? true
    else {
        throw CoreGameError.awardStateInvalid
    }
    if let vote = state.drawVote {
        guard
            state.hasAttemptedDrawVote,
            state.isActivePlayer(vote.proposedBy),
            !vote.approvals.isEmpty,
            vote.approvals == state.activePlayers.filter(vote.approvals.contains),
            vote.approvals.contains(vote.proposedBy)
        else {
            throw CoreGameError.gameResultInvalid
        }
    }

    if state.phase != .gameOver {
        guard
            state.gameResult == nil,
            state.winnerPlayer == nil,
            state.winningVictoryPoints == 0,
            state.isActivePlayer(state.currentPlayer)
        else {
            throw CoreGameError.gameResultInvalid
        }
        return
    }

    guard let result = state.gameResult else {
        throw CoreGameError.gameResultInvalid
    }
    guard
        state.setupState == nil,
        state.turnState == nil,
        state.drawVote == nil,
        state.activeTradeOffer == nil,
        state.tradeResponses.isEmpty
    else {
        throw CoreGameError.gameResultInvalid
    }
    guard result.winnerPlayers.allSatisfy(state.isActivePlayer) else {
        throw CoreGameError.gameResultInvalid
    }
    guard result.finalScoresByPlayer == victoryPointsByPlayer(in: state) else {
        throw CoreGameError.gameResultInvalid
    }

    switch result.reason {
    case .victory:
        guard
            result.endedByPlayer == nil,
            result.winnerPlayers.count == 1,
            let winner = result.winnerPlayers.first,
            winner == state.currentPlayer,
            state.winnerPlayer == winner,
            victoryPoints(for: winner, in: state) >= 10,
            state.winningVictoryPoints == victoryPoints(for: winner, in: state)
        else {
            throw CoreGameError.gameResultInvalid
        }
    case .draw:
        guard
            result.winnerPlayers.isEmpty,
            result.endedByPlayer == nil,
            state.winnerPlayer == nil,
            state.winningVictoryPoints == 0,
            state.hasAttemptedDrawVote
        else {
            throw CoreGameError.gameResultInvalid
        }
    case .hostEnded:
        guard
            result.winnerPlayers.isEmpty,
            result.endedByPlayer == state.hostPlayer,
            state.winnerPlayer == nil,
            state.winningVictoryPoints == 0
        else {
            throw CoreGameError.gameResultInvalid
        }
    }
}

private func validateOwnershipTransition(
    from: CoreGameStateV1,
    to: CoreGameStateV1,
    actor: String,
    isStartTransition: Bool
) throws {
    if isStartTransition {
        guard to.settlementsByNode.isEmpty else {
            throw CoreGameError.settlementsByNodeInvalid
        }
        guard to.citiesByNode.isEmpty else {
            throw CoreGameError.citiesByNodeInvalid
        }
        guard to.roadsByEdge.isEmpty else {
            throw CoreGameError.roadsByEdgeInvalid
        }
        return
    }

    if to.phase == .setup {
        guard let setupState = to.setupState else {
            throw CoreGameError.setupStateMissing
        }
        let ownership = ownershipFromSetupPlacements(setupState.placements)
        guard to.settlementsByNode == ownership.settlementsByNode else {
            throw CoreGameError.settlementsByNodeInvalid
        }
        guard to.citiesByNode.isEmpty else {
            throw CoreGameError.citiesByNodeInvalid
        }
        guard to.roadsByEdge == ownership.roadsByEdge else {
            throw CoreGameError.roadsByEdgeInvalid
        }
        return
    }

    if from.phase == .setup, to.phase == .turn {
        try validateSetupCompletionOwnership(from: from, to: to, actor: actor)
        return
    }

    if from.phase == .turn, (to.phase == .turn || to.phase == .gameOver), from.currentPlayer == to.currentPlayer {
        if try validateTurnBuildOwnershipTransitionIfAny(from: from, to: to, actor: actor) {
            return
        }
    }

    guard to.settlementsByNode == from.settlementsByNode else {
        throw CoreGameError.settlementsByNodeInvalid
    }
    guard to.citiesByNode == from.citiesByNode else {
        throw CoreGameError.citiesByNodeInvalid
    }
    guard to.roadsByEdge == from.roadsByEdge else {
        throw CoreGameError.roadsByEdgeInvalid
    }
}

private func validateTurnBuildOwnershipTransitionIfAny(
    from: CoreGameStateV1,
    to: CoreGameStateV1,
    actor: String
) throws -> Bool {
    let ownershipUnchanged =
        from.settlementsByNode == to.settlementsByNode &&
        from.citiesByNode == to.citiesByNode &&
        from.roadsByEdge == to.roadsByEdge
    if ownershipUnchanged {
        return false
    }

    guard actor == from.currentPlayer else {
        throw CoreGameError.actorMismatch
    }
    guard from.turnState?.step == .afterRoll else {
        throw CoreGameError.turnStepMismatch
    }
    if to.phase == .turn {
        guard from.turnState == to.turnState else {
            throw CoreGameError.turnStepMismatch
        }
    } else if to.phase == .gameOver {
        guard to.turnState == nil else {
            throw CoreGameError.turnStepMismatch
        }
    } else {
        throw CoreGameError.turnStepMismatch
    }

    for (node, owner) in from.settlementsByNode where to.settlementsByNode[node] != nil && to.settlementsByNode[node] != owner {
        _ = node
        throw CoreGameError.settlementsByNodeInvalid
    }
    for (node, owner) in from.citiesByNode where to.citiesByNode[node] != nil && to.citiesByNode[node] != owner {
        _ = node
        throw CoreGameError.citiesByNodeInvalid
    }
    for (edge, owner) in from.roadsByEdge where to.roadsByEdge[edge] != nil && to.roadsByEdge[edge] != owner {
        _ = edge
        throw CoreGameError.roadsByEdgeInvalid
    }

    let addedSettlements = to.settlementsByNode.filter { from.settlementsByNode[$0.key] == nil }
    let removedSettlements = from.settlementsByNode.filter { to.settlementsByNode[$0.key] == nil }
    let addedCities = to.citiesByNode.filter { from.citiesByNode[$0.key] == nil }
    let removedCities = from.citiesByNode.filter { to.citiesByNode[$0.key] == nil }
    let addedRoads = to.roadsByEdge.filter { from.roadsByEdge[$0.key] == nil }
    let removedRoads = from.roadsByEdge.filter { to.roadsByEdge[$0.key] == nil }

    if !addedRoads.isEmpty || !removedRoads.isEmpty {
        guard removedRoads.isEmpty else {
            throw CoreGameError.roadsByEdgeInvalid
        }
        guard addedSettlements.isEmpty, removedSettlements.isEmpty, addedCities.isEmpty, removedCities.isEmpty else {
            throw CoreGameError.roadsByEdgeInvalid
        }

        let roadCount = from.roadsByEdge.values.filter { $0 == actor }.count
        for (edge, owner) in addedRoads {
            guard owner == actor else {
                throw CoreGameError.roadsByEdgeInvalid
            }
            guard edge >= 0, edge < validationTopology.edges.count else {
                throw CoreGameError.invalidEdge
            }
        }

        if addedRoads.count == 1 {
            guard roadCount < 15, let edge = addedRoads.first?.key else {
                throw CoreGameError.roadsByEdgeInvalid
            }
            guard isRoadConnectedForBuildValidation(edgeID: edge, player: actor, state: from) else {
                throw CoreGameError.roadsByEdgeInvalid
            }
            return true
        }

        if addedRoads.count == 2, isRoadBuildingOwnershipTransition(from: from, to: to, actor: actor) {
            guard roadCount <= 13 else {
                throw CoreGameError.roadsByEdgeInvalid
            }
            let edges = addedRoads.map(\.key)
            guard canPlaceTwoConnectedRoadsForValidation(edges: edges, player: actor, from: from) else {
                throw CoreGameError.roadsByEdgeInvalid
            }
            return true
        }

        throw CoreGameError.roadsByEdgeInvalid
    }

    if !addedCities.isEmpty || !removedSettlements.isEmpty || !removedCities.isEmpty {
        guard addedCities.count == 1, removedSettlements.count == 1, removedCities.isEmpty else {
            throw CoreGameError.citiesByNodeInvalid
        }
        guard addedRoads.isEmpty, removedRoads.isEmpty, addedSettlements.isEmpty else {
            throw CoreGameError.citiesByNodeInvalid
        }
        guard let (cityNode, cityOwner) = addedCities.first, cityOwner == actor else {
            throw CoreGameError.citiesByNodeInvalid
        }
        guard let (settlementNode, settlementOwner) = removedSettlements.first, settlementOwner == actor else {
            throw CoreGameError.settlementsByNodeInvalid
        }
        guard cityNode == settlementNode else {
            throw CoreGameError.citiesByNodeInvalid
        }
        let cityCount = from.citiesByNode.values.filter { $0 == actor }.count
        guard cityCount < 4 else {
            throw CoreGameError.citiesByNodeInvalid
        }
        return true
    }

    if !addedSettlements.isEmpty || !removedSettlements.isEmpty {
        guard addedSettlements.count == 1, removedSettlements.isEmpty else {
            throw CoreGameError.settlementsByNodeInvalid
        }
        guard addedRoads.isEmpty, removedRoads.isEmpty, addedCities.isEmpty, removedCities.isEmpty else {
            throw CoreGameError.settlementsByNodeInvalid
        }
        guard let (node, owner) = addedSettlements.first, owner == actor else {
            throw CoreGameError.settlementsByNodeInvalid
        }
        guard node >= 0, node < validationTopology.nodesCount else {
            throw CoreGameError.invalidNode
        }
        guard from.citiesByNode[node] == nil else {
            throw CoreGameError.nodeOccupied
        }
        let occupiedNodes = Set(from.settlementsByNode.keys).union(Set(from.citiesByNode.keys))
        let adjacentNodes = Set(validationTopology.nodes(adjacentTo: node))
        if !adjacentNodes.isDisjoint(with: occupiedNodes) {
            throw CoreGameError.distanceRuleViolation
        }
        let settlementCount = from.settlementsByNode.values.filter { $0 == actor }.count
        guard settlementCount < 5 else {
            throw CoreGameError.settlementsByNodeInvalid
        }
        guard isSettlementConnectedForBuildValidation(nodeID: node, player: actor, state: from) else {
            throw CoreGameError.settlementsByNodeInvalid
        }
        return true
    }

    throw CoreGameError.roadsByEdgeInvalid
}

private func validateSetupCompletionOwnership(from: CoreGameStateV1, to: CoreGameStateV1, actor: String) throws {
    guard let setupState = from.setupState else {
        throw CoreGameError.setupStateMissing
    }

    let ownership = ownershipFromSetupPlacements(setupState.placements)
    for (node, owner) in ownership.settlementsByNode {
        guard to.settlementsByNode[node] == owner else {
            throw CoreGameError.settlementsByNodeInvalid
        }
    }
    for (edge, owner) in ownership.roadsByEdge {
        guard to.roadsByEdge[edge] == owner else {
            throw CoreGameError.roadsByEdgeInvalid
        }
    }

    guard to.citiesByNode == from.citiesByNode else {
        throw CoreGameError.citiesByNodeInvalid
    }

    let addedSettlements = to.settlementsByNode.filter { ownership.settlementsByNode[$0.key] == nil }
    let addedRoads = to.roadsByEdge.filter { ownership.roadsByEdge[$0.key] == nil }

    switch setupState.step {
    case .placeRoad:
        guard addedSettlements.isEmpty else {
            throw CoreGameError.settlementsByNodeInvalid
        }
        guard addedRoads.count == 1, let (newRoad, newRoadOwner) = addedRoads.first else {
            throw CoreGameError.roadsByEdgeInvalid
        }
        guard newRoadOwner == actor else {
            throw CoreGameError.roadsByEdgeInvalid
        }
        guard let anchorSettlement = setupState.lastPlacedSettlementNode else {
            throw CoreGameError.roadBeforeSettlement
        }
        try validateRoad(edge: newRoad, incidentTo: anchorSettlement)

    case .placeSettlement:
        guard addedSettlements.count == 1, let (newSettlement, newSettlementOwner) = addedSettlements.first else {
            throw CoreGameError.settlementsByNodeInvalid
        }
        guard newSettlementOwner == actor else {
            throw CoreGameError.settlementsByNodeInvalid
        }
        try validateSettlement(node: newSettlement, occupiedNodes: Set(ownership.settlementsByNode.keys))

        guard addedRoads.count == 1, let (newRoad, newRoadOwner) = addedRoads.first else {
            throw CoreGameError.roadsByEdgeInvalid
        }
        guard newRoadOwner == actor else {
            throw CoreGameError.roadsByEdgeInvalid
        }
        try validateRoad(edge: newRoad, incidentTo: newSettlement)

    case .done:
        throw CoreGameError.setupStepMismatch
    }
}

private func validateTurnStepTransition(from: CoreGameStateV1, to: CoreGameStateV1) throws {
    guard from.phase == .turn, to.phase == .turn else {
        return
    }
    guard let fromTurn = from.turnState, let toTurn = to.turnState else {
        throw CoreGameError.turnStateMissing
    }

    if fromTurn == toTurn {
        return
    }

    if from.currentPlayer != to.currentPlayer {
        guard fromTurn.step == .afterRoll else {
            throw CoreGameError.turnStepMismatch
        }
        guard toTurn.step == .needsRoll else {
            throw CoreGameError.turnStepMismatch
        }
        guard toTurn.lastRoll == nil else {
            throw CoreGameError.turnStepMismatch
        }
        guard toTurn.discardRequirementsByPlayer.isEmpty else {
            throw CoreGameError.turnStepMismatch
        }
        guard toTurn.submittedDiscardsByPlayer.isEmpty else {
            throw CoreGameError.turnStepMismatch
        }
        guard toTurn.eligibleStealVictims.isEmpty else {
            throw CoreGameError.turnStepMismatch
        }
        return
    }

    switch (fromTurn.step, toTurn.step) {
    case (.needsRoll, .afterRoll):
        guard let roll = toTurn.lastRoll else {
            throw CoreGameError.turnStepMismatch
        }
        guard roll.d1 + roll.d2 != 7 else {
            throw CoreGameError.turnStepMismatch
        }
        guard toTurn.discardRequirementsByPlayer.isEmpty else {
            throw CoreGameError.turnStepMismatch
        }
        guard toTurn.submittedDiscardsByPlayer.isEmpty else {
            throw CoreGameError.turnStepMismatch
        }
        guard toTurn.eligibleStealVictims.isEmpty else {
            throw CoreGameError.turnStepMismatch
        }

    case (.needsRoll, .pendingDiscards), (.needsRoll, .needsRobberMove):
        guard let roll = toTurn.lastRoll, roll.d1 + roll.d2 == 7 else {
            throw CoreGameError.turnStepMismatch
        }

        let expectedRequirements = requiredDiscardsForValidation(
            from.resourcesByPlayer,
            players: from.activePlayers
        )
        guard toTurn.discardRequirementsByPlayer == expectedRequirements else {
            throw CoreGameError.turnStepMismatch
        }
        guard toTurn.submittedDiscardsByPlayer.isEmpty else {
            throw CoreGameError.turnStepMismatch
        }
        guard toTurn.eligibleStealVictims.isEmpty else {
            throw CoreGameError.turnStepMismatch
        }
        if toTurn.step == .pendingDiscards {
            guard !expectedRequirements.isEmpty else {
                throw CoreGameError.turnStepMismatch
            }
        } else {
            guard expectedRequirements.isEmpty else {
                throw CoreGameError.turnStepMismatch
            }
        }

    case (.pendingDiscards, .pendingDiscards), (.pendingDiscards, .needsRobberMove):
        guard toTurn.lastRoll == fromTurn.lastRoll else {
            throw CoreGameError.turnStepMismatch
        }
        guard toTurn.discardRequirementsByPlayer == fromTurn.discardRequirementsByPlayer else {
            throw CoreGameError.turnStepMismatch
        }

        let fromSubmitted = fromTurn.submittedDiscardsByPlayer
        let toSubmitted = toTurn.submittedDiscardsByPlayer
        let newPlayers = Set(toSubmitted.keys).subtracting(fromSubmitted.keys)
        guard newPlayers.count == 1, let newPlayer = newPlayers.first else {
            throw CoreGameError.turnStepMismatch
        }
        guard fromTurn.discardRequirementsByPlayer[newPlayer] != nil else {
            throw CoreGameError.turnStepMismatch
        }
        guard nextPendingDiscardPlayer(roster: from.roster, turnState: fromTurn) == newPlayer else {
            throw CoreGameError.discardSubmissionOutOfOrder
        }
        guard toSubmitted.count == fromSubmitted.count + 1 else {
            throw CoreGameError.turnStepMismatch
        }
        for (player, submitted) in fromSubmitted {
            guard toSubmitted[player] == submitted else {
                throw CoreGameError.turnStepMismatch
            }
        }

        guard let newDiscard = toSubmitted[newPlayer] else {
            throw CoreGameError.turnStepMismatch
        }
        guard isNonNegative(newDiscard) else {
            throw CoreGameError.turnStepMismatch
        }
        guard newDiscard.totalCount == fromTurn.discardRequirementsByPlayer[newPlayer] else {
            throw CoreGameError.turnStepMismatch
        }
        guard toTurn.eligibleStealVictims.isEmpty else {
            throw CoreGameError.turnStepMismatch
        }

        let allSubmitted = fromTurn.discardRequirementsByPlayer.keys.allSatisfy { toSubmitted[$0] != nil }
        guard (toTurn.step == .needsRobberMove) == allSubmitted else {
            throw CoreGameError.turnStepMismatch
        }

    case (.needsRobberMove, .afterRoll), (.needsRobberMove, .needsRobberSteal):
        guard toTurn.lastRoll == fromTurn.lastRoll else {
            throw CoreGameError.turnStepMismatch
        }
        guard toTurn.discardRequirementsByPlayer.isEmpty else {
            throw CoreGameError.turnStepMismatch
        }
        guard toTurn.submittedDiscardsByPlayer.isEmpty else {
            throw CoreGameError.turnStepMismatch
        }
        if toTurn.step == .afterRoll {
            guard toTurn.eligibleStealVictims.isEmpty else {
                throw CoreGameError.turnStepMismatch
            }
        } else {
            guard !toTurn.eligibleStealVictims.isEmpty else {
                throw CoreGameError.turnStepMismatch
            }
        }

    case (.needsRobberSteal, .afterRoll):
        guard toTurn.lastRoll == fromTurn.lastRoll else {
            throw CoreGameError.turnStepMismatch
        }
        guard toTurn.discardRequirementsByPlayer.isEmpty else {
            throw CoreGameError.turnStepMismatch
        }
        guard toTurn.submittedDiscardsByPlayer.isEmpty else {
            throw CoreGameError.turnStepMismatch
        }
        guard toTurn.eligibleStealVictims.isEmpty else {
            throw CoreGameError.turnStepMismatch
        }

    default:
        throw CoreGameError.turnStepMismatch
    }
}

private func expectedEconomyAfterTransition(
    from: CoreGameStateV1,
    to: CoreGameStateV1,
    actor: String,
    isStartTransition: Bool
) -> EconomyUpdateV1 {
    if isStartTransition {
        return EconomyUpdateV1(
            resourcesByPlayer: Dictionary(uniqueKeysWithValues: to.roster.map { ($0, .zero) }),
            bankResources: .standardBank
        )
    }

    if let startingResourceNode = startingResourceSettlementNodeGrantedDuringTransition(from: from, to: to, actor: actor) {
        return applyStartingSettlementPayout(
            player: actor,
            settlementNode: startingResourceNode,
            board: from.board,
            resourcesByPlayer: from.resourcesByPlayer,
            bankResources: from.bankResources
        )
    }

    if
        from.phase == .turn,
        to.phase == .turn,
        from.turnState?.step == .needsRoll,
        to.turnState?.step == .afterRoll,
        to.currentPlayer == from.currentPlayer,
        let lastRoll = to.turnState?.lastRoll
    {
        return applyProductionPayout(
            rollTotal: lastRoll.d1 + lastRoll.d2,
            board: from.board,
            settlementsByNode: from.settlementsByNode,
            citiesByNode: from.citiesByNode,
            resourcesByPlayer: from.resourcesByPlayer,
            bankResources: from.bankResources,
            eligiblePlayers: Set(from.activePlayers)
        )
    }

    if
        from.phase == .turn,
        (to.phase == .turn || to.phase == .gameOver),
        to.currentPlayer == from.currentPlayer
    {
        let original = EconomyUpdateV1(resourcesByPlayer: from.resourcesByPlayer, bankResources: from.bankResources)
        let discardUpdate = expectedEconomyAfterDiscardSubmissionIfAny(from: from, to: to)
        if discardUpdate.resourcesByPlayer != original.resourcesByPlayer || discardUpdate.bankResources != original.bankResources {
            return discardUpdate
        }
        let stealUpdate = expectedEconomyAfterRobberStealIfAny(from: from, to: to)
        if stealUpdate.resourcesByPlayer != original.resourcesByPlayer || stealUpdate.bankResources != original.bankResources {
            return stealUpdate
        }
        let tradeExecutionUpdate = expectedEconomyAfterTradeExecutionIfAny(from: from, to: to)
        if tradeExecutionUpdate.resourcesByPlayer != original.resourcesByPlayer ||
            tradeExecutionUpdate.bankResources != original.bankResources
        {
            return tradeExecutionUpdate
        }
        let devCardUpdate = expectedEconomyAfterDevCardIfAny(from: from, to: to)
        if devCardUpdate.resourcesByPlayer != original.resourcesByPlayer ||
            devCardUpdate.bankResources != original.bankResources
        {
            return devCardUpdate
        }
        let maritimeUpdate = expectedEconomyAfterMaritimeTradeIfAny(from: from, to: to)
        if maritimeUpdate.resourcesByPlayer != original.resourcesByPlayer ||
            maritimeUpdate.bankResources != original.bankResources
        {
            return maritimeUpdate
        }
        let buildUpdate = expectedEconomyAfterBuildIfAny(from: from, to: to)
        if buildUpdate.resourcesByPlayer != original.resourcesByPlayer || buildUpdate.bankResources != original.bankResources {
            return buildUpdate
        }
        return original
    }

    return EconomyUpdateV1(resourcesByPlayer: from.resourcesByPlayer, bankResources: from.bankResources)
}

private func isAfterRollEconomyTransition(from: CoreGameStateV1, to: CoreGameStateV1) -> Bool {
    guard
        from.phase == .turn,
        (to.phase == .turn || to.phase == .gameOver),
        from.currentPlayer == to.currentPlayer,
        from.turnState?.step == .afterRoll
    else {
        return false
    }

    if to.phase == .turn {
        return from.turnState == to.turnState
    }
    return to.turnState == nil
}

func isDevCardPlayWindowStep(_ step: TurnStepV1?) -> Bool {
    guard let step else {
        return false
    }
    return step.allowsDevCardPlay
}

private func isDevCardPlayEconomyTransition(from: CoreGameStateV1, to: CoreGameStateV1) -> Bool {
    guard
        from.phase == .turn,
        (to.phase == .turn || to.phase == .gameOver),
        from.currentPlayer == to.currentPlayer,
        isDevCardPlayWindowStep(from.turnState?.step)
    else {
        return false
    }

    if to.phase == .turn {
        return isDevCardPlayWindowStep(to.turnState?.step)
    }
    return to.turnState == nil
}

private func expectedEconomyAfterDiscardSubmissionIfAny(from: CoreGameStateV1, to: CoreGameStateV1) -> EconomyUpdateV1 {
    guard
        let fromTurn = from.turnState,
        let toTurn = to.turnState,
        fromTurn.step == .pendingDiscards,
        toTurn.step == .pendingDiscards || toTurn.step == .needsRobberMove
    else {
        return EconomyUpdateV1(resourcesByPlayer: from.resourcesByPlayer, bankResources: from.bankResources)
    }

    let fromSubmitted = fromTurn.submittedDiscardsByPlayer
    let toSubmitted = toTurn.submittedDiscardsByPlayer
    let newPlayers = Set(toSubmitted.keys).subtracting(fromSubmitted.keys)
    guard newPlayers.count == 1, let newPlayer = newPlayers.first, let discarded = toSubmitted[newPlayer] else {
        return EconomyUpdateV1(resourcesByPlayer: from.resourcesByPlayer, bankResources: from.bankResources)
    }

    let playerHand = from.resourcesByPlayer[newPlayer] ?? .zero
    guard
        discarded.wood <= playerHand.wood,
        discarded.brick <= playerHand.brick,
        discarded.sheep <= playerHand.sheep,
        discarded.wheat <= playerHand.wheat,
        discarded.ore <= playerHand.ore
    else {
        return EconomyUpdateV1(resourcesByPlayer: from.resourcesByPlayer, bankResources: from.bankResources)
    }

    var updatedResourcesByPlayer = from.resourcesByPlayer
    updatedResourcesByPlayer[newPlayer] = ResourceHandV1(
        wood: playerHand.wood - discarded.wood,
        brick: playerHand.brick - discarded.brick,
        sheep: playerHand.sheep - discarded.sheep,
        wheat: playerHand.wheat - discarded.wheat,
        ore: playerHand.ore - discarded.ore
    )

    let updatedBankResources = ResourceHandV1(
        wood: from.bankResources.wood + discarded.wood,
        brick: from.bankResources.brick + discarded.brick,
        sheep: from.bankResources.sheep + discarded.sheep,
        wheat: from.bankResources.wheat + discarded.wheat,
        ore: from.bankResources.ore + discarded.ore
    )

    return EconomyUpdateV1(resourcesByPlayer: updatedResourcesByPlayer, bankResources: updatedBankResources)
}

private func expectedEconomyAfterRobberStealIfAny(from: CoreGameStateV1, to: CoreGameStateV1) -> EconomyUpdateV1 {
    guard
        let fromTurn = from.turnState,
        let toTurn = to.turnState,
        fromTurn.step == .needsRobberSteal,
        toTurn.step == .afterRoll,
        let robberRngState = from.robberRngState
    else {
        return EconomyUpdateV1(resourcesByPlayer: from.resourcesByPlayer, bankResources: from.bankResources)
    }

    let stealer = from.currentPlayer
    let stealerBefore = from.resourcesByPlayer[stealer] ?? .zero
    let stealerAfter = to.resourcesByPlayer[stealer] ?? .zero
    guard stealerAfter.totalCount == stealerBefore.totalCount + 1 else {
        return EconomyUpdateV1(resourcesByPlayer: from.resourcesByPlayer, bankResources: from.bankResources)
    }

    let victimCandidates = fromTurn.eligibleStealVictims.filter { victim in
        let before = from.resourcesByPlayer[victim] ?? .zero
        let after = to.resourcesByPlayer[victim] ?? .zero
        return after.totalCount == before.totalCount - 1
    }
    guard victimCandidates.count == 1, let victim = victimCandidates.first else {
        return EconomyUpdateV1(resourcesByPlayer: from.resourcesByPlayer, bankResources: from.bankResources)
    }

    for player in from.roster where player != stealer && player != victim {
        guard to.resourcesByPlayer[player] == from.resourcesByPlayer[player] else {
            return EconomyUpdateV1(resourcesByPlayer: from.resourcesByPlayer, bankResources: from.bankResources)
        }
    }

    let victimBefore = from.resourcesByPlayer[victim] ?? .zero
    guard victimBefore.totalCount > 0 else {
        return EconomyUpdateV1(resourcesByPlayer: from.resourcesByPlayer, bankResources: from.bankResources)
    }

    var rng = DeterministicRNG(seed: robberRngState)
    let stolenResource = deterministicStolenResourceForValidation(from: victimBefore, rng: &rng)

    var expectedResourcesByPlayer = from.resourcesByPlayer
    expectedResourcesByPlayer[stealer] = stealerBefore.addingOne(for: stolenResource)
    expectedResourcesByPlayer[victim] = victimBefore.subtracting(1, for: stolenResource)

    return EconomyUpdateV1(resourcesByPlayer: expectedResourcesByPlayer, bankResources: from.bankResources)
}

private func expectedEconomyAfterBuildIfAny(from: CoreGameStateV1, to: CoreGameStateV1) -> EconomyUpdateV1 {
    guard
        isAfterRollEconomyTransition(from: from, to: to),
        from.devCardsByPlayer == to.devCardsByPlayer,
        from.newDevCardsByPlayer == to.newDevCardsByPlayer,
        from.revealedVictoryPointsByPlayer == to.revealedVictoryPointsByPlayer,
        from.devCardActionPlayedThisTurn == to.devCardActionPlayedThisTurn,
        from.knightsPlayedByPlayer == to.knightsPlayedByPlayer
    else {
        return EconomyUpdateV1(resourcesByPlayer: from.resourcesByPlayer, bankResources: from.bankResources)
    }

    let roadsChanged = from.roadsByEdge != to.roadsByEdge
    let settlementsChanged = from.settlementsByNode != to.settlementsByNode
    let citiesChanged = from.citiesByNode != to.citiesByNode
    let changeCount = [roadsChanged, settlementsChanged, citiesChanged].filter { $0 }.count
    if changeCount == 0 {
        return EconomyUpdateV1(resourcesByPlayer: from.resourcesByPlayer, bankResources: from.bankResources)
    }

    let cost: ResourceHandV1
    if roadsChanged && !settlementsChanged && !citiesChanged {
        cost = CoreBuildCostsV1.road
    } else if settlementsChanged && !roadsChanged && !citiesChanged {
        cost = CoreBuildCostsV1.settlement
    } else if settlementsChanged && citiesChanged && !roadsChanged {
        cost = CoreBuildCostsV1.city
    } else {
        return EconomyUpdateV1(resourcesByPlayer: from.resourcesByPlayer, bankResources: from.bankResources)
    }

    let player = from.currentPlayer
    let hand = from.resourcesByPlayer[player] ?? .zero
    guard
        hand.wood >= cost.wood,
        hand.brick >= cost.brick,
        hand.sheep >= cost.sheep,
        hand.wheat >= cost.wheat,
        hand.ore >= cost.ore
    else {
        return EconomyUpdateV1(resourcesByPlayer: from.resourcesByPlayer, bankResources: from.bankResources)
    }

    var resourcesByPlayer = from.resourcesByPlayer
    resourcesByPlayer[player] = ResourceHandV1(
        wood: hand.wood - cost.wood,
        brick: hand.brick - cost.brick,
        sheep: hand.sheep - cost.sheep,
        wheat: hand.wheat - cost.wheat,
        ore: hand.ore - cost.ore
    )
    let bank = from.bankResources
    let bankResources = ResourceHandV1(
        wood: bank.wood + cost.wood,
        brick: bank.brick + cost.brick,
        sheep: bank.sheep + cost.sheep,
        wheat: bank.wheat + cost.wheat,
        ore: bank.ore + cost.ore
    )
    return EconomyUpdateV1(resourcesByPlayer: resourcesByPlayer, bankResources: bankResources)
}

private func expectedEconomyAfterMaritimeTradeIfAny(from: CoreGameStateV1, to: CoreGameStateV1) -> EconomyUpdateV1 {
    guard
        isAfterRollEconomyTransition(from: from, to: to),
        from.board == to.board,
        from.activeTradeOffer == to.activeTradeOffer,
        from.tradeResponses == to.tradeResponses,
        from.devDeck == to.devDeck,
        from.devCardsByPlayer == to.devCardsByPlayer,
        from.newDevCardsByPlayer == to.newDevCardsByPlayer,
        from.revealedVictoryPointsByPlayer == to.revealedVictoryPointsByPlayer,
        from.devCardActionPlayedThisTurn == to.devCardActionPlayedThisTurn,
        from.knightsPlayedByPlayer == to.knightsPlayedByPlayer,
        from.settlementsByNode == to.settlementsByNode,
        from.citiesByNode == to.citiesByNode,
        from.roadsByEdge == to.roadsByEdge,
        let board = from.board
    else {
        return EconomyUpdateV1(resourcesByPlayer: from.resourcesByPlayer, bankResources: from.bankResources)
    }

    let player = from.currentPlayer
    let playerHand = from.resourcesByPlayer[player] ?? .zero
    for giveResource in [ResourceV1.wood, .brick, .sheep, .wheat, .ore] {
        let ratio = bestMaritimeTradeRatioForValidation(
            player: player,
            giveResource: giveResource,
            board: board,
            settlementsByNode: from.settlementsByNode,
            citiesByNode: from.citiesByNode
        )
        guard playerHand.count(for: giveResource) >= ratio else {
            continue
        }

        for receiveResource in [ResourceV1.wood, .brick, .sheep, .wheat, .ore] where receiveResource != giveResource {
            guard from.bankResources.count(for: receiveResource) >= 1 else {
                continue
            }

            var expectedResourcesByPlayer = from.resourcesByPlayer
            expectedResourcesByPlayer[player] = playerHand
                .subtracting(ratio, for: giveResource)
                .adding(1, for: receiveResource)
            let expectedBank = from.bankResources
                .adding(ratio, for: giveResource)
                .subtracting(1, for: receiveResource)

            if to.resourcesByPlayer == expectedResourcesByPlayer && to.bankResources == expectedBank {
                return EconomyUpdateV1(
                    resourcesByPlayer: expectedResourcesByPlayer,
                    bankResources: expectedBank
                )
            }
        }
    }

    return EconomyUpdateV1(resourcesByPlayer: from.resourcesByPlayer, bankResources: from.bankResources)
}

func expectedEconomyAfterTradeExecutionIfAny(from: CoreGameStateV1, to: CoreGameStateV1) -> EconomyUpdateV1 {
    guard
        isAfterRollEconomyTransition(from: from, to: to),
        let offer = from.activeTradeOffer,
        to.activeTradeOffer == nil
    else {
        return EconomyUpdateV1(resourcesByPlayer: from.resourcesByPlayer, bankResources: from.bankResources)
    }

    let acceptedPlayers = Set(
        to.tradeResponses
            .filter { $0.offerHash == offer.offerHash && $0.kind == .accept }
            .map(\.respondingPlayer)
    )

    for acceptor in acceptedPlayers {
        let proposer = from.currentPlayer
        let proposerHand = from.resourcesByPlayer[proposer] ?? .zero
        let acceptorHand = from.resourcesByPlayer[acceptor] ?? .zero
        guard
            canAffordForValidation(hand: proposerHand, cost: offer.give),
            canAffordForValidation(hand: acceptorHand, cost: offer.receive)
        else {
            continue
        }

        var expectedResourcesByPlayer = from.resourcesByPlayer
        expectedResourcesByPlayer[proposer] = addHandsForValidation(
            subtractHandsForValidation(proposerHand, offer.give),
            offer.receive
        )
        expectedResourcesByPlayer[acceptor] = addHandsForValidation(
            subtractHandsForValidation(acceptorHand, offer.receive),
            offer.give
        )

        if to.resourcesByPlayer == expectedResourcesByPlayer {
            return EconomyUpdateV1(
                resourcesByPlayer: expectedResourcesByPlayer,
                bankResources: from.bankResources
            )
        }
    }

    return EconomyUpdateV1(resourcesByPlayer: from.resourcesByPlayer, bankResources: from.bankResources)
}

private func expectedEconomyAfterDevCardIfAny(from: CoreGameStateV1, to: CoreGameStateV1) -> EconomyUpdateV1 {
    guard
        isDevCardPlayEconomyTransition(from: from, to: to)
    else {
        return EconomyUpdateV1(resourcesByPlayer: from.resourcesByPlayer, bankResources: from.bankResources)
    }

    let player = from.currentPlayer
    let original = EconomyUpdateV1(resourcesByPlayer: from.resourcesByPlayer, bankResources: from.bankResources)

    if to.devDeck.count == from.devDeck.count - 1, Array(from.devDeck.dropFirst()) == to.devDeck {
        let cost = CoreBuildCostsV1.developmentCard
        let hand = from.resourcesByPlayer[player] ?? .zero
        guard canAffordForValidation(hand: hand, cost: cost) else {
            return original
        }
        var expectedResourcesByPlayer = from.resourcesByPlayer
        expectedResourcesByPlayer[player] = subtractHandsForValidation(hand, cost)
        let bank = from.bankResources
        let expectedBank = addHandsForValidation(bank, cost)
        return EconomyUpdateV1(resourcesByPlayer: expectedResourcesByPlayer, bankResources: expectedBank)
    }

    for resource in [ResourceV1.wood, .brick, .sheep, .wheat, .ore] {
        var expectedResourcesByPlayer = from.resourcesByPlayer
        var collected = 0
        for other in from.roster where other != player {
            let hand = expectedResourcesByPlayer[other] ?? .zero
            let amount = hand.count(for: resource)
            if amount > 0 {
                expectedResourcesByPlayer[other] = hand.subtracting(amount, for: resource)
                collected += amount
            }
        }
        let playerHand = expectedResourcesByPlayer[player] ?? .zero
        expectedResourcesByPlayer[player] = playerHand.adding(collected, for: resource)
        if to.resourcesByPlayer == expectedResourcesByPlayer && to.bankResources == from.bankResources {
            return EconomyUpdateV1(resourcesByPlayer: expectedResourcesByPlayer, bankResources: from.bankResources)
        }
    }

    let resources: [ResourceV1] = [.wood, .brick, .sheep, .wheat, .ore]
    for first in resources {
        for second in resources {
            let requiredSecond = first == second ? 2 : 1
            guard from.bankResources.count(for: first) >= 1,
                  from.bankResources.count(for: second) >= requiredSecond else {
                continue
            }
            var expectedResourcesByPlayer = from.resourcesByPlayer
            let hand = expectedResourcesByPlayer[player] ?? .zero
            expectedResourcesByPlayer[player] = hand.adding(1, for: first).adding(1, for: second)
            let expectedBank = from.bankResources.subtracting(1, for: first).subtracting(1, for: second)
            if to.resourcesByPlayer == expectedResourcesByPlayer && to.bankResources == expectedBank {
                return EconomyUpdateV1(resourcesByPlayer: expectedResourcesByPlayer, bankResources: expectedBank)
            }
        }
    }

    if
        let fromBoard = from.board,
        let toBoard = to.board,
        fromBoard.robberTile != toBoard.robberTile,
        let robberSeed = from.robberRngState
    {
        let victims = eligibleRobberVictimsForValidation(
            tileID: toBoard.robberTile,
            settlementsByNode: from.settlementsByNode,
            citiesByNode: from.citiesByNode,
            resourcesByPlayer: from.resourcesByPlayer,
            currentPlayer: player,
            eligiblePlayers: Set(from.activePlayers)
        )
        if victims.isEmpty {
            if to.resourcesByPlayer == from.resourcesByPlayer && to.bankResources == from.bankResources {
                return original
            }
        } else {
            for victim in victims {
                let victimHand = from.resourcesByPlayer[victim] ?? .zero
                guard victimHand.totalCount > 0 else {
                    continue
                }
                var rng = DeterministicRNG(seed: robberSeed)
                let stolen = deterministicStolenResourceForValidation(from: victimHand, rng: &rng)
                var expectedResourcesByPlayer = from.resourcesByPlayer
                expectedResourcesByPlayer[player] = (from.resourcesByPlayer[player] ?? .zero).addingOne(for: stolen)
                expectedResourcesByPlayer[victim] = victimHand.subtracting(1, for: stolen)
                if to.resourcesByPlayer == expectedResourcesByPlayer && to.bankResources == from.bankResources {
                    return EconomyUpdateV1(resourcesByPlayer: expectedResourcesByPlayer, bankResources: from.bankResources)
                }
            }
        }
    }

    return original
}

private func startingResourceSettlementNodeGrantedDuringTransition(
    from: CoreGameStateV1,
    to: CoreGameStateV1,
    actor: String
) -> NodeID? {
    guard from.phase == .setup, let fromSetupState = from.setupState else {
        return nil
    }

    if
        fromSetupState.step == .placeRoad,
        let placement = fromSetupState.placements[actor],
        placement.road1 != nil,
        placement.road2 == nil,
        let settlement2 = placement.settlement2
    {
        return settlement2
    }

    if fromSetupState.step != .placeSettlement {
        return nil
    }

    let before = fromSetupState.placements[actor] ?? PlayerSetupPlacementsV1()
    guard before.road1 != nil, before.road2 == nil, before.settlement2 == nil else {
        return nil
    }

    if
        let toSetupState = to.setupState,
        let after = toSetupState.placements[actor],
        after.road2 != nil,
        let settlement2 = after.settlement2
    {
        return settlement2
    }

    if to.phase == .turn {
        let existing = ownershipFromSetupPlacements(fromSetupState.placements).settlementsByNode
        let added = to.settlementsByNode.filter { existing[$0.key] == nil && $0.value == actor }
        if added.count == 1, let node = added.first?.key {
            return node
        }
    }

    return nil
}

private func validateSettlement(node: NodeID, occupiedNodes: Set<NodeID>) throws {
    guard node >= 0, node < validationTopology.nodesCount else {
        throw CoreGameError.invalidNode
    }
    guard !occupiedNodes.contains(node) else {
        throw CoreGameError.nodeOccupied
    }
    let adjacentNodes = Set(validationTopology.nodes(adjacentTo: node))
    if !adjacentNodes.isDisjoint(with: occupiedNodes) {
        throw CoreGameError.distanceRuleViolation
    }
}

private func validateRoad(edge: EdgeID, incidentTo settlementNode: NodeID) throws {
    guard edge >= 0, edge < validationTopology.edges.count else {
        throw CoreGameError.invalidEdge
    }
    let road = validationTopology.edges[edge]
    guard road.a == settlementNode || road.b == settlementNode else {
        throw CoreGameError.roadNotAdjacentToLastSettlement
    }
}

private func ownershipFromSetupPlacements(_ placements: [String: PlayerSetupPlacementsV1]) -> (
    settlementsByNode: [NodeID: String],
    roadsByEdge: [EdgeID: String]
) {
    var settlementsByNode: [NodeID: String] = [:]
    var roadsByEdge: [EdgeID: String] = [:]

    for (player, placement) in placements {
        if let settlement1 = placement.settlement1 {
            settlementsByNode[settlement1] = player
        }
        if let settlement2 = placement.settlement2 {
            settlementsByNode[settlement2] = player
        }
        if let road1 = placement.road1 {
            roadsByEdge[road1] = player
        }
        if let road2 = placement.road2 {
            roadsByEdge[road2] = player
        }
    }

    return (settlementsByNode, roadsByEdge)
}

private func requiredDiscardsForValidation(
    _ resourcesByPlayer: [String: ResourceHandV1],
    players: [String]
) -> [String: Int] {
    var result: [String: Int] = [:]
    for player in players {
        let hand = resourcesByPlayer[player] ?? .zero
        if hand.totalCount > 7 {
            result[player] = hand.totalCount / 2
        }
    }
    return result
}

private func isNonNegative(_ hand: ResourceHandV1) -> Bool {
    hand.wood >= 0 && hand.brick >= 0 && hand.sheep >= 0 && hand.wheat >= 0 && hand.ore >= 0
}

private func isRobberMoveBoardTransition(from: CoreGameStateV1, to: CoreGameStateV1) -> Bool {
    guard
        from.phase == .turn,
        to.phase == .turn,
        from.currentPlayer == to.currentPlayer,
        from.turnState?.step == .needsRobberMove,
        to.turnState?.step == .afterRoll || to.turnState?.step == .needsRobberSteal
    else {
        return false
    }
    return true
}

private func isKnightDevCardBoardTransition(from: CoreGameStateV1, to: CoreGameStateV1) -> Bool {
    guard
        from.phase == .turn,
        to.phase == .turn || to.phase == .gameOver,
        from.currentPlayer == to.currentPlayer,
        isDevCardPlayWindowStep(from.turnState?.step),
        (to.phase == .turn && isDevCardPlayWindowStep(to.turnState?.step)) || (to.phase == .gameOver && to.turnState == nil)
    else {
        return false
    }
    return isKnightDevCardTransition(from: from, to: to, actor: from.currentPlayer)
}

private func isOnlyRobberTileChanged(from: BoardSetupV1?, to: BoardSetupV1?) -> Bool {
    guard let from, let to else {
        return false
    }
    guard
        from.resourcesByTile == to.resourcesByTile,
        from.numbersByTile == to.numbersByTile,
        from.portsByIndex == to.portsByIndex,
        from.generator == to.generator
    else {
        return false
    }
    guard from.robberTile != to.robberTile else {
        return false
    }
    guard to.robberTile >= 0, to.robberTile < to.resourcesByTile.count else {
        return false
    }
    return true
}

func isKnightDevCardTransition(from: CoreGameStateV1, to: CoreGameStateV1, actor: String) -> Bool {
    guard from.currentPlayer == actor, to.currentPlayer == actor else {
        return false
    }
    guard from.devDeck == to.devDeck else {
        return false
    }
    guard from.newDevCardsByPlayer == to.newDevCardsByPlayer else {
        return false
    }
    guard from.revealedVictoryPointsByPlayer == to.revealedVictoryPointsByPlayer else {
        return false
    }
    guard to.devCardActionPlayedThisTurn else {
        return false
    }

    for player in from.roster where player != actor {
        guard from.devCardsByPlayer[player] == to.devCardsByPlayer[player] else {
            return false
        }
        guard from.knightsPlayedByPlayer[player] == to.knightsPlayedByPlayer[player] else {
            return false
        }
    }

    let fromInventory = from.devCardsByPlayer[actor] ?? .zero
    let toInventory = to.devCardsByPlayer[actor] ?? .zero
    guard fromInventory.knight == toInventory.knight + 1 else {
        return false
    }
    guard fromInventory.monopoly == toInventory.monopoly else {
        return false
    }
    guard fromInventory.yearOfPlenty == toInventory.yearOfPlenty else {
        return false
    }
    guard fromInventory.roadBuilding == toInventory.roadBuilding else {
        return false
    }
    guard fromInventory.victoryPoint == toInventory.victoryPoint else {
        return false
    }

    return (to.knightsPlayedByPlayer[actor] ?? 0) == (from.knightsPlayedByPlayer[actor] ?? 0) + 1
}

func isMonopolyDevCardTransitionForAudit(from: CoreGameStateV1, to: CoreGameStateV1) -> Bool {
    guard from.currentPlayer == to.currentPlayer else {
        return false
    }
    let actor = from.currentPlayer
    guard from.devDeck == to.devDeck else {
        return false
    }
    guard from.newDevCardsByPlayer == to.newDevCardsByPlayer else {
        return false
    }
    guard from.revealedVictoryPointsByPlayer == to.revealedVictoryPointsByPlayer else {
        return false
    }
    guard from.knightsPlayedByPlayer == to.knightsPlayedByPlayer else {
        return false
    }
    guard to.devCardActionPlayedThisTurn else {
        return false
    }

    for player in from.roster where player != actor {
        guard from.devCardsByPlayer[player] == to.devCardsByPlayer[player] else {
            return false
        }
    }

    let fromInventory = from.devCardsByPlayer[actor] ?? .zero
    let toInventory = to.devCardsByPlayer[actor] ?? .zero
    return
        fromInventory.monopoly == toInventory.monopoly + 1 &&
        fromInventory.knight == toInventory.knight &&
        fromInventory.yearOfPlenty == toInventory.yearOfPlenty &&
        fromInventory.roadBuilding == toInventory.roadBuilding &&
        fromInventory.victoryPoint == toInventory.victoryPoint
}

func isYearOfPlentyDevCardTransitionForAudit(from: CoreGameStateV1, to: CoreGameStateV1) -> Bool {
    guard from.currentPlayer == to.currentPlayer else {
        return false
    }
    let actor = from.currentPlayer
    guard from.devDeck == to.devDeck else {
        return false
    }
    guard from.newDevCardsByPlayer == to.newDevCardsByPlayer else {
        return false
    }
    guard from.revealedVictoryPointsByPlayer == to.revealedVictoryPointsByPlayer else {
        return false
    }
    guard from.knightsPlayedByPlayer == to.knightsPlayedByPlayer else {
        return false
    }
    guard to.devCardActionPlayedThisTurn else {
        return false
    }

    for player in from.roster where player != actor {
        guard from.devCardsByPlayer[player] == to.devCardsByPlayer[player] else {
            return false
        }
    }

    let fromInventory = from.devCardsByPlayer[actor] ?? .zero
    let toInventory = to.devCardsByPlayer[actor] ?? .zero
    return
        fromInventory.yearOfPlenty == toInventory.yearOfPlenty + 1 &&
        fromInventory.knight == toInventory.knight &&
        fromInventory.monopoly == toInventory.monopoly &&
        fromInventory.roadBuilding == toInventory.roadBuilding &&
        fromInventory.victoryPoint == toInventory.victoryPoint
}

func isRoadBuildingDevCardTransitionForAudit(from: CoreGameStateV1, to: CoreGameStateV1) -> Bool {
    guard from.currentPlayer == to.currentPlayer else {
        return false
    }
    let actor = from.currentPlayer
    guard from.devDeck == to.devDeck else {
        return false
    }
    guard from.newDevCardsByPlayer == to.newDevCardsByPlayer else {
        return false
    }
    guard from.revealedVictoryPointsByPlayer == to.revealedVictoryPointsByPlayer else {
        return false
    }
    guard from.knightsPlayedByPlayer == to.knightsPlayedByPlayer else {
        return false
    }
    guard to.devCardActionPlayedThisTurn else {
        return false
    }

    for player in from.roster where player != actor {
        guard from.devCardsByPlayer[player] == to.devCardsByPlayer[player] else {
            return false
        }
    }

    let fromInventory = from.devCardsByPlayer[actor] ?? .zero
    let toInventory = to.devCardsByPlayer[actor] ?? .zero
    return
        fromInventory.roadBuilding == toInventory.roadBuilding + 1 &&
        fromInventory.knight == toInventory.knight &&
        fromInventory.monopoly == toInventory.monopoly &&
        fromInventory.yearOfPlenty == toInventory.yearOfPlenty &&
        fromInventory.victoryPoint == toInventory.victoryPoint
}

func isRevealVictoryPointTransitionForAudit(from: CoreGameStateV1, to: CoreGameStateV1) -> Bool {
    guard from.currentPlayer == to.currentPlayer else {
        return false
    }
    let actor = from.currentPlayer
    guard victoryPoints(for: actor, in: to) >= 10 else {
        return false
    }
    guard from.devDeck == to.devDeck else {
        return false
    }
    guard from.knightsPlayedByPlayer == to.knightsPlayedByPlayer else {
        return false
    }
    guard from.devCardActionPlayedThisTurn == to.devCardActionPlayedThisTurn else {
        return false
    }

    for player in from.roster where player != actor {
        guard from.devCardsByPlayer[player] == to.devCardsByPlayer[player] else {
            return false
        }
        guard from.newDevCardsByPlayer[player] == to.newDevCardsByPlayer[player] else {
            return false
        }
        guard from.revealedVictoryPointsByPlayer[player] == to.revealedVictoryPointsByPlayer[player] else {
            return false
        }
    }

    guard (to.revealedVictoryPointsByPlayer[actor] ?? 0) == (from.revealedVictoryPointsByPlayer[actor] ?? 0) + 1 else {
        return false
    }

    let fromDev = from.devCardsByPlayer[actor] ?? .zero
    let toDev = to.devCardsByPlayer[actor] ?? .zero
    let fromNew = from.newDevCardsByPlayer[actor] ?? .zero
    let toNew = to.newDevCardsByPlayer[actor] ?? .zero

    let playableReveal =
        fromDev.victoryPoint == toDev.victoryPoint + 1 &&
        fromNew == toNew &&
        fromDev.knight == toDev.knight &&
        fromDev.monopoly == toDev.monopoly &&
        fromDev.yearOfPlenty == toDev.yearOfPlenty &&
        fromDev.roadBuilding == toDev.roadBuilding

    let newReveal =
        fromNew.victoryPoint == toNew.victoryPoint + 1 &&
        fromDev == toDev &&
        fromNew.knight == toNew.knight &&
        fromNew.monopoly == toNew.monopoly &&
        fromNew.yearOfPlenty == toNew.yearOfPlenty &&
        fromNew.roadBuilding == toNew.roadBuilding

    return playableReveal || newReveal
}

func isBuildRoadTransitionForAudit(from: CoreGameStateV1, to: CoreGameStateV1) -> Bool {
    guard isBuildTransitionStableForAudit(from: from, to: to) else {
        return false
    }
    guard from.settlementsByNode == to.settlementsByNode else {
        return false
    }
    guard from.citiesByNode == to.citiesByNode else {
        return false
    }
    guard to.roadsByEdge.count == from.roadsByEdge.count + 1 else {
        return false
    }

    for (edge, owner) in from.roadsByEdge {
        guard to.roadsByEdge[edge] == owner else {
            return false
        }
    }
    let added = to.roadsByEdge.filter { from.roadsByEdge[$0.key] == nil }
    return added.count == 1 && added.first?.value == from.currentPlayer
}

func isBuildSettlementTransitionForAudit(from: CoreGameStateV1, to: CoreGameStateV1) -> Bool {
    guard isBuildTransitionStableForAudit(from: from, to: to) else {
        return false
    }
    guard from.roadsByEdge == to.roadsByEdge else {
        return false
    }
    guard from.citiesByNode == to.citiesByNode else {
        return false
    }
    guard to.settlementsByNode.count == from.settlementsByNode.count + 1 else {
        return false
    }

    for (node, owner) in from.settlementsByNode {
        guard to.settlementsByNode[node] == owner else {
            return false
        }
    }
    let added = to.settlementsByNode.filter { from.settlementsByNode[$0.key] == nil }
    return added.count == 1 && added.first?.value == from.currentPlayer
}

func isBuildCityTransitionForAudit(from: CoreGameStateV1, to: CoreGameStateV1) -> Bool {
    guard isBuildTransitionStableForAudit(from: from, to: to) else {
        return false
    }
    guard from.roadsByEdge == to.roadsByEdge else {
        return false
    }
    guard to.settlementsByNode.count + 1 == from.settlementsByNode.count else {
        return false
    }
    guard to.citiesByNode.count == from.citiesByNode.count + 1 else {
        return false
    }

    let removedSettlements = from.settlementsByNode.filter { to.settlementsByNode[$0.key] == nil }
    let addedCities = to.citiesByNode.filter { from.citiesByNode[$0.key] == nil }
    guard removedSettlements.count == 1, addedCities.count == 1 else {
        return false
    }
    guard let removedSettlement = removedSettlements.first, let addedCity = addedCities.first else {
        return false
    }
    return
        removedSettlement.key == addedCity.key &&
        removedSettlement.value == from.currentPlayer &&
        addedCity.value == from.currentPlayer
}

private func isBuildTransitionStableForAudit(from: CoreGameStateV1, to: CoreGameStateV1) -> Bool {
    guard from.currentPlayer == to.currentPlayer else {
        return false
    }
    guard from.phase == .turn, to.phase == .turn || to.phase == .gameOver else {
        return false
    }
    guard from.turnState?.step == .afterRoll else {
        return false
    }
    if to.phase == .turn {
        guard to.turnState == from.turnState else {
            return false
        }
    } else {
        guard to.turnState == nil else {
            return false
        }
    }
    guard from.board == to.board else {
        return false
    }
    guard from.activeTradeOffer == to.activeTradeOffer else {
        return false
    }
    guard from.tradeResponses == to.tradeResponses else {
        return false
    }
    guard from.devDeck == to.devDeck else {
        return false
    }
    guard from.devCardsByPlayer == to.devCardsByPlayer else {
        return false
    }
    guard from.newDevCardsByPlayer == to.newDevCardsByPlayer else {
        return false
    }
    guard from.revealedVictoryPointsByPlayer == to.revealedVictoryPointsByPlayer else {
        return false
    }
    guard from.devCardActionPlayedThisTurn == to.devCardActionPlayedThisTurn else {
        return false
    }
    guard from.knightsPlayedByPlayer == to.knightsPlayedByPlayer else {
        return false
    }
    return true
}

func isMaritimeTradeTransitionForAudit(from: CoreGameStateV1, to: CoreGameStateV1) -> Bool {
    guard from.currentPlayer == to.currentPlayer else {
        return false
    }
    guard from.phase == .turn, to.phase == .turn else {
        return false
    }
    guard from.turnState?.step == .afterRoll, to.turnState == from.turnState else {
        return false
    }
    guard from.board == to.board else {
        return false
    }
    guard from.settlementsByNode == to.settlementsByNode else {
        return false
    }
    guard from.citiesByNode == to.citiesByNode else {
        return false
    }
    guard from.roadsByEdge == to.roadsByEdge else {
        return false
    }
    guard from.activeTradeOffer == to.activeTradeOffer else {
        return false
    }
    guard from.tradeResponses == to.tradeResponses else {
        return false
    }
    guard from.devDeck == to.devDeck else {
        return false
    }
    guard from.devCardsByPlayer == to.devCardsByPlayer else {
        return false
    }
    guard from.newDevCardsByPlayer == to.newDevCardsByPlayer else {
        return false
    }
    guard from.revealedVictoryPointsByPlayer == to.revealedVictoryPointsByPlayer else {
        return false
    }
    guard from.devCardActionPlayedThisTurn == to.devCardActionPlayedThisTurn else {
        return false
    }
    guard from.knightsPlayedByPlayer == to.knightsPlayedByPlayer else {
        return false
    }

    return from.resourcesByPlayer != to.resourcesByPlayer || from.bankResources != to.bankResources
}

private func deterministicStolenResourceForValidation(from hand: ResourceHandV1, rng: inout DeterministicRNG) -> ResourceV1 {
    let total = hand.totalCount
    let pick = Int(rng.nextUInt64() % UInt64(total))

    let ordered: [(ResourceV1, Int)] = [
        (.wood, hand.wood),
        (.brick, hand.brick),
        (.sheep, hand.sheep),
        (.wheat, hand.wheat),
        (.ore, hand.ore),
    ]

    var cursor = 0
    for (resource, count) in ordered {
        if pick < cursor + count {
            return resource
        }
        cursor += count
    }
    return .wood
}

private func eligibleRobberVictimsForValidation(
    tileID: Int,
    settlementsByNode: [NodeID: String],
    citiesByNode: [NodeID: String],
    resourcesByPlayer: [String: ResourceHandV1],
    currentPlayer: String,
    eligiblePlayers: Set<String>
) -> [String] {
    guard tileID >= 0, tileID < validationTopology.tiles.count else {
        return []
    }

    var victims: Set<String> = []
    for node in validationTopology.tiles[tileID].nodes {
        if let cityOwner = citiesByNode[node],
           cityOwner != currentPlayer,
           eligiblePlayers.contains(cityOwner),
           (resourcesByPlayer[cityOwner] ?? .zero).totalCount > 0
        {
            victims.insert(cityOwner)
            continue
        }

        if let settlementOwner = settlementsByNode[node],
           settlementOwner != currentPlayer,
           eligiblePlayers.contains(settlementOwner),
           (resourcesByPlayer[settlementOwner] ?? .zero).totalCount > 0
        {
            victims.insert(settlementOwner)
        }
    }

    return victims.sorted()
}

private func isRoadBuildingOwnershipTransition(from: CoreGameStateV1, to: CoreGameStateV1, actor: String) -> Bool {
    guard from.currentPlayer == actor, to.currentPlayer == actor else {
        return false
    }
    guard from.devDeck == to.devDeck else {
        return false
    }
    guard from.newDevCardsByPlayer == to.newDevCardsByPlayer else {
        return false
    }
    guard from.revealedVictoryPointsByPlayer == to.revealedVictoryPointsByPlayer else {
        return false
    }
    guard from.knightsPlayedByPlayer == to.knightsPlayedByPlayer else {
        return false
    }
    guard to.devCardActionPlayedThisTurn else {
        return false
    }

    for player in from.roster where player != actor {
        guard from.devCardsByPlayer[player] == to.devCardsByPlayer[player] else {
            return false
        }
    }

    let fromInventory = from.devCardsByPlayer[actor] ?? .zero
    let toInventory = to.devCardsByPlayer[actor] ?? .zero
    return fromInventory.roadBuilding == toInventory.roadBuilding + 1 &&
        fromInventory.knight == toInventory.knight &&
        fromInventory.monopoly == toInventory.monopoly &&
        fromInventory.yearOfPlenty == toInventory.yearOfPlenty &&
        fromInventory.victoryPoint == toInventory.victoryPoint
}

private func canPlaceTwoConnectedRoadsForValidation(
    edges: [EdgeID],
    player: String,
    from state: CoreGameStateV1
) -> Bool {
    guard edges.count == 2, edges[0] != edges[1] else {
        return false
    }

    func canPlaceInOrder(_ first: EdgeID, _ second: EdgeID) -> Bool {
        guard isRoadConnectedForBuildValidation(edgeID: first, player: player, state: state) else {
            return false
        }

        var roads = state.roadsByEdge
        roads[first] = player
        let withFirstRoad = validationStateWithRoads(state: state, roadsByEdge: roads)
        return isRoadConnectedForBuildValidation(edgeID: second, player: player, state: withFirstRoad)
    }

    return canPlaceInOrder(edges[0], edges[1]) || canPlaceInOrder(edges[1], edges[0])
}

private func validationStateWithRoads(state: CoreGameStateV1, roadsByEdge: [EdgeID: String]) -> CoreGameStateV1 {
    CoreGameStateV1(
        gameId: state.gameId,
        rev: state.rev,
        prevHash: state.prevHash,
        stateHash: state.stateHash,
        roster: state.roster,
        currentPlayer: state.currentPlayer,
        playerDisplayNamesByPlayer: state.playerDisplayNamesByPlayer,
        phase: state.phase,
        seed: state.seed,
        diceRngState: state.diceRngState,
        robberRngState: state.robberRngState,
        resourcesByPlayer: state.resourcesByPlayer,
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
        roadsByEdge: roadsByEdge,
        boardRules: state.boardRules,
        board: state.board,
        setupState: state.setupState,
        turnState: state.turnState
    )
}

private func isRoadConnectedForBuildValidation(edgeID: Int, player: String, state: CoreGameStateV1) -> Bool {
    let edge = validationTopology.edges[edgeID]
    let nodes = [edge.a, edge.b]
    for node in nodes {
        if state.settlementsByNode[node] == player || state.citiesByNode[node] == player {
            return true
        }
        if state.settlementsByNode[node] != nil || state.citiesByNode[node] != nil {
            continue
        }
        for adjacentEdge in validationTopology.edges(incidentTo: node) where adjacentEdge != edgeID {
            if state.roadsByEdge[adjacentEdge] == player {
                return true
            }
        }
    }
    return false
}

private func isSettlementConnectedForBuildValidation(nodeID: Int, player: String, state: CoreGameStateV1) -> Bool {
    for edge in validationTopology.edges(incidentTo: nodeID) {
        if state.roadsByEdge[edge] == player {
            return true
        }
    }
    return false
}

func isValidTradeHandForValidation(_ hand: ResourceHandV1) -> Bool {
    hand.wood >= 0 &&
        hand.brick >= 0 &&
        hand.sheep >= 0 &&
        hand.wheat >= 0 &&
        hand.ore >= 0
}

private func bestMaritimeTradeRatioForValidation(
    player: String,
    giveResource: ResourceV1,
    board: BoardSetupV1,
    settlementsByNode: [NodeID: String],
    citiesByNode: [NodeID: String]
) -> Int {
    var hasThreeToOne = false
    var hasMatchingTwoToOne = false

    for portIndex in board.portsByIndex.indices {
        guard portIndex < validationTopology.ports.count else {
            continue
        }
        let port = validationTopology.ports[portIndex]
        let edge = validationTopology.edges[port.edge]
        let ownsPort =
            settlementsByNode[edge.a] == player ||
            settlementsByNode[edge.b] == player ||
            citiesByNode[edge.a] == player ||
            citiesByNode[edge.b] == player
        if !ownsPort {
            continue
        }

        switch board.portsByIndex[portIndex] {
        case .threeToOne:
            hasThreeToOne = true
        case let .twoToOne(resource):
            if resource == giveResource {
                hasMatchingTwoToOne = true
            }
        }
    }

    if hasMatchingTwoToOne {
        return 2
    }
    if hasThreeToOne {
        return 3
    }
    return 4
}

func canAffordForValidation(hand: ResourceHandV1, cost: ResourceHandV1) -> Bool {
    hand.wood >= cost.wood &&
        hand.brick >= cost.brick &&
        hand.sheep >= cost.sheep &&
        hand.wheat >= cost.wheat &&
        hand.ore >= cost.ore
}

private func addHandsForValidation(_ lhs: ResourceHandV1, _ rhs: ResourceHandV1) -> ResourceHandV1 {
    ResourceHandV1(
        wood: lhs.wood + rhs.wood,
        brick: lhs.brick + rhs.brick,
        sheep: lhs.sheep + rhs.sheep,
        wheat: lhs.wheat + rhs.wheat,
        ore: lhs.ore + rhs.ore
    )
}

private func subtractHandsForValidation(_ lhs: ResourceHandV1, _ rhs: ResourceHandV1) -> ResourceHandV1 {
    ResourceHandV1(
        wood: lhs.wood - rhs.wood,
        brick: lhs.brick - rhs.brick,
        sheep: lhs.sheep - rhs.sheep,
        wheat: lhs.wheat - rhs.wheat,
        ore: lhs.ore - rhs.ore
    )
}

func isNonNegativeInventory(_ value: DevCardInventoryV1) -> Bool {
    value.knight >= 0 &&
        value.monopoly >= 0 &&
        value.yearOfPlenty >= 0 &&
        value.roadBuilding >= 0 &&
        value.victoryPoint >= 0
}

func mergeDevInventoriesForValidation(
    _ lhs: DevCardInventoryV1,
    _ rhs: DevCardInventoryV1
) -> DevCardInventoryV1 {
    DevCardInventoryV1(
        knight: lhs.knight + rhs.knight,
        monopoly: lhs.monopoly + rhs.monopoly,
        yearOfPlenty: lhs.yearOfPlenty + rhs.yearOfPlenty,
        roadBuilding: lhs.roadBuilding + rhs.roadBuilding,
        victoryPoint: lhs.victoryPoint + rhs.victoryPoint
    )
}
