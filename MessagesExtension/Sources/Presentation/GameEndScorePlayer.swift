struct GameEndScorePlayer: Identifiable, Equatable {
    let id: String
    let displayName: String
    let playerTint: GamePlayerTint
    let victoryPoints: Int
    let isWinner: Bool
    let isLocalPlayer: Bool
    let awardLabels: [String]
    let scoreBreakdown: GameEndScoreBreakdown
}
