import Foundation

public func victoryPoints(for player: String, in state: CoreGameStateV1) -> Int {
    let settlements = state.settlementsByNode.values.filter { $0 == player }.count
    let cities = state.citiesByNode.values.filter { $0 == player }.count
    let revealedVP = state.revealedVictoryPointsByPlayer[player] ?? 0
    let largestArmy = state.largestArmyOwner == player ? 2 : 0
    let longestRoad = state.longestRoadOwner == player ? 2 : 0
    return settlements + (2 * cities) + revealedVP + largestArmy + longestRoad
}

public func victoryPointsByPlayer(in state: CoreGameStateV1) -> [String: Int] {
    var result: [String: Int] = [:]
    for player in state.roster {
        result[player] = victoryPoints(for: player, in: state)
    }
    return result
}
