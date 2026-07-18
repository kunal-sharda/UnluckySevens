import ULS_CoreGame

enum GameShellStatusLineResolver {
    static func resolve(
        actingAs: String?,
        currentPlayer: String?,
        currentPlayerDisplay: String,
        subtitle: String,
        phase: PhaseV1? = nil,
        winnerDisplay: String? = nil,
        didLocalPlayerWin: Bool = false
    ) -> GameShellStatusLine {
        if phase == .gameOver {
            let title: String
            if didLocalPlayerWin {
                title = "You won"
            } else if let winnerDisplay {
                title = "\(winnerDisplay) won"
            } else {
                title = "Game over"
            }

            return GameShellStatusLine(title: title, subtitle: subtitle)
        }

        guard let currentPlayer, !currentPlayer.isEmpty, currentPlayer != "-" else {
            return GameShellStatusLine(title: "Open game", subtitle: subtitle)
        }

        if actingAs == currentPlayer {
            return GameShellStatusLine(title: "Your turn", subtitle: subtitle)
        }

        return GameShellStatusLine(title: "\(currentPlayerDisplay)'s Turn", subtitle: subtitle)
    }
}
