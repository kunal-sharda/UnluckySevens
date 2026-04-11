import CoreGraphics
import ULS_CoreGame
import XCTest
@testable import MessagesExtension

final class GameBoardSceneTests: XCTestCase {
    func testOverlayUpdatesDoNotRebuildBaseSceneTree() {
        let renderModel = makeRenderModel()
        let scene = GameBoardScene(size: CGSize(width: 320, height: 240))

        scene.update(
            renderModel: renderModel,
            size: CGSize(width: 320, height: 240),
            overlayModel: .empty
        )

        let baseIdentifier = scene.debugBaseNodeIdentifier
        let baseChildCount = scene.debugBaseChildCount

        scene.updateOverlay(
            renderModel: renderModel,
            size: CGSize(width: 320, height: 240),
            overlayModel: GameBoardOverlayModel(
                legalTileIDs: [],
                legalNodeIDs: [],
                legalEdgeIDs: [],
                anchorNodeID: nil,
                selectedTarget: .edge(3)
            )
        )

        XCTAssertEqual(scene.debugBaseNodeIdentifier, baseIdentifier)
        XCTAssertEqual(scene.debugBaseChildCount, baseChildCount)
        XCTAssertGreaterThan(scene.debugOverlayChildCount, 0)
    }

    func testCameraUpdatesStayInSceneState() {
        let scene = GameBoardScene(size: CGSize(width: 320, height: 240))
        let state = GameBoardCameraState(zoom: 1.8, offset: CGSize(width: 24, height: -18))

        scene.updateCamera(state: state, size: CGSize(width: 320, height: 240))

        XCTAssertEqual(scene.debugCameraState, state)
        XCTAssertEqual(scene.debugCameraNodePosition.x, 160 - (24 / 1.8), accuracy: 0.001)
        XCTAssertEqual(scene.debugCameraNodePosition.y, 120 + (-18 / 1.8), accuracy: 0.001)
    }

    func testScenePointsUseTopLeftBoardCoordinates() {
        let scene = GameBoardScene(size: CGSize(width: 320, height: 240))

        XCTAssertEqual(
            scene.debugScenePoint(forLayoutPoint: CGPoint(x: 40, y: 20)),
            CGPoint(x: 40, y: 220)
        )
        XCTAssertEqual(
            scene.debugScenePoint(forLayoutPoint: CGPoint(x: 120, y: 200)),
            CGPoint(x: 120, y: 40)
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
            gameId: "scene-tests",
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

        return GameBoardRenderModelBuilder.build(state: state)!
    }
}
