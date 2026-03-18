import ULS_CoreGame
import ULS_Transport

enum TurnInteractionResolver {
    static func draftBuildIntent(
        state: CoreGameStateV1?,
        actingAs: String?,
        mode: GameMode,
        target: GameBoardTarget
    ) -> ULS_Transport.TurnIntentV1? {
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
            return ULS_Transport.TurnIntentV1(
                buildRoadEdgeID: edgeID,
                gameId: state.gameId,
                anchorRev: state.rev,
                anchorHash: state.stateHash,
                actor: actingAs
            )
        case let (.buildSettlement, .node(nodeID)):
            guard state.legalBuildSettlementNodes(for: actingAs).contains(nodeID) else {
                return nil
            }
            return ULS_Transport.TurnIntentV1(
                buildSettlementNodeID: nodeID,
                gameId: state.gameId,
                anchorRev: state.rev,
                anchorHash: state.stateHash,
                actor: actingAs
            )
        case let (.buildCity, .node(nodeID)):
            guard state.legalBuildCityNodes(for: actingAs).contains(nodeID) else {
                return nil
            }
            return ULS_Transport.TurnIntentV1(
                buildCityNodeID: nodeID,
                gameId: state.gameId,
                anchorRev: state.rev,
                anchorHash: state.stateHash,
                actor: actingAs
            )
        default:
            return nil
        }
    }

    static func draftDiscardIntent(
        state: CoreGameStateV1?,
        actingAs: String?
    ) -> ULS_Transport.TurnIntentV1? {
        guard
            let state,
            state.phase == .turn,
            state.turnState?.step == .pendingDiscards,
            let actingAs,
            let required = state.turnState?.discardRequirementsByPlayer[actingAs],
            required > 0,
            let discarded = state.defaultDiscard(for: actingAs)
        else {
            return nil
        }

        return ULS_Transport.TurnIntentV1(
            submitDiscardFor: actingAs,
            discarded: TransportResourceHandV1(
                wood: discarded.wood,
                brick: discarded.brick,
                sheep: discarded.sheep,
                wheat: discarded.wheat,
                ore: discarded.ore
            ),
            gameId: state.gameId,
            anchorRev: state.rev,
            anchorHash: state.stateHash,
            actor: actingAs
        )
    }

    static func draftRobberMoveIntent(
        state: CoreGameStateV1?,
        actingAs: String?,
        target: GameBoardTarget
    ) -> ULS_Transport.TurnIntentV1? {
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

        return ULS_Transport.TurnIntentV1(
            moveRobberTileID: tileID,
            gameId: state.gameId,
            anchorRev: state.rev,
            anchorHash: state.stateHash,
            actor: actingAs
        )
    }

    static func draftStealVictimIntent(
        state: CoreGameStateV1?,
        actingAs: String?,
        target: GameBoardTarget
    ) -> ULS_Transport.TurnIntentV1? {
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
    ) -> ULS_Transport.TurnIntentV1? {
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

        return ULS_Transport.TurnIntentV1(
            selectStealVictimPlayer: victimPlayer,
            gameId: state.gameId,
            anchorRev: state.rev,
            anchorHash: state.stateHash,
            actor: actingAs
        )
    }
}
