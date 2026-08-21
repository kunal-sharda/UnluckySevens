import XCTest
import ULS_CoreGame
@testable import MessagesExtension

final class GameShellProjectionBuilderTests: XCTestCase {
    private let topology = StandardBoardTopologyV1.standard()

    func testBuildStateProjectionComposesGameplayShellModels() throws {
        let state = makeTurnState(
            resourcesByPlayer: [
                "A": ResourceHandV1(wood: 2, brick: 1, sheep: 1, wheat: 1, ore: 1),
                "B": .zero,
            ],
            devCardsByPlayer: [
                "A": DevCardInventoryV1(roadBuilding: 1),
            ]
        )

        let projection = GameShellProjectionBuilder.build(
            state: state,
            actingAs: "A",
            actionAvailability: .none,
            modeAvailability: .none,
            contextBanner: "banner",
            contextMeta: "meta"
        )

        XCTAssertEqual(projection.gameId, state.gameId)
        XCTAssertEqual(projection.phase, PhaseV1.turn.rawValue)
        XCTAssertEqual(projection.gameScreenModel.header.statusLine.title, "Your turn")
        XCTAssertNotNil(projection.gameScreenModel.boardRenderModel)
        XCTAssertNil(projection.setupGuidanceText)
        XCTAssertNil(projection.discardPanelModel)
        XCTAssertTrue(projection.robberVictimOptions.isEmpty)
        XCTAssertEqual(projection.tradePanelModel?.roleTitle, "Trade")
        let diagnostics = GameShellProjectionDiagnosticsBuilder.build(state: state, actingAs: "A")
        XCTAssertEqual(
            projection,
            GameShellProjectionBuilder.build(
                state: state,
                actingAs: "A",
                actionAvailability: .none,
                modeAvailability: .none,
                contextBanner: "banner",
                contextMeta: "meta"
            )
        )
        XCTAssertEqual(
            diagnostics,
            GameShellProjectionDiagnosticsBuilder.build(state: state, actingAs: "A")
        )
        XCTAssertEqual(diagnostics.kind, "STATE")
        XCTAssertEqual(diagnostics.gameId, projection.gameId)
        XCTAssertEqual(diagnostics.phase, projection.phase)
        XCTAssertEqual(diagnostics.boardHash, state.board?.boardHash)
        XCTAssertEqual(diagnostics.visibleHands, "A: w:2, b:1, s:1, wh:1, o:1 | B: 0")
    }

    func testBuildStateProjectionKeepsTradePanelStateDrivenAndDiscardPanelStateDriven() throws {
        let tradeOffer = TradeOfferV1(
            offerHash: "offer-1",
            proposer: "A",
            give: ResourceHandV1(wood: 1),
            receive: ResourceHandV1(brick: 1),
            recipients: ["B"],
            createdRev: 6
        )
        let tradeState = makeTurnState(
            activeTradeOffer: tradeOffer,
            tradeResponses: [
                TradeResponseV1(
                    respondingPlayer: "B",
                    offerHash: tradeOffer.offerHash,
                    kind: .counter,
                    respondedAtRev: 7,
                    counterGive: ResourceHandV1(brick: 1),
                    counterReceive: ResourceHandV1(ore: 1)
                )
            ]
        )
        let tradeProjection = GameShellProjectionBuilder.build(
            state: tradeState,
            actingAs: "A"
        )

        XCTAssertEqual(tradeProjection.tradePanelModel?.participantStatuses.first?.playerID, "B")
        XCTAssertEqual(tradeProjection.tradePanelModel?.participantStatuses.first?.state, .countered)
        XCTAssertEqual(tradeProjection.tradePanelModel?.message, "Review the counters below.")

        let discardState = makeTurnState(
            currentPlayer: "A",
            resourcesByPlayer: [
                "A": .zero,
                "B": ResourceHandV1(wood: 1, brick: 1, sheep: 1, wheat: 1),
            ],
            turnState: TurnStateV1(
                step: .pendingDiscards,
                lastRoll: DiceRollV1(d1: 3, d2: 4),
                discardRequirementsByPlayer: ["B": 4]
            )
        )
        let discardProjection = GameShellProjectionBuilder.build(
            state: discardState,
            actingAs: "A"
        )

        XCTAssertNil(discardProjection.discardPanelModel?.action)
    }

    private func makeTurnState(
        currentPlayer: String = "A",
        resourcesByPlayer: [String: ResourceHandV1] = [
            "A": ResourceHandV1(wood: 5, brick: 5, sheep: 5, wheat: 5, ore: 5),
            "B": .zero,
        ],
        devCardsByPlayer: [String: DevCardInventoryV1] = [:],
        activeTradeOffer: TradeOfferV1? = nil,
        tradeResponses: [TradeResponseV1] = [],
        settlementsByNode: [NodeID: String] = [:],
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
            gameId: "game-shell-projection",
            rev: 6,
            prevHash: "hash-5",
            stateHash: "",
            roster: Array(resourcesByPlayer.keys).sorted(),
            currentPlayer: currentPlayer,
            phase: .turn,
            seed: 11,
            diceRngState: 12,
            robberRngState: 13,
            resourcesByPlayer: resourcesByPlayer,
            devCardsByPlayer: devCardsByPlayer,
            activeTradeOffer: activeTradeOffer,
            tradeResponses: tradeResponses,
            settlementsByNode: settlementsByNode,
            roadsByEdge: roadsByEdge,
            boardRules: BoardRulesV1(strategy: .randomV1),
            board: board,
            turnState: turnState
        ).rehashed()
    }
}
