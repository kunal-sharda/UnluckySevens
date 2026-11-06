import ULS_CoreGame

enum GameContinuation {
    static func text(for state: CoreGameStateV1) -> String? {
        guard state.phase != .gameOver else { return nil }
        let name = PlayerPseudonymResolver.displayName(for: state.currentPlayer, in: state)
        if state.phase == .setup {
            return state.setupState?.step == .placeRoad
                ? "\(name) places a connected road next."
                : "\(name) places a settlement next."
        }
        guard state.phase == .turn else { return nil }
        if let vote = state.drawVote {
            let pending = state.activePlayers.filter { !vote.approvals.contains($0) }
                .map { PlayerPseudonymResolver.displayName(for: $0, in: state) }
            if !pending.isEmpty { return "Waiting for \(pending.joined(separator: ", ")) to vote on the draw." }
        }
        switch state.turnState?.step {
        case .needsRoll:
            return "\(name) rolls next or plays an eligible Dev Card."
        case .pendingDiscards:
            guard let player = state.nextDiscardingPlayer else { return "\(name) moves the robber next." }
            return "\(PlayerPseudonymResolver.displayName(for: player, in: state)) discards next."
        case .needsRobberMove:
            return "\(name) moves the robber next."
        case .needsRobberSteal:
            return "\(name) chooses a player to steal from."
        case .afterRoll:
            if state.activeTradeOffer != nil,
               let panel = GameTradePanelModelBuilder.build(state: state, actingAs: nil) {
                let waiting = panel.participantStatuses.filter { $0.isTargeted && $0.state == .waiting }
                    .map(\.displayName)
                if !waiting.isEmpty { return "Waiting for \(waiting.joined(separator: ", ")) to respond to the trade." }
            }
            return "\(name) continues their turn."
        case nil:
            return "\(name) acts next."
        }
    }
}
