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

        if !isRobberMoveBoardTransition(from: from, to: to) {
            guard to.board == from.board else {
                throw CoreGameError.boardChanged
            }
        } else if !isOnlyRobberTileChanged(from: from.board, to: to.board) {
            throw CoreGameError.boardChanged
        }
    }

    try validateOwnershipTransition(from: from, to: to, actor: actor, isStartTransition: isStartTransition)
    try validateTurnStepTransition(from: from, to: to)

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

        let allSubmitted = fromTurn.discardRequirementsByPlayer.keys.allSatisfy { toSubmitted[$0] != nil }
        guard (toTurn.step == .needsRobberMove) == allSubmitted else {
            throw CoreGameError.turnStepMismatch
        }

    case (.needsRobberMove, .afterRoll):
        guard toTurn.lastRoll == fromTurn.lastRoll else {
            throw CoreGameError.turnStepMismatch
        }
        guard toTurn.discardRequirementsByPlayer.isEmpty else {
            throw CoreGameError.turnStepMismatch
        }
        guard toTurn.submittedDiscardsByPlayer.isEmpty else {
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
        return expectedEconomyAfterDiscardSubmissionIfAny(from: from, to: to)
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
        to.turnState?.step == .afterRoll
    else {
        return false
    }
    return true
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
