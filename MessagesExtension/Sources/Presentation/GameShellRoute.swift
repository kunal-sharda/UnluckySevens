import ULS_CoreGame

enum GameTradeOverlayRoute: Equatable {
    case chooser
    case playerDraft(GameTradeDraft)
    case maritimeDraft(GameMaritimeTradeDraft)
    case liveOffer
}

struct GameTradeDraft: Equatable {
    enum Kind: Equatable {
        case offer
        case counter(originalProposerID: String)
    }

    var kind: Kind
    var give: ResourceHandV1
    var receive: ResourceHandV1
    var recipients: [String]

    var isCounter: Bool {
        if case .counter = kind {
            return true
        }
        return false
    }
}

struct GameMaritimeTradeDraft: Equatable {
    var give: ResourceHandV1
    var receive: ResourceHandV1
}

enum GameShellRoute: Equatable {
    case none
    case utility(GameLowerShelf)
    case build
    case devCards
    case trade(GameTradeOverlayRoute)

    var selectedDockKind: GameActionDockItem.Kind? {
        switch self {
        case .build:
            return .build
        case .devCards:
            return .devCards
        case .trade:
            return .trade
        case .none, .utility:
            return nil
        }
    }

    var utilityShelf: GameLowerShelf? {
        guard case let .utility(shelf) = self else {
            return nil
        }
        return shelf
    }

    var tradeOverlayRoute: GameTradeOverlayRoute? {
        guard case let .trade(route) = self else {
            return nil
        }
        return route
    }
}
