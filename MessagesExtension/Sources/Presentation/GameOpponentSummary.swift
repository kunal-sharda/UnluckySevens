struct GameOpponentSummary: Identifiable, Equatable {
    let id: String
    let displayName: String
    let victoryPoints: Int
    let handCount: Int
    let isCurrentPlayer: Bool
}
