import Foundation

// Trade transition validation remains independent from reducer trade execution.
func validateTradeTransition(from: CoreGameStateV1, to: CoreGameStateV1) throws {
    if to.phase != .turn {
        guard to.activeTradeOffer == nil, to.tradeResponses.isEmpty else {
            throw CoreGameError.tradeStateInvalid
        }
        return
    }

    guard from.phase == .turn else {
        guard to.activeTradeOffer == nil, to.tradeResponses.isEmpty else {
            throw CoreGameError.tradeStateInvalid
        }
        return
    }

    if from.currentPlayer != to.currentPlayer {
        guard to.activeTradeOffer == nil, to.tradeResponses.isEmpty else {
            throw CoreGameError.tradeStateInvalid
        }
        return
    }

    if from.activeTradeOffer == to.activeTradeOffer, from.tradeResponses == to.tradeResponses {
        return
    }

    guard from.turnState?.step == .afterRoll, to.turnState?.step == .afterRoll else {
        throw CoreGameError.tradeStateInvalid
    }

    if from.activeTradeOffer == nil {
        guard let offer = to.activeTradeOffer else {
            throw CoreGameError.tradeStateInvalid
        }
        guard to.tradeResponses.isEmpty else {
            throw CoreGameError.tradeStateInvalid
        }
        try validateTradeOfferForValidation(offer, from: from, to: to)
        return
    }

    guard let fromOffer = from.activeTradeOffer else {
        throw CoreGameError.tradeStateInvalid
    }

    if let toOffer = to.activeTradeOffer {
        if toOffer != fromOffer {
            guard to.tradeResponses.isEmpty else {
                throw CoreGameError.tradeStateInvalid
            }
            guard to.resourcesByPlayer == from.resourcesByPlayer, to.bankResources == from.bankResources else {
                throw CoreGameError.tradeStateInvalid
            }
            try validateTradeOfferForValidation(toOffer, from: from, to: to)
            return
        }

        let addedResponse = try addedTradeResponseForValidation(from: from, to: to, offer: fromOffer)

        guard let addedResponse else {
            throw CoreGameError.tradeStateInvalid
        }
        try validateTradeResponseForValidation(addedResponse, from: from, offer: fromOffer, to: to)
        guard addedResponse.kind != .accept else {
            throw CoreGameError.tradeStateInvalid
        }
        guard to.resourcesByPlayer == from.resourcesByPlayer, to.bankResources == from.bankResources else {
            throw CoreGameError.tradeStateInvalid
        }
        return
    }

    let addedResponse = try addedTradeResponseForValidation(from: from, to: to, offer: fromOffer)

    if let addedResponse {
        try validateTradeResponseForValidation(addedResponse, from: from, offer: fromOffer, to: to)

        switch addedResponse.kind {
        case .accept:
            guard expectedEconomyAfterTradeExecutionIfAny(from: from, to: to).resourcesByPlayer == to.resourcesByPlayer,
                  expectedEconomyAfterTradeExecutionIfAny(from: from, to: to).bankResources == to.bankResources
            else {
                throw CoreGameError.tradeStateInvalid
            }
        case .decline:
            guard to.resourcesByPlayer == from.resourcesByPlayer, to.bankResources == from.bankResources else {
                throw CoreGameError.tradeStateInvalid
            }
            guard to.tradeResponses.count == fromOffer.recipients.count else {
                throw CoreGameError.tradeStateInvalid
            }
            guard to.tradeResponses.allSatisfy({ $0.kind == .decline }) else {
                throw CoreGameError.tradeStateInvalid
            }
        case .counter:
            throw CoreGameError.tradeStateInvalid
        }
        return
    }

    let acceptedPlayers = Set(from.tradeResponses.filter { $0.offerHash == fromOffer.offerHash && $0.kind == .accept }.map(\.respondingPlayer))
    guard !acceptedPlayers.isEmpty else {
        throw CoreGameError.tradeStateInvalid
    }
    let expectedEconomy = expectedEconomyAfterTradeExecutionIfAny(from: from, to: to)
    guard expectedEconomy.resourcesByPlayer == to.resourcesByPlayer, expectedEconomy.bankResources == to.bankResources else {
        throw CoreGameError.tradeStateInvalid
    }
}

private func validateTradeOfferForValidation(
    _ offer: TradeOfferV1,
    from: CoreGameStateV1,
    to: CoreGameStateV1
) throws {
    guard offer.proposer == from.currentPlayer else {
        throw CoreGameError.tradeStateInvalid
    }
    guard
        isValidTradeHandForValidation(offer.give),
        isValidTradeHandForValidation(offer.receive),
        offer.give.totalCount > 0,
        offer.receive.totalCount > 0,
        offer.give != offer.receive
    else {
        throw CoreGameError.tradeStateInvalid
    }
    guard canAffordForValidation(hand: from.resourcesByPlayer[from.currentPlayer] ?? .zero, cost: offer.give) else {
        throw CoreGameError.tradeStateInvalid
    }
    let normalizedRecipients = Array(Set(offer.recipients)).sorted()
    guard
        !normalizedRecipients.isEmpty,
        normalizedRecipients == offer.recipients,
        normalizedRecipients.allSatisfy({ $0 != from.currentPlayer && from.roster.contains($0) })
    else {
        throw CoreGameError.tradeStateInvalid
    }
    let expectedHash = deterministicTradeOfferHash(
        gameId: from.gameId,
        proposer: from.currentPlayer,
        give: offer.give,
        receive: offer.receive,
        recipients: offer.recipients,
        anchorRev: from.rev,
        anchorHash: from.stateHash
    )
    guard offer.offerHash == expectedHash else {
        throw CoreGameError.tradeStateInvalid
    }
    guard offer.createdRev == to.rev else {
        throw CoreGameError.tradeStateInvalid
    }
}

private func addedTradeResponseForValidation(
    from: CoreGameStateV1,
    to: CoreGameStateV1,
    offer: TradeOfferV1
) throws -> TradeResponseV1? {
    for priorResponse in from.tradeResponses {
        guard to.tradeResponses.contains(priorResponse) else {
            throw CoreGameError.tradeStateInvalid
        }
    }

    let priorPlayers = Set(from.tradeResponses.map(\.respondingPlayer))
    let newResponses = to.tradeResponses.filter { !priorPlayers.contains($0.respondingPlayer) }
    guard newResponses.count <= 1 else {
        throw CoreGameError.tradeStateInvalid
    }
    if let addedResponse = newResponses.first {
        guard addedResponse.offerHash == offer.offerHash else {
            throw CoreGameError.tradeStateInvalid
        }
        return addedResponse
    }
    return nil
}

private func validateTradeResponseForValidation(
    _ response: TradeResponseV1,
    from: CoreGameStateV1,
    offer: TradeOfferV1,
    to: CoreGameStateV1
) throws {
    guard response.offerHash == offer.offerHash else {
        throw CoreGameError.tradeStateInvalid
    }
    guard response.respondedAtRev == to.rev else {
        throw CoreGameError.tradeStateInvalid
    }
    guard response.respondingPlayer != from.currentPlayer, from.roster.contains(response.respondingPlayer) else {
        throw CoreGameError.tradeStateInvalid
    }
    guard offer.recipients.contains(response.respondingPlayer) else {
        throw CoreGameError.tradeStateInvalid
    }

    let responsePlayers = to.tradeResponses.map(\.respondingPlayer)
    guard Set(responsePlayers).count == responsePlayers.count else {
        throw CoreGameError.tradeStateInvalid
    }

    switch response.kind {
    case .accept, .decline:
        guard response.counterGive == nil, response.counterReceive == nil else {
            throw CoreGameError.tradeStateInvalid
        }
    case .counter:
        guard
            let give = response.counterGive,
            let receive = response.counterReceive,
            isValidTradeHandForValidation(give),
            isValidTradeHandForValidation(receive),
            give.totalCount > 0,
            receive.totalCount > 0,
            give != receive,
            canAffordForValidation(hand: from.resourcesByPlayer[response.respondingPlayer] ?? .zero, cost: give)
        else {
            throw CoreGameError.tradeStateInvalid
        }
    }
}
