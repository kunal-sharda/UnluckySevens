import Foundation
import ULS_CoreGame

enum CompactStateTransportError: Error {
    case invalidPayload
}

private enum CompactStateCodec {
    static let transportForm = "compactStateV4"

    static func encodePhase(_ phase: PhaseV1) -> Int {
        switch phase {
        case .lobby: return 0
        case .setup: return 1
        case .turn: return 2
        case .gameOver: return 3
        }
    }

    static func decodePhase(_ code: Int) throws -> PhaseV1 {
        switch code {
        case 0: return .lobby
        case 1: return .setup
        case 2: return .turn
        case 3: return .gameOver
        default: throw CompactStateTransportError.invalidPayload
        }
    }

    static func encodeBoardStrategy(_ strategy: BoardGenStrategyV1) -> Int {
        switch strategy {
        case .randomV1: return 0
        case .noRedAdjacentV1: return 1
        }
    }

    static func decodeBoardStrategy(_ code: Int) throws -> BoardGenStrategyV1 {
        switch code {
        case 0: return .randomV1
        case 1: return .noRedAdjacentV1
        default: throw CompactStateTransportError.invalidPayload
        }
    }

    static func encodeDevCard(_ card: DevCardV1) -> Int {
        switch card {
        case .knight: return 0
        case .monopoly: return 1
        case .yearOfPlenty: return 2
        case .roadBuilding: return 3
        case .victoryPoint: return 4
        }
    }

    static func decodeDevCard(_ code: Int) throws -> DevCardV1 {
        switch code {
        case 0: return .knight
        case 1: return .monopoly
        case 2: return .yearOfPlenty
        case 3: return .roadBuilding
        case 4: return .victoryPoint
        default: throw CompactStateTransportError.invalidPayload
        }
    }

    static func encodeAuditAction(_ action: AuditActionV1) -> Int {
        switch action {
        case .rollDice: return 0
        case .submitDiscard: return 1
        case .moveRobber: return 2
        case .selectStealVictim: return 3
        case .buildRoad: return 4
        case .buildSettlement: return 5
        case .buildCity: return 6
        case .proposeTrade: return 7
        case .acceptTrade: return 8
        case .declineTrade: return 9
        case .counterTrade: return 10
        case .maritimeTrade: return 12
        case .buyDevCard: return 13
        case .playKnight: return 14
        case .playMonopoly: return 15
        case .playYearOfPlenty: return 16
        case .playRoadBuilding: return 17
        case .revealVictoryPoint: return 18
        case .endTurn: return 19
        }
    }

    static func decodeAuditAction(_ code: Int) throws -> AuditActionV1 {
        switch code {
        case 0: return .rollDice
        case 1: return .submitDiscard
        case 2: return .moveRobber
        case 3: return .selectStealVictim
        case 4: return .buildRoad
        case 5: return .buildSettlement
        case 6: return .buildCity
        case 7: return .proposeTrade
        case 8: return .acceptTrade
        case 9: return .declineTrade
        case 10: return .counterTrade
        case 12: return .maritimeTrade
        case 13: return .buyDevCard
        case 14: return .playKnight
        case 15: return .playMonopoly
        case 16: return .playYearOfPlenty
        case 17: return .playRoadBuilding
        case 18: return .revealVictoryPoint
        case 19: return .endTurn
        default: throw CompactStateTransportError.invalidPayload
        }
    }

    static func encodeTradeResponseKind(_ kind: TradeResponseKindV1) -> Int {
        switch kind {
        case .accept: return 0
        case .decline: return 1
        case .counter: return 2
        }
    }

    static func decodeTradeResponseKind(_ code: Int) throws -> TradeResponseKindV1 {
        switch code {
        case 0: return .accept
        case 1: return .decline
        case 2: return .counter
        default: throw CompactStateTransportError.invalidPayload
        }
    }

    static func encodeTurnStep(_ step: TurnStepV1) -> Int {
        switch step {
        case .needsRoll: return 0
        case .pendingDiscards: return 1
        case .needsRobberMove: return 2
        case .needsRobberSteal: return 3
        case .afterRoll: return 4
        }
    }

    static func decodeTurnStep(_ code: Int) throws -> TurnStepV1 {
        switch code {
        case 0: return .needsRoll
        case 1: return .pendingDiscards
        case 2: return .needsRobberMove
        case 3: return .needsRobberSteal
        case 4: return .afterRoll
        default: throw CompactStateTransportError.invalidPayload
        }
    }

    static func encodeSetupStep(_ step: SetupStepV1) -> Int {
        switch step {
        case .placeSettlement: return 0
        case .placeRoad: return 1
        case .done: return 2
        }
    }

    static func decodeSetupStep(_ code: Int) throws -> SetupStepV1 {
        switch code {
        case 0: return .placeSettlement
        case 1: return .placeRoad
        case 2: return .done
        default: throw CompactStateTransportError.invalidPayload
        }
    }

    static func rosterIndexMap(_ roster: [String]) -> [String: Int] {
        Dictionary(uniqueKeysWithValues: roster.enumerated().map { ($1, $0) })
    }

    static func index(for player: String, in rosterIndexMap: [String: Int]) throws -> Int {
        guard let index = rosterIndexMap[player] else {
            throw CompactStateTransportError.invalidPayload
        }
        return index
    }

    static func player(at index: Int, in roster: [String]) throws -> String {
        guard roster.indices.contains(index) else {
            throw CompactStateTransportError.invalidPayload
        }
        return roster[index]
    }
}

private struct CompactResourceHandTransportV1: Codable, Equatable {
    let wood: Int
    let brick: Int
    let sheep: Int
    let wheat: Int
    let ore: Int

    init(_ hand: ResourceHandV1) {
        wood = hand.wood
        brick = hand.brick
        sheep = hand.sheep
        wheat = hand.wheat
        ore = hand.ore
    }

    func rehydrated() -> ResourceHandV1 {
        ResourceHandV1(wood: wood, brick: brick, sheep: sheep, wheat: wheat, ore: ore)
    }

    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        wood = try container.decode(Int.self)
        brick = try container.decode(Int.self)
        sheep = try container.decode(Int.self)
        wheat = try container.decode(Int.self)
        ore = try container.decode(Int.self)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(wood)
        try container.encode(brick)
        try container.encode(sheep)
        try container.encode(wheat)
        try container.encode(ore)
    }
}

private struct CompactDevCardInventoryTransportV1: Codable, Equatable {
    let knight: Int
    let monopoly: Int
    let yearOfPlenty: Int
    let roadBuilding: Int
    let victoryPoint: Int

    init(_ inventory: DevCardInventoryV1) {
        knight = inventory.knight
        monopoly = inventory.monopoly
        yearOfPlenty = inventory.yearOfPlenty
        roadBuilding = inventory.roadBuilding
        victoryPoint = inventory.victoryPoint
    }

    func rehydrated() -> DevCardInventoryV1 {
        DevCardInventoryV1(
            knight: knight,
            monopoly: monopoly,
            yearOfPlenty: yearOfPlenty,
            roadBuilding: roadBuilding,
            victoryPoint: victoryPoint
        )
    }

    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        knight = try container.decode(Int.self)
        monopoly = try container.decode(Int.self)
        yearOfPlenty = try container.decode(Int.self)
        roadBuilding = try container.decode(Int.self)
        victoryPoint = try container.decode(Int.self)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(knight)
        try container.encode(monopoly)
        try container.encode(yearOfPlenty)
        try container.encode(roadBuilding)
        try container.encode(victoryPoint)
    }
}

private struct CompactAuditEntryTransportV1: Codable, Equatable {
    let rev: Int
    let actorIndex: Int
    let actionCode: Int
    let rollTotal: Int?

    init(entry: AuditEntryV1, rosterIndexMap: [String: Int]) throws {
        rev = entry.rev
        actorIndex = try CompactStateCodec.index(for: entry.actor, in: rosterIndexMap)
        actionCode = CompactStateCodec.encodeAuditAction(entry.action)
        rollTotal = entry.rollTotal
    }

    func rehydrated(roster: [String]) throws -> AuditEntryV1 {
        AuditEntryV1(
            rev: rev,
            actor: try CompactStateCodec.player(at: actorIndex, in: roster),
            action: try CompactStateCodec.decodeAuditAction(actionCode),
            rollTotal: rollTotal
        )
    }

    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        rev = try container.decode(Int.self)
        actorIndex = try container.decode(Int.self)
        actionCode = try container.decode(Int.self)
        rollTotal = try container.decodeIfPresent(Int.self)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(rev)
        try container.encode(actorIndex)
        try container.encode(actionCode)
        if let rollTotal {
            try container.encode(rollTotal)
        } else {
            try container.encodeNil()
        }
    }
}

private struct CompactTurnRecapTransportV1: Codable, Equatable {
    let actorIndex: Int
    let startRev: Int
    let endRev: Int
    let rollTotal: Int?
    let actionCodes: [Int]

    init(recap: TurnRecapV1, rosterIndexMap: [String: Int]) throws {
        actorIndex = try CompactStateCodec.index(for: recap.actor, in: rosterIndexMap)
        startRev = recap.startRev
        endRev = recap.endRev
        rollTotal = recap.rollTotal
        actionCodes = recap.actions.map(CompactStateCodec.encodeAuditAction)
    }

    func rehydrated(roster: [String]) throws -> TurnRecapV1 {
        TurnRecapV1(
            actor: try CompactStateCodec.player(at: actorIndex, in: roster),
            startRev: startRev,
            endRev: endRev,
            rollTotal: rollTotal,
            actions: try actionCodes.map(CompactStateCodec.decodeAuditAction)
        )
    }

    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        actorIndex = try container.decode(Int.self)
        startRev = try container.decode(Int.self)
        endRev = try container.decode(Int.self)
        rollTotal = try container.decodeIfPresent(Int.self)
        actionCodes = try container.decode([Int].self)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(actorIndex)
        try container.encode(startRev)
        try container.encode(endRev)
        if let rollTotal {
            try container.encode(rollTotal)
        } else {
            try container.encodeNil()
        }
        try container.encode(actionCodes)
    }
}

private struct CompactTradeOfferTransportV1: Codable, Equatable {
    let offerHash: String
    let proposerIndex: Int
    let give: CompactResourceHandTransportV1
    let receive: CompactResourceHandTransportV1
    let recipientIndices: [Int]
    let createdRev: Int

    init(offer: TradeOfferV1, rosterIndexMap: [String: Int]) throws {
        offerHash = offer.offerHash
        proposerIndex = try CompactStateCodec.index(for: offer.proposer, in: rosterIndexMap)
        give = CompactResourceHandTransportV1(offer.give)
        receive = CompactResourceHandTransportV1(offer.receive)
        recipientIndices = try offer.recipients.map { try CompactStateCodec.index(for: $0, in: rosterIndexMap) }
        createdRev = offer.createdRev
    }

    func rehydrated(roster: [String]) throws -> TradeOfferV1 {
        TradeOfferV1(
            offerHash: offerHash,
            proposer: try CompactStateCodec.player(at: proposerIndex, in: roster),
            give: give.rehydrated(),
            receive: receive.rehydrated(),
            recipients: try recipientIndices.map { try CompactStateCodec.player(at: $0, in: roster) },
            createdRev: createdRev
        )
    }

    enum CodingKeys: String, CodingKey {
        case offerHash = "h"
        case proposerIndex = "p"
        case give = "g"
        case receive = "r"
        case recipientIndices = "i"
        case createdRev = "c"
    }
}

private struct CompactTradeResponseTransportV1: Codable, Equatable {
    let respondingPlayerIndex: Int
    let offerHash: String
    let kindCode: Int
    let respondedAtRev: Int
    let counterGive: CompactResourceHandTransportV1?
    let counterReceive: CompactResourceHandTransportV1?

    init(response: TradeResponseV1, rosterIndexMap: [String: Int]) throws {
        respondingPlayerIndex = try CompactStateCodec.index(for: response.respondingPlayer, in: rosterIndexMap)
        offerHash = response.offerHash
        kindCode = CompactStateCodec.encodeTradeResponseKind(response.kind)
        respondedAtRev = response.respondedAtRev
        counterGive = response.counterGive.map(CompactResourceHandTransportV1.init)
        counterReceive = response.counterReceive.map(CompactResourceHandTransportV1.init)
    }

    func rehydrated(roster: [String]) throws -> TradeResponseV1 {
        TradeResponseV1(
            respondingPlayer: try CompactStateCodec.player(at: respondingPlayerIndex, in: roster),
            offerHash: offerHash,
            kind: try CompactStateCodec.decodeTradeResponseKind(kindCode),
            respondedAtRev: respondedAtRev,
            counterGive: counterGive?.rehydrated(),
            counterReceive: counterReceive?.rehydrated()
        )
    }

    enum CodingKeys: String, CodingKey {
        case respondingPlayerIndex = "p"
        case offerHash = "h"
        case kindCode = "k"
        case respondedAtRev = "r"
        case counterGive = "g"
        case counterReceive = "c"
    }
}

private struct CompactOwnershipEntryV1: Codable, Equatable {
    let slot: Int
    let ownerIndex: Int

    init(slot: Int, ownerIndex: Int) {
        self.slot = slot
        self.ownerIndex = ownerIndex
    }

    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        slot = try container.decode(Int.self)
        ownerIndex = try container.decode(Int.self)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(slot)
        try container.encode(ownerIndex)
    }
}

private struct CompactBoardTransportV1: Codable, Equatable {
    let robberTile: Int
}

private struct CompactDiceRollTransportV1: Codable, Equatable {
    let d1: Int
    let d2: Int

    init(_ roll: DiceRollV1) {
        d1 = roll.d1
        d2 = roll.d2
    }

    func rehydrated() -> DiceRollV1 {
        DiceRollV1(d1: d1, d2: d2)
    }

    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        d1 = try container.decode(Int.self)
        d2 = try container.decode(Int.self)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(d1)
        try container.encode(d2)
    }
}

private struct CompactPlayerSetupPlacementsTransportV1: Codable, Equatable {
    let settlement1: NodeID?
    let road1: EdgeID?
    let settlement2: NodeID?
    let road2: EdgeID?

    init(_ placements: PlayerSetupPlacementsV1) {
        settlement1 = placements.settlement1
        road1 = placements.road1
        settlement2 = placements.settlement2
        road2 = placements.road2
    }

    func rehydrated() -> PlayerSetupPlacementsV1 {
        PlayerSetupPlacementsV1(
            settlement1: settlement1,
            road1: road1,
            settlement2: settlement2,
            road2: road2
        )
    }

    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        settlement1 = try container.decodeIfPresent(NodeID.self)
        road1 = try container.decodeIfPresent(EdgeID.self)
        settlement2 = try container.decodeIfPresent(NodeID.self)
        road2 = try container.decodeIfPresent(EdgeID.self)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        if let settlement1 {
            try container.encode(settlement1)
        } else {
            try container.encodeNil()
        }
        if let road1 {
            try container.encode(road1)
        } else {
            try container.encodeNil()
        }
        if let settlement2 {
            try container.encode(settlement2)
        } else {
            try container.encodeNil()
        }
        if let road2 {
            try container.encode(road2)
        } else {
            try container.encodeNil()
        }
    }
}

private struct CompactSetupStateTransportV1: Codable, Equatable {
    let orderIndices: [Int]
    let turnIndex: Int
    let stepCode: Int
    let placements: [CompactPlayerSetupPlacementsTransportV1?]
    let lastPlacedSettlementNode: Int?

    init(setupState: SetupStateV1, roster: [String], rosterIndexMap: [String: Int]) throws {
        orderIndices = try setupState.order.map { try CompactStateCodec.index(for: $0, in: rosterIndexMap) }
        turnIndex = setupState.turnIndex
        stepCode = CompactStateCodec.encodeSetupStep(setupState.step)
        placements = roster.map { player in
            setupState.placements[player].map(CompactPlayerSetupPlacementsTransportV1.init)
        }
        lastPlacedSettlementNode = setupState.lastPlacedSettlementNode
    }

    func rehydrated(roster: [String]) throws -> SetupStateV1 {
        var placementsByPlayer: [String: PlayerSetupPlacementsV1] = [:]
        for (index, placements) in placements.enumerated() {
            guard let placements else { continue }
            placementsByPlayer[try CompactStateCodec.player(at: index, in: roster)] = placements.rehydrated()
        }

        return SetupStateV1(
            order: try orderIndices.map { try CompactStateCodec.player(at: $0, in: roster) },
            turnIndex: turnIndex,
            step: try CompactStateCodec.decodeSetupStep(stepCode),
            placements: placementsByPlayer,
            lastPlacedSettlementNode: lastPlacedSettlementNode
        )
    }

    enum CodingKeys: String, CodingKey {
        case orderIndices = "o"
        case turnIndex = "t"
        case stepCode = "s"
        case placements = "p"
        case lastPlacedSettlementNode = "l"
    }
}

private struct CompactTurnStateTransportV1: Codable, Equatable {
    let stepCode: Int
    let lastRoll: CompactDiceRollTransportV1?
    let discardRequirements: [Int]
    let submittedDiscards: [CompactResourceHandTransportV1?]
    let eligibleStealVictimIndices: [Int]

    init(turnState: TurnStateV1, roster: [String], rosterIndexMap: [String: Int]) throws {
        stepCode = CompactStateCodec.encodeTurnStep(turnState.step)
        lastRoll = turnState.lastRoll.map(CompactDiceRollTransportV1.init)
        discardRequirements = roster.map { turnState.discardRequirementsByPlayer[$0] ?? 0 }
        submittedDiscards = roster.map { player in
            turnState.submittedDiscardsByPlayer[player].map(CompactResourceHandTransportV1.init)
        }
        eligibleStealVictimIndices = try turnState.eligibleStealVictims.map {
            try CompactStateCodec.index(for: $0, in: rosterIndexMap)
        }
    }

    func rehydrated(roster: [String]) throws -> TurnStateV1 {
        var discardRequirementsByPlayer: [String: Int] = [:]
        var submittedDiscardsByPlayer: [String: ResourceHandV1] = [:]

        for (index, requirement) in discardRequirements.enumerated() where requirement > 0 {
            discardRequirementsByPlayer[try CompactStateCodec.player(at: index, in: roster)] = requirement
        }

        for (index, submitted) in submittedDiscards.enumerated() {
            guard let submitted else { continue }
            submittedDiscardsByPlayer[try CompactStateCodec.player(at: index, in: roster)] = submitted.rehydrated()
        }

        return TurnStateV1(
            step: try CompactStateCodec.decodeTurnStep(stepCode),
            lastRoll: lastRoll?.rehydrated(),
            discardRequirementsByPlayer: discardRequirementsByPlayer,
            submittedDiscardsByPlayer: submittedDiscardsByPlayer,
            eligibleStealVictims: try eligibleStealVictimIndices.map { try CompactStateCodec.player(at: $0, in: roster) }
        )
    }

    enum CodingKeys: String, CodingKey {
        case stepCode = "s"
        case lastRoll = "r"
        case discardRequirements = "d"
        case submittedDiscards = "u"
        case eligibleStealVictimIndices = "e"
    }
}

private struct CompactStateTransportV1: Codable, Equatable {
    let transportForm: String
    let gameId: String
    let rev: Int
    let prevHash: String?
    let stateHash: String
    let roster: [String]
    let playerDisplayNames: [String?]?
    let currentPlayerIndex: Int
    let phaseCode: Int
    let seed: UInt64?
    let diceRngState: UInt64?
    let robberRngState: UInt64?
    let resourcesByPlayer: [CompactResourceHandTransportV1]
    let bankResources: CompactResourceHandTransportV1
    let devDeckCodes: [Int]
    let devCardsByPlayer: [CompactDevCardInventoryTransportV1]
    let newDevCardsByPlayer: [CompactDevCardInventoryTransportV1]
    let revealedVictoryPoints: [Int]
    let devCardActionPlayedThisTurn: Bool
    let knightsPlayed: [Int]
    let largestArmyOwnerIndex: Int?
    let largestArmySize: Int
    let longestRoadOwnerIndex: Int?
    let longestRoadLength: Int
    let winnerPlayerIndex: Int?
    let winningVictoryPoints: Int
    let gameResultReasonCode: Int?
    let gameResultWinnerPlayerIndices: [Int]?
    let gameResultEndedByPlayerIndex: Int?
    let gameResultFinalScores: [Int]?
    let resignedPlayerIndices: [Int]
    let drawVoteProposerIndex: Int?
    let drawVoteApprovalIndices: [Int]?
    let hasAttemptedDrawVote: Bool
    let auditLog: [CompactAuditEntryTransportV1]
    let lastTurnRecap: CompactTurnRecapTransportV1?
    let activeTradeOffer: CompactTradeOfferTransportV1?
    let tradeResponses: [CompactTradeResponseTransportV1]
    let settlementsByNode: [CompactOwnershipEntryV1]
    let citiesByNode: [CompactOwnershipEntryV1]
    let roadsByEdge: [CompactOwnershipEntryV1]
    let boardStrategyCode: Int?
    let compactBoard: CompactBoardTransportV1?
    let setupState: CompactSetupStateTransportV1?
    let turnState: CompactTurnStateTransportV1?

    init(state: CoreGameStateV1) throws {
        let rosterIndexMap = CompactStateCodec.rosterIndexMap(state.roster)
        transportForm = CompactStateCodec.transportForm
        gameId = state.gameId
        rev = state.rev
        prevHash = state.prevHash
        stateHash = state.stateHash
        roster = state.roster
        let compactPlayerDisplayNames = state.roster.map { state.playerDisplayNamesByPlayer[$0] }
        playerDisplayNames = compactPlayerDisplayNames.contains(where: { $0 != nil }) ? compactPlayerDisplayNames : nil
        currentPlayerIndex = try CompactStateCodec.index(for: state.currentPlayer, in: rosterIndexMap)
        phaseCode = CompactStateCodec.encodePhase(state.phase)
        seed = state.seed
        diceRngState = state.diceRngState
        robberRngState = state.robberRngState
        resourcesByPlayer = state.roster.map { CompactResourceHandTransportV1(state.resourcesByPlayer[$0] ?? .zero) }
        bankResources = CompactResourceHandTransportV1(state.bankResources)
        devDeckCodes = state.devDeck.map(CompactStateCodec.encodeDevCard)
        devCardsByPlayer = state.roster.map { CompactDevCardInventoryTransportV1(state.devCardsByPlayer[$0] ?? .zero) }
        newDevCardsByPlayer = state.roster.map { CompactDevCardInventoryTransportV1(state.newDevCardsByPlayer[$0] ?? .zero) }
        revealedVictoryPoints = state.roster.map { state.revealedVictoryPointsByPlayer[$0] ?? 0 }
        devCardActionPlayedThisTurn = state.devCardActionPlayedThisTurn
        knightsPlayed = state.roster.map { state.knightsPlayedByPlayer[$0] ?? 0 }
        largestArmyOwnerIndex = try state.largestArmyOwner.map { try CompactStateCodec.index(for: $0, in: rosterIndexMap) }
        largestArmySize = state.largestArmySize
        longestRoadOwnerIndex = try state.longestRoadOwner.map { try CompactStateCodec.index(for: $0, in: rosterIndexMap) }
        longestRoadLength = state.longestRoadLength
        winnerPlayerIndex = try state.winnerPlayer.map { try CompactStateCodec.index(for: $0, in: rosterIndexMap) }
        winningVictoryPoints = state.winningVictoryPoints
        gameResultReasonCode = state.gameResult.map {
            switch $0.reason {
            case .victory: return 0
            case .draw: return 1
            case .hostEnded: return 2
            }
        }
        gameResultWinnerPlayerIndices = try state.gameResult?.winnerPlayers.map {
            try CompactStateCodec.index(for: $0, in: rosterIndexMap)
        }
        gameResultEndedByPlayerIndex = try state.gameResult?.endedByPlayer.map {
            try CompactStateCodec.index(for: $0, in: rosterIndexMap)
        }
        gameResultFinalScores = state.gameResult.map { result in
            state.roster.map { result.finalScoresByPlayer[$0] ?? 0 }
        }
        resignedPlayerIndices = try state.resignedPlayers.map {
            try CompactStateCodec.index(for: $0, in: rosterIndexMap)
        }
        drawVoteProposerIndex = try state.drawVote.map {
            try CompactStateCodec.index(for: $0.proposedBy, in: rosterIndexMap)
        }
        drawVoteApprovalIndices = try state.drawVote?.approvals.map {
            try CompactStateCodec.index(for: $0, in: rosterIndexMap)
        }
        hasAttemptedDrawVote = state.hasAttemptedDrawVote
        auditLog = try state.auditLog.map { try CompactAuditEntryTransportV1(entry: $0, rosterIndexMap: rosterIndexMap) }
        lastTurnRecap = try state.lastTurnRecap.map { try CompactTurnRecapTransportV1(recap: $0, rosterIndexMap: rosterIndexMap) }
        activeTradeOffer = try state.activeTradeOffer.map { try CompactTradeOfferTransportV1(offer: $0, rosterIndexMap: rosterIndexMap) }
        tradeResponses = try state.tradeResponses.map { try CompactTradeResponseTransportV1(response: $0, rosterIndexMap: rosterIndexMap) }
        settlementsByNode = try Self.compactOwnershipMap(state.settlementsByNode, rosterIndexMap: rosterIndexMap)
        citiesByNode = try Self.compactOwnershipMap(state.citiesByNode, rosterIndexMap: rosterIndexMap)
        roadsByEdge = try Self.compactOwnershipMap(state.roadsByEdge, rosterIndexMap: rosterIndexMap)
        boardStrategyCode = state.boardRules.map { CompactStateCodec.encodeBoardStrategy($0.strategy) }
        compactBoard = state.board.map { CompactBoardTransportV1(robberTile: $0.robberTile) }
        setupState = try state.setupState.map { try CompactSetupStateTransportV1(setupState: $0, roster: state.roster, rosterIndexMap: rosterIndexMap) }
        turnState = try state.turnState.map { try CompactTurnStateTransportV1(turnState: $0, roster: state.roster, rosterIndexMap: rosterIndexMap) }
    }

    func rehydratedState() throws -> CoreGameStateV1 {
        guard transportForm == CompactStateCodec.transportForm else {
            throw CompactStateTransportError.invalidPayload
        }

        var resourcesByPlayer: [String: ResourceHandV1] = [:]
        var devCardsByPlayer: [String: DevCardInventoryV1] = [:]
        var newDevCardsByPlayer: [String: DevCardInventoryV1] = [:]
        var revealedVictoryPointsByPlayer: [String: Int] = [:]
        var knightsPlayedByPlayer: [String: Int] = [:]
        var playerDisplayNamesByPlayer: [String: String] = [:]

        for (index, player) in roster.enumerated() {
            resourcesByPlayer[player] = resourcesByPlayerValue(at: index)
            devCardsByPlayer[player] = devCardsValue(at: index)
            newDevCardsByPlayer[player] = newDevCardsValue(at: index)
            revealedVictoryPointsByPlayer[player] = revealedVictoryPointsValue(at: index)
            knightsPlayedByPlayer[player] = knightsPlayedValue(at: index)
            if let displayName = playerDisplayNameValue(at: index) {
                playerDisplayNamesByPlayer[player] = displayName
            }
        }

        let gameResult: GameResultV1?
        if
            let gameResultReasonCode,
            let winnerIndices = gameResultWinnerPlayerIndices,
            let gameResultFinalScores,
            gameResultFinalScores.count == roster.count
        {
            let reason: GameEndReasonV1 = switch gameResultReasonCode {
            case 0: .victory
            case 1: .draw
            case 2: .hostEnded
            default: throw CompactStateTransportError.invalidPayload
            }
            gameResult = GameResultV1(
                reason: reason,
                winnerPlayers: try winnerIndices.map {
                    try CompactStateCodec.player(at: $0, in: roster)
                },
                endedByPlayer: try gameResultEndedByPlayerIndex.map {
                    try CompactStateCodec.player(at: $0, in: roster)
                },
                finalScoresByPlayer: Dictionary(
                    uniqueKeysWithValues: roster.enumerated().map {
                        ($0.element, gameResultFinalScores[$0.offset])
                    }
                )
            )
        } else {
            gameResult = nil
        }

        let resignedPlayers = try resignedPlayerIndices.map {
            try CompactStateCodec.player(at: $0, in: roster)
        }
        let drawVote: DrawVoteV1?
        if let drawVoteProposerIndex, let drawVoteApprovalIndices {
            drawVote = DrawVoteV1(
                proposedBy: try CompactStateCodec.player(at: drawVoteProposerIndex, in: roster),
                approvals: try drawVoteApprovalIndices.map {
                    try CompactStateCodec.player(at: $0, in: roster)
                }
            )
        } else {
            drawVote = nil
        }

        return CoreGameStateV1(
            gameId: gameId,
            rev: rev,
            prevHash: prevHash,
            stateHash: stateHash,
            roster: roster,
            currentPlayer: try CompactStateCodec.player(at: currentPlayerIndex, in: roster),
            playerDisplayNamesByPlayer: playerDisplayNamesByPlayer,
            phase: try CompactStateCodec.decodePhase(phaseCode),
            seed: seed,
            diceRngState: diceRngState,
            robberRngState: robberRngState,
            resourcesByPlayer: resourcesByPlayer,
            bankResources: bankResources.rehydrated(),
            devDeck: try devDeckCodes.map(CompactStateCodec.decodeDevCard),
            devCardsByPlayer: devCardsByPlayer,
            newDevCardsByPlayer: newDevCardsByPlayer,
            revealedVictoryPointsByPlayer: revealedVictoryPointsByPlayer,
            devCardActionPlayedThisTurn: devCardActionPlayedThisTurn,
            knightsPlayedByPlayer: knightsPlayedByPlayer,
            largestArmyOwner: try largestArmyOwnerIndex.map { try CompactStateCodec.player(at: $0, in: roster) },
            largestArmySize: largestArmySize,
            longestRoadOwner: try longestRoadOwnerIndex.map { try CompactStateCodec.player(at: $0, in: roster) },
            longestRoadLength: longestRoadLength,
            winnerPlayer: try winnerPlayerIndex.map { try CompactStateCodec.player(at: $0, in: roster) },
            winningVictoryPoints: winningVictoryPoints,
            gameResult: gameResult,
            resignedPlayers: resignedPlayers,
            drawVote: drawVote,
            hasAttemptedDrawVote: hasAttemptedDrawVote,
            auditLog: try auditLog.map { try $0.rehydrated(roster: roster) },
            lastTurnRecap: try lastTurnRecap?.rehydrated(roster: roster),
            activeTradeOffer: try activeTradeOffer?.rehydrated(roster: roster),
            tradeResponses: try tradeResponses.map { try $0.rehydrated(roster: roster) },
            settlementsByNode: try Self.rehydratedOwnershipMap(settlementsByNode, roster: roster),
            citiesByNode: try Self.rehydratedOwnershipMap(citiesByNode, roster: roster),
            roadsByEdge: try Self.rehydratedOwnershipMap(roadsByEdge, roster: roster),
            boardRules: try rehydratedBoardRules(),
            board: try rehydratedBoard(),
            setupState: try setupState?.rehydrated(roster: roster),
            turnState: try turnState?.rehydrated(roster: roster)
        )
    }

    private func resourcesByPlayerValue(at index: Int) -> ResourceHandV1 {
        guard resourcesByPlayer.indices.contains(index) else {
            return .zero
        }
        return resourcesByPlayer[index].rehydrated()
    }

    private func playerDisplayNameValue(at index: Int) -> String? {
        guard let playerDisplayNames, playerDisplayNames.indices.contains(index) else {
            return nil
        }
        return playerDisplayNames[index]
    }

    private func devCardsValue(at index: Int) -> DevCardInventoryV1 {
        guard devCardsByPlayer.indices.contains(index) else {
            return .zero
        }
        return devCardsByPlayer[index].rehydrated()
    }

    private func newDevCardsValue(at index: Int) -> DevCardInventoryV1 {
        guard newDevCardsByPlayer.indices.contains(index) else {
            return .zero
        }
        return newDevCardsByPlayer[index].rehydrated()
    }

    private func revealedVictoryPointsValue(at index: Int) -> Int {
        guard revealedVictoryPoints.indices.contains(index) else {
            return 0
        }
        return revealedVictoryPoints[index]
    }

    private func knightsPlayedValue(at index: Int) -> Int {
        guard knightsPlayed.indices.contains(index) else {
            return 0
        }
        return knightsPlayed[index]
    }

    private func rehydratedBoardRules() throws -> BoardRulesV1? {
        guard let boardStrategyCode else {
            return nil
        }
        return BoardRulesV1(strategy: try CompactStateCodec.decodeBoardStrategy(boardStrategyCode))
    }

    private func rehydratedBoard() throws -> BoardSetupV1? {
        guard let compactBoard else {
            return nil
        }
        guard let seed, let boardRules = try rehydratedBoardRules() else {
            throw CompactStateTransportError.invalidPayload
        }

        let boardSeed = SeedDeriver(masterSeed: seed).seed(for: .board)
        let generatedBoard = StandardBoardGeneratorV1.generate(boardSeed: boardSeed, rules: boardRules)

        return BoardSetupV1(
            resourcesByTile: generatedBoard.resourcesByTile,
            numbersByTile: generatedBoard.numbersByTile,
            portsByIndex: generatedBoard.portsByIndex,
            robberTile: compactBoard.robberTile,
            generator: generatedBoard.generator,
            boardHash: ""
        ).rehashed()
    }

    private static func compactOwnershipMap(
        _ ownership: [Int: String],
        rosterIndexMap: [String: Int]
    ) throws -> [CompactOwnershipEntryV1] {
        try ownership.map { key, value in
            CompactOwnershipEntryV1(
                slot: key,
                ownerIndex: try CompactStateCodec.index(for: value, in: rosterIndexMap)
            )
        }
        .sorted { $0.slot < $1.slot }
    }

    private static func rehydratedOwnershipMap(
        _ entries: [CompactOwnershipEntryV1],
        roster: [String]
    ) throws -> [Int: String] {
        var ownership: [Int: String] = [:]
        for entry in entries {
            ownership[entry.slot] = try CompactStateCodec.player(at: entry.ownerIndex, in: roster)
        }
        return ownership
    }

    enum CodingKeys: String, CodingKey {
        case transportForm = "f"
        case gameId = "g"
        case rev = "r"
        case prevHash = "p"
        case stateHash = "h"
        case roster = "o"
        case playerDisplayNames = "N"
        case currentPlayerIndex = "c"
        case phaseCode = "x"
        case seed = "s"
        case diceRngState = "d"
        case robberRngState = "z"
        case resourcesByPlayer = "u"
        case bankResources = "b"
        case devDeckCodes = "k"
        case devCardsByPlayer = "v"
        case newDevCardsByPlayer = "n"
        case revealedVictoryPoints = "q"
        case devCardActionPlayedThisTurn = "y"
        case knightsPlayed = "j"
        case largestArmyOwnerIndex = "l"
        case largestArmySize = "m"
        case longestRoadOwnerIndex = "i"
        case longestRoadLength = "t"
        case winnerPlayerIndex = "w"
        case winningVictoryPoints = "W"
        case gameResultReasonCode = "G"
        case gameResultWinnerPlayerIndices = "H"
        case gameResultEndedByPlayerIndex = "Q"
        case gameResultFinalScores = "J"
        case resignedPlayerIndices = "I"
        case drawVoteProposerIndex = "D"
        case drawVoteApprovalIndices = "V"
        case hasAttemptedDrawVote = "F"
        case auditLog = "a"
        case lastTurnRecap = "R"
        case activeTradeOffer = "A"
        case tradeResponses = "T"
        case settlementsByNode = "S"
        case citiesByNode = "C"
        case roadsByEdge = "E"
        case boardStrategyCode = "B"
        case compactBoard = "P"
        case setupState = "U"
        case turnState = "Y"
    }
}

enum CompactStateTransport {
    static func encode(_ state: CoreGameStateV1) throws -> String {
        let encoder = JSONEncoder()
        let rawData = try encoder.encode(state)
        let compactData = try encoder.encode(CompactStateTransportV1(state: state))

        let selectedData = compactData.count < rawData.count ? compactData : rawData
        guard let jsonString = String(data: selectedData, encoding: .utf8) else {
            throw CompactStateTransportError.invalidPayload
        }
        return jsonString
    }

    static func decode(_ payload: String) throws -> CoreGameStateV1 {
        let data = Data(payload.utf8)
        let decoder = JSONDecoder()

        if let compactState = try? decoder.decode(CompactStateTransportV1.self, from: data) {
            return try compactState.rehydratedState()
        }

        if let state = try? decoder.decode(CoreGameStateV1.self, from: data) {
            return state
        }

        throw CompactStateTransportError.invalidPayload
    }
}
