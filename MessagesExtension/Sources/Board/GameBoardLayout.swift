import CoreGraphics
import ULS_CoreGame

struct GameBoardLayout {
    let size: CGSize
    let geometry: BoardRenderGeometryV1

    let tileRadius: CGFloat
    let roadWidth: CGFloat
    let structureRadius: CGFloat
    let portBadgeSize: CGSize
    let boardCenter: CGPoint
    let contentFrame: CGRect
    let boardHullFrame: CGRect

    private let nodePoints: [CGPoint]
    private let tileCenters: [CGPoint]

    private static let padding: CGFloat = 8
    private static let horizontalSeaMultiplier: CGFloat = 0.98
    private static let topSeaMultiplier: CGFloat = 0.78
    private static let bottomSeaMultiplier: CGFloat = 0.92

    init(size: CGSize, geometry: BoardRenderGeometryV1) {
        self.size = size
        self.geometry = geometry

        let geometryBounds = Self.bounds(for: geometry)
        let normalizedTileRadius = Self.normalizedTileRadius(for: geometry)
        let expandedBounds = Self.expandedBounds(
            geometryBounds: geometryBounds,
            normalizedTileRadius: normalizedTileRadius
        )
        let layoutScale = Self.layoutScale(size: size, expandedBounds: expandedBounds)
        let scaledWidth = expandedBounds.width * layoutScale
        let scaledHeight = expandedBounds.height * layoutScale
        let originX = ((size.width - scaledWidth) * 0.5) - (expandedBounds.minX * layoutScale)
        let originY = ((size.height - scaledHeight) * 0.5) - (expandedBounds.minY * layoutScale)

        func resolvedPoint(_ point: BoardRenderPointV1) -> CGPoint {
            CGPoint(
                x: originX + (point.x * layoutScale),
                y: originY + (point.y * layoutScale)
            )
        }

        let resolvedNodePoints = geometry.nodePositions.map(resolvedPoint)
        let resolvedTileCenters = geometry.tileCenters.map(resolvedPoint)
        let resolvedTileRadius = max(normalizedTileRadius * layoutScale, 8)
        let minX = resolvedNodePoints.map(\.x).min() ?? 0
        let maxX = resolvedNodePoints.map(\.x).max() ?? size.width
        let minY = resolvedNodePoints.map(\.y).min() ?? 0
        let maxY = resolvedNodePoints.map(\.y).max() ?? size.height
        let contentInset = resolvedTileRadius * 1.5

        nodePoints = resolvedNodePoints
        tileCenters = resolvedTileCenters
        tileRadius = resolvedTileRadius
        roadWidth = max(resolvedTileRadius * 0.125, 4.5)
        structureRadius = max(resolvedTileRadius * 0.275, 9.6)
        portBadgeSize = CGSize(
            width: max(resolvedTileRadius * 0.52, 19),
            height: max(resolvedTileRadius * 0.27, 12.5)
        )
        boardCenter = CGPoint(x: size.width * 0.5, y: size.height * 0.5)
        contentFrame = CGRect(
            x: minX - contentInset,
            y: minY - contentInset,
            width: max((maxX - minX) + (contentInset * 2), 1),
            height: max((maxY - minY) + (contentInset * 2), 1)
        )
        boardHullFrame = CGRect(
            x: minX,
            y: minY,
            width: max(maxX - minX, 1),
            height: max(maxY - minY, 1)
        )
    }

    func portMarkerSize(for kind: PortKindV1) -> CGSize {
        switch kind {
        case .threeToOne:
            CGSize(
                width: max(portBadgeSize.width * 1.18, 22),
                height: max(portBadgeSize.height * 1.62, 18)
            )
        case .twoToOne:
            CGSize(
                width: max(portBadgeSize.height * 1.34, 16),
                height: max(portBadgeSize.height * 1.34, 16)
            )
        }
    }

    func tileCenter(for tileID: TileID) -> CGPoint {
        tileCenters[tileID]
    }

    func nodePoint(for nodeID: NodeID) -> CGPoint {
        nodePoints[nodeID]
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
        let desiredOffset = max(edgeLength * 0.48, 14)
        let candidate = CGPoint(
            x: midpoint.x + (direction.dx * desiredOffset),
            y: midpoint.y + (direction.dy * desiredOffset)
        )

        return clamp(
            point: candidate,
            to: viewportFrame(for: portMarkerSize(for: port.kind))
        )
    }

    private static func bounds(for geometry: BoardRenderGeometryV1) -> CGRect {
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

    private static func layoutScale(size: CGSize, expandedBounds: CGRect) -> CGFloat {
        let availableWidth = max(size.width - (padding * 2), 1)
        let availableHeight = max(size.height - (padding * 2), 1)
        return min(
            availableWidth / max(expandedBounds.width, 1),
            availableHeight / max(expandedBounds.height, 1)
        )
    }

    private static func normalizedTileRadius(for geometry: BoardRenderGeometryV1) -> CGFloat {
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

    private static func expandedBounds(
        geometryBounds: CGRect,
        normalizedTileRadius: CGFloat
    ) -> CGRect {
        let horizontalInset = normalizedTileRadius * horizontalSeaMultiplier
        let topInset = normalizedTileRadius * topSeaMultiplier
        let bottomInset = normalizedTileRadius * bottomSeaMultiplier

        return CGRect(
            x: geometryBounds.minX - horizontalInset,
            y: geometryBounds.minY - topInset,
            width: geometryBounds.width + (horizontalInset * 2),
            height: geometryBounds.height + topInset + bottomInset
        )
    }
}
