import ULS_CoreGame
import XCTest

final class GameSetupPlacementModelTests: XCTestCase {
    func testSettlementStepProjectsFirstPlacementAndSnakeOrder() throws {
        let state = makeState(
            setup: initializeSetupState(roster: ["A", "B", "C"]),
            currentPlayer: "A"
        )

        let model = try XCTUnwrap(makeModel(state: state, actingAs: "A"))

        XCTAssertEqual(model.piece, .settlement)
        XCTAssertTrue(model.isLocalPlayerActive)
        XCTAssertEqual(model.title, "Place Your First Settlement")
        XCTAssertEqual(model.instruction, "")
        XCTAssertEqual(model.progressLabel, "Placement 1 of 6")
        XCTAssertEqual(model.order.map(\.displayName), ["A", "B", "C", "C", "B", "A"])
        XCTAssertEqual(model.visibleOrder.map(\.displayName), ["A", "B", "C"])
        XCTAssertTrue(model.order[0].isCurrent)
    }

    func testRoadStepProjectsConnectedRoadGuidanceWithoutInventingLegality() throws {
        let setup = SetupStateV1(
            order: makeSetupOrder(roster: ["A", "B"]),
            turnIndex: 2,
            step: .placeRoad,
            placements: [
                "A": PlayerSetupPlacementsV1(settlement1: 0, road1: 0),
                "B": PlayerSetupPlacementsV1(settlement1: 2, road1: 2, settlement2: 4),
            ],
            lastPlacedSettlementNode: 4
        )
        let state = makeState(setup: setup, currentPlayer: "B")

        let model = try XCTUnwrap(makeModel(state: state, actingAs: "B"))

        XCTAssertEqual(model.piece, .road)
        XCTAssertEqual(model.title, "Connect Your Second Road")
        XCTAssertEqual(model.instruction, "Choose a glowing road beside your new settlement.")
        XCTAssertEqual(model.placementNumber, 3)
        XCTAssertEqual(model.pairNumber, 2)
        XCTAssertTrue(model.order[0].isComplete)
        XCTAssertTrue(model.order[1].isComplete)
        XCTAssertTrue(model.order[2].isCurrent)
        XCTAssertEqual(model.visibleOrder.map(\.displayName), ["B", "A"])
    }

    func testFinalPlacementShowsOnlyTheCurrentPlayer() throws {
        let setup = SetupStateV1(
            order: makeSetupOrder(roster: ["A", "B"]),
            turnIndex: 3,
            step: .placeSettlement,
            placements: [
                "A": PlayerSetupPlacementsV1(settlement1: 0, road1: 0),
                "B": PlayerSetupPlacementsV1(settlement1: 2, road1: 2, settlement2: 4, road2: 4),
            ],
            lastPlacedSettlementNode: nil
        )
        let state = makeState(setup: setup, currentPlayer: "A")

        let model = try XCTUnwrap(makeModel(state: state, actingAs: "A"))

        XCTAssertEqual(model.visibleOrder.map(\.displayName), ["A"])
        XCTAssertTrue(model.visibleOrder[0].isCurrent)
    }

    func testWaitingPlayerSeesActivePlayerAndNoPlacementInstruction() throws {
        let state = makeState(
            setup: initializeSetupState(roster: ["A", "B"]),
            currentPlayer: "A"
        )

        let model = try XCTUnwrap(makeModel(state: state, actingAs: "B"))

        XCTAssertFalse(model.isLocalPlayerActive)
        XCTAssertEqual(model.title, "A Is Placing")
        XCTAssertEqual(model.instruction, "Waiting for settlement and road placement.")
    }

    private func makeModel(
        state: CoreGameStateV1,
        actingAs: String
    ) -> GameSetupPlacementModel? {
        GameSetupPlacementModelBuilder.build(
            state: state,
            actingAs: actingAs,
            players: state.roster.enumerated().map { index, player in
                GameInfoPlayerSummary(
                    id: player,
                    displayName: player,
                    playerTint: GamePlayerTint(
                        red: Double(index + 1) * 0.2,
                        green: 0.4,
                        blue: 0.5
                    ),
                    victoryPoints: 0,
                    resourceCardCount: 0,
                    developmentCardCount: 0,
                    isCurrentPlayer: player == state.currentPlayer,
                    isLocalPlayer: player == actingAs,
                    awardLabels: []
                )
            }
        )
    }

    private func makeState(
        setup: SetupStateV1,
        currentPlayer: String
    ) -> CoreGameStateV1 {
        let roster = Array(Set(setup.order)).sorted()
        return CoreGameStateV1(
            gameId: "setup-model",
            rev: 2,
            prevHash: "hash-1",
            stateHash: "",
            roster: roster,
            currentPlayer: currentPlayer,
            phase: .setup,
            seed: 12,
            diceRngState: 13,
            robberRngState: 14,
            resourcesByPlayer: Dictionary(uniqueKeysWithValues: roster.map { ($0, ResourceHandV1.zero) }),
            setupState: setup
        ).rehashed()
    }
}
