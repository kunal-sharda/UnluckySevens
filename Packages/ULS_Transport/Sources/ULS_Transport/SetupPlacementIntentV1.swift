import Foundation

public struct SetupPlacementIntentV1: Codable, Equatable {
    public enum Kind: String, Codable, Equatable {
        case placeSetupSettlement
        case placeSetupRoad
    }

    public let kind: Kind
    public let gameId: String
    public let anchorRev: Int
    public let anchorHash: String
    public let actor: String
    public let node: Int?
    public let edge: Int?

    public init(
        gameId: String,
        anchorRev: Int,
        anchorHash: String,
        actor: String,
        node: Int
    ) {
        kind = .placeSetupSettlement
        self.gameId = gameId
        self.anchorRev = anchorRev
        self.anchorHash = anchorHash
        self.actor = actor
        self.node = node
        edge = nil
    }

    public init(
        gameId: String,
        anchorRev: Int,
        anchorHash: String,
        actor: String,
        edge: Int
    ) {
        kind = .placeSetupRoad
        self.gameId = gameId
        self.anchorRev = anchorRev
        self.anchorHash = anchorHash
        self.actor = actor
        node = nil
        self.edge = edge
    }

    private enum CodingKeys: String, CodingKey {
        case kind
        case gameId
        case anchorRev
        case anchorHash
        case actor
        case node
        case edge
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        kind = try container.decode(Kind.self, forKey: .kind)
        gameId = try container.decode(String.self, forKey: .gameId)
        anchorRev = try container.decode(Int.self, forKey: .anchorRev)
        anchorHash = try container.decode(String.self, forKey: .anchorHash)
        actor = try container.decode(String.self, forKey: .actor)
        node = try container.decodeIfPresent(Int.self, forKey: .node)
        edge = try container.decodeIfPresent(Int.self, forKey: .edge)

        switch kind {
        case .placeSetupSettlement:
            guard node != nil, edge == nil else {
                throw DecodingError.dataCorruptedError(
                    forKey: .node,
                    in: container,
                    debugDescription: "placeSetupSettlement must include node and exclude edge."
                )
            }
        case .placeSetupRoad:
            guard edge != nil, node == nil else {
                throw DecodingError.dataCorruptedError(
                    forKey: .edge,
                    in: container,
                    debugDescription: "placeSetupRoad must include edge and exclude node."
                )
            }
        }
    }
}
