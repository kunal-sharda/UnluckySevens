import ULS_CoreGame

enum LobbyDisplayNameDraftResolver {
    static func resolve(
        state: CoreGameStateV1?,
        localParticipant: String?,
        preferredDisplayName: String
    ) -> String {
        guard
            let state,
            state.phase == .lobby,
            let localParticipant
        else {
            return preferredDisplayName
        }

        if let customDisplayName = state.playerDisplayNamesByPlayer[localParticipant] {
            return customDisplayName
        }

        if state.roster.contains(localParticipant) {
            return ""
        }

        return preferredDisplayName
    }
}
