enum GameLowerShelf: String, Equatable {
    case hand
    case bank
    case players
    case build
    case devCards
    case forcedFlow

    var actionKind: GameActionDockItem.Kind? {
        switch self {
        case .build:
            return .build
        case .devCards:
            return .devCards
        case .hand, .bank, .players, .forcedFlow:
            return nil
        }
    }

    var title: String {
        switch self {
        case .hand:
            return "Hand"
        case .bank:
            return "Bank"
        case .players:
            return "Players"
        case .build:
            return "Build"
        case .devCards:
            return "Play Dev"
        case .forcedFlow:
            return "Flow"
        }
    }

    var systemImage: String {
        switch self {
        case .hand:
            return "shippingbox.fill"
        case .bank:
            return "banknote.fill"
        case .players:
            return "person.2.fill"
        case .build:
            return "hammer.fill"
        case .devCards:
            return "sparkles.rectangle.stack.fill"
        case .forcedFlow:
            return "arrow.triangle.2.circlepath"
        }
    }
}
