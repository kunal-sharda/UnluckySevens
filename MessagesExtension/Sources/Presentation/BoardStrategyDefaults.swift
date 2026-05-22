import ULS_CoreGame

enum BoardStrategyDefaults {
    static let newGame: BoardGenStrategyV1 = .noRedAdjacentV1
    static let desertPlacement: BoardDesertPlacementV1 = .anywhereV1
    static let targetPlayerCount = CoreGameStateV1.defaultTargetPlayerCount
}
