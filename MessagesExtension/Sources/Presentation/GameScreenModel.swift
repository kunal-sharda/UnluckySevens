struct GameScreenModel: Equatable {
    let header: GameHeaderModel
    let opponents: [GameOpponentSummary]
    let board: GameBoardPlaceholderModel
    let boardRenderModel: GameBoardRenderModel?
    let handTray: GameHandTrayModel
    let actionDock: GameActionDockModel
    let modeAvailability: GameModeAvailability
}
