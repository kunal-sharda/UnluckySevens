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

        switch kind {
        case .rollDice, .endTurn:
            guard discarded == nil, discardPlayer == nil, robberTileID == nil, stealVictimPlayer == nil else {
                throw DecodingError.dataCorruptedError(
                    forKey: .kind,
                    in: container,
                    debugDescription: "\(kind.rawValue) must not include stage-4.3 payload fields."
                )
            }
        case .submitDiscard:
            guard discarded != nil, discardPlayer != nil, robberTileID == nil, stealVictimPlayer == nil else {
                throw DecodingError.dataCorruptedError(
                    forKey: .kind,
                    in: container,
                    debugDescription: "submitDiscard must include discarded and discardPlayer."
                )
            }
        case .moveRobber:
            guard robberTileID != nil, discarded == nil, discardPlayer == nil, stealVictimPlayer == nil else {
                throw DecodingError.dataCorruptedError(
                    forKey: .kind,
                    in: container,
                    debugDescription: "moveRobber must include robberTileID."
                )
            }
        case .selectStealVictim:
            guard stealVictimPlayer != nil, discarded == nil, discardPlayer == nil, robberTileID == nil else {
                throw DecodingError.dataCorruptedError(
                    forKey: .kind,
                    in: container,
                    debugDescription: "selectStealVictim must include stealVictimPlayer."
                )
            }
        }
    }
}
