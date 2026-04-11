import ULS_CoreGame
import ULS_Transport

enum TradeInteractionResolver {
    static func draftSuggestedTradeOfferIntent(
        state: CoreGameStateV1?,
        actingAs: String?
    ) -> ULS_Transport.TurnIntentV1? {
        guard
            let state,
            state.phase == .turn,
            state.turnState?.step == .afterRoll,
            state.activeTradeOffer == nil,
            let actingAs,
            actingAs == state.currentPlayer,
            let proposal = state.defaultTradeProposal(for: actingAs)
        else {
            return nil
        }

        return ULS_Transport.TurnIntentV1(
            proposeTradeGive: transportHand(from: proposal.give),
            receive: transportHand(from: proposal.receive),
            gameId: state.gameId,
            anchorRev: state.rev,
            anchorHash: state.stateHash,
            actor: actingAs
        )
    }

    static func draftSuggestedMaritimeTradeIntent(
        state: CoreGameStateV1?,
        actingAs: String?
    ) -> ULS_Transport.TurnIntentV1? {
        guard
            let state,
            state.phase == .turn,
            state.turnState?.step == .afterRoll,
            let actingAs,
            actingAs == state.currentPlayer,
            let maritime = state.defaultMaritimeTrade(for: actingAs)
        else {
            return nil
        }

        return ULS_Transport.TurnIntentV1(
            maritimeTradeGive: transportHand(from: maritime.give),
            receive: transportHand(from: maritime.receive),
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
            !state.pendingTradeAccepts.contains(where: { $0.acceptingPlayer == actingAs }),
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

    static func draftExecuteTradeIntent(
        state: CoreGameStateV1?,
        actingAs: String?,
        acceptingPlayer: String
    ) -> ULS_Transport.TurnIntentV1? {
        guard
            let state,
            state.phase == .turn,
            state.turnState?.step == .afterRoll,
            let offer = state.activeTradeOffer,
            let actingAs,
            actingAs == state.currentPlayer,
            state.pendingTradeAccepts.contains(where: { $0.acceptingPlayer == acceptingPlayer && $0.offerHash == offer.offerHash })
        else {
            return nil
        }

        return ULS_Transport.TurnIntentV1(
            executeTradePlayer: acceptingPlayer,
            offerHash: offer.offerHash,
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
