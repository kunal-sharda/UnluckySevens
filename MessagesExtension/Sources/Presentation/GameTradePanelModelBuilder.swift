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
        guard let actingAs else {
            return GameTradePanelModel(
                roleTitle: "Trade Desk",
                message: "Trade actions need your joined local Messages identity before they can be authored from this device.",
                activeOffer: nil,
                actions: [],
                acceptedPlayers: [],
                executeOptions: [],
                participantStatuses: [],
                footnotes: []
            )
        }

        guard actingAs == state.currentPlayer else {
            return GameTradePanelModel(
                roleTitle: "Waiting For Offer",
                message: "Only \(playerName(state.currentPlayer, in: state)) can open a new trade on this turn.",
                activeOffer: nil,
                actions: [],
                acceptedPlayers: [],
                executeOptions: [],
                participantStatuses: [],
                footnotes: [
                    "When a player offer is live, accept and execution status will appear here."
                ]
            )
        }

        var actions: [GameTradeAction] = []
        var footnotes: [String] = []

        if let proposal = state.defaultTradeProposal(for: actingAs) {
            actions.append(
                GameTradeAction(
                    kind: .publishSuggestedOffer,
                    title: "Offer Player Trade",
                    detail: "Publish the current best player-to-player offer from core queries.",
                    systemImage: "person.2.fill",
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
                    title: "Take Maritime Trade",
                    detail: "Resolve immediately using the best current \(maritime.ratio):1 quote from your ports or the bank.",
                    systemImage: "ferry.fill",
                    giveLabel: "You give",
                    give: handChips(from: maritime.give),
                    receiveLabel: "You get",
                    receive: handChips(from: maritime.receive)
                )
            )
        }

        let message: String
        if actions.isEmpty {
            message = "No legal player or maritime trade is available from your current hand, ports, and bank state."
        } else {
            message = "Choose a player offer or an immediate maritime trade. Player offers stay open until you execute one accepted response or end the turn."
            footnotes.append(
                "There is no explicit cancel or decline bubble in the current protocol; unanswered player offers simply stay pending until you execute one accepted response or end the turn."
            )
        }

        return GameTradePanelModel(
            roleTitle: "Trade Desk",
            message: message,
            activeOffer: nil,
            actions: actions,
            acceptedPlayers: [],
            executeOptions: [],
            participantStatuses: [],
            footnotes: footnotes
        )
    }

    private static func buildActiveOfferPanel(
        state: CoreGameStateV1,
        offer: TradeOfferV1,
        actingAs: String?,
        selectedTurnIntent: ULS_Transport.TurnIntentV1?
    ) -> GameTradePanelModel {
        let proposerDisplay = playerName(offer.proposer, in: state)
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
            .map { playerName($0, in: state) }
        let selectedAcceptPlayer = selectedAcceptPlayer(from: selectedTurnIntent, state: state, offer: offer)

        var actions: [GameTradeAction] = []
        var executeOptions: [GameTradeExecuteOption] = []
        var participantStatuses: [GameTradeParticipantStatus] = []
        var footnotes: [String] = []
        let roleTitle = isCurrentPlayer ? "Your Offer" : "Incoming Offer"
        var message = "Trade is waiting on responses."

        if let actingAs, actingAs != state.currentPlayer {
            let alreadyAccepted = state.pendingTradeAccepts.contains { $0.acceptingPlayer == actingAs }
            let canAffordResponse = canAfford(hand: state.resourcesByPlayer[actingAs] ?? .zero, cost: offer.receive)
            if alreadyAccepted {
                message = "You already accepted this offer. Waiting for \(playerName(state.currentPlayer, in: state)) to execute it or end the turn."
                footnotes.append("With the current protocol, a sent accept cannot be withdrawn.")
            } else if !canAffordResponse {
                message = "You cannot accept this offer right now because you do not have the requested cards."
                footnotes.append("There is no explicit decline bubble yet; leaving the offer unanswered is the only decline path.")
            } else {
                actions.append(
                    GameTradeAction(
                        kind: .sendAcceptOffer,
                        title: "Accept Offer",
                        detail: "Send an accept bubble for this exact offer so the proposer can choose you.",
                        systemImage: "checkmark.circle.fill",
                        giveLabel: "\(proposerDisplay) gives",
                        give: handChips(from: offer.give),
                        receiveLabel: "\(proposerDisplay) wants",
                        receive: handChips(from: offer.receive)
                    )
                )
                message = "Review the offer and accept it if you want \(proposerDisplay) to choose you."
                footnotes.append("Decline is passive right now: leave the offer unanswered and wait for the proposer to execute or end the turn.")
            }
        }

        if let actingAs, actingAs == state.currentPlayer {
            if let tradeAcceptPlayer = selectedAcceptPlayer {
                actions.append(
                    GameTradeAction(
                        kind: .applySelectedAccept,
                        title: "Apply Selected Accept",
                        detail: "Apply the selected accept bubble from \(playerName(tradeAcceptPlayer, in: state)) into canonical state before execution.",
                        systemImage: "square.and.arrow.down.fill",
                        giveLabel: "You give",
                        give: handChips(from: offer.give),
                        receiveLabel: "You get",
                        receive: handChips(from: offer.receive)
                    )
                )
                message = "Apply the selected accept from \(playerName(tradeAcceptPlayer, in: state)), then choose Execute."
            } else if !state.pendingTradeAccepts.isEmpty {
                executeOptions = state.pendingTradeAccepts
                    .sorted { $0.acceptingPlayer < $1.acceptingPlayer }
                    .map {
                        GameTradeExecuteOption(
                            playerID: $0.acceptingPlayer,
                            displayName: playerName($0.acceptingPlayer, in: state)
                        )
                    }
                message = "Choose one accepted player to execute. The offer stays open to everyone else until you execute or end the turn."
            } else {
                message = "Waiting for another player to accept this offer."
            }
            footnotes.append("There is no explicit cancel bubble yet. To clear the offer without trading, end the turn.")
        }

        if isCurrentPlayer {
            participantStatuses = participantStatusesForProposer(
                state: state,
                offer: offer,
                selectedAcceptPlayer: selectedAcceptPlayer
            )
        } else {
            participantStatuses = participantStatusesForResponder(
                state: state,
                actingAs: actingAs,
                offer: offer
            )
        }

        return GameTradePanelModel(
            roleTitle: roleTitle,
            message: message,
            activeOffer: activeOffer,
            actions: actions,
            acceptedPlayers: acceptedPlayers,
            executeOptions: executeOptions,
            participantStatuses: participantStatuses,
            footnotes: footnotes
        )
    }

    private static func participantStatusesForProposer(
        state: CoreGameStateV1,
        offer: TradeOfferV1,
        selectedAcceptPlayer: String?
    ) -> [GameTradeParticipantStatus] {
        state.roster
            .filter { $0 != state.currentPlayer }
            .sorted()
            .map { player in
                let accepted = state.pendingTradeAccepts.contains {
                    $0.acceptingPlayer == player && $0.offerHash == offer.offerHash
                }
                let isSelected = player == selectedAcceptPlayer
                let detailText: String
                if isSelected {
                    detailText = "Selected bubble"
                } else if accepted {
                    detailText = "Accepted"
                } else {
                    detailText = "Waiting"
                }
                return GameTradeParticipantStatus(
                    playerID: player,
                    displayName: playerName(player, in: state),
                    detailText: detailText,
                    isPositive: accepted || isSelected,
                    isEmphasized: isSelected
                )
            }
    }

    private static func participantStatusesForResponder(
        state: CoreGameStateV1,
        actingAs: String?,
        offer: TradeOfferV1
    ) -> [GameTradeParticipantStatus] {
        state.pendingTradeAccepts
            .sorted { $0.acceptingPlayer < $1.acceptingPlayer }
            .map { accept in
                let isLocal = accept.acceptingPlayer == actingAs
                return GameTradeParticipantStatus(
                    playerID: accept.acceptingPlayer,
                    displayName: playerName(accept.acceptingPlayer, in: state),
                    detailText: isLocal ? "You accepted" : "Accepted",
                    isPositive: true,
                    isEmphasized: isLocal
                )
            }
    }

    private static func selectedAcceptPlayer(
        from selectedTurnIntent: ULS_Transport.TurnIntentV1?,
        state: CoreGameStateV1,
        offer: TradeOfferV1
    ) -> String? {
        guard let selectedTurnIntent,
              selectedTurnIntent.kind == .acceptTrade,
              selectedTurnIntent.gameId == state.gameId,
              selectedTurnIntent.anchorRev == state.rev,
              selectedTurnIntent.anchorHash == state.stateHash,
              selectedTurnIntent.tradeOfferHash == offer.offerHash
        else {
            return nil
        }

        return selectedTurnIntent.tradeAcceptPlayer
    }

    private static func canAfford(hand: ResourceHandV1, cost: ResourceHandV1) -> Bool {
        hand.wood >= cost.wood
            && hand.brick >= cost.brick
            && hand.sheep >= cost.sheep
            && hand.wheat >= cost.wheat
            && hand.ore >= cost.ore
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

    private static func playerName(_ playerID: String, in state: CoreGameStateV1) -> String {
        PlayerPseudonymResolver.displayName(for: playerID, gameID: state.gameId, roster: state.roster)
    }
}
