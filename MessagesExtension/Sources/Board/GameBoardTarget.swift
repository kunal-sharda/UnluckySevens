import Foundation
import ULS_CoreGame

enum GameBoardTarget: Equatable {
    case tile(TileID)
    case node(NodeID)
    case edge(EdgeID)

    func selectionLabel(for mode: GameMode) -> String {
        switch (mode, self) {
        case (.setup, .node), (.buildSettlement, .node):
            return "Settlement selected"
        case (.buildCity, .node):
            return "City target selected"
        case (.robberVictim, .node), (.devCardKnightVictim, .node):
            return "Victim selected"
        case (.setup, .edge), (.buildRoad, .edge), (.devCardRoadBuildingFirst, .edge), (.devCardRoadBuildingSecond, .edge):
            return "Road selected"
        case (.robberMove, .tile), (.devCardKnightMove, .tile):
            return "Robber tile selected"
        case (.idle, _):
            return defaultLabel
        default:
            return defaultLabel
        }
    }

    var defaultLabel: String {
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
