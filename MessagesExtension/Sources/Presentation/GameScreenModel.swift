struct GameScreenModel: Equatable {
    let header: GameHeaderModel
    let opponents: [GameOpponentSummary]
    let board: GameBoardPlaceholderModel
    let handTray: GameHandTrayModel
    let actionDock: GameActionDockModel
}
