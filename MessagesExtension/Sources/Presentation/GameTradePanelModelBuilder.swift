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

        let maritimeOptions = availableMaritimeOptions(state: state, actingAs: actingAs)

        guard let offer = state.activeTradeOffer else {
            return buildIdlePanel(state: state, actingAs: actingAs, maritimeOptions: maritimeOptions)
        }

        return buildActiveOfferPanel(
            state: state,
            offer: offer,
            actingAs: actingAs,
            selectedTurnIntent: selectedTurnIntent,
            maritimeOptions: maritimeOptions
        )
    }

    private static func buildIdlePanel(
        state: CoreGameStateV1,
        actingAs: String?,
        maritimeOptions: [GameTradeMaritimeOption]
    ) -> GameTradePanelModel {
        guard let actingAs else {
            return GameTradePanelModel(
                roleTitle: "Trade Desk",
                message: "Trade actions need your joined local Messages identity before they can be authored from this device.",
                activeOffer: nil,
                participantStatuses: [],
                responderActions: nil,
                selectedResponse: nil,
                maritimeOptions: [],
                pendingBannerText: nil,
                canReplaceOffer: false
            )
        }

        guard actingAs == state.currentPlayer else {
            return GameTradePanelModel(
                roleTitle: "Waiting For Offer",
                message: "Only \(playerName(state.currentPlayer, in: state)) can open a new trade on this turn.",
                activeOffer: nil,
                participantStatuses: [],
                responderActions: nil,
                selectedResponse: nil,
                maritimeOptions: [],
                pendingBannerText: nil,
                canReplaceOffer: false
            )
        }

        let message: String
        if maritimeOptions.isEmpty {
            message = "Start a player trade from the chooser, or take a maritime trade later if your hand or ports unlock one."
        } else {
            message = "Choose a player trade or pick one of the legal maritime / bank quick trades."
        }

        return GameTradePanelModel(
            roleTitle: "Trade Desk",
            message: message,
            activeOffer: nil,
            participantStatuses: [],
            responderActions: nil,
            selectedResponse: nil,
            maritimeOptions: maritimeOptions,
            pendingBannerText: nil,
            canReplaceOffer: false
        )
    }

    private static func buildActiveOfferPanel(
        state: CoreGameStateV1,
        offer: TradeOfferV1,
        actingAs: String?,
        selectedTurnIntent: ULS_Transport.TurnIntentV1?,
        maritimeOptions: [GameTradeMaritimeOption]
    ) -> GameTradePanelModel {
        let proposerDisplay = playerName(offer.proposer, in: state)
        let recipientNames = offer.recipients.map { playerName($0, in: state) }
        let isCurrentPlayer = actingAs == state.currentPlayer
        let isTargetedResponder = actingAs.map { offer.recipients.contains($0) } ?? false
        let responseByPlayer = Dictionary(
            uniqueKeysWithValues: state.tradeResponses
                .filter { $0.offerHash == offer.offerHash }
                .map { ($0.respondingPlayer, $0) }
        )

        let participantStatuses = state.roster
            .filter { $0 != state.currentPlayer }
            .sorted()
            .map { playerID in
                let response = responseByPlayer[playerID]
                let isTargeted = offer.recipients.contains(playerID)
                let stateValue: GameTradeParticipantResponseState
                let detailText: String
                switch response?.kind {
                case .accept:
                    stateValue = .accepted
                    detailText = "Accepted"
                case .decline:
                    stateValue = .declined
                    detailText = "Declined"
                case .counter:
                    stateValue = .countered
                    detailText = "Countered"
                case nil:
                    stateValue = isTargeted ? .waiting : .watching
                    detailText = isTargeted ? "Waiting" : "Watching"
                }
                return GameTradeParticipantStatus(
                    playerID: playerID,
                    displayName: playerName(playerID, in: state),
                    state: stateValue,
                    detailText: detailText,
                    isTargeted: isTargeted,
                    counterGive: handChips(from: response?.counterGive ?? .zero),
                    counterReceive: handChips(from: response?.counterReceive ?? .zero)
                )
            }

        let selectedResponse = selectedTradeResponse(
            selectedTurnIntent: selectedTurnIntent,
            state: state,
            offer: offer
        )

        let responderActions: GameTradeResponderActions?
        if
            let actingAs,
            actingAs != state.currentPlayer,
            offer.recipients.contains(actingAs),
            responseByPlayer[actingAs] == nil
        {
            responderActions = GameTradeResponderActions(
                canAccept: canAfford(hand: state.resourcesByPlayer[actingAs] ?? .zero, cost: offer.receive),
                canDecline: true,
                canCounter: true
            )
        } else {
            responderActions = nil
        }

        let roleTitle: String
        let message: String
        if isCurrentPlayer {
            roleTitle = "Your Offer"
            if let selectedResponse {
                message = "Apply the selected \(selectedResponse.kind.rawValue) from \(selectedResponse.displayName)."
            } else if participantStatuses.contains(where: { $0.state == .countered }) {
                message = "Counters are visible below. Replace the live offer if you want to answer one."
            } else {
                message = "Trade is waiting on targeted player responses."
            }
        } else if isTargetedResponder {
            roleTitle = "Incoming Offer"
            if let response = responseByPlayer[actingAs ?? ""] {
                switch response.kind {
                case .accept:
                    message = "You already accepted this offer."
                case .decline:
                    message = "You declined this offer."
                case .counter:
                    message = "You sent a counteroffer back to \(proposerDisplay)."
                }
            } else if responderActions?.canAccept == false {
                message = "You can decline or counter this offer, but you cannot accept it with your current hidden hand."
            } else {
                message = "Accept, decline, or counter this offer."
            }
        } else {
            roleTitle = "Table Offer"
            message = "This trade is visible to the table, but it was not sent to you."
        }

        return GameTradePanelModel(
            roleTitle: roleTitle,
            message: message,
            activeOffer: GameTradeOfferSummary(
                proposerPlayerID: offer.proposer,
                proposerDisplay: proposerDisplay,
                giveLabel: isCurrentPlayer ? "You give" : "\(proposerDisplay) gives",
                give: handChips(from: offer.give),
                receiveLabel: isCurrentPlayer ? "You want" : "\(proposerDisplay) wants",
                receive: handChips(from: offer.receive),
                recipientPlayerIDs: offer.recipients,
                recipientsLabel: recipientNames.isEmpty ? "No recipients" : "To " + recipientNames.joined(separator: ", ")
            ),
            participantStatuses: participantStatuses,
            responderActions: responderActions,
            selectedResponse: selectedResponse,
            maritimeOptions: maritimeOptions,
            pendingBannerText: pendingBannerText(for: offer, proposerDisplay: proposerDisplay, recipients: recipientNames),
            canReplaceOffer: isCurrentPlayer
        )
    }

    private static func selectedTradeResponse(
        selectedTurnIntent: ULS_Transport.TurnIntentV1?,
        state: CoreGameStateV1,
        offer: TradeOfferV1
    ) -> GameTradeSelectedResponseSummary? {
        guard let selectedTurnIntent,
              selectedTurnIntent.gameId == state.gameId,
              selectedTurnIntent.anchorRev == state.rev,
              selectedTurnIntent.anchorHash == state.stateHash,
              selectedTurnIntent.tradeOfferHash == offer.offerHash,
              let playerID = selectedTurnIntent.tradeAcceptPlayer
        else {
            return nil
        }

        let kind: GameTradeResponseIntentKind
        switch selectedTurnIntent.kind {
        case .acceptTrade:
            kind = .accept
        case .declineTrade:
            kind = .decline
        case .counterTrade:
            kind = .counter
        default:
            return nil
        }

        return GameTradeSelectedResponseSummary(
            playerID: playerID,
            displayName: playerName(playerID, in: state),
            kind: kind
        )
    }

    private static func availableMaritimeOptions(
        state: CoreGameStateV1,
        actingAs: String?
    ) -> [GameTradeMaritimeOption] {
        guard let actingAs, actingAs == state.currentPlayer else {
            return []
        }
        return state.maritimeTradeQuotes(for: actingAs).map {
            GameTradeMaritimeOption(
                give: handChips(from: $0.give),
                receive: handChips(from: $0.receive),
                ratio: $0.ratio
            )
        }
    }

    private static func pendingBannerText(
        for offer: TradeOfferV1,
        proposerDisplay: String,
        recipients: [String]
    ) -> String {
        let give = compactHandDescription(offer.give)
        let receive = compactHandDescription(offer.receive)
        let recipientLabel: String
        if recipients.count == 1, let recipient = recipients.first {
            recipientLabel = recipient
        } else {
            recipientLabel = "\(recipients.count) players"
        }
        return "\(proposerDisplay): \(give) for \(receive) to \(recipientLabel)"
    }

    private static func compactHandDescription(_ hand: ResourceHandV1) -> String {
        handChips(from: hand)
            .map { "\($0.count) \($0.shortLabel.lowercased())" }
            .joined(separator: ", ")
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
