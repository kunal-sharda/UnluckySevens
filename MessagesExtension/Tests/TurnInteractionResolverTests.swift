import ULS_CoreGame
import ULS_Transport
import XCTest

final class TurnInteractionResolverTests: XCTestCase {
    private let topology = StandardBoardTopologyV1.standard()

    func testDraftBuildRoadIntentForLegalEdge() throws {
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
        let edge = try XCTUnwrap(state.legalBuildRoadEdges(for: "A").first)

        let intent = TurnInteractionResolver.draftBuildIntent(
            state: state,
            actingAs: "A",
            mode: .buildRoad,
            target: .edge(edge)
        )

        XCTAssertEqual(
            intent,
            TurnIntentV1(
                buildRoadEdgeID: edge,
                gameId: state.gameId,
                anchorRev: state.rev,
                anchorHash: state.stateHash,
                actor: "A"
            )
        )
    }

    func testDraftBuildSettlementIntentForLegalNode() throws {
        let homeNode = topology.tiles[0].nodes[0]
        let homeRoad = topology.edges(incidentTo: homeNode)[0]
        let firstHop = topology.edges[homeRoad].a == homeNode
            ? topology.edges[homeRoad].b
            : topology.edges[homeRoad].a
        let extensionRoad = try XCTUnwrap(
            topology.edges(incidentTo: firstHop)
                .first { $0 != homeRoad }
        )
        let settlementState = makeTurnState(
            resourcesByPlayer: [
                "A": ResourceHandV1(wood: 2, brick: 2, sheep: 2, wheat: 2),
                "B": .zero,
            ],
            settlementsByNode: [homeNode: "A"],
            roadsByEdge: [
                homeRoad: "A",
                extensionRoad: "A",
            ]
        )
        let node = try XCTUnwrap(settlementState.legalBuildSettlementNodes(for: "A").first)

        let intent = TurnInteractionResolver.draftBuildIntent(
            state: settlementState,
            actingAs: "A",
            mode: .buildSettlement,
            target: .node(node)
        )

        XCTAssertEqual(
            intent,
            TurnIntentV1(
                buildSettlementNodeID: node,
                gameId: settlementState.gameId,
                anchorRev: settlementState.rev,
                anchorHash: settlementState.stateHash,
                actor: "A"
            )
        )
    }

    func testDraftBuildCityIntentForUpgradeableSettlement() throws {
        let state = makeTurnState(
            resourcesByPlayer: [
                "A": ResourceHandV1(wheat: 2, ore: 3),
                "B": .zero,
            ],
            settlementsByNode: [0: "A"]
        )

        let intent = TurnInteractionResolver.draftBuildIntent(
            state: state,
            actingAs: "A",
            mode: .buildCity,
            target: .node(0)
        )

        XCTAssertEqual(
            intent,
            TurnIntentV1(
                buildCityNodeID: 0,
                gameId: state.gameId,
                anchorRev: state.rev,
                anchorHash: state.stateHash,
                actor: "A"
            )
        )
    }

    func testDraftBuildIntentRejectsIllegalTargetAndWrongActor() {
        let state = makeTurnState(resourcesByPlayer: ["A": .zero, "B": .zero])

        XCTAssertNil(
            TurnInteractionResolver.draftBuildIntent(
                state: state,
                actingAs: "A",
                mode: .buildRoad,
                target: .node(0)
            )
        )

        XCTAssertNil(
            TurnInteractionResolver.draftBuildIntent(
                state: state,
                actingAs: "B",
                mode: .buildCity,
                target: .node(0)
            )
        )
    }

    private func makeTurnState(
        resourcesByPlayer: [String: ResourceHandV1],
        settlementsByNode: [NodeID: String] = [:],
        citiesByNode: [NodeID: String] = [:],
        roadsByEdge: [EdgeID: String] = [:],
        turnState: TurnStateV1 = TurnStateV1(step: .afterRoll, lastRoll: DiceRollV1(d1: 4, d2: 3))
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
            gameId: "turn-interaction",
            rev: 5,
            prevHash: "hash-4",
            stateHash: "",
            roster: ["A", "B"],
            currentPlayer: "A",
            phase: .turn,
            seed: 31,
            diceRngState: 32,
            robberRngState: 33,
            resourcesByPlayer: resourcesByPlayer,
            settlementsByNode: settlementsByNode,
            citiesByNode: citiesByNode,
            roadsByEdge: roadsByEdge,
            boardRules: BoardRulesV1(strategy: .randomV1),
            board: board,
            turnState: turnState
        ).rehashed()
    }
}
