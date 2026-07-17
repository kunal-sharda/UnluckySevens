struct GameDiceRollResult: Equatable {
    let first: Int
    let second: Int

    var total: Int { first + second }
}
