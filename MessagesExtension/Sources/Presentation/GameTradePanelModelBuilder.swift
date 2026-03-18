import ULS_CoreGame
import ULS_Transport

enum GameTradePanelModelBuilder {
    static func build(
        state: CoreGameStateV1?,
        actingAs: String?,
        selectedTurnIntent: ULS_Transport.TurnIntentV1?
    ) -> GameTradePanelModel? {
        guard
            let state,
            state.phase == .turn,
            state.turnState?.step == .afterRoll
        else {
            return nil
        }

        if let offer = state.activeTradeOffer {
            return buildActiveOfferPanel(
                state: state,
                offer: offer,
                actingAs: actingAs,
                selectedTurnIntent: selectedTurnIntent
            )
        }

        return buildIdleTradePanel(state: state, actingAs: actingAs)
    }

    private static func buildIdleTradePanel(
        state: CoreGameStateV1,
        actingAs: String?
    ) -> GameTradePanelModel {
        guard let actingAs, actingAs == state.currentPlayer else {
            return GameTradePanelModel(
                message: "Waiting for \(shortIdentifier(state.currentPlayer)) to publish a trade.",
                activeOffer: nil,
                actions: [],
                acceptedPlayers: [],
                executeOptions: []
            )
        }

        var actions: [GameTradeAction] = []

        if let proposal = state.defaultTradeProposal(for: actingAs) {
            actions.append(
                GameTradeAction(
                    kind: .publishSuggestedOffer,
                    title: "Publish Player Trade",
                    detail: "Uses the current default offer from core queries.",
                    giveLabel: "You give",
                    give: handChips(from: proposal.give),
                    receiveLabel: "You want",
                    receive: handChips(from: proposal.receive)
                )
            )
        }

        if let maritime = state.defaultMaritimeTrade(for: actingAs) {
            actions.append(
                GameTradeAction(
                    kind: .publishSuggestedMaritime,
                    title: "Publish Maritime Trade",
                    detail: "Use the best current \(maritime.ratio):1 quote from owned ports or the bank.",
                    giveLabel: "You give",
                    give: handChips(from: maritime.give),
                    receiveLabel: "You get",
                    receive: handChips(from: maritime.receive)
                )
            )
        }

        let message: String
        if actions.isEmpty {
            message = "No legal player or maritime trade is available from the current state."
        } else {
            message = "Pick a compact trade action. Full custom composition can come later if the default path proves too narrow."
        }

        return GameTradePanelModel(
            message: message,
            activeOffer: nil,
            actions: actions,
            acceptedPlayers: [],
            executeOptions: []
        )
    }

    private static func buildActiveOfferPanel(
        state: CoreGameStateV1,
        offer: TradeOfferV1,
        actingAs: String?,
        selectedTurnIntent: ULS_Transport.TurnIntentV1?
    ) -> GameTradePanelModel {
        let proposerDisplay = shortIdentifier(offer.proposer)
        let isCurrentPlayer = actingAs == state.currentPlayer
        let activeOffer = GameTradeOfferSummary(
            proposerDisplay: proposerDisplay,
            giveLabel: isCurrentPlayer ? "You give" : "\(proposerDisplay) gives",
            give: handChips(from: offer.give),
            receiveLabel: isCurrentPlayer ? "You want" : "\(proposerDisplay) wants",
            receive: handChips(from: offer.receive)
        )

        let acceptedPlayers = state.pendingTradeAccepts
            .map(\.acceptingPlayer)
            .sorted()
            .map(shortIdentifier)

        var actions: [GameTradeAction] = []
        var executeOptions: [GameTradeExecuteOption] = []
        var message = "Trade is waiting on responses."

        if let actingAs, actingAs != state.currentPlayer {
            let alreadyAccepted = state.pendingTradeAccepts.contains { $0.acceptingPlayer == actingAs }
            if alreadyAccepted {
                message = "You already accepted this offer. Waiting on \(shortIdentifier(state.currentPlayer)) to act."
            } else {
                actions.append(
                    GameTradeAction(
                        kind: .sendAcceptOffer,
                        title: "Send Accept",
                        detail: "Respond to this offer without leaving the product flow.",
                        giveLabel: "\(proposerDisplay) gives",
                        give: handChips(from: offer.give),
                        receiveLabel: "\(proposerDisplay) wants",
                        receive: handChips(from: offer.receive)
                    )
                )
                message = "Review the offer and send an accept if you want the proposer to choose you."
            }
        }

        if let actingAs, actingAs == state.currentPlayer {
            if let selectedTurnIntent,
               selectedTurnIntent.kind == .acceptTrade,
               selectedTurnIntent.gameId == state.gameId,
               selectedTurnIntent.anchorRev == state.rev,
               selectedTurnIntent.anchorHash == state.stateHash,
               selectedTurnIntent.tradeOfferHash == offer.offerHash,
               let tradeAcceptPlayer = selectedTurnIntent.tradeAcceptPlayer {
                actions.append(
                    GameTradeAction(
                        kind: .applySelectedAccept,
                        title: "Apply Selected Accept",
                        detail: "Apply the selected accept bubble from \(shortIdentifier(tradeAcceptPlayer)) into canonical state.",
                        giveLabel: "You give",
                        give: handChips(from: offer.give),
                        receiveLabel: "You get",
                        receive: handChips(from: offer.receive)
                    )
                )
                message = "Apply the selected accept bubble, then execute the trade from the resulting state."
            } else if !state.pendingTradeAccepts.isEmpty {
                executeOptions = state.pendingTradeAccepts
                    .sorted { $0.acceptingPlayer < $1.acceptingPlayer }
                    .map {
                        GameTradeExecuteOption(
                            playerID: $0.acceptingPlayer,
                            displayName: shortIdentifier($0.acceptingPlayer)
                        )
                    }
                message = "Choose one accepted response to execute."
            } else {
                message = "Waiting for another player to accept this offer."
            }
        }

        return GameTradePanelModel(
            message: message,
            activeOffer: activeOffer,
            actions: actions,
            acceptedPlayers: acceptedPlayers,
            executeOptions: executeOptions
        )
    }

    private static func handChips(from hand: ResourceHandV1) -> [GameHandChip] {
        [
            GameHandChip(resource: .wood, count: hand.wood),
            GameHandChip(resource: .brick, count: hand.brick),
            GameHandChip(resource: .sheep, count: hand.sheep),
            GameHandChip(resource: .wheat, count: hand.wheat),
            GameHandChip(resource: .ore, count: hand.ore),
        ]
        .filter { $0.count > 0 }
    }

    private static func shortIdentifier(_ value: String) -> String {
        String(value.prefix(8))
    }
}
