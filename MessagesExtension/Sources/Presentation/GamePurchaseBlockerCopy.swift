import ULS_CoreGame

enum GamePurchaseBlockerCopy {
    static func message(_ blocker: CorePurchaseBlockerV1?, kind: CorePurchaseKindV1) -> String? {
        guard let blocker else { return nil }
        switch blocker {
        case .unknownViewer: return "Open your game to purchase"
        case .wrongPhase: return "Available during normal play"
        case .notYourTurn: return "Wait for your turn"
        case .rollFirst: return "Roll first"
        case .finishRequiredAction: return "Finish the current action first"
        case .emptyDeck: return "No Dev Cards left"
        case let .insufficientResources(missing):
            return "Need " + ResourceV1.allCases.compactMap { resource in
                missing.count(for: resource) > 0 ? "\(missing.count(for: resource)) \(resource.shortLabel)" : nil
            }.joined(separator: ", ")
        case .noPieces:
            switch kind {
            case .road: return "No roads left"
            case .settlement: return "No settlements left"
            case .city: return "No cities left"
            case .developmentCard: return "No Dev Cards left"
            }
        case .noLegalPlacement:
            return kind == .city ? "No settlement to upgrade" : "No legal placement"
        }
    }
}
