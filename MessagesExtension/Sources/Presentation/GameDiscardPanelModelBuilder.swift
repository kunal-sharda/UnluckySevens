import ULS_CoreGame

enum GameDiscardPanelModelBuilder {
    static func build(
        state: CoreGameStateV1?,
        actingAs: String?
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
           let availableHand = state.resourcesByPlayer[actingAs] {
            let action: GameDiscardPanelModel.Action = if actingAs == state.currentPlayer {
                .publishDiscard(requiredCount: requiredCount, availableHand: handChips(from: availableHand))
            } else {
                .sendDiscard(requiredCount: requiredCount, availableHand: handChips(from: availableHand))
            }

            return GameDiscardPanelModel(waitingPlayers: waitingPlayers, action: action)
        }

        return GameDiscardPanelModel(waitingPlayers: waitingPlayers, action: nil)
    }

    private static func waitingPlayers(in state: CoreGameStateV1) -> [String] {
        let submitted = state.turnState?.submittedDiscardsByPlayer ?? [:]
        return (state.turnState?.discardRequirementsByPlayer ?? [:])
            .keys
            .filter { submitted[$0] == nil }
            .sorted()
            .map { playerName($0, in: state) }
    }

    private static func playerName(_ playerID: String, in state: CoreGameStateV1) -> String {
        PlayerPseudonymResolver.displayName(for: playerID, gameID: state.gameId, roster: state.roster)
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
}
