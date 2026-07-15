struct GameScreenModel: Equatable {
    let header: GameHeaderModel
    let opponents: [GameOpponentSummary]
    let board: GameBoardPlaceholderModel
    let boardRenderModel: GameBoardRenderModel?
    let handTray: GameHandTrayModel
    let ownedDevCards: [GameOwnedDevCardSummary]
    let gameInfo: GameInfoModel
    let devDeckCount: Int
    let canBuyDevCard: Bool
    let actionDock: GameActionDockModel
    let modeAvailability: GameModeAvailability
}
