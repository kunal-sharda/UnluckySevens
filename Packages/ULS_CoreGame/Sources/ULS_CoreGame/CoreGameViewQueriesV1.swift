import Foundation

public struct VisiblePlayerResourcesV1: Equatable {
    public let player: String
    public let totalCount: Int
    public let revealedHand: ResourceHandV1?

    public init(player: String, totalCount: Int, revealedHand: ResourceHandV1?) {
        self.player = player
        self.totalCount = totalCount
        self.revealedHand = revealedHand
    }
}

public struct VisiblePlayerDevCardsV1: Equatable {
    public let player: String
    public let totalCount: Int
    public let revealedPlayable: DevCardInventoryV1?
    public let revealedNew: DevCardInventoryV1?

    public init(
        player: String,
        totalCount: Int,
        revealedPlayable: DevCardInventoryV1?,
        revealedNew: DevCardInventoryV1?
    ) {
        self.player = player
        self.totalCount = totalCount
        self.revealedPlayable = revealedPlayable
        self.revealedNew = revealedNew
    }
}

public struct ResourceExchangeV1: Equatable {
    public let give: ResourceHandV1
    public let receive: ResourceHandV1

    public init(give: ResourceHandV1, receive: ResourceHandV1) {
        self.give = give
        self.receive = receive
    }
}

public struct MaritimeTradeQuoteV1: Equatable {
    public let give: ResourceHandV1
    public let receive: ResourceHandV1
    public let ratio: Int

    public init(give: ResourceHandV1, receive: ResourceHandV1, ratio: Int) {
        self.give = give
        self.receive = receive
        self.ratio = ratio
    }
}

public struct ResourcePairV1: Equatable {
    public let first: ResourceV1
    public let second: ResourceV1

    public init(first: ResourceV1, second: ResourceV1) {
        self.first = first
        self.second = second
    }
}

public struct MonopolyPreviewV1: Equatable {
    public let resource: ResourceV1
    public let claimCount: Int

    public init(resource: ResourceV1, claimCount: Int) {
        self.resource = resource
        self.claimCount = claimCount
    }
}

public struct BankResourceOptionV1: Equatable {
    public let resource: ResourceV1
    public let remainingCount: Int

    public init(resource: ResourceV1, remainingCount: Int) {
        self.resource = resource
        self.remainingCount = remainingCount
    }
}

public struct EdgePairV1: Equatable {
    public let firstEdgeID: EdgeID
    public let secondEdgeID: EdgeID

    public init(firstEdgeID: EdgeID, secondEdgeID: EdgeID) {
        self.firstEdgeID = firstEdgeID
        self.secondEdgeID = secondEdgeID
    }
}

public extension CoreGameStateV1 {
    func visibleResourceHands(for viewer: String?) -> [VisiblePlayerResourcesV1] {
        roster.map { player in
            let hand = resourcesByPlayer[player] ?? .zero
            return VisiblePlayerResourcesV1(
                player: player,
                totalCount: hand.totalCount,
                revealedHand: viewer == player ? hand : nil
            )
        }
    }

    func visibleDevCards(for viewer: String?) -> [VisiblePlayerDevCardsV1] {
        roster.map { player in
            let playable = devCardsByPlayer[player] ?? .zero
            let newCards = newDevCardsByPlayer[player] ?? .zero
            return VisiblePlayerDevCardsV1(
                player: player,
                totalCount: playable.totalCount + newCards.totalCount,
                revealedPlayable: viewer == player ? playable : nil,
                revealedNew: viewer == player ? newCards : nil
            )
        }
    }

    func defaultKnightVictim(for tileID: TileID, actor: String) -> String? {
        legalKnightVictims(for: tileID, actor: actor).first
    }

    func legalKnightMoveTilesForDevCard(for actor: String) -> [TileID] {
        guard
            phase == .turn,
            turnState?.step.allowsDevCardPlay == true,
            currentPlayer == actor,
            !devCardActionPlayedThisTurn,
            (devCardsByPlayer[actor] ?? .zero).knight > 0,
            let board
        else {
            return []
        }

        return board.resourcesByTile.indices.filter { $0 != board.robberTile }
    }

    func legalKnightVictims(for tileID: TileID, actor: String) -> [String] {
        let topology = StandardBoardTopologyV1.standard()
        guard tileID >= 0, tileID < topology.tiles.count else {
            return []
        }

        var victims: Set<String> = []
        for node in topology.tiles[tileID].nodes {
            if let cityOwner = citiesByNode[node],
               cityOwner != actor,
               (resourcesByPlayer[cityOwner] ?? .zero).totalCount > 0
            {
                victims.insert(cityOwner)
                continue
            }
            if let settlementOwner = settlementsByNode[node],
               settlementOwner != actor,
               (resourcesByPlayer[settlementOwner] ?? .zero).totalCount > 0
            {
                victims.insert(settlementOwner)
            }
        }

        return victims.sorted()
    }

    func knightVictimCandidateNodes(for tileID: TileID, actor: String) -> [NodeID] {
        let topology = StandardBoardTopologyV1.standard()
        let victims = Set(legalKnightVictims(for: tileID, actor: actor))
        guard tileID >= 0, tileID < topology.tiles.count, !victims.isEmpty else {
            return []
        }

        return Array(
            Set(
                topology.tiles[tileID].nodes.filter { nodeID in
                    if let owner = citiesByNode[nodeID] {
                        return victims.contains(owner)
                    }
                    if let owner = settlementsByNode[nodeID] {
                        return victims.contains(owner)
                    }
                    return false
                }
            )
        )
        .sorted()
    }

    func defaultMonopolyResource(for actor: String) -> ResourceV1? {
        var bestResource: ResourceV1?
        var bestCount = 0

        for resource in Self.tradeableResources {
            let count = roster
                .filter { $0 != actor }
                .reduce(0) { partial, player in
                    partial + (resourcesByPlayer[player] ?? .zero).count(for: resource)
                }
            if count > bestCount {
                bestCount = count
                bestResource = resource
            }
        }

        return bestResource ?? Self.tradeableResources.first
    }

    func monopolyPreviews(for actor: String) -> [MonopolyPreviewV1] {
        guard
            phase == .turn,
            turnState?.step.allowsDevCardPlay == true,
            currentPlayer == actor,
            !devCardActionPlayedThisTurn,
            (devCardsByPlayer[actor] ?? .zero).monopoly > 0
        else {
            return []
        }

        return Self.tradeableResources.map { resource in
            MonopolyPreviewV1(
                resource: resource,
                claimCount: roster
                    .filter { $0 != actor }
                    .reduce(0) { partial, player in
                        partial + (resourcesByPlayer[player] ?? .zero).count(for: resource)
                    }
            )
        }
    }

    func defaultYearOfPlentyResources() -> ResourcePairV1? {
        for resource in Self.tradeableResources where bankResources.count(for: resource) >= 2 {
            return ResourcePairV1(first: resource, second: resource)
        }

        let available = Self.tradeableResources.filter { bankResources.count(for: $0) > 0 }
        guard available.count >= 2 else {
            return nil
        }

        return ResourcePairV1(first: available[0], second: available[1])
    }

    func yearOfPlentyBankOptions(for actor: String) -> [BankResourceOptionV1] {
        guard
            phase == .turn,
            turnState?.step.allowsDevCardPlay == true,
            currentPlayer == actor,
            !devCardActionPlayedThisTurn,
            (devCardsByPlayer[actor] ?? .zero).yearOfPlenty > 0
        else {
            return []
        }

        return Self.tradeableResources.compactMap { resource in
            let remainingCount = bankResources.count(for: resource)
            guard remainingCount > 0 else {
                return nil
            }
            return BankResourceOptionV1(resource: resource, remainingCount: remainingCount)
        }
    }

    func defaultRoadBuildingEdges(for player: String) -> EdgePairV1? {
        guard let firstEdgeID = legalRoadBuildingFirstEdges(for: player).first,
              let secondEdgeID = legalRoadBuildingSecondEdges(for: player, firstEdgeID: firstEdgeID).first else {
            return nil
        }

        return EdgePairV1(firstEdgeID: firstEdgeID, secondEdgeID: secondEdgeID)
    }

    func legalRoadBuildingFirstEdges(for player: String) -> [EdgeID] {
        let topology = StandardBoardTopologyV1.standard()
        guard canPlayRoadBuilding(for: player) else {
            return []
        }

        return topology.edges.indices.filter { firstEdgeID in
            guard roadsByEdge[firstEdgeID] == nil, isRoadConnected(firstEdgeID, player: player, roads: roadsByEdge) else {
                return false
            }
            return !legalRoadBuildingSecondEdges(for: player, firstEdgeID: firstEdgeID).isEmpty
        }
    }

    func legalRoadBuildingSecondEdges(for player: String, firstEdgeID: EdgeID) -> [EdgeID] {
        let topology = StandardBoardTopologyV1.standard()
        guard canPlayRoadBuilding(for: player) else {
            return []
        }
        guard firstEdgeID >= 0, firstEdgeID < topology.edges.count else {
            return []
        }
        guard roadsByEdge[firstEdgeID] == nil, isRoadConnected(firstEdgeID, player: player, roads: roadsByEdge) else {
            return []
        }

        var roadsAfterFirst = roadsByEdge
        roadsAfterFirst[firstEdgeID] = player
        return topology.edges.indices.filter { secondEdgeID in
            guard secondEdgeID != firstEdgeID else {
                return false
            }
            guard roadsAfterFirst[secondEdgeID] == nil else {
                return false
            }
            return isRoadConnected(secondEdgeID, player: player, roads: roadsAfterFirst)
        }
    }

    func canRevealVictoryPoint(for actor: String, winningGoal: Int = 10) -> Bool {
        guard
            phase == .turn,
            turnState?.step.allowsDevCardPlay == true,
            currentPlayer == actor
        else {
            return false
        }

        let hiddenVictoryPoints = (devCardsByPlayer[actor] ?? .zero).victoryPoint + (newDevCardsByPlayer[actor] ?? .zero).victoryPoint
        guard hiddenVictoryPoints > 0 else {
            return false
        }

        return victoryPoints(for: actor, in: self) + hiddenVictoryPoints >= winningGoal
    }

    func firstLegalRoadEdge(for player: String) -> EdgeID? {
        legalBuildRoadEdges(for: player).first
    }

    func legalBuildRoadEdges(for player: String) -> [EdgeID] {
        let topology = StandardBoardTopologyV1.standard()
        guard phase == .turn, turnState?.step == .afterRoll, currentPlayer == player else {
            return []
        }

        let hand = resourcesByPlayer[player] ?? .zero
        let cost = ResourceHandV1(wood: 1, brick: 1)
        guard canAfford(hand: hand, cost: cost) else {
            return []
        }

        let roadCount = roadsByEdge.values.filter { $0 == player }.count
        guard roadCount < 15 else {
            return []
        }

        return topology.edges.indices.filter { edgeID in
            roadsByEdge[edgeID] == nil && isRoadConnected(edgeID, player: player, roads: roadsByEdge)
        }
    }

    func firstLegalSettlementNode(for player: String) -> NodeID? {
        legalBuildSettlementNodes(for: player).first
    }

    func legalBuildSettlementNodes(for player: String) -> [NodeID] {
        let topology = StandardBoardTopologyV1.standard()
        guard phase == .turn, turnState?.step == .afterRoll, currentPlayer == player else {
            return []
        }

        let hand = resourcesByPlayer[player] ?? .zero
        let cost = ResourceHandV1(wood: 1, brick: 1, sheep: 1, wheat: 1)
        guard canAfford(hand: hand, cost: cost) else {
            return []
        }

        let settlementCount = settlementsByNode.values.filter { $0 == player }.count
        guard settlementCount < 5 else {
            return []
        }

        let occupiedNodes = Set(settlementsByNode.keys).union(Set(citiesByNode.keys))
        return (0 ..< topology.nodesCount).filter { nodeID in
            if occupiedNodes.contains(nodeID) {
                return false
            }

            let adjacent = Set(topology.nodes(adjacentTo: nodeID))
            if !adjacent.isDisjoint(with: occupiedNodes) {
                return false
            }

            return topology.edges(incidentTo: nodeID).contains { roadsByEdge[$0] == player }
        }
    }

    func firstUpgradeableCityNode(for player: String) -> NodeID? {
        legalBuildCityNodes(for: player).first
    }

    func legalBuildCityNodes(for player: String) -> [NodeID] {
        guard phase == .turn, turnState?.step == .afterRoll, currentPlayer == player else {
            return []
        }

        let hand = resourcesByPlayer[player] ?? .zero
        let cost = ResourceHandV1(wheat: 2, ore: 3)
        guard canAfford(hand: hand, cost: cost) else {
            return []
        }

        let cityCount = citiesByNode.values.filter { $0 == player }.count
        guard cityCount < 4 else {
            return []
        }

        return settlementsByNode
            .filter { $0.value == player }
            .keys
            .sorted()
    }

    func legalSetupSettlementNodes(for player: String) -> [NodeID] {
        let topology = StandardBoardTopologyV1.standard()
        guard phase == .setup,
              currentPlayer == player,
              let setupState,
              setupState.step == .placeSettlement
        else {
            return []
        }

        let occupiedNodes = occupiedSetupSettlementNodes(from: setupState.placements)
        return (0 ..< topology.nodesCount).filter { nodeID in
            guard !occupiedNodes.contains(nodeID) else {
                return false
            }

            let adjacentNodes = Set(topology.nodes(adjacentTo: nodeID))
            return adjacentNodes.isDisjoint(with: occupiedNodes)
        }
    }

    func legalSetupRoadEdges(for player: String) -> [EdgeID] {
        let topology = StandardBoardTopologyV1.standard()
        guard phase == .setup,
              currentPlayer == player,
              let setupState,
              setupState.step == .placeRoad,
              let anchorNode = setupState.lastPlacedSettlementNode
        else {
            return []
        }

        let occupiedEdges = occupiedSetupRoadEdges(from: setupState.placements)
        return topology.edges(incidentTo: anchorNode)
            .filter { !occupiedEdges.contains($0) }
            .sorted()
    }

    func legalRobberMoveTiles(for player: String) -> [TileID] {
        guard phase == .turn,
              turnState?.step == .needsRobberMove,
              currentPlayer == player,
              let board
        else {
            return []
        }

        return board.resourcesByTile.indices.filter { $0 != board.robberTile }
    }

    func robberVictimCandidateNodes(for player: String) -> [NodeID] {
        let topology = StandardBoardTopologyV1.standard()
        guard phase == .turn,
              turnState?.step == .needsRobberSteal,
              currentPlayer == player,
              let board,
              board.robberTile >= 0,
              board.robberTile < topology.tiles.count
        else {
            return []
        }

        let eligibleVictims = Set(turnState?.eligibleStealVictims ?? [])
        return Array(
            Set(
                topology.tiles[board.robberTile].nodes.filter { nodeID in
                    if let owner = citiesByNode[nodeID] {
                        return eligibleVictims.contains(owner)
                    }
                    if let owner = settlementsByNode[nodeID] {
                        return eligibleVictims.contains(owner)
                    }
                    return false
                }
            )
        )
        .sorted()
    }

    func defaultDiscard(for player: String) -> ResourceHandV1? {
        guard let turnState, let required = turnState.discardRequirementsByPlayer[player], required > 0 else {
            return nil
        }

        let hand = resourcesByPlayer[player] ?? .zero
        var remaining = required
        var discarded = ResourceHandV1.zero

        for resource in Self.tradeableResources {
            let take = min(hand.count(for: resource), remaining)
            discarded = discarded.adding(take, for: resource)
            remaining -= take
        }

        return remaining == 0 ? discarded : nil
    }

    func defaultTradeProposal(for actor: String) -> ResourceExchangeV1? {
        let hand = resourcesByPlayer[actor] ?? .zero
        let orderedResources = Self.tradeableResources.map { ($0, hand.count(for: $0)) }

        guard let giveResource = orderedResources.first(where: { $0.1 > 0 })?.0 else {
            return nil
        }
        guard let receiveResource = orderedResources.first(where: { $0.0 != giveResource })?.0 else {
            return nil
        }

        return ResourceExchangeV1(
            give: ResourceHandV1.zero.adding(1, for: giveResource),
            receive: ResourceHandV1.zero.adding(1, for: receiveResource)
        )
    }

    func defaultMaritimeTrade(for actor: String) -> MaritimeTradeQuoteV1? {
        maritimeTradeQuotes(for: actor).first
    }

    func maritimeTradeQuotes(for actor: String) -> [MaritimeTradeQuoteV1] {
        guard let board else {
            return []
        }

        let hand = resourcesByPlayer[actor] ?? .zero
        var quotes: [MaritimeTradeQuoteV1] = []
        for giveResource in Self.tradeableResources {
            let ratio = bestMaritimeTradeRatio(for: actor, giveResource: giveResource, board: board)
            guard hand.count(for: giveResource) >= ratio else {
                continue
            }

            for receiveResource in Self.tradeableResources where receiveResource != giveResource {
                guard bankResources.count(for: receiveResource) >= 1 else {
                    continue
                }
                quotes.append(
                    MaritimeTradeQuoteV1(
                        give: ResourceHandV1.zero.adding(ratio, for: giveResource),
                        receive: ResourceHandV1.zero.adding(1, for: receiveResource),
                        ratio: ratio
                    )
                )
            }
        }

        return quotes
    }

    private static var tradeableResources: [ResourceV1] {
        [.wood, .brick, .sheep, .wheat, .ore]
    }

    private func canPlayRoadBuilding(for player: String) -> Bool {
        let roadCount = roadsByEdge.values.filter { $0 == player }.count
        return
            phase == .turn &&
            turnState?.step.allowsDevCardPlay == true &&
            currentPlayer == player &&
            !devCardActionPlayedThisTurn &&
            (devCardsByPlayer[player] ?? .zero).roadBuilding > 0 &&
            roadCount <= 13
    }

    private func resourceOrder(_ resource: ResourceV1) -> Int {
        Self.tradeableResources.firstIndex(of: resource) ?? .max
    }

    private func canAfford(hand: ResourceHandV1, cost: ResourceHandV1) -> Bool {
        hand.wood >= cost.wood &&
            hand.brick >= cost.brick &&
            hand.sheep >= cost.sheep &&
            hand.wheat >= cost.wheat &&
            hand.ore >= cost.ore
    }

    private func isRoadConnected(_ edgeID: EdgeID, player: String, roads: [EdgeID: String]) -> Bool {
        let topology = StandardBoardTopologyV1.standard()
        let edge = topology.edges[edgeID]
        let nodes = [edge.a, edge.b]

        for node in nodes {
            if settlementsByNode[node] == player || citiesByNode[node] == player {
                return true
            }
            if settlementsByNode[node] != nil || citiesByNode[node] != nil {
                continue
            }
            for adjacentEdge in topology.edges(incidentTo: node) where adjacentEdge != edgeID {
                if roads[adjacentEdge] == player {
                    return true
                }
            }
        }

        return false
    }

    private func occupiedSetupSettlementNodes(from placements: [String: PlayerSetupPlacementsV1]) -> Set<NodeID> {
        Set(placements.values.flatMap { placement in
            [placement.settlement1, placement.settlement2].compactMap { $0 }
        })
    }

    private func occupiedSetupRoadEdges(from placements: [String: PlayerSetupPlacementsV1]) -> Set<EdgeID> {
        Set(placements.values.flatMap { placement in
            [placement.road1, placement.road2].compactMap { $0 }
        })
    }

    private func bestMaritimeTradeRatio(
        for actor: String,
        giveResource: ResourceV1,
        board: BoardSetupV1
    ) -> Int {
        let topology = StandardBoardTopologyV1.standard()
        var hasThreeToOne = false
        var hasMatchingTwoToOne = false

        for portIndex in board.portsByIndex.indices {
            guard portIndex < topology.ports.count else {
                continue
            }

            let port = topology.ports[portIndex]
            let edge = topology.edges[port.edge]
            let ownsPort =
                settlementsByNode[edge.a] == actor ||
                settlementsByNode[edge.b] == actor ||
                citiesByNode[edge.a] == actor ||
                citiesByNode[edge.b] == actor
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
}
