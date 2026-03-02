import Foundation

public enum TurnStepV1: String, Codable, Equatable {
    case needsRoll
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

    public init(step: TurnStepV1, lastRoll: DiceRollV1?) {
        self.step = step
        self.lastRoll = lastRoll
    }

    internal func canonicalJSONValue() -> [String: Any] {
        [
            "step": step.rawValue,
            "lastRoll": lastRoll?.canonicalJSONValue() ?? NSNull(),
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
