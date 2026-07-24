import CoreGraphics
import SpriteKit
import UIKit
import ULS_CoreGame

final class GameBoardScene: SKScene {
    static let backdropOverscan: CGFloat = 96

    static func numberTokenPipCount(for number: Int) -> Int {
        guard (2...12).contains(number), number != 7 else { return 0 }
        return 6 - abs(7 - number)
    }

    private static func numberTokenFont(ofSize size: CGFloat) -> UIFont {
        let systemFont = UIFont.systemFont(ofSize: size, weight: .bold)
        guard let serifDescriptor = systemFont.fontDescriptor.withDesign(.serif) else {
            return systemFont
        }
        return UIFont(descriptor: serifDescriptor, size: size)
    }

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

        let oceanStyle = GameBoardOceanStyle.current
        let backdropKey = BackdropLayerKey(referenceSize: referenceSize, oceanStyle: oceanStyle)
        if cachedBackdropKey != backdropKey {
            cachedBackdropKey = backdropKey
            backdropContentNode.removeAllChildren()
            backgroundColor = oceanStyle.backgroundColor
            backdropContentNode.addChild(makeBoardBackdrop(size: referenceSize, oceanStyle: oceanStyle))
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

    func updateOceanStyle(_ oceanStyle: GameBoardOceanStyle, referenceSize: CGSize) {
        let backdropKey = BackdropLayerKey(referenceSize: referenceSize, oceanStyle: oceanStyle)
        guard cachedBackdropKey != backdropKey else { return }

        cachedBackdropKey = backdropKey
        backgroundColor = oceanStyle.backgroundColor
        backdropContentNode.removeAllChildren()
        backdropContentNode.addChild(makeBoardBackdrop(size: referenceSize, oceanStyle: oceanStyle))
    }

    private func makeBoardBackdrop(size: CGSize, oceanStyle: GameBoardOceanStyle) -> SKNode {
        let root = SKNode()

        let outerRect = CGRect(origin: .zero, size: size)
            .insetBy(dx: -Self.backdropOverscan, dy: -Self.backdropOverscan)
        let water = SKShapeNode(rect: outerRect, cornerRadius: 22)
        water.name = "oceanBackdrop"
        water.fillColor = .white
        water.fillTexture = makeOceanTexture(size: outerRect.size, oceanStyle: oceanStyle)
        water.strokeColor = .clear
        water.lineWidth = 0
        water.zPosition = 0
        root.addChild(water)

        return root
    }

    private func makeOceanTexture(size: CGSize, oceanStyle: GameBoardOceanStyle) -> SKTexture {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let image = UIGraphicsImageRenderer(size: size, format: format).image { rendererContext in
            let context = rendererContext.cgContext
            let centerColor = oceanStyle.centerColor.cgColor
            let edgeColor = oceanStyle.edgeColor.cgColor

            switch oceanStyle {
            case .flat:
                context.setFillColor(centerColor)
                context.fill(CGRect(origin: .zero, size: size))
            case .shallowGlow:
                let gradient = CGGradient(
                    colorsSpace: CGColorSpaceCreateDeviceRGB(),
                    colors: [centerColor, centerColor, edgeColor] as CFArray,
                    locations: [0, 0.30, 1]
                )!
                context.drawRadialGradient(
                    gradient,
                    startCenter: CGPoint(x: size.width * 0.5, y: size.height * 0.5),
                    startRadius: 0,
                    endCenter: CGPoint(x: size.width * 0.5, y: size.height * 0.5),
                    endRadius: max(size.width, size.height) * 0.70,
                    options: [.drawsAfterEndLocation]
                )
            case .verticalDepth:
                let gradient = CGGradient(
                    colorsSpace: CGColorSpaceCreateDeviceRGB(),
                    colors: [centerColor, edgeColor] as CFArray,
                    locations: [0, 1]
                )!
                context.drawLinearGradient(
                    gradient,
                    start: CGPoint(x: size.width * 0.5, y: 0),
                    end: CGPoint(x: size.width * 0.5, y: size.height),
                    options: []
                )
            case .edgeVignette:
                let gradient = CGGradient(
                    colorsSpace: CGColorSpaceCreateDeviceRGB(),
                    colors: [edgeColor, centerColor, centerColor, edgeColor] as CFArray,
                    locations: [0, 0.34, 0.58, 1]
                )!
                context.drawRadialGradient(
                    gradient,
                    startCenter: CGPoint(x: size.width * 0.5, y: size.height * 0.5),
                    startRadius: 0,
                    endCenter: CGPoint(x: size.width * 0.5, y: size.height * 0.5),
                    endRadius: max(size.width, size.height) * 0.72,
                    options: [.drawsAfterEndLocation]
                )
            }
        }
        let texture = SKTexture(image: image)
        texture.filteringMode = .linear
        return texture
    }

    private func makeBoardGridNode(layout: GameBoardLayout, topology: BoardGraphV1) -> SKNode {
        let node = SKNode()
        node.name = "tileFrameNetwork"
        node.zPosition = 32

        let framePath = CGMutablePath()
        for edgeID in topology.edges.indices {
            let edgeLine = layout.edgeLine(for: edgeID, topology: topology)
            let sceneStart = scenePoint(for: edgeLine.start)
            let sceneEnd = scenePoint(for: edgeLine.end)

            framePath.move(to: sceneStart)
            framePath.addLine(to: sceneEnd)
        }

        let darkFrame = SKShapeNode(path: framePath)
        darkFrame.name = "tileFrameDark"
        darkFrame.strokeColor = GameBoardPalette.tileBorderDark
        darkFrame.fillColor = .clear
        darkFrame.lineWidth = max(layout.tileRadius * 0.12, 4.2)
        darkFrame.lineCap = .square
        darkFrame.lineJoin = .miter
        darkFrame.zPosition = 0
        node.addChild(darkFrame)

        let warmFrame = SKShapeNode(path: framePath)
        warmFrame.name = "tileFrameWarm"
        warmFrame.strokeColor = GameBoardPalette.tileBorderWarm
        warmFrame.fillColor = .clear
        warmFrame.lineWidth = max(layout.tileRadius * 0.066, 2.5)
        warmFrame.lineCap = .square
        warmFrame.lineJoin = .miter
        warmFrame.zPosition = 1
        node.addChild(warmFrame)

        let hairline = SKShapeNode(path: framePath)
        hairline.name = "tileFrameHairline"
        hairline.strokeColor = GameBoardPalette.tileBorderHairline
        hairline.fillColor = .clear
        hairline.lineWidth = max(layout.tileRadius * 0.018, 0.7)
        hairline.lineCap = .square
        hairline.lineJoin = .miter
        hairline.zPosition = 2
        node.addChild(hairline)

        return node
    }

    private func makeTileNode(tile: GameBoardTileRenderModel, layout: GameBoardLayout) -> SKNode {
        let tileNode = SKNode()
        tileNode.position = scenePoint(for: layout.tileCenter(for: tile.tileID))
        tileNode.zPosition = 20
        let fieldRadius = GameBoardTileArt.fieldHexRadius(forTopologyRadius: layout.tileRadius)

        let field = SKShapeNode(path: hexagonPath(radius: fieldRadius))
        field.name = "tileField"
        field.fillColor = GameBoardPalette.resourceFill(for: tile.resource)
        field.strokeColor = .clear
        field.zPosition = 0
        tileNode.addChild(field)

        let terrainInset = SKShapeNode(path: hexagonPath(radius: fieldRadius * 0.925))
        terrainInset.name = "tileTerrainInset"
        terrainInset.fillColor = .clear
        terrainInset.strokeColor = GameBoardPalette.resourceInset(for: tile.resource)
        terrainInset.lineWidth = max(layout.tileRadius * 0.048, 1.4)
        terrainInset.lineJoin = .miter
        terrainInset.zPosition = 2
        tileNode.addChild(terrainInset)

        let stampCrop = SKCropNode()
        stampCrop.name = "tileStampCrop"
        stampCrop.zPosition = 10

        let mask = SKShapeNode(path: hexagonPath(radius: fieldRadius * 0.98))
        mask.fillColor = .white
        mask.strokeColor = .clear
        stampCrop.maskNode = mask

        let stamp = SKSpriteNode(texture: GameBoardTileArt.stampTexture(for: tile.resource))
        stamp.name = "tileStamp"
        stamp.size = GameBoardTileArt.stampSize(for: tile.resource, hexRadius: layout.tileRadius)
        stamp.zPosition = 0
        stampCrop.addChild(stamp)
        tileNode.addChild(stampCrop)

        if let number = tile.number {
            tileNode.addChild(makeTokenNode(number: number, radius: layout.tileRadius))
        }

        if tile.hasRobber {
            tileNode.addChild(makeRobberNode(radius: layout.tileRadius))
        }

        return tileNode
    }

    private func makeTokenNode(number: Int, radius: CGFloat) -> SKNode {
        let node = SKNode()
        node.name = "numberToken.\(number)"
        node.zPosition = 30

        let tokenRadius = max(radius * 0.24, 10)
        let token = SKShapeNode(circleOfRadius: tokenRadius)
        token.fillColor = GameBoardPalette.tokenFill
        token.strokeColor = GameBoardPalette.tokenStroke
        token.lineWidth = 1.2
        node.addChild(token)

        let isHighProbability = number == 6 || number == 8
        let markColor = isHighProbability
            ? SKColor(red: 0.65, green: 0.18, blue: 0.14, alpha: 0.92)
            : GameBoardPalette.ink
        let fontSize = max(radius * 0.31, 11)
        let label = SKLabelNode()
        label.name = "numberToken.label"
        label.attributedText = NSAttributedString(
            string: "\(number)",
            attributes: [
                .font: Self.numberTokenFont(ofSize: fontSize),
                .foregroundColor: markColor,
            ]
        )
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .left
        label.position = CGPoint(x: 0, y: tokenRadius * 0.13)
        label.position.x = -label.frame.midX
        label.zPosition = 1
        node.addChild(label)

        let pipCount = Self.numberTokenPipCount(for: number)
        let pipRadius = max(tokenRadius * 0.045, 0.7)
        let pipStep = pipRadius * 2.7
        let pipStartX = -CGFloat(pipCount - 1) * pipStep / 2
        for index in 0..<pipCount {
            let pip = SKShapeNode(circleOfRadius: pipRadius)
            pip.name = "numberToken.pip"
            pip.fillColor = markColor
            pip.strokeColor = .clear
            pip.position = CGPoint(
                x: pipStartX + CGFloat(index) * pipStep,
                y: -tokenRadius * 0.52
            )
            pip.zPosition = 1
            node.addChild(pip)
        }

        return node
    }

    private func makeRobberNode(radius: CGFloat) -> SKNode {
        let node = SKNode()
        node.name = "robber"
        node.position = CGPoint(x: 0, y: -radius * 0.28)
        node.zPosition = 40

        let artwork = SKNode()
        artwork.name = "robber.artwork"
        artwork.yScale = -1
        let paths = RobberPieceGeometry.paths(center: .zero, height: max(radius * 0.82, 30))

        for (name, path) in [("base", paths.base), ("body", paths.body), ("head", paths.head)] {
            let shape = SKShapeNode(path: path)
            shape.name = "robber.\(name)"
            shape.fillColor = RobberPieceGeometry.pieceColor
            shape.strokeColor = .clear
            artwork.addChild(shape)
        }

        let mask = SKShapeNode(path: paths.mask)
        mask.name = "robber.mask"
        mask.fillColor = RobberPieceGeometry.maskColor
        mask.strokeColor = .clear
        artwork.addChild(mask)

        let eyes = SKShapeNode(path: paths.eyes)
        eyes.name = "robber.eyes"
        eyes.fillColor = RobberPieceGeometry.pieceColor
        eyes.strokeColor = .clear
        artwork.addChild(eyes)

        let seven = SKShapeNode(path: paths.seven)
        seven.name = "robber.seven"
        seven.fillColor = .clear
        seven.strokeColor = RobberPieceGeometry.sevenColor
        seven.lineWidth = paths.sevenLineWidth
        seven.lineCap = .square
        seven.lineJoin = .miter
        artwork.addChild(seven)

        node.addChild(artwork)

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
        node.addChild(
            makePortTether(
                from: sceneAnchor,
                to: sceneStart,
                width: max(layout.tileRadius * 0.03, 0.85)
            )
        )
        node.addChild(
            makePortTether(
                from: sceneAnchor,
                to: sceneEnd,
                width: max(layout.tileRadius * 0.03, 0.85)
            )
        )
        let markerSize = layout.portMarkerSize(for: port.kind)
        let marker: SKNode
        switch port.kind {
        case .threeToOne:
            marker = makeGenericPortShip(size: markerSize)
        case let .twoToOne(resource):
            marker = makeResourcePortMarker(
                resource: resource,
                side: markerSize.width
            )
        }
        marker.position = sceneAnchor
        marker.zPosition = 1
        node.addChild(marker)

        return node
    }

    private func makeGenericPortShip(size: CGSize) -> SKNode {
        let node = SKNode()
        node.name = "port.generic.ship"

        let texture = GameBoardTileArt.merchantShipTexture
        let textureSize = texture.size()
        let scale = min(
            size.width / max(textureSize.width, 1),
            size.height / max(textureSize.height, 1)
        )
        let ship = SKSpriteNode(texture: texture)
        ship.name = "port.generic.ship.art"
        ship.size = CGSize(width: textureSize.width * scale, height: textureSize.height * scale)
        node.addChild(ship)

        return node
    }

    private func makeResourcePortMarker(resource: ResourceV1, side: CGFloat) -> SKNode {
        let node = SKNode()
        node.name = "port.resource.\(resource.rawValue)"

        let marker = SKShapeNode(
            rect: CGRect(x: -side * 0.5, y: -side * 0.5, width: side, height: side),
            cornerRadius: side * 0.28
        )
        marker.fillColor = GameBoardPalette.resourceFill(for: resource)
        marker.strokeColor = GameBoardPalette.resourceInset(for: resource)
        marker.lineWidth = 1.1
        node.addChild(marker)

        let texture = GameBoardTileArt.miniStampTexture(for: resource)
        let stamp = SKSpriteNode(texture: texture)
        stamp.size = CGSize(width: side * 0.70, height: side * 0.70)
        stamp.zPosition = 1
        node.addChild(stamp)

        return node
    }

    private func makePortTether(
        from start: CGPoint,
        to end: CGPoint,
        width: CGFloat,
        alpha: CGFloat = 0.42
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
        shadow.lineWidth = layout.roadWidth + 2
        shadow.lineCap = .round
        shadow.position = CGPoint(x: 0, y: -0.75)
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
        highlight.lineWidth = max(layout.roadWidth * 0.30, 1.5)
        highlight.lineCap = .round
        node.addChild(highlight)

        let outline = SKShapeNode(path: roadPath)
        outline.strokeColor = stroke
        outline.lineWidth = max(layout.roadWidth + 1.2, 1)
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
        fill.lineWidth = 2.2
        node.addChild(fill)

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

    private func scenePoint(for point: CGPoint) -> CGPoint {
        CGPoint(x: point.x, y: boardWorldSize.height - point.y)
    }

    private func structurePath(kind: GameBoardStructureRenderModel.Kind, radius: CGFloat) -> CGPath {
        GamePieceGeometry.structurePath(
            kind: kind == .settlement ? .settlement : .city,
            radius: radius
        )
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
        let oceanStyle: GameBoardOceanStyle
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
