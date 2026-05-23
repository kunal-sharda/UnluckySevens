#if DEBUG
import ULS_CoreGame

enum UXTestingAutoplayResolver {
    enum Action: Equatable {
        case joinDummy(actorID: String, displayName: String?)
        case setup(intent: SetupIntentV1, actor: String)
        case turn(draft: TurnActionDraft)
    }

    static func nextAction(
        state: CoreGameStateV1,
        fixture: UXTestFixture,
        humanActorID: String
    ) -> Action? {
        let dummyActorIDs = fixture.actorIDs.filter { $0 != humanActorID }

        switch state.phase {
        case .lobby:
            return nextLobbyAction(
                state: state,
                dummyActorIDs: dummyActorIDs
            )
        case .setup:
            return nextSetupAction(
                state: state,
                dummyActorIDs: dummyActorIDs
            )
        case .turn:
            return nextTurnAction(
                state: state,
                dummyActorIDs: dummyActorIDs
            )
        case .gameOver:
            return nil
        }
    }

    private static func nextLobbyAction(
        state: CoreGameStateV1,
        dummyActorIDs: [String]
    ) -> Action? {
        guard let actorID = dummyActorIDs.first(where: { !state.roster.contains($0) }) else {
            return nil
        }

        return .joinDummy(
            actorID: actorID,
            displayName: UXTestFixtures.displayName(for: actorID)
        )
    }

    private static func nextSetupAction(
        state: CoreGameStateV1,
        dummyActorIDs: [String]
    ) -> Action? {
        let actor = state.currentPlayer
        guard dummyActorIDs.contains(actor), let setupState = state.setupState else {
            return nil
        }

        switch setupState.step {
        case .placeSettlement:
            guard let nodeID = state.legalSetupSettlementNodes(for: actor).first else {
                return nil
            }
            return .setup(intent: .placeSetupSettlement(node: nodeID), actor: actor)
        case .placeRoad:
            guard let edgeID = state.legalSetupRoadEdges(for: actor).first else {
                return nil
            }
            return .setup(intent: .placeSetupRoad(edge: edgeID), actor: actor)
        case .done:
            return nil
        }
    }

    private static func nextTurnAction(
        state: CoreGameStateV1,
        dummyActorIDs: [String]
    ) -> Action? {
        guard let turnState = state.turnState else {
            return nil
        }

        if turnState.step == .pendingDiscards {
            return nextDiscardAction(
                state: state,
                dummyActorIDs: dummyActorIDs
            )
        }

        let actor = state.currentPlayer
        guard dummyActorIDs.contains(actor) else {
            return nil
        }

        switch turnState.step {
        case .needsRoll:
            return .turn(
                draft: TurnActionDraft(
                    intent: .rollDice,
                    actor: actor,
                    state: state
                )
            )
        case .needsRobberMove:
            guard let tileID = state.legalRobberMoveTiles(for: actor).first else {
                return nil
            }
            return .turn(
                draft: TurnActionDraft(
                    intent: .moveRobber(tileID: tileID),
                    actor: actor,
                    state: state
                )
            )
        case .needsRobberSteal:
            guard let victim = turnState.eligibleStealVictims.first else {
                return nil
            }
            return .turn(
                draft: TurnActionDraft(
                    intent: .selectStealVictim(victimPlayer: victim),
                    actor: actor,
                    state: state
                )
            )
        case .afterRoll:
            return .turn(
                draft: TurnActionDraft(
                    intent: .endTurn,
                    actor: actor,
                    state: state
                )
            )
        case .pendingDiscards:
            return nil
        }
    }

    private static func nextDiscardAction(
        state: CoreGameStateV1,
        dummyActorIDs: [String]
    ) -> Action? {
        guard
            let actor = PendingDiscardOrderResolver.nextPendingPlayer(in: state),
            dummyActorIDs.contains(actor),
            let requiredCount = state.turnState?.discardRequirementsByPlayer[actor],
            let availableHand = state.resourcesByPlayer[actor],
            let discarded = discardHand(requiredCount: requiredCount, availableHand: availableHand)
        else {
            return nil
        }

        return .turn(
            draft: TurnActionDraft(
                intent: .submitDiscard(player: actor, discarded: discarded),
                actor: actor,
                state: state
            )
        )
    }

    private static func discardHand(
        requiredCount: Int,
        availableHand: ResourceHandV1
    ) -> ResourceHandV1? {
        guard requiredCount > 0, availableHand.totalCount >= requiredCount else {
            return nil
        }

        var remaining = requiredCount
        var discarded = ResourceHandV1.zero
        for resource in tradeableResources where remaining > 0 {
            let count = min(remaining, availableHand.count(for: resource))
            discarded = discarded.adding(count, for: resource)
            remaining -= count
        }

        return remaining == 0 ? discarded : nil
    }

    private static let tradeableResources: [ResourceV1] = [
        .wood,
        .brick,
        .sheep,
        .wheat,
        .ore,
    ]
}
#endif
