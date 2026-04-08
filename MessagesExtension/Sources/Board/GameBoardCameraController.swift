import CoreGraphics
import ULS_CoreGame

struct GameBoardCameraState: Equatable {
    var zoom: CGFloat = 1.0
    var offset: CGSize = .zero
}

enum GameBoardCameraController {
    static let minZoom: CGFloat = 1.0
    static let maxZoom: CGFloat = 2.4
    fileprivate static let edgeEndpointExclusionFraction: CGFloat = 0.2

    static func clampedZoom(_ proposed: CGFloat) -> CGFloat {
        min(max(proposed, minZoom), maxZoom)
    }

    static func clampedOffset(
        _ proposed: CGSize,
        zoom: CGFloat,
        viewportSize: CGSize,
        contentFrame: CGRect
    ) -> CGSize {
        let maxX = max(((contentFrame.width * zoom) - viewportSize.width) * 0.5, 0)
        let maxY = max(((contentFrame.height * zoom) - viewportSize.height) * 0.5, 0)

        return CGSize(
            width: min(max(proposed.width, -maxX), maxX),
            height: min(max(proposed.height, -maxY), maxY)
        )
    }

    static func applyingDrag(
        base: GameBoardCameraState,
        translation: CGSize,
        viewportSize: CGSize,
        contentFrame: CGRect
    ) -> GameBoardCameraState {
        GameBoardCameraState(
            zoom: base.zoom,
            offset: clampedOffset(
                CGSize(
                    width: base.offset.width + translation.width,
                    height: base.offset.height + translation.height
                ),
                zoom: base.zoom,
                viewportSize: viewportSize,
                contentFrame: contentFrame
            )
        )
    }

    static func applyingMagnification(
        base: GameBoardCameraState,
        magnification: CGFloat,
        viewportSize: CGSize,
        contentFrame: CGRect
    ) -> GameBoardCameraState {
        let zoom = clampedZoom(base.zoom * magnification)
        return GameBoardCameraState(
            zoom: zoom,
            offset: clampedOffset(base.offset, zoom: zoom, viewportSize: viewportSize, contentFrame: contentFrame)
        )
    }

    static func hitTarget(
        at location: CGPoint,
        state: GameBoardCameraState,
        renderModel: GameBoardRenderModel,
        overlayModel: GameBoardOverlayModel,
        interactionMode: GameMode,
        viewportSize: CGSize
    ) -> GameBoardTarget? {
        let layout = GameBoardLayout(size: viewportSize, geometry: renderModel.geometry)
        let boardPoint = inverseTransformedPoint(location, state: state, viewportSize: viewportSize)
        let selectionContext = SelectionContext(
            interactionMode: interactionMode,
            overlayModel: overlayModel
        )
        let candidates = [
            nearestNode(
                to: boardPoint,
                layout: layout,
                count: renderModel.geometry.nodePositions.count,
                selectionContext: selectionContext
            ),
            nearestEdge(
                to: boardPoint,
                layout: layout,
                topology: renderModel.topology,
                selectionContext: selectionContext
            ),
            nearestTile(to: boardPoint, layout: layout, count: renderModel.tiles.count),
        ]
        .compactMap { $0 }

        return candidates.min { lhs, rhs in
            if lhs.score == rhs.score {
                return lhs.priority < rhs.priority
            }

            return lhs.score < rhs.score
        }?.target
    }

    private static func inverseTransformedPoint(
        _ point: CGPoint,
        state: GameBoardCameraState,
        viewportSize: CGSize
    ) -> CGPoint {
        let center = CGPoint(x: viewportSize.width * 0.5, y: viewportSize.height * 0.5)
        let offsetPoint = CGPoint(x: point.x - state.offset.width, y: point.y - state.offset.height)
        return CGPoint(
            x: center.x + ((offsetPoint.x - center.x) / state.zoom),
            y: center.y + ((offsetPoint.y - center.y) / state.zoom)
        )
    }

    private static func nearestNode(
        to point: CGPoint,
        layout: GameBoardLayout,
        count: Int,
        selectionContext: SelectionContext
    ) -> HitCandidate? {
        guard !selectionContext.prefersSetupRoadEdges else {
            return nil
        }

        let threshold = max(layout.structureRadius * 1.2, 14)
        var best: (id: Int, distance: CGFloat)?

        for nodeID in 0..<count {
            let distance = distanceBetween(point, layout.nodePoint(for: nodeID))
            guard distance <= threshold else { continue }
            if distance < (best?.distance ?? .greatestFiniteMagnitude) {
                best = (nodeID, distance)
            }
        }

        guard let best else {
            return nil
        }

        return HitCandidate(
            target: .node(best.id),
            score: best.distance / threshold,
            priority: 0
        )
    }

    private static func nearestEdge(
        to point: CGPoint,
        layout: GameBoardLayout,
        topology: BoardGraphV1,
        selectionContext: SelectionContext
    ) -> HitCandidate? {
        let threshold = selectionContext.edgeThreshold(layout: layout)
        var best: (id: Int, distance: CGFloat)?

        for edgeID in topology.edges.indices {
            let edgeLine = layout.edgeLine(for: edgeID, topology: topology)
            let projection = projectedPoint(point, onSegmentFrom: edgeLine.start, to: edgeLine.end)
            let edgeEndpointExclusionFraction = selectionContext.edgeEndpointExclusionFraction(
                for: edgeID,
                topology: topology
            )
            guard projection.t >= edgeEndpointExclusionFraction,
                  projection.t <= (1 - edgeEndpointExclusionFraction) else {
                continue
            }

            let distance = distanceBetween(point, projection.point)
            guard distance <= threshold else { continue }
            if distance < (best?.distance ?? .greatestFiniteMagnitude) {
                best = (edgeID, distance)
            }
        }

        guard let best else {
            return nil
        }

        return HitCandidate(
            target: .edge(best.id),
            score: best.distance / threshold,
            priority: selectionContext.prefersSetupRoadEdges ? 0 : 1
        )
    }

    private static func nearestTile(
        to point: CGPoint,
        layout: GameBoardLayout,
        count: Int
    ) -> HitCandidate? {
        let threshold = max(layout.tileRadius * 0.9, 18)
        var best: (id: Int, distance: CGFloat)?

        for tileID in 0..<count {
            let distance = distanceBetween(point, layout.tileCenter(for: tileID))
            guard distance <= threshold else { continue }
            if distance < (best?.distance ?? .greatestFiniteMagnitude) {
                best = (tileID, distance)
            }
        }

        guard let best else {
            return nil
        }

        return HitCandidate(
            target: .tile(best.id),
            score: best.distance / threshold,
            priority: 2
        )
    }

    private static func distanceBetween(_ lhs: CGPoint, _ rhs: CGPoint) -> CGFloat {
        let dx = lhs.x - rhs.x
        let dy = lhs.y - rhs.y
        return sqrt((dx * dx) + (dy * dy))
    }

    private static func projectedPoint(
        _ point: CGPoint,
        onSegmentFrom start: CGPoint,
        to end: CGPoint
    ) -> (point: CGPoint, t: CGFloat) {
        let dx = end.x - start.x
        let dy = end.y - start.y

        if dx == 0, dy == 0 {
            return (start, 0)
        }

        let t = max(0, min(1, ((point.x - start.x) * dx + (point.y - start.y) * dy) / ((dx * dx) + (dy * dy))))
        let projection = CGPoint(x: start.x + (t * dx), y: start.y + (t * dy))
        return (projection, t)
    }
}

private struct SelectionContext {
    let interactionMode: GameMode
    let overlayModel: GameBoardOverlayModel

    var prefersSetupRoadEdges: Bool {
        interactionMode == .setup
            && overlayModel.anchorNodeID != nil
            && !overlayModel.legalEdgeIDs.isEmpty
            && overlayModel.legalNodeIDs.isEmpty
    }

    func edgeThreshold(layout: GameBoardLayout) -> CGFloat {
        if prefersSetupRoadEdges {
            return max(layout.roadWidth * 1.7, 16)
        }
        return max(layout.roadWidth * 1.35, 12)
    }

    func edgeEndpointExclusionFraction(
        for edgeID: EdgeID,
        topology: BoardGraphV1
    ) -> CGFloat {
        guard prefersSetupRoadEdges else {
            return GameBoardCameraController.edgeEndpointExclusionFraction
        }

        guard
            overlayModel.legalEdgeIDs.contains(edgeID),
            let anchorNodeID = overlayModel.anchorNodeID
        else {
            return GameBoardCameraController.edgeEndpointExclusionFraction
        }

        return topology.edges(incidentTo: anchorNodeID).contains(edgeID) ? 0.02 : 0.12
    }
}

private struct HitCandidate {
    let target: GameBoardTarget
    let score: CGFloat
    let priority: Int
}
