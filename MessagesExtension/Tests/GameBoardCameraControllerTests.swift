@testable import MessagesExtensionSupport
import CoreGraphics
import ULS_CoreGame
import XCTest

final class GameBoardCameraControllerTests: XCTestCase {
    func testClampedZoomLimitsRange() {
        XCTAssertEqual(GameBoardCameraController.clampedZoom(0.2), 0.9)
        XCTAssertEqual(GameBoardCameraController.clampedZoom(1.4), 1.4)
        XCTAssertEqual(GameBoardCameraController.clampedZoom(8.0), 2.8)
    }

    func testClampedOffsetKeepsViewportInsideContentBounds() {
        let offset = GameBoardCameraController.clampedOffset(
            CGSize(width: 900, height: -900),
            zoom: 2.0,
            viewportSize: CGSize(width: 320, height: 240),
            contentFrame: CGRect(x: 20, y: 20, width: 220, height: 180)
        )

        XCTAssertEqual(offset.width, 60, accuracy: 0.001)
        XCTAssertEqual(offset.height, -60, accuracy: 0.001)
    }

    func testClampedOffsetAllowsLimitedPanSlackAtFittedZoom() {
        let offset = GameBoardCameraController.clampedOffset(
            CGSize(width: 900, height: -900),
            zoom: 1.0,
            viewportSize: CGSize(width: 320, height: 240),
            contentFrame: CGRect(x: 20, y: 20, width: 220, height: 180)
        )

        XCTAssertEqual(offset.width, 32, accuracy: 0.001)
        XCTAssertEqual(offset.height, -24, accuracy: 0.001)
    }

    func testHitTargetResolvesNodeTileAndEdgeAcrossCameraTransforms() {
        let model = makeRenderModel()
        let viewportSize = CGSize(width: 320, height: 240)
        let layout = GameBoardLayout(size: viewportSize, geometry: model.geometry)

        XCTAssertEqual(
            GameBoardCameraController.hitTarget(
                at: layout.nodePoint(for: 0),
                state: GameBoardCameraState(),
                renderModel: model,
                overlayModel: .empty,
                interactionMode: .idle,
                viewportSize: viewportSize,
                boardReferenceSize: viewportSize
            ),
            .node(0)
        )

        XCTAssertEqual(
            GameBoardCameraController.hitTarget(
                at: layout.tileCenter(for: 0),
                state: GameBoardCameraState(),
                renderModel: model,
                overlayModel: .empty,
                interactionMode: .idle,
                viewportSize: viewportSize,
                boardReferenceSize: viewportSize
            ),
            .tile(0)
        )

        let transformedState = GameBoardCameraState(zoom: 1.8, offset: CGSize(width: 28, height: -18))
        let edgeMidpoint = layout.edgeMidpoint(for: 3, topology: model.topology)
        let transformedMidpoint = transform(
            edgeMidpoint,
            state: transformedState,
            viewportSize: viewportSize,
            boardCenter: layout.boardCenter
        )

        XCTAssertEqual(
            GameBoardCameraController.hitTarget(
                at: transformedMidpoint,
                state: transformedState,
                renderModel: model,
                overlayModel: .empty,
                interactionMode: .idle,
                viewportSize: viewportSize,
                boardReferenceSize: viewportSize
            ),
            .edge(3)
        )
    }

    func testHitTargetUsesReferenceBoardSpaceWhenViewportShrinks() {
        let model = makeRenderModel()
        let referenceSize = CGSize(width: 320, height: 240)
        let viewportSize = CGSize(width: 320, height: 180)
        let layout = GameBoardLayout(size: referenceSize, geometry: model.geometry)
        let tileID = 0
        let tappedPoint = transform(
            layout.tileCenter(for: tileID),
            state: GameBoardCameraState(),
            viewportSize: viewportSize,
            boardCenter: layout.boardCenter
        )

        XCTAssertEqual(
            GameBoardCameraController.hitTarget(
                at: tappedPoint,
                state: GameBoardCameraState(),
                renderModel: model,
                overlayModel: .empty,
                interactionMode: .idle,
                viewportSize: viewportSize,
                boardReferenceSize: referenceSize
            ),
            .tile(tileID)
        )
    }

    func testProjectedLegalTargetLocationRoundTripsThroughProductionHitTesting() throws {
        let model = makeRenderModel()
        let referenceSize = CGSize(width: 320, height: 240)
        let viewportSize = CGSize(width: 320, height: 180)
        let state = GameBoardCameraState(zoom: 1.35, offset: CGSize(width: 18, height: -12))
        let cases: [(target: GameBoardTarget, mode: GameMode, overlay: GameBoardOverlayModel)] = [
            (
                .node(0),
                .buildSettlement,
                GameBoardOverlayModel(
                    legalTileIDs: [], legalNodeIDs: [0], legalEdgeIDs: [],
                    anchorNodeID: nil, selectedTarget: nil
                )
            ),
            (
                .edge(3),
                .buildRoad,
                GameBoardOverlayModel(
                    legalTileIDs: [], legalNodeIDs: [], legalEdgeIDs: [3],
                    anchorNodeID: nil, selectedTarget: nil
                )
            ),
            (
                .tile(0),
                .robberMove,
                GameBoardOverlayModel(
                    legalTileIDs: [0], legalNodeIDs: [], legalEdgeIDs: [],
                    anchorNodeID: nil, selectedTarget: nil
                )
            ),
        ]

        for item in cases {
            let location = try XCTUnwrap(
                GameBoardCameraController.projectedLocation(
                    for: item.target,
                    state: state,
                    renderModel: model,
                    viewportSize: viewportSize,
                    boardReferenceSize: referenceSize
                )
            )
            XCTAssertEqual(
                GameBoardCameraController.hitTarget(
                    at: location,
                    state: state,
                    renderModel: model,
                    overlayModel: item.overlay,
                    interactionMode: item.mode,
                    viewportSize: viewportSize,
                    boardReferenceSize: referenceSize
                ),
                item.target
            )
        }
    }

    func testSetupRoadModePrefersIncidentEdgeNearSettlementEndpoint() {
        let model = makeRenderModel()
        let viewportSize = CGSize(width: 320, height: 240)
        let layout = GameBoardLayout(size: viewportSize, geometry: model.geometry)
        let edgeID = 3
        let anchorNodeID = model.topology.edges[edgeID].a
        let edgeLine = layout.edgeLine(for: edgeID, topology: model.topology)
        let anchorPoint = layout.nodePoint(for: anchorNodeID)
        let startPoint: CGPoint
        let endPoint: CGPoint

        if distanceBetween(anchorPoint, edgeLine.start) <= distanceBetween(anchorPoint, edgeLine.end) {
            startPoint = edgeLine.start
            endPoint = edgeLine.end
        } else {
            startPoint = edgeLine.end
            endPoint = edgeLine.start
        }

        let nearAnchorPoint = CGPoint(
            x: startPoint.x + ((endPoint.x - startPoint.x) * 0.05),
            y: startPoint.y + ((endPoint.y - startPoint.y) * 0.05)
        )

        XCTAssertEqual(
            GameBoardCameraController.hitTarget(
                at: nearAnchorPoint,
                state: GameBoardCameraState(),
                renderModel: model,
                overlayModel: GameBoardOverlayModel(
                    legalTileIDs: [],
                    legalNodeIDs: [],
                    legalEdgeIDs: [edgeID],
                    anchorNodeID: anchorNodeID,
                    selectedTarget: nil
                ),
                interactionMode: .setup,
                viewportSize: viewportSize,
                boardReferenceSize: viewportSize
            ),
            .edge(edgeID)
        )
    }

    func testBuildRoadModeOnlyResolvesLegalEdges() {
        let model = makeRenderModel()
        let viewportSize = CGSize(width: 320, height: 240)
        let layout = GameBoardLayout(size: viewportSize, geometry: model.geometry)
        let edgeID = 3
        let edgeLine = layout.edgeLine(for: edgeID, topology: model.topology)
        let point = CGPoint(
            x: edgeLine.start.x + ((edgeLine.end.x - edgeLine.start.x) * 0.22),
            y: edgeLine.start.y + ((edgeLine.end.y - edgeLine.start.y) * 0.22)
        )

        XCTAssertEqual(
            GameBoardCameraController.hitTarget(
                at: point,
                state: GameBoardCameraState(),
                renderModel: model,
                overlayModel: GameBoardOverlayModel(
                    legalTileIDs: [],
                    legalNodeIDs: [model.topology.edges[edgeID].a],
                    legalEdgeIDs: [edgeID],
                    anchorNodeID: nil,
                    selectedTarget: nil
                ),
                interactionMode: .buildRoad,
                viewportSize: viewportSize,
                boardReferenceSize: viewportSize
            ),
            .edge(edgeID)
        )
    }

    func testTradeModeDoesNotResolveBoardTargets() {
        let model = makeRenderModel()
        let viewportSize = CGSize(width: 320, height: 240)
        let layout = GameBoardLayout(size: viewportSize, geometry: model.geometry)

        XCTAssertNil(
            GameBoardCameraController.hitTarget(
                at: layout.nodePoint(for: 0),
                state: GameBoardCameraState(),
                renderModel: model,
                overlayModel: .empty,
                interactionMode: .trade,
                viewportSize: viewportSize,
                boardReferenceSize: viewportSize
            )
        )
    }

    func testChoiceDrivenDevCardModesOnlyResolveTheirLegalTargets() {
        let model = makeRenderModel()
        let viewportSize = CGSize(width: 320, height: 240)
        let layout = GameBoardLayout(size: viewportSize, geometry: model.geometry)
        let tileID = 0
        let nodeID = 0
        let edgeID = 3

        XCTAssertEqual(
            GameBoardCameraController.hitTarget(
                at: layout.tileCenter(for: tileID),
                state: GameBoardCameraState(),
                renderModel: model,
                overlayModel: GameBoardOverlayModel(
                    legalTileIDs: [tileID],
                    legalNodeIDs: [],
                    legalEdgeIDs: [],
                    anchorNodeID: nil,
                    selectedTarget: nil
                ),
                interactionMode: .devCardKnightMove,
                viewportSize: viewportSize,
                boardReferenceSize: viewportSize
            ),
            .tile(tileID)
        )

        XCTAssertEqual(
            GameBoardCameraController.hitTarget(
                at: layout.nodePoint(for: nodeID),
                state: GameBoardCameraState(),
                renderModel: model,
                overlayModel: GameBoardOverlayModel(
                    legalTileIDs: [],
                    legalNodeIDs: [nodeID],
                    legalEdgeIDs: [],
                    anchorNodeID: nil,
                    selectedTarget: nil
                ),
                interactionMode: .devCardKnightVictim,
                viewportSize: viewportSize,
                boardReferenceSize: viewportSize
            ),
            .node(nodeID)
        )

        let edgeLine = layout.edgeLine(for: edgeID, topology: model.topology)
        let edgePoint = CGPoint(
            x: edgeLine.start.x + ((edgeLine.end.x - edgeLine.start.x) * 0.22),
            y: edgeLine.start.y + ((edgeLine.end.y - edgeLine.start.y) * 0.22)
        )
        XCTAssertEqual(
            GameBoardCameraController.hitTarget(
                at: edgePoint,
                state: GameBoardCameraState(),
                renderModel: model,
                overlayModel: GameBoardOverlayModel(
                    legalTileIDs: [],
                    legalNodeIDs: [],
                    legalEdgeIDs: [edgeID],
                    anchorNodeID: nil,
                    selectedTarget: nil
                ),
                interactionMode: .devCardRoadBuildingFirst,
                viewportSize: viewportSize,
                boardReferenceSize: viewportSize
            ),
            .edge(edgeID)
        )

        XCTAssertNil(
            GameBoardCameraController.hitTarget(
                at: layout.nodePoint(for: nodeID),
                state: GameBoardCameraState(),
                renderModel: model,
                overlayModel: .empty,
                interactionMode: .devCardMonopoly,
                viewportSize: viewportSize,
                boardReferenceSize: viewportSize
            )
        )
    }

    private func makeRenderModel() -> GameBoardRenderModel {
        let board = BoardSetupV1(
            resourcesByTile: [
                .wood, .brick, .desert, .sheep, .wheat,
                .ore, .wood, .brick, .sheep, .wheat,
                .ore, .wood, .brick, .sheep, .wheat,
                .ore, .wood, .brick, .sheep,
            ],
            numbersByTile: [
                5, 2, nil, 6, 3,
                8, 10, 9, 12, 11,
                4, 8, 10, 9, 4,
                5, 6, 3, 11,
            ],
            portsByIndex: StandardBoardTopologyV1.standard().ports.map(\.kind),
            robberTile: 2,
            generator: .noRedAdjacentV1,
            boardHash: ""
        ).rehashed()

        let state = CoreGameStateV1(
            gameId: "camera-controller",
            rev: 2,
            prevHash: "hash-1",
            stateHash: "",
            roster: ["A", "B", "C"],
            currentPlayer: "A",
            phase: .turn,
            seed: 1,
            diceRngState: 2,
            robberRngState: 3,
            resourcesByPlayer: ["A": .zero, "B": .zero, "C": .zero],
            settlementsByNode: [0: "A"],
            citiesByNode: [9: "B"],
            roadsByEdge: [3: "A"],
            boardRules: BoardRulesV1(strategy: .noRedAdjacentV1),
            board: board,
            turnState: TurnStateV1(step: .afterRoll, lastRoll: DiceRollV1(d1: 4, d2: 2))
        ).rehashed()

        guard let model = GameBoardRenderModelBuilder.build(state: state) else {
            fatalError("Expected render model")
        }
        return model
    }

    private func transform(
        _ point: CGPoint,
        state: GameBoardCameraState,
        viewportSize: CGSize,
        boardCenter: CGPoint
    ) -> CGPoint {
        let viewportCenter = CGPoint(x: viewportSize.width * 0.5, y: viewportSize.height * 0.5)
        return CGPoint(
            x: viewportCenter.x + ((point.x - boardCenter.x) * state.zoom) + state.offset.width,
            y: viewportCenter.y + ((point.y - boardCenter.y) * state.zoom) + state.offset.height
        )
    }

    private func distanceBetween(_ lhs: CGPoint, _ rhs: CGPoint) -> CGFloat {
        let dx = lhs.x - rhs.x
        let dy = lhs.y - rhs.y
        return sqrt((dx * dx) + (dy * dy))
    }
}
