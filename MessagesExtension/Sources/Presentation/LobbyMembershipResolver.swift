import ULS_CoreGame
import ULS_Transport

enum LobbyMembershipResolver {
    static func canJoin(
        state: CoreGameStateV1?,
        localParticipant: String?,
        pendingJoiners: [String]
    ) -> Bool {
        guard
            let state,
            state.phase == .lobby,
            let localParticipant
        else {
            return false
        }

        return !state.roster.contains(localParticipant) && !pendingJoiners.contains(localParticipant)
    }

    static func canStart(
        state: CoreGameStateV1?,
        localParticipant: String?,
        pendingJoiners: [String]
    ) -> Bool {
        guard
            let state,
            state.phase == .lobby,
            state.rev == 0,
            let inviter = state.roster.first,
            inviter == localParticipant
        else {
            return false
        }

        return finalRoster(state: state, pendingJoiners: pendingJoiners).count >= 2
    }

    static func finalRoster(
        state: CoreGameStateV1?,
        pendingJoiners: [String]
    ) -> [String] {
        guard
            let state,
            state.phase == .lobby,
            let inviter = state.roster.first
        else {
            return []
        }

        var finalRoster: [String] = [inviter]
        for joiner in pendingJoiners where joiner != inviter && !finalRoster.contains(joiner) {
            finalRoster.append(joiner)
        }
        return finalRoster
    }

    static func makeJoinIntent(
        state: CoreGameStateV1?,
        localParticipant: String?
    ) -> JoinIntentV1? {
        guard
            let state,
            state.phase == .lobby,
            let localParticipant
        else {
            return nil
        }

        return JoinIntentV1(
            gameId: state.gameId,
            anchorRev: state.rev,
            anchorHash: state.stateHash,
            actor: localParticipant
        )
    }
}
