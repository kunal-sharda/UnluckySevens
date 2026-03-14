import CoreGraphics
import ULS_CoreGame

struct GameBoardLayout {
    let size: CGSize
    let geometry: BoardRenderGeometryV1

    private let padding: CGFloat = 28

    init(size: CGSize, geometry: BoardRenderGeometryV1) {
        self.size = size
        self.geometry = geometry
    }

    var tileRadius: CGFloat {
        let width = max(bounds.width, 1)
        let height = max(bounds.height, 1)
        let availableWidth = max(size.width - (padding * 2), 1)
        let availableHeight = max(size.height - (padding * 2), 1)
        return min(availableWidth / width, availableHeight / height) * 0.44
    }

    func tileCenter(for tileID: TileID) -> CGPoint {
        point(for: geometry.tileCenters[tileID])
    }

    func nodePoint(for nodeID: NodeID) -> CGPoint {
        point(for: geometry.nodePositions[nodeID])
    }

    func edgeLine(for edgeID: EdgeID, topology: BoardGraphV1) -> (start: CGPoint, end: CGPoint) {
        let edge = topology.edges[edgeID]
        return (nodePoint(for: edge.a), nodePoint(for: edge.b))
    }

    private var bounds: CGRect {
        let xs = geometry.nodePositions.map(\.x)
        let ys = geometry.nodePositions.map(\.y)
        let minX = xs.min() ?? 0
        let maxX = xs.max() ?? 1
        let minY = ys.min() ?? 0
        let maxY = ys.max() ?? 1
        return CGRect(
            x: minX,
            y: minY,
            width: max(maxX - minX, 1),
            height: max(maxY - minY, 1)
        )
    }

    private func point(for renderPoint: BoardRenderPointV1) -> CGPoint {
        let bounds = bounds
        let availableWidth = max(size.width - (padding * 2), 1)
        let availableHeight = max(size.height - (padding * 2), 1)
        let scale = min(availableWidth / bounds.width, availableHeight / bounds.height)
        let scaledWidth = bounds.width * scale
        let scaledHeight = bounds.height * scale
        let originX = ((size.width - scaledWidth) * 0.5) - (bounds.minX * scale)
        let originY = ((size.height - scaledHeight) * 0.5) - (bounds.minY * scale)

        return CGPoint(
            x: originX + (renderPoint.x * scale),
            y: originY + (renderPoint.y * scale)
        )
    }
}
