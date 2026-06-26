import CoreGraphics
import SpriteKit
import ULS_CoreGame

final class GameBoardScene: SKScene {
    private let contentRootNode = SKNode()
    private let baseContentNode = SKNode()
    private let overlayContentNode = SKNode()
    private let backdropContentNode = SKNode()
    private let tileContentNode = SKNode()
    private let gridContentNode = SKNode()
    private let portContentNode = SKNode()
    private let roadContentNode = SKNode()
    private let structureContentNode = SKNode()
    private let cameraNode = SKCameraNode()
    private var currentCameraState = GameBoardCameraState()
    private var boardWorldSize: CGSize
    private var cachedBackdropKey: BackdropLayerKey?
    private var cachedTileKey: TileLayerKey?
    private var cachedGridKey: GridLayerKey?
    private var cachedPortKey: PortLayerKey?
    private var cachedRoadKey: RoadLayerKey?
    private var cachedStructureKey: StructureLayerKey?
    private var cachedOverlayKey: OverlayLayerKey?

    override init(size: CGSize) {
        boardWorldSize = size
        super.init(size: size)
        scaleMode = .resizeFill
        backgroundColor = GameBoardPalette.sceneBackground
        configureSceneRoots()
    }

    required init?(coder aDecoder: NSCoder) {
        boardWorldSize = CGSize(width: 320, height: 240)
        super.init(coder: aDecoder)
        scaleMode = .resizeFill
        backgroundColor = GameBoardPalette.sceneBackground
        configureSceneRoots()
    }

    func update(
        renderModel: GameBoardRenderModel,
        referenceSize: CGSize,
        viewportSize: CGSize,
        overlayModel: GameBoardOverlayModel
    ) {
        updateBase(renderModel: renderModel, referenceSize: referenceSize, viewportSize: viewportSize)
        updateOverlay(
            renderModel: renderModel,
            referenceSize: referenceSize,
            viewportSize: viewportSize,
            overlayModel: overlayModel
        )
    }

    func updateViewport(viewportSize: CGSize) {
        if self.size != viewportSize {
            self.size = viewportSize
        }
        applyCameraState()
    }

    func updateBase(renderModel: GameBoardRenderModel, referenceSize: CGSize, viewportSize: CGSize) {
        if self.size != viewportSize {
            self.size = viewportSize
        }
        boardWorldSize = referenceSize
        applyCameraState()
        let layout = GameBoardLayout(size: referenceSize, geometry: renderModel.geometry)

        let backdropKey = BackdropLayerKey(referenceSize: referenceSize)
        if cachedBackdropKey != backdropKey {
            cachedBackdropKey = backdropKey
            backdropContentNode.removeAllChildren()
            backdropContentNode.addChild(makeBoardBackdrop(size: referenceSize))
        }

        let tileKey = TileLayerKey(referenceSize: referenceSize, tiles: renderModel.tiles)
        if cachedTileKey != tileKey {
            cachedTileKey = tileKey
            tileContentNode.removeAllChildren()
            for tile in renderModel.tiles {
                tileContentNode.addChild(makeTileNode(tile: tile, layout: layout))
            }
        }

        let gridKey = GridLayerKey(referenceSize: referenceSize, topology: renderModel.topology)
        if cachedGridKey != gridKey {
            cachedGridKey = gridKey
            gridContentNode.removeAllChildren()
            gridContentNode.addChild(makeBoardGridNode(layout: layout, topology: renderModel.topology))
        }

        let portKey = PortLayerKey(
            referenceSize: referenceSize,
            topology: renderModel.topology,
            ports: renderModel.ports
        )
        if cachedPortKey != portKey {
            cachedPortKey = portKey
            portContentNode.removeAllChildren()
            for port in renderModel.ports {
                portContentNode.addChild(makePortNode(port: port, layout: layout, topology: renderModel.topology))
            }
        }

        let roadKey = RoadLayerKey(
            referenceSize: referenceSize,
            topology: renderModel.topology,
            roads: renderModel.roads,
            playerOrder: renderModel.playerOrder
        )
        if cachedRoadKey != roadKey {
            cachedRoadKey = roadKey
            roadContentNode.removeAllChildren()
            for road in renderModel.roads {
                roadContentNode.addChild(
                    makeRoadNode(
                        road: road,
                        layout: layout,
                        topology: renderModel.topology,
                        playerOrder: renderModel.playerOrder
                    )
                )
            }
        }

        let structureKey = StructureLayerKey(
            referenceSize: referenceSize,
            structures: renderModel.structures,
            playerOrder: renderModel.playerOrder
        )
        if cachedStructureKey != structureKey {
            cachedStructureKey = structureKey
            structureContentNode.removeAllChildren()
            for structure in renderModel.structures {
                structureContentNode.addChild(
                    makeStructureNode(
                        structure: structure,
                        layout: layout,
                        playerOrder: renderModel.playerOrder
                    )
                )
            }
        }
    }

    func updateOverlay(
        renderModel: GameBoardRenderModel,
        referenceSize: CGSize,
        viewportSize: CGSize,
        overlayModel: GameBoardOverlayModel
    ) {
        if self.size != viewportSize {
            self.size = viewportSize
        }
        boardWorldSize = referenceSize
        applyCameraState()
        let overlayKey = OverlayLayerKey(
            referenceSize: referenceSize,
            topology: renderModel.topology,
            overlayModel: overlayModel
        )
        guard cachedOverlayKey != overlayKey else {
            return
        }

        cachedOverlayKey = overlayKey
        overlayContentNode.removeAllChildren()

        let layout = GameBoardLayout(size: referenceSize, geometry: renderModel.geometry)
        overlayContentNode.addChild(
            makeOverlayNode(
                overlayModel: overlayModel,
                layout: layout,
                topology: renderModel.topology
            )
        )
    }

    func updateCamera(state: GameBoardCameraState, viewportSize: CGSize) {
        if self.size != viewportSize {
            self.size = viewportSize
        }
        currentCameraState = state
        applyCameraState()
    }

    private func makeBoardBackdrop(size: CGSize) -> SKNode {
        let root = SKNode()

        let outerRect = CGRect(origin: .zero, size: size)
        let felt = SKShapeNode(rect: outerRect, cornerRadius: 30)
        felt.fillColor = GameBoardPalette.sceneBackground
        felt.strokeColor = GameBoardPalette.sceneBackgroundEdge
        felt.lineWidth = 1.5
        felt.zPosition = 0
        root.addChild(felt)
        root.addChild(makeClothThreadNode(in: outerRect))

        let shadowRect = outerRect.insetBy(dx: 8, dy: 8)
        let shadow = SKShapeNode(rect: shadowRect, cornerRadius: 31)
        shadow.fillColor = .black.withAlphaComponent(0.13)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 0, y: -2)
        shadow.zPosition = 1
        root.addChild(shadow)

        let rimRect = outerRect.insetBy(dx: 7, dy: 7)
        let rim = SKShapeNode(rect: rimRect, cornerRadius: 31)
        rim.fillColor = GameBoardPalette.boardRim
        rim.strokeColor = GameBoardPalette.boardRimEdge
        rim.lineWidth = 1.3
        rim.zPosition = 2
        root.addChild(rim)

        let waterRect = outerRect.insetBy(dx: 12, dy: 12)
        let water = SKShapeNode(rect: waterRect, cornerRadius: 22)
        water.fillColor = GameBoardPalette.water
        water.strokeColor = GameBoardPalette.waterEdge
        water.lineWidth = 1.6
        water.zPosition = 3
        root.addChild(water)

        let inset = outerRect.insetBy(dx: 20, dy: 20)
        let boardBase = SKShapeNode(rect: inset, cornerRadius: 24)
        boardBase.fillColor = GameBoardPalette.boardBase
        boardBase.strokeColor = GameBoardPalette.boardBaseEdge
        boardBase.lineWidth = 0.8
        boardBase.zPosition = 4
        root.addChild(boardBase)

        return root
    }

    private func makeClothThreadNode(in rect: CGRect) -> SKNode {
        let node = SKNode()
        node.zPosition = 0.5

        let spacing: CGFloat = 18
        var y = rect.minY + spacing
        while y < rect.maxY {
            let path = CGMutablePath()
            path.move(to: CGPoint(x: rect.minX + 14, y: y))
            path.addLine(to: CGPoint(x: rect.maxX - 14, y: y + 3))

            let thread = SKShapeNode(path: path)
            thread.strokeColor = GameBoardPalette.clothThread
            thread.lineWidth = 1
            thread.lineCap = .round
            node.addChild(thread)
            y += spacing
        }

        return node
    }

    private func makeBoardGridNode(layout: GameBoardLayout, topology: BoardGraphV1) -> SKNode {
        let node = SKNode()
        node.zPosition = 32

        for edgeID in topology.edges.indices {
            let edgeLine = layout.edgeLine(for: edgeID, topology: topology)
            let sceneStart = scenePoint(for: edgeLine.start)
            let sceneEnd = scenePoint(for: edgeLine.end)

            let shadowPath = CGMutablePath()
            shadowPath.move(to: sceneStart)
            shadowPath.addLine(to: sceneEnd)

            let shadow = SKShapeNode(path: shadowPath)
            shadow.strokeColor = .black.withAlphaComponent(0.18)
            shadow.lineWidth = max(layout.roadWidth * 0.68, 5)
            shadow.lineCap = .round
            shadow.position = CGPoint(x: 0, y: -1.2)
            node.addChild(shadow)

            let edge = SKShapeNode(path: shadowPath)
            edge.strokeColor = GameBoardPalette.gridStroke
            edge.lineWidth = max(layout.roadWidth * 0.48, 4)
            edge.lineCap = .round
            node.addChild(edge)
        }

        for nodeID in 0..<topology.nodesCount {
            let point = scenePoint(for: layout.nodePoint(for: nodeID))
            let radius = max(layout.structureRadius * 0.68, 6)

            let shadow = SKShapeNode(circleOfRadius: radius + 1.2)
            shadow.position = CGPoint(x: point.x, y: point.y - 1.4)
            shadow.fillColor = .black.withAlphaComponent(0.20)
            shadow.strokeColor = .clear
            node.addChild(shadow)

            let cap = SKShapeNode(circleOfRadius: radius)
            cap.position = point
            cap.fillColor = GameBoardPalette.gridFill
            cap.strokeColor = GameBoardPalette.portStroke.withAlphaComponent(0.56)
            cap.lineWidth = 1
            node.addChild(cap)

            let inset = SKShapeNode(circleOfRadius: max(radius * 0.42, 2.5))
            inset.position = point
            inset.fillColor = .clear
            inset.strokeColor = GameBoardPalette.portStroke.withAlphaComponent(0.42)
            inset.lineWidth = 0.9
            node.addChild(inset)
        }

        return node
    }

    private func makeTileNode(tile: GameBoardTileRenderModel, layout: GameBoardLayout) -> SKNode {
        let tileNode = SKNode()
        tileNode.position = scenePoint(for: layout.tileCenter(for: tile.tileID))
        tileNode.zPosition = 20

        let shadow = SKShapeNode(path: hexagonPath(radius: layout.tileRadius))
        shadow.fillColor = .black.withAlphaComponent(0.12)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 0, y: -max(layout.tileRadius * 0.05, 2))
        shadow.zPosition = 0
        tileNode.addChild(shadow)

        let hex = SKShapeNode(path: hexagonPath(radius: layout.tileRadius))
        hex.fillColor = GameBoardPalette.resourceFill(for: tile.resource)
        hex.strokeColor = GameBoardPalette.outline
        hex.lineWidth = max(layout.tileRadius * 0.055, 2)
        hex.zPosition = 10
        tileNode.addChild(hex)

        tileNode.addChild(makeTerrainDetailNode(resource: tile.resource, radius: layout.tileRadius, seed: tile.tileID))

        let innerRing = SKShapeNode(path: hexagonPath(radius: layout.tileRadius * 0.84))
        innerRing.fillColor = .clear
        innerRing.strokeColor = .white.withAlphaComponent(0.10)
        innerRing.lineWidth = 1
        innerRing.zPosition = 11
        tileNode.addChild(innerRing)

        if let number = tile.number {
            tileNode.addChild(makeTokenNode(number: number, radius: layout.tileRadius))
        }

        if tile.hasRobber {
            tileNode.addChild(makeRobberNode(radius: layout.tileRadius))
        }

        return tileNode
    }

    private func makeTerrainDetailNode(resource: ResourceV1, radius: CGFloat, seed: Int) -> SKNode {
        let node = SKNode()
        node.zPosition = 12

        switch resource {
        case .wood:
            let points = terrainPoints(radius: radius, seed: seed, count: 10)
            for point in points {
                let trunk = SKShapeNode(rectOf: CGSize(width: max(radius * 0.035, 1.5), height: max(radius * 0.16, 5)))
                trunk.position = CGPoint(x: point.x, y: point.y - radius * 0.08)
                trunk.fillColor = SKColor(red: 0.18, green: 0.12, blue: 0.06, alpha: 0.34)
                trunk.strokeColor = .clear
                node.addChild(trunk)

                let tree = SKShapeNode(path: trianglePath(radius: max(radius * 0.13, 6)))
                tree.position = point
                tree.fillColor = SKColor(red: 0.10, green: 0.30, blue: 0.10, alpha: 0.42)
                tree.strokeColor = .clear
                node.addChild(tree)
            }
        case .brick:
            for index in 0..<7 {
                let path = CGMutablePath()
                let y = (-radius * 0.48) + (CGFloat(index) * radius * 0.16)
                path.move(to: CGPoint(x: -radius * 0.48, y: y))
                path.addLine(to: CGPoint(x: radius * 0.48, y: y + ((index.isMultiple(of: 2) ? 1 : -1) * radius * 0.035)))

                let ridge = SKShapeNode(path: path)
                ridge.strokeColor = SKColor(red: 0.36, green: 0.12, blue: 0.07, alpha: 0.24)
                ridge.lineWidth = max(radius * 0.018, 1)
                ridge.lineCap = .round
                node.addChild(ridge)
            }
        case .sheep:
            let points = terrainPoints(radius: radius, seed: seed + 11, count: 9)
            for point in points {
                let body = SKShapeNode(ellipseOf: CGSize(width: radius * 0.16, height: radius * 0.10))
                body.position = point
                body.fillColor = SKColor(red: 0.93, green: 0.88, blue: 0.72, alpha: 0.34)
                body.strokeColor = SKColor(red: 0.30, green: 0.38, blue: 0.16, alpha: 0.24)
                body.lineWidth = 0.6
                node.addChild(body)
            }
        case .wheat:
            for index in 0..<13 {
                let x = (-radius * 0.52) + (CGFloat(index) * radius * 0.085)
                let path = CGMutablePath()
                path.move(to: CGPoint(x: x, y: -radius * 0.46))
                path.addLine(to: CGPoint(x: x + radius * 0.14, y: radius * 0.48))

                let stalk = SKShapeNode(path: path)
                stalk.strokeColor = SKColor(red: 0.98, green: 0.83, blue: 0.24, alpha: 0.24)
                stalk.lineWidth = max(radius * 0.018, 1)
                stalk.lineCap = .round
                node.addChild(stalk)
            }
        case .ore:
            for point in terrainPoints(radius: radius, seed: seed + 23, count: 5) {
                let mountain = SKShapeNode(path: trianglePath(radius: radius * 0.22))
                mountain.position = point
                mountain.fillColor = SKColor(red: 0.20, green: 0.23, blue: 0.23, alpha: 0.30)
                mountain.strokeColor = SKColor.white.withAlphaComponent(0.16)
                mountain.lineWidth = 1
                node.addChild(mountain)
            }
        case .desert:
            for point in terrainPoints(radius: radius, seed: seed + 31, count: 13) {
                let pebble = SKShapeNode(circleOfRadius: max(radius * 0.025, 1.5))
                pebble.position = point
                pebble.fillColor = SKColor(red: 0.40, green: 0.30, blue: 0.18, alpha: 0.24)
                pebble.strokeColor = .clear
                node.addChild(pebble)
            }
        }

        return node
    }

    private func terrainPoints(radius: CGFloat, seed: Int, count: Int) -> [CGPoint] {
        let anchors: [CGPoint] = [
            CGPoint(x: -0.36, y: 0.24),
            CGPoint(x: -0.12, y: 0.34),
            CGPoint(x: 0.22, y: 0.28),
            CGPoint(x: 0.42, y: 0.05),
            CGPoint(x: 0.20, y: -0.22),
            CGPoint(x: -0.12, y: -0.30),
            CGPoint(x: -0.42, y: -0.06),
            CGPoint(x: 0.02, y: 0.04),
            CGPoint(x: -0.26, y: -0.18),
            CGPoint(x: 0.34, y: -0.34),
            CGPoint(x: -0.02, y: -0.48),
            CGPoint(x: -0.48, y: 0.10),
            CGPoint(x: 0.08, y: 0.50),
        ]

        return (0..<count).map { index in
            let anchor = anchors[(index + seed) % anchors.count]
            let jitterX = CGFloat(((seed * 17) + (index * 11)) % 9 - 4) * radius * 0.006
            let jitterY = CGFloat(((seed * 13) + (index * 7)) % 9 - 4) * radius * 0.006
            return CGPoint(
                x: (anchor.x * radius) + jitterX,
                y: (anchor.y * radius) + jitterY
            )
        }
    }

    private func makeTokenNode(number: Int, radius: CGFloat) -> SKNode {
        let node = SKNode()
        node.zPosition = 30

        let token = SKShapeNode(circleOfRadius: max(radius * 0.24, 10))
        token.fillColor = GameBoardPalette.tokenFill
        token.strokeColor = GameBoardPalette.tokenStroke
        token.lineWidth = 1.2
        node.addChild(token)

        let label = SKLabelNode(text: "\(number)")
        label.fontName = "Georgia-Bold"
        label.fontSize = max(radius * 0.34, 12)
        label.fontColor = (number == 6 || number == 8)
            ? SKColor(red: 0.65, green: 0.18, blue: 0.14, alpha: 0.92)
            : GameBoardPalette.ink
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.zPosition = 1
        node.addChild(label)

        return node
    }

    private func makeRobberNode(radius: CGFloat) -> SKNode {
        let node = SKNode()
        node.position = CGPoint(x: 0, y: -radius * 0.38)
        node.zPosition = 40

        let base = SKShapeNode(circleOfRadius: max(radius * 0.18, 8))
        base.fillColor = GameBoardPalette.robber
        base.strokeColor = .clear
        node.addChild(base)

        let cap = SKShapeNode(circleOfRadius: max(radius * 0.11, 5))
        cap.fillColor = GameBoardPalette.robberAccent
        cap.strokeColor = .clear
        cap.position = CGPoint(x: 0, y: max(radius * 0.12, 6))
        node.addChild(cap)

        return node
    }

    private func makePortNode(
        port: GameBoardPortRenderModel,
        layout: GameBoardLayout,
        topology: BoardGraphV1
    ) -> SKNode {
        let node = SKNode()
        node.zPosition = 35

        let edgeLine = layout.edgeLine(for: port.edgeID, topology: topology)
        let anchor = layout.portAnchor(for: port, topology: topology)
        let sceneStart = scenePoint(for: edgeLine.start)
        let sceneEnd = scenePoint(for: edgeLine.end)
        let sceneAnchor = scenePoint(for: anchor)
        let badgeRotation = portBadgeRotation(for: layout.edgeAngle(for: port.edgeID, topology: topology))

        node.addChild(
            makePortTether(
                from: sceneAnchor,
                to: sceneStart,
                width: max(layout.tileRadius * 0.08, 2)
            )
        )
        node.addChild(
            makePortTether(
                from: sceneAnchor,
                to: sceneEnd,
                width: max(layout.tileRadius * 0.08, 2)
            )
        )
        let badgeSize = layout.portBadgeSize
        let badgeContainer = SKNode()
        badgeContainer.position = sceneAnchor
        badgeContainer.zRotation = badgeRotation
        badgeContainer.zPosition = 1

        let badge = SKShapeNode(
            rect: CGRect(
                x: -(badgeSize.width * 0.5),
                y: -(badgeSize.height * 0.5),
                width: badgeSize.width,
                height: badgeSize.height
            ),
            cornerRadius: badgeSize.height * 0.45
        )
        badge.fillColor = GameBoardPalette.portFill
        badge.strokeColor = GameBoardPalette.portStroke
        badge.lineWidth = 1
        badgeContainer.addChild(badge)

        let label = SKLabelNode(text: GameBoardPalette.portLabel(for: port.kind))
        label.fontName = "AvenirNext-Bold"
        label.fontSize = max(layout.tileRadius * 0.14, 7.5)
        label.fontColor = GameBoardPalette.ink
        label.position = .zero
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.zPosition = 1
        badgeContainer.addChild(label)
        node.addChild(badgeContainer)

        return node
    }

    private func portBadgeRotation(for edgeAngle: CGFloat) -> CGFloat {
        var sceneAlignedAngle = -edgeAngle
        while sceneAlignedAngle > (.pi * 0.5) {
            sceneAlignedAngle -= .pi
        }
        while sceneAlignedAngle < (-.pi * 0.5) {
            sceneAlignedAngle += .pi
        }
        return sceneAlignedAngle
    }

    private func makePortTether(
        from start: CGPoint,
        to end: CGPoint,
        width: CGFloat,
        alpha: CGFloat = 0.75
    ) -> SKShapeNode {
        let path = CGMutablePath()
        path.move(to: start)
        path.addLine(to: end)

        let tether = SKShapeNode(path: path)
        tether.strokeColor = GameBoardPalette.portStroke.withAlphaComponent(alpha)
        tether.lineWidth = width
        tether.lineCap = .round
        return tether
    }

    private func makeRoadNode(
        road: GameBoardRoadRenderModel,
        layout: GameBoardLayout,
        topology: BoardGraphV1,
        playerOrder: [String]
    ) -> SKNode {
        let node = SKNode()
        node.zPosition = 50

        let edgeLine = layout.edgeLine(for: road.edgeID, topology: topology)
        let sceneStart = scenePoint(for: edgeLine.start)
        let sceneEnd = scenePoint(for: edgeLine.end)
        let color = GameBoardPalette.playerColor(owner: road.owner, playerOrder: playerOrder)
        let stroke = GameBoardPalette.playerStroke(owner: road.owner, playerOrder: playerOrder)

        let shadowPath = CGMutablePath()
        shadowPath.move(to: sceneStart)
        shadowPath.addLine(to: sceneEnd)

        let shadow = SKShapeNode(path: shadowPath)
        shadow.strokeColor = GameBoardPalette.roadShadow
        shadow.lineWidth = layout.roadWidth + 4
        shadow.lineCap = .round
        shadow.position = CGPoint(x: 0, y: -1)
        node.addChild(shadow)

        let roadPath = CGMutablePath()
        roadPath.move(to: sceneStart)
        roadPath.addLine(to: sceneEnd)

        let roadLine = SKShapeNode(path: roadPath)
        roadLine.strokeColor = color
        roadLine.lineWidth = layout.roadWidth
        roadLine.lineCap = .round
        node.addChild(roadLine)

        let highlight = SKShapeNode(path: roadPath)
        highlight.strokeColor = .white.withAlphaComponent(0.16)
        highlight.lineWidth = max(layout.roadWidth * 0.34, 2)
        highlight.lineCap = .round
        node.addChild(highlight)

        let outline = SKShapeNode(path: roadPath)
        outline.strokeColor = stroke
        outline.lineWidth = max(layout.roadWidth + 1.5, 1)
        outline.lineCap = .round
        outline.zPosition = -1
        node.addChild(outline)

        return node
    }

    private func makeStructureNode(
        structure: GameBoardStructureRenderModel,
        layout: GameBoardLayout,
        playerOrder: [String]
    ) -> SKNode {
        let node = SKNode()
        node.position = scenePoint(for: layout.nodePoint(for: structure.nodeID))
        node.zPosition = 60

        let shadow = SKShapeNode(path: structurePath(kind: structure.kind, radius: layout.structureRadius))
        shadow.fillColor = .black.withAlphaComponent(0.16)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 0, y: -2)
        node.addChild(shadow)

        let fill = SKShapeNode(path: structurePath(kind: structure.kind, radius: layout.structureRadius))
        fill.fillColor = GameBoardPalette.playerColor(owner: structure.owner, playerOrder: playerOrder)
        fill.strokeColor = GameBoardPalette.playerStroke(owner: structure.owner, playerOrder: playerOrder)
        fill.lineWidth = 1.3
        node.addChild(fill)

        let cap = SKShapeNode(path: structureCapPath(kind: structure.kind, radius: layout.structureRadius))
        cap.fillColor = GameBoardPalette.structureFill.withAlphaComponent(0.30)
        cap.strokeColor = .clear
        cap.position = CGPoint(x: 0, y: max(layout.structureRadius * 0.08, 1))
        node.addChild(cap)

        return node
    }

    private func makeOverlayNode(
        overlayModel: GameBoardOverlayModel,
        layout: GameBoardLayout,
        topology: BoardGraphV1
    ) -> SKNode {
        let node = SKNode()
        node.zPosition = 90
        let denseNodeHighlights = overlayModel.legalNodeIDs.count > 10

        if let anchorNodeID = overlayModel.anchorNodeID {
            node.addChild(
                makeAnchorHighlightNode(
                    at: scenePoint(for: layout.nodePoint(for: anchorNodeID)),
                    radius: layout.structureRadius
                )
            )
        }

        for tileID in overlayModel.legalTileIDs {
            node.addChild(
                makeTileHighlightNode(
                    at: scenePoint(for: layout.tileCenter(for: tileID)),
                    radius: layout.tileRadius,
                    isSelected: overlayModel.selectedTarget == .tile(tileID)
                )
            )
        }

        for edgeID in overlayModel.legalEdgeIDs {
            node.addChild(
                makeEdgeHighlightNode(
                    edgeID: edgeID,
                    layout: layout,
                    topology: topology,
                    isSelected: overlayModel.selectedTarget == .edge(edgeID)
                )
            )
        }

        for nodeID in overlayModel.legalNodeIDs {
            node.addChild(
                makeNodeHighlightNode(
                    at: scenePoint(for: layout.nodePoint(for: nodeID)),
                    radius: layout.structureRadius,
                    isSelected: overlayModel.selectedTarget == .node(nodeID),
                    denseCluster: denseNodeHighlights
                )
            )
        }

        if let selectedTarget = overlayModel.selectedTarget {
            switch selectedTarget {
            case let .tile(tileID) where !overlayModel.legalTileIDs.contains(tileID):
                node.addChild(
                    makeTileHighlightNode(
                        at: scenePoint(for: layout.tileCenter(for: tileID)),
                        radius: layout.tileRadius,
                        isSelected: true
                    )
                )
            case let .node(nodeID) where !overlayModel.legalNodeIDs.contains(nodeID):
                node.addChild(
                    makeNodeHighlightNode(
                        at: scenePoint(for: layout.nodePoint(for: nodeID)),
                        radius: layout.structureRadius,
                        isSelected: true,
                        denseCluster: false
                    )
                )
            case let .edge(edgeID) where !overlayModel.legalEdgeIDs.contains(edgeID):
                node.addChild(
                    makeEdgeHighlightNode(
                        edgeID: edgeID,
                        layout: layout,
                        topology: topology,
                        isSelected: true
                    )
                )
            default:
                break
            }
        }

        return node
    }

    private func makeAnchorHighlightNode(
        at center: CGPoint,
        radius: CGFloat
    ) -> SKNode {
        let node = SKNode()
        node.position = center
        node.zPosition = 1

        let halo = SKShapeNode(circleOfRadius: radius + 7)
        halo.fillColor = GameBoardPalette.legalHighlightFill.withAlphaComponent(0.18)
        halo.strokeColor = GameBoardPalette.selectedHighlight.withAlphaComponent(0.88)
        halo.lineWidth = 3
        node.addChild(halo)

        let ring = SKShapeNode(circleOfRadius: radius + 13)
        ring.fillColor = .clear
        ring.strokeColor = GameBoardPalette.selectedHighlight.withAlphaComponent(0.34)
        ring.lineWidth = 1.6
        node.addChild(ring)

        return node
    }

    private func makeTileHighlightNode(
        at center: CGPoint,
        radius: CGFloat,
        isSelected: Bool
    ) -> SKNode {
        let node = SKNode()
        node.position = center

        let halo = SKShapeNode(path: hexagonPath(radius: radius * 1.02))
        halo.fillColor = isSelected
            ? GameBoardPalette.selectedHighlightFill
            : GameBoardPalette.legalHighlightFill.withAlphaComponent(0.18)
        halo.strokeColor = isSelected ? GameBoardPalette.selectedHighlight : GameBoardPalette.legalHighlight
        halo.lineWidth = isSelected ? 4 : 1.6
        node.addChild(halo)

        if isSelected {
            let ring = SKShapeNode(path: hexagonPath(radius: radius * 1.11))
            ring.fillColor = .clear
            ring.strokeColor = GameBoardPalette.selectedHighlight.withAlphaComponent(0.36)
            ring.lineWidth = 2
            node.addChild(ring)
        }

        return node
    }

    private func makeEdgeHighlightNode(
        edgeID: EdgeID,
        layout: GameBoardLayout,
        topology: BoardGraphV1,
        isSelected: Bool
    ) -> SKNode {
        let node = SKNode()
        let edgeLine = layout.edgeLine(for: edgeID, topology: topology)
        let sceneStart = scenePoint(for: edgeLine.start)
        let sceneEnd = scenePoint(for: edgeLine.end)

        let path = CGMutablePath()
        path.move(to: sceneStart)
        path.addLine(to: sceneEnd)

        let halo = SKShapeNode(path: path)
        halo.strokeColor = isSelected ? GameBoardPalette.selectedHighlight : GameBoardPalette.legalHighlight
        halo.lineWidth = layout.roadWidth + (isSelected ? 5.5 : 2.5)
        halo.lineCap = .round
        halo.alpha = isSelected ? 0.92 : 0.40
        node.addChild(halo)

        if isSelected {
            let glow = SKShapeNode(path: path)
            glow.strokeColor = GameBoardPalette.selectedHighlight.withAlphaComponent(0.26)
            glow.lineWidth = layout.roadWidth + 12
            glow.lineCap = .round
            node.addChild(glow)
        }

        return node
    }

    private func makeNodeHighlightNode(
        at center: CGPoint,
        radius: CGFloat,
        isSelected: Bool,
        denseCluster: Bool
    ) -> SKNode {
        let node = SKNode()
        node.position = center

        let circleRadius: CGFloat
        if denseCluster {
            circleRadius = isSelected ? max(radius * 0.70, 8) : max(radius * 0.38, 4.5)
        } else {
            circleRadius = radius + (isSelected ? 5 : 3)
        }

        let ring = SKShapeNode(circleOfRadius: circleRadius)
        ring.fillColor = isSelected
            ? GameBoardPalette.selectedHighlightFill
            : GameBoardPalette.legalHighlightFill.withAlphaComponent(denseCluster ? 0.06 : 0.26)
        ring.strokeColor = isSelected
            ? GameBoardPalette.selectedHighlight
            : GameBoardPalette.legalHighlight.withAlphaComponent(denseCluster ? 0.60 : 1.0)
        ring.lineWidth = denseCluster ? (isSelected ? 3 : 1.1) : (isSelected ? 4 : 2.2)
        node.addChild(ring)

        if isSelected {
            let outerRing = SKShapeNode(circleOfRadius: circleRadius + 6)
            outerRing.fillColor = .clear
            outerRing.strokeColor = GameBoardPalette.selectedHighlight.withAlphaComponent(0.32)
            outerRing.lineWidth = 1.8
            node.addChild(outerRing)
        }

        return node
    }

    private func hexagonPath(radius: CGFloat) -> CGPath {
        let path = CGMutablePath()
        let adjustedRadius = max(radius, 8)

        for index in 0..<6 {
            let angle = (CGFloat.pi / 3 * CGFloat(index)) - (.pi / 6)
            let point = CGPoint(
                x: cos(angle) * adjustedRadius,
                y: sin(angle) * adjustedRadius
            )

            if index == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }

        path.closeSubpath()
        return path
    }

    private func trianglePath(radius: CGFloat) -> CGPath {
        let path = CGMutablePath()
        let adjustedRadius = max(radius, 4)

        path.move(to: CGPoint(x: 0, y: adjustedRadius))
        path.addLine(to: CGPoint(x: -adjustedRadius * 0.78, y: -adjustedRadius * 0.58))
        path.addLine(to: CGPoint(x: adjustedRadius * 0.78, y: -adjustedRadius * 0.58))
        path.closeSubpath()

        return path
    }

    private func scenePoint(for point: CGPoint) -> CGPoint {
        CGPoint(x: point.x, y: boardWorldSize.height - point.y)
    }

    private func structurePath(kind: GameBoardStructureRenderModel.Kind, radius: CGFloat) -> CGPath {
        let adjustedRadius = max(radius, 8)
        let path = CGMutablePath()

        switch kind {
        case .settlement:
            path.move(to: CGPoint(x: -adjustedRadius * 0.70, y: -adjustedRadius * 0.58))
            path.addLine(to: CGPoint(x: -adjustedRadius * 0.70, y: adjustedRadius * 0.10))
            path.addLine(to: CGPoint(x: 0, y: adjustedRadius * 0.78))
            path.addLine(to: CGPoint(x: adjustedRadius * 0.70, y: adjustedRadius * 0.10))
            path.addLine(to: CGPoint(x: adjustedRadius * 0.70, y: -adjustedRadius * 0.58))
            path.closeSubpath()
        case .city:
            path.move(to: CGPoint(x: -adjustedRadius * 0.90, y: -adjustedRadius * 0.62))
            path.addLine(to: CGPoint(x: -adjustedRadius * 0.90, y: adjustedRadius * 0.20))
            path.addLine(to: CGPoint(x: -adjustedRadius * 0.42, y: adjustedRadius * 0.20))
            path.addLine(to: CGPoint(x: -adjustedRadius * 0.42, y: adjustedRadius * 0.66))
            path.addLine(to: CGPoint(x: adjustedRadius * 0.10, y: adjustedRadius * 0.66))
            path.addLine(to: CGPoint(x: adjustedRadius * 0.10, y: adjustedRadius * 0.30))
            path.addLine(to: CGPoint(x: adjustedRadius * 0.90, y: adjustedRadius * 0.30))
            path.addLine(to: CGPoint(x: adjustedRadius * 0.90, y: -adjustedRadius * 0.62))
            path.closeSubpath()
        }

        return path
    }

    private func structureCapPath(kind: GameBoardStructureRenderModel.Kind, radius: CGFloat) -> CGPath {
        let adjustedRadius = max(radius, 8)
        let path = CGMutablePath()

        switch kind {
        case .settlement:
            path.move(to: CGPoint(x: -adjustedRadius * 0.52, y: adjustedRadius * 0.04))
            path.addLine(to: CGPoint(x: 0, y: adjustedRadius * 0.54))
            path.addLine(to: CGPoint(x: adjustedRadius * 0.52, y: adjustedRadius * 0.04))
            path.closeSubpath()
        case .city:
            path.addRect(
                CGRect(
                    x: -adjustedRadius * 0.72,
                    y: adjustedRadius * 0.08,
                    width: adjustedRadius * 0.20,
                    height: max(adjustedRadius * 0.10, 1.5)
                )
            )
            path.addRect(
                CGRect(
                    x: -adjustedRadius * 0.24,
                    y: adjustedRadius * 0.54,
                    width: adjustedRadius * 0.22,
                    height: max(adjustedRadius * 0.10, 1.5)
                )
            )
            path.addRect(
                CGRect(
                    x: adjustedRadius * 0.28,
                    y: adjustedRadius * 0.18,
                    width: adjustedRadius * 0.38,
                    height: max(adjustedRadius * 0.10, 1.5)
                )
            )
        }

        return path
    }

    private func configureSceneRoots() {
        camera = cameraNode
        baseContentNode.zPosition = 0
        overlayContentNode.zPosition = 90

        if contentRootNode.parent == nil {
            addChild(contentRootNode)
        }

        if baseContentNode.parent == nil {
            contentRootNode.addChild(baseContentNode)
        }

        if backdropContentNode.parent == nil {
            baseContentNode.addChild(backdropContentNode)
        }

        if tileContentNode.parent == nil {
            baseContentNode.addChild(tileContentNode)
        }

        if gridContentNode.parent == nil {
            baseContentNode.addChild(gridContentNode)
        }

        if portContentNode.parent == nil {
            baseContentNode.addChild(portContentNode)
        }

        if roadContentNode.parent == nil {
            baseContentNode.addChild(roadContentNode)
        }

        if structureContentNode.parent == nil {
            baseContentNode.addChild(structureContentNode)
        }

        if overlayContentNode.parent == nil {
            contentRootNode.addChild(overlayContentNode)
        }

        if cameraNode.parent == nil {
            addChild(cameraNode)
        }
    }

    private func applyCameraState() {
        let zoom = max(currentCameraState.zoom, 0.001)
        let center = CGPoint(x: boardWorldSize.width * 0.5, y: boardWorldSize.height * 0.5)

        cameraNode.position = CGPoint(
            x: center.x - (currentCameraState.offset.width / zoom),
            // Layout/tap coordinates are top-left based, so positive vertical
            // offset should move the visible board down with the user's drag.
            y: center.y + (currentCameraState.offset.height / zoom)
        )
        cameraNode.xScale = 1 / zoom
        cameraNode.yScale = 1 / zoom
    }

    private struct BackdropLayerKey: Equatable {
        let referenceSize: CGSize
    }

    private struct TileLayerKey: Equatable {
        let referenceSize: CGSize
        let tiles: [GameBoardTileRenderModel]
    }

    private struct GridLayerKey: Equatable {
        let referenceSize: CGSize
        let topology: BoardGraphV1
    }

    private struct PortLayerKey: Equatable {
        let referenceSize: CGSize
        let topology: BoardGraphV1
        let ports: [GameBoardPortRenderModel]
    }

    private struct RoadLayerKey: Equatable {
        let referenceSize: CGSize
        let topology: BoardGraphV1
        let roads: [GameBoardRoadRenderModel]
        let playerOrder: [String]
    }

    private struct StructureLayerKey: Equatable {
        let referenceSize: CGSize
        let structures: [GameBoardStructureRenderModel]
        let playerOrder: [String]
    }

    private struct OverlayLayerKey: Equatable {
        let referenceSize: CGSize
        let topology: BoardGraphV1
        let overlayModel: GameBoardOverlayModel
    }
}
