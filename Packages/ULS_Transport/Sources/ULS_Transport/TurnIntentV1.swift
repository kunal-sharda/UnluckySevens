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

public enum TransportResourceV1: String, Codable, Equatable {
    case wood
    case brick
    case sheep
    case wheat
    case ore
}

public enum TransportDevCardPlayKindV1: String, Codable, Equatable {
    case knight
    case monopoly
    case yearOfPlenty
    case roadBuilding
    case revealVictoryPoint
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
        case declineTrade
        case counterTrade
        case executeTrade
        case maritimeTrade
        case buyDevCard
        case playDevCard
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
    public let tradeTargetPlayers: [String]?
    public let devCardPlayKind: TransportDevCardPlayKindV1?
    public let devCardResource: TransportResourceV1?
    public let devCardFirstResource: TransportResourceV1?
    public let devCardSecondResource: TransportResourceV1?
    public let devCardTileID: Int?
    public let devCardVictimPlayer: String?
    public let devCardFirstEdgeID: Int?
    public let devCardSecondEdgeID: Int?

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
        tradeTargetPlayers = nil
        devCardPlayKind = nil
        devCardResource = nil
        devCardFirstResource = nil
        devCardSecondResource = nil
        devCardTileID = nil
        devCardVictimPlayer = nil
        devCardFirstEdgeID = nil
        devCardSecondEdgeID = nil
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
        tradeTargetPlayers = nil
        devCardPlayKind = nil
        devCardResource = nil
        devCardFirstResource = nil
        devCardSecondResource = nil
        devCardTileID = nil
        devCardVictimPlayer = nil
        devCardFirstEdgeID = nil
        devCardSecondEdgeID = nil
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
        tradeTargetPlayers = nil
        devCardPlayKind = nil
        devCardResource = nil
        devCardFirstResource = nil
        devCardSecondResource = nil
        devCardTileID = nil
        devCardVictimPlayer = nil
        devCardFirstEdgeID = nil
        devCardSecondEdgeID = nil
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
        tradeTargetPlayers = nil
        devCardPlayKind = nil
        devCardResource = nil
        devCardFirstResource = nil
        devCardSecondResource = nil
        devCardTileID = nil
        devCardVictimPlayer = nil
        devCardFirstEdgeID = nil
        devCardSecondEdgeID = nil
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
        tradeTargetPlayers = nil
        devCardPlayKind = nil
        devCardResource = nil
        devCardFirstResource = nil
        devCardSecondResource = nil
        devCardTileID = nil
        devCardVictimPlayer = nil
        devCardFirstEdgeID = nil
        devCardSecondEdgeID = nil
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
        tradeTargetPlayers = nil
        devCardPlayKind = nil
        devCardResource = nil
        devCardFirstResource = nil
        devCardSecondResource = nil
        devCardTileID = nil
        devCardVictimPlayer = nil
        devCardFirstEdgeID = nil
        devCardSecondEdgeID = nil
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
        tradeTargetPlayers = nil
        devCardPlayKind = nil
        devCardResource = nil
        devCardFirstResource = nil
        devCardSecondResource = nil
        devCardTileID = nil
        devCardVictimPlayer = nil
        devCardFirstEdgeID = nil
        devCardSecondEdgeID = nil
    }

    public init(
        proposeTradeGive tradeGive: TransportResourceHandV1,
        receive tradeReceive: TransportResourceHandV1,
        targetPlayers tradeTargetPlayers: [String],
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
        self.tradeTargetPlayers = tradeTargetPlayers
        devCardPlayKind = nil
        devCardResource = nil
        devCardFirstResource = nil
        devCardSecondResource = nil
        devCardTileID = nil
        devCardVictimPlayer = nil
        devCardFirstEdgeID = nil
        devCardSecondEdgeID = nil
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
        tradeTargetPlayers = nil
        devCardPlayKind = nil
        devCardResource = nil
        devCardFirstResource = nil
        devCardSecondResource = nil
        devCardTileID = nil
        devCardVictimPlayer = nil
        devCardFirstEdgeID = nil
        devCardSecondEdgeID = nil
    }

    public init(
        declineTradePlayer tradeAcceptPlayer: String,
        offerHash tradeOfferHash: String,
        gameId: String,
        anchorRev: Int,
        anchorHash: String,
        actor: String
    ) {
        kind = .declineTrade
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
        tradeTargetPlayers = nil
        devCardPlayKind = nil
        devCardResource = nil
        devCardFirstResource = nil
        devCardSecondResource = nil
        devCardTileID = nil
        devCardVictimPlayer = nil
        devCardFirstEdgeID = nil
        devCardSecondEdgeID = nil
    }

    public init(
        counterTradePlayer tradeAcceptPlayer: String,
        offerHash tradeOfferHash: String,
        counterGive tradeGive: TransportResourceHandV1,
        receive tradeReceive: TransportResourceHandV1,
        gameId: String,
        anchorRev: Int,
        anchorHash: String,
        actor: String
    ) {
        kind = .counterTrade
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
        self.tradeAcceptPlayer = tradeAcceptPlayer
        self.tradeOfferHash = tradeOfferHash
        tradeTargetPlayers = nil
        devCardPlayKind = nil
        devCardResource = nil
        devCardFirstResource = nil
        devCardSecondResource = nil
        devCardTileID = nil
        devCardVictimPlayer = nil
        devCardFirstEdgeID = nil
        devCardSecondEdgeID = nil
    }

    public init(
        executeTradePlayer tradeAcceptPlayer: String,
        offerHash tradeOfferHash: String,
        gameId: String,
        anchorRev: Int,
        anchorHash: String,
        actor: String
    ) {
        kind = .executeTrade
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
        tradeTargetPlayers = nil
        devCardPlayKind = nil
        devCardResource = nil
        devCardFirstResource = nil
        devCardSecondResource = nil
        devCardTileID = nil
        devCardVictimPlayer = nil
        devCardFirstEdgeID = nil
        devCardSecondEdgeID = nil
    }

    public init(
        maritimeTradeGive tradeGive: TransportResourceHandV1,
        receive tradeReceive: TransportResourceHandV1,
        gameId: String,
        anchorRev: Int,
        anchorHash: String,
        actor: String
    ) {
        kind = .maritimeTrade
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
        tradeTargetPlayers = nil
        devCardPlayKind = nil
        devCardResource = nil
        devCardFirstResource = nil
        devCardSecondResource = nil
        devCardTileID = nil
        devCardVictimPlayer = nil
        devCardFirstEdgeID = nil
        devCardSecondEdgeID = nil
    }

    public init(
        playDevCardKind: TransportDevCardPlayKindV1,
        resource: TransportResourceV1? = nil,
        firstResource: TransportResourceV1? = nil,
        secondResource: TransportResourceV1? = nil,
        tileID: Int? = nil,
        victimPlayer: String? = nil,
        firstEdgeID: Int? = nil,
        secondEdgeID: Int? = nil,
        gameId: String,
        anchorRev: Int,
        anchorHash: String,
        actor: String
    ) {
        kind = .playDevCard
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
        tradeTargetPlayers = nil
        devCardPlayKind = playDevCardKind
        devCardResource = resource
        devCardFirstResource = firstResource
        devCardSecondResource = secondResource
        devCardTileID = tileID
        devCardVictimPlayer = victimPlayer
        devCardFirstEdgeID = firstEdgeID
        devCardSecondEdgeID = secondEdgeID
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
        case tradeTargetPlayers
        case devCardPlayKind
        case devCardResource
        case devCardFirstResource
        case devCardSecondResource
        case devCardTileID
        case devCardVictimPlayer
        case devCardFirstEdgeID
        case devCardSecondEdgeID
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
        tradeTargetPlayers = try container.decodeIfPresent([String].self, forKey: .tradeTargetPlayers)
        devCardPlayKind = try container.decodeIfPresent(TransportDevCardPlayKindV1.self, forKey: .devCardPlayKind)
        devCardResource = try container.decodeIfPresent(TransportResourceV1.self, forKey: .devCardResource)
        devCardFirstResource = try container.decodeIfPresent(TransportResourceV1.self, forKey: .devCardFirstResource)
        devCardSecondResource = try container.decodeIfPresent(TransportResourceV1.self, forKey: .devCardSecondResource)
        devCardTileID = try container.decodeIfPresent(Int.self, forKey: .devCardTileID)
        devCardVictimPlayer = try container.decodeIfPresent(String.self, forKey: .devCardVictimPlayer)
        devCardFirstEdgeID = try container.decodeIfPresent(Int.self, forKey: .devCardFirstEdgeID)
        devCardSecondEdgeID = try container.decodeIfPresent(Int.self, forKey: .devCardSecondEdgeID)

        switch kind {
        case .rollDice, .endTurn, .buyDevCard:
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
            guard tradeGive != nil, tradeReceive != nil, tradeTargetPlayers != nil, otherPayloadsForProposeTradeEmpty else {
                throw DecodingError.dataCorruptedError(
                    forKey: .kind,
                    in: container,
                    debugDescription: "proposeTrade must include tradeGive, tradeReceive, and tradeTargetPlayers."
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
        case .declineTrade:
            guard tradeAcceptPlayer != nil, tradeOfferHash != nil, otherPayloadsForAcceptTradeEmpty else {
                throw DecodingError.dataCorruptedError(
                    forKey: .kind,
                    in: container,
                    debugDescription: "declineTrade must include tradeAcceptPlayer and tradeOfferHash."
                )
            }
        case .counterTrade:
            guard tradeAcceptPlayer != nil, tradeOfferHash != nil, tradeGive != nil, tradeReceive != nil, otherPayloadsForCounterTradeEmpty else {
                throw DecodingError.dataCorruptedError(
                    forKey: .kind,
                    in: container,
                    debugDescription: "counterTrade must include tradeAcceptPlayer, tradeOfferHash, tradeGive, and tradeReceive."
                )
            }
        case .executeTrade:
            guard tradeAcceptPlayer != nil, tradeOfferHash != nil, otherPayloadsForAcceptTradeEmpty else {
                throw DecodingError.dataCorruptedError(
                    forKey: .kind,
                    in: container,
                    debugDescription: "executeTrade must include tradeAcceptPlayer and tradeOfferHash."
                )
            }
        case .maritimeTrade:
            guard tradeGive != nil, tradeReceive != nil, otherPayloadsForProposeTradeEmpty else {
                throw DecodingError.dataCorruptedError(
                    forKey: .kind,
                    in: container,
                    debugDescription: "maritimeTrade must include tradeGive and tradeReceive."
                )
            }
        case .playDevCard:
            guard discarded == nil,
                  discardPlayer == nil,
                  robberTileID == nil,
                  stealVictimPlayer == nil,
                  buildEdgeID == nil,
                  buildNodeID == nil,
                  tradeGive == nil,
                  tradeReceive == nil,
                  tradeAcceptPlayer == nil,
                  tradeOfferHash == nil,
                  tradeTargetPlayers == nil
            else {
                throw DecodingError.dataCorruptedError(
                    forKey: .kind,
                    in: container,
                    debugDescription: "playDevCard does not allow non-dev payload fields."
                )
            }
            guard let playKind = devCardPlayKind else {
                throw DecodingError.dataCorruptedError(
                    forKey: .kind,
                    in: container,
                    debugDescription: "playDevCard must include devCardPlayKind."
                )
            }
            switch playKind {
            case .knight:
                guard devCardTileID != nil,
                      devCardResource == nil,
                      devCardFirstResource == nil,
                      devCardSecondResource == nil,
                      devCardFirstEdgeID == nil,
                      devCardSecondEdgeID == nil
                else {
                    throw DecodingError.dataCorruptedError(
                        forKey: .kind,
                        in: container,
                        debugDescription: "Knight payload must include tile and optional victim only."
                    )
                }
            case .monopoly:
                guard devCardResource != nil,
                      devCardTileID == nil,
                      devCardVictimPlayer == nil,
                      devCardFirstResource == nil,
                      devCardSecondResource == nil,
                      devCardFirstEdgeID == nil,
                      devCardSecondEdgeID == nil
                else {
                    throw DecodingError.dataCorruptedError(
                        forKey: .kind,
                        in: container,
                        debugDescription: "Monopoly payload must include resource only."
                    )
                }
            case .yearOfPlenty:
                guard devCardFirstResource != nil,
                      devCardSecondResource != nil,
                      devCardTileID == nil,
                      devCardVictimPlayer == nil,
                      devCardResource == nil,
                      devCardFirstEdgeID == nil,
                      devCardSecondEdgeID == nil
                else {
                    throw DecodingError.dataCorruptedError(
                        forKey: .kind,
                        in: container,
                        debugDescription: "Year of Plenty payload must include first and second resources."
                    )
                }
            case .roadBuilding:
                guard devCardFirstEdgeID != nil,
                      devCardSecondEdgeID != nil,
                      devCardTileID == nil,
                      devCardVictimPlayer == nil,
                      devCardResource == nil,
                      devCardFirstResource == nil,
                      devCardSecondResource == nil
                else {
                    throw DecodingError.dataCorruptedError(
                        forKey: .kind,
                        in: container,
                        debugDescription: "Road Building payload must include first and second edges."
                    )
                }
            case .revealVictoryPoint:
                guard devCardTileID == nil,
                      devCardVictimPlayer == nil,
                      devCardResource == nil,
                      devCardFirstResource == nil,
                      devCardSecondResource == nil,
                      devCardFirstEdgeID == nil,
                      devCardSecondEdgeID == nil
                else {
                    throw DecodingError.dataCorruptedError(
                        forKey: .kind,
                        in: container,
                        debugDescription: "Reveal VP payload must not include additional fields."
                    )
                }
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
            tradeOfferHash == nil &&
            tradeTargetPlayers == nil &&
            devCardPlayKind == nil &&
            devCardResource == nil &&
            devCardFirstResource == nil &&
            devCardSecondResource == nil &&
            devCardTileID == nil &&
            devCardVictimPlayer == nil &&
            devCardFirstEdgeID == nil &&
            devCardSecondEdgeID == nil
    }

    private var otherPayloadsForDiscardEmpty: Bool {
        robberTileID == nil &&
            stealVictimPlayer == nil &&
            buildEdgeID == nil &&
            buildNodeID == nil &&
            tradeGive == nil &&
            tradeReceive == nil &&
            tradeAcceptPlayer == nil &&
            tradeOfferHash == nil &&
            tradeTargetPlayers == nil &&
            devCardPlayKind == nil &&
            devCardResource == nil &&
            devCardFirstResource == nil &&
            devCardSecondResource == nil &&
            devCardTileID == nil &&
            devCardVictimPlayer == nil &&
            devCardFirstEdgeID == nil &&
            devCardSecondEdgeID == nil
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
            tradeOfferHash == nil &&
            tradeTargetPlayers == nil &&
            devCardPlayKind == nil &&
            devCardResource == nil &&
            devCardFirstResource == nil &&
            devCardSecondResource == nil &&
            devCardTileID == nil &&
            devCardVictimPlayer == nil &&
            devCardFirstEdgeID == nil &&
            devCardSecondEdgeID == nil
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
            tradeOfferHash == nil &&
            tradeTargetPlayers == nil &&
            devCardPlayKind == nil &&
            devCardResource == nil &&
            devCardFirstResource == nil &&
            devCardSecondResource == nil &&
            devCardTileID == nil &&
            devCardVictimPlayer == nil &&
            devCardFirstEdgeID == nil &&
            devCardSecondEdgeID == nil
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
            tradeOfferHash == nil &&
            tradeTargetPlayers == nil &&
            devCardPlayKind == nil &&
            devCardResource == nil &&
            devCardFirstResource == nil &&
            devCardSecondResource == nil &&
            devCardTileID == nil &&
            devCardVictimPlayer == nil &&
            devCardFirstEdgeID == nil &&
            devCardSecondEdgeID == nil
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
            tradeOfferHash == nil &&
            tradeTargetPlayers == nil &&
            devCardPlayKind == nil &&
            devCardResource == nil &&
            devCardFirstResource == nil &&
            devCardSecondResource == nil &&
            devCardTileID == nil &&
            devCardVictimPlayer == nil &&
            devCardFirstEdgeID == nil &&
            devCardSecondEdgeID == nil
    }

    private var otherPayloadsForProposeTradeEmpty: Bool {
        discarded == nil &&
            discardPlayer == nil &&
            robberTileID == nil &&
            stealVictimPlayer == nil &&
            buildEdgeID == nil &&
            buildNodeID == nil &&
            tradeAcceptPlayer == nil &&
            tradeOfferHash == nil &&
            devCardPlayKind == nil &&
            devCardResource == nil &&
            devCardFirstResource == nil &&
            devCardSecondResource == nil &&
            devCardTileID == nil &&
            devCardVictimPlayer == nil &&
            devCardFirstEdgeID == nil &&
            devCardSecondEdgeID == nil
    }

    private var otherPayloadsForAcceptTradeEmpty: Bool {
        discarded == nil &&
            discardPlayer == nil &&
            robberTileID == nil &&
            stealVictimPlayer == nil &&
            buildEdgeID == nil &&
            buildNodeID == nil &&
            tradeGive == nil &&
            tradeReceive == nil &&
            tradeTargetPlayers == nil &&
            devCardPlayKind == nil &&
            devCardResource == nil &&
            devCardFirstResource == nil &&
            devCardSecondResource == nil &&
            devCardTileID == nil &&
            devCardVictimPlayer == nil &&
            devCardFirstEdgeID == nil &&
            devCardSecondEdgeID == nil
    }

    private var otherPayloadsForCounterTradeEmpty: Bool {
        discarded == nil &&
            discardPlayer == nil &&
            robberTileID == nil &&
            stealVictimPlayer == nil &&
            buildEdgeID == nil &&
            buildNodeID == nil &&
            tradeTargetPlayers == nil &&
            devCardPlayKind == nil &&
            devCardResource == nil &&
            devCardFirstResource == nil &&
            devCardSecondResource == nil &&
            devCardTileID == nil &&
            devCardVictimPlayer == nil &&
            devCardFirstEdgeID == nil &&
            devCardSecondEdgeID == nil
    }
}
