import ULS_CoreGame

enum GameBoardOverlayModelBuilder {
    static func build(
        state: CoreGameStateV1?,
        actingAs: String?,
        mode: GameMode,
        devCardDraft: GameDevCardDraft? = nil,
        selectedTarget: GameBoardTarget?
    ) -> GameBoardOverlayModel {
        guard let state else {
            return .empty
        }

        let legalTiles = legalTileIDs(state: state, actingAs: actingAs, mode: mode)
        let legalNodes = legalNodeIDs(state: state, actingAs: actingAs, mode: mode, devCardDraft: devCardDraft)
        let legalEdges = legalEdgeIDs(state: state, actingAs: actingAs, mode: mode, devCardDraft: devCardDraft)
        let anchorNodeID = setupAnchorNodeID(state: state, mode: mode)

        let overlay = GameBoardOverlayModel(
            legalTileIDs: legalTiles,
            legalNodeIDs: legalNodes,
            legalEdgeIDs: legalEdges,
            anchorNodeID: anchorNodeID,
            selectedTarget: nil
        )

        let normalizedSelection: GameBoardTarget?
        if let selectedTarget, overlay.allowsSelection(of: selectedTarget, in: mode) {
            normalizedSelection = selectedTarget
        } else {
            normalizedSelection = nil
        }

        return GameBoardOverlayModel(
            legalTileIDs: legalTiles,
            legalNodeIDs: legalNodes,
            legalEdgeIDs: legalEdges,
            anchorNodeID: anchorNodeID,
            selectedTarget: normalizedSelection
        )
    }

    private static func setupAnchorNodeID(
        state: CoreGameStateV1,
        mode: GameMode
    ) -> NodeID? {
        guard
            mode == .setup,
            state.setupState?.step == .placeRoad
        else {
            return nil
        }

        return state.setupState?.lastPlacedSettlementNode
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
        case .devCardKnightMove:
            return state.legalKnightMoveTilesForDevCard(for: actor)
        default:
            return []
        }
    }

    private static func legalNodeIDs(
        state: CoreGameStateV1,
        actingAs: String?,
        mode: GameMode,
        devCardDraft: GameDevCardDraft?
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
        case .devCardKnightVictim:
            guard case let .knight(tileID?, _) = devCardDraft else {
                return []
            }
            return state.knightVictimCandidateNodes(for: tileID, actor: actor)
        case .idle, .buildRoad, .robberMove, .trade, .playDevCard, .devCardKnightMove, .devCardMonopoly, .devCardYearOfPlenty, .devCardRoadBuildingFirst, .devCardRoadBuildingSecond, .discard:
            return []
        }
    }

    private static func legalEdgeIDs(
        state: CoreGameStateV1,
        actingAs: String?,
        mode: GameMode,
        devCardDraft: GameDevCardDraft?
    ) -> [EdgeID] {
        guard let actor = actingAs else {
            return []
        }

        switch mode {
        case .setup:
            return state.legalSetupRoadEdges(for: actor)
        case .buildRoad:
            return state.legalBuildRoadEdges(for: actor)
        case .devCardRoadBuildingFirst:
            return state.legalRoadBuildingFirstEdges(for: actor)
        case .devCardRoadBuildingSecond:
            guard case let .roadBuilding(firstEdgeID?, _) = devCardDraft else {
                return []
            }
            return state.legalRoadBuildingSecondEdges(for: actor, firstEdgeID: firstEdgeID)
        case .idle, .buildSettlement, .buildCity, .robberMove, .robberVictim, .trade, .playDevCard, .devCardKnightMove, .devCardKnightVictim, .devCardMonopoly, .devCardYearOfPlenty, .discard:
            return []
        }
    }
}
