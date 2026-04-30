import ULS_CoreGame

enum TurnInteractionResolver {
    static func draftBuildIntent(
        state: CoreGameStateV1?,
        actingAs: String?,
        mode: GameMode,
        target: GameBoardTarget
    ) -> TurnActionDraft? {
        guard
            let state,
            state.phase == .turn,
            state.turnState?.step == .afterRoll,
            let actingAs,
            actingAs == state.currentPlayer
        else {
            return nil
        }

        switch (mode, target) {
        case let (.buildRoad, .edge(edgeID)):
            guard state.legalBuildRoadEdges(for: actingAs).contains(edgeID) else {
                return nil
            }
            return TurnActionDraft(
                intent: .buildRoad(edgeID: edgeID),
                actor: actingAs,
                state: state
            )
        case let (.buildSettlement, .node(nodeID)):
            guard state.legalBuildSettlementNodes(for: actingAs).contains(nodeID) else {
                return nil
            }
            return TurnActionDraft(
                intent: .buildSettlement(nodeID: nodeID),
                actor: actingAs,
                state: state
            )
        case let (.buildCity, .node(nodeID)):
            guard state.legalBuildCityNodes(for: actingAs).contains(nodeID) else {
                return nil
            }
            return TurnActionDraft(
                intent: .buildCity(nodeID: nodeID),
                actor: actingAs,
                state: state
            )
        default:
            return nil
        }
    }

    static func draftDiscardIntent(
        state: CoreGameStateV1?,
        actingAs: String?,
        discarded: ResourceHandV1
    ) -> TurnActionDraft? {
        guard
            let state,
            state.phase == .turn,
            state.turnState?.step == .pendingDiscards,
            let actingAs,
            PendingDiscardOrderResolver.nextPendingPlayer(in: state) == actingAs,
            let required = state.turnState?.discardRequirementsByPlayer[actingAs],
            required > 0,
            discarded.totalCount == required
        else {
            return nil
        }

        let availableHand = state.resourcesByPlayer[actingAs] ?? .zero
        guard
            discarded.wood <= availableHand.wood,
            discarded.brick <= availableHand.brick,
            discarded.sheep <= availableHand.sheep,
            discarded.wheat <= availableHand.wheat,
            discarded.ore <= availableHand.ore
        else {
            return nil
        }

        return TurnActionDraft(
            intent: .submitDiscard(player: actingAs, discarded: discarded),
            actor: actingAs,
            state: state
        )
    }

    static func draftRobberMoveIntent(
        state: CoreGameStateV1?,
        actingAs: String?,
        target: GameBoardTarget
    ) -> TurnActionDraft? {
        guard
            let state,
            state.phase == .turn,
            state.turnState?.step == .needsRobberMove,
            let actingAs,
            actingAs == state.currentPlayer
        else {
            return nil
        }

        guard
            case let .tile(tileID) = target,
            state.legalRobberMoveTiles(for: actingAs).contains(tileID)
        else {
            return nil
        }

        return TurnActionDraft(
            intent: .moveRobber(tileID: tileID),
            actor: actingAs,
            state: state
        )
    }

    static func draftStealVictimIntent(
        state: CoreGameStateV1?,
        actingAs: String?,
        target: GameBoardTarget
    ) -> TurnActionDraft? {
        guard
            let state,
            state.phase == .turn,
            state.turnState?.step == .needsRobberSteal,
            let actingAs,
            actingAs == state.currentPlayer,
            case let .node(nodeID) = target
        else {
            return nil
        }

        guard state.robberVictimCandidateNodes(for: actingAs).contains(nodeID) else {
            return nil
        }

        let victim = state.citiesByNode[nodeID] ?? state.settlementsByNode[nodeID]
        guard let victim, state.turnState?.eligibleStealVictims.contains(victim) == true else {
            return nil
        }

        return draftStealVictimIntent(
            state: state,
            actingAs: actingAs,
            victimPlayer: victim
        )
    }

    static func draftStealVictimIntent(
        state: CoreGameStateV1?,
        actingAs: String?,
        victimPlayer: String
    ) -> TurnActionDraft? {
        guard
            let state,
            state.phase == .turn,
            state.turnState?.step == .needsRobberSteal,
            let actingAs,
            actingAs == state.currentPlayer,
            state.turnState?.eligibleStealVictims.contains(victimPlayer) == true
        else {
            return nil
        }

        return TurnActionDraft(
            intent: .selectStealVictim(victimPlayer: victimPlayer),
            actor: actingAs,
            state: state
        )
    }
}
