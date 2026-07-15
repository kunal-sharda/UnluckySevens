struct GameInfoPlayerSummary: Identifiable, Equatable {
    let id: String
    let displayName: String
    let playerTint: GamePlayerTint
    let victoryPoints: Int
    let resourceCardCount: Int
    let developmentCardCount: Int
    let isCurrentPlayer: Bool
    let isLocalPlayer: Bool
    let awardLabels: [String]
}
