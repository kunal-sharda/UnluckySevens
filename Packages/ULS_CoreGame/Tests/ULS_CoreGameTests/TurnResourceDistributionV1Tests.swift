import XCTest
@testable import ULS_CoreGame

final class TurnResourceDistributionV1Tests: XCTestCase {
    private let topology = StandardBoardTopologyV1.standard()
    private let rollSeed: UInt64 = 0x0123456789ABCDEF // first roll = 4 + 6

    func testNonSevenRollDistributesToSettlementAndCity() throws {
        let settlementNode = topology.tiles[0].nodes[0]
        let cityNode = topology.tiles[0].nodes[1]
        let board = makeSingleTileBoard(number: 10, robberTile: 18)

        let initial = makeTurnState(
            board: board,
            settlementsByNode: [settlementNode: "A"],
            citiesByNode: [cityNode: "B"],
            bankResources: .standardBank
        )

        let rolled = try apply(intent: .rollDice, to: initial, actor: "A")

        XCTAssertEqual(rolled.turnState?.lastRoll, DiceRollV1(d1: 4, d2: 6))
        XCTAssertEqual(rolled.resourcesByPlayer["A"]?.wood, 1)
        XCTAssertEqual(rolled.resourcesByPlayer["B"]?.wood, 2)
        XCTAssertEqual(rolled.bankResources.wood, 16)
        XCTAssertNoThrow(try validateTransition(from: initial, to: rolled, actor: "A"))
    }

    func testRobberBlocksMatchingTileProduction() throws {
        let settlementNode = topology.tiles[0].nodes[0]
        let cityNode = topology.tiles[0].nodes[1]
        let board = makeSingleTileBoard(number: 10, robberTile: 0)

        let initial = makeTurnState(
            board: board,
            settlementsByNode: [settlementNode: "A"],
            citiesByNode: [cityNode: "B"],
            bankResources: .standardBank
        )

        let rolled = try apply(intent: .rollDice, to: initial, actor: "A")

        XCTAssertEqual(rolled.turnState?.lastRoll, DiceRollV1(d1: 4, d2: 6))
        XCTAssertEqual(rolled.resourcesByPlayer["A"], .zero)
        XCTAssertEqual(rolled.resourcesByPlayer["B"], .zero)
        XCTAssertEqual(rolled.bankResources, .standardBank)
        XCTAssertNoThrow(try validateTransition(from: initial, to: rolled, actor: "A"))
    }

    func testBankDepletionSkipsEntireResourcePayoutForRoll() throws {
        let settlementNode = topology.tiles[0].nodes[0]
        let cityNode = topology.tiles[0].nodes[1]
        let board = makeSingleTileBoard(number: 10, robberTile: 18)
        let constrainedBank = ResourceHandV1(wood: 2, brick: 19, sheep: 19, wheat: 19, ore: 19)

        let initial = makeTurnState(
            board: board,
            settlementsByNode: [settlementNode: "A"],
            citiesByNode: [cityNode: "B"],
            bankResources: constrainedBank
        )

        let rolled = try apply(intent: .rollDice, to: initial, actor: "A")

        XCTAssertEqual(rolled.turnState?.lastRoll, DiceRollV1(d1: 4, d2: 6))
        XCTAssertEqual(rolled.resourcesByPlayer["A"], .zero)
        XCTAssertEqual(rolled.resourcesByPlayer["B"], .zero)
        XCTAssertEqual(rolled.bankResources, constrainedBank)
        XCTAssertNoThrow(try validateTransition(from: initial, to: rolled, actor: "A"))
    }

    private func makeTurnState(
        board: BoardSetupV1,
        settlementsByNode: [NodeID: String],
        citiesByNode: [NodeID: String],
        bankResources: ResourceHandV1
    ) -> CoreGameStateV1 {
        CoreGameStateV1(
            gameId: "game-turn-production",
            rev: 8,
            prevHash: "hash-7",
            stateHash: "",
            roster: ["A", "B"],
            currentPlayer: "A",
            phase: .turn,
            seed: 42,
            diceRngState: rollSeed,
            resourcesByPlayer: ["A": .zero, "B": .zero],
            bankResources: bankResources,
            settlementsByNode: settlementsByNode,
            citiesByNode: citiesByNode,
            roadsByEdge: [:],
            boardRules: BoardRulesV1(strategy: .randomV1),
            board: board,
            setupState: nil,
            turnState: TurnStateV1(step: .needsRoll, lastRoll: nil)
        ).rehashed()
    }

    private func makeSingleTileBoard(number: Int, robberTile: Int) -> BoardSetupV1 {
        BoardSetupV1(
            resourcesByTile: [.wood] + Array(repeating: .desert, count: 18),
            numbersByTile: [number] + Array(repeating: nil, count: 18),
            portsByIndex: topology.ports.map(\.kind),
            robberTile: robberTile,
            generator: .randomV1,
            boardHash: ""
        ).rehashed()
    }
}
