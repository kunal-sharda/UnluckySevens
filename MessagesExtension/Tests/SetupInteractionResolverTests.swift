import ULS_CoreGame
import ULS_Transport
import XCTest

final class SetupInteractionResolverTests: XCTestCase {
    private let topology = StandardBoardTopologyV1.standard()

    func testGuidanceTextMatchesSetupStep() {
        let settlementState = makeSetupState(step: .placeSettlement)
        XCTAssertEqual(
            SetupInteractionResolver.guidanceText(state: settlementState, actingAs: "A"),
            "Tap a highlighted node to place your settlement."
        )

        let settlement = settlementState.legalSetupSettlementNodes(for: "A").first ?? 0
        let roadState = makeSetupState(
            step: .placeRoad,
            placements: [
                "A": PlayerSetupPlacementsV1(settlement1: settlement),
            ],
            lastPlacedSettlementNode: settlement
        )
        XCTAssertEqual(
            SetupInteractionResolver.guidanceText(state: roadState, actingAs: "A"),
            "Tap the highlighted road connected to the settlement you just placed."
        )
    }

    func testDraftIntentBuildsSettlementIntentForLegalNode() throws {
        let state = makeSetupState(step: .placeSettlement)
        let node = try XCTUnwrap(state.legalSetupSettlementNodes(for: "A").first)

        let intent = SetupInteractionResolver.draftIntent(
            state: state,
            actingAs: "A",
            target: .node(node)
        )

        XCTAssertEqual(
            intent,
            SetupPlacementIntentV1(
                gameId: state.gameId,
                anchorRev: state.rev,
                anchorHash: state.stateHash,
                actor: "A",
                node: node
            )
        )
    }

    func testDraftIntentBuildsRoadIntentForLegalEdge() throws {
        let seedSettlement = try XCTUnwrap(makeSetupState(step: .placeSettlement).legalSetupSettlementNodes(for: "A").first)
        let state = makeSetupState(
            step: .placeRoad,
            placements: [
                "A": PlayerSetupPlacementsV1(settlement1: seedSettlement),
            ],
            lastPlacedSettlementNode: seedSettlement
        )
        let edge = try XCTUnwrap(state.legalSetupRoadEdges(for: "A").first)

        let intent = SetupInteractionResolver.draftIntent(
            state: state,
            actingAs: "A",
            target: .edge(edge)
        )

        XCTAssertEqual(
            intent,
            SetupPlacementIntentV1(
                gameId: state.gameId,
                anchorRev: state.rev,
                anchorHash: state.stateHash,
                actor: "A",
                edge: edge
            )
        )
    }

    func testDraftIntentRejectsIllegalTargetKinds() throws {
        let settlementState = makeSetupState(step: .placeSettlement)
        XCTAssertNil(
            SetupInteractionResolver.draftIntent(
                state: settlementState,
                actingAs: "A",
                target: .edge(0)
            )
        )

        let seedSettlement = try XCTUnwrap(settlementState.legalSetupSettlementNodes(for: "A").first)
        let roadState = makeSetupState(
            step: .placeRoad,
            placements: [
                "A": PlayerSetupPlacementsV1(settlement1: seedSettlement),
            ],
            lastPlacedSettlementNode: seedSettlement
        )

        XCTAssertNil(
            SetupInteractionResolver.draftIntent(
                state: roadState,
                actingAs: "B",
                target: .node(seedSettlement)
            )
        )
    }

    private func makeSetupState(
        step: SetupStepV1,
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
            gameId: "setup-interaction",
            rev: 2,
            prevHash: "hash-1",
            stateHash: "",
            roster: ["A", "B"],
            currentPlayer: "A",
            phase: .setup,
            seed: 12,
            diceRngState: 13,
            robberRngState: 14,
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
            )
        ).rehashed()
    }
}
