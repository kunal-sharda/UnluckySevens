import XCTest
@testable import ULS_CoreGame

final class TurnMaritimeTradeV1Tests: XCTestCase {
    private let topology = StandardBoardTopologyV1.standard()

    func testMaritimeTradeUsesBestRatioAndPreservesBankConservation() throws {
        let woodPortNode = try XCTUnwrap(portNode {
            if case .twoToOne(.wood) = $0 {
                return true
            }
            return false
        })
        let state = makeState(
            resourcesByPlayer: [
                "A": ResourceHandV1(wood: 2),
                "B": .zero,
            ],
            settlementsByNode: [woodPortNode: "A"]
        )

        let traded = try apply(
            intent: .maritimeTrade(
                give: ResourceHandV1(wood: 2),
                receive: ResourceHandV1(brick: 1)
            ),
            to: state,
            actor: "A"
        )

        XCTAssertEqual(traded.resourcesByPlayer["A"], ResourceHandV1(brick: 1))
        XCTAssertEqual(
            traded.bankResources,
            state.bankResources.adding(2, for: .wood).subtracting(1, for: .brick)
        )
        XCTAssertNoThrow(try validateTransition(from: state, to: traded, actor: "A"))
    }

    func testMaritimeTradeRejectsWhenBestRatioIsNotUsed() throws {
        let woodPortNode = try XCTUnwrap(portNode {
            if case .twoToOne(.wood) = $0 {
                return true
            }
            return false
        })
        let state = makeState(
            resourcesByPlayer: [
                "A": ResourceHandV1(wood: 3),
                "B": .zero,
            ],
            settlementsByNode: [woodPortNode: "A"]
        )

        XCTAssertThrowsError(
            try apply(
                intent: .maritimeTrade(
                    give: ResourceHandV1(wood: 3),
                    receive: ResourceHandV1(brick: 1)
                ),
                to: state,
                actor: "A"
            )
        ) { error in
            XCTAssertEqual(error as? CoreGameError, .maritimeTradeInvalid)
        }
    }

    func testMaritimeTradeRejectsInsufficientResourcesWithNoMutation() {
        let state = makeState(
            resourcesByPlayer: [
                "A": ResourceHandV1(wood: 3),
                "B": .zero,
            ]
        )
        let snapshot = state

        XCTAssertThrowsError(
            try apply(
                intent: .maritimeTrade(
                    give: ResourceHandV1(wood: 4),
                    receive: ResourceHandV1(brick: 1)
                ),
                to: state,
                actor: "A"
            )
        ) { error in
            XCTAssertEqual(error as? CoreGameError, .maritimeTradeInsufficientResources)
        }
        XCTAssertEqual(state, snapshot)
    }

    func testMaritimeTradeRejectsWhenBankCannotPay() {
        let state = makeState(
            resourcesByPlayer: [
                "A": ResourceHandV1(wood: 4),
                "B": .zero,
            ],
            bankResources: ResourceHandV1(wood: 19, brick: 19, sheep: 19, wheat: 19, ore: 0)
        )

        XCTAssertThrowsError(
            try apply(
                intent: .maritimeTrade(
                    give: ResourceHandV1(wood: 4),
                    receive: ResourceHandV1(ore: 1)
                ),
                to: state,
                actor: "A"
            )
        ) { error in
            XCTAssertEqual(error as? CoreGameError, .bankResourcesInvalid)
        }
    }

    private func makeState(
        resourcesByPlayer: [String: ResourceHandV1],
        bankResources: ResourceHandV1 = .standardBank,
        settlementsByNode: [NodeID: String] = [:]
    ) -> CoreGameStateV1 {
        let board = BoardSetupV1(
            resourcesByTile: [.wood] + Array(repeating: .desert, count: 18),
            numbersByTile: [5] + Array(repeating: nil, count: 18),
            portsByIndex: topology.ports.map(\.kind),
            robberTile: 1,
            generator: .randomV1,
            boardHash: ""
        ).rehashed()

        return CoreGameStateV1(
            gameId: "game-maritime",
            rev: 90,
            prevHash: "hash-89",
            stateHash: "",
            roster: ["A", "B"],
            currentPlayer: "A",
            phase: .turn,
            seed: 3,
            diceRngState: 4,
            robberRngState: 5,
            resourcesByPlayer: resourcesByPlayer,
            bankResources: bankResources,
            settlementsByNode: settlementsByNode,
            citiesByNode: [:],
            roadsByEdge: [:],
            boardRules: BoardRulesV1(strategy: .randomV1),
            board: board,
            setupState: nil,
            turnState: TurnStateV1(step: .afterRoll, lastRoll: DiceRollV1(d1: 4, d2: 3))
        ).rehashed()
    }

    private func portNode(matching predicate: (PortKindV1) -> Bool) -> NodeID? {
        for (index, port) in topology.ports.enumerated() where predicate(port.kind) {
            let edgeID = topology.ports[index].edge
            return topology.edges[edgeID].a
        }
        return nil
    }
}
