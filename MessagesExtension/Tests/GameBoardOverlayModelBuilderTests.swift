import ULS_CoreGame
import XCTest

final class GameBoardOverlayModelBuilderTests: XCTestCase {
    private let topology = StandardBoardTopologyV1.standard()

    func testIdlePreservesSelectedTarget() throws {
        let state = makeTurnState()

        let overlay = GameBoardOverlayModelBuilder.build(
            state: state,
            actingAs: "A",
            mode: .idle,
            selectedTarget: .tile(3)
        )

        XCTAssertEqual(overlay.selectedTarget, .tile(3))
        XCTAssertTrue(overlay.legalTileIDs.isEmpty)
        XCTAssertTrue(overlay.legalNodeIDs.isEmpty)
        XCTAssertTrue(overlay.legalEdgeIDs.isEmpty)
    }

    func testBuildRoadModeUsesLegalEdgesAndRejectsIllegalSelection() throws {
        let homeNode = topology.tiles[0].nodes[0]
        let homeRoad = topology.edges(incidentTo: homeNode)[0]
        let state = makeTurnState(
            resourcesByPlayer: [
                "A": ResourceHandV1(wood: 3, brick: 3, sheep: 2, wheat: 2),
                "B": .zero,
            ],
            settlementsByNode: [homeNode: "A"],
            roadsByEdge: [homeRoad: "A"]
        )

        let legalEdge = try XCTUnwrap(state.legalBuildRoadEdges(for: "A").first)
        let overlay = GameBoardOverlayModelBuilder.build(
            state: state,
            actingAs: "A",
            mode: .buildRoad,
            selectedTarget: .node(homeNode)
        )

        XCTAssertTrue(overlay.legalEdgeIDs.contains(legalEdge))
        XCTAssertNil(overlay.selectedTarget)

        let selectedOverlay = GameBoardOverlayModelBuilder.build(
            state: state,
            actingAs: "A",
            mode: .buildRoad,
            selectedTarget: .edge(legalEdge)
        )
        XCTAssertEqual(selectedOverlay.selectedTarget, .edge(legalEdge))
    }

    func testSetupModeSwitchesBetweenNodeAndEdgeHighlights() throws {
        let settlementState = makeSetupState()
        let settlementTarget = try XCTUnwrap(settlementState.legalSetupSettlementNodes(for: "A").first)
        let settlementOverlay = GameBoardOverlayModelBuilder.build(
            state: settlementState,
            actingAs: "A",
            mode: .setup,
            selectedTarget: .node(settlementTarget)
        )
        XCTAssertTrue(settlementOverlay.legalNodeIDs.contains(settlementTarget))
        XCTAssertEqual(settlementOverlay.selectedTarget, .node(settlementTarget))

        let roadState = makeSetupState(
            step: .placeRoad,
            placements: [
                "A": PlayerSetupPlacementsV1(settlement1: settlementTarget),
            ],
            lastPlacedSettlementNode: settlementTarget
        )
        let roadTarget = try XCTUnwrap(roadState.legalSetupRoadEdges(for: "A").first)
        let roadOverlay = GameBoardOverlayModelBuilder.build(
            state: roadState,
            actingAs: "A",
            mode: .setup,
            selectedTarget: .edge(roadTarget)
        )
        XCTAssertTrue(roadOverlay.legalNodeIDs.isEmpty)
        XCTAssertTrue(roadOverlay.legalEdgeIDs.contains(roadTarget))
        XCTAssertEqual(roadOverlay.selectedTarget, .edge(roadTarget))
    }

    func testRobberModesExposeTileAndVictimNodeHighlights() throws {
        let victimNode = try XCTUnwrap(topology.tiles[1].nodes.first)
        let robberMoveState = makeTurnState(
            turnState: TurnStateV1(step: .needsRobberMove, lastRoll: DiceRollV1(d1: 3, d2: 4))
        )
        let robberMoveOverlay = GameBoardOverlayModelBuilder.build(
            state: robberMoveState,
            actingAs: "A",
            mode: .robberMove,
            selectedTarget: .tile(0)
        )
        XCTAssertFalse(robberMoveOverlay.legalTileIDs.isEmpty)
        XCTAssertFalse(robberMoveOverlay.legalTileIDs.contains(1))
        XCTAssertEqual(robberMoveOverlay.selectedTarget, .tile(0))

        let robberVictimState = makeTurnState(
            resourcesByPlayer: [
                "A": .zero,
                "B": ResourceHandV1(wood: 1),
            ],
            settlementsByNode: [victimNode: "B"],
            turnState: TurnStateV1(
                step: .needsRobberSteal,
                lastRoll: DiceRollV1(d1: 3, d2: 4),
                eligibleStealVictims: ["B"]
            )
        )
        let robberVictimOverlay = GameBoardOverlayModelBuilder.build(
            state: robberVictimState,
            actingAs: "A",
            mode: .robberVictim,
            selectedTarget: .node(victimNode)
        )
        XCTAssertEqual(robberVictimOverlay.legalNodeIDs, [victimNode])
        XCTAssertEqual(robberVictimOverlay.selectedTarget, .node(victimNode))
    }

    private func makeTurnState(
        resourcesByPlayer: [String: ResourceHandV1] = [
            "A": ResourceHandV1(wood: 5, brick: 5, sheep: 5, wheat: 5, ore: 5),
            "B": .zero,
        ],
        settlementsByNode: [NodeID: String] = [:],
        citiesByNode: [NodeID: String] = [:],
        roadsByEdge: [EdgeID: String] = [:],
        turnState: TurnStateV1 = TurnStateV1(step: .afterRoll, lastRoll: DiceRollV1(d1: 4, d2: 3))
    ) -> CoreGameStateV1 {
        let roster = Array(resourcesByPlayer.keys).sorted()
        let board = BoardSetupV1(
            resourcesByTile: [.wood] + Array(repeating: .desert, count: 18),
            numbersByTile: [5] + Array(repeating: nil, count: 18),
            portsByIndex: topology.ports.map(\.kind),
            robberTile: 1,
            generator: .randomV1,
            boardHash: ""
        ).rehashed()

        return CoreGameStateV1(
            gameId: "overlay-builder-turn",
            rev: 6,
            prevHash: "hash-5",
            stateHash: "",
            roster: roster,
            currentPlayer: "A",
            phase: .turn,
            seed: 11,
            diceRngState: 12,
            robberRngState: 13,
            resourcesByPlayer: resourcesByPlayer,
            settlementsByNode: settlementsByNode,
            citiesByNode: citiesByNode,
            roadsByEdge: roadsByEdge,
            boardRules: BoardRulesV1(strategy: .randomV1),
            board: board,
            turnState: turnState
        ).rehashed()
    }

    private func makeSetupState(
        step: SetupStepV1 = .placeSettlement,
        placements: [String: PlayerSetupPlacementsV1] = [:],
        lastPlacedSettlementNode: NodeID? = nil
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
            gameId: "overlay-builder-setup",
            rev: 2,
            prevHash: "hash-1",
            stateHash: "",
            roster: ["A", "B"],
            currentPlayer: "A",
            phase: .setup,
            seed: 21,
            diceRngState: 22,
            robberRngState: 23,
            resourcesByPlayer: ["A": .zero, "B": .zero],
            settlementsByNode: [:],
            citiesByNode: [:],
            roadsByEdge: [:],
            boardRules: BoardRulesV1(strategy: .randomV1),
            board: board,
            setupState: SetupStateV1(
                order: makeSetupOrder(roster: ["A", "B"]),
                turnIndex: 0,
                step: step,
                placements: placements,
                lastPlacedSettlementNode: lastPlacedSettlementNode
            ),
            turnState: nil
        ).rehashed()
    }
}
