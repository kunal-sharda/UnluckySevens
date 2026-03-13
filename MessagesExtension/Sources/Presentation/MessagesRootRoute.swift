import ULS_CoreGame

enum MessagesRootRoute: Equatable {
    case lobby
    case game

    static func resolve(phase: PhaseV1?) -> Self {
        guard let phase else {
            return .lobby
        }

        switch phase {
        case .lobby:
            return .lobby
        case .setup, .turn, .gameOver:
            return .game
        }
    }
}
