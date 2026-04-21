import ULS_CoreGame
import ULS_Transport

enum TurnIntentContextCandidateSource: Equatable {
    case selectedState
    case latestKnownState
    case localLedgerState

    fileprivate var priority: Int {
        switch self {
        case .latestKnownState:
            return 3
        case .selectedState:
            return 2
        case .localLedgerState:
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
        localLedgerState: CoreGameStateV1?
    ) -> TurnIntentContextResolution {
        resolve(
            gameId: turnIntent.gameId,
            anchorRev: turnIntent.anchorRev,
            anchorHash: turnIntent.anchorHash,
            selectedState: selectedState,
            latestKnownStatesByGameId: latestKnownStatesByGameId,
            localLedgerState: localLedgerState
        )
    }

    static func resolve(
        gameId: String,
        anchorRev: Int,
        anchorHash: String,
        selectedState: CoreGameStateV1?,
        latestKnownStatesByGameId: [String: CoreGameStateV1],
        localLedgerState: CoreGameStateV1?
    ) -> TurnIntentContextResolution {
        let candidates = orderedCandidates(
            gameId: gameId,
            selectedState: selectedState,
            latestKnownStatesByGameId: latestKnownStatesByGameId,
            localLedgerState: localLedgerState
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
        autoApplyContext(
            turnIntent,
            resolution: resolution,
            localParticipant: localParticipant
        ) != nil
    }

    static func autoApplyContext(
        _ turnIntent: ULS_Transport.TurnIntentV1,
        resolution: TurnIntentContextResolution,
        localParticipant: String?
    ) -> TurnIntentContextCandidate? {
        guard let localParticipant else {
            return nil
        }

        if turnIntent.kind == .submitDiscard,
           let recovered = resolution.bestAvailable,
           isNewerRecoveredState(recovered.state, than: turnIntent) {
            return canReanchorDiscardResponderMessage(
                turnIntent,
                onto: recovered.state,
                localParticipant: localParticipant
            ) ? recovered : nil
        }

        if let anchorMatched = resolution.anchorMatched,
           isAuthorityContext(anchorMatched.state, localParticipant: localParticipant) {
            return anchorMatched
        }

        guard
            let recovered = resolution.bestAvailable,
            canReanchorDiscardResponderMessage(
                turnIntent,
                onto: recovered.state,
                localParticipant: localParticipant
            )
        else {
            return nil
        }

        return recovered
    }

    static func shouldPreferRecoveredState(
        _ turnIntent: ULS_Transport.TurnIntentV1,
        resolution: TurnIntentContextResolution,
        localParticipant: String?
    ) -> Bool {
        if case .responderMessage = TurnIntentTransportRoleResolver.resolve(turnIntent) {
            guard
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

        guard
            let recovered = resolution.bestAvailable,
            recovered.state.gameId == turnIntent.gameId
        else {
            return false
        }

        return recovered.state.rev > turnIntent.anchorRev && !shouldAutoApply(
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

    private static func isAuthorityContext(
        _ state: CoreGameStateV1,
        localParticipant: String
    ) -> Bool {
        state.currentPlayer == localParticipant && state.roster.contains(localParticipant)
    }

    private static func canReanchorDiscardResponderMessage(
        _ turnIntent: ULS_Transport.TurnIntentV1,
        onto state: CoreGameStateV1,
        localParticipant: String
    ) -> Bool {
        guard
            turnIntent.kind == .submitDiscard,
            state.gameId == turnIntent.gameId,
            state.phase == .turn,
            state.turnState?.step == .pendingDiscards,
            isAuthorityContext(state, localParticipant: localParticipant),
            let discardPlayer = turnIntent.discardPlayer,
            discardPlayer == turnIntent.actor,
            let turnState = state.turnState,
            turnState.discardRequirementsByPlayer[discardPlayer] != nil,
            turnState.submittedDiscardsByPlayer[discardPlayer] == nil
        else {
            return false
        }

        return state.rev > turnIntent.anchorRev || state.stateHash != turnIntent.anchorHash
    }

    private static func isNewerRecoveredState(
        _ state: CoreGameStateV1,
        than turnIntent: ULS_Transport.TurnIntentV1
    ) -> Bool {
        state.gameId == turnIntent.gameId
            && (state.rev > turnIntent.anchorRev || state.stateHash != turnIntent.anchorHash)
    }

    private static func orderedCandidates(
        gameId: String,
        selectedState: CoreGameStateV1?,
        latestKnownStatesByGameId: [String: CoreGameStateV1],
        localLedgerState: CoreGameStateV1?
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

        if let localLedgerState {
            candidates.append(
                TurnIntentContextCandidate(
                    state: localLedgerState,
                    source: .localLedgerState
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
