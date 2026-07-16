import CoreGraphics
import SpriteKit
import UIKit
import ULS_CoreGame

private final class GameBoardTileArtBundleToken {}

enum GameBoardTileArt {
    private static let woodStampTexture = makeTexture(named: "stamp_wood")
    private static let brickStampTexture = makeTexture(named: "stamp_brick")
    private static let sheepStampTexture = makeTexture(named: "stamp_sheep")
    private static let wheatStampTexture = makeTexture(named: "stamp_wheat")
    private static let oreStampTexture = makeTexture(named: "stamp_ore")
    private static let desertStampTexture = makeTexture(named: "stamp_desert")
    private static let woodMiniStampTexture = makeTexture(named: "mini_stamp_wood")
    private static let brickMiniStampTexture = makeTexture(named: "mini_stamp_brick")
    private static let sheepMiniStampTexture = makeTexture(named: "mini_stamp_sheep")
    private static let wheatMiniStampTexture = makeTexture(named: "mini_stamp_wheat")
    private static let oreMiniStampTexture = makeTexture(named: "mini_stamp_ore")
    static let merchantShipTexture = makeTexture(named: "merchant_ship_colored")

    static func stampTexture(for resource: ResourceV1) -> SKTexture {
        switch resource {
        case .wood:
            woodStampTexture
        case .brick:
            brickStampTexture
        case .sheep:
            sheepStampTexture
        case .wheat:
            wheatStampTexture
        case .ore:
            oreStampTexture
        case .desert:
            desertStampTexture
        }
    }

    static func miniStampTexture(for resource: ResourceV1) -> SKTexture {
        switch resource {
        case .wood:
            woodMiniStampTexture
        case .brick:
            brickMiniStampTexture
        case .sheep:
            sheepMiniStampTexture
        case .wheat:
            wheatMiniStampTexture
        case .ore:
            oreMiniStampTexture
        case .desert:
            desertStampTexture
        }
    }

    static func stampSize(for resource: ResourceV1, hexRadius radius: CGFloat) -> CGSize {
        let textureSize = stampTexture(for: resource).size()
        let maxSourceDimension = max(textureSize.width, textureSize.height, 1)
        let maxRenderedDimension = radius * stampScale(for: resource)

        return CGSize(
            width: textureSize.width * maxRenderedDimension / maxSourceDimension,
            height: textureSize.height * maxRenderedDimension / maxSourceDimension
        )
    }

    static func fieldHexRadius(forTopologyRadius radius: CGFloat) -> CGFloat {
        radius
    }

    static func frameHexRadius(forTopologyRadius radius: CGFloat) -> CGFloat {
        radius
    }

    private static func stampScale(for resource: ResourceV1) -> CGFloat {
        switch resource {
        case .wood, .brick, .wheat:
            return 1.12
        case .sheep, .ore:
            return 1.04
        case .desert:
            return 1.00
        }
    }

    private static func makeTexture(named name: String) -> SKTexture {
        let bundle = Bundle(for: GameBoardTileArtBundleToken.self)
        let texture: SKTexture
        if let image = UIImage(named: name, in: bundle, compatibleWith: nil) {
            texture = SKTexture(image: image)
        } else {
            texture = SKTexture(imageNamed: name)
        }
        texture.filteringMode = .linear
        texture.usesMipmaps = true
        return texture
    }

}
