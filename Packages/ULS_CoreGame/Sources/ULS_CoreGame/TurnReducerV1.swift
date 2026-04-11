import Foundation

private let turnBuildTopology = StandardBoardTopologyV1.standard()

public enum TurnIntentV1: Codable, Equatable {
    case rollDice
    case submitDiscard(player: String, discarded: ResourceHandV1)
    case moveRobber(tileID: Int)
    case selectStealVictim(victimPlayer: String)
    case buildRoad(edgeID: Int)
    case buildSettlement(nodeID: Int)
    case buildCity(nodeID: Int)
    case proposeTrade(give: ResourceHandV1, receive: ResourceHandV1)
    case acceptTrade(acceptingPlayer: String, offerHash: String)
    case executeTrade(acceptingPlayer: String, offerHash: String)
    case maritimeTrade(give: ResourceHandV1, receive: ResourceHandV1)
    case buyDevCard
    case playKnight(tileID: Int, victimPlayer: String?)
    case playMonopoly(resource: ResourceV1)
    case playYearOfPlenty(first: ResourceV1, second: ResourceV1)
    case playRoadBuilding(firstEdgeID: Int, secondEdgeID: Int)
    case revealVictoryPoint
    case endTurn
}

public func apply(intent: TurnIntentV1, to state: CoreGameStateV1, actor: String) throws -> CoreGameStateV1 {
    if state.phase == .gameOver {
        throw CoreGameError.gameAlreadyOver
    }

    guard state.phase == .turn, let turnState = state.turnState else {
        throw CoreGameError.turnStateMissing
    }

    guard actor == state.currentPlayer else {
        throw CoreGameError.actorMismatch
    }

    func nextTurnState(
        from state: CoreGameStateV1,
        currentPlayer: String,
        diceRngState: UInt64?,
        robberRngState: UInt64?,
        board: BoardSetupV1?,
        turnState: TurnStateV1,
        resourcesByPlayer: [String: ResourceHandV1]? = nil,
        bankResources: ResourceHandV1? = nil,
        devDeck: [DevCardV1]? = nil,
        devCardsByPlayer: [String: DevCardInventoryV1]? = nil,
        newDevCardsByPlayer: [String: DevCardInventoryV1]? = nil,
        revealedVictoryPointsByPlayer: [String: Int]? = nil,
        devCardActionPlayedThisTurn: Bool? = nil,
        knightsPlayedByPlayer: [String: Int]? = nil,
        activeTradeOffer: TradeOfferV1?? = nil,
        pendingTradeAccepts: [TradeAcceptV1]?? = nil,
        settlementsByNode: [NodeID: String]? = nil,
        citiesByNode: [NodeID: String]? = nil,
        roadsByEdge: [EdgeID: String]? = nil
    ) -> CoreGameStateV1 {
        baseNextTurnState(
            from: state,
            currentPlayer: currentPlayer,
            diceRngState: diceRngState,
            robberRngState: robberRngState,
            board: board,
            turnState: turnState,
            resourcesByPlayer: resourcesByPlayer,
            bankResources: bankResources,
            devDeck: devDeck,
            devCardsByPlayer: devCardsByPlayer,
            newDevCardsByPlayer: newDevCardsByPlayer,
            revealedVictoryPointsByPlayer: revealedVictoryPointsByPlayer,
            devCardActionPlayedThisTurn: devCardActionPlayedThisTurn,
            knightsPlayedByPlayer: knightsPlayedByPlayer,
            activeTradeOffer: activeTradeOffer,
            pendingTradeAccepts: pendingTradeAccepts,
            settlementsByNode: settlementsByNode,
            citiesByNode: citiesByNode,
            roadsByEdge: roadsByEdge,
            intent: intent
        )
    }

    switch intent {
    case .rollDice:
        guard turnState.step == .needsRoll else {
            throw CoreGameError.turnStepMismatch
        }

        guard let diceRngState = state.diceRngState else {
            throw CoreGameError.missingDiceRngState
        }

        var rng = DeterministicRNG(seed: diceRngState)
        let roll = rng.rollDice()
        let rollTotal = roll.0 + roll.1

        if rollTotal == 7 {
            let requirements = requiredDiscards(for: state.resourcesByPlayer)
            let nextStep: TurnStepV1 = requirements.isEmpty ? .needsRobberMove : .pendingDiscards
            return nextTurnState(
                from: state,
                currentPlayer: state.currentPlayer,
                diceRngState: rng.state,
                robberRngState: state.robberRngState,
                board: state.board,
                turnState: TurnStateV1(
                    step: nextStep,
                    lastRoll: DiceRollV1(d1: roll.0, d2: roll.1),
                    discardRequirementsByPlayer: requirements,
                    submittedDiscardsByPlayer: [:],
                    eligibleStealVictims: []
                )
            )
        }

        let economy = applyProductionPayout(
            rollTotal: rollTotal,
            board: state.board,
            settlementsByNode: state.settlementsByNode,
            citiesByNode: state.citiesByNode,
            resourcesByPlayer: state.resourcesByPlayer,
            bankResources: state.bankResources
        )

        return nextTurnState(
            from: state,
            currentPlayer: state.currentPlayer,
            diceRngState: rng.state,
            robberRngState: state.robberRngState,
            board: state.board,
            turnState: TurnStateV1(step: .afterRoll, lastRoll: DiceRollV1(d1: roll.0, d2: roll.1)),
            resourcesByPlayer: economy.resourcesByPlayer,
            bankResources: economy.bankResources
        )

    case let .submitDiscard(player, discarded):
        guard turnState.step == .pendingDiscards else {
            throw CoreGameError.turnStepMismatch
        }

        guard let requiredCount = turnState.discardRequirementsByPlayer[player] else {
            throw CoreGameError.discardSubmissionNotRequired
        }

        guard turnState.submittedDiscardsByPlayer[player] == nil else {
            throw CoreGameError.discardAlreadySubmitted
        }

        guard discarded.totalCount == requiredCount else {
            throw CoreGameError.discardCountMismatch
        }

        guard
            discarded.wood >= 0,
            discarded.brick >= 0,
            discarded.sheep >= 0,
            discarded.wheat >= 0,
            discarded.ore >= 0
        else {
            throw CoreGameError.discardCountMismatch
        }

        let playerHand = state.resourcesByPlayer[player] ?? .zero
        guard
            discarded.wood <= playerHand.wood,
            discarded.brick <= playerHand.brick,
            discarded.sheep <= playerHand.sheep,
            discarded.wheat <= playerHand.wheat,
            discarded.ore <= playerHand.ore
        else {
            throw CoreGameError.insufficientResourcesForDiscard
        }

        var updatedResourcesByPlayer = state.resourcesByPlayer
        updatedResourcesByPlayer[player] = ResourceHandV1(
            wood: playerHand.wood - discarded.wood,
            brick: playerHand.brick - discarded.brick,
            sheep: playerHand.sheep - discarded.sheep,
            wheat: playerHand.wheat - discarded.wheat,
            ore: playerHand.ore - discarded.ore
        )

        let updatedBankResources = ResourceHandV1(
            wood: state.bankResources.wood + discarded.wood,
            brick: state.bankResources.brick + discarded.brick,
            sheep: state.bankResources.sheep + discarded.sheep,
            wheat: state.bankResources.wheat + discarded.wheat,
            ore: state.bankResources.ore + discarded.ore
        )

        var submitted = turnState.submittedDiscardsByPlayer
        submitted[player] = discarded
        let allSubmitted = turnState.discardRequirementsByPlayer.keys.allSatisfy { submitted[$0] != nil }

        return nextTurnState(
            from: state,
            currentPlayer: state.currentPlayer,
            diceRngState: state.diceRngState,
            robberRngState: state.robberRngState,
            board: state.board,
            turnState: TurnStateV1(
                step: allSubmitted ? .needsRobberMove : .pendingDiscards,
                lastRoll: turnState.lastRoll,
                discardRequirementsByPlayer: turnState.discardRequirementsByPlayer,
                submittedDiscardsByPlayer: submitted,
                eligibleStealVictims: []
            ),
            resourcesByPlayer: updatedResourcesByPlayer,
            bankResources: updatedBankResources
        )

    case let .moveRobber(tileID):
        guard turnState.step == .needsRobberMove else {
            throw CoreGameError.turnStepMismatch
        }
        guard let board = state.board else {
            throw CoreGameError.boardChanged
        }
        guard tileID >= 0, tileID < board.resourcesByTile.count else {
            throw CoreGameError.invalidRobberTile
        }
        guard tileID != board.robberTile else {
            throw CoreGameError.robberTileUnchanged
        }

        let movedBoard = BoardSetupV1(
            resourcesByTile: board.resourcesByTile,
            numbersByTile: board.numbersByTile,
            portsByIndex: board.portsByIndex,
            robberTile: tileID,
            generator: board.generator,
            boardHash: ""
        ).rehashed()

        let victims = eligibleRobberVictims(
            for: tileID,
            settlementsByNode: state.settlementsByNode,
            citiesByNode: state.citiesByNode,
            resourcesByPlayer: state.resourcesByPlayer,
            currentPlayer: state.currentPlayer
        )
        let nextStep: TurnStepV1 = victims.isEmpty ? .afterRoll : .needsRobberSteal

        return nextTurnState(
            from: state,
            currentPlayer: state.currentPlayer,
            diceRngState: state.diceRngState,
            robberRngState: state.robberRngState,
            board: movedBoard,
            turnState: TurnStateV1(
                step: nextStep,
                lastRoll: turnState.lastRoll,
                eligibleStealVictims: victims
            )
        )

    case let .selectStealVictim(victimPlayer):
        guard turnState.step == .needsRobberSteal else {
            throw CoreGameError.turnStepMismatch
        }
        guard turnState.eligibleStealVictims.contains(victimPlayer) else {
            throw CoreGameError.robberStealVictimNotEligible
        }
        guard let robberRngState = state.robberRngState else {
            throw CoreGameError.missingRobberRngState
        }

        let victimHand = state.resourcesByPlayer[victimPlayer] ?? .zero
        guard victimHand.totalCount > 0 else {
            throw CoreGameError.robberStealVictimNotEligible
        }

        var rng = DeterministicRNG(seed: robberRngState)
        let stolen = deterministicStolenResource(from: victimHand, rng: &rng)

        let stealerHand = state.resourcesByPlayer[state.currentPlayer] ?? .zero
        var updatedResourcesByPlayer = state.resourcesByPlayer
        updatedResourcesByPlayer[state.currentPlayer] = stealerHand.addingOne(for: stolen)
        updatedResourcesByPlayer[victimPlayer] = victimHand.subtracting(1, for: stolen)

        return nextTurnState(
            from: state,
            currentPlayer: state.currentPlayer,
            diceRngState: state.diceRngState,
            robberRngState: rng.state,
            board: state.board,
            turnState: TurnStateV1(step: .afterRoll, lastRoll: turnState.lastRoll),
            resourcesByPlayer: updatedResourcesByPlayer
        )

    case let .buildRoad(edgeID):
        guard turnState.step == .afterRoll else {
            throw CoreGameError.turnStepMismatch
        }
        guard edgeID >= 0, edgeID < turnBuildTopology.edges.count else {
            throw CoreGameError.invalidEdge
        }
        guard state.roadsByEdge[edgeID] == nil else {
            throw CoreGameError.edgeOccupied
        }

        let player = state.currentPlayer
        let playerRoadCount = state.roadsByEdge.values.filter { $0 == player }.count
        guard playerRoadCount < 15 else {
            throw CoreGameError.buildPieceLimitReached
        }
        guard isRoadConnected(edgeID: edgeID, for: player, in: state) else {
            throw CoreGameError.roadConnectionRequired
        }

        let cost = ResourceHandV1(wood: 1, brick: 1)
        guard canAfford(hand: state.resourcesByPlayer[player] ?? .zero, cost: cost) else {
            throw CoreGameError.buildInsufficientResources
        }
        let economy = applyBuildCost(player: player, cost: cost, state: state)

        var roads = state.roadsByEdge
        roads[edgeID] = player

        return nextTurnState(
            from: state,
            currentPlayer: player,
            diceRngState: state.diceRngState,
            robberRngState: state.robberRngState,
            board: state.board,
            turnState: turnState,
            resourcesByPlayer: economy.resourcesByPlayer,
            bankResources: economy.bankResources,
            roadsByEdge: roads
        )

    case let .buildSettlement(nodeID):
        guard turnState.step == .afterRoll else {
            throw CoreGameError.turnStepMismatch
        }
        guard nodeID >= 0, nodeID < turnBuildTopology.nodesCount else {
            throw CoreGameError.invalidNode
        }
        guard state.settlementsByNode[nodeID] == nil, state.citiesByNode[nodeID] == nil else {
            throw CoreGameError.nodeOccupied
        }

        let occupiedNodes = Set(state.settlementsByNode.keys).union(Set(state.citiesByNode.keys))
        let adjacentNodes = Set(turnBuildTopology.nodes(adjacentTo: nodeID))
        if !adjacentNodes.isDisjoint(with: occupiedNodes) {
            throw CoreGameError.distanceRuleViolation
        }

        let player = state.currentPlayer
        let playerSettlementCount = state.settlementsByNode.values.filter { $0 == player }.count
        guard playerSettlementCount < 5 else {
            throw CoreGameError.buildPieceLimitReached
        }
        guard isSettlementConnected(nodeID: nodeID, for: player, in: state) else {
            throw CoreGameError.settlementConnectionRequired
        }

        let cost = ResourceHandV1(wood: 1, brick: 1, sheep: 1, wheat: 1)
        guard canAfford(hand: state.resourcesByPlayer[player] ?? .zero, cost: cost) else {
            throw CoreGameError.buildInsufficientResources
        }
        let economy = applyBuildCost(player: player, cost: cost, state: state)

        var settlements = state.settlementsByNode
        settlements[nodeID] = player

        return nextTurnState(
            from: state,
            currentPlayer: player,
            diceRngState: state.diceRngState,
            robberRngState: state.robberRngState,
            board: state.board,
            turnState: turnState,
            resourcesByPlayer: economy.resourcesByPlayer,
            bankResources: economy.bankResources,
            settlementsByNode: settlements
        )

    case let .buildCity(nodeID):
        guard turnState.step == .afterRoll else {
            throw CoreGameError.turnStepMismatch
        }
        guard nodeID >= 0, nodeID < turnBuildTopology.nodesCount else {
            throw CoreGameError.invalidNode
        }
        let player = state.currentPlayer
        guard state.settlementsByNode[nodeID] == player else {
            throw CoreGameError.cityRequiresOwnSettlement
        }
        guard state.citiesByNode[nodeID] == nil else {
            throw CoreGameError.nodeOccupied
        }

        let playerCityCount = state.citiesByNode.values.filter { $0 == player }.count
        guard playerCityCount < 4 else {
            throw CoreGameError.buildPieceLimitReached
        }

        let cost = ResourceHandV1(wheat: 2, ore: 3)
        guard canAfford(hand: state.resourcesByPlayer[player] ?? .zero, cost: cost) else {
            throw CoreGameError.buildInsufficientResources
        }
        let economy = applyBuildCost(player: player, cost: cost, state: state)

        var settlements = state.settlementsByNode
        settlements.removeValue(forKey: nodeID)
        var cities = state.citiesByNode
        cities[nodeID] = player

        return nextTurnState(
            from: state,
            currentPlayer: player,
            diceRngState: state.diceRngState,
            robberRngState: state.robberRngState,
            board: state.board,
            turnState: turnState,
            resourcesByPlayer: economy.resourcesByPlayer,
            bankResources: economy.bankResources,
            settlementsByNode: settlements,
            citiesByNode: cities
        )

    case let .proposeTrade(give, receive):
        guard turnState.step == .afterRoll else {
            throw CoreGameError.turnStepMismatch
        }
        guard state.activeTradeOffer == nil else {
            throw CoreGameError.tradeOfferAlreadyActive
        }
        guard
            isValidTradeHand(give),
            isValidTradeHand(receive),
            give.totalCount > 0,
            receive.totalCount > 0,
            give != receive
        else {
            throw CoreGameError.tradeOfferInvalid
        }
        guard canAfford(hand: state.resourcesByPlayer[state.currentPlayer] ?? .zero, cost: give) else {
            throw CoreGameError.tradeOfferInvalid
        }

        let offerHash = deterministicTradeOfferHash(
            gameId: state.gameId,
            proposer: state.currentPlayer,
            give: give,
            receive: receive,
            anchorRev: state.rev,
            anchorHash: state.stateHash
        )
        let offer = TradeOfferV1(
            offerHash: offerHash,
            proposer: state.currentPlayer,
            give: give,
            receive: receive,
            createdRev: state.rev + 1
        )
        return nextTurnState(
            from: state,
            currentPlayer: state.currentPlayer,
            diceRngState: state.diceRngState,
            robberRngState: state.robberRngState,
            board: state.board,
            turnState: turnState,
            activeTradeOffer: .some(offer),
            pendingTradeAccepts: .some([])
        )

    case let .acceptTrade(acceptingPlayer, offerHash):
        guard turnState.step == .afterRoll else {
            throw CoreGameError.turnStepMismatch
        }
        guard let offer = state.activeTradeOffer else {
            throw CoreGameError.tradeOfferMissing
        }
        guard offer.offerHash == offerHash else {
            throw CoreGameError.tradeOfferAnchorMismatch
        }
        guard acceptingPlayer != state.currentPlayer, state.roster.contains(acceptingPlayer) else {
            throw CoreGameError.tradeAcceptPlayerInvalid
        }
        guard !state.pendingTradeAccepts.contains(where: { $0.acceptingPlayer == acceptingPlayer }) else {
            throw CoreGameError.tradeAcceptAlreadySubmitted
        }

        var accepts = state.pendingTradeAccepts
        accepts.append(
            TradeAcceptV1(
                acceptingPlayer: acceptingPlayer,
                offerHash: offerHash,
                acceptedAtRev: state.rev + 1
            )
        )
        return nextTurnState(
            from: state,
            currentPlayer: state.currentPlayer,
            diceRngState: state.diceRngState,
            robberRngState: state.robberRngState,
            board: state.board,
            turnState: turnState,
            activeTradeOffer: .some(offer),
            pendingTradeAccepts: .some(accepts)
        )

    case let .executeTrade(acceptingPlayer, offerHash):
        guard turnState.step == .afterRoll else {
            throw CoreGameError.turnStepMismatch
        }
        guard let offer = state.activeTradeOffer else {
            throw CoreGameError.tradeOfferMissing
        }
        guard offer.offerHash == offerHash else {
            throw CoreGameError.tradeOfferAnchorMismatch
        }
        guard state.pendingTradeAccepts.contains(where: { $0.acceptingPlayer == acceptingPlayer && $0.offerHash == offerHash }) else {
            throw CoreGameError.tradeAcceptMissing
        }

        let proposer = state.currentPlayer
        let proposerHand = state.resourcesByPlayer[proposer] ?? .zero
        let acceptorHand = state.resourcesByPlayer[acceptingPlayer] ?? .zero
        guard canAfford(hand: proposerHand, cost: offer.give), canAfford(hand: acceptorHand, cost: offer.receive) else {
            throw CoreGameError.tradeExecutionInsufficientResources
        }

        var updatedResourcesByPlayer = state.resourcesByPlayer
        updatedResourcesByPlayer[proposer] = addHands(
            subtractHands(proposerHand, offer.give),
            offer.receive
        )
        updatedResourcesByPlayer[acceptingPlayer] = addHands(
            subtractHands(acceptorHand, offer.receive),
            offer.give
        )

        return nextTurnState(
            from: state,
            currentPlayer: proposer,
            diceRngState: state.diceRngState,
            robberRngState: state.robberRngState,
            board: state.board,
            turnState: turnState,
            resourcesByPlayer: updatedResourcesByPlayer,
            activeTradeOffer: .some(nil),
            pendingTradeAccepts: .some([])
        )

    case let .maritimeTrade(give, receive):
        guard turnState.step == .afterRoll else {
            throw CoreGameError.turnStepMismatch
        }
        guard let board = state.board else {
            throw CoreGameError.boardChanged
        }
        guard
            let (giveResource, giveCount) = singleResourceAndCount(in: give),
            let (receiveResource, receiveCount) = singleResourceAndCount(in: receive),
            giveCount > 0,
            receiveCount == 1,
            giveResource != receiveResource
        else {
            throw CoreGameError.maritimeTradeInvalid
        }

        let player = state.currentPlayer
        let requiredRatio = bestMaritimeTradeRatio(
            player: player,
            giveResource: giveResource,
            board: board,
            settlementsByNode: state.settlementsByNode,
            citiesByNode: state.citiesByNode
        )
        guard giveCount == requiredRatio else {
            throw CoreGameError.maritimeTradeInvalid
        }

        let playerHand = state.resourcesByPlayer[player] ?? .zero
        guard playerHand.count(for: giveResource) >= giveCount else {
            throw CoreGameError.maritimeTradeInsufficientResources
        }
        guard state.bankResources.count(for: receiveResource) >= receiveCount else {
            throw CoreGameError.bankResourcesInvalid
        }

        var updatedResourcesByPlayer = state.resourcesByPlayer
        updatedResourcesByPlayer[player] = playerHand
            .subtracting(giveCount, for: giveResource)
            .adding(receiveCount, for: receiveResource)
        let updatedBankResources = state.bankResources
            .adding(giveCount, for: giveResource)
            .subtracting(receiveCount, for: receiveResource)

        return nextTurnState(
            from: state,
            currentPlayer: player,
            diceRngState: state.diceRngState,
            robberRngState: state.robberRngState,
            board: state.board,
            turnState: turnState,
            resourcesByPlayer: updatedResourcesByPlayer,
            bankResources: updatedBankResources
        )

    case .buyDevCard:
        guard turnState.step == .afterRoll else {
            throw CoreGameError.turnStepMismatch
        }
        guard let draw = drawTopDevCard(from: state.devDeck) else {
            throw CoreGameError.devDeckEmpty
        }

        let player = state.currentPlayer
        let cost = ResourceHandV1(sheep: 1, wheat: 1, ore: 1)
        guard canAfford(hand: state.resourcesByPlayer[player] ?? .zero, cost: cost) else {
            throw CoreGameError.devCardPurchaseInsufficientResources
        }
        let economy = applyBuildCost(player: player, cost: cost, state: state)

        var newDevCardsByPlayer = state.newDevCardsByPlayer
        let currentNew = newDevCardsByPlayer[player] ?? .zero
        newDevCardsByPlayer[player] = currentNew.addingOne(card: draw.card)

        return nextTurnState(
            from: state,
            currentPlayer: player,
            diceRngState: state.diceRngState,
            robberRngState: state.robberRngState,
            board: state.board,
            turnState: turnState,
            resourcesByPlayer: economy.resourcesByPlayer,
            bankResources: economy.bankResources,
            devDeck: draw.remaining,
            newDevCardsByPlayer: newDevCardsByPlayer
        )

    case let .playKnight(tileID, victimPlayer):
        guard turnState.step.allowsDevCardPlay else {
            throw CoreGameError.turnStepMismatch
        }
        try ensureDevCardActionCanBePlayed(state: state)
        try ensureCardAvailable(card: .knight, state: state)

        guard let board = state.board else {
            throw CoreGameError.boardChanged
        }
        guard tileID >= 0, tileID < board.resourcesByTile.count else {
            throw CoreGameError.invalidRobberTile
        }
        guard tileID != board.robberTile else {
            throw CoreGameError.robberTileUnchanged
        }
        guard let robberSeed = state.robberRngState else {
            throw CoreGameError.missingRobberRngState
        }

        var updatedDevCardsByPlayer = state.devCardsByPlayer
        updatedDevCardsByPlayer[state.currentPlayer] = (updatedDevCardsByPlayer[state.currentPlayer] ?? .zero)
            .subtractingOne(card: .knight)
        var updatedKnightsPlayedByPlayer = state.knightsPlayedByPlayer
        updatedKnightsPlayedByPlayer[state.currentPlayer, default: 0] += 1

        let movedBoard = BoardSetupV1(
            resourcesByTile: board.resourcesByTile,
            numbersByTile: board.numbersByTile,
            portsByIndex: board.portsByIndex,
            robberTile: tileID,
            generator: board.generator,
            boardHash: ""
        ).rehashed()

        var updatedResourcesByPlayer = state.resourcesByPlayer
        var nextRobberSeed = robberSeed
        let victims = eligibleRobberVictims(
            for: tileID,
            settlementsByNode: state.settlementsByNode,
            citiesByNode: state.citiesByNode,
            resourcesByPlayer: state.resourcesByPlayer,
            currentPlayer: state.currentPlayer
        )
        if !victims.isEmpty {
            let selectedVictim = victimPlayer ?? victims[0]
            guard victims.contains(selectedVictim) else {
                throw CoreGameError.robberStealVictimNotEligible
            }
            let victimHand = state.resourcesByPlayer[selectedVictim] ?? .zero
            guard victimHand.totalCount > 0 else {
                throw CoreGameError.robberStealVictimNotEligible
            }

            var rng = DeterministicRNG(seed: robberSeed)
            let stolen = deterministicStolenResource(from: victimHand, rng: &rng)
            nextRobberSeed = rng.state

            let stealerHand = state.resourcesByPlayer[state.currentPlayer] ?? .zero
            updatedResourcesByPlayer[state.currentPlayer] = stealerHand.addingOne(for: stolen)
            updatedResourcesByPlayer[selectedVictim] = victimHand.subtracting(1, for: stolen)
        }

        return nextTurnState(
            from: state,
            currentPlayer: state.currentPlayer,
            diceRngState: state.diceRngState,
            robberRngState: nextRobberSeed,
            board: movedBoard,
            turnState: turnState,
            resourcesByPlayer: updatedResourcesByPlayer,
            devCardsByPlayer: updatedDevCardsByPlayer,
            devCardActionPlayedThisTurn: true,
            knightsPlayedByPlayer: updatedKnightsPlayedByPlayer
        )

    case let .playMonopoly(resource):
        guard turnState.step.allowsDevCardPlay else {
            throw CoreGameError.turnStepMismatch
        }
        try ensureDevCardActionCanBePlayed(state: state)
        try ensureCardAvailable(card: .monopoly, state: state)
        guard resource != .desert else {
            throw CoreGameError.devCardPayloadInvalid
        }

        var updatedDevCardsByPlayer = state.devCardsByPlayer
        updatedDevCardsByPlayer[state.currentPlayer] = (updatedDevCardsByPlayer[state.currentPlayer] ?? .zero)
            .subtractingOne(card: .monopoly)

        let current = state.currentPlayer
        var updatedResourcesByPlayer = state.resourcesByPlayer
        var totalCollected = 0
        for player in state.roster where player != current {
            let hand = updatedResourcesByPlayer[player] ?? .zero
            let amount = hand.count(for: resource)
            if amount > 0 {
                updatedResourcesByPlayer[player] = hand.subtracting(amount, for: resource)
                totalCollected += amount
            }
        }
        let currentHand = updatedResourcesByPlayer[current] ?? .zero
        updatedResourcesByPlayer[current] = currentHand.adding(totalCollected, for: resource)

        return nextTurnState(
            from: state,
            currentPlayer: current,
            diceRngState: state.diceRngState,
            robberRngState: state.robberRngState,
            board: state.board,
            turnState: turnState,
            resourcesByPlayer: updatedResourcesByPlayer,
            devCardsByPlayer: updatedDevCardsByPlayer,
            devCardActionPlayedThisTurn: true
        )

    case let .playYearOfPlenty(first, second):
        guard turnState.step.allowsDevCardPlay else {
            throw CoreGameError.turnStepMismatch
        }
        try ensureDevCardActionCanBePlayed(state: state)
        try ensureCardAvailable(card: .yearOfPlenty, state: state)
        guard first != .desert, second != .desert else {
            throw CoreGameError.devCardPayloadInvalid
        }

        guard state.bankResources.count(for: first) >= 1 else {
            throw CoreGameError.bankResourcesInvalid
        }
        let requiredSecond = first == second ? 2 : 1
        guard state.bankResources.count(for: second) >= requiredSecond else {
            throw CoreGameError.bankResourcesInvalid
        }

        var updatedDevCardsByPlayer = state.devCardsByPlayer
        updatedDevCardsByPlayer[state.currentPlayer] = (updatedDevCardsByPlayer[state.currentPlayer] ?? .zero)
            .subtractingOne(card: .yearOfPlenty)

        var updatedResourcesByPlayer = state.resourcesByPlayer
        let currentHand = updatedResourcesByPlayer[state.currentPlayer] ?? .zero
        updatedResourcesByPlayer[state.currentPlayer] = currentHand
            .adding(1, for: first)
            .adding(1, for: second)

        let updatedBankResources = state.bankResources
            .subtracting(1, for: first)
            .subtracting(1, for: second)

        return nextTurnState(
            from: state,
            currentPlayer: state.currentPlayer,
            diceRngState: state.diceRngState,
            robberRngState: state.robberRngState,
            board: state.board,
            turnState: turnState,
            resourcesByPlayer: updatedResourcesByPlayer,
            bankResources: updatedBankResources,
            devCardsByPlayer: updatedDevCardsByPlayer,
            devCardActionPlayedThisTurn: true
        )

    case let .playRoadBuilding(firstEdgeID, secondEdgeID):
        guard turnState.step.allowsDevCardPlay else {
            throw CoreGameError.turnStepMismatch
        }
        try ensureDevCardActionCanBePlayed(state: state)
        try ensureCardAvailable(card: .roadBuilding, state: state)

        let player = state.currentPlayer
        var roads = state.roadsByEdge
        var workingState = state
        var playerRoadCount = roads.values.filter { $0 == player }.count
        for edgeID in [firstEdgeID, secondEdgeID] {
            guard edgeID >= 0, edgeID < turnBuildTopology.edges.count else {
                throw CoreGameError.invalidEdge
            }
            guard roads[edgeID] == nil else {
                throw CoreGameError.edgeOccupied
            }
            guard playerRoadCount < 15 else {
                throw CoreGameError.buildPieceLimitReached
            }
            guard isRoadConnected(edgeID: edgeID, for: player, in: workingState) else {
                throw CoreGameError.roadConnectionRequired
            }
            roads[edgeID] = player
            playerRoadCount += 1
            workingState = CoreGameStateV1(
                gameId: workingState.gameId,
                rev: workingState.rev,
                prevHash: workingState.prevHash,
                stateHash: workingState.stateHash,
                roster: workingState.roster,
                currentPlayer: workingState.currentPlayer,
                phase: workingState.phase,
                seed: workingState.seed,
                diceRngState: workingState.diceRngState,
                robberRngState: workingState.robberRngState,
                resourcesByPlayer: workingState.resourcesByPlayer,
                bankResources: workingState.bankResources,
                devDeck: workingState.devDeck,
                devCardsByPlayer: workingState.devCardsByPlayer,
                newDevCardsByPlayer: workingState.newDevCardsByPlayer,
                revealedVictoryPointsByPlayer: workingState.revealedVictoryPointsByPlayer,
                devCardActionPlayedThisTurn: workingState.devCardActionPlayedThisTurn,
                knightsPlayedByPlayer: workingState.knightsPlayedByPlayer,
                largestArmyOwner: workingState.largestArmyOwner,
                largestArmySize: workingState.largestArmySize,
                longestRoadOwner: workingState.longestRoadOwner,
                longestRoadLength: workingState.longestRoadLength,
                winnerPlayer: workingState.winnerPlayer,
                winningVictoryPoints: workingState.winningVictoryPoints,
                auditLog: workingState.auditLog,
                lastTurnRecap: workingState.lastTurnRecap,
                activeTradeOffer: workingState.activeTradeOffer,
                pendingTradeAccepts: workingState.pendingTradeAccepts,
                settlementsByNode: workingState.settlementsByNode,
                citiesByNode: workingState.citiesByNode,
                roadsByEdge: roads,
                boardRules: workingState.boardRules,
                board: workingState.board,
                setupState: workingState.setupState,
                turnState: workingState.turnState
            )
        }

        var updatedDevCardsByPlayer = state.devCardsByPlayer
        updatedDevCardsByPlayer[player] = (updatedDevCardsByPlayer[player] ?? .zero)
            .subtractingOne(card: .roadBuilding)

        return nextTurnState(
            from: state,
            currentPlayer: player,
            diceRngState: state.diceRngState,
            robberRngState: state.robberRngState,
            board: state.board,
            turnState: turnState,
            devCardsByPlayer: updatedDevCardsByPlayer,
            devCardActionPlayedThisTurn: true,
            roadsByEdge: roads
        )

    case .revealVictoryPoint:
        guard turnState.step.allowsDevCardPlay else {
            throw CoreGameError.turnStepMismatch
        }

        let player = state.currentPlayer
        var devCardsByPlayer = state.devCardsByPlayer
        var newDevCardsByPlayer = state.newDevCardsByPlayer
        let playable = devCardsByPlayer[player] ?? .zero
        let newlyBought = newDevCardsByPlayer[player] ?? .zero
        if playable.victoryPoint > 0 {
            devCardsByPlayer[player] = playable.subtractingOne(card: .victoryPoint)
        } else if newlyBought.victoryPoint > 0 {
            newDevCardsByPlayer[player] = newlyBought.subtractingOne(card: .victoryPoint)
        } else {
            throw CoreGameError.devCardNotOwned
        }

        var revealed = state.revealedVictoryPointsByPlayer
        revealed[player, default: 0] += 1

        return nextTurnState(
            from: state,
            currentPlayer: player,
            diceRngState: state.diceRngState,
            robberRngState: state.robberRngState,
            board: state.board,
            turnState: turnState,
            devCardsByPlayer: devCardsByPlayer,
            newDevCardsByPlayer: newDevCardsByPlayer,
            revealedVictoryPointsByPlayer: revealed
        )

    case .endTurn:
        guard turnState.step == .afterRoll else {
            throw CoreGameError.turnStepMismatch
        }

        guard let currentIndex = state.roster.firstIndex(of: state.currentPlayer), !state.roster.isEmpty else {
            throw CoreGameError.turnCurrentPlayerNotInRoster
        }

        let nextIndex = state.roster.index(after: currentIndex)
        let wrappedIndex = nextIndex == state.roster.endIndex ? state.roster.startIndex : nextIndex
        let nextPlayer = state.roster[wrappedIndex]

        let endingPlayer = state.currentPlayer
        var devCardsByPlayer = state.devCardsByPlayer
        var newDevCardsByPlayer = state.newDevCardsByPlayer
        let endingPlayable = devCardsByPlayer[endingPlayer] ?? .zero
        let endingNew = newDevCardsByPlayer[endingPlayer] ?? .zero
        devCardsByPlayer[endingPlayer] = mergeDevInventories(endingPlayable, endingNew)
        newDevCardsByPlayer[endingPlayer] = .zero

        return nextTurnState(
            from: state,
            currentPlayer: nextPlayer,
            diceRngState: state.diceRngState,
            robberRngState: state.robberRngState,
            board: state.board,
            turnState: TurnStateV1(step: .needsRoll, lastRoll: nil),
            devCardsByPlayer: devCardsByPlayer,
            newDevCardsByPlayer: newDevCardsByPlayer,
            devCardActionPlayedThisTurn: false,
            activeTradeOffer: .some(nil),
            pendingTradeAccepts: .some([])
        )
    }
}

private func baseNextTurnState(
    from state: CoreGameStateV1,
    currentPlayer: String,
    diceRngState: UInt64?,
    robberRngState: UInt64?,
    board: BoardSetupV1?,
    turnState: TurnStateV1,
    resourcesByPlayer: [String: ResourceHandV1]? = nil,
    bankResources: ResourceHandV1? = nil,
    devDeck: [DevCardV1]? = nil,
    devCardsByPlayer: [String: DevCardInventoryV1]? = nil,
    newDevCardsByPlayer: [String: DevCardInventoryV1]? = nil,
    revealedVictoryPointsByPlayer: [String: Int]? = nil,
    devCardActionPlayedThisTurn: Bool? = nil,
    knightsPlayedByPlayer: [String: Int]? = nil,
    activeTradeOffer: TradeOfferV1?? = nil,
    pendingTradeAccepts: [TradeAcceptV1]?? = nil,
    settlementsByNode: [NodeID: String]? = nil,
    citiesByNode: [NodeID: String]? = nil,
    roadsByEdge: [EdgeID: String]? = nil,
    intent: TurnIntentV1
) -> CoreGameStateV1 {
    let provisional = CoreGameStateV1(
        gameId: state.gameId,
        rev: state.rev + 1,
        prevHash: state.stateHash,
        stateHash: "",
        roster: state.roster,
        currentPlayer: currentPlayer,
        phase: .turn,
        seed: state.seed,
        diceRngState: diceRngState,
        robberRngState: robberRngState,
        resourcesByPlayer: resourcesByPlayer ?? state.resourcesByPlayer,
        bankResources: bankResources ?? state.bankResources,
        devDeck: devDeck ?? state.devDeck,
        devCardsByPlayer: devCardsByPlayer ?? state.devCardsByPlayer,
        newDevCardsByPlayer: newDevCardsByPlayer ?? state.newDevCardsByPlayer,
        revealedVictoryPointsByPlayer: revealedVictoryPointsByPlayer ?? state.revealedVictoryPointsByPlayer,
        devCardActionPlayedThisTurn: devCardActionPlayedThisTurn ?? state.devCardActionPlayedThisTurn,
        knightsPlayedByPlayer: knightsPlayedByPlayer ?? state.knightsPlayedByPlayer,
        largestArmyOwner: state.largestArmyOwner,
        largestArmySize: state.largestArmySize,
        longestRoadOwner: state.longestRoadOwner,
        longestRoadLength: state.longestRoadLength,
        winnerPlayer: state.winnerPlayer,
        winningVictoryPoints: state.winningVictoryPoints,
        auditLog: state.auditLog,
        lastTurnRecap: state.lastTurnRecap,
        activeTradeOffer: activeTradeOffer ?? state.activeTradeOffer,
        pendingTradeAccepts: (pendingTradeAccepts ?? state.pendingTradeAccepts) ?? state.pendingTradeAccepts,
        settlementsByNode: settlementsByNode ?? state.settlementsByNode,
        citiesByNode: citiesByNode ?? state.citiesByNode,
        roadsByEdge: roadsByEdge ?? state.roadsByEdge,
        boardRules: state.boardRules,
        board: board,
        setupState: nil,
        turnState: turnState
    )

    let awards = recomputeAwards(from: state, for: provisional)
    let withAwards = stateByApplyingAwards(provisional, awards: awards)
    let withAudit = stateByAppendingAuditEntry(from: state, to: withAwards, intent: intent)
    if shouldTransitionToGameOver(from: state, to: withAudit) {
        let winner = state.currentPlayer
        let winningPoints = victoryPoints(for: winner, in: withAudit)
        return stateByApplyingGameOver(withAudit, winner: winner, winningPoints: winningPoints).rehashed()
    }
    return withAudit.rehashed()
}

private func stateByApplyingAwards(_ state: CoreGameStateV1, awards: AwardStateV1) -> CoreGameStateV1 {
    CoreGameStateV1(
        gameId: state.gameId,
        rev: state.rev,
        prevHash: state.prevHash,
        stateHash: state.stateHash,
        roster: state.roster,
        currentPlayer: state.currentPlayer,
        phase: state.phase,
        seed: state.seed,
        diceRngState: state.diceRngState,
        robberRngState: state.robberRngState,
        resourcesByPlayer: state.resourcesByPlayer,
        bankResources: state.bankResources,
        devDeck: state.devDeck,
        devCardsByPlayer: state.devCardsByPlayer,
        newDevCardsByPlayer: state.newDevCardsByPlayer,
        revealedVictoryPointsByPlayer: state.revealedVictoryPointsByPlayer,
        devCardActionPlayedThisTurn: state.devCardActionPlayedThisTurn,
        knightsPlayedByPlayer: state.knightsPlayedByPlayer,
        largestArmyOwner: awards.largestArmyOwner,
        largestArmySize: awards.largestArmySize,
        longestRoadOwner: awards.longestRoadOwner,
        longestRoadLength: awards.longestRoadLength,
        winnerPlayer: state.winnerPlayer,
        winningVictoryPoints: state.winningVictoryPoints,
        auditLog: state.auditLog,
        lastTurnRecap: state.lastTurnRecap,
        activeTradeOffer: state.activeTradeOffer,
        pendingTradeAccepts: state.pendingTradeAccepts,
        settlementsByNode: state.settlementsByNode,
        citiesByNode: state.citiesByNode,
        roadsByEdge: state.roadsByEdge,
        boardRules: state.boardRules,
        board: state.board,
        setupState: state.setupState,
        turnState: state.turnState
    )
}

private func shouldTransitionToGameOver(from previous: CoreGameStateV1, to candidate: CoreGameStateV1) -> Bool {
    guard
        previous.phase == .turn,
        candidate.phase == .turn,
        previous.currentPlayer == candidate.currentPlayer,
        previous.turnState?.step == .afterRoll
    else {
        return false
    }
    return victoryPoints(for: previous.currentPlayer, in: candidate) >= 10
}

private func stateByApplyingGameOver(
    _ state: CoreGameStateV1,
    winner: String,
    winningPoints: Int
) -> CoreGameStateV1 {
    CoreGameStateV1(
        gameId: state.gameId,
        rev: state.rev,
        prevHash: state.prevHash,
        stateHash: state.stateHash,
        roster: state.roster,
        currentPlayer: winner,
        phase: .gameOver,
        seed: state.seed,
        diceRngState: state.diceRngState,
        robberRngState: state.robberRngState,
        resourcesByPlayer: state.resourcesByPlayer,
        bankResources: state.bankResources,
        devDeck: state.devDeck,
        devCardsByPlayer: state.devCardsByPlayer,
        newDevCardsByPlayer: state.newDevCardsByPlayer,
        revealedVictoryPointsByPlayer: state.revealedVictoryPointsByPlayer,
        devCardActionPlayedThisTurn: state.devCardActionPlayedThisTurn,
        knightsPlayedByPlayer: state.knightsPlayedByPlayer,
        largestArmyOwner: state.largestArmyOwner,
        largestArmySize: state.largestArmySize,
        longestRoadOwner: state.longestRoadOwner,
        longestRoadLength: state.longestRoadLength,
        winnerPlayer: winner,
        winningVictoryPoints: max(10, winningPoints),
        auditLog: state.auditLog,
        lastTurnRecap: state.lastTurnRecap,
        activeTradeOffer: nil,
        pendingTradeAccepts: [],
        settlementsByNode: state.settlementsByNode,
        citiesByNode: state.citiesByNode,
        roadsByEdge: state.roadsByEdge,
        boardRules: state.boardRules,
        board: state.board,
        setupState: nil,
        turnState: nil
    )
}

private func stateByAppendingAuditEntry(
    from previous: CoreGameStateV1,
    to next: CoreGameStateV1,
    intent: TurnIntentV1
) -> CoreGameStateV1 {
    let action = auditAction(for: intent)
    let rollTotal = auditRollTotal(for: intent, turnState: next.turnState)
    let entry = AuditEntryV1(
        rev: next.rev,
        actor: previous.currentPlayer,
        action: action,
        rollTotal: rollTotal
    )
    let updatedAuditLog = previous.auditLog + [entry]
    let recap = computeLastTurnRecap(from: updatedAuditLog)

    return CoreGameStateV1(
        gameId: next.gameId,
        rev: next.rev,
        prevHash: next.prevHash,
        stateHash: next.stateHash,
        roster: next.roster,
        currentPlayer: next.currentPlayer,
        phase: next.phase,
        seed: next.seed,
        diceRngState: next.diceRngState,
        robberRngState: next.robberRngState,
        resourcesByPlayer: next.resourcesByPlayer,
        bankResources: next.bankResources,
        devDeck: next.devDeck,
        devCardsByPlayer: next.devCardsByPlayer,
        newDevCardsByPlayer: next.newDevCardsByPlayer,
        revealedVictoryPointsByPlayer: next.revealedVictoryPointsByPlayer,
        devCardActionPlayedThisTurn: next.devCardActionPlayedThisTurn,
        knightsPlayedByPlayer: next.knightsPlayedByPlayer,
        largestArmyOwner: next.largestArmyOwner,
        largestArmySize: next.largestArmySize,
        longestRoadOwner: next.longestRoadOwner,
        longestRoadLength: next.longestRoadLength,
        winnerPlayer: next.winnerPlayer,
        winningVictoryPoints: next.winningVictoryPoints,
        auditLog: updatedAuditLog,
        lastTurnRecap: recap,
        activeTradeOffer: next.activeTradeOffer,
        pendingTradeAccepts: next.pendingTradeAccepts,
        settlementsByNode: next.settlementsByNode,
        citiesByNode: next.citiesByNode,
        roadsByEdge: next.roadsByEdge,
        boardRules: next.boardRules,
        board: next.board,
        setupState: next.setupState,
        turnState: next.turnState
    )
}

private func auditAction(for intent: TurnIntentV1) -> AuditActionV1 {
    switch intent {
    case .rollDice:
        return .rollDice
    case .submitDiscard:
        return .submitDiscard
    case .moveRobber:
        return .moveRobber
    case .selectStealVictim:
        return .selectStealVictim
    case .buildRoad:
        return .buildRoad
    case .buildSettlement:
        return .buildSettlement
    case .buildCity:
        return .buildCity
    case .proposeTrade:
        return .proposeTrade
    case .acceptTrade:
        return .acceptTrade
    case .executeTrade:
        return .executeTrade
    case .maritimeTrade:
        return .maritimeTrade
    case .buyDevCard:
        return .buyDevCard
    case .playKnight:
        return .playKnight
    case .playMonopoly:
        return .playMonopoly
    case .playYearOfPlenty:
        return .playYearOfPlenty
    case .playRoadBuilding:
        return .playRoadBuilding
    case .revealVictoryPoint:
        return .revealVictoryPoint
    case .endTurn:
        return .endTurn
    }
}

private func auditRollTotal(for intent: TurnIntentV1, turnState: TurnStateV1?) -> Int? {
    guard case .rollDice = intent, let roll = turnState?.lastRoll else {
        return nil
    }
    return roll.d1 + roll.d2
}

private func requiredDiscards(for resourcesByPlayer: [String: ResourceHandV1]) -> [String: Int] {
    var result: [String: Int] = [:]
    for (player, hand) in resourcesByPlayer {
        if hand.totalCount > 7 {
            result[player] = hand.totalCount / 2
        }
    }
    return result
}

private func eligibleRobberVictims(
    for tileID: Int,
    settlementsByNode: [NodeID: String],
    citiesByNode: [NodeID: String],
    resourcesByPlayer: [String: ResourceHandV1],
    currentPlayer: String
) -> [String] {
    let topology = StandardBoardTopologyV1.standard()
    guard tileID >= 0, tileID < topology.tiles.count else {
        return []
    }

    var victims: Set<String> = []
    for node in topology.tiles[tileID].nodes {
        if let cityOwner = citiesByNode[node],
           cityOwner != currentPlayer,
           (resourcesByPlayer[cityOwner] ?? .zero).totalCount > 0
        {
            victims.insert(cityOwner)
            continue
        }

        if let settlementOwner = settlementsByNode[node],
           settlementOwner != currentPlayer,
           (resourcesByPlayer[settlementOwner] ?? .zero).totalCount > 0
        {
            victims.insert(settlementOwner)
        }
    }

    return victims.sorted()
}

private func deterministicStolenResource(from hand: ResourceHandV1, rng: inout DeterministicRNG) -> ResourceV1 {
    let total = hand.totalCount
    let pick = Int(rng.nextUInt64() % UInt64(total))

    let resources: [(ResourceV1, Int)] = [
        (.wood, hand.wood),
        (.brick, hand.brick),
        (.sheep, hand.sheep),
        (.wheat, hand.wheat),
        (.ore, hand.ore),
    ]

    var cursor = 0
    for (resource, count) in resources {
        if pick < cursor + count {
            return resource
        }
        cursor += count
    }

    return .wood
}

private func canAfford(hand: ResourceHandV1, cost: ResourceHandV1) -> Bool {
    hand.wood >= cost.wood &&
        hand.brick >= cost.brick &&
        hand.sheep >= cost.sheep &&
        hand.wheat >= cost.wheat &&
        hand.ore >= cost.ore
}

private func isValidTradeHand(_ hand: ResourceHandV1) -> Bool {
    hand.wood >= 0 &&
        hand.brick >= 0 &&
        hand.sheep >= 0 &&
        hand.wheat >= 0 &&
        hand.ore >= 0
}

private func addHands(_ lhs: ResourceHandV1, _ rhs: ResourceHandV1) -> ResourceHandV1 {
    ResourceHandV1(
        wood: lhs.wood + rhs.wood,
        brick: lhs.brick + rhs.brick,
        sheep: lhs.sheep + rhs.sheep,
        wheat: lhs.wheat + rhs.wheat,
        ore: lhs.ore + rhs.ore
    )
}

private func subtractHands(_ lhs: ResourceHandV1, _ rhs: ResourceHandV1) -> ResourceHandV1 {
    ResourceHandV1(
        wood: lhs.wood - rhs.wood,
        brick: lhs.brick - rhs.brick,
        sheep: lhs.sheep - rhs.sheep,
        wheat: lhs.wheat - rhs.wheat,
        ore: lhs.ore - rhs.ore
    )
}

private func ensureDevCardActionCanBePlayed(state: CoreGameStateV1) throws {
    if state.devCardActionPlayedThisTurn {
        throw CoreGameError.devCardAlreadyPlayedThisTurn
    }
}

private func ensureCardAvailable(card: DevCardV1, state: CoreGameStateV1) throws {
    let hand = state.devCardsByPlayer[state.currentPlayer] ?? .zero
    if hand.count(for: card) <= 0 {
        throw CoreGameError.devCardNotOwned
    }
}

private func mergeDevInventories(_ lhs: DevCardInventoryV1, _ rhs: DevCardInventoryV1) -> DevCardInventoryV1 {
    DevCardInventoryV1(
        knight: lhs.knight + rhs.knight,
        monopoly: lhs.monopoly + rhs.monopoly,
        yearOfPlenty: lhs.yearOfPlenty + rhs.yearOfPlenty,
        roadBuilding: lhs.roadBuilding + rhs.roadBuilding,
        victoryPoint: lhs.victoryPoint + rhs.victoryPoint
    )
}

private func applyBuildCost(player: String, cost: ResourceHandV1, state: CoreGameStateV1) -> EconomyUpdateV1 {
    let hand = state.resourcesByPlayer[player] ?? .zero
    var resourcesByPlayer = state.resourcesByPlayer
    resourcesByPlayer[player] = ResourceHandV1(
        wood: hand.wood - cost.wood,
        brick: hand.brick - cost.brick,
        sheep: hand.sheep - cost.sheep,
        wheat: hand.wheat - cost.wheat,
        ore: hand.ore - cost.ore
    )
    let bank = state.bankResources
    let bankResources = ResourceHandV1(
        wood: bank.wood + cost.wood,
        brick: bank.brick + cost.brick,
        sheep: bank.sheep + cost.sheep,
        wheat: bank.wheat + cost.wheat,
        ore: bank.ore + cost.ore
    )
    return EconomyUpdateV1(resourcesByPlayer: resourcesByPlayer, bankResources: bankResources)
}

private func singleResourceAndCount(in hand: ResourceHandV1) -> (resource: ResourceV1, count: Int)? {
    let entries: [(ResourceV1, Int)] = [
        (.wood, hand.wood),
        (.brick, hand.brick),
        (.sheep, hand.sheep),
        (.wheat, hand.wheat),
        (.ore, hand.ore),
    ].filter { $0.1 > 0 }

    guard entries.count == 1, let entry = entries.first else {
        return nil
    }
    return entry
}

private func bestMaritimeTradeRatio(
    player: String,
    giveResource: ResourceV1,
    board: BoardSetupV1,
    settlementsByNode: [NodeID: String],
    citiesByNode: [NodeID: String]
) -> Int {
    var hasThreeToOne = false
    var hasMatchingTwoToOne = false

    for portIndex in board.portsByIndex.indices {
        guard portIndex < turnBuildTopology.ports.count else {
            continue
        }
        let port = turnBuildTopology.ports[portIndex]
        let edge = turnBuildTopology.edges[port.edge]
        let ownsPort =
            settlementsByNode[edge.a] == player ||
            settlementsByNode[edge.b] == player ||
            citiesByNode[edge.a] == player ||
            citiesByNode[edge.b] == player
        if !ownsPort {
            continue
        }

        switch board.portsByIndex[portIndex] {
        case .threeToOne:
            hasThreeToOne = true
        case let .twoToOne(resource):
            if resource == giveResource {
                hasMatchingTwoToOne = true
            }
        }
    }

    if hasMatchingTwoToOne {
        return 2
    }
    if hasThreeToOne {
        return 3
    }
    return 4
}

private func isRoadConnected(edgeID: Int, for player: String, in state: CoreGameStateV1) -> Bool {
    let edge = turnBuildTopology.edges[edgeID]
    let nodes = [edge.a, edge.b]
    for node in nodes {
        if state.settlementsByNode[node] == player || state.citiesByNode[node] == player {
            return true
        }
        if state.settlementsByNode[node] != nil || state.citiesByNode[node] != nil {
            continue
        }
        for adjacentEdge in turnBuildTopology.edges(incidentTo: node) where adjacentEdge != edgeID {
            if state.roadsByEdge[adjacentEdge] == player {
                return true
            }
        }
    }
    return false
}

private func isSettlementConnected(nodeID: Int, for player: String, in state: CoreGameStateV1) -> Bool {
    for edge in turnBuildTopology.edges(incidentTo: nodeID) {
        if state.roadsByEdge[edge] == player {
            return true
        }
    }
    return false
}
