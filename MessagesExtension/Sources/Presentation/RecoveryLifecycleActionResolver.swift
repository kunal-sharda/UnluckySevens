import ULS_CoreGame

/// Pure current-game lifecycle policy. The lobby facade retains conversation I/O,
/// ledger mutation, UI status, and player-facing error presentation.
enum GameLifecycleAction: Equatable {
    case resign
    case proposeDraw
    case voteOnDraw(approve: Bool)
    case hostEnd
}

struct GameLifecycleActionDraft: Equatable {
    let action: GameLifecycleAction
    let fromState: CoreGameStateV1
    let actor: String
    let resultingState: CoreGameStateV1

}

enum GameLifecycleActionResolver {
    /// A single pure availability decision used by bound-game affordances and
    /// publish preflight. Core remains the authority for lifecycle legality.
    static func isAvailable(
        action: GameLifecycleAction,
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
        action: GameLifecycleAction,
        state: CoreGameStateV1,
        actor: String
    ) throws -> GameLifecycleActionDraft {
        try validateCanonicalSnapshot(state)

        let resultingState: CoreGameStateV1
        switch action {
        case .resign, .proposeDraw, .voteOnDraw, .hostEnd:
            let intent = lifecycleIntent(for: action, anchoredTo: state)
            resultingState = try ULS_CoreGame.apply(
                intent: intent,
                to: state,
                actor: actor
            )
            try validateTransition(from: state, to: resultingState, actor: actor)
        }

        return GameLifecycleActionDraft(
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
        for action: GameLifecycleAction,
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
        }
    }
}
