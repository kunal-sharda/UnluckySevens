import Foundation

public enum TurnStepV1: String, Codable, Equatable {
    case needsRoll
    case pendingDiscards
    case needsRobberMove
    case afterRoll
}

public struct DiceRollV1: Codable, Equatable {
    public let d1: Int
    public let d2: Int

    public init(d1: Int, d2: Int) {
        self.d1 = d1
        self.d2 = d2
    }
}

public struct TurnStateV1: Codable, Equatable {
    public let step: TurnStepV1
    public let lastRoll: DiceRollV1?
    public let discardRequirementsByPlayer: [String: Int]
    public let submittedDiscardsByPlayer: [String: ResourceHandV1]

    public init(
        step: TurnStepV1,
        lastRoll: DiceRollV1?,
        discardRequirementsByPlayer: [String: Int] = [:],
        submittedDiscardsByPlayer: [String: ResourceHandV1] = [:]
    ) {
        self.step = step
        self.lastRoll = lastRoll
        self.discardRequirementsByPlayer = discardRequirementsByPlayer
        self.submittedDiscardsByPlayer = submittedDiscardsByPlayer
    }

    internal func canonicalJSONValue() -> [String: Any] {
        [
            "step": step.rawValue,
            "lastRoll": lastRoll?.canonicalJSONValue() ?? NSNull(),
            "discardRequirementsByPlayer": discardRequirementsByPlayer,
            "submittedDiscardsByPlayer": submittedDiscardsByPlayer.mapValues { $0.canonicalJSONValue() },
        ]
    }
}

extension DiceRollV1 {
    internal func canonicalJSONValue() -> [String: Any] {
        [
            "d1": d1,
            "d2": d2,
        ]
    }
}
