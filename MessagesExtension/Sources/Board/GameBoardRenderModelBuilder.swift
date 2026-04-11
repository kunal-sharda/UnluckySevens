import ULS_CoreGame

enum GameBoardRenderModelBuilder {
    static func build(state: CoreGameStateV1?) -> GameBoardRenderModel? {
        guard let state, let board = state.board else {
            return nil
        }

        let topology = StandardBoardTopologyV1.standard()
        let geometry = StandardBoardTopologyV1.renderGeometry()

        let tiles = topology.tiles.indices.map { tileID in
            GameBoardTileRenderModel(
                tileID: tileID,
                resource: board.resourcesByTile[tileID],
                number: board.numbersByTile[tileID],
                hasRobber: board.robberTile == tileID
            )
        }

        let ports = topology.ports.enumerated().map { index, port in
            let kind = index < board.portsByIndex.count ? board.portsByIndex[index] : port.kind
            return GameBoardPortRenderModel(slotIndex: index, edgeID: port.edge, kind: kind)
        }

        let settlements = state.settlementsByNode
            .map { GameBoardStructureRenderModel(nodeID: $0.key, owner: $0.value, kind: .settlement) }
        let cities = state.citiesByNode
            .map { GameBoardStructureRenderModel(nodeID: $0.key, owner: $0.value, kind: .city) }
        let structures = (settlements + cities).sorted { lhs, rhs in
            if lhs.nodeID != rhs.nodeID {
                return lhs.nodeID < rhs.nodeID
            }
            return lhs.owner < rhs.owner
        }

        let roads = state.roadsByEdge
            .map { GameBoardRoadRenderModel(edgeID: $0.key, owner: $0.value) }
            .sorted { lhs, rhs in
                if lhs.edgeID != rhs.edgeID {
                    return lhs.edgeID < rhs.edgeID
                }
                return lhs.owner < rhs.owner
            }

        return GameBoardRenderModel(
            topology: topology,
            geometry: geometry,
            playerOrder: state.roster,
            tiles: tiles,
            ports: ports,
            structures: structures,
            roads: roads
        )
    }
}
