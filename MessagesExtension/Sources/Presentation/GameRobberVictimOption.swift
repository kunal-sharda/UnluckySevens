struct GameRobberVictimOption: Identifiable, Equatable {
    let playerID: String
    let displayName: String
    let handCount: Int

    var id: String {
        playerID
    }
}
