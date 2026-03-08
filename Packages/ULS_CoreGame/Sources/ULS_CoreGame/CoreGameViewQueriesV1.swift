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
        let topology = StandardBoardTopologyV1.standard()
        guard tileID >= 0, tileID < topology.tiles.count else {
            return nil
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

        return victims.sorted().first
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

    func defaultRoadBuildingEdges(for player: String) -> EdgePairV1? {
        let topology = StandardBoardTopologyV1.standard()
        let roadCount = roadsByEdge.values.filter { $0 == player }.count
        guard roadCount <= 13 else {
            return nil
        }

        for firstEdge in topology.edges.indices where roadsByEdge[firstEdge] == nil {
            if !isRoadConnected(firstEdge, player: player, roads: roadsByEdge) {
                continue
            }

            var roadsAfterFirst = roadsByEdge
            roadsAfterFirst[firstEdge] = player
            for secondEdge in topology.edges.indices where secondEdge != firstEdge && roadsAfterFirst[secondEdge] == nil {
                if isRoadConnected(secondEdge, player: player, roads: roadsAfterFirst) {
                    return EdgePairV1(firstEdgeID: firstEdge, secondEdgeID: secondEdge)
                }
            }
        }

        return nil
    }

    func firstLegalRoadEdge(for player: String) -> EdgeID? {
        let topology = StandardBoardTopologyV1.standard()
        let roadCount = roadsByEdge.values.filter { $0 == player }.count
        guard roadCount < 15 else {
            return nil
        }

        for edgeID in topology.edges.indices where roadsByEdge[edgeID] == nil {
            if isRoadConnected(edgeID, player: player, roads: roadsByEdge) {
                return edgeID
            }
        }

        return nil
    }

    func firstLegalSettlementNode(for player: String) -> NodeID? {
        let topology = StandardBoardTopologyV1.standard()
        let settlementCount = settlementsByNode.values.filter { $0 == player }.count
        guard settlementCount < 5 else {
            return nil
        }

        let occupiedNodes = Set(settlementsByNode.keys).union(Set(citiesByNode.keys))
        for nodeID in 0 ..< topology.nodesCount {
            if occupiedNodes.contains(nodeID) {
                continue
            }

            let adjacent = Set(topology.nodes(adjacentTo: nodeID))
            if !adjacent.isDisjoint(with: occupiedNodes) {
                continue
            }

            let hasRoad = topology.edges(incidentTo: nodeID).contains { roadsByEdge[$0] == player }
            if hasRoad {
                return nodeID
            }
        }

        return nil
    }

    func firstUpgradeableCityNode(for player: String) -> NodeID? {
        let cityCount = citiesByNode.values.filter { $0 == player }.count
        guard cityCount < 4 else {
            return nil
        }

        return settlementsByNode
            .filter { $0.value == player }
            .keys
            .sorted()
            .first
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
        guard let board else {
            return nil
        }

        let hand = resourcesByPlayer[actor] ?? .zero
        for giveResource in Self.tradeableResources {
            let ratio = bestMaritimeTradeRatio(for: actor, giveResource: giveResource, board: board)
            guard hand.count(for: giveResource) >= ratio else {
                continue
            }

            for receiveResource in Self.tradeableResources where receiveResource != giveResource {
                guard bankResources.count(for: receiveResource) >= 1 else {
                    continue
                }
                return MaritimeTradeQuoteV1(
                    give: ResourceHandV1.zero.adding(ratio, for: giveResource),
                    receive: ResourceHandV1.zero.adding(1, for: receiveResource),
                    ratio: ratio
                )
            }
        }

        return nil
    }

    private static var tradeableResources: [ResourceV1] {
        [.wood, .brick, .sheep, .wheat, .ore]
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
