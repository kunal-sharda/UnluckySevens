import ULS_CoreGame

struct ActiveGameRecoverySummary: Identifiable, Equatable {
    let id: String
    let gameId: String
    let title: String
    let subtitle: String
    let detail: String
    let isLastActive: Bool
    let isCurrentSelection: Bool
}

enum ActiveGameRecoveryModelBuilder {
    static func build(
        from state: CoreGameStateV1,
        isLastActive: Bool,
        isCurrentSelection: Bool
    ) -> ActiveGameRecoverySummary {
        let currentPlayerName = PlayerPseudonymResolver.displayName(for: state.currentPlayer, in: state)

        let title: String
        switch state.phase {
        case .lobby:
            title = "Lobby"
        case .setup:
            title = "Setup — \(currentPlayerName)"
        case .turn:
            title = "\(currentPlayerName)'s turn"
        case .gameOver:
            let winnerName = PlayerPseudonymResolver.displayName(for: state.winnerPlayer, in: state)
            title = "\(winnerName) won"
        }

        let subtitle = "rev \(state.rev) · \(state.phase.rawValue.capitalized) · \(state.roster.count) players"
        let detail = shortGameIdentifier(state.gameId)

        return ActiveGameRecoverySummary(
            id: state.gameId,
            gameId: state.gameId,
            title: title,
            subtitle: subtitle,
            detail: detail,
            isLastActive: isLastActive,
            isCurrentSelection: isCurrentSelection
        )
    }

    private static func shortGameIdentifier(_ gameId: String) -> String {
        if gameId.count <= 12 {
            return gameId
        }
        return "\(gameId.prefix(6))...\(gameId.suffix(4))"
    }
}
