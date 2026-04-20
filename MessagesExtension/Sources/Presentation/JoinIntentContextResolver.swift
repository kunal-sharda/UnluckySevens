import ULS_CoreGame
import ULS_Transport

struct JoinIntentContextDecision: Equatable {
    let recoveredContext: TurnIntentContextCandidate?
    let shouldRecordJoiner: Bool
}

enum JoinIntentContextResolver {
    static func resolve(
        joinIntent: JoinIntentV1,
        selectedState: CoreGameStateV1?,
        latestKnownStatesByGameId: [String: CoreGameStateV1],
        localLedgerState: CoreGameStateV1?,
        localParticipant: String?
    ) -> JoinIntentContextDecision {
        let resolution = TurnIntentContextResolver.resolve(
            gameId: joinIntent.gameId,
            anchorRev: joinIntent.anchorRev,
            anchorHash: joinIntent.anchorHash,
            selectedState: selectedState,
            latestKnownStatesByGameId: latestKnownStatesByGameId,
            localLedgerState: localLedgerState
        )

        guard let recovered = resolution.anchorMatched ?? resolution.bestAvailable else {
            return JoinIntentContextDecision(recoveredContext: nil, shouldRecordJoiner: false)
        }

        let shouldRecordJoiner = recovered.state.phase == .lobby

        return JoinIntentContextDecision(
            recoveredContext: recovered,
            shouldRecordJoiner: shouldRecordJoiner
        )
    }
}
