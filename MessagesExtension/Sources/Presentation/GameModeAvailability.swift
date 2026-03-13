struct GameModeAvailability: Equatable {
    let canSetup: Bool
    let canBuildRoad: Bool
    let canBuildSettlement: Bool
    let canBuildCity: Bool
    let canRobberMove: Bool
    let canRobberVictim: Bool
    let canTrade: Bool
    let canPlayDevCard: Bool
    let canDiscard: Bool

    static let none = GameModeAvailability(
        canSetup: false,
        canBuildRoad: false,
        canBuildSettlement: false,
        canBuildCity: false,
        canRobberMove: false,
        canRobberVictim: false,
        canTrade: false,
        canPlayDevCard: false,
        canDiscard: false
    )
}
