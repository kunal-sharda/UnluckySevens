struct GameActionAvailability: Equatable {
    let canRoll: Bool
    let canBuild: Bool
    let canTrade: Bool
    let canBuyDevCard: Bool
    let canPlayDevCards: Bool
    let canEndTurn: Bool

    var canUseDevCards: Bool {
        canBuyDevCard || canPlayDevCards
    }

    static let none = GameActionAvailability(
        canRoll: false,
        canBuild: false,
        canTrade: false,
        canBuyDevCard: false,
        canPlayDevCards: false,
        canEndTurn: false
    )
}
