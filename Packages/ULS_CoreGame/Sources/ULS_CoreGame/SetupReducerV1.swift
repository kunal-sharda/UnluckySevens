import Foundation

private let setupTopology = StandardBoardTopologyV1.standard()

public enum SetupIntentV1: Codable, Equatable {
    case placeSetupSettlement(node: Int)
    case placeSetupRoad(edge: Int)
    case placeSetupPair(settlementNode: Int, roadEdge: Int)
}

public func apply(intent: SetupIntentV1, to state: CoreGameStateV1, actor: String) throws -> CoreGameStateV1 {
    guard state.phase == .setup, let setupState = state.setupState else {
        throw CoreGameError.setupStateMissing
    }

    let topology = setupTopology

    guard actor == state.currentPlayer else {
        throw CoreGameError.actorMismatch
    }

    guard setupState.turnIndex >= 0, setupState.turnIndex < setupState.order.count else {
        throw CoreGameError.setupTurnIndexOutOfRange
    }

    guard setupState.order[setupState.turnIndex] == state.currentPlayer else {
        throw CoreGameError.setupCurrentPlayerMismatch
    }

    let player = state.currentPlayer

    switch intent {
    case let .placeSetupSettlement(node):
        let advancedSetup = try applySettlementPlacement(
            node: node,
            setupState: setupState,
            player: player,
            topology: topology
        )
        let ownership = boardOwnership(from: advancedSetup.placements)

        return nextState(
            from: state,
            currentPlayer: player,
            phase: .setup,
            setupState: advancedSetup,
            turnState: nil,
            settlementsByNode: ownership.settlementsByNode,
            roadsByEdge: ownership.roadsByEdge
        )

    case let .placeSetupRoad(edge):
        let roadResult = try applyRoadPlacement(
            edge: edge,
            setupState: setupState,
            player: player,
            roster: state.roster,
            topology: topology
        )
        let economy = grantStartingResourcesIfEligible(
            from: state,
            player: player,
            settlementNode: roadResult.startingResourceSettlementNode,
            topology: topology
        )
        let ownership = boardOwnership(from: roadResult.placements)

        return nextState(
            from: state,
            currentPlayer: roadResult.currentPlayer,
            phase: roadResult.phase,
            setupState: roadResult.setupState,
            turnState: roadResult.phase == .turn ? TurnStateV1(step: .needsRoll, lastRoll: nil) : nil,
            resourcesByPlayer: economy.resourcesByPlayer,
            bankResources: economy.bankResources,
            settlementsByNode: ownership.settlementsByNode,
            roadsByEdge: ownership.roadsByEdge
        )

    case let .placeSetupPair(settlementNode, roadEdge):
        let afterSettlement = try applySettlementPlacement(
            node: settlementNode,
            setupState: setupState,
            player: player,
            topology: topology
        )
        let roadResult = try applyRoadPlacement(
            edge: roadEdge,
            setupState: afterSettlement,
            player: player,
            roster: state.roster,
            topology: topology
        )
        let economy = grantStartingResourcesIfEligible(
            from: state,
            player: player,
            settlementNode: roadResult.startingResourceSettlementNode,
            topology: topology
        )
        let ownership = boardOwnership(from: roadResult.placements)

        return nextState(
            from: state,
            currentPlayer: roadResult.currentPlayer,
            phase: roadResult.phase,
            setupState: roadResult.setupState,
            turnState: roadResult.phase == .turn ? TurnStateV1(step: .needsRoll, lastRoll: nil) : nil,
            resourcesByPlayer: economy.resourcesByPlayer,
            bankResources: economy.bankResources,
            settlementsByNode: ownership.settlementsByNode,
            roadsByEdge: ownership.roadsByEdge
        )
    }
}

private func applySettlementPlacement(
    node: Int,
    setupState: SetupStateV1,
    player: String,
    topology: BoardGraphV1
) throws -> SetupStateV1 {
    guard setupState.step == .placeSettlement else {
        throw CoreGameError.setupStepMismatch
    }

    guard node >= 0, node < topology.nodesCount else {
        throw CoreGameError.invalidNode
    }

    let occupiedNodes = occupiedSettlementNodes(from: setupState.placements)
    guard !occupiedNodes.contains(node) else {
        throw CoreGameError.nodeOccupied
    }

    let adjacentNodes = Set(topology.nodes(adjacentTo: node))
    if !adjacentNodes.isDisjoint(with: occupiedNodes) {
        throw CoreGameError.distanceRuleViolation
    }

    var playerPlacements = setupState.placements[player] ?? PlayerSetupPlacementsV1()
    if playerPlacements.settlement1 == nil {
        playerPlacements = PlayerSetupPlacementsV1(
            settlement1: node,
            road1: playerPlacements.road1,
            settlement2: playerPlacements.settlement2,
            road2: playerPlacements.road2
        )
    } else if playerPlacements.settlement2 == nil {
        playerPlacements = PlayerSetupPlacementsV1(
            settlement1: playerPlacements.settlement1,
            road1: playerPlacements.road1,
            settlement2: node,
            road2: playerPlacements.road2
        )
    } else {
        throw CoreGameError.setupPlacementSlotUnavailable
    }

    return SetupStateV1(
        order: setupState.order,
        turnIndex: setupState.turnIndex,
        step: .placeRoad,
        placements: setupState.placements.merging([player: playerPlacements]) { _, new in new },
        lastPlacedSettlementNode: node
    )
}

private func applyRoadPlacement(
    edge: Int,
    setupState: SetupStateV1,
    player: String,
    roster: [String],
    topology: BoardGraphV1
) throws -> RoadPlacementResult {
    guard setupState.step == .placeRoad else {
        throw CoreGameError.setupStepMismatch
    }

    guard edge >= 0, edge < topology.edges.count else {
        throw CoreGameError.invalidEdge
    }

    let occupiedEdges = occupiedRoadEdges(from: setupState.placements)
    guard !occupiedEdges.contains(edge) else {
        throw CoreGameError.edgeOccupied
    }

    guard let lastSettlementNode = setupState.lastPlacedSettlementNode else {
        throw CoreGameError.roadBeforeSettlement
    }

    let selectedEdge = topology.edges[edge]
    guard selectedEdge.a == lastSettlementNode || selectedEdge.b == lastSettlementNode else {
        throw CoreGameError.roadNotAdjacentToLastSettlement
    }

    var playerPlacements = setupState.placements[player] ?? PlayerSetupPlacementsV1()
    var startingResourceSettlementNode: NodeID?
    if playerPlacements.road1 == nil {
        guard playerPlacements.settlement1 != nil else {
            throw CoreGameError.roadBeforeSettlement
        }
        playerPlacements = PlayerSetupPlacementsV1(
            settlement1: playerPlacements.settlement1,
            road1: edge,
            settlement2: playerPlacements.settlement2,
            road2: playerPlacements.road2
        )
    } else if playerPlacements.road2 == nil {
        guard playerPlacements.settlement2 != nil else {
            throw CoreGameError.roadBeforeSettlement
        }
        playerPlacements = PlayerSetupPlacementsV1(
            settlement1: playerPlacements.settlement1,
            road1: playerPlacements.road1,
            settlement2: playerPlacements.settlement2,
            road2: edge
        )
        startingResourceSettlementNode = playerPlacements.settlement2
    } else {
        throw CoreGameError.setupPlacementSlotUnavailable
    }

    let updatedPlacements = setupState.placements.merging([player: playerPlacements]) { _, new in new }
    let advancedTurnIndex = setupState.turnIndex + 1

    if advancedTurnIndex >= setupState.order.count {
        guard let firstPlayer = roster.first else {
            throw CoreGameError.setupTurnIndexOutOfRange
        }
        return RoadPlacementResult(
            phase: .turn,
            currentPlayer: firstPlayer,
            setupState: nil,
            placements: updatedPlacements,
            startingResourceSettlementNode: startingResourceSettlementNode
        )
    }

    let advancedSetupState = SetupStateV1(
        order: setupState.order,
        turnIndex: advancedTurnIndex,
        step: .placeSettlement,
        placements: updatedPlacements,
        lastPlacedSettlementNode: nil
    )

    return RoadPlacementResult(
        phase: .setup,
        currentPlayer: advancedSetupState.order[advancedSetupState.turnIndex],
        setupState: advancedSetupState,
        placements: updatedPlacements,
        startingResourceSettlementNode: startingResourceSettlementNode
    )
}

private struct RoadPlacementResult {
    let phase: PhaseV1
    let currentPlayer: String
    let setupState: SetupStateV1?
    let placements: [String: PlayerSetupPlacementsV1]
    let startingResourceSettlementNode: NodeID?
}

private func occupiedSettlementNodes(from placements: [String: PlayerSetupPlacementsV1]) -> Set<NodeID> {
    var nodes = Set<NodeID>()
    for placement in placements.values {
        if let settlement1 = placement.settlement1 {
            nodes.insert(settlement1)
        }
        if let settlement2 = placement.settlement2 {
            nodes.insert(settlement2)
        }
    }
    return nodes
}

private func occupiedRoadEdges(from placements: [String: PlayerSetupPlacementsV1]) -> Set<EdgeID> {
    var edges = Set<EdgeID>()
    for placement in placements.values {
        if let road1 = placement.road1 {
            edges.insert(road1)
        }
        if let road2 = placement.road2 {
            edges.insert(road2)
        }
    }
    return edges
}

private func nextState(
    from state: CoreGameStateV1,
    currentPlayer: String,
    phase: PhaseV1,
    setupState: SetupStateV1?,
    turnState: TurnStateV1?,
    resourcesByPlayer: [String: ResourceHandV1]? = nil,
    bankResources: ResourceHandV1? = nil,
    settlementsByNode: [NodeID: String]? = nil,
    roadsByEdge: [EdgeID: String]? = nil
) -> CoreGameStateV1 {
    CoreGameStateV1(
        gameId: state.gameId,
        rev: state.rev + 1,
        prevHash: state.stateHash,
        stateHash: "",
        roster: state.roster,
        currentPlayer: currentPlayer,
        targetPlayerCount: state.targetPlayerCount,
        playerDisplayNamesByPlayer: state.playerDisplayNamesByPlayer,
        phase: phase,
        seed: state.seed,
        diceRngState: state.diceRngState,
        robberRngState: state.robberRngState,
        resourcesByPlayer: resourcesByPlayer ?? state.resourcesByPlayer,
        bankResources: bankResources ?? state.bankResources,
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
        auditLog: state.auditLog,
        lastTurnRecap: state.lastTurnRecap,
        settlementsByNode: settlementsByNode ?? state.settlementsByNode,
        citiesByNode: state.citiesByNode,
        roadsByEdge: roadsByEdge ?? state.roadsByEdge,
        boardRules: state.boardRules,
        board: state.board,
        setupState: setupState,
        turnState: turnState
    ).rehashed()
}

private func grantStartingResourcesIfEligible(
    from state: CoreGameStateV1,
    player: String,
    settlementNode: NodeID?,
    topology: BoardGraphV1
) -> EconomyUpdateV1 {
    _ = topology
    return applyStartingSettlementPayout(
        player: player,
        settlementNode: settlementNode,
        board: state.board,
        resourcesByPlayer: state.resourcesByPlayer,
        bankResources: state.bankResources
    )
}

private func boardOwnership(from placements: [String: PlayerSetupPlacementsV1]) -> (
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
