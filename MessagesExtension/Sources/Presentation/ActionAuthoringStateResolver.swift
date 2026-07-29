import ULS_CoreGame

enum ActionAuthoringStateSource: Equatable {
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

struct ActionAuthoringStateResolution: Equatable {
    let state: CoreGameStateV1?
    let source: ActionAuthoringStateSource?
    let prefersRecoveredState: Bool
}

enum ActionAuthoringStateResolver {
    static func resolve(
        gameId: String?,
        selectedState: CoreGameStateV1?,
        latestKnownStatesByGameId: [String: CoreGameStateV1],
        localLedgerState: CoreGameStateV1?
    ) -> ActionAuthoringStateResolution {
        let resolvedGameId = gameId ?? selectedState?.gameId ?? localLedgerState?.gameId
        guard let resolvedGameId else {
            return ActionAuthoringStateResolution(
                state: nil,
                source: nil,
                prefersRecoveredState: false
            )
        }

        var candidates: [(state: CoreGameStateV1, source: ActionAuthoringStateSource)] = []

        if let selectedState, selectedState.gameId == resolvedGameId {
            candidates.append((selectedState, .selectedState))
        }

        if let latestKnownState = latestKnownStatesByGameId[resolvedGameId] {
            candidates.append((latestKnownState, .latestKnownState))
        }

        if let localLedgerState, localLedgerState.gameId == resolvedGameId {
            candidates.append((localLedgerState, .localLedgerState))
        }

        guard !candidates.isEmpty else {
            return ActionAuthoringStateResolution(
                state: nil,
                source: nil,
                prefersRecoveredState: false
            )
        }

        let preferred = candidates.max { lhs, rhs in
            if lhs.state.rev != rhs.state.rev {
                return lhs.state.rev < rhs.state.rev
            }
            if lhs.state.stateHash != rhs.state.stateHash {
                return lhs.state.stateHash < rhs.state.stateHash
            }
            return lhs.source.priority < rhs.source.priority
        }

        let prefersRecoveredState: Bool
        if
            let selectedState,
            selectedState.gameId == resolvedGameId,
            let preferred
        {
            prefersRecoveredState =
                preferred.state.rev != selectedState.rev
                || preferred.state.stateHash != selectedState.stateHash
        } else {
            prefersRecoveredState = preferred?.source != .selectedState
        }

        return ActionAuthoringStateResolution(
            state: preferred?.state,
            source: preferred?.source,
            prefersRecoveredState: prefersRecoveredState
        )
    }
}
