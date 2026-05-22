import ULS_CoreGame

struct LobbySetupOptionsModel: Equatable {
    let targetPlayerCount: Int
    let boardStrategy: BoardGenStrategyV1
    let desertPlacement: BoardDesertPlacementV1
    let isEditable: Bool
    let summaryText: String
}
