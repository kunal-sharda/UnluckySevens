import ULS_CoreGame

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

        guard setupState.turnIndex < state.roster.count else {
            return nil
        }

        switch setupState.step {
        case .placeSettlement:
            return "Choose a glowing corner."
        case .placeRoad:
            return "Choose a glowing road beside your settlement."
        case .done:
            return nil
        }
    }

    static func draftIntent(
        state: CoreGameStateV1?,
        actingAs: String?,
        target: GameBoardTarget
    ) -> SetupIntentV1? {
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
            return .placeSetupSettlement(node: nodeID)
        case let (.placeRoad, .edge(edgeID)):
            guard state.legalSetupRoadEdges(for: actingAs).contains(edgeID) else {
                return nil
            }
            return .placeSetupRoad(edge: edgeID)
        default:
            return nil
        }
    }
}
