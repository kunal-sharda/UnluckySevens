struct GameActionAvailability: Equatable {
    let canRoll: Bool
    let canBuild: Bool
    let canTrade: Bool
    let canUseDevCards: Bool
    let canEndTurn: Bool

    static let none = GameActionAvailability(
        canRoll: false,
        canBuild: false,
        canTrade: false,
        canUseDevCards: false,
        canEndTurn: false
    )
}
