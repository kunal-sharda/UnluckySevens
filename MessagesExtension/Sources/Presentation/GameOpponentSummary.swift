struct GamePlayerTint: Equatable {
    let red: Double
    let green: Double
    let blue: Double
}

struct GameOpponentSummary: Identifiable, Equatable {
    let id: String
    let displayName: String
    let playerTint: GamePlayerTint
    let victoryPoints: Int
    let handCount: Int
    let isCurrentPlayer: Bool
}
