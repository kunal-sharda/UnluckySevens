import CryptoKit
import Foundation

public enum BoardGenStrategyV1: String, Codable, Equatable {
    case randomV1
    case noRedAdjacentV1
}

public struct BoardRulesV1: Codable, Equatable {
    public let strategy: BoardGenStrategyV1

    public init(strategy: BoardGenStrategyV1 = .randomV1) {
        self.strategy = strategy
    }
}

public struct BoardSetupV1: Codable, Equatable {
    public let resourcesByTile: [ResourceV1]
    public let numbersByTile: [Int?]
    public let portsByIndex: [PortKindV1]
    public let robberTile: Int
    public let generator: BoardGenStrategyV1
    public let boardHash: String

    public init(
        resourcesByTile: [ResourceV1],
        numbersByTile: [Int?],
        portsByIndex: [PortKindV1],
        robberTile: Int,
        generator: BoardGenStrategyV1,
        boardHash: String
    ) {
        self.resourcesByTile = resourcesByTile
        self.numbersByTile = numbersByTile
        self.portsByIndex = portsByIndex
        self.robberTile = robberTile
        self.generator = generator
        self.boardHash = boardHash
    }

    public func rehashed() -> BoardSetupV1 {
        BoardSetupV1(
            resourcesByTile: resourcesByTile,
            numbersByTile: numbersByTile,
            portsByIndex: portsByIndex,
            robberTile: robberTile,
            generator: generator,
            boardHash: canonicalBoardHash()
        )
    }

    public func canonicalBoardHash() -> String {
        let payload = canonicalHashPayload()
        guard JSONSerialization.isValidJSONObject(payload),
              let canonicalData = try? JSONSerialization.data(withJSONObject: payload, options: [.sortedKeys]) else {
            preconditionFailure("BoardSetupV1 canonical payload must be JSON-serializable.")
        }

        let digest = SHA256.hash(data: canonicalData)
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    internal func canonicalJSONIncludingHash() -> [String: Any] {
        var payload = canonicalHashPayload()
        payload["boardHash"] = boardHash
        return payload
    }

    private func canonicalHashPayload() -> [String: Any] {
        [
            "resourcesByTile": resourcesByTile.map(\.rawValue),
            "numbersByTile": numbersByTile.map { value in
                value.map { $0 as Any } ?? NSNull()
            },
            "portsByIndex": portsByIndex.map(\.canonicalJSONValue),
            "robberTile": robberTile,
            "generator": generator.rawValue,
        ]
    }
}

extension BoardRulesV1 {
    internal func canonicalJSONValue() -> [String: Any] {
        ["strategy": strategy.rawValue]
    }
}

extension PortKindV1 {
    internal var canonicalJSONValue: [String: Any] {
        switch self {
        case .threeToOne:
            return ["kind": "threeToOne"]
        case let .twoToOne(resource):
            return ["kind": "twoToOne", "resource": resource.rawValue]
        }
    }
}
