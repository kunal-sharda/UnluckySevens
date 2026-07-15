struct GameInfoModel: Equatable {
    let players: [GameInfoPlayerSummary]
    let recapText: String?

    static let empty = GameInfoModel(players: [], recapText: nil)
}
