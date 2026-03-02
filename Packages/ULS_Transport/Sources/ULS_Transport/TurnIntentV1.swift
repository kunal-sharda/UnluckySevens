import Foundation

public struct TurnIntentV1: Codable, Equatable {
    public enum Kind: String, Codable, Equatable {
        case rollDice
        case endTurn
    }

    public let kind: Kind
    public let gameId: String
    public let anchorRev: Int
    public let anchorHash: String
    public let actor: String

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
    }
}
