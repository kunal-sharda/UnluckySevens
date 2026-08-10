import ULS_CoreGame

enum GameTradeOverlayRoute: Equatable {
    case chooser
    case playerDraft(GameTradeDraft)
    case maritime
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

enum GameShellRoute: Equatable {
    case none
    case build
    case devCards
    case trade(GameTradeOverlayRoute)
    case endTurnConfirmation
    case gameInfo

    var selectedDockKind: GameActionDockItem.Kind? {
        switch self {
        case .build:
            return .build
        case .devCards:
            return .devCards
        case .trade:
            return .trade
        case .endTurnConfirmation:
            return .endTurn
        case .none, .gameInfo:
            return nil
        }
    }

    var tradeOverlayRoute: GameTradeOverlayRoute? {
        guard case let .trade(route) = self else {
            return nil
        }
        return route
    }
}
