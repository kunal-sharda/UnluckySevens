import CoreGraphics
import ULS_CoreGame

struct GameBoardCameraState: Equatable {
    var zoom: CGFloat = 1.0
    var offset: CGSize = .zero
}

enum GameBoardCameraController {
    static let minZoom: CGFloat = 0.9
    static let maxZoom: CGFloat = 2.8
    fileprivate static let edgeEndpointExclusionFraction: CGFloat = 0.2
    private static let minimumPanSlack: CGFloat = 24
    private static let maximumPanSlack: CGFloat = 48

    static func clampedZoom(_ proposed: CGFloat) -> CGFloat {
        min(max(proposed, minZoom), maxZoom)
    }

    static func clampedOffset(
        _ proposed: CGSize,
        zoom: CGFloat,
        viewportSize: CGSize,
        contentFrame: CGRect
    ) -> CGSize {
        let maxX = max(
            max(((contentFrame.width * zoom) - viewportSize.width) * 0.5, 0),
            panSlack(for: viewportSize.width)
        )
        let maxY = max(
            max(((contentFrame.height * zoom) - viewportSize.height) * 0.5, 0),
            panSlack(for: viewportSize.height)
        )

        return CGSize(
            width: min(max(proposed.width, -maxX), maxX),
            height: min(max(proposed.height, -maxY), maxY)
        )
    }

    private static func panSlack(for viewportDimension: CGFloat) -> CGFloat {
        min(max(viewportDimension * 0.10, minimumPanSlack), maximumPanSlack)
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
        viewportSize: CGSize,
        boardReferenceSize: CGSize
    ) -> GameBoardTarget? {
        let layout = GameBoardLayout(size: boardReferenceSize, geometry: renderModel.geometry)
        let boardPoint = inverseTransformedPoint(
            location,
            state: state,
            viewportSize: viewportSize,
            boardCenter: layout.boardCenter
        )
        let selectionContext = SelectionContext(
            interactionMode: interactionMode,
            overlayModel: overlayModel
        )
        let candidates = [
            nearestNode(
                to: boardPoint,
                layout: layout,
                candidateIDs: selectionContext.nodeCandidateIDs(
                    totalCount: renderModel.geometry.nodePositions.count
                ),
                selectionContext: selectionContext
            ),
            nearestEdge(
                to: boardPoint,
                layout: layout,
                topology: renderModel.topology,
                candidateIDs: selectionContext.edgeCandidateIDs(
                    totalCount: renderModel.topology.edges.count
                ),
                selectionContext: selectionContext
            ),
            nearestTile(
                to: boardPoint,
                layout: layout,
                candidateIDs: selectionContext.tileCandidateIDs(
                    totalCount: renderModel.tiles.count
                ),
                selectionContext: selectionContext
            ),
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
        viewportSize: CGSize,
        boardCenter: CGPoint
    ) -> CGPoint {
        let viewportCenter = CGPoint(x: viewportSize.width * 0.5, y: viewportSize.height * 0.5)
        let offsetPoint = CGPoint(x: point.x - state.offset.width, y: point.y - state.offset.height)
        return CGPoint(
            x: boardCenter.x + ((offsetPoint.x - viewportCenter.x) / state.zoom),
            y: boardCenter.y + ((offsetPoint.y - viewportCenter.y) / state.zoom)
        )
    }

    private static func nearestNode(
        to point: CGPoint,
        layout: GameBoardLayout,
        candidateIDs: [NodeID],
        selectionContext: SelectionContext
    ) -> HitCandidate? {
        guard !candidateIDs.isEmpty else {
            return nil
        }

        let threshold = selectionContext.nodeThreshold(layout: layout)
        var best: (id: Int, distance: CGFloat)?

        for nodeID in candidateIDs {
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
        candidateIDs: [EdgeID],
        selectionContext: SelectionContext
    ) -> HitCandidate? {
        guard !candidateIDs.isEmpty else {
            return nil
        }

        let threshold = selectionContext.edgeThreshold(layout: layout)
        var best: (id: Int, distance: CGFloat)?

        for edgeID in candidateIDs {
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
        candidateIDs: [TileID],
        selectionContext: SelectionContext
    ) -> HitCandidate? {
        guard !candidateIDs.isEmpty else {
            return nil
        }

        let threshold = selectionContext.tileThreshold(layout: layout)
        var best: (id: Int, distance: CGFloat)?

        for tileID in candidateIDs {
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
        switch interactionMode {
        case .setup, .buildRoad:
            return max(layout.roadWidth * 1.7, 16)
        default:
            return max(layout.roadWidth * 1.35, 12)
        }
    }

    func nodeThreshold(layout: GameBoardLayout) -> CGFloat {
        switch interactionMode {
        case .setup, .buildSettlement, .buildCity, .robberVictim:
            return max(layout.structureRadius * 1.65, 18)
        default:
            return max(layout.structureRadius * 1.2, 14)
        }
    }

    func tileThreshold(layout: GameBoardLayout) -> CGFloat {
        switch interactionMode {
        case .robberMove:
            return max(layout.tileRadius * 1.08, 24)
        default:
            return max(layout.tileRadius * 0.9, 18)
        }
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

    func nodeCandidateIDs(totalCount: Int) -> [NodeID] {
        switch interactionMode {
        case .idle:
            return Array(0..<totalCount)
        case .setup:
            return prefersSetupRoadEdges ? [] : overlayModel.legalNodeIDs
        case .buildSettlement, .buildCity, .robberVictim, .devCardKnightVictim:
            return overlayModel.legalNodeIDs
        case .buildRoad,
             .robberMove,
             .trade,
             .playDevCard,
             .devCardKnightMove,
             .devCardMonopoly,
             .devCardYearOfPlenty,
             .devCardRoadBuildingFirst,
             .devCardRoadBuildingSecond,
             .discard:
            return []
        }
    }

    func edgeCandidateIDs(totalCount: Int) -> [EdgeID] {
        switch interactionMode {
        case .idle:
            return Array(0..<totalCount)
        case .setup, .buildRoad, .devCardRoadBuildingFirst, .devCardRoadBuildingSecond:
            return overlayModel.legalEdgeIDs
        case .buildSettlement,
             .buildCity,
             .robberMove,
             .robberVictim,
             .trade,
             .playDevCard,
             .devCardKnightMove,
             .devCardKnightVictim,
             .devCardMonopoly,
             .devCardYearOfPlenty,
             .discard:
            return []
        }
    }

    func tileCandidateIDs(totalCount: Int) -> [TileID] {
        switch interactionMode {
        case .idle:
            return Array(0..<totalCount)
        case .robberMove, .devCardKnightMove:
            return overlayModel.legalTileIDs
        case .setup,
             .buildRoad,
             .buildSettlement,
             .buildCity,
             .robberVictim,
             .trade,
             .playDevCard,
             .devCardKnightVictim,
             .devCardMonopoly,
             .devCardYearOfPlenty,
             .devCardRoadBuildingFirst,
             .devCardRoadBuildingSecond,
             .discard:
            return []
        }
    }
}

private struct HitCandidate {
    let target: GameBoardTarget
    let score: CGFloat
    let priority: Int
}
