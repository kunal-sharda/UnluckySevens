import Foundation

public struct BoardRenderPointV1: Codable, Equatable, Hashable {
    public let x: Double
    public let y: Double

    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }
}

public struct BoardRenderGeometryV1: Codable, Equatable {
    public let tileCenters: [BoardRenderPointV1]
    public let nodePositions: [BoardRenderPointV1]

    public init(
        tileCenters: [BoardRenderPointV1],
        nodePositions: [BoardRenderPointV1]
    ) {
        self.tileCenters = tileCenters
        self.nodePositions = nodePositions
    }
}
