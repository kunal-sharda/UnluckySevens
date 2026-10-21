import ULS_CoreGame

enum LobbyReconciliationPublicationResolver {
    static func pendingResolution(
        state: CoreGameStateV1?,
        localParticipant: String?,
        hasBoundSession: Bool,
        observedStates: [CoreGameStateV1]
    ) -> LobbyReconciliationResolutionV1? {
        guard
            let state,
            state.phase == .lobby,
            let localParticipant,
            state.roster.first == localParticipant,
            hasBoundSession,
            let resolution = try? reconcileLobbyV1(
                anchor: state,
                observedStates: observedStates,
                actor: localParticipant
            ),
            resolution.state != nil
        else {
            return nil
        }
        return resolution
    }
}
