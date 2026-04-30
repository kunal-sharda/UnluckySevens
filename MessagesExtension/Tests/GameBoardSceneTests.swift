import CoreGraphics
import SpriteKit
import ULS_CoreGame
import XCTest
@testable import MessagesExtension

final class GameBoardSceneTests: XCTestCase {
    func testOverlayUpdatesDoNotRebuildBaseSceneTree() throws {
        let renderModel = makeRenderModel()
        let scene = GameBoardScene(size: CGSize(width: 320, height: 240))

        scene.update(
            renderModel: renderModel,
            referenceSize: CGSize(width: 320, height: 240),
            viewportSize: CGSize(width: 320, height: 240),
            overlayModel: .empty
        )

        let baseNode = try XCTUnwrap(baseContentNode(in: scene))
        let baseIdentifier = ObjectIdentifier(baseNode)
        let baseChildCount = baseNode.children.count

        scene.updateOverlay(
            renderModel: renderModel,
            referenceSize: CGSize(width: 320, height: 240),
            viewportSize: CGSize(width: 320, height: 240),
            overlayModel: GameBoardOverlayModel(
                legalTileIDs: [],
                legalNodeIDs: [],
                legalEdgeIDs: [],
                anchorNodeID: nil,
                selectedTarget: .edge(3)
            )
        )

        let updatedBaseNode = try XCTUnwrap(baseContentNode(in: scene))
        let overlayNode = try XCTUnwrap(overlayContentNode(in: scene))

        XCTAssertEqual(ObjectIdentifier(updatedBaseNode), baseIdentifier)
        XCTAssertEqual(updatedBaseNode.children.count, baseChildCount)
        XCTAssertGreaterThan(overlayNode.children.count, 0)
    }

    func testCameraUpdatesStayInSceneState() throws {
        let scene = GameBoardScene(size: CGSize(width: 320, height: 240))
        let state = GameBoardCameraState(zoom: 1.8, offset: CGSize(width: 24, height: -18))

        scene.updateCamera(state: state, viewportSize: CGSize(width: 320, height: 240))

        let camera = try XCTUnwrap(scene.camera)
        XCTAssertEqual(camera.xScale, 1 / 1.8, accuracy: 0.001)
        XCTAssertEqual(camera.yScale, 1 / 1.8, accuracy: 0.001)
        XCTAssertEqual(camera.position.x, 160 - (24 / 1.8), accuracy: 0.001)
        XCTAssertEqual(camera.position.y, 120 + (-18 / 1.8), accuracy: 0.001)
    }

    func testViewportResizeDoesNotRebuildBaseSceneTree() throws {
        let renderModel = makeRenderModel()
        let scene = GameBoardScene(size: CGSize(width: 320, height: 240))

        scene.update(
            renderModel: renderModel,
            referenceSize: CGSize(width: 320, height: 240),
            viewportSize: CGSize(width: 320, height: 240),
            overlayModel: .empty
        )

        let baseNode = try XCTUnwrap(baseContentNode(in: scene))
        let baseIdentifier = ObjectIdentifier(baseNode)
        let baseChildCount = baseNode.children.count

        scene.updateViewport(viewportSize: CGSize(width: 320, height: 180))

        let updatedBaseNode = try XCTUnwrap(baseContentNode(in: scene))
        XCTAssertEqual(ObjectIdentifier(updatedBaseNode), baseIdentifier)
        XCTAssertEqual(updatedBaseNode.children.count, baseChildCount)
    }

    func testViewportResizeDoesNotChangeBoardWorldCoordinates() throws {
        let renderModel = makeRenderModel()
        let scene = GameBoardScene(size: CGSize(width: 320, height: 240))

        scene.update(
            renderModel: renderModel,
            referenceSize: CGSize(width: 320, height: 240),
            viewportSize: CGSize(width: 320, height: 240),
            overlayModel: .empty
        )

        let initialTileNode = try XCTUnwrap(tileNode(forTileID: 0, in: scene, renderModel: renderModel))
        let baseline = initialTileNode.position

        scene.updateViewport(viewportSize: CGSize(width: 320, height: 180))

        let resizedTileNode = try XCTUnwrap(self.tileNode(forTileID: 0, in: scene, renderModel: renderModel))
        XCTAssertEqual(
            resizedTileNode.position,
            baseline,
            "Board world coordinates should stay fixed when only the visible viewport changes."
        )
    }

    func testTileNodesUseTopLeftBoardCoordinates() throws {
        let renderModel = makeRenderModel()
        let scene = GameBoardScene(size: CGSize(width: 320, height: 240))

        scene.update(
            renderModel: renderModel,
            referenceSize: CGSize(width: 320, height: 240),
            viewportSize: CGSize(width: 320, height: 240),
            overlayModel: .empty
        )

        let layout = GameBoardLayout(size: CGSize(width: 320, height: 240), geometry: renderModel.geometry)
        let tileCenter = layout.tileCenter(for: 0)
        let expectedPosition = CGPoint(x: tileCenter.x, y: 240 - tileCenter.y)
        let tileNode = try XCTUnwrap(self.tileNode(forTileID: 0, in: scene, renderModel: renderModel))

        XCTAssertEqual(tileNode.position.x, expectedPosition.x, accuracy: 0.001)
        XCTAssertEqual(tileNode.position.y, expectedPosition.y, accuracy: 0.001)
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

    private func baseContentNode(in scene: GameBoardScene) -> SKNode? {
        contentRootNode(in: scene)?.children.first(where: { $0.zPosition == 0 })
    }

    private func overlayContentNode(in scene: GameBoardScene) -> SKNode? {
        contentRootNode(in: scene)?.children.first(where: { $0.zPosition == 90 })
    }

    private func contentRootNode(in scene: GameBoardScene) -> SKNode? {
        scene.children.first(where: { $0 !== scene.camera })
    }

    private func tileLayerNode(in scene: GameBoardScene, renderModel: GameBoardRenderModel) -> SKNode? {
        baseContentNode(in: scene)?.children.first(where: { $0.children.count == renderModel.tiles.count })
    }

    private func tileNode(
        forTileID tileID: Int,
        in scene: GameBoardScene,
        renderModel: GameBoardRenderModel
    ) -> SKNode? {
        let layout = GameBoardLayout(size: CGSize(width: 320, height: 240), geometry: renderModel.geometry)
        let tileCenter = layout.tileCenter(for: tileID)
        let expectedPosition = CGPoint(x: tileCenter.x, y: 240 - tileCenter.y)

        return tileLayerNode(in: scene, renderModel: renderModel)?.children.first(where: {
            abs($0.position.x - expectedPosition.x) < 0.001
                && abs($0.position.y - expectedPosition.y) < 0.001
        })
    }
}
