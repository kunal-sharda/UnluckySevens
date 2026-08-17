import XCTest
@testable import ULS_CoreGame

final class TurnRobberStealV1Tests: XCTestCase {
    private let topology = StandardBoardTopologyV1.standard()

    func testMoveRobberWithoutVictimsSkipsStealStep() throws {
        let board = makeBoard(robberTile: 1)
        let state = makeState(
            board: board,
            turnState: TurnStateV1(step: .needsRobberMove, lastRoll: DiceRollV1(d1: 3, d2: 4)),
            resourcesByPlayer: [
                "A": ResourceHandV1(wood: 2),
                "B": .zero,
            ],
            settlementsByNode: [topology.tiles[0].nodes[0]: "A"]
        )

        let moved = try apply(intent: .moveRobber(tileID: 0), to: state, actor: "A")

        XCTAssertEqual(moved.turnState?.step, .afterRoll)
        XCTAssertEqual(moved.turnState?.eligibleStealVictims, [])
        XCTAssertEqual(moved.board?.robberTile, 0)
        XCTAssertNoThrow(try validateTransition(from: state, to: moved, actor: "A"))
    }

    func testSelectStealVictimUsesDeterministicRng() throws {
        let seed: UInt64 = 0xABCDEF
        let victimHand = ResourceHandV1(wood: 1, brick: 2, sheep: 1)
        let state = makeState(
            board: makeBoard(robberTile: 0),
            turnState: TurnStateV1(
                step: .needsRobberSteal,
                lastRoll: DiceRollV1(d1: 5, d2: 2),
                eligibleStealVictims: ["B"]
            ),
            resourcesByPlayer: [
                "A": .zero,
                "B": victimHand,
            ],
            robberRngState: seed
        )

        var expectedRng = DeterministicRNG(seed: seed)
        let expectedResource = deterministicStolenResourceForTest(from: victimHand, rng: &expectedRng)
        let expectedRobberState = expectedRng.state

        let stolen = try apply(intent: .selectStealVictim(victimPlayer: "B"), to: state, actor: "A")

        XCTAssertEqual(stolen.turnState?.step, .afterRoll)
        XCTAssertEqual(stolen.robberRngState, expectedRobberState)
        XCTAssertEqual(stolen.resourcesByPlayer["A"], ResourceHandV1().addingOne(for: expectedResource))
        XCTAssertEqual(stolen.resourcesByPlayer["B"], victimHand.subtracting(1, for: expectedResource))
        XCTAssertNoThrow(try validateTransition(from: state, to: stolen, actor: "A"))
    }

    func testOnlyCurrentPlayerCanSelectStealVictim() throws {
        let state = makeState(
            board: makeBoard(robberTile: 0),
            turnState: TurnStateV1(
                step: .needsRobberSteal,
                lastRoll: DiceRollV1(d1: 4, d2: 3),
                eligibleStealVictims: ["B"]
            ),
            resourcesByPlayer: [
                "A": .zero,
                "B": ResourceHandV1(ore: 1),
            ],
            robberRngState: 55
        )
        let snapshot = state

        XCTAssertThrowsError(try apply(intent: .selectStealVictim(victimPlayer: "B"), to: state, actor: "B")) { error in
            XCTAssertEqual(error as? CoreGameError, .actorMismatch)
        }
        XCTAssertEqual(state, snapshot)
    }

    func testMultipleEligibleVictimsAllowsSelectingEitherAdjacentPlayer() throws {
        let victimHand = ResourceHandV1(wheat: 1)
        let state = makeState(
            board: makeBoard(robberTile: 0),
            turnState: TurnStateV1(
                step: .needsRobberSteal,
                lastRoll: DiceRollV1(d1: 6, d2: 1),
                eligibleStealVictims: ["B", "C"]
            ),
            resourcesByPlayer: [
                "A": .zero,
                "B": ResourceHandV1(ore: 1),
                "C": victimHand,
            ],
            robberRngState: 77
        )

        let stolen = try apply(intent: .selectStealVictim(victimPlayer: "C"), to: state, actor: "A")

        XCTAssertEqual(stolen.turnState?.step, .afterRoll)
        XCTAssertEqual(stolen.turnState?.eligibleStealVictims, [])
        XCTAssertEqual(stolen.resourcesByPlayer["A"], ResourceHandV1(wheat: 1))
        XCTAssertEqual(stolen.resourcesByPlayer["B"], ResourceHandV1(ore: 1))
        XCTAssertEqual(stolen.resourcesByPlayer["C"], .zero)
        XCTAssertNoThrow(try validateTransition(from: state, to: stolen, actor: "A"))
    }

    private func makeState(
        board: BoardSetupV1,
        turnState: TurnStateV1,
        resourcesByPlayer: [String: ResourceHandV1],
        settlementsByNode: [NodeID: String] = [:],
        robberRngState: UInt64 = 999
    ) -> CoreGameStateV1 {
        CoreGameStateV1(
            gameId: "game-robber-steal",
            rev: 21,
            prevHash: "hash-20",
            stateHash: "",
            roster: resourcesByPlayer.keys.sorted(),
            currentPlayer: "A",
            phase: .turn,
            seed: 123,
            diceRngState: 456,
            robberRngState: robberRngState,
            resourcesByPlayer: resourcesByPlayer,
            bankResources: .standardBank,
            settlementsByNode: settlementsByNode,
            citiesByNode: [:],
            roadsByEdge: [:],
            boardRules: BoardRulesV1(strategy: .randomV1),
            board: board,
            setupState: nil,
            turnState: turnState
        ).rehashed()
    }

    private func makeBoard(robberTile: Int) -> BoardSetupV1 {
        BoardSetupV1(
            resourcesByTile: [.wood] + Array(repeating: .desert, count: 18),
            numbersByTile: [5] + Array(repeating: nil, count: 18),
            portsByIndex: topology.ports.map(\.kind),
            robberTile: robberTile,
            generator: .randomV1,
            boardHash: ""
        ).rehashed()
    }

    private func deterministicStolenResourceForTest(from hand: ResourceHandV1, rng: inout DeterministicRNG) -> ResourceV1 {
        let total = hand.totalCount
        let pick = Int(rng.nextUInt64() % UInt64(total))

        let ordered: [(ResourceV1, Int)] = [
            (.wood, hand.wood),
            (.brick, hand.brick),
            (.sheep, hand.sheep),
            (.wheat, hand.wheat),
            (.ore, hand.ore),
        ]

        var cursor = 0
        for (resource, count) in ordered {
            if pick < cursor + count {
                return resource
            }
            cursor += count
        }
        return .wood
    }
}
