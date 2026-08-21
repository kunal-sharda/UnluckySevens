import ULS_CoreGame

enum GameResourceHandDraftTransform {
    private static let tradeableResources: [ResourceV1] = [.wood, .brick, .sheep, .wheat, .ore]

    static func countMap(for hand: ResourceHandV1) -> [ResourceV1: Int] {
        [
            .wood: hand.wood,
            .brick: hand.brick,
            .sheep: hand.sheep,
            .wheat: hand.wheat,
            .ore: hand.ore,
        ]
        .filter { $0.value > 0 }
    }

    static func resourceCount(_ resource: ResourceV1, in chips: [GameHandChip]) -> Int {
        chips.first(where: { $0.resource == resource })?.count ?? 0
    }

    static func resourceCount(_ resource: ResourceV1, in hand: ResourceHandV1) -> Int {
        switch resource {
        case .wood:
            hand.wood
        case .brick:
            hand.brick
        case .sheep:
            hand.sheep
        case .wheat:
            hand.wheat
        case .ore:
            hand.ore
        case .desert:
            0
        }
    }

    static func updating(
        resource: ResourceV1,
        in hand: ResourceHandV1,
        delta: Int
    ) -> ResourceHandV1 {
        ResourceHandV1(
            wood: resource == .wood ? max(hand.wood + delta, 0) : hand.wood,
            brick: resource == .brick ? max(hand.brick + delta, 0) : hand.brick,
            sheep: resource == .sheep ? max(hand.sheep + delta, 0) : hand.sheep,
            wheat: resource == .wheat ? max(hand.wheat + delta, 0) : hand.wheat,
            ore: resource == .ore ? max(hand.ore + delta, 0) : hand.ore
        )
    }

    static func resourceHand(from chips: [GameHandChip]) -> ResourceHandV1 {
        ResourceHandV1(
            wood: resourceCount(.wood, in: chips),
            brick: resourceCount(.brick, in: chips),
            sheep: resourceCount(.sheep, in: chips),
            wheat: resourceCount(.wheat, in: chips),
            ore: resourceCount(.ore, in: chips)
        )
    }

    static func sanitizingDiscardDraft(
        _ draft: ResourceHandV1,
        requiredCount: Int,
        availableHand: [GameHandChip]
    ) -> ResourceHandV1 {
        var sanitized = ResourceHandV1.zero
        for resource in tradeableResources {
            let selected = resourceCount(resource, in: draft)
            let available = resourceCount(resource, in: availableHand)
            if selected > 0, available > 0 {
                sanitized = sanitized.adding(min(selected, available), for: resource)
            }
        }

        return sanitized.totalCount > requiredCount ? .zero : sanitized
    }

    static func togglingRecipient(
        _ playerID: String,
        in draft: GameTradeDraft
    ) -> GameTradeDraft {
        guard !draft.isCounter else {
            return draft
        }

        var nextDraft = draft
        if let existingIndex = nextDraft.recipients.firstIndex(of: playerID) {
            nextDraft.recipients.remove(at: existingIndex)
        } else {
            nextDraft.recipients.append(playerID)
            nextDraft.recipients.sort()
        }
        return nextDraft
    }
}
