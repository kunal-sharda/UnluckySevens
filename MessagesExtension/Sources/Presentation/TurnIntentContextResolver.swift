import ULS_CoreGame
import ULS_Transport

enum TurnIntentContextCandidateSource: Equatable {
    case selectedState
    case latestKnownState
    case cachedPublishedState

    fileprivate var priority: Int {
        switch self {
        case .latestKnownState:
            return 3
        case .selectedState:
            return 2
        case .cachedPublishedState:
            return 1
        }
    }
}

struct TurnIntentContextCandidate: Equatable {
    let state: CoreGameStateV1
    let source: TurnIntentContextCandidateSource
}

struct TurnIntentContextResolution: Equatable {
    let anchorMatched: TurnIntentContextCandidate?
    let bestAvailable: TurnIntentContextCandidate?
}

enum TurnIntentContextResolver {
    static func resolve(
        turnIntent: ULS_Transport.TurnIntentV1,
        selectedState: CoreGameStateV1?,
        latestKnownStatesByGameId: [String: CoreGameStateV1],
        cachedPublishedState: CoreGameStateV1?
    ) -> TurnIntentContextResolution {
        resolve(
            gameId: turnIntent.gameId,
            anchorRev: turnIntent.anchorRev,
            anchorHash: turnIntent.anchorHash,
            selectedState: selectedState,
            latestKnownStatesByGameId: latestKnownStatesByGameId,
            cachedPublishedState: cachedPublishedState
        )
    }

    static func resolve(
        gameId: String,
        anchorRev: Int,
        anchorHash: String,
        selectedState: CoreGameStateV1?,
        latestKnownStatesByGameId: [String: CoreGameStateV1],
        cachedPublishedState: CoreGameStateV1?
    ) -> TurnIntentContextResolution {
        let candidates = orderedCandidates(
            gameId: gameId,
            selectedState: selectedState,
            latestKnownStatesByGameId: latestKnownStatesByGameId,
            cachedPublishedState: cachedPublishedState
        )

        let anchorMatched = candidates.first { candidate in
            candidate.state.gameId == gameId
                && candidate.state.rev == anchorRev
                && candidate.state.stateHash == anchorHash
        }

        let bestAvailable = candidates
            .filter { $0.state.gameId == gameId }
            .max(by: isWorseCandidate(_:than:))

        return TurnIntentContextResolution(
            anchorMatched: anchorMatched,
            bestAvailable: bestAvailable
        )
    }

    static func shouldAutoApply(
        _ turnIntent: ULS_Transport.TurnIntentV1,
        resolution: TurnIntentContextResolution,
        localParticipant: String?
    ) -> Bool {
        guard
            isTradeResponse(turnIntent.kind),
            let localParticipant,
            let anchorMatched = resolution.anchorMatched
        else {
            return false
        }

        return anchorMatched.state.currentPlayer == localParticipant
            && anchorMatched.state.roster.contains(localParticipant)
    }

    static func shouldPreferRecoveredState(
        _ turnIntent: ULS_Transport.TurnIntentV1,
        resolution: TurnIntentContextResolution,
        localParticipant: String?
    ) -> Bool {
        guard
            isTradeResponse(turnIntent.kind),
            let recovered = resolution.bestAvailable,
            recovered.state.gameId == turnIntent.gameId
        else {
            return false
        }

        return !shouldAutoApply(
            turnIntent,
            resolution: resolution,
            localParticipant: localParticipant
        )
    }

    static func isTradeResponse(_ kind: ULS_Transport.TurnIntentV1.Kind) -> Bool {
        switch kind {
        case .acceptTrade, .declineTrade, .counterTrade:
            return true
        default:
            return false
        }
    }

    private static func orderedCandidates(
        gameId: String,
        selectedState: CoreGameStateV1?,
        latestKnownStatesByGameId: [String: CoreGameStateV1],
        cachedPublishedState: CoreGameStateV1?
    ) -> [TurnIntentContextCandidate] {
        var candidates: [TurnIntentContextCandidate] = []

        if let selectedState {
            candidates.append(
                TurnIntentContextCandidate(
                    state: selectedState,
                    source: .selectedState
                )
            )
        }

        if let latestKnown = latestKnownStatesByGameId[gameId] {
            candidates.append(
                TurnIntentContextCandidate(
                    state: latestKnown,
                    source: .latestKnownState
                )
            )
        }

        if let cachedPublishedState {
            candidates.append(
                TurnIntentContextCandidate(
                    state: cachedPublishedState,
                    source: .cachedPublishedState
                )
            )
        }

        var deduped: [TurnIntentContextCandidate] = []
        for candidate in candidates {
            let duplicateIndex = deduped.firstIndex { existing in
                existing.state.gameId == candidate.state.gameId
                    && existing.state.rev == candidate.state.rev
                    && existing.state.stateHash == candidate.state.stateHash
            }

            if let duplicateIndex {
                let existing = deduped[duplicateIndex]
                if candidate.source.priority > existing.source.priority {
                    deduped[duplicateIndex] = candidate
                }
            } else {
                deduped.append(candidate)
            }
        }

        return deduped.sorted { lhs, rhs in
            if lhs.state.rev != rhs.state.rev {
                return lhs.state.rev > rhs.state.rev
            }
            return lhs.source.priority > rhs.source.priority
        }
    }

    private static func isWorseCandidate(
        _ lhs: TurnIntentContextCandidate,
        than rhs: TurnIntentContextCandidate
    ) -> Bool {
        if lhs.state.rev != rhs.state.rev {
            return lhs.state.rev < rhs.state.rev
        }
        return lhs.source.priority < rhs.source.priority
    }
}
