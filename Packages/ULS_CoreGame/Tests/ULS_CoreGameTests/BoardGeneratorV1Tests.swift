import XCTest
@testable import ULS_CoreGame

final class BoardGeneratorV1Tests: XCTestCase {
    private let topology = StandardBoardTopologyV1.standard()
    private let masterSeed: UInt64 = 0x0123456789ABCDEF

    func testRandomV1GoldenBoardHash_master0123456789ABCDEF() {
        let boardSeed = SeedDeriver(masterSeed: masterSeed).seed(for: .board)
        let board = StandardBoardGeneratorV1.generate(
            boardSeed: boardSeed,
            rules: BoardRulesV1(strategy: .randomV1),
            topology: topology
        )

        XCTAssertEqual(board.boardHash, "51ad72e8f1f1e426177739c03ad9216204765750ea4561910e795904d5a293b4")
    }

    func testNoRedAdjacentV1GoldenBoardHash_master0123456789ABCDEF() {
        let boardSeed = SeedDeriver(masterSeed: masterSeed).seed(for: .board)
        let board = StandardBoardGeneratorV1.generate(
            boardSeed: boardSeed,
            rules: BoardRulesV1(strategy: .noRedAdjacentV1),
            topology: topology
        )

        XCTAssertEqual(board.boardHash, "c026d0d515ed5ac0c82fbfacd5d2db3191e86f598b8834347e878dcbdb7b0767")
    }

    func testResourceDistributionIsCorrect() {
        let board = makeBoard(strategy: .randomV1)
        XCTAssertEqual(board.resourcesByTile.count, 19)
        XCTAssertEqual(board.resourcesByTile.filter { $0 == .wood }.count, 4)
        XCTAssertEqual(board.resourcesByTile.filter { $0 == .sheep }.count, 4)
        XCTAssertEqual(board.resourcesByTile.filter { $0 == .wheat }.count, 4)
        XCTAssertEqual(board.resourcesByTile.filter { $0 == .brick }.count, 3)
        XCTAssertEqual(board.resourcesByTile.filter { $0 == .ore }.count, 3)
        XCTAssertEqual(board.resourcesByTile.filter { $0 == .desert }.count, 1)
    }

    func testNumberDistributionAndDesertNilAreCorrect() {
        let board = makeBoard(strategy: .randomV1)
        XCTAssertEqual(board.numbersByTile.count, 19)
        XCTAssertEqual(board.numbersByTile.filter { $0 == nil }.count, 1)

        let assignedNumbers = board.numbersByTile.compactMap { $0 }.sorted()
        XCTAssertEqual(assignedNumbers, [2, 3, 3, 4, 4, 5, 5, 6, 6, 8, 8, 9, 9, 10, 10, 11, 11, 12])
        XCTAssertEqual(assignedNumbers.contains(7), false)

        for tileIndex in board.resourcesByTile.indices {
            if board.resourcesByTile[tileIndex] == .desert {
                XCTAssertNil(board.numbersByTile[tileIndex])
            } else {
                XCTAssertNotNil(board.numbersByTile[tileIndex])
            }
        }
    }

    func testPortDistributionIsCorrect() {
        let board = makeBoard(strategy: .randomV1)
        XCTAssertEqual(board.portsByIndex.count, 9)

        let threeToOne = board.portsByIndex.filter { if case .threeToOne = $0 { return true } else { return false } }.count
        XCTAssertEqual(threeToOne, 4)

        var twoToOneResources: [ResourceV1] = []
        for kind in board.portsByIndex {
            if case let .twoToOne(resource) = kind {
                twoToOneResources.append(resource)
            }
        }

        XCTAssertEqual(twoToOneResources.count, 5)
        XCTAssertEqual(Set(twoToOneResources), Set([.wood, .brick, .sheep, .wheat, .ore]))
    }

    func testRobberTileMatchesDesertTile() {
        let board = makeBoard(strategy: .randomV1)
        XCTAssertEqual(board.resourcesByTile[board.robberTile], .desert)
    }

    func testNoRedAdjacentStrategyHasNoAdjacentSixOrEight() {
        let board = makeBoard(strategy: .noRedAdjacentV1)
        let adjacentPairs = tileAdjacencyPairs()

        for (a, b) in adjacentPairs {
            guard let left = board.numbersByTile[a], let right = board.numbersByTile[b] else { continue }
            XCTAssertFalse(isRed(left) && isRed(right))
        }
    }

    func testBorderDesertPlacementPutsDesertOnCoastalTile() {
        for strategy in BoardGenStrategyV1.allCases {
            for boardSeed in UInt64(0)..<UInt64(64) {
                let board = StandardBoardGeneratorV1.generate(
                    boardSeed: boardSeed,
                    rules: BoardRulesV1(strategy: strategy, desertPlacement: .borderV1),
                    topology: topology
                )

                XCTAssertTrue(isBorderTile(board.robberTile), "Expected desert on border for seed \(boardSeed) and strategy \(strategy).")
            }
        }
    }

    func testRandomStrategyCanProduceAdjacentSixOrEight() {
        let sampledSeeds = Array(0..<256).map(UInt64.init)
        let adjacentPairs = tileAdjacencyPairs()
        let foundAdjacentReds = sampledSeeds.contains { boardSeed in
            let board = StandardBoardGeneratorV1.generate(
                boardSeed: boardSeed,
                rules: BoardRulesV1(strategy: .randomV1),
                topology: topology
            )

            for (a, b) in adjacentPairs {
                guard let left = board.numbersByTile[a], let right = board.numbersByTile[b] else { continue }
                if isRed(left) && isRed(right) {
                    return true
                }
            }
            return false
        }

        XCTAssertTrue(
            foundAdjacentReds,
            "Expected unconstrained random strategy to allow at least one adjacent 6/8 layout in sampled seeds."
        )
    }

    private func makeBoard(strategy: BoardGenStrategyV1) -> BoardSetupV1 {
        let boardSeed = SeedDeriver(masterSeed: masterSeed).seed(for: .board)
        return StandardBoardGeneratorV1.generate(
            boardSeed: boardSeed,
            rules: BoardRulesV1(strategy: strategy),
            topology: topology
        )
    }

    private func tileAdjacencyPairs() -> [(Int, Int)] {
        var pairs = Set<TilePair>()
        for edgeID in topology.edges.indices {
            let tiles = topology.tiles(adjacentToEdge: edgeID)
            if tiles.count == 2 {
                pairs.insert(TilePair(tiles[0], tiles[1]))
            }
        }
        return pairs
            .map { ($0.a, $0.b) }
            .sorted { lhs, rhs in
                if lhs.0 != rhs.0 { return lhs.0 < rhs.0 }
                return lhs.1 < rhs.1
            }
    }

    private func isBorderTile(_ tileID: Int) -> Bool {
        topology.tiles[tileID].edges.contains { edgeID in
            topology.isCoastal(edge: edgeID)
        }
    }

    private func isRed(_ value: Int) -> Bool {
        value == 6 || value == 8
    }
}

private struct TilePair: Hashable {
    let a: Int
    let b: Int

    init(_ lhs: Int, _ rhs: Int) {
        if lhs <= rhs {
            a = lhs
            b = rhs
        } else {
            a = rhs
            b = lhs
        }
    }
}
