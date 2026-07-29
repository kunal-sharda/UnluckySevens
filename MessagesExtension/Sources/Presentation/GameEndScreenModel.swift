struct GameEndScreenModel: Equatable {
    let winnerTitle: String
    let winningScoreText: String?
    let resultDetail: String?
    let players: [GameEndScorePlayer]
    let localDevelopmentCardGroups: [GameEndDevelopmentCardGroup]
    let recapText: String?
}
