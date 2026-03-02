import Foundation

private let awardsTopology = StandardBoardTopologyV1.standard()

internal struct AwardStateV1: Equatable {
    let largestArmyOwner: String?
    let largestArmySize: Int
    let longestRoadOwner: String?
    let longestRoadLength: Int
}

internal func recomputeAwards(from previous: CoreGameStateV1, for state: CoreGameStateV1) -> AwardStateV1 {
    let largestArmy = resolveLargestArmy(
        roster: state.roster,
        knightsPlayedByPlayer: state.knightsPlayedByPlayer,
        previousOwner: previous.largestArmyOwner
    )
    let longestRoad = resolveLongestRoad(
        roster: state.roster,
        roadsByEdge: state.roadsByEdge,
        settlementsByNode: state.settlementsByNode,
        citiesByNode: state.citiesByNode,
        previousOwner: previous.longestRoadOwner
    )
    return AwardStateV1(
        largestArmyOwner: largestArmy.owner,
        largestArmySize: largestArmy.size,
        longestRoadOwner: longestRoad.owner,
        longestRoadLength: longestRoad.length
    )
}

private func resolveLargestArmy(
    roster: [String],
    knightsPlayedByPlayer: [String: Int],
    previousOwner: String?
) -> (owner: String?, size: Int) {
    var counts: [String: Int] = [:]
    for player in roster {
        counts[player] = max(0, knightsPlayedByPlayer[player] ?? 0)
    }
    return resolveAwardOwner(
        counts: counts,
        threshold: 3,
        previousOwner: previousOwner
    )
}

private func resolveLongestRoad(
    roster: [String],
    roadsByEdge: [EdgeID: String],
    settlementsByNode: [NodeID: String],
    citiesByNode: [NodeID: String],
    previousOwner: String?
) -> (owner: String?, length: Int) {
    var lengths: [String: Int] = [:]
    for player in roster {
        lengths[player] = longestRoadLength(
            player: player,
            roadsByEdge: roadsByEdge,
            settlementsByNode: settlementsByNode,
            citiesByNode: citiesByNode
        )
    }
    let resolved = resolveAwardOwner(
        counts: lengths,
        threshold: 5,
        previousOwner: previousOwner
    )
    return (owner: resolved.owner, length: resolved.size)
}

private func resolveAwardOwner(
    counts: [String: Int],
    threshold: Int,
    previousOwner: String?
) -> (owner: String?, size: Int) {
    guard let maxCount = counts.values.max(), maxCount >= threshold else {
        return (owner: nil, size: 0)
    }

    let contenders = counts
        .filter { $0.value == maxCount }
        .map(\.key)
        .sorted()

    if let previousOwner, contenders.contains(previousOwner) {
        return (owner: previousOwner, size: maxCount)
    }
    if contenders.count == 1 {
        return (owner: contenders[0], size: maxCount)
    }
    return (owner: nil, size: maxCount)
}

private func longestRoadLength(
    player: String,
    roadsByEdge: [EdgeID: String],
    settlementsByNode: [NodeID: String],
    citiesByNode: [NodeID: String]
) -> Int {
    let ownedEdges = roadsByEdge
        .filter { $0.value == player }
        .map(\.key)
        .sorted()
    guard !ownedEdges.isEmpty else {
        return 0
    }
    let ownedEdgeSet = Set(ownedEdges)

    func canTraverse(through node: NodeID) -> Bool {
        if let settlementOwner = settlementsByNode[node], settlementOwner != player {
            return false
        }
        if let cityOwner = citiesByNode[node], cityOwner != player {
            return false
        }
        return true
    }

    func dfs(edgeID: EdgeID, fromNode: NodeID, visited: Set<EdgeID>) -> Int {
        let edge = awardsTopology.edges[edgeID]
        let nextNode = edge.a == fromNode ? edge.b : edge.a
        var best = 1
        if canTraverse(through: nextNode) {
            for adjacentEdge in awardsTopology.edges(incidentTo: nextNode).sorted()
                where adjacentEdge != edgeID &&
                ownedEdgeSet.contains(adjacentEdge) &&
                !visited.contains(adjacentEdge)
            {
                var nextVisited = visited
                nextVisited.insert(adjacentEdge)
                best = max(best, 1 + dfs(edgeID: adjacentEdge, fromNode: nextNode, visited: nextVisited))
            }
        }
        return best
    }

    var bestOverall = 0
    for edgeID in ownedEdges {
        let edge = awardsTopology.edges[edgeID]
        bestOverall = max(bestOverall, dfs(edgeID: edgeID, fromNode: edge.a, visited: [edgeID]))
        bestOverall = max(bestOverall, dfs(edgeID: edgeID, fromNode: edge.b, visited: [edgeID]))
    }
    return bestOverall
}
