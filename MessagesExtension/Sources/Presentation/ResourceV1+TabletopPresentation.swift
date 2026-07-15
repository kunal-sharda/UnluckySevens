import SwiftUI
import ULS_CoreGame

extension ResourceV1 {
    var tabletopStampAssetName: String {
        switch self {
        case .wood:
            return "stamp_wood"
        case .brick:
            return "stamp_brick"
        case .sheep:
            return "stamp_sheep"
        case .wheat:
            return "stamp_wheat"
        case .ore:
            return "stamp_ore"
        case .desert:
            return "stamp_desert"
        }
    }

    var tabletopIconSize: CGSize {
        switch self {
        case .wood, .wheat:
            return CGSize(width: 20, height: 22)
        case .brick:
            return CGSize(width: 22, height: 21)
        case .sheep:
            return CGSize(width: 23, height: 21)
        case .ore:
            return CGSize(width: 22, height: 21)
        case .desert:
            return CGSize(width: 22, height: 22)
        }
    }

    var tabletopCardFill: Color {
        switch self {
        case .wood:
            return GameTheme.wood
        case .brick:
            return GameTheme.brick
        case .sheep:
            return GameTheme.sheep
        case .wheat:
            return GameTheme.wheat
        case .ore:
            return GameTheme.ore
        case .desert:
            return Color(red: 0.68, green: 0.55, blue: 0.34)
        }
    }

    var tabletopInk: Color {
        GameTheme.ink.opacity(0.88)
    }

    var tabletopCountInk: Color {
        GameTheme.ink
    }
}
