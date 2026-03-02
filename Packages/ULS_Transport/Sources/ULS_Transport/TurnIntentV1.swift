import Foundation

public struct TransportResourceHandV1: Codable, Equatable {
    public let wood: Int
    public let brick: Int
    public let sheep: Int
    public let wheat: Int
    public let ore: Int

    public init(wood: Int = 0, brick: Int = 0, sheep: Int = 0, wheat: Int = 0, ore: Int = 0) {
        self.wood = wood
        self.brick = brick
        self.sheep = sheep
        self.wheat = wheat
        self.ore = ore
    }
}

public struct TurnIntentV1: Codable, Equatable {
    public enum Kind: String, Codable, Equatable {
        case rollDice
        case submitDiscard
        case moveRobber
        case selectStealVictim
        case buildRoad
        case buildSettlement
        case buildCity
        case proposeTrade
        case acceptTrade
        case endTurn
    }

    public let kind: Kind
    public let gameId: String
    public let anchorRev: Int
    public let anchorHash: String
    public let actor: String
    public let discarded: TransportResourceHandV1?
    public let discardPlayer: String?
    public let robberTileID: Int?
    public let stealVictimPlayer: String?
    public let buildEdgeID: Int?
    public let buildNodeID: Int?
    public let tradeGive: TransportResourceHandV1?
    public let tradeReceive: TransportResourceHandV1?
    public let tradeAcceptPlayer: String?
    public let tradeOfferHash: String?

    public init(
        kind: Kind,
        gameId: String,
        anchorRev: Int,
        anchorHash: String,
        actor: String
    ) {
        self.kind = kind
        self.gameId = gameId
        self.anchorRev = anchorRev
        self.anchorHash = anchorHash
        self.actor = actor
        discarded = nil
        discardPlayer = nil
        robberTileID = nil
        stealVictimPlayer = nil
        buildEdgeID = nil
        buildNodeID = nil
        tradeGive = nil
        tradeReceive = nil
        tradeAcceptPlayer = nil
        tradeOfferHash = nil
    }

    public init(
        submitDiscardFor discardPlayer: String,
        discarded: TransportResourceHandV1,
        gameId: String,
        anchorRev: Int,
        anchorHash: String,
        actor: String
    ) {
        kind = .submitDiscard
        self.gameId = gameId
        self.anchorRev = anchorRev
        self.anchorHash = anchorHash
        self.actor = actor
        self.discarded = discarded
        self.discardPlayer = discardPlayer
        robberTileID = nil
        stealVictimPlayer = nil
        buildEdgeID = nil
        buildNodeID = nil
        tradeGive = nil
        tradeReceive = nil
        tradeAcceptPlayer = nil
        tradeOfferHash = nil
    }

    public init(
        moveRobberTileID robberTileID: Int,
        gameId: String,
        anchorRev: Int,
        anchorHash: String,
        actor: String
    ) {
        kind = .moveRobber
        self.gameId = gameId
        self.anchorRev = anchorRev
        self.anchorHash = anchorHash
        self.actor = actor
        discarded = nil
        discardPlayer = nil
        self.robberTileID = robberTileID
        stealVictimPlayer = nil
        buildEdgeID = nil
        buildNodeID = nil
        tradeGive = nil
        tradeReceive = nil
        tradeAcceptPlayer = nil
        tradeOfferHash = nil
    }

    public init(
        selectStealVictimPlayer stealVictimPlayer: String,
        gameId: String,
        anchorRev: Int,
        anchorHash: String,
        actor: String
    ) {
        kind = .selectStealVictim
        self.gameId = gameId
        self.anchorRev = anchorRev
        self.anchorHash = anchorHash
        self.actor = actor
        discarded = nil
        discardPlayer = nil
        robberTileID = nil
        self.stealVictimPlayer = stealVictimPlayer
        buildEdgeID = nil
        buildNodeID = nil
        tradeGive = nil
        tradeReceive = nil
        tradeAcceptPlayer = nil
        tradeOfferHash = nil
    }

    public init(
        buildRoadEdgeID buildEdgeID: Int,
        gameId: String,
        anchorRev: Int,
        anchorHash: String,
        actor: String
    ) {
        kind = .buildRoad
        self.gameId = gameId
        self.anchorRev = anchorRev
        self.anchorHash = anchorHash
        self.actor = actor
        discarded = nil
        discardPlayer = nil
        robberTileID = nil
        stealVictimPlayer = nil
        self.buildEdgeID = buildEdgeID
        buildNodeID = nil
        tradeGive = nil
        tradeReceive = nil
        tradeAcceptPlayer = nil
        tradeOfferHash = nil
    }

    public init(
        buildSettlementNodeID buildNodeID: Int,
        gameId: String,
        anchorRev: Int,
        anchorHash: String,
        actor: String
    ) {
        kind = .buildSettlement
        self.gameId = gameId
        self.anchorRev = anchorRev
        self.anchorHash = anchorHash
        self.actor = actor
        discarded = nil
        discardPlayer = nil
        robberTileID = nil
        stealVictimPlayer = nil
        buildEdgeID = nil
        self.buildNodeID = buildNodeID
        tradeGive = nil
        tradeReceive = nil
        tradeAcceptPlayer = nil
        tradeOfferHash = nil
    }

    public init(
        buildCityNodeID buildNodeID: Int,
        gameId: String,
        anchorRev: Int,
        anchorHash: String,
        actor: String
    ) {
        kind = .buildCity
        self.gameId = gameId
        self.anchorRev = anchorRev
        self.anchorHash = anchorHash
        self.actor = actor
        discarded = nil
        discardPlayer = nil
        robberTileID = nil
        stealVictimPlayer = nil
        buildEdgeID = nil
        self.buildNodeID = buildNodeID
        tradeGive = nil
        tradeReceive = nil
        tradeAcceptPlayer = nil
        tradeOfferHash = nil
    }

    public init(
        proposeTradeGive tradeGive: TransportResourceHandV1,
        receive tradeReceive: TransportResourceHandV1,
        gameId: String,
        anchorRev: Int,
        anchorHash: String,
        actor: String
    ) {
        kind = .proposeTrade
        self.gameId = gameId
        self.anchorRev = anchorRev
        self.anchorHash = anchorHash
        self.actor = actor
        discarded = nil
        discardPlayer = nil
        robberTileID = nil
        stealVictimPlayer = nil
        buildEdgeID = nil
        buildNodeID = nil
        self.tradeGive = tradeGive
        self.tradeReceive = tradeReceive
        tradeAcceptPlayer = nil
        tradeOfferHash = nil
    }

    public init(
        acceptTradePlayer tradeAcceptPlayer: String,
        offerHash tradeOfferHash: String,
        gameId: String,
        anchorRev: Int,
        anchorHash: String,
        actor: String
    ) {
        kind = .acceptTrade
        self.gameId = gameId
        self.anchorRev = anchorRev
        self.anchorHash = anchorHash
        self.actor = actor
        discarded = nil
        discardPlayer = nil
        robberTileID = nil
        stealVictimPlayer = nil
        buildEdgeID = nil
        buildNodeID = nil
        tradeGive = nil
        tradeReceive = nil
        self.tradeAcceptPlayer = tradeAcceptPlayer
        self.tradeOfferHash = tradeOfferHash
    }

    private enum CodingKeys: String, CodingKey {
        case kind
        case gameId
        case anchorRev
        case anchorHash
        case actor
        case discarded
        case discardPlayer
        case robberTileID
        case stealVictimPlayer
        case buildEdgeID
        case buildNodeID
        case tradeGive
        case tradeReceive
        case tradeAcceptPlayer
        case tradeOfferHash
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        kind = try container.decode(Kind.self, forKey: .kind)
        gameId = try container.decode(String.self, forKey: .gameId)
        anchorRev = try container.decode(Int.self, forKey: .anchorRev)
        anchorHash = try container.decode(String.self, forKey: .anchorHash)
        actor = try container.decode(String.self, forKey: .actor)
        discarded = try container.decodeIfPresent(TransportResourceHandV1.self, forKey: .discarded)
        discardPlayer = try container.decodeIfPresent(String.self, forKey: .discardPlayer)
        robberTileID = try container.decodeIfPresent(Int.self, forKey: .robberTileID)
        stealVictimPlayer = try container.decodeIfPresent(String.self, forKey: .stealVictimPlayer)
        buildEdgeID = try container.decodeIfPresent(Int.self, forKey: .buildEdgeID)
        buildNodeID = try container.decodeIfPresent(Int.self, forKey: .buildNodeID)
        tradeGive = try container.decodeIfPresent(TransportResourceHandV1.self, forKey: .tradeGive)
        tradeReceive = try container.decodeIfPresent(TransportResourceHandV1.self, forKey: .tradeReceive)
        tradeAcceptPlayer = try container.decodeIfPresent(String.self, forKey: .tradeAcceptPlayer)
        tradeOfferHash = try container.decodeIfPresent(String.self, forKey: .tradeOfferHash)

        switch kind {
        case .rollDice, .endTurn:
            guard allOptionalPayloadsEmpty else {
                throw DecodingError.dataCorruptedError(
                    forKey: .kind,
                    in: container,
                    debugDescription: "\(kind.rawValue) must not include additional payload fields."
                )
            }
        case .submitDiscard:
            guard discarded != nil, discardPlayer != nil, otherPayloadsForDiscardEmpty else {
                throw DecodingError.dataCorruptedError(
                    forKey: .kind,
                    in: container,
                    debugDescription: "submitDiscard must include discarded and discardPlayer."
                )
            }
        case .moveRobber:
            guard robberTileID != nil, otherPayloadsForMoveRobberEmpty else {
                throw DecodingError.dataCorruptedError(
                    forKey: .kind,
                    in: container,
                    debugDescription: "moveRobber must include robberTileID."
                )
            }
        case .selectStealVictim:
            guard stealVictimPlayer != nil, otherPayloadsForStealVictimEmpty else {
                throw DecodingError.dataCorruptedError(
                    forKey: .kind,
                    in: container,
                    debugDescription: "selectStealVictim must include stealVictimPlayer."
                )
            }
        case .buildRoad:
            guard buildEdgeID != nil, otherPayloadsForBuildRoadEmpty else {
                throw DecodingError.dataCorruptedError(
                    forKey: .kind,
                    in: container,
                    debugDescription: "buildRoad must include buildEdgeID."
                )
            }
        case .buildSettlement:
            guard buildNodeID != nil, otherPayloadsForBuildNodeEmpty else {
                throw DecodingError.dataCorruptedError(
                    forKey: .kind,
                    in: container,
                    debugDescription: "buildSettlement must include buildNodeID."
                )
            }
        case .buildCity:
            guard buildNodeID != nil, otherPayloadsForBuildNodeEmpty else {
                throw DecodingError.dataCorruptedError(
                    forKey: .kind,
                    in: container,
                    debugDescription: "buildCity must include buildNodeID."
                )
            }
        case .proposeTrade:
            guard tradeGive != nil, tradeReceive != nil, otherPayloadsForProposeTradeEmpty else {
                throw DecodingError.dataCorruptedError(
                    forKey: .kind,
                    in: container,
                    debugDescription: "proposeTrade must include tradeGive and tradeReceive."
                )
            }
        case .acceptTrade:
            guard tradeAcceptPlayer != nil, tradeOfferHash != nil, otherPayloadsForAcceptTradeEmpty else {
                throw DecodingError.dataCorruptedError(
                    forKey: .kind,
                    in: container,
                    debugDescription: "acceptTrade must include tradeAcceptPlayer and tradeOfferHash."
                )
            }
        }
    }

    private var allOptionalPayloadsEmpty: Bool {
        discarded == nil &&
            discardPlayer == nil &&
            robberTileID == nil &&
            stealVictimPlayer == nil &&
            buildEdgeID == nil &&
            buildNodeID == nil &&
            tradeGive == nil &&
            tradeReceive == nil &&
            tradeAcceptPlayer == nil &&
            tradeOfferHash == nil
    }

    private var otherPayloadsForDiscardEmpty: Bool {
        robberTileID == nil &&
            stealVictimPlayer == nil &&
            buildEdgeID == nil &&
            buildNodeID == nil &&
            tradeGive == nil &&
            tradeReceive == nil &&
            tradeAcceptPlayer == nil &&
            tradeOfferHash == nil
    }

    private var otherPayloadsForMoveRobberEmpty: Bool {
        discarded == nil &&
            discardPlayer == nil &&
            stealVictimPlayer == nil &&
            buildEdgeID == nil &&
            buildNodeID == nil &&
            tradeGive == nil &&
            tradeReceive == nil &&
            tradeAcceptPlayer == nil &&
            tradeOfferHash == nil
    }

    private var otherPayloadsForStealVictimEmpty: Bool {
        discarded == nil &&
            discardPlayer == nil &&
            robberTileID == nil &&
            buildEdgeID == nil &&
            buildNodeID == nil &&
            tradeGive == nil &&
            tradeReceive == nil &&
            tradeAcceptPlayer == nil &&
            tradeOfferHash == nil
    }

    private var otherPayloadsForBuildRoadEmpty: Bool {
        discarded == nil &&
            discardPlayer == nil &&
            robberTileID == nil &&
            stealVictimPlayer == nil &&
            buildNodeID == nil &&
            tradeGive == nil &&
            tradeReceive == nil &&
            tradeAcceptPlayer == nil &&
            tradeOfferHash == nil
    }

    private var otherPayloadsForBuildNodeEmpty: Bool {
        discarded == nil &&
            discardPlayer == nil &&
            robberTileID == nil &&
            stealVictimPlayer == nil &&
            buildEdgeID == nil &&
            tradeGive == nil &&
            tradeReceive == nil &&
            tradeAcceptPlayer == nil &&
            tradeOfferHash == nil
    }

    private var otherPayloadsForProposeTradeEmpty: Bool {
        discarded == nil &&
            discardPlayer == nil &&
            robberTileID == nil &&
            stealVictimPlayer == nil &&
            buildEdgeID == nil &&
            buildNodeID == nil &&
            tradeAcceptPlayer == nil &&
            tradeOfferHash == nil
    }

    private var otherPayloadsForAcceptTradeEmpty: Bool {
        discarded == nil &&
            discardPlayer == nil &&
            robberTileID == nil &&
            stealVictimPlayer == nil &&
            buildEdgeID == nil &&
            buildNodeID == nil &&
            tradeGive == nil &&
            tradeReceive == nil
    }
}
