import ULS_CoreGame

enum LobbyPublicationReceiptKind: Equatable {
    case genesis
    case snapshotBootstrap
    case knownSnapshot
    case memberAuthored
    case hostReconciliation
}

enum LobbyPublicationReceiptError: Error, Equatable {
    case missingAnchor
    case unauthorizedTransition
}

enum LobbyPublicationReceiptValidator {
    static func validate(
        state: CoreGameStateV1,
        observedStates: [CoreGameStateV1]
    ) throws -> LobbyPublicationReceiptKind {
        try validateCanonicalSnapshot(state)
        guard state.phase == .lobby else {
            throw LobbyPublicationReceiptError.unauthorizedTransition
        }

        let observedStates = observedStates.filter { $0.gameId == state.gameId && $0.phase == .lobby }
        if observedStates.contains(state) { return .knownSnapshot }

        if state.rev == 0, state.prevHash == nil {
            guard state.roster.count == 1, state.currentPlayer == state.roster.first else {
                throw LobbyPublicationReceiptError.unauthorizedTransition
            }
            return .genesis
        }

        // A fresh device has no transcript ancestry: Messages replaces the session bubble.
        // Bootstrap only an empty local history. This is snapshot trust, not a claim that
        // a reconciliation was independently reproduced or its sender authenticated.
        if observedStates.isEmpty {
            guard state.rev > 0, state.prevHash != nil,
                  (1...4).contains(state.roster.count), state.currentPlayer == state.roster.first else {
                throw LobbyPublicationReceiptError.unauthorizedTransition
            }
            return .snapshotBootstrap
        }

        guard
            let parentHash = state.prevHash,
            let parent = observedStates.first(where: { $0.stateHash == parentHash })
        else {
            throw LobbyPublicationReceiptError.missingAnchor
        }
        if
            let transitionActor = inferredLobbyTransitionActor(from: parent, to: state),
            (try? validateTransition(from: parent, to: state, actor: transitionActor)) != nil
        {
            return .memberAuthored
        }

        guard
            let originalInviter = parent.roster.first,
            let resolution = try? reconcileLobbyV1(
                anchor: parent,
                observedStates: observedStates,
                actor: originalInviter
            ),
            resolution.state == state
        else {
            throw LobbyPublicationReceiptError.unauthorizedTransition
        }
        return .hostReconciliation
    }

    private static func inferredLobbyTransitionActor(
        from parent: CoreGameStateV1,
        to state: CoreGameStateV1
    ) -> String? {
        let addedPlayers = state.roster.filter { !parent.roster.contains($0) }
        if addedPlayers.count == 1 {
            return addedPlayers[0]
        }
        guard state.roster == parent.roster else {
            return nil
        }
        let changedNames = parent.roster.filter {
            parent.playerDisplayNamesByPlayer[$0] != state.playerDisplayNamesByPlayer[$0]
        }
        return changedNames.count == 1 ? changedNames[0] : nil
    }
}
