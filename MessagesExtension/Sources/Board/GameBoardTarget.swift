import Foundation
import ULS_CoreGame

enum GameBoardTarget: Equatable {
    case tile(TileID)
    case node(NodeID)
    case edge(EdgeID)

    var debugLabel: String {
        switch self {
        case let .tile(id):
            return "Tile \(id)"
        case let .node(id):
            return "Node \(id)"
        case let .edge(id):
            return "Edge \(id)"
        }
    }
}
