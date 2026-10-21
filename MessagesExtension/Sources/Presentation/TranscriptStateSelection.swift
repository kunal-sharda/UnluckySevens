import ULS_CoreGame

enum TranscriptActiveContextSource: Equatable {
    case selectedBubble
    case receivedMessage
    case latestKnownState
    case lastSentState
    case localLedgerState

    var label: String {
        switch self {
        case .selectedBubble:
            return "selectedBubble"
        case .receivedMessage:
            return "receivedMessage"
        case .latestKnownState:
            return "latestKnownState"
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
        var contexts: [String: CanonicalStateConvergenceContextV1] = [:]
        return recording(
            state,
            in: latestKnownStatesByGameId,
            convergenceContextsByGameId: &contexts
        )
    }

    static func recording(
        _ state: CoreGameStateV1,
        in latestKnownStatesByGameId: [String: CoreGameStateV1],
        convergenceContextsByGameId: inout [String: CanonicalStateConvergenceContextV1]
    ) -> [String: CoreGameStateV1] {
        guard (try? validateCanonicalSnapshot(state)) != nil else {
            return latestKnownStatesByGameId
        }
        var updatedStates = latestKnownStatesByGameId

        guard let existing = updatedStates[state.gameId] else {
            var context = convergenceContextsByGameId[state.gameId] ?? .init()
            context.observe(state)
            convergenceContextsByGameId[state.gameId] = context
            updatedStates[state.gameId] = state
            return updatedStates
        }

        var context = convergenceContextsByGameId[state.gameId] ?? .init()
        context.observe(existing)
        context.observe(state)
        convergenceContextsByGameId[state.gameId] = context
        if CanonicalStatePreferenceV1.prefers(state, over: existing, context: context) {
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
        trigger: TranscriptSelectionTrigger,
        convergenceContext: CanonicalStateConvergenceContextV1 = .init()
    ) -> TranscriptStateSelectionResult {
        let preferredState = latestKnownState(
            for: decodedState.gameId,
            in: latestKnownStatesByGameId
        ) ?? decodedState
        let redirectedToLatestKnown =
            preferredState.stateHash != decodedState.stateHash
            && CanonicalStatePreferenceV1.prefers(
                preferredState,
                over: decodedState,
                context: convergenceContext
            )
        let wasAlreadyOnPreferredState =
            activeState?.gameId == preferredState.gameId
            && activeState?.rev == preferredState.rev
            && activeState?.stateHash == preferredState.stateHash

        let shouldShowLatestUpdateNotice: Bool
        if redirectedToLatestKnown {
            shouldShowLatestUpdateNotice = trigger != .selectionPoll || !wasAlreadyOnPreferredState
        } else if let activeState,
                  activeState.gameId == preferredState.gameId,
                  CanonicalStatePreferenceV1.prefers(
                      preferredState,
                      over: activeState,
                      context: convergenceContext
                  ) {
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
                source: source,
                convergenceContext: convergenceContext
            ),
            selectionStatus: redirectedToLatestKnown
                ? "Opened latest game rev\(preferredState.rev) via \(source.label)"
                : "Decoded game rev\(preferredState.rev) via \(source.label)",
            shouldShowLatestUpdateNotice: shouldShowLatestUpdateNotice,
            redirectedToLatestKnown: redirectedToLatestKnown
        )
    }

    private static func shouldActivate(
        preferredState: CoreGameStateV1,
        decodedState: CoreGameStateV1,
        activeState: CoreGameStateV1?,
        activeSource: TranscriptActiveContextSource?,
        source: TranscriptPayloadSource,
        convergenceContext: CanonicalStateConvergenceContextV1
    ) -> Bool {
        guard let activeState else {
            return true
        }

        guard activeState.gameId == preferredState.gameId else {
            return true
        }

        if CanonicalStatePreferenceV1.prefers(
            preferredState,
            over: activeState,
            context: convergenceContext
        ) {
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
