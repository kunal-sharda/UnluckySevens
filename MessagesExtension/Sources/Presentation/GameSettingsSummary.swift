import ULS_CoreGame

struct GameSettingsSummary: Equatable {
    let rules: String
    let board: String
    let victory: String

    init(boardStrategy: BoardGenStrategyV1? = nil) {
        rules = "Standard"
        victory = "10 points"
        switch boardStrategy ?? BoardStrategyDefaults.newGame {
        case .noRedAdjacentV1:
            board = "Balanced"
        case .randomV1:
            board = "Classic random"
        }
    }
}
