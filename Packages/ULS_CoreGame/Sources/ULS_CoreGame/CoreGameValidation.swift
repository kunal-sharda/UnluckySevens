import Foundation

private let validationTopology = StandardBoardTopologyV1.standard()

public enum CoreGameError: Error, Equatable {
    case revMismatch
    case prevHashMismatch
    case actorMismatch
    case rosterChanged
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
    case tradeAcceptMissing
    case tradeExecutionInsufficientResources
    case tradeStateInvalid
    case devDeckInvalid
    case devDeckEmpty
    case devCardPurchaseInsufficientResources
    case devCardAlreadyPlayedThisTurn
    case devCardNotOwned
    case devCardPayloadInvalid
}

public func validateTransition(from: CoreGameStateV1, to: CoreGameStateV1, actor: String) throws {
    guard to.gameId == from.gameId else {
        throw CoreGameError.gameIdMismatch
    }

    guard to.rev == from.rev + 1 else {
        throw CoreGameError.revMismatch
    }

    guard to.prevHash == from.stateHash else {
        throw CoreGameError.prevHashMismatch
    }

    guard actor == from.currentPlayer else {
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

    let isStartTransition = from.phase == .lobby && to.phase == .setup
    if !isStartTransition {
        guard to.roster == from.roster else {
            throw CoreGameError.rosterChanged
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

    try validateOwnershipTransition(from: from, to: to, actor: actor, isStartTransition: isStartTransition)
    try validateTurnStepTransition(from: from, to: to)
    try validateTradeTransition(from: from, to: to)
    try validateDevCardTransition(from: from, to: to, isStartTransition: isStartTransition)

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

    let expectedStateHash = to.rehashed().stateHash
    guard to.stateHash == expectedStateHash else {
        throw CoreGameError.invalidStateHash
    }
}

private func validateTradeTransition(from: CoreGameStateV1, to: CoreGameStateV1) throws {
    if to.phase != .turn {
        guard to.activeTradeOffer == nil, to.pendingTradeAccepts.isEmpty else {
            throw CoreGameError.tradeStateInvalid
        }
        return
    }

    guard from.phase == .turn else {
        guard to.activeTradeOffer == nil, to.pendingTradeAccepts.isEmpty else {
            throw CoreGameError.tradeStateInvalid
        }
        return
    }

    if from.currentPlayer != to.currentPlayer {
        guard to.activeTradeOffer == nil, to.pendingTradeAccepts.isEmpty else {
            throw CoreGameError.tradeStateInvalid
        }
        return
    }

    if from.activeTradeOffer == to.activeTradeOffer, from.pendingTradeAccepts == to.pendingTradeAccepts {
        return
    }

    guard from.turnState?.step == .afterRoll, to.turnState?.step == .afterRoll else {
        throw CoreGameError.tradeStateInvalid
    }

    if from.activeTradeOffer == nil {
        guard let offer = to.activeTradeOffer else {
            throw CoreGameError.tradeStateInvalid
        }
        guard to.pendingTradeAccepts.isEmpty else {
            throw CoreGameError.tradeStateInvalid
        }
        guard offer.proposer == from.currentPlayer else {
            throw CoreGameError.tradeStateInvalid
        }
        guard
            isValidTradeHandForValidation(offer.give),
            isValidTradeHandForValidation(offer.receive),
            offer.give.totalCount > 0,
            offer.receive.totalCount > 0,
            offer.give != offer.receive
        else {
            throw CoreGameError.tradeStateInvalid
        }
        guard canAffordForValidation(hand: from.resourcesByPlayer[from.currentPlayer] ?? .zero, cost: offer.give) else {
            throw CoreGameError.tradeStateInvalid
        }
        let expectedHash = deterministicTradeOfferHash(
            gameId: from.gameId,
            proposer: from.currentPlayer,
            give: offer.give,
            receive: offer.receive,
            anchorRev: from.rev,
            anchorHash: from.stateHash
        )
        guard offer.offerHash == expectedHash else {
            throw CoreGameError.tradeStateInvalid
        }
        guard offer.createdRev == to.rev else {
            throw CoreGameError.tradeStateInvalid
        }
        return
    }

    guard let fromOffer = from.activeTradeOffer else {
        throw CoreGameError.tradeStateInvalid
    }
    if to.activeTradeOffer == nil {
        guard to.pendingTradeAccepts.isEmpty else {
            throw CoreGameError.tradeStateInvalid
        }
        guard !from.pendingTradeAccepts.isEmpty else {
            throw CoreGameError.tradeStateInvalid
        }
        guard to.resourcesByPlayer != from.resourcesByPlayer else {
            throw CoreGameError.tradeStateInvalid
        }
        return
    }

    guard to.activeTradeOffer == fromOffer else {
        throw CoreGameError.tradeStateInvalid
    }

    for priorAccept in from.pendingTradeAccepts {
        guard to.pendingTradeAccepts.contains(priorAccept) else {
            throw CoreGameError.tradeStateInvalid
        }
    }

    let priorPlayers = Set(from.pendingTradeAccepts.map(\.acceptingPlayer))
    let newAccepts = to.pendingTradeAccepts.filter { !priorPlayers.contains($0.acceptingPlayer) }
    guard newAccepts.count == 1, let addedAccept = newAccepts.first else {
        throw CoreGameError.tradeStateInvalid
    }
    guard addedAccept.offerHash == fromOffer.offerHash else {
        throw CoreGameError.tradeStateInvalid
    }
    guard addedAccept.acceptedAtRev == to.rev else {
        throw CoreGameError.tradeStateInvalid
    }
    guard addedAccept.acceptingPlayer != from.currentPlayer, from.roster.contains(addedAccept.acceptingPlayer) else {
        throw CoreGameError.tradeStateInvalid
    }

    let acceptPlayers = to.pendingTradeAccepts.map(\.acceptingPlayer)
    guard Set(acceptPlayers).count == acceptPlayers.count else {
        throw CoreGameError.tradeStateInvalid
    }
}

private func validateDevCardTransition(
    from: CoreGameStateV1,
    to: CoreGameStateV1,
    isStartTransition: Bool
) throws {
    if isStartTransition {
        return
    }

    let devStateUnchanged =
        from.devDeck == to.devDeck &&
        from.devCardsByPlayer == to.devCardsByPlayer &&
        from.newDevCardsByPlayer == to.newDevCardsByPlayer &&
        from.revealedVictoryPointsByPlayer == to.revealedVictoryPointsByPlayer &&
        from.devCardActionPlayedThisTurn == to.devCardActionPlayedThisTurn &&
        from.knightsPlayedByPlayer == to.knightsPlayedByPlayer

    if from.phase != .turn || to.phase != .turn {
        guard devStateUnchanged else {
            throw CoreGameError.devDeckInvalid
        }
        return
    }

    if from.currentPlayer != to.currentPlayer {
        try validateEndTurnDevCardCarryover(from: from, to: to)
        return
    }

    if devStateUnchanged {
        return
    }

    guard from.turnState?.step == .afterRoll, to.turnState?.step == .afterRoll else {
        throw CoreGameError.devDeckInvalid
    }

    if to.devDeck != from.devDeck {
        guard to.devDeck.count == from.devDeck.count - 1 else {
            throw CoreGameError.devDeckInvalid
        }
        guard Array(from.devDeck.dropFirst()) == to.devDeck else {
            throw CoreGameError.devDeckInvalid
        }
        guard to.devCardActionPlayedThisTurn == from.devCardActionPlayedThisTurn else {
            throw CoreGameError.devDeckInvalid
        }
    }

    let current = from.currentPlayer
    for player in from.roster where player != current {
        guard to.devCardsByPlayer[player] == from.devCardsByPlayer[player] else {
            throw CoreGameError.devDeckInvalid
        }
        guard to.newDevCardsByPlayer[player] == from.newDevCardsByPlayer[player] else {
            throw CoreGameError.devDeckInvalid
        }
        guard to.revealedVictoryPointsByPlayer[player] == from.revealedVictoryPointsByPlayer[player] else {
            throw CoreGameError.devDeckInvalid
        }
        guard to.knightsPlayedByPlayer[player] == from.knightsPlayedByPlayer[player] else {
            throw CoreGameError.devDeckInvalid
        }
    }

    let fromCurrentInventory = from.devCardsByPlayer[current] ?? .zero
    let toCurrentInventory = to.devCardsByPlayer[current] ?? .zero
    let fromCurrentNewInventory = from.newDevCardsByPlayer[current] ?? .zero
    let toCurrentNewInventory = to.newDevCardsByPlayer[current] ?? .zero
    guard isNonNegativeInventory(toCurrentInventory), isNonNegativeInventory(toCurrentNewInventory) else {
        throw CoreGameError.devDeckInvalid
    }

    if to.devDeck == from.devDeck {
        guard fromCurrentInventory.totalCount + fromCurrentNewInventory.totalCount >= toCurrentInventory.totalCount + toCurrentNewInventory.totalCount else {
            throw CoreGameError.devDeckInvalid
        }
    }

    guard (to.revealedVictoryPointsByPlayer[current] ?? 0) >= (from.revealedVictoryPointsByPlayer[current] ?? 0) else {
        throw CoreGameError.devDeckInvalid
    }
    guard (to.knightsPlayedByPlayer[current] ?? 0) >= (from.knightsPlayedByPlayer[current] ?? 0) else {
        throw CoreGameError.devDeckInvalid
    }

    if from.devCardActionPlayedThisTurn {
        guard to.devCardActionPlayedThisTurn else {
            throw CoreGameError.devDeckInvalid
        }
    }
}

private func validateEndTurnDevCardCarryover(from: CoreGameStateV1, to: CoreGameStateV1) throws {
    guard to.devDeck == from.devDeck else {
        throw CoreGameError.devDeckInvalid
    }

    let endingPlayer = from.currentPlayer
    for player in from.roster {
        if player == endingPlayer {
            let expectedPlayable = mergeDevInventoriesForValidation(
                from.devCardsByPlayer[player] ?? .zero,
                from.newDevCardsByPlayer[player] ?? .zero
            )
            guard to.devCardsByPlayer[player] == expectedPlayable else {
                throw CoreGameError.devDeckInvalid
            }
            guard to.newDevCardsByPlayer[player] == .zero else {
                throw CoreGameError.devDeckInvalid
            }
        } else {
            guard to.devCardsByPlayer[player] == from.devCardsByPlayer[player] else {
                throw CoreGameError.devDeckInvalid
            }
            guard to.newDevCardsByPlayer[player] == from.newDevCardsByPlayer[player] else {
                throw CoreGameError.devDeckInvalid
            }
        }

        guard to.revealedVictoryPointsByPlayer[player] == from.revealedVictoryPointsByPlayer[player] else {
            throw CoreGameError.devDeckInvalid
        }
        guard to.knightsPlayedByPlayer[player] == from.knightsPlayedByPlayer[player] else {
            throw CoreGameError.devDeckInvalid
        }
    }

    guard to.devCardActionPlayedThisTurn == false else {
        throw CoreGameError.devDeckInvalid
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

    if from.phase == .turn, to.phase == .turn, from.currentPlayer == to.currentPlayer {
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
    guard from.turnState == to.turnState, from.turnState?.step == .afterRoll else {
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

        let expectedRequirements = requiredDiscardsForValidation(from.resourcesByPlayer)
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
            bankResources: from.bankResources
        )
    }

    if from.phase == .turn, to.phase == .turn, to.currentPlayer == from.currentPlayer {
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
        let buildUpdate = expectedEconomyAfterBuildIfAny(from: from, to: to)
        if buildUpdate.resourcesByPlayer != original.resourcesByPlayer || buildUpdate.bankResources != original.bankResources {
            return buildUpdate
        }
        return original
    }

    return EconomyUpdateV1(resourcesByPlayer: from.resourcesByPlayer, bankResources: from.bankResources)
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
        from.phase == .turn,
        to.phase == .turn,
        from.currentPlayer == to.currentPlayer,
        from.turnState == to.turnState,
        from.turnState?.step == .afterRoll,
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
        cost = ResourceHandV1(wood: 1, brick: 1)
    } else if settlementsChanged && !roadsChanged && !citiesChanged {
        cost = ResourceHandV1(wood: 1, brick: 1, sheep: 1, wheat: 1)
    } else if settlementsChanged && citiesChanged && !roadsChanged {
        cost = ResourceHandV1(wheat: 2, ore: 3)
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

private func expectedEconomyAfterTradeExecutionIfAny(from: CoreGameStateV1, to: CoreGameStateV1) -> EconomyUpdateV1 {
    guard
        from.phase == .turn,
        to.phase == .turn,
        from.currentPlayer == to.currentPlayer,
        from.turnState == to.turnState,
        from.turnState?.step == .afterRoll,
        let offer = from.activeTradeOffer,
        to.activeTradeOffer == nil,
        to.pendingTradeAccepts.isEmpty
    else {
        return EconomyUpdateV1(resourcesByPlayer: from.resourcesByPlayer, bankResources: from.bankResources)
    }

    for accept in from.pendingTradeAccepts where accept.offerHash == offer.offerHash {
        let proposer = from.currentPlayer
        let acceptor = accept.acceptingPlayer
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
        from.phase == .turn,
        to.phase == .turn,
        from.currentPlayer == to.currentPlayer,
        from.turnState == to.turnState,
        from.turnState?.step == .afterRoll
    else {
        return EconomyUpdateV1(resourcesByPlayer: from.resourcesByPlayer, bankResources: from.bankResources)
    }

    let player = from.currentPlayer
    let original = EconomyUpdateV1(resourcesByPlayer: from.resourcesByPlayer, bankResources: from.bankResources)

    if to.devDeck.count == from.devDeck.count - 1, Array(from.devDeck.dropFirst()) == to.devDeck {
        let cost = ResourceHandV1(sheep: 1, wheat: 1, ore: 1)
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
            currentPlayer: player
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

private func requiredDiscardsForValidation(_ resourcesByPlayer: [String: ResourceHandV1]) -> [String: Int] {
    var result: [String: Int] = [:]
    for (player, hand) in resourcesByPlayer {
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
        to.phase == .turn,
        from.currentPlayer == to.currentPlayer,
        from.turnState?.step == .afterRoll,
        to.turnState?.step == .afterRoll
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

private func isKnightDevCardTransition(from: CoreGameStateV1, to: CoreGameStateV1, actor: String) -> Bool {
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
    currentPlayer: String
) -> [String] {
    guard tileID >= 0, tileID < validationTopology.tiles.count else {
        return []
    }

    var victims: Set<String> = []
    for node in validationTopology.tiles[tileID].nodes {
        if let cityOwner = citiesByNode[node],
           cityOwner != currentPlayer,
           (resourcesByPlayer[cityOwner] ?? .zero).totalCount > 0
        {
            victims.insert(cityOwner)
            continue
        }

        if let settlementOwner = settlementsByNode[node],
           settlementOwner != currentPlayer,
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
        activeTradeOffer: state.activeTradeOffer,
        pendingTradeAccepts: state.pendingTradeAccepts,
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

private func isValidTradeHandForValidation(_ hand: ResourceHandV1) -> Bool {
    hand.wood >= 0 &&
        hand.brick >= 0 &&
        hand.sheep >= 0 &&
        hand.wheat >= 0 &&
        hand.ore >= 0
}

private func canAffordForValidation(hand: ResourceHandV1, cost: ResourceHandV1) -> Bool {
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

private func isNonNegativeInventory(_ value: DevCardInventoryV1) -> Bool {
    value.knight >= 0 &&
        value.monopoly >= 0 &&
        value.yearOfPlenty >= 0 &&
        value.roadBuilding >= 0 &&
        value.victoryPoint >= 0
}

private func mergeDevInventoriesForValidation(
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
