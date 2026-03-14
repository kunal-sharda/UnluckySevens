import SpriteKit
import ULS_CoreGame

enum GameBoardPalette {
    static let water = SKColor(red: 0.30, green: 0.55, blue: 0.72, alpha: 0.96)
    static let waterEdge = SKColor(red: 0.13, green: 0.24, blue: 0.33, alpha: 0.28)
    static let boardBase = SKColor(red: 0.41, green: 0.27, blue: 0.16, alpha: 0.34)
    static let boardBaseEdge = SKColor(red: 0.22, green: 0.15, blue: 0.10, alpha: 0.20)
    static let ink = SKColor(red: 0.20, green: 0.13, blue: 0.08, alpha: 0.92)
    static let outline = SKColor(red: 0.27, green: 0.18, blue: 0.11, alpha: 0.34)
    static let tokenFill = SKColor(red: 0.97, green: 0.92, blue: 0.81, alpha: 0.98)
    static let tokenStroke = SKColor(red: 0.57, green: 0.41, blue: 0.23, alpha: 0.45)
    static let robber = SKColor(red: 0.16, green: 0.13, blue: 0.12, alpha: 0.90)
    static let robberAccent = SKColor(red: 0.71, green: 0.60, blue: 0.47, alpha: 0.32)
    static let portFill = SKColor(red: 0.95, green: 0.90, blue: 0.81, alpha: 0.94)
    static let portStroke = SKColor(red: 0.45, green: 0.33, blue: 0.21, alpha: 0.34)
    static let roadShadow = SKColor.black.withAlphaComponent(0.18)
    static let structureFill = SKColor(red: 0.98, green: 0.96, blue: 0.90, alpha: 0.94)
    static let legalHighlight = SKColor(red: 0.94, green: 0.80, blue: 0.33, alpha: 0.92)
    static let legalHighlightFill = SKColor(red: 0.98, green: 0.90, blue: 0.54, alpha: 0.18)
    static let selectedHighlight = SKColor(red: 0.99, green: 0.96, blue: 0.86, alpha: 0.98)
    static let selectedHighlightFill = SKColor(red: 0.99, green: 0.96, blue: 0.86, alpha: 0.26)

    static func resourceFill(for resource: ResourceV1) -> SKColor {
        switch resource {
        case .wood:
            return SKColor(red: 0.41, green: 0.56, blue: 0.27, alpha: 0.94)
        case .brick:
            return SKColor(red: 0.67, green: 0.31, blue: 0.24, alpha: 0.94)
        case .sheep:
            return SKColor(red: 0.56, green: 0.72, blue: 0.39, alpha: 0.94)
        case .wheat:
            return SKColor(red: 0.86, green: 0.72, blue: 0.30, alpha: 0.96)
        case .ore:
            return SKColor(red: 0.47, green: 0.51, blue: 0.54, alpha: 0.94)
        case .desert:
            return SKColor(red: 0.80, green: 0.69, blue: 0.50, alpha: 0.94)
        }
    }

    static func playerColor(owner: String, playerOrder: [String]) -> SKColor {
        let palette: [SKColor] = [
            SKColor(red: 0.79, green: 0.22, blue: 0.19, alpha: 1.0),
            SKColor(red: 0.18, green: 0.39, blue: 0.78, alpha: 1.0),
            SKColor(red: 0.96, green: 0.95, blue: 0.91, alpha: 1.0),
            SKColor(red: 0.90, green: 0.56, blue: 0.14, alpha: 1.0),
        ]

        if let index = playerOrder.firstIndex(of: owner) {
            return palette[index % palette.count]
        }

        let fallbackIndex = abs(owner.hashValue) % palette.count
        return palette[fallbackIndex]
    }

    static func playerStroke(owner: String, playerOrder: [String]) -> SKColor {
        let color = playerColor(owner: owner, playerOrder: playerOrder)
        return mix(color, with: .black, fraction: 0.28)
    }

    static func portLabel(for kind: PortKindV1) -> String {
        switch kind {
        case .threeToOne:
            return "3:1"
        case let .twoToOne(resource):
            switch resource {
            case .brick:
                return "Br"
            case .wood:
                return "Wd"
            case .sheep:
                return "Sh"
            case .wheat:
                return "Wh"
            case .ore:
                return "Or"
            case .desert:
                return "2:1"
            }
        }
    }

    private static func mix(_ lhs: SKColor, with rhs: SKColor, fraction: CGFloat) -> SKColor {
        var lhsRed: CGFloat = 0
        var lhsGreen: CGFloat = 0
        var lhsBlue: CGFloat = 0
        var lhsAlpha: CGFloat = 0
        lhs.getRed(&lhsRed, green: &lhsGreen, blue: &lhsBlue, alpha: &lhsAlpha)

        var rhsRed: CGFloat = 0
        var rhsGreen: CGFloat = 0
        var rhsBlue: CGFloat = 0
        var rhsAlpha: CGFloat = 0
        rhs.getRed(&rhsRed, green: &rhsGreen, blue: &rhsBlue, alpha: &rhsAlpha)

        let clamped = min(max(fraction, 0), 1)
        let inverse = 1 - clamped
        return SKColor(
            red: (lhsRed * inverse) + (rhsRed * clamped),
            green: (lhsGreen * inverse) + (rhsGreen * clamped),
            blue: (lhsBlue * inverse) + (rhsBlue * clamped),
            alpha: (lhsAlpha * inverse) + (rhsAlpha * clamped)
        )
    }
}
