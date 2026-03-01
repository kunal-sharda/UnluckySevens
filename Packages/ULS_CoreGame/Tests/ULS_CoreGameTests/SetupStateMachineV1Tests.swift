import XCTest
@testable import ULS_CoreGame

final class SetupStateMachineV1Tests: XCTestCase {
    func testSnakeOrderForThreePlayers() {
        let order = makeSetupOrder(roster: ["A", "B", "C"])
        XCTAssertEqual(order, ["A", "B", "C", "C", "B", "A"])
    }

    func testSetupSequenceAdvancesStepAndTurnAndFillsSlots() throws {
        var state = makeSetupPhaseState(roster: ["A", "B"])

        state = try apply(intent: .placeSetupSettlement(node: 10), to: state, actor: "A")
        XCTAssertEqual(state.setupState?.step, .placeRoad)
        XCTAssertEqual(state.setupState?.turnIndex, 0)
        XCTAssertEqual(state.setupState?.placements["A"]?.settlement1, 10)
        XCTAssertEqual(state.currentPlayer, "A")

        state = try apply(intent: .placeSetupRoad(edge: 20), to: state, actor: "A")
        XCTAssertEqual(state.setupState?.step, .placeSettlement)
        XCTAssertEqual(state.setupState?.turnIndex, 1)
        XCTAssertEqual(state.setupState?.placements["A"]?.road1, 20)
        XCTAssertEqual(state.currentPlayer, "B")

        state = try apply(intent: .placeSetupSettlement(node: 11), to: state, actor: "B")
        state = try apply(intent: .placeSetupRoad(edge: 21), to: state, actor: "B")
        XCTAssertEqual(state.setupState?.turnIndex, 2)
        XCTAssertEqual(state.currentPlayer, "B")
        XCTAssertEqual(state.setupState?.placements["B"]?.settlement1, 11)
        XCTAssertEqual(state.setupState?.placements["B"]?.road1, 21)

        state = try apply(intent: .placeSetupSettlement(node: 12), to: state, actor: "B")
        state = try apply(intent: .placeSetupRoad(edge: 22), to: state, actor: "B")
        XCTAssertEqual(state.setupState?.turnIndex, 3)
        XCTAssertEqual(state.currentPlayer, "A")
        XCTAssertEqual(state.setupState?.placements["B"]?.settlement2, 12)
        XCTAssertEqual(state.setupState?.placements["B"]?.road2, 22)
    }

    func testRoadBeforeSettlementThrows() {
        let roster = ["A", "B"]
        let setup = SetupStateV1(
            order: makeSetupOrder(roster: roster),
            turnIndex: 0,
            step: .placeRoad,
            placements: [:],
            lastPlacedSettlementNode: nil
        )
        let state = CoreGameStateV1(
            gameId: "game-setup",
            rev: 1,
            prevHash: "hash-0",
            stateHash: "",
            roster: roster,
            currentPlayer: "A",
            phase: .setup,
            seed: 1,
            diceRngState: 2,
            boardRules: nil,
            board: nil,
            setupState: setup
        ).rehashed()

        XCTAssertThrowsError(try apply(intent: .placeSetupRoad(edge: 99), to: state, actor: "A")) { error in
            XCTAssertEqual(error as? CoreGameError, .roadBeforeSettlement)
        }
    }

    func testSetupCompletionTransitionsToTurnAndResetsCurrentPlayer() throws {
        var state = makeSetupPhaseState(roster: ["A", "B"])

        state = try apply(intent: .placeSetupSettlement(node: 0), to: state, actor: "A")
        state = try apply(intent: .placeSetupRoad(edge: 0), to: state, actor: "A")

        state = try apply(intent: .placeSetupSettlement(node: 1), to: state, actor: "B")
        state = try apply(intent: .placeSetupRoad(edge: 1), to: state, actor: "B")

        state = try apply(intent: .placeSetupSettlement(node: 2), to: state, actor: "B")
        state = try apply(intent: .placeSetupRoad(edge: 2), to: state, actor: "B")

        state = try apply(intent: .placeSetupSettlement(node: 3), to: state, actor: "A")
        state = try apply(intent: .placeSetupRoad(edge: 3), to: state, actor: "A")

        XCTAssertEqual(state.phase, .turn)
        XCTAssertEqual(state.currentPlayer, "A")
        XCTAssertNil(state.setupState)
    }

    private func makeSetupPhaseState(roster: [String]) -> CoreGameStateV1 {
        let setup = initializeSetupState(roster: roster)

        return CoreGameStateV1(
            gameId: "game-setup",
            rev: 1,
            prevHash: "hash-0",
            stateHash: "",
            roster: roster,
            currentPlayer: setup.order[0],
            phase: .setup,
            seed: 1,
            diceRngState: 2,
            boardRules: nil,
            board: nil,
            setupState: setup
        ).rehashed()
    }
}
