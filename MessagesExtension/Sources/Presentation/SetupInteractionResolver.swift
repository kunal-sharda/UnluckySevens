import ULS_CoreGame
import ULS_Transport

enum SetupInteractionResolver {
    static func guidanceText(
        state: CoreGameStateV1?,
        actingAs: String?
    ) -> String? {
        guard
            let state,
            state.phase == .setup,
            let actingAs,
            actingAs == state.currentPlayer,
            let setupState = state.setupState
        else {
            return nil
        }

        switch setupState.step {
        case .placeSettlement:
            return "Tap a highlighted node to place your settlement."
        case .placeRoad:
            return "Tap a highlighted edge connected to your new settlement."
        case .done:
            return nil
        }
    }

    static func draftIntent(
        state: CoreGameStateV1?,
        actingAs: String?,
        target: GameBoardTarget
    ) -> SetupPlacementIntentV1? {
        guard
            let state,
            state.phase == .setup,
            let actingAs,
            actingAs == state.currentPlayer,
            let setupState = state.setupState
        else {
            return nil
        }

        switch (setupState.step, target) {
        case let (.placeSettlement, .node(nodeID)):
            guard state.legalSetupSettlementNodes(for: actingAs).contains(nodeID) else {
                return nil
            }
            return SetupPlacementIntentV1(
                gameId: state.gameId,
                anchorRev: state.rev,
                anchorHash: state.stateHash,
                actor: actingAs,
                node: nodeID
            )
        case let (.placeRoad, .edge(edgeID)):
            guard state.legalSetupRoadEdges(for: actingAs).contains(edgeID) else {
                return nil
            }
            return SetupPlacementIntentV1(
                gameId: state.gameId,
                anchorRev: state.rev,
                anchorHash: state.stateHash,
                actor: actingAs,
                edge: edgeID
            )
        default:
            return nil
        }
    }
}
