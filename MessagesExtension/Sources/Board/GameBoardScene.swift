import CoreGraphics
import SpriteKit

final class GameBoardScene: SKScene {
    override init(size: CGSize) {
        super.init(size: size)
        scaleMode = .resizeFill
        backgroundColor = .clear
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        scaleMode = .resizeFill
        backgroundColor = .clear
    }

    func update(renderModel: GameBoardRenderModel, size: CGSize) {
        self.size = size
        removeAllChildren()

        let layout = GameBoardLayout(size: size, geometry: renderModel.geometry)
        addChild(makeBoardBackdrop(size: size))

        for tile in renderModel.tiles {
            addChild(makeTileNode(tile: tile, layout: layout))
        }
    }

    private func makeBoardBackdrop(size: CGSize) -> SKShapeNode {
        let rect = CGRect(origin: .zero, size: size)
        let shape = SKShapeNode(rect: rect, cornerRadius: 22)
        shape.fillColor = SKColor(red: 0.77, green: 0.86, blue: 0.89, alpha: 0.28)
        shape.strokeColor = SKColor(red: 0.33, green: 0.24, blue: 0.16, alpha: 0.12)
        shape.lineWidth = 1
        shape.position = .zero
        shape.zPosition = 0
        return shape
    }

    private func makeTileNode(tile: GameBoardTileRenderModel, layout: GameBoardLayout) -> SKNode {
        let tileNode = SKNode()
        tileNode.position = layout.tileCenter(for: tile.tileID)
        tileNode.zPosition = 10

        let hex = SKShapeNode(path: hexagonPath(radius: layout.tileRadius))
        hex.fillColor = fillColor(for: tile)
        hex.strokeColor = SKColor(red: 0.30, green: 0.20, blue: 0.12, alpha: 0.18)
        hex.lineWidth = 1
        tileNode.addChild(hex)

        if let number = tile.number {
            let label = SKLabelNode(text: "\(number)")
            label.fontName = "Georgia-Bold"
            label.fontSize = max(layout.tileRadius * 0.42, 11)
            label.fontColor = SKColor(red: 0.23, green: 0.15, blue: 0.09, alpha: 0.88)
            label.verticalAlignmentMode = .center
            label.horizontalAlignmentMode = .center
            label.zPosition = 20
            tileNode.addChild(label)
        }

        if tile.hasRobber {
            let robber = SKShapeNode(circleOfRadius: max(layout.tileRadius * 0.18, 7))
            robber.fillColor = SKColor(red: 0.16, green: 0.13, blue: 0.12, alpha: 0.86)
            robber.strokeColor = .clear
            robber.position = CGPoint(x: 0, y: -layout.tileRadius * 0.34)
            robber.zPosition = 30
            tileNode.addChild(robber)
        }

        return tileNode
    }

    private func fillColor(for tile: GameBoardTileRenderModel) -> SKColor {
        switch tile.resource {
        case .wood:
            return SKColor(red: 0.41, green: 0.56, blue: 0.27, alpha: 0.92)
        case .brick:
            return SKColor(red: 0.67, green: 0.31, blue: 0.24, alpha: 0.92)
        case .sheep:
            return SKColor(red: 0.56, green: 0.72, blue: 0.39, alpha: 0.92)
        case .wheat:
            return SKColor(red: 0.86, green: 0.72, blue: 0.30, alpha: 0.94)
        case .ore:
            return SKColor(red: 0.47, green: 0.51, blue: 0.54, alpha: 0.92)
        case .desert:
            return SKColor(red: 0.80, green: 0.69, blue: 0.50, alpha: 0.92)
        }
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
}
