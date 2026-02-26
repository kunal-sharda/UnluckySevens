import Foundation

public struct JoinIntentV1: Codable, Equatable {
    public let kind: String
    public let gameId: String
    public let anchorRev: Int
    public let anchorHash: String
    public let actor: String

    public init(
        kind: String = "join",
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

    private enum CodingKeys: String, CodingKey {
        case kind
        case gameId
        case anchorRev
        case anchorHash
        case actor
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let kind = try container.decode(String.self, forKey: .kind)
        guard kind == "join" else {
            throw DecodingError.dataCorruptedError(
                forKey: .kind,
                in: container,
                debugDescription: "Unsupported intent kind."
            )
        }

        self.kind = kind
        gameId = try container.decode(String.self, forKey: .gameId)
        anchorRev = try container.decode(Int.self, forKey: .anchorRev)
        anchorHash = try container.decode(String.self, forKey: .anchorHash)
        actor = try container.decode(String.self, forKey: .actor)
    }
}
