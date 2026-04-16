import ULS_CoreGame
import ULS_Transport

enum TradeInteractionResolver {
    static func draftTradeOfferIntent(
        state: CoreGameStateV1?,
        actingAs: String?,
        give: ResourceHandV1,
        receive: ResourceHandV1,
        targetPlayers: [String]
    ) -> ULS_Transport.TurnIntentV1? {
        guard
            let state,
            state.phase == .turn,
            state.turnState?.step == .afterRoll,
            let actingAs,
            actingAs == state.currentPlayer
        else {
            return nil
        }

        return ULS_Transport.TurnIntentV1(
            proposeTradeGive: transportHand(from: give),
            receive: transportHand(from: receive),
            targetPlayers: targetPlayers.sorted(),
            gameId: state.gameId,
            anchorRev: state.rev,
            anchorHash: state.stateHash,
            actor: actingAs
        )
    }

    static func draftMaritimeTradeIntent(
        state: CoreGameStateV1?,
        actingAs: String?,
        give: ResourceHandV1,
        receive: ResourceHandV1
    ) -> ULS_Transport.TurnIntentV1? {
        guard
            let state,
            state.phase == .turn,
            state.turnState?.step == .afterRoll,
            let actingAs,
            actingAs == state.currentPlayer
        else {
            return nil
        }

        return ULS_Transport.TurnIntentV1(
            maritimeTradeGive: transportHand(from: give),
            receive: transportHand(from: receive),
            gameId: state.gameId,
            anchorRev: state.rev,
            anchorHash: state.stateHash,
            actor: actingAs
        )
    }

    static func draftAcceptTradeIntent(
        state: CoreGameStateV1?,
        actingAs: String?
    ) -> ULS_Transport.TurnIntentV1? {
        guard
            let state,
            state.phase == .turn,
            state.turnState?.step == .afterRoll,
            let offer = state.activeTradeOffer,
            let actingAs,
            actingAs != state.currentPlayer,
            offer.recipients.contains(actingAs),
            !state.tradeResponses.contains(where: { $0.respondingPlayer == actingAs && $0.offerHash == offer.offerHash }),
            canAfford(hand: state.resourcesByPlayer[actingAs] ?? .zero, cost: offer.receive)
        else {
            return nil
        }

        return ULS_Transport.TurnIntentV1(
            acceptTradePlayer: actingAs,
            offerHash: offer.offerHash,
            gameId: state.gameId,
            anchorRev: state.rev,
            anchorHash: state.stateHash,
            actor: actingAs
        )
    }

    static func draftDeclineTradeIntent(
        state: CoreGameStateV1?,
        actingAs: String?
    ) -> ULS_Transport.TurnIntentV1? {
        guard
            let state,
            state.phase == .turn,
            state.turnState?.step == .afterRoll,
            let offer = state.activeTradeOffer,
            let actingAs,
            actingAs != state.currentPlayer,
            offer.recipients.contains(actingAs),
            !state.tradeResponses.contains(where: { $0.respondingPlayer == actingAs && $0.offerHash == offer.offerHash })
        else {
            return nil
        }

        return ULS_Transport.TurnIntentV1(
            declineTradePlayer: actingAs,
            offerHash: offer.offerHash,
            gameId: state.gameId,
            anchorRev: state.rev,
            anchorHash: state.stateHash,
            actor: actingAs
        )
    }

    static func draftCounterTradeIntent(
        state: CoreGameStateV1?,
        actingAs: String?,
        give: ResourceHandV1,
        receive: ResourceHandV1
    ) -> ULS_Transport.TurnIntentV1? {
        guard
            let state,
            state.phase == .turn,
            state.turnState?.step == .afterRoll,
            let offer = state.activeTradeOffer,
            let actingAs,
            actingAs != state.currentPlayer,
            offer.recipients.contains(actingAs),
            !state.tradeResponses.contains(where: { $0.respondingPlayer == actingAs && $0.offerHash == offer.offerHash })
        else {
            return nil
        }

        return ULS_Transport.TurnIntentV1(
            counterTradePlayer: actingAs,
            offerHash: offer.offerHash,
            counterGive: transportHand(from: give),
            receive: transportHand(from: receive),
            gameId: state.gameId,
            anchorRev: state.rev,
            anchorHash: state.stateHash,
            actor: actingAs
        )
    }

    private static func transportHand(from hand: ResourceHandV1) -> TransportResourceHandV1 {
        TransportResourceHandV1(
            wood: hand.wood,
            brick: hand.brick,
            sheep: hand.sheep,
            wheat: hand.wheat,
            ore: hand.ore
        )
    }

    private static func canAfford(hand: ResourceHandV1, cost: ResourceHandV1) -> Bool {
        hand.wood >= cost.wood
            && hand.brick >= cost.brick
            && hand.sheep >= cost.sheep
            && hand.wheat >= cost.wheat
            && hand.ore >= cost.ore
    }
}
