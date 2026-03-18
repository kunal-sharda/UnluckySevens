import ULS_CoreGame

enum GameBoardOverlayModelBuilder {
    static func build(
        state: CoreGameStateV1?,
        actingAs: String?,
        mode: GameMode,
        selectedTarget: GameBoardTarget?
    ) -> GameBoardOverlayModel {
        guard let state else {
            return .empty
        }

        let legalTiles = legalTileIDs(state: state, actingAs: actingAs, mode: mode)
        let legalNodes = legalNodeIDs(state: state, actingAs: actingAs, mode: mode)
        let legalEdges = legalEdgeIDs(state: state, actingAs: actingAs, mode: mode)

        let overlay = GameBoardOverlayModel(
            legalTileIDs: legalTiles,
            legalNodeIDs: legalNodes,
            legalEdgeIDs: legalEdges,
            selectedTarget: nil
        )

        let normalizedSelection: GameBoardTarget?
        if let selectedTarget, overlay.allowsSelection(of: selectedTarget, in: mode) {
            normalizedSelection = selectedTarget
        } else if mode == .idle {
            normalizedSelection = selectedTarget
        } else {
            normalizedSelection = nil
        }

        return GameBoardOverlayModel(
            legalTileIDs: legalTiles,
            legalNodeIDs: legalNodes,
            legalEdgeIDs: legalEdges,
            selectedTarget: normalizedSelection
        )
    }

    private static func legalTileIDs(
        state: CoreGameStateV1,
        actingAs: String?,
        mode: GameMode
    ) -> [TileID] {
        guard let actor = actingAs else {
            return []
        }

        switch mode {
        case .robberMove:
            return state.legalRobberMoveTiles(for: actor)
        default:
            return []
        }
    }

    private static func legalNodeIDs(
        state: CoreGameStateV1,
        actingAs: String?,
        mode: GameMode
    ) -> [NodeID] {
        guard let actor = actingAs else {
            return []
        }

        switch mode {
        case .setup:
            return state.legalSetupSettlementNodes(for: actor)
        case .buildSettlement:
            return state.legalBuildSettlementNodes(for: actor)
        case .buildCity:
            return state.legalBuildCityNodes(for: actor)
        case .robberVictim:
            return state.robberVictimCandidateNodes(for: actor)
        case .idle, .buildRoad, .robberMove, .trade, .playDevCard, .discard:
            return []
        }
    }

    private static func legalEdgeIDs(
        state: CoreGameStateV1,
        actingAs: String?,
        mode: GameMode
    ) -> [EdgeID] {
        guard let actor = actingAs else {
            return []
        }

        switch mode {
        case .setup:
            return state.legalSetupRoadEdges(for: actor)
        case .buildRoad:
            return state.legalBuildRoadEdges(for: actor)
        case .idle, .buildSettlement, .buildCity, .robberMove, .robberVictim, .trade, .playDevCard, .discard:
            return []
        }
    }
}
