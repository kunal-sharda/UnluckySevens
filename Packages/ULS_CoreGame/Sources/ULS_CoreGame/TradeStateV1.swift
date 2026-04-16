import CryptoKit
import Foundation

public struct TradeOfferV1: Codable, Equatable {
    public let offerHash: String
    public let proposer: String
    public let give: ResourceHandV1
    public let receive: ResourceHandV1
    public let recipients: [String]
    public let createdRev: Int

    public init(
        offerHash: String,
        proposer: String,
        give: ResourceHandV1,
        receive: ResourceHandV1,
        recipients: [String],
        createdRev: Int
    ) {
        self.offerHash = offerHash
        self.proposer = proposer
        self.give = give
        self.receive = receive
        self.recipients = Array(Set(recipients)).sorted()
        self.createdRev = createdRev
    }

    internal func canonicalJSONValue() -> [String: Any] {
        [
            "offerHash": offerHash,
            "proposer": proposer,
            "give": give.canonicalJSONValue(),
            "receive": receive.canonicalJSONValue(),
            "recipients": recipients,
            "createdRev": createdRev,
        ]
    }
}

public enum TradeResponseKindV1: String, Codable, Equatable {
    case accept
    case decline
    case counter
}

public struct TradeResponseV1: Codable, Equatable {
    public let respondingPlayer: String
    public let offerHash: String
    public let kind: TradeResponseKindV1
    public let respondedAtRev: Int
    public let counterGive: ResourceHandV1?
    public let counterReceive: ResourceHandV1?

    public init(
        respondingPlayer: String,
        offerHash: String,
        kind: TradeResponseKindV1,
        respondedAtRev: Int,
        counterGive: ResourceHandV1? = nil,
        counterReceive: ResourceHandV1? = nil
    ) {
        self.respondingPlayer = respondingPlayer
        self.offerHash = offerHash
        self.kind = kind
        self.respondedAtRev = respondedAtRev
        self.counterGive = counterGive
        self.counterReceive = counterReceive
    }

    internal func canonicalJSONValue() -> [String: Any] {
        [
            "respondingPlayer": respondingPlayer,
            "offerHash": offerHash,
            "kind": kind.rawValue,
            "respondedAtRev": respondedAtRev,
            "counterGive": counterGive?.canonicalJSONValue() ?? NSNull(),
            "counterReceive": counterReceive?.canonicalJSONValue() ?? NSNull(),
        ]
    }
}

internal func deterministicTradeOfferHash(
    gameId: String,
    proposer: String,
    give: ResourceHandV1,
    receive: ResourceHandV1,
    recipients: [String],
    anchorRev: Int,
    anchorHash: String
) -> String {
    let payload: [String: Any] = [
        "gameId": gameId,
        "proposer": proposer,
        "give": give.canonicalJSONValue(),
        "receive": receive.canonicalJSONValue(),
        "recipients": Array(Set(recipients)).sorted(),
        "anchorRev": anchorRev,
        "anchorHash": anchorHash,
    ]
    guard JSONSerialization.isValidJSONObject(payload),
          let data = try? JSONSerialization.data(withJSONObject: payload, options: [.sortedKeys]) else {
        preconditionFailure("Trade offer hash payload must be JSON serializable.")
    }
    let digest = SHA256.hash(data: data)
    return digest.map { String(format: "%02x", $0) }.joined()
}
