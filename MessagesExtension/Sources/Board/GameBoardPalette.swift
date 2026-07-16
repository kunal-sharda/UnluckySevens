import SpriteKit
import ULS_CoreGame

enum GameBoardOceanStyle: String, CaseIterable {
    case flat
    case shallowGlow
    case verticalDepth
    case edgeVignette

    static let defaultsKey = "uls.debug.boardOceanStyle"

    static var current: GameBoardOceanStyle {
#if DEBUG
        GameBoardOceanStyle(
            rawValue: UserDefaults.standard.string(forKey: defaultsKey) ?? ""
        ) ?? .flat
#else
        .flat
#endif
    }

    var shortLabel: String {
        switch self {
        case .flat: "Flat"
        case .shallowGlow: "Glow"
        case .verticalDepth: "Depth"
        case .edgeVignette: "Halo"
        }
    }

    var centerVector: vector_float4 {
        switch self {
        case .flat:
            vector_float4(0.060, 0.380, 0.420, 1.0)
        case .shallowGlow:
            vector_float4(0.092, 0.438, 0.472, 1.0)
        case .verticalDepth:
            vector_float4(0.083, 0.420, 0.454, 1.0)
        case .edgeVignette:
            vector_float4(0.110, 0.470, 0.500, 1.0)
        }
    }

    var edgeVector: vector_float4 {
        switch self {
        case .flat:
            centerVector
        case .shallowGlow:
            vector_float4(0.048, 0.342, 0.382, 1.0)
        case .verticalDepth:
            vector_float4(0.036, 0.310, 0.360, 1.0)
        case .edgeVignette:
            vector_float4(0.040, 0.314, 0.360, 1.0)
        }
    }

    var backgroundColor: SKColor {
        SKColor(
            red: CGFloat(edgeVector.x),
            green: CGFloat(edgeVector.y),
            blue: CGFloat(edgeVector.z),
            alpha: 1.0
        )
    }

    var centerColor: SKColor {
        SKColor(
            red: CGFloat(centerVector.x),
            green: CGFloat(centerVector.y),
            blue: CGFloat(centerVector.z),
            alpha: 1.0
        )
    }

    var edgeColor: SKColor {
        SKColor(
            red: CGFloat(edgeVector.x),
            green: CGFloat(edgeVector.y),
            blue: CGFloat(edgeVector.z),
            alpha: 1.0
        )
    }
}

enum GameBoardPalette {
    static let sceneBackground = GameBoardOceanStyle.current.backgroundColor
    static let sceneBackgroundEdge = SKColor(red: 0.06, green: 0.10, blue: 0.08, alpha: 0.24)
    static let boardRim = SKColor(red: 0.91, green: 0.84, blue: 0.68, alpha: 1.0)
    static let boardRimEdge = SKColor(red: 0.35, green: 0.28, blue: 0.19, alpha: 0.58)
    static let water = SKColor(red: 0.06, green: 0.38, blue: 0.42, alpha: 0.99)
    static let waterEdge = SKColor(red: 0.02, green: 0.17, blue: 0.20, alpha: 0.58)
    static let boardBase = SKColor(red: 0.04, green: 0.28, blue: 0.31, alpha: 0.24)
    static let boardBaseEdge = SKColor(red: 0.02, green: 0.15, blue: 0.17, alpha: 0.24)
    static let ink = SKColor(red: 0.19, green: 0.15, blue: 0.12, alpha: 0.94)
    static let outline = SKColor(red: 0.91, green: 0.81, blue: 0.62, alpha: 0.92)
    static let tileBorderDark = SKColor(red: 0.30, green: 0.20, blue: 0.11, alpha: 0.92)
    static let tileBorderWarm = SKColor(red: 0.88, green: 0.73, blue: 0.46, alpha: 1.0)
    static let tileBorderHairline = SKColor(red: 0.98, green: 0.91, blue: 0.70, alpha: 0.92)
    static let tokenFill = SKColor(red: 0.96, green: 0.89, blue: 0.72, alpha: 0.82)
    static let tokenStroke = SKColor(red: 0.42, green: 0.31, blue: 0.18, alpha: 0.46)
    static let robber = SKColor(red: 0.16, green: 0.13, blue: 0.12, alpha: 0.90)
    static let robberAccent = SKColor(red: 0.71, green: 0.60, blue: 0.47, alpha: 0.32)
    static let portFill = SKColor(red: 0.94, green: 0.86, blue: 0.67, alpha: 0.98)
    static let portStroke = SKColor(red: 0.36, green: 0.27, blue: 0.16, alpha: 0.54)
    static let roadShadow = SKColor.black.withAlphaComponent(0.22)
    static let structureFill = SKColor(red: 0.95, green: 0.92, blue: 0.84, alpha: 0.94)
    static let legalHighlight = SKColor(red: 0.96, green: 0.70, blue: 0.14, alpha: 0.88)
    static let legalHighlightFill = SKColor(red: 1.00, green: 0.77, blue: 0.05, alpha: 0.18)
    static let selectedHighlight = SKColor(red: 1.00, green: 0.94, blue: 0.52, alpha: 1.0)
    static let selectedHighlightFill = SKColor(red: 1.00, green: 0.84, blue: 0.16, alpha: 0.30)

    static func resourceFill(for resource: ResourceV1) -> SKColor {
        switch resource {
        case .wood:
            return SKColor(red: 0.25, green: 0.47, blue: 0.18, alpha: 0.98)
        case .brick:
            return SKColor(red: 0.74, green: 0.30, blue: 0.16, alpha: 0.98)
        case .sheep:
            return SKColor(red: 0.55, green: 0.68, blue: 0.31, alpha: 0.98)
        case .wheat:
            return SKColor(red: 0.86, green: 0.66, blue: 0.18, alpha: 0.98)
        case .ore:
            return SKColor(red: 0.40, green: 0.45, blue: 0.45, alpha: 0.98)
        case .desert:
            return SKColor(red: 0.71, green: 0.58, blue: 0.36, alpha: 0.98)
        }
    }

    static func resourceInset(for resource: ResourceV1) -> SKColor {
        mix(resourceFill(for: resource), with: .black, fraction: 0.26)
            .withAlphaComponent(0.90)
    }

    static func playerColor(owner: String, playerOrder: [String]) -> SKColor {
        let palette: [SKColor] = [
            SKColor(red: 0.72, green: 0.18, blue: 0.16, alpha: 1.0),
            SKColor(red: 0.18, green: 0.42, blue: 0.70, alpha: 1.0),
            SKColor(red: 0.91, green: 0.88, blue: 0.78, alpha: 1.0),
            SKColor(red: 0.78, green: 0.48, blue: 0.13, alpha: 1.0),
        ]

        if let index = playerOrder.firstIndex(of: owner) {
            return palette[index % palette.count]
        }

        let fallbackIndex = abs(owner.hashValue) % palette.count
        return palette[fallbackIndex]
    }

    static func playerStroke(owner: String, playerOrder: [String]) -> SKColor {
        let color = playerColor(owner: owner, playerOrder: playerOrder)
        return mix(color, with: .black, fraction: 0.38)
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
