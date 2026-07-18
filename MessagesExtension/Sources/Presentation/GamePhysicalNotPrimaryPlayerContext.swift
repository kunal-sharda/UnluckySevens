import ULS_CoreGame

enum GamePhysicalNotPrimaryPlayerContext: Equatable {
    case ordinaryWaiting
    case incomingTrade
    case waitingForDiscard

    static func resolve(
        state: CoreGameStateV1?,
        actingAs: String?,
        tradePanel: GameTradePanelModel?,
        discardPanel: GameDiscardPanelModel?
    ) -> Self? {
        guard
            let state,
            state.phase == .turn,
            let actingAs,
            actingAs != state.currentPlayer,
            let turnStep = state.turnState?.step
        else {
            return nil
        }

        switch turnStep {
        case .needsRoll:
            return .ordinaryWaiting
        case .afterRoll:
            guard
                tradePanel?.activeOffer != nil,
                tradePanel?.responderActions != nil
            else {
                return .ordinaryWaiting
            }
            return .incomingTrade
        case .pendingDiscards:
            guard discardPanel?.action == nil else {
                return nil
            }
            return .waitingForDiscard
        case .needsRobberMove, .needsRobberSteal:
            return nil
        }
    }

    var headerPrompt: GamePhysicalTurnHeaderPrompt? {
        switch self {
        case .ordinaryWaiting:
            return nil
        case .incomingTrade:
            return .answerTradeOffer
        case .waitingForDiscard:
            return nil
        }
    }

    var isWaitingForDiscard: Bool {
        self == .waitingForDiscard
    }

    func headerTitle(
        fallback: String,
        discardPanel: GameDiscardPanelModel?
    ) -> String {
        guard self == .waitingForDiscard else {
            return fallback
        }

        guard let nextPlayer = discardPanel?.waitingPlayers.first else {
            return "Waiting for discard"
        }
        return "Waiting for \(nextPlayer) to discard"
    }
}
