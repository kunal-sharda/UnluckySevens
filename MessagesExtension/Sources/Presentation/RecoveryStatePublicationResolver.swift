import ULS_CoreGame

enum RecoveryStatePublicationResolver {
    static func resolve(
        state: CoreGameStateV1,
        actor: String
    ) throws -> CoreGameStateV1 {
        try validateCanonicalSnapshot(state)
        guard state.roster.contains(actor) else {
            throw CoreGameError.actorMismatch
        }
        return state
    }
}
