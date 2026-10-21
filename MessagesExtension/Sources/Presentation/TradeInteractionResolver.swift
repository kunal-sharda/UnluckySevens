import ULS_CoreGame

enum TradeInteractionResolver {
    static func draftTradeOfferIntent(
        state: CoreGameStateV1?,
        actingAs: String?,
        give: ResourceHandV1,
        receive: ResourceHandV1,
        targetPlayers: [String]
    ) -> TurnActionDraft? {
        guard
            let state,
            state.phase == .turn,
            state.turnState?.step == .afterRoll,
            let actingAs,
            actingAs == state.currentPlayer
        else {
            return nil
        }

        return TurnActionDraft(
            intent: .proposeTrade(give: give, receive: receive, recipients: targetPlayers.sorted()),
            actor: actingAs,
            state: state
        )
    }

    static func draftMaritimeTradeIntent(
        state: CoreGameStateV1?,
        actingAs: String?,
        give: ResourceHandV1,
        receive: ResourceHandV1
    ) -> TurnActionDraft? {
        guard
            let state,
            state.phase == .turn,
            state.turnState?.step == .afterRoll,
            let actingAs,
            actingAs == state.currentPlayer
        else {
            return nil
        }

        return TurnActionDraft(
            intent: .maritimeTrade(give: give, receive: receive),
            actor: actingAs,
            state: state
        )
    }

    static func draftAcceptTradeIntent(
        state: CoreGameStateV1?,
        actingAs: String?
    ) -> TurnActionDraft? {
        guard
            let state,
            let offer = state.activeTradeOffer,
            let actingAs,
            TradeAcceptEligibilityResolver.resolve(state: state, actingAs: actingAs) == .eligible
        else {
            return nil
        }

        return TurnActionDraft(
            intent: .acceptTrade(acceptingPlayer: actingAs, offerHash: offer.offerHash),
            actor: actingAs,
            state: state
        )
    }

    static func draftDeclineTradeIntent(
        state: CoreGameStateV1?,
        actingAs: String?
    ) -> TurnActionDraft? {
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

        return TurnActionDraft(
            intent: .declineTrade(decliningPlayer: actingAs, offerHash: offer.offerHash),
            actor: actingAs,
            state: state
        )
    }

    static func draftCounterTradeIntent(
        state: CoreGameStateV1?,
        actingAs: String?,
        give: ResourceHandV1,
        receive: ResourceHandV1
    ) -> TurnActionDraft? {
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

        return TurnActionDraft(
            intent: .counterTrade(
                counteringPlayer: actingAs,
                offerHash: offer.offerHash,
                give: give,
                receive: receive
            ),
            actor: actingAs,
            state: state
        )
    }

}
