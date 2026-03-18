import ULS_CoreGame

enum GameShellStatusLineResolver {
    static func resolve(
        hasTradePending: Bool,
        actingAs: String?,
        currentPlayer: String?,
        currentPlayerDisplay: String,
        subtitle: String,
        turnStep: TurnStepV1? = nil,
        discardRequiredForActingPlayer: Bool = false
    ) -> GameShellStatusLine {
        if hasTradePending {
            return GameShellStatusLine(title: "Trade pending", subtitle: subtitle)
        }

        switch turnStep {
        case .pendingDiscards:
            if discardRequiredForActingPlayer {
                return GameShellStatusLine(title: "Discard required", subtitle: subtitle)
            }
            return GameShellStatusLine(title: "Waiting on discards", subtitle: subtitle)
        case .needsRobberMove:
            if actingAs == currentPlayer {
                return GameShellStatusLine(title: "Move the robber", subtitle: subtitle)
            }
        case .needsRobberSteal:
            if actingAs == currentPlayer {
                return GameShellStatusLine(title: "Steal a card", subtitle: subtitle)
            }
        default:
            break
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
