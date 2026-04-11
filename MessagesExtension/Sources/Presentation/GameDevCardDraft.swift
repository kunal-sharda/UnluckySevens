import ULS_CoreGame

enum GameDevCardDraft: Equatable {
    case knight(tileID: TileID?, victimPlayer: String?)
    case monopoly(resource: ResourceV1?)
    case yearOfPlenty(first: ResourceV1?, second: ResourceV1?)
    case roadBuilding(firstEdgeID: EdgeID?, secondEdgeID: EdgeID?)

    var actionKind: GameDevCardActionKind {
        switch self {
        case .knight:
            return .playKnight
        case .monopoly:
            return .playMonopoly
        case .yearOfPlenty:
            return .playYearOfPlenty
        case .roadBuilding:
            return .playRoadBuilding
        }
    }
}
