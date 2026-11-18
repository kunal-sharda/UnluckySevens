import Foundation

public struct ProductionReceiptV1: Codable, Equatable {
    public let revision: Int
    public let roller: String
    public let roll: DiceRollV1
    public let gains: ResourceHandV1
    public let blockedByRobber: Bool
    public let bankShortage: Bool
}

public extension CoreGameStateV1 {
    /// Attributes only a verified roll transition. Never interprets trade, steal or discard deltas as production.
    func productionReceipt(from previous: CoreGameStateV1, for viewer: String) -> ProductionReceiptV1? {
        guard previous.roster.contains(viewer), !previous.resignedPlayers.contains(viewer),
              previous.gameId == gameId, rev == previous.rev + 1,
              previous.turnState?.step == .needsRoll,
              let expected = try? apply(intent: .rollDice, to: previous, actor: previous.currentPlayer),
              expected == self, let roll = turnState?.lastRoll else { return nil }
        let total = roll.d1 + roll.d2
        let before = previous.resourcesByPlayer[viewer] ?? .zero
        let after = resourcesByPlayer[viewer] ?? .zero
        let resources: [ResourceV1] = [.wood, .brick, .sheep, .wheat, .ore]
        var gains = ResourceHandV1.zero
        for resource in resources {
            gains = gains.adding(max(0, after.count(for: resource) - before.count(for: resource)), for: resource)
        }
        guard total != 7, let board = previous.board else {
            return ProductionReceiptV1(revision: rev, roller: previous.currentPlayer, roll: roll, gains: .zero,
                                       blockedByRobber: false, bankShortage: false)
        }
        // Use the production allocator for both counterfactuals so all payout rules stay in one place.
        let ampleBank = ResourceHandV1(wood: 1_000, brick: 1_000, sheep: 1_000, wheat: 1_000, ore: 1_000)
        func potential(_ board: BoardSetupV1) -> ResourceHandV1 {
            applyProductionPayout(
                rollTotal: total, board: board,
                settlementsByNode: previous.settlementsByNode, citiesByNode: previous.citiesByNode,
                resourcesByPlayer: previous.resourcesByPlayer, bankResources: ampleBank,
                eligiblePlayers: Set(previous.activePlayers)
            ).resourcesByPlayer[viewer] ?? before
        }
        let unblockedBoard = BoardSetupV1(
            resourcesByTile: board.resourcesByTile, numbersByTile: board.numbersByTile,
            portsByIndex: board.portsByIndex, robberTile: -1,
            generator: board.generator, boardHash: board.boardHash
        )
        let withRobber = potential(board)
        let withoutRobber = potential(unblockedBoard)
        return ProductionReceiptV1(
            revision: rev, roller: previous.currentPlayer, roll: roll, gains: gains,
            blockedByRobber: resources.contains { withoutRobber.count(for: $0) > withRobber.count(for: $0) },
            bankShortage: resources.contains { withRobber.count(for: $0) > after.count(for: $0) }
        )
    }
}
