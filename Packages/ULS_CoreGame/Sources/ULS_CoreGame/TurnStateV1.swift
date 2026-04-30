import Foundation

public enum TurnStepV1: String, Codable, Equatable {
    case needsRoll
    case pendingDiscards
    case needsRobberMove
    case needsRobberSteal
    case afterRoll
}

public extension TurnStepV1 {
    var allowsDevCardPlay: Bool {
        switch self {
        case .needsRoll, .afterRoll:
            return true
        case .pendingDiscards, .needsRobberMove, .needsRobberSteal:
            return false
        }
    }
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
    public let eligibleStealVictims: [String]

    public init(
        step: TurnStepV1,
        lastRoll: DiceRollV1?,
        discardRequirementsByPlayer: [String: Int] = [:],
        submittedDiscardsByPlayer: [String: ResourceHandV1] = [:],
        eligibleStealVictims: [String] = []
    ) {
        self.step = step
        self.lastRoll = lastRoll
        self.discardRequirementsByPlayer = discardRequirementsByPlayer
        self.submittedDiscardsByPlayer = submittedDiscardsByPlayer
        self.eligibleStealVictims = eligibleStealVictims
    }

    internal func canonicalJSONValue() -> [String: Any] {
        [
            "step": step.rawValue,
            "lastRoll": lastRoll?.canonicalJSONValue() ?? NSNull(),
            "discardRequirementsByPlayer": discardRequirementsByPlayer,
            "submittedDiscardsByPlayer": submittedDiscardsByPlayer.mapValues { $0.canonicalJSONValue() },
            "eligibleStealVictims": eligibleStealVictims,
        ]
    }
}

func orderedPendingDiscardPlayers(
    roster: [String],
    turnState: TurnStateV1
) -> [String] {
    let submittedPlayers = Set(turnState.submittedDiscardsByPlayer.keys)
    let requiredPlayers = Set(turnState.discardRequirementsByPlayer.keys)

    var orderedPlayers = roster.filter { player in
        requiredPlayers.contains(player) && !submittedPlayers.contains(player)
    }

    let remainingPlayers = requiredPlayers
        .subtracting(orderedPlayers)
        .subtracting(submittedPlayers)
        .sorted()
    orderedPlayers.append(contentsOf: remainingPlayers)
    return orderedPlayers
}

func nextPendingDiscardPlayer(
    roster: [String],
    turnState: TurnStateV1
) -> String? {
    orderedPendingDiscardPlayers(roster: roster, turnState: turnState).first
}

extension DiceRollV1 {
    internal func canonicalJSONValue() -> [String: Any] {
        [
            "d1": d1,
            "d2": d2,
        ]
    }
}
