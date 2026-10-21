import Foundation

/// Terminalization can reveal several VP cards alongside the winning action.
/// Validate the whole successor by replay, rather than weakening individual
/// action validators to accept arbitrary inventory changes on game over.
func matchesWinningTurnTransition(from: CoreGameStateV1, to: CoreGameStateV1, actor: String) -> Bool {
    guard from.phase == .turn, to.phase == .gameOver,
          to.gameResult?.reason == .victory, let action = to.auditLog.last?.action else { return false }
    var intents: [TurnIntentV1] = []
    switch action {
    case .buyDevCard: intents = [.buyDevCard]
    case .revealVictoryPoint: intents = [.revealVictoryPoint]
    case .endTurn: intents = [.endTurn]
    case .rollDice: intents = [.rollDice]
    case .buildSettlement:
        intents = to.settlementsByNode.keys.filter { from.settlementsByNode[$0] == nil }
            .map { .buildSettlement(nodeID: $0) }
    case .buildCity:
        intents = to.citiesByNode.keys.filter { from.citiesByNode[$0] == nil }
            .map { .buildCity(nodeID: $0) }
    case .buildRoad:
        intents = to.roadsByEdge.keys.filter { from.roadsByEdge[$0] == nil }
            .map { .buildRoad(edgeID: $0) }
    case .playRoadBuilding:
        let edges = to.roadsByEdge.keys.filter { from.roadsByEdge[$0] == nil }.sorted()
        if edges.count == 2 {
            intents = [.playRoadBuilding(firstEdgeID: edges[0], secondEdgeID: edges[1]),
                       .playRoadBuilding(firstEdgeID: edges[1], secondEdgeID: edges[0])]
        }
    case .playKnight:
        if let tile = to.board?.robberTile {
            intents = ([nil] + from.roster.map(Optional.some)).map { .playKnight(tileID: tile, victimPlayer: $0) }
        }
    default: return false
    }
    return intents.contains { (try? apply(intent: $0, to: from, actor: actor)) == to }
}
