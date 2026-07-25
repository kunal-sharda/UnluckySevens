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
            title = "Waiting for Players"
        case .setup:
            title = "\(currentPlayerName) is placing"
        case .turn:
            title = "\(currentPlayerName)'s turn"
        case .gameOver:
            let winnerName = PlayerPseudonymResolver.displayName(for: state.winnerPlayer, in: state)
            title = "\(winnerName) won"
        }

        let playerCount = state.roster.count
        let subtitle = playerCount == 1 ? "1 player" : "\(playerCount) players"
        let detail = ""

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

}
