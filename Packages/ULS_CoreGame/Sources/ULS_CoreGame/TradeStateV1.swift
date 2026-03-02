import CryptoKit
import Foundation

public struct TradeOfferV1: Codable, Equatable {
    public let offerHash: String
    public let proposer: String
    public let give: ResourceHandV1
    public let receive: ResourceHandV1
    public let createdRev: Int

    public init(
        offerHash: String,
        proposer: String,
        give: ResourceHandV1,
        receive: ResourceHandV1,
        createdRev: Int
    ) {
        self.offerHash = offerHash
        self.proposer = proposer
        self.give = give
        self.receive = receive
        self.createdRev = createdRev
    }

    internal func canonicalJSONValue() -> [String: Any] {
        [
            "offerHash": offerHash,
            "proposer": proposer,
            "give": give.canonicalJSONValue(),
            "receive": receive.canonicalJSONValue(),
            "createdRev": createdRev,
        ]
    }
}

public struct TradeAcceptV1: Codable, Equatable {
    public let acceptingPlayer: String
    public let offerHash: String
    public let acceptedAtRev: Int

    public init(
        acceptingPlayer: String,
        offerHash: String,
        acceptedAtRev: Int
    ) {
        self.acceptingPlayer = acceptingPlayer
        self.offerHash = offerHash
        self.acceptedAtRev = acceptedAtRev
    }

    internal func canonicalJSONValue() -> [String: Any] {
        [
            "acceptingPlayer": acceptingPlayer,
            "offerHash": offerHash,
            "acceptedAtRev": acceptedAtRev,
        ]
    }
}

internal func deterministicTradeOfferHash(
    gameId: String,
    proposer: String,
    give: ResourceHandV1,
    receive: ResourceHandV1,
    anchorRev: Int,
    anchorHash: String
) -> String {
    let payload: [String: Any] = [
        "gameId": gameId,
        "proposer": proposer,
        "give": give.canonicalJSONValue(),
        "receive": receive.canonicalJSONValue(),
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
