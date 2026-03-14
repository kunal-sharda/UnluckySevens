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

    var roadWidth: CGFloat {
        max(tileRadius * 0.18, 6)
    }

    var structureRadius: CGFloat {
        max(tileRadius * 0.22, 8)
    }

    var boardCenter: CGPoint {
        CGPoint(x: size.width * 0.5, y: size.height * 0.5)
    }

    var contentFrame: CGRect {
        let minX = geometry.nodePositions.indices.map { nodePoint(for: $0).x }.min() ?? 0
        let maxX = geometry.nodePositions.indices.map { nodePoint(for: $0).x }.max() ?? size.width
        let minY = geometry.nodePositions.indices.map { nodePoint(for: $0).y }.min() ?? 0
        let maxY = geometry.nodePositions.indices.map { nodePoint(for: $0).y }.max() ?? size.height

        let inset = tileRadius * 0.9
        return CGRect(
            x: minX - inset,
            y: minY - inset,
            width: max((maxX - minX) + (inset * 2), 1),
            height: max((maxY - minY) + (inset * 2), 1)
        )
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

    func edgeMidpoint(for edgeID: EdgeID, topology: BoardGraphV1) -> CGPoint {
        let edgeLine = edgeLine(for: edgeID, topology: topology)
        return CGPoint(
            x: (edgeLine.start.x + edgeLine.end.x) * 0.5,
            y: (edgeLine.start.y + edgeLine.end.y) * 0.5
        )
    }

    func portAnchor(for edgeID: EdgeID, topology: BoardGraphV1) -> CGPoint {
        let midpoint = edgeMidpoint(for: edgeID, topology: topology)
        let direction = normalizedVector(from: boardCenter, to: midpoint)
        let offset = max(tileRadius * 0.9, 24)
        return CGPoint(
            x: midpoint.x + (direction.dx * offset),
            y: midpoint.y + (direction.dy * offset)
        )
    }

    func edgeAngle(for edgeID: EdgeID, topology: BoardGraphV1) -> CGFloat {
        let edgeLine = edgeLine(for: edgeID, topology: topology)
        return atan2(edgeLine.end.y - edgeLine.start.y, edgeLine.end.x - edgeLine.start.x)
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

    private func normalizedVector(from start: CGPoint, to end: CGPoint) -> CGVector {
        let dx = end.x - start.x
        let dy = end.y - start.y
        let magnitude = max(sqrt((dx * dx) + (dy * dy)), 0.001)
        return CGVector(dx: dx / magnitude, dy: dy / magnitude)
    }
}
