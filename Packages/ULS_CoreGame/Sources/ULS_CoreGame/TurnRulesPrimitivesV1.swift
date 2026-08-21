import Foundation

/// Pure rule primitives used by the reducer. Keeping these separate from action
/// orchestration makes the reducer's state transitions easier to audit without
/// sharing its decision flow with transition validation.
enum TurnRulesPrimitivesV1 {
    static func requiredDiscards(
        for resourcesByPlayer: [String: ResourceHandV1],
        players: [String]
    ) -> [String: Int] {
        var result: [String: Int] = [:]
        for player in players {
            let hand = resourcesByPlayer[player] ?? .zero
            if hand.totalCount > 7 { result[player] = hand.totalCount / 2 }
        }
        return result
    }

    static func deterministicStolenResource(from hand: ResourceHandV1, rng: inout DeterministicRNG) -> ResourceV1 {
        let pick = Int(rng.nextUInt64() % UInt64(hand.totalCount))
        let resources: [(ResourceV1, Int)] = [(.wood, hand.wood), (.brick, hand.brick), (.sheep, hand.sheep), (.wheat, hand.wheat), (.ore, hand.ore)]
        var cursor = 0
        for (resource, count) in resources {
            if pick < cursor + count { return resource }
            cursor += count
        }
        return .wood
    }

    static func canAfford(hand: ResourceHandV1, cost: ResourceHandV1) -> Bool {
        hand.wood >= cost.wood && hand.brick >= cost.brick && hand.sheep >= cost.sheep && hand.wheat >= cost.wheat && hand.ore >= cost.ore
    }

    static func isValidTradeHand(_ hand: ResourceHandV1) -> Bool {
        hand.wood >= 0 && hand.brick >= 0 && hand.sheep >= 0 && hand.wheat >= 0 && hand.ore >= 0
    }

    static func addHands(_ lhs: ResourceHandV1, _ rhs: ResourceHandV1) -> ResourceHandV1 {
        ResourceHandV1(wood: lhs.wood + rhs.wood, brick: lhs.brick + rhs.brick, sheep: lhs.sheep + rhs.sheep, wheat: lhs.wheat + rhs.wheat, ore: lhs.ore + rhs.ore)
    }

    static func subtractHands(_ lhs: ResourceHandV1, _ rhs: ResourceHandV1) -> ResourceHandV1 {
        ResourceHandV1(wood: lhs.wood - rhs.wood, brick: lhs.brick - rhs.brick, sheep: lhs.sheep - rhs.sheep, wheat: lhs.wheat - rhs.wheat, ore: lhs.ore - rhs.ore)
    }

    static func mergeDevInventories(_ lhs: DevCardInventoryV1, _ rhs: DevCardInventoryV1) -> DevCardInventoryV1 {
        DevCardInventoryV1(knight: lhs.knight + rhs.knight, monopoly: lhs.monopoly + rhs.monopoly, yearOfPlenty: lhs.yearOfPlenty + rhs.yearOfPlenty, roadBuilding: lhs.roadBuilding + rhs.roadBuilding, victoryPoint: lhs.victoryPoint + rhs.victoryPoint)
    }
}
