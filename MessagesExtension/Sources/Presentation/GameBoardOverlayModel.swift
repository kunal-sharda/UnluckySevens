import ULS_CoreGame

struct GameBoardOverlayModel: Equatable {
    let legalTileIDs: [TileID]
    let legalNodeIDs: [NodeID]
    let legalEdgeIDs: [EdgeID]
    let selectedTarget: GameBoardTarget?

    static let empty = GameBoardOverlayModel(
        legalTileIDs: [],
        legalNodeIDs: [],
        legalEdgeIDs: [],
        selectedTarget: nil
    )

    func allowsSelection(of target: GameBoardTarget, in mode: GameMode) -> Bool {
        if mode == .idle {
            return true
        }

        switch target {
        case let .tile(tileID):
            return legalTileIDs.contains(tileID)
        case let .node(nodeID):
            return legalNodeIDs.contains(nodeID)
        case let .edge(edgeID):
            return legalEdgeIDs.contains(edgeID)
        }
    }
}
