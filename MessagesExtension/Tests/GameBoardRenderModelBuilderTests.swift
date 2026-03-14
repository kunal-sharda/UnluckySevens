import ULS_CoreGame
import XCTest

final class GameBoardRenderModelBuilderTests: XCTestCase {
    func testBuildReturnsNilWithoutBoard() {
        let state = makeState(board: nil)
        XCTAssertNil(GameBoardRenderModelBuilder.build(state: state))
    }

    func testBuildIncludesTilesPortsAndPlacedPieces() {
        let board = makeBoard()
        let state = makeState(
            board: board,
            settlementsByNode: [0: "A"],
            citiesByNode: [9: "B"],
            roadsByEdge: [3: "A"]
        )

        let model = GameBoardRenderModelBuilder.build(state: state)

        XCTAssertNotNil(model)
        XCTAssertEqual(model?.tiles.count, 19)
        XCTAssertEqual(model?.ports.count, 9)
        XCTAssertEqual(model?.structures.count, 2)
        XCTAssertEqual(model?.roads.count, 1)
        XCTAssertEqual(model?.tiles.first?.resource, .wood)
        XCTAssertTrue(model?.tiles[2].hasRobber == true)
        XCTAssertEqual(model?.geometry.tileCenters.count, 19)
        XCTAssertEqual(model?.geometry.nodePositions.count, 54)
    }

    private func makeState(
        board: BoardSetupV1?,
        settlementsByNode: [NodeID: String] = [:],
        citiesByNode: [NodeID: String] = [:],
        roadsByEdge: [EdgeID: String] = [:]
    ) -> CoreGameStateV1 {
        CoreGameStateV1(
            gameId: "board-render-model",
            rev: 3,
            prevHash: "hash-2",
            stateHash: "",
            roster: ["A", "B", "C"],
            currentPlayer: "A",
            phase: .turn,
            seed: 1,
            diceRngState: 2,
            robberRngState: 3,
            resourcesByPlayer: ["A": .zero, "B": .zero, "C": .zero],
            settlementsByNode: settlementsByNode,
            citiesByNode: citiesByNode,
            roadsByEdge: roadsByEdge,
            boardRules: BoardRulesV1(strategy: .noRedAdjacentV1),
            board: board,
            turnState: TurnStateV1(step: .afterRoll, lastRoll: DiceRollV1(d1: 4, d2: 2))
        ).rehashed()
    }

    private func makeBoard() -> BoardSetupV1 {
        BoardSetupV1(
            resourcesByTile: [
                .wood, .brick, .desert, .sheep, .wheat,
                .ore, .wood, .brick, .sheep, .wheat,
                .ore, .wood, .brick, .sheep, .wheat,
                .ore, .wood, .brick, .sheep,
            ],
            numbersByTile: [
                5, 2, nil, 6, 3,
                8, 10, 9, 12, 11,
                4, 8, 10, 9, 4,
                5, 6, 3, 11,
            ],
            portsByIndex: StandardBoardTopologyV1.standard().ports.map(\.kind),
            robberTile: 2,
            generator: .noRedAdjacentV1,
            boardHash: ""
        ).rehashed()
    }
}
