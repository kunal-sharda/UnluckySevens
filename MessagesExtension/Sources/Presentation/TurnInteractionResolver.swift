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
}
