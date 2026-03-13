enum GameShellStatusLineResolver {
    static func resolve(
        hasTradePending: Bool,
        actingAs: String?,
        currentPlayer: String?,
        currentPlayerDisplay: String,
        subtitle: String
    ) -> GameShellStatusLine {
        if hasTradePending {
            return GameShellStatusLine(title: "Trade pending", subtitle: subtitle)
        }

        guard let currentPlayer, !currentPlayer.isEmpty, currentPlayer != "-" else {
            return GameShellStatusLine(title: "Open game", subtitle: subtitle)
        }

        if actingAs == currentPlayer {
            return GameShellStatusLine(title: "Your turn", subtitle: subtitle)
        }

        return GameShellStatusLine(title: "Waiting on \(currentPlayerDisplay)", subtitle: subtitle)
    }
}
