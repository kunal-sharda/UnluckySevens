struct GameEndScoreBreakdown: Equatable {
    let buildingPoints: Int
    let developmentCardPoints: Int
    let largestArmyPoints: Int
    let longestRoadPoints: Int

    var parts: [String] {
        [
            buildingPoints > 0 ? "Buildings \(buildingPoints)" : nil,
            developmentCardPoints > 0 ? "VP cards \(developmentCardPoints)" : nil,
            largestArmyPoints > 0 ? "Largest Army \(largestArmyPoints)" : nil,
            longestRoadPoints > 0 ? "Longest Road \(longestRoadPoints)" : nil,
        ]
        .compactMap { $0 }
    }
}
