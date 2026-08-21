import ULS_CoreGame

/// Pure recovery-action policy. The lobby facade retains conversation I/O,
/// ledger mutation, UI status, and player-facing error presentation.
enum RecoveryLifecycleAction: Equatable {
    case resend
    case resign
    case proposeDraw
    case voteOnDraw(approve: Bool)
    case hostEnd
}

struct RecoveryLifecycleActionDraft: Equatable {
    let action: RecoveryLifecycleAction
    let fromState: CoreGameStateV1
    let actor: String
    let resultingState: CoreGameStateV1

    var permitsRecoverySessionStart: Bool {
        action == .resend
    }
}

enum RecoveryLifecycleActionResolver {
    /// A single pure availability decision used by recovery affordances and
    /// publish preflight. Core remains the authority for lifecycle legality.
    static func isAvailable(
        action: RecoveryLifecycleAction,
        state: CoreGameStateV1?,
        actor: String?,
        hasCompatibleActiveConversation: Bool
    ) -> Bool {
        guard
            let state,
            let actor,
            hasCompatibleActiveConversation
        else {
            return false
        }

        return (try? prepare(action: action, state: state, actor: actor)) != nil
    }

    /// Validates the canonical recovered state, anchors a lifecycle intent,
    /// applies it through Core, and independently validates its transition.
    /// Resend deliberately returns the identical canonical state.
    static func prepare(
        action: RecoveryLifecycleAction,
        state: CoreGameStateV1,
        actor: String
    ) throws -> RecoveryLifecycleActionDraft {
        try validateCanonicalSnapshot(state)

        let resultingState: CoreGameStateV1
        switch action {
        case .resend:
            resultingState = try RecoveryStatePublicationResolver.resolve(
                state: state,
                actor: actor
            )
        case .resign, .proposeDraw, .voteOnDraw, .hostEnd:
            let intent = lifecycleIntent(for: action, anchoredTo: state)
            resultingState = try ULS_CoreGame.apply(
                intent: intent,
                to: state,
                actor: actor
            )
            try validateTransition(from: state, to: resultingState, actor: actor)
        }

        return RecoveryLifecycleActionDraft(
            action: action,
            fromState: state,
            actor: actor,
            resultingState: resultingState
        )
    }

    static func shouldOfferDrawBeforeHostEnd(state: CoreGameStateV1?) -> Bool {
        guard let state else {
            return false
        }
        return !state.hasAttemptedDrawVote && state.drawVote == nil
    }

    private static func lifecycleIntent(
        for action: RecoveryLifecycleAction,
        anchoredTo state: CoreGameStateV1
    ) -> GameLifecycleIntentV1 {
        switch action {
        case .resign:
            return .resign(anchoredTo: state)
        case .proposeDraw:
            return .proposeDraw(anchoredTo: state)
        case let .voteOnDraw(approve):
            return .voteDraw(approve: approve, anchoredTo: state)
        case .hostEnd:
            return .endGame(anchoredTo: state)
        case .resend:
            preconditionFailure("Resend does not have a lifecycle intent.")
        }
    }
}
