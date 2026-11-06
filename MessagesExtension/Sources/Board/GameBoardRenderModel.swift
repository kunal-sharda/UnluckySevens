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
    let slotIndex: Int
    let edgeID: EdgeID
    let kind: PortKindV1
}

struct GameBoardRenderModel: Equatable {
    let topology: BoardGraphV1
    let geometry: BoardRenderGeometryV1
    let playerOrder: [String]
    let tiles: [GameBoardTileRenderModel]
    let ports: [GameBoardPortRenderModel]
    let structures: [GameBoardStructureRenderModel]
    let roads: [GameBoardRoadRenderModel]
    var playerNames: [String: String] = [:]

    var publicOwnershipSummary: String {
        playerOrder.map { player in
            let mark = GamePlayerMark.resolve(owner: player, playerOrder: playerOrder)
            let settlements = structures.filter { $0.owner == player && $0.kind == .settlement }.count
            let cities = structures.filter { $0.owner == player && $0.kind == .city }.count
            let roadCount = roads.filter { $0.owner == player }.count
            return "\(playerNames[player] ?? mark.name), \(mark.name): \(roadCount) roads, \(settlements) settlements, \(cities) cities"
        }.joined(separator: ". ")
    }
}
