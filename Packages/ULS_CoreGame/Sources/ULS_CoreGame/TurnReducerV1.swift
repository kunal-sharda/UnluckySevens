import Foundation

private let turnBuildTopology = StandardBoardTopologyV1.standard()

public enum TurnIntentV1: Codable, Equatable {
    case rollDice
    case submitDiscard(player: String, discarded: ResourceHandV1)
    case moveRobber(tileID: Int)
    case selectStealVictim(victimPlayer: String)
    case buildRoad(edgeID: Int)
    case buildSettlement(nodeID: Int)
    case buildCity(nodeID: Int)
    case endTurn
}

public func apply(intent: TurnIntentV1, to state: CoreGameStateV1, actor: String) throws -> CoreGameStateV1 {
    guard state.phase == .turn, let turnState = state.turnState else {
        throw CoreGameError.turnStateMissing
    }

    guard actor == state.currentPlayer else {
        throw CoreGameError.actorMismatch
    }

    switch intent {
    case .rollDice:
        guard turnState.step == .needsRoll else {
            throw CoreGameError.turnStepMismatch
        }

        guard let diceRngState = state.diceRngState else {
            throw CoreGameError.missingDiceRngState
        }

        var rng = DeterministicRNG(seed: diceRngState)
        let roll = rng.rollDice()
        let rollTotal = roll.0 + roll.1

        if rollTotal == 7 {
            let requirements = requiredDiscards(for: state.resourcesByPlayer)
            let nextStep: TurnStepV1 = requirements.isEmpty ? .needsRobberMove : .pendingDiscards
            return nextTurnState(
                from: state,
                currentPlayer: state.currentPlayer,
                diceRngState: rng.state,
                robberRngState: state.robberRngState,
                board: state.board,
                turnState: TurnStateV1(
                    step: nextStep,
                    lastRoll: DiceRollV1(d1: roll.0, d2: roll.1),
                    discardRequirementsByPlayer: requirements,
                    submittedDiscardsByPlayer: [:],
                    eligibleStealVictims: []
                )
            )
        }

        let economy = applyProductionPayout(
            rollTotal: rollTotal,
            board: state.board,
            settlementsByNode: state.settlementsByNode,
            citiesByNode: state.citiesByNode,
            resourcesByPlayer: state.resourcesByPlayer,
            bankResources: state.bankResources
        )

        return nextTurnState(
            from: state,
            currentPlayer: state.currentPlayer,
            diceRngState: rng.state,
            robberRngState: state.robberRngState,
            board: state.board,
            turnState: TurnStateV1(step: .afterRoll, lastRoll: DiceRollV1(d1: roll.0, d2: roll.1)),
            resourcesByPlayer: economy.resourcesByPlayer,
            bankResources: economy.bankResources
        )

    case let .submitDiscard(player, discarded):
        guard turnState.step == .pendingDiscards else {
            throw CoreGameError.turnStepMismatch
        }

        guard let requiredCount = turnState.discardRequirementsByPlayer[player] else {
            throw CoreGameError.discardSubmissionNotRequired
        }

        guard turnState.submittedDiscardsByPlayer[player] == nil else {
            throw CoreGameError.discardAlreadySubmitted
        }

        guard discarded.totalCount == requiredCount else {
            throw CoreGameError.discardCountMismatch
        }

        guard
            discarded.wood >= 0,
            discarded.brick >= 0,
            discarded.sheep >= 0,
            discarded.wheat >= 0,
            discarded.ore >= 0
        else {
            throw CoreGameError.discardCountMismatch
        }

        let playerHand = state.resourcesByPlayer[player] ?? .zero
        guard
            discarded.wood <= playerHand.wood,
            discarded.brick <= playerHand.brick,
            discarded.sheep <= playerHand.sheep,
            discarded.wheat <= playerHand.wheat,
            discarded.ore <= playerHand.ore
        else {
            throw CoreGameError.insufficientResourcesForDiscard
        }

        var updatedResourcesByPlayer = state.resourcesByPlayer
        updatedResourcesByPlayer[player] = ResourceHandV1(
            wood: playerHand.wood - discarded.wood,
            brick: playerHand.brick - discarded.brick,
            sheep: playerHand.sheep - discarded.sheep,
            wheat: playerHand.wheat - discarded.wheat,
            ore: playerHand.ore - discarded.ore
        )

        let updatedBankResources = ResourceHandV1(
            wood: state.bankResources.wood + discarded.wood,
            brick: state.bankResources.brick + discarded.brick,
            sheep: state.bankResources.sheep + discarded.sheep,
            wheat: state.bankResources.wheat + discarded.wheat,
            ore: state.bankResources.ore + discarded.ore
        )

        var submitted = turnState.submittedDiscardsByPlayer
        submitted[player] = discarded
        let allSubmitted = turnState.discardRequirementsByPlayer.keys.allSatisfy { submitted[$0] != nil }

        return nextTurnState(
            from: state,
            currentPlayer: state.currentPlayer,
            diceRngState: state.diceRngState,
            robberRngState: state.robberRngState,
            board: state.board,
            turnState: TurnStateV1(
                step: allSubmitted ? .needsRobberMove : .pendingDiscards,
                lastRoll: turnState.lastRoll,
                discardRequirementsByPlayer: turnState.discardRequirementsByPlayer,
                submittedDiscardsByPlayer: submitted,
                eligibleStealVictims: []
            ),
            resourcesByPlayer: updatedResourcesByPlayer,
            bankResources: updatedBankResources
        )

    case let .moveRobber(tileID):
        guard turnState.step == .needsRobberMove else {
            throw CoreGameError.turnStepMismatch
        }
        guard let board = state.board else {
            throw CoreGameError.boardChanged
        }
        guard tileID >= 0, tileID < board.resourcesByTile.count else {
            throw CoreGameError.invalidRobberTile
        }
        guard tileID != board.robberTile else {
            throw CoreGameError.robberTileUnchanged
        }

        let movedBoard = BoardSetupV1(
            resourcesByTile: board.resourcesByTile,
            numbersByTile: board.numbersByTile,
            portsByIndex: board.portsByIndex,
            robberTile: tileID,
            generator: board.generator,
            boardHash: ""
        ).rehashed()

        let victims = eligibleRobberVictims(
            for: tileID,
            settlementsByNode: state.settlementsByNode,
            citiesByNode: state.citiesByNode,
            resourcesByPlayer: state.resourcesByPlayer,
            currentPlayer: state.currentPlayer
        )
        let nextStep: TurnStepV1 = victims.isEmpty ? .afterRoll : .needsRobberSteal

        return nextTurnState(
            from: state,
            currentPlayer: state.currentPlayer,
            diceRngState: state.diceRngState,
            robberRngState: state.robberRngState,
            board: movedBoard,
            turnState: TurnStateV1(
                step: nextStep,
                lastRoll: turnState.lastRoll,
                eligibleStealVictims: victims
            )
        )

    case let .selectStealVictim(victimPlayer):
        guard turnState.step == .needsRobberSteal else {
            throw CoreGameError.turnStepMismatch
        }
        guard turnState.eligibleStealVictims.contains(victimPlayer) else {
            throw CoreGameError.robberStealVictimNotEligible
        }
        guard let robberRngState = state.robberRngState else {
            throw CoreGameError.missingRobberRngState
        }

        let victimHand = state.resourcesByPlayer[victimPlayer] ?? .zero
        guard victimHand.totalCount > 0 else {
            throw CoreGameError.robberStealVictimNotEligible
        }

        var rng = DeterministicRNG(seed: robberRngState)
        let stolen = deterministicStolenResource(from: victimHand, rng: &rng)

        let stealerHand = state.resourcesByPlayer[state.currentPlayer] ?? .zero
        var updatedResourcesByPlayer = state.resourcesByPlayer
        updatedResourcesByPlayer[state.currentPlayer] = stealerHand.addingOne(for: stolen)
        updatedResourcesByPlayer[victimPlayer] = victimHand.subtracting(1, for: stolen)

        return nextTurnState(
            from: state,
            currentPlayer: state.currentPlayer,
            diceRngState: state.diceRngState,
            robberRngState: rng.state,
            board: state.board,
            turnState: TurnStateV1(step: .afterRoll, lastRoll: turnState.lastRoll),
            resourcesByPlayer: updatedResourcesByPlayer
        )

    case let .buildRoad(edgeID):
        guard turnState.step == .afterRoll else {
            throw CoreGameError.turnStepMismatch
        }
        guard edgeID >= 0, edgeID < turnBuildTopology.edges.count else {
            throw CoreGameError.invalidEdge
        }
        guard state.roadsByEdge[edgeID] == nil else {
            throw CoreGameError.edgeOccupied
        }

        let player = state.currentPlayer
        let playerRoadCount = state.roadsByEdge.values.filter { $0 == player }.count
        guard playerRoadCount < 15 else {
            throw CoreGameError.buildPieceLimitReached
        }
        guard isRoadConnected(edgeID: edgeID, for: player, in: state) else {
            throw CoreGameError.roadConnectionRequired
        }

        let cost = ResourceHandV1(wood: 1, brick: 1)
        guard canAfford(hand: state.resourcesByPlayer[player] ?? .zero, cost: cost) else {
            throw CoreGameError.buildInsufficientResources
        }
        let economy = applyBuildCost(player: player, cost: cost, state: state)

        var roads = state.roadsByEdge
        roads[edgeID] = player

        return nextTurnState(
            from: state,
            currentPlayer: player,
            diceRngState: state.diceRngState,
            robberRngState: state.robberRngState,
            board: state.board,
            turnState: turnState,
            resourcesByPlayer: economy.resourcesByPlayer,
            bankResources: economy.bankResources,
            roadsByEdge: roads
        )

    case let .buildSettlement(nodeID):
        guard turnState.step == .afterRoll else {
            throw CoreGameError.turnStepMismatch
        }
        guard nodeID >= 0, nodeID < turnBuildTopology.nodesCount else {
            throw CoreGameError.invalidNode
        }
        guard state.settlementsByNode[nodeID] == nil, state.citiesByNode[nodeID] == nil else {
            throw CoreGameError.nodeOccupied
        }

        let occupiedNodes = Set(state.settlementsByNode.keys).union(Set(state.citiesByNode.keys))
        let adjacentNodes = Set(turnBuildTopology.nodes(adjacentTo: nodeID))
        if !adjacentNodes.isDisjoint(with: occupiedNodes) {
            throw CoreGameError.distanceRuleViolation
        }

        let player = state.currentPlayer
        let playerSettlementCount = state.settlementsByNode.values.filter { $0 == player }.count
        guard playerSettlementCount < 5 else {
            throw CoreGameError.buildPieceLimitReached
        }
        guard isSettlementConnected(nodeID: nodeID, for: player, in: state) else {
            throw CoreGameError.settlementConnectionRequired
        }

        let cost = ResourceHandV1(wood: 1, brick: 1, sheep: 1, wheat: 1)
        guard canAfford(hand: state.resourcesByPlayer[player] ?? .zero, cost: cost) else {
            throw CoreGameError.buildInsufficientResources
        }
        let economy = applyBuildCost(player: player, cost: cost, state: state)

        var settlements = state.settlementsByNode
        settlements[nodeID] = player

        return nextTurnState(
            from: state,
            currentPlayer: player,
            diceRngState: state.diceRngState,
            robberRngState: state.robberRngState,
            board: state.board,
            turnState: turnState,
            resourcesByPlayer: economy.resourcesByPlayer,
            bankResources: economy.bankResources,
            settlementsByNode: settlements
        )

    case let .buildCity(nodeID):
        guard turnState.step == .afterRoll else {
            throw CoreGameError.turnStepMismatch
        }
        guard nodeID >= 0, nodeID < turnBuildTopology.nodesCount else {
            throw CoreGameError.invalidNode
        }
        let player = state.currentPlayer
        guard state.settlementsByNode[nodeID] == player else {
            throw CoreGameError.cityRequiresOwnSettlement
        }
        guard state.citiesByNode[nodeID] == nil else {
            throw CoreGameError.nodeOccupied
        }

        let playerCityCount = state.citiesByNode.values.filter { $0 == player }.count
        guard playerCityCount < 4 else {
            throw CoreGameError.buildPieceLimitReached
        }

        let cost = ResourceHandV1(wheat: 2, ore: 3)
        guard canAfford(hand: state.resourcesByPlayer[player] ?? .zero, cost: cost) else {
            throw CoreGameError.buildInsufficientResources
        }
        let economy = applyBuildCost(player: player, cost: cost, state: state)

        var settlements = state.settlementsByNode
        settlements.removeValue(forKey: nodeID)
        var cities = state.citiesByNode
        cities[nodeID] = player

        return nextTurnState(
            from: state,
            currentPlayer: player,
            diceRngState: state.diceRngState,
            robberRngState: state.robberRngState,
            board: state.board,
            turnState: turnState,
            resourcesByPlayer: economy.resourcesByPlayer,
            bankResources: economy.bankResources,
            settlementsByNode: settlements,
            citiesByNode: cities
        )

    case .endTurn:
        guard turnState.step == .afterRoll else {
            throw CoreGameError.turnStepMismatch
        }

        guard let currentIndex = state.roster.firstIndex(of: state.currentPlayer), !state.roster.isEmpty else {
            throw CoreGameError.turnCurrentPlayerNotInRoster
        }

        let nextIndex = state.roster.index(after: currentIndex)
        let wrappedIndex = nextIndex == state.roster.endIndex ? state.roster.startIndex : nextIndex
        let nextPlayer = state.roster[wrappedIndex]

        return nextTurnState(
            from: state,
            currentPlayer: nextPlayer,
            diceRngState: state.diceRngState,
            robberRngState: state.robberRngState,
            board: state.board,
            turnState: TurnStateV1(step: .needsRoll, lastRoll: nil)
        )
    }
}

private func nextTurnState(
    from state: CoreGameStateV1,
    currentPlayer: String,
    diceRngState: UInt64?,
    robberRngState: UInt64?,
    board: BoardSetupV1?,
    turnState: TurnStateV1,
    resourcesByPlayer: [String: ResourceHandV1]? = nil,
    bankResources: ResourceHandV1? = nil,
    settlementsByNode: [NodeID: String]? = nil,
    citiesByNode: [NodeID: String]? = nil,
    roadsByEdge: [EdgeID: String]? = nil
) -> CoreGameStateV1 {
    CoreGameStateV1(
        gameId: state.gameId,
        rev: state.rev + 1,
        prevHash: state.stateHash,
        stateHash: "",
        roster: state.roster,
        currentPlayer: currentPlayer,
        phase: .turn,
        seed: state.seed,
        diceRngState: diceRngState,
        robberRngState: robberRngState,
        resourcesByPlayer: resourcesByPlayer ?? state.resourcesByPlayer,
        bankResources: bankResources ?? state.bankResources,
        settlementsByNode: settlementsByNode ?? state.settlementsByNode,
        citiesByNode: citiesByNode ?? state.citiesByNode,
        roadsByEdge: roadsByEdge ?? state.roadsByEdge,
        boardRules: state.boardRules,
        board: board,
        setupState: nil,
        turnState: turnState
    ).rehashed()
}

private func requiredDiscards(for resourcesByPlayer: [String: ResourceHandV1]) -> [String: Int] {
    var result: [String: Int] = [:]
    for (player, hand) in resourcesByPlayer {
        if hand.totalCount > 7 {
            result[player] = hand.totalCount / 2
        }
    }
    return result
}

private func eligibleRobberVictims(
    for tileID: Int,
    settlementsByNode: [NodeID: String],
    citiesByNode: [NodeID: String],
    resourcesByPlayer: [String: ResourceHandV1],
    currentPlayer: String
) -> [String] {
    let topology = StandardBoardTopologyV1.standard()
    guard tileID >= 0, tileID < topology.tiles.count else {
        return []
    }

    var victims: Set<String> = []
    for node in topology.tiles[tileID].nodes {
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

private func deterministicStolenResource(from hand: ResourceHandV1, rng: inout DeterministicRNG) -> ResourceV1 {
    let total = hand.totalCount
    let pick = Int(rng.nextUInt64() % UInt64(total))

    let resources: [(ResourceV1, Int)] = [
        (.wood, hand.wood),
        (.brick, hand.brick),
        (.sheep, hand.sheep),
        (.wheat, hand.wheat),
        (.ore, hand.ore),
    ]

    var cursor = 0
    for (resource, count) in resources {
        if pick < cursor + count {
            return resource
        }
        cursor += count
    }

    return .wood
}

private func canAfford(hand: ResourceHandV1, cost: ResourceHandV1) -> Bool {
    hand.wood >= cost.wood &&
        hand.brick >= cost.brick &&
        hand.sheep >= cost.sheep &&
        hand.wheat >= cost.wheat &&
        hand.ore >= cost.ore
}

private func applyBuildCost(player: String, cost: ResourceHandV1, state: CoreGameStateV1) -> EconomyUpdateV1 {
    let hand = state.resourcesByPlayer[player] ?? .zero
    var resourcesByPlayer = state.resourcesByPlayer
    resourcesByPlayer[player] = ResourceHandV1(
        wood: hand.wood - cost.wood,
        brick: hand.brick - cost.brick,
        sheep: hand.sheep - cost.sheep,
        wheat: hand.wheat - cost.wheat,
        ore: hand.ore - cost.ore
    )
    let bank = state.bankResources
    let bankResources = ResourceHandV1(
        wood: bank.wood + cost.wood,
        brick: bank.brick + cost.brick,
        sheep: bank.sheep + cost.sheep,
        wheat: bank.wheat + cost.wheat,
        ore: bank.ore + cost.ore
    )
    return EconomyUpdateV1(resourcesByPlayer: resourcesByPlayer, bankResources: bankResources)
}

private func isRoadConnected(edgeID: Int, for player: String, in state: CoreGameStateV1) -> Bool {
    let edge = turnBuildTopology.edges[edgeID]
    let nodes = [edge.a, edge.b]
    for node in nodes {
        if state.settlementsByNode[node] == player || state.citiesByNode[node] == player {
            return true
        }
        if state.settlementsByNode[node] != nil || state.citiesByNode[node] != nil {
            continue
        }
        for adjacentEdge in turnBuildTopology.edges(incidentTo: node) where adjacentEdge != edgeID {
            if state.roadsByEdge[adjacentEdge] == player {
                return true
            }
        }
    }
    return false
}

private func isSettlementConnected(nodeID: Int, for player: String, in state: CoreGameStateV1) -> Bool {
    for edge in turnBuildTopology.edges(incidentTo: nodeID) {
        if state.roadsByEdge[edge] == player {
            return true
        }
    }
    return false
}
