import ULS_CoreGame

enum GameRobberVictimOptionBuilder {
    static func build(
        state: CoreGameStateV1?,
        actingAs: String?
    ) -> [GameRobberVictimOption] {
        guard
            let state,
            state.phase == .turn,
            state.turnState?.step == .needsRobberSteal,
            let actingAs,
            actingAs == state.currentPlayer
        else {
            return []
        }

        let visibleHandCounts = Dictionary(
            uniqueKeysWithValues: state.visibleResourceHands(for: actingAs).map { ($0.player, $0.totalCount) }
        )

        return (state.turnState?.eligibleStealVictims ?? []).sorted().map { victim in
            GameRobberVictimOption(
                playerID: victim,
                displayName: shortIdentifier(victim),
                handCount: visibleHandCounts[victim] ?? 0
            )
        }
    }

    private static func shortIdentifier(_ value: String) -> String {
        String(value.prefix(8))
    }
}
