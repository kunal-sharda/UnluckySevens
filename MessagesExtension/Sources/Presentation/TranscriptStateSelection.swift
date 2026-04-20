import ULS_CoreGame

enum TranscriptActiveContextSource: Equatable {
    case selectedBubble
    case lastSentState
    case localLedgerState

    var label: String {
        switch self {
        case .selectedBubble:
            return "selectedBubble"
        case .lastSentState:
            return "lastSentState"
        case .localLedgerState:
            return "localLedgerState"
        }
    }
}

struct TranscriptStateSelectionResult: Equatable {
    let preferredState: CoreGameStateV1
    let shouldActivate: Bool
    let selectionStatus: String
    let shouldShowLatestUpdateNotice: Bool
    let redirectedToLatestKnown: Bool
}

enum TranscriptStateSelection {
    static func recording(
        _ state: CoreGameStateV1,
        in latestKnownStatesByGameId: [String: CoreGameStateV1]
    ) -> [String: CoreGameStateV1] {
        var updatedStates = latestKnownStatesByGameId

        guard let existing = updatedStates[state.gameId] else {
            updatedStates[state.gameId] = state
            return updatedStates
        }

        if state.rev > existing.rev || (state.rev == existing.rev && state.stateHash != existing.stateHash) {
            updatedStates[state.gameId] = state
        }

        return updatedStates
    }

    static func latestKnownState(
        for gameId: String,
        in latestKnownStatesByGameId: [String: CoreGameStateV1]
    ) -> CoreGameStateV1? {
        latestKnownStatesByGameId[gameId]
    }

    static func resolve(
        decodedState: CoreGameStateV1,
        latestKnownStatesByGameId: [String: CoreGameStateV1],
        activeState: CoreGameStateV1?,
        activeSource: TranscriptActiveContextSource?,
        source: TranscriptPayloadSource,
        trigger: TranscriptSelectionTrigger
    ) -> TranscriptStateSelectionResult {
        let preferredState = latestKnownState(
            for: decodedState.gameId,
            in: latestKnownStatesByGameId
        ) ?? decodedState
        let redirectedToLatestKnown = preferredState.rev > decodedState.rev
        let wasAlreadyOnPreferredState =
            activeState?.gameId == preferredState.gameId
            && activeState?.rev == preferredState.rev
            && activeState?.stateHash == preferredState.stateHash

        let shouldShowLatestUpdateNotice: Bool
        if redirectedToLatestKnown {
            shouldShowLatestUpdateNotice = trigger != .selectionPoll || !wasAlreadyOnPreferredState
        } else if let activeState,
                  activeState.gameId == preferredState.gameId,
                  preferredState.rev > activeState.rev {
            shouldShowLatestUpdateNotice = true
        } else {
            shouldShowLatestUpdateNotice = false
        }

        return TranscriptStateSelectionResult(
            preferredState: preferredState,
            shouldActivate: shouldActivate(
                preferredState: preferredState,
                decodedState: decodedState,
                activeState: activeState,
                activeSource: activeSource,
                source: source
            ),
            selectionStatus: redirectedToLatestKnown
                ? "Opened latest STATE rev\(preferredState.rev) via \(source.label)"
                : "Decoded STATE rev\(preferredState.rev) via \(source.label)",
            shouldShowLatestUpdateNotice: shouldShowLatestUpdateNotice,
            redirectedToLatestKnown: redirectedToLatestKnown
        )
    }

    private static func shouldActivate(
        preferredState: CoreGameStateV1,
        decodedState: CoreGameStateV1,
        activeState: CoreGameStateV1?,
        activeSource: TranscriptActiveContextSource?,
        source: TranscriptPayloadSource
    ) -> Bool {
        guard let activeState else {
            return true
        }

        guard activeState.gameId == preferredState.gameId else {
            return true
        }

        if preferredState.rev > activeState.rev {
            return true
        }

        if preferredState.rev == activeState.rev, preferredState.stateHash != activeState.stateHash {
            return true
        }

        if activeSource == .lastSentState || activeSource == .localLedgerState {
            return preferredState.rev >= activeState.rev
        }

        return preferredState.rev == activeState.rev
            && preferredState.stateHash == activeState.stateHash
            && source != .local
            && activeSource != .selectedBubble
            && decodedState.rev == preferredState.rev
            && decodedState.stateHash == preferredState.stateHash
    }
}
