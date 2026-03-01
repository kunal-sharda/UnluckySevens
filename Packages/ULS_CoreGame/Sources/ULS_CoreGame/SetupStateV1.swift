import Foundation

public enum SetupStepV1: String, Codable, Equatable {
    case placeSettlement
    case placeRoad
    case done
}

public struct PlayerSetupPlacementsV1: Codable, Equatable {
    public let settlement1: NodeID?
    public let road1: EdgeID?
    public let settlement2: NodeID?
    public let road2: EdgeID?

    public init(
        settlement1: NodeID? = nil,
        road1: EdgeID? = nil,
        settlement2: NodeID? = nil,
        road2: EdgeID? = nil
    ) {
        self.settlement1 = settlement1
        self.road1 = road1
        self.settlement2 = settlement2
        self.road2 = road2
    }

    internal func canonicalJSONValue() -> [String: Any] {
        [
            "settlement1": settlement1 ?? NSNull(),
            "road1": road1 ?? NSNull(),
            "settlement2": settlement2 ?? NSNull(),
            "road2": road2 ?? NSNull(),
        ]
    }
}

public struct SetupStateV1: Codable, Equatable {
    public let order: [String]
    public let turnIndex: Int
    public let step: SetupStepV1
    public let placements: [String: PlayerSetupPlacementsV1]
    public let lastPlacedSettlementNode: Int?

    public init(
        order: [String],
        turnIndex: Int,
        step: SetupStepV1,
        placements: [String: PlayerSetupPlacementsV1],
        lastPlacedSettlementNode: Int?
    ) {
        self.order = order
        self.turnIndex = turnIndex
        self.step = step
        self.placements = placements
        self.lastPlacedSettlementNode = lastPlacedSettlementNode
    }

    internal func canonicalJSONValue() -> [String: Any] {
        [
            "order": order,
            "turnIndex": turnIndex,
            "step": step.rawValue,
            "placements": placements.mapValues { $0.canonicalJSONValue() },
            "lastPlacedSettlementNode": lastPlacedSettlementNode ?? NSNull(),
        ]
    }
}

public func makeSetupOrder(roster: [String]) -> [String] {
    roster + roster.reversed()
}

public func initializeSetupState(roster: [String]) -> SetupStateV1 {
    SetupStateV1(
        order: makeSetupOrder(roster: roster),
        turnIndex: 0,
        step: .placeSettlement,
        placements: [:],
        lastPlacedSettlementNode: nil
    )
}
