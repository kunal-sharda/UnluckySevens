import ULS_CoreGame
import ULS_Transport

enum GameDiscardPanelModelBuilder {
    static func build(
        state: CoreGameStateV1?,
        actingAs: String?,
        selectedTurnIntent: ULS_Transport.TurnIntentV1?
    ) -> GameDiscardPanelModel? {
        guard
            let state,
            state.phase == .turn,
            state.turnState?.step == .pendingDiscards
        else {
            return nil
        }

        let waitingPlayers = waitingPlayers(in: state)

        if let actingAs,
           let requiredCount = state.turnState?.discardRequirementsByPlayer[actingAs],
           requiredCount > 0,
           let suggested = state.defaultDiscard(for: actingAs) {
            let action: GameDiscardPanelModel.Action = if actingAs == state.currentPlayer {
                .publishSuggestedDiscard(requiredCount: requiredCount, suggested: handChips(from: suggested))
            } else {
                .sendSuggestedDiscard(requiredCount: requiredCount, suggested: handChips(from: suggested))
            }

            return GameDiscardPanelModel(waitingPlayers: waitingPlayers, action: action)
        }

        if actingAs == state.currentPlayer,
           let selectedTurnIntent,
           selectedTurnIntent.kind == .submitDiscard,
           selectedTurnIntent.gameId == state.gameId,
           selectedTurnIntent.anchorRev == state.rev,
           selectedTurnIntent.anchorHash == state.stateHash,
           let discardPlayer = selectedTurnIntent.discardPlayer,
           let discarded = selectedTurnIntent.discarded {
            return GameDiscardPanelModel(
                waitingPlayers: waitingPlayers,
                action: .applySelectedDiscard(
                    playerDisplay: shortIdentifier(discardPlayer),
                    suggested: handChips(from: discarded)
                )
            )
        }

        return GameDiscardPanelModel(waitingPlayers: waitingPlayers, action: nil)
    }

    private static func waitingPlayers(in state: CoreGameStateV1) -> [String] {
        let submitted = state.turnState?.submittedDiscardsByPlayer ?? [:]
        return (state.turnState?.discardRequirementsByPlayer ?? [:])
            .keys
            .filter { submitted[$0] == nil }
            .sorted()
            .map(shortIdentifier)
    }

    private static func shortIdentifier(_ value: String) -> String {
        String(value.prefix(8))
    }

    private static func handChips(from hand: ResourceHandV1) -> [GameHandChip] {
        [
            GameHandChip(resource: .wood, count: hand.wood),
            GameHandChip(resource: .brick, count: hand.brick),
            GameHandChip(resource: .sheep, count: hand.sheep),
            GameHandChip(resource: .wheat, count: hand.wheat),
            GameHandChip(resource: .ore, count: hand.ore),
        ]
        .filter { $0.count > 0 }
    }

    private static func handChips(from hand: TransportResourceHandV1) -> [GameHandChip] {
        [
            GameHandChip(resource: .wood, count: hand.wood),
            GameHandChip(resource: .brick, count: hand.brick),
            GameHandChip(resource: .sheep, count: hand.sheep),
            GameHandChip(resource: .wheat, count: hand.wheat),
            GameHandChip(resource: .ore, count: hand.ore),
        ]
        .filter { $0.count > 0 }
    }
}
