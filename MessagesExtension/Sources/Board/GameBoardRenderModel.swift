import ULS_CoreGame

struct GameBoardTileRenderModel: Equatable {
    let tileID: TileID
    let resource: ResourceV1
    let number: Int?
    let hasRobber: Bool
}

struct GameBoardStructureRenderModel: Equatable {
    enum Kind: Equatable {
        case settlement
        case city
    }

    let nodeID: NodeID
    let owner: String
    let kind: Kind
}

struct GameBoardRoadRenderModel: Equatable {
    let edgeID: EdgeID
    let owner: String
}

struct GameBoardPortRenderModel: Equatable {
    let edgeID: EdgeID
    let kind: PortKindV1
}

struct GameBoardRenderModel: Equatable {
    let topology: BoardGraphV1
    let geometry: BoardRenderGeometryV1
    let tiles: [GameBoardTileRenderModel]
    let ports: [GameBoardPortRenderModel]
    let structures: [GameBoardStructureRenderModel]
    let roads: [GameBoardRoadRenderModel]
}
