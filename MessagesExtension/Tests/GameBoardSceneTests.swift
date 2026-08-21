import CoreGraphics
import SpriteKit
import UIKit
import ULS_CoreGame
import XCTest
@testable import MessagesExtension

final class GameBoardSceneTests: XCTestCase {
    func testFlatWaterIsProductionOceanDefault() {
        XCTAssertEqual(GameBoardOceanStyle.productionDefault, .flat)
    }

    func testSharedSettlementAndCityGeometryRemainDistinct() {
        let settlement = GamePieceGeometry.structurePath(kind: .settlement, radius: 20)
        let city = GamePieceGeometry.structurePath(kind: .city, radius: 20)

        XCTAssertGreaterThan(city.boundingBox.width, settlement.boundingBox.width)
        XCTAssertNotEqual(city.boundingBox, settlement.boundingBox)
        XCTAssertFalse(city.isEmpty)
        XCTAssertFalse(settlement.isEmpty)
    }

    func testCityGeometryStacksHalfWidthSettlementOnMatchingHeightRectangle() {
        let settlement = GamePieceGeometry.structurePath(kind: .settlement, radius: 20)
        let city = GamePieceGeometry.structurePath(kind: .city, radius: 20)

        XCTAssertTrue(city.contains(CGPoint(x: -10, y: 8)))
        XCTAssertTrue(city.contains(CGPoint(x: 12, y: -2)))
        XCTAssertFalse(city.contains(CGPoint(x: 12, y: 2)))
        XCTAssertFalse(city.contains(CGPoint(x: 2, y: 8)))
        XCTAssertEqual(city.boundingBox.width / settlement.boundingBox.width, 1.568, accuracy: 0.001)
        XCTAssertEqual(city.boundingBox.height / settlement.boundingBox.height, 1.112, accuracy: 0.001)
        XCTAssertEqual(
            (20 * GamePieceGeometry.structureScale(for: .city) * 0.90) / settlement.boundingBox.width,
            0.784,
            accuracy: 0.001
        )
    }

    func testNumberTokenFillLetsTerrainRemainVisible() {
        var alpha: CGFloat = 0

        GameBoardPalette.tokenFill.getRed(nil, green: nil, blue: nil, alpha: &alpha)

        XCTAssertLessThan(alpha, 0.90)
        XCTAssertGreaterThanOrEqual(alpha, 0.80)
    }

    func testNumberTokenProbabilityPipsMatchDiceCombinations() {
        XCTAssertEqual(GameBoardScene.numberTokenPipCount(for: 2), 1)
        XCTAssertEqual(GameBoardScene.numberTokenPipCount(for: 3), 2)
        XCTAssertEqual(GameBoardScene.numberTokenPipCount(for: 4), 3)
        XCTAssertEqual(GameBoardScene.numberTokenPipCount(for: 5), 4)
        XCTAssertEqual(GameBoardScene.numberTokenPipCount(for: 6), 5)
        XCTAssertEqual(GameBoardScene.numberTokenPipCount(for: 8), 5)
        XCTAssertEqual(GameBoardScene.numberTokenPipCount(for: 9), 4)
        XCTAssertEqual(GameBoardScene.numberTokenPipCount(for: 10), 3)
        XCTAssertEqual(GameBoardScene.numberTokenPipCount(for: 11), 2)
        XCTAssertEqual(GameBoardScene.numberTokenPipCount(for: 12), 1)
        XCTAssertEqual(GameBoardScene.numberTokenPipCount(for: 7), 0)
    }

    @MainActor
    func testGameInfoOcclusionIsAuthoredInsideSpriteKitViewport() throws {
        let viewport = CGSize(width: 320, height: 240)
        let scene = GameBoardScene(size: viewport)

        // Production initializes the camera before presenting Game Information.
        // Exercise that path so the authored viewport coordinates are meaningful.
        scene.updateCamera(state: GameBoardCameraState(), viewportSize: viewport)
        scene.updateBottomOcclusion(height: 72, viewportSize: viewport)

        let occlusion = try XCTUnwrap(
            descendants(of: scene).first(where: { $0.name == "gameInfo.bottomOcclusion" })
                as? SKShapeNode
        )
        XCTAssertFalse(occlusion.isHidden)
        XCTAssertEqual(occlusion.zPosition, 1_000)
        XCTAssertEqual(occlusion.frame.minX, 0, accuracy: 0.01)
        XCTAssertEqual(occlusion.frame.maxX, 320, accuracy: 0.01)
        XCTAssertEqual(occlusion.frame.maxY, 72, accuracy: 0.01)

        scene.updateBottomOcclusion(height: 0, viewportSize: viewport)
        XCTAssertTrue(occlusion.isHidden)
    }

    func testNumberTokenNumeralsCenterTheirRenderedGlyphBounds() {
        let renderModel = makeRenderModel()
        let scene = GameBoardScene(size: CGSize(width: 320, height: 240))

        scene.update(
            renderModel: renderModel,
            referenceSize: CGSize(width: 320, height: 240),
            viewportSize: CGSize(width: 320, height: 240),
            overlayModel: .empty
        )

        let labels = descendants(of: scene)
            .compactMap { $0 as? SKLabelNode }
            .filter { $0.name == "numberToken.label" }

        XCTAssertFalse(labels.isEmpty)
        for label in labels {
            XCTAssertNotNil(label.attributedText)
            XCTAssertEqual(label.frame.midX, 0, accuracy: 0.01, "Expected \(label.text ?? "number") to be optically centered.")
        }
    }

    @MainActor
    func testRobberScalesAndCentersAcrossBoardReferenceSizes() throws {
        let renderModel = makeRenderModel()
        let referenceSizes = [
            CGSize(width: 240, height: 180),
            CGSize(width: 360, height: 260),
            CGSize(width: 768, height: 600),
        ]

        for referenceSize in referenceSizes {
            let scene = GameBoardScene(size: referenceSize)
            scene.update(
                renderModel: renderModel,
                referenceSize: referenceSize,
                viewportSize: referenceSize,
                overlayModel: .empty
            )

            let robber = try XCTUnwrap(
                descendants(of: scene).first(where: { $0.name == "robber" })
            )
            let artwork = try XCTUnwrap(
                robber.children.first(where: { $0.name == "robber.artwork" })
            )
            let pieceBounds = artwork.children
                .filter { ["robber.base", "robber.body", "robber.head"].contains($0.name) }
                .map(\.frame)
                .reduce(CGRect.null) { $0.union($1) }
            let layout = GameBoardLayout(size: referenceSize, geometry: renderModel.geometry)

            XCTAssertEqual(robber.position.x, 0, accuracy: 0.001)
            XCTAssertEqual(robber.position.y, 0, accuracy: 0.001)
            XCTAssertEqual(pieceBounds.midX, 0, accuracy: 0.01)
            XCTAssertEqual(pieceBounds.midY, 0, accuracy: 0.01)
            XCTAssertEqual(
                pieceBounds.height,
                GameBoardScene.robberHeight(forTileRadius: layout.tileRadius),
                accuracy: 0.01
            )

            let view = SKView(frame: CGRect(origin: .zero, size: referenceSize))
            view.presentScene(scene)
            let texture = try XCTUnwrap(view.texture(from: scene))
            let image = UIImage(cgImage: texture.cgImage())
            let attachment = XCTAttachment(image: image)
            attachment.name = "Robber centered \(Int(referenceSize.width))x\(Int(referenceSize.height))"
            attachment.lifetime = .keepAlways
            add(attachment)
        }
    }

    func testOceanBackdropIsOneUninterruptedWaterSurface() throws {
        let renderModel = makeRenderModel()
        let scene = GameBoardScene(size: CGSize(width: 320, height: 240))

        scene.update(
            renderModel: renderModel,
            referenceSize: CGSize(width: 320, height: 240),
            viewportSize: CGSize(width: 320, height: 240),
            overlayModel: .empty
        )
        scene.updateOceanStyle(.shallowGlow, referenceSize: CGSize(width: 320, height: 240))

        let base = try XCTUnwrap(baseContentNode(in: scene))
        let backdropLayer = try XCTUnwrap(base.children.first)
        let backdrop = try XCTUnwrap(backdropLayer.children.first)
        let water = try XCTUnwrap(backdrop.children.first as? SKShapeNode)

        XCTAssertEqual(backdrop.children.count, 1)
        XCTAssertNotNil(water.fillTexture)
        XCTAssertEqual(water.name, "oceanBackdrop")
        XCTAssertLessThanOrEqual(water.frame.minX, -GameBoardScene.backdropOverscan)
        XCTAssertLessThanOrEqual(water.frame.minY, -GameBoardScene.backdropOverscan)
        XCTAssertGreaterThanOrEqual(water.frame.maxX, 320 + GameBoardScene.backdropOverscan)
        XCTAssertGreaterThanOrEqual(water.frame.maxY, 240 + GameBoardScene.backdropOverscan)
    }

    func testPortsUsePhysicalShipAndResourceMarkersInsteadOfRateLabels() {
        let renderModel = makeRenderModel()
        let scene = GameBoardScene(size: CGSize(width: 320, height: 240))

        scene.update(
            renderModel: renderModel,
            referenceSize: CGSize(width: 320, height: 240),
            viewportSize: CGSize(width: 320, height: 240),
            overlayModel: .empty
        )

        let nodes = descendants(of: scene)
        XCTAssertEqual(nodes.filter { $0.name == "port.generic.ship" }.count, 4)
        XCTAssertEqual(nodes.filter { $0.name == "port.generic.ship.art" && $0 is SKSpriteNode }.count, 4)
        XCTAssertEqual(nodes.filter { $0.name?.hasPrefix("port.resource.") == true }.count, 5)
        XCTAssertFalse(nodes.compactMap { $0 as? SKLabelNode }.contains { $0.text == "3:1" || $0.text == "2:1" })
    }

    func testSharedRoadGeometryUsesRequestedLength() {
        let road = GamePieceGeometry.roadPath(length: 54)

        XCTAssertEqual(road.boundingBox.width, 54, accuracy: 0.001)
        XCTAssertEqual(road.boundingBox.height, 0, accuracy: 0.001)
    }

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

    func testTileNodesUseSpriteKitFieldAndSavedStampSprite() throws {
        let renderModel = makeRenderModel()
        let scene = GameBoardScene(size: CGSize(width: 320, height: 240))

        scene.update(
            renderModel: renderModel,
            referenceSize: CGSize(width: 320, height: 240),
            viewportSize: CGSize(width: 320, height: 240),
            overlayModel: .empty
        )

        let layout = GameBoardLayout(size: CGSize(width: 320, height: 240), geometry: renderModel.geometry)
        let tileNode = try XCTUnwrap(self.tileNode(forTileID: 0, in: scene, renderModel: renderModel))
        let field = try XCTUnwrap(tileNode.children.compactMap { $0 as? SKShapeNode }.first(where: { $0.name == "tileField" }))
        let terrainInset = try XCTUnwrap(tileNode.children.compactMap { $0 as? SKShapeNode }.first(where: { $0.name == "tileTerrainInset" }))
        let stampCrop = try XCTUnwrap(tileNode.children.compactMap { $0 as? SKCropNode }.first(where: { $0.name == "tileStampCrop" }))
        let stamp = try XCTUnwrap(stampCrop.children.compactMap { $0 as? SKSpriteNode }.first(where: { $0.name == "tileStamp" }))
        let expectedSize = GameBoardTileArt.stampSize(for: renderModel.tiles[0].resource, hexRadius: layout.tileRadius)

        XCTAssertColor(
            field.fillColor,
            equals: GameBoardPalette.resourceFill(for: renderModel.tiles[0].resource)
        )
        XCTAssertColor(
            terrainInset.strokeColor,
            equals: GameBoardPalette.resourceInset(for: renderModel.tiles[0].resource)
        )
        XCTAssertNotNil(stampCrop.maskNode)
        XCTAssertNotNil(stamp.texture)
        XCTAssertEqual(stamp.texture?.usesMipmaps, true)
        XCTAssertEqual(stamp.colorBlendFactor, 0)
        XCTAssertEqual(stampCrop.zPosition, 10)
        XCTAssertEqual(GameBoardTileArt.fieldHexRadius(forTopologyRadius: layout.tileRadius), layout.tileRadius)
        XCTAssertEqual(stamp.size.width, expectedSize.width, accuracy: 0.001)
        XCTAssertEqual(stamp.size.height, expectedSize.height, accuracy: 0.001)
    }

    func testPermanentGridDrawsSharedPhysicalFrameWithoutNodeCaps() throws {
        let renderModel = makeRenderModel()
        let scene = GameBoardScene(size: CGSize(width: 320, height: 240))

        scene.update(
            renderModel: renderModel,
            referenceSize: CGSize(width: 320, height: 240),
            viewportSize: CGSize(width: 320, height: 240),
            overlayModel: .empty
        )

        let layout = GameBoardLayout(size: CGSize(width: 320, height: 240), geometry: renderModel.geometry)
        let gridRoot = try XCTUnwrap(gridRootNode(in: scene))
        let borderNodes = gridRoot.children.compactMap { $0 as? SKShapeNode }

        XCTAssertEqual(gridRoot.children.count, 3)
        XCTAssertEqual(borderNodes.count, 3)

        let darkFrame = try XCTUnwrap(borderNodes.first)
        let warmFrame = try XCTUnwrap(borderNodes.dropFirst().first)
        let hairline = try XCTUnwrap(borderNodes.dropFirst(2).first)

        XCTAssertEqual(darkFrame.name, "tileFrameDark")
        XCTAssertEqual(warmFrame.name, "tileFrameWarm")
        XCTAssertEqual(hairline.name, "tileFrameHairline")
        XCTAssertEqual(darkFrame.lineCap, .square)
        XCTAssertEqual(warmFrame.lineCap, .square)
        XCTAssertEqual(hairline.lineCap, .square)
        XCTAssertEqual(darkFrame.lineWidth, max(layout.tileRadius * 0.12, 4.2), accuracy: 0.001)
        XCTAssertEqual(warmFrame.lineWidth, max(layout.tileRadius * 0.066, 2.5), accuracy: 0.001)
        XCTAssertEqual(hairline.lineWidth, max(layout.tileRadius * 0.018, 0.7), accuracy: 0.001)
        XCTAssertLessThan(darkFrame.lineWidth, layout.roadWidth)

        let expectedPathElementCount = renderModel.topology.edges.count * 2
        XCTAssertEqual(pathElementCount(in: darkFrame.path), expectedPathElementCount)
        XCTAssertEqual(pathElementCount(in: warmFrame.path), expectedPathElementCount)
        XCTAssertEqual(pathElementCount(in: hairline.path), expectedPathElementCount)
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

    private func gridRootNode(in scene: GameBoardScene) -> SKNode? {
        baseContentNode(in: scene)?
            .children
            .compactMap { $0.children.first }
            .first(where: { $0.name == "tileFrameNetwork" })
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

    private func descendants(of node: SKNode) -> [SKNode] {
        node.children + node.children.flatMap { descendants(of: $0) }
    }

    private func pathElementCount(in path: CGPath?) -> Int {
        var count = 0
        path?.applyWithBlock { _ in count += 1 }
        return count
    }

    private func XCTAssertColor(
        _ actual: SKColor,
        equals expected: SKColor,
        accuracy: CGFloat = 0.001,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        var actualRed: CGFloat = 0
        var actualGreen: CGFloat = 0
        var actualBlue: CGFloat = 0
        var actualAlpha: CGFloat = 0
        var expectedRed: CGFloat = 0
        var expectedGreen: CGFloat = 0
        var expectedBlue: CGFloat = 0
        var expectedAlpha: CGFloat = 0

        actual.getRed(&actualRed, green: &actualGreen, blue: &actualBlue, alpha: &actualAlpha)
        expected.getRed(&expectedRed, green: &expectedGreen, blue: &expectedBlue, alpha: &expectedAlpha)

        XCTAssertEqual(actualRed, expectedRed, accuracy: accuracy, file: file, line: line)
        XCTAssertEqual(actualGreen, expectedGreen, accuracy: accuracy, file: file, line: line)
        XCTAssertEqual(actualBlue, expectedBlue, accuracy: accuracy, file: file, line: line)
        XCTAssertEqual(actualAlpha, expectedAlpha, accuracy: accuracy, file: file, line: line)
    }
}
