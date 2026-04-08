import ULS_CoreGame

enum ProductActorResolver {
    static func resolve(
        localParticipant: String?,
        state: CoreGameStateV1?
    ) -> String? {
        guard
            let localParticipant,
            let state,
            state.roster.contains(localParticipant)
        else {
            return nil
        }

        return localParticipant
    }
}
