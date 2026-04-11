import CoreGraphics
import ULS_CoreGame

struct GameBoardLayout {
    let size: CGSize
    let geometry: BoardRenderGeometryV1

    private let padding: CGFloat = 28
    private let portMarginMultiplier: CGFloat = 2.0

    init(size: CGSize, geometry: BoardRenderGeometryV1) {
        self.size = size
        self.geometry = geometry
    }

    var tileRadius: CGFloat {
        max(normalizedTileRadius * layoutScale, 8)
    }

    var roadWidth: CGFloat {
        max(tileRadius * 0.18, 6)
    }

    var structureRadius: CGFloat {
        max(tileRadius * 0.22, 8)
    }

    var portBadgeSize: CGSize {
        CGSize(width: max(tileRadius * 0.56, 20), height: max(tileRadius * 0.28, 13))
    }

    var boardCenter: CGPoint {
        CGPoint(x: size.width * 0.5, y: size.height * 0.5)
    }

    var contentFrame: CGRect {
        let minX = geometry.nodePositions.indices.map { nodePoint(for: $0).x }.min() ?? 0
        let maxX = geometry.nodePositions.indices.map { nodePoint(for: $0).x }.max() ?? size.width
        let minY = geometry.nodePositions.indices.map { nodePoint(for: $0).y }.min() ?? 0
        let maxY = geometry.nodePositions.indices.map { nodePoint(for: $0).y }.max() ?? size.height

        let inset = tileRadius * 1.5
        return CGRect(
            x: minX - inset,
            y: minY - inset,
            width: max((maxX - minX) + (inset * 2), 1),
            height: max((maxY - minY) + (inset * 2), 1)
        )
    }

    var boardHullFrame: CGRect {
        let minX = geometry.nodePositions.indices.map { nodePoint(for: $0).x }.min() ?? 0
        let maxX = geometry.nodePositions.indices.map { nodePoint(for: $0).x }.max() ?? size.width
        let minY = geometry.nodePositions.indices.map { nodePoint(for: $0).y }.min() ?? 0
        let maxY = geometry.nodePositions.indices.map { nodePoint(for: $0).y }.max() ?? size.height

        return CGRect(
            x: minX,
            y: minY,
            width: max(maxX - minX, 1),
            height: max(maxY - minY, 1)
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

    func edgeLength(for edgeID: EdgeID, topology: BoardGraphV1) -> CGFloat {
        let edgeLine = edgeLine(for: edgeID, topology: topology)
        return hypot(
            edgeLine.end.x - edgeLine.start.x,
            edgeLine.end.y - edgeLine.start.y
        )
    }

    func portAnchor(for port: GameBoardPortRenderModel, topology: BoardGraphV1) -> CGPoint {
        let midpoint = edgeMidpoint(for: port.edgeID, topology: topology)
        let direction = outwardEdgeNormal(for: port.edgeID, topology: topology)
        let edgeLength = edgeLength(for: port.edgeID, topology: topology)
        let desiredOffset = max(edgeLength * 0.92, 16)
        let candidate = CGPoint(
            x: midpoint.x + (direction.dx * desiredOffset),
            y: midpoint.y + (direction.dy * desiredOffset)
        )

        return clamp(
            point: candidate,
            to: viewportFrame(for: portBadgeSize)
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
        let bounds = expandedBounds
        let scale = layoutScale
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

    private func outwardEdgeNormal(for edgeID: EdgeID, topology: BoardGraphV1) -> CGVector {
        let edgeLine = edgeLine(for: edgeID, topology: topology)
        let tangent = normalizedVector(from: edgeLine.start, to: edgeLine.end)
        let centerToMidpoint = normalizedVector(from: boardCenter, to: edgeMidpoint(for: edgeID, topology: topology))
        let leftNormal = CGVector(dx: -tangent.dy, dy: tangent.dx)
        let rightNormal = CGVector(dx: tangent.dy, dy: -tangent.dx)

        return dot(leftNormal, centerToMidpoint) >= dot(rightNormal, centerToMidpoint)
            ? leftNormal
            : rightNormal
    }

    private func viewportFrame(for badgeSize: CGSize) -> CGRect {
        let insetX = (badgeSize.width * 0.5) + 8
        let insetY = (badgeSize.height * 0.5) + 8
        return CGRect(origin: .zero, size: size).insetBy(dx: insetX, dy: insetY)
    }

    private func clamp(point: CGPoint, to frame: CGRect) -> CGPoint {
        CGPoint(
            x: min(max(point.x, frame.minX), frame.maxX),
            y: min(max(point.y, frame.minY), frame.maxY)
        )
    }

    private func dot(_ lhs: CGVector, _ rhs: CGVector) -> CGFloat {
        (lhs.dx * rhs.dx) + (lhs.dy * rhs.dy)
    }

    private var layoutScale: CGFloat {
        let availableWidth = max(size.width - (padding * 2), 1)
        let availableHeight = max(size.height - (padding * 2), 1)
        let expandedBounds = expandedBounds
        return min(
            availableWidth / max(expandedBounds.width, 1),
            availableHeight / max(expandedBounds.height, 1)
        )
    }

    private var normalizedTileRadius: CGFloat {
        let radii = geometry.tileCenters.compactMap { tileCenter in
            geometry.nodePositions
                .map { nodePoint in
                    hypot(
                        CGFloat(nodePoint.x - tileCenter.x),
                        CGFloat(nodePoint.y - tileCenter.y)
                    )
                }
                .filter { $0 > 0.0001 }
                .min()
        }

        guard !radii.isEmpty else {
            return 1
        }

        return radii.reduce(0, +) / CGFloat(radii.count)
    }

    private var expandedBounds: CGRect {
        bounds.insetBy(
            dx: -(normalizedTileRadius * portMarginMultiplier),
            dy: -(normalizedTileRadius * portMarginMultiplier * 0.92)
        )
    }
}
