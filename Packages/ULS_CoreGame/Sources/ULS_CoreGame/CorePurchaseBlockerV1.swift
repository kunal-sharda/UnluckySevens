/// Read-only inspection of a viewer's own purchase options. This never applies an action.
public enum CorePurchaseKindV1: Equatable {
    case road, settlement, city, developmentCard
}

public enum CorePurchaseBlockerV1: Equatable {
    case unknownViewer
    case wrongPhase
    case notYourTurn
    case rollFirst
    case finishRequiredAction
    case emptyDeck
    case insufficientResources(ResourceHandV1)
    case noPieces
    case noLegalPlacement
}

public extension CoreGameStateV1 {
    func purchaseBlocker(for kind: CorePurchaseKindV1, viewer: String?) -> CorePurchaseBlockerV1? {
        guard let viewer, roster.contains(viewer) else { return .unknownViewer }
        guard phase == .turn else { return .wrongPhase }
        guard currentPlayer == viewer else { return .notYourTurn }
        guard turnState?.step == .afterRoll else {
            return turnState?.step == .needsRoll ? .rollFirst : .finishRequiredAction
        }
        // Dev purchase checks the deck before affordability, as its reducer does.
        if kind == .developmentCard, devDeck.isEmpty { return .emptyDeck }
        let cost: ResourceHandV1
        switch kind {
        case .road: cost = CoreBuildCostsV1.road
        case .settlement: cost = CoreBuildCostsV1.settlement
        case .city: cost = CoreBuildCostsV1.city
        case .developmentCard: cost = CoreBuildCostsV1.developmentCard
        }
        guard let hand = visibleResourceHands(for: viewer).first(where: { $0.player == viewer })?.revealedHand else {
            return .unknownViewer
        }
        let missing = ResourceHandV1(
            wood: max(0, cost.wood - hand.wood), brick: max(0, cost.brick - hand.brick),
            sheep: max(0, cost.sheep - hand.sheep), wheat: max(0, cost.wheat - hand.wheat),
            ore: max(0, cost.ore - hand.ore)
        )
        // Construction queries check affordability before piece stock and geometry.
        if missing.totalCount > 0 { return .insufficientResources(missing) }
        switch kind {
        case .road:
            if roadsByEdge.values.filter({ $0 == viewer }).count >= 15 { return .noPieces }
            return legalBuildRoadEdges(for: viewer).isEmpty ? .noLegalPlacement : nil
        case .settlement:
            if settlementsByNode.values.filter({ $0 == viewer }).count >= 5 { return .noPieces }
            return legalBuildSettlementNodes(for: viewer).isEmpty ? .noLegalPlacement : nil
        case .city:
            if citiesByNode.values.filter({ $0 == viewer }).count >= 4 { return .noPieces }
            return legalBuildCityNodes(for: viewer).isEmpty ? .noLegalPlacement : nil
        case .developmentCard:
            return nil
        }
    }
}
