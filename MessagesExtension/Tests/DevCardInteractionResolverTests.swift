import ULS_CoreGame
import XCTest
@testable import MessagesExtension

final class DevCardInteractionResolverTests: XCTestCase {
    func testDraftBuyDevCardIntentForCurrentPlayer() {
        let state = makeState(
            resourcesByPlayer: ["A": ResourceHandV1(sheep: 1, wheat: 1, ore: 1), "B": .zero]
        )

        let intent = DevCardInteractionResolver.draftBuyDevCardIntent(
            state: state,
            actingAs: "A"
        )

        XCTAssertEqual(intent?.intent, .buyDevCard)
        XCTAssertEqual(intent?.actor, "A")
    }

    func testDraftPlayKnightIntentUsesExplicitTileAndVictim() throws {
        let topology = StandardBoardTopologyV1.standard()
        let victimNode = topology.tiles[1].nodes[0]
        let state = makeState(
            resourcesByPlayer: ["A": .zero, "B": ResourceHandV1(wood: 2)],
            devCardsByPlayer: ["A": DevCardInventoryV1(knight: 1)],
            settlementsByNode: [victimNode: "B"]
        )

        let tileID = try XCTUnwrap(state.legalKnightMoveTilesForDevCard(for: "A").first)
        let victimPlayer = state.legalKnightVictims(for: tileID, actor: "A").first
        let intent = DevCardInteractionResolver.draftPlayKnightIntent(
            state: state,
            actingAs: "A",
            tileID: tileID,
            victimPlayer: victimPlayer
        )

        XCTAssertEqual(intent?.intent, .playKnight(tileID: tileID, victimPlayer: victimPlayer))
    }

    func testDraftPlayKnightIntentBeforeRollingIsLegalForCurrentPlayer() throws {
        let topology = StandardBoardTopologyV1.standard()
        let victimNode = topology.tiles[1].nodes[0]
        let state = makeState(
            resourcesByPlayer: ["A": .zero, "B": ResourceHandV1(wood: 2)],
            devCardsByPlayer: ["A": DevCardInventoryV1(knight: 1)],
            settlementsByNode: [victimNode: "B"],
            turnState: TurnStateV1(step: .needsRoll, lastRoll: nil)
        )

        let tileID = try XCTUnwrap(state.legalKnightMoveTilesForDevCard(for: "A").first)
        let intent = DevCardInteractionResolver.draftPlayKnightIntent(
            state: state,
            actingAs: "A",
            tileID: tileID,
            victimPlayer: state.legalKnightVictims(for: tileID, actor: "A").first
        )

        XCTAssertEqual(intent?.intent, .playKnight(tileID: tileID, victimPlayer: state.legalKnightVictims(for: tileID, actor: "A").first))
    }

    func testDraftPlayYearOfPlentyIntentUsesExplicitPair() {
        let state = makeState(
            resourcesByPlayer: ["A": .zero, "B": .zero],
            devCardsByPlayer: ["A": DevCardInventoryV1(yearOfPlenty: 1)]
        )

        let intent = DevCardInteractionResolver.draftPlayYearOfPlentyIntent(
            state: state,
            actingAs: "A",
            firstResource: .wood,
            secondResource: .wood
        )

        XCTAssertEqual(intent?.intent, .playYearOfPlenty(first: .wood, second: .wood))
    }

    func testDraftPlayRoadBuildingIntentRequiresExplicitLegalEdges() throws {
        let state = makeState(
            resourcesByPlayer: ["A": .zero, "B": .zero],
            devCardsByPlayer: ["A": DevCardInventoryV1(roadBuilding: 1)],
            roadsByEdge: [0: "A"]
        )

        let firstEdgeID = try XCTUnwrap(state.legalRoadBuildingFirstEdges(for: "A").first)
        let secondEdgeID = try XCTUnwrap(
            state.legalRoadBuildingSecondEdges(for: "A", firstEdgeID: firstEdgeID).first
        )
        let intent = DevCardInteractionResolver.draftPlayRoadBuildingIntent(
            state: state,
            actingAs: "A",
            firstEdgeID: firstEdgeID,
            secondEdgeID: secondEdgeID
        )

        XCTAssertEqual(intent?.intent, .playRoadBuilding(firstEdgeID: firstEdgeID, secondEdgeID: secondEdgeID))
    }

    func testDraftRevealVictoryPointIntentRequiresWinningThreshold() {
        let nonWinningState = makeState(
            resourcesByPlayer: ["A": .zero, "B": .zero],
            newDevCardsByPlayer: ["A": DevCardInventoryV1(victoryPoint: 1)]
        )
        XCTAssertNil(
            DevCardInteractionResolver.draftRevealVictoryPointIntent(
                state: nonWinningState,
                actingAs: "A"
            )
        )

        let winningState = makeState(
            resourcesByPlayer: ["A": .zero, "B": .zero],
            newDevCardsByPlayer: ["A": DevCardInventoryV1(victoryPoint: 1)],
            revealedVictoryPointsByPlayer: ["A": 9, "B": 0]
        )
        let winningIntent = DevCardInteractionResolver.draftRevealVictoryPointIntent(
            state: winningState,
            actingAs: "A"
        )

        XCTAssertEqual(winningIntent?.intent, .revealVictoryPoint)
    }

    private func makeState(
        resourcesByPlayer: [String: ResourceHandV1],
        devCardsByPlayer: [String: DevCardInventoryV1] = [:],
        newDevCardsByPlayer: [String: DevCardInventoryV1] = [:],
        settlementsByNode: [Int: String] = [:],
        roadsByEdge: [Int: String] = [:],
        revealedVictoryPointsByPlayer: [String: Int] = [:],
        turnState: TurnStateV1 = TurnStateV1(step: .afterRoll, lastRoll: DiceRollV1(d1: 4, d2: 2))
    ) -> CoreGameStateV1 {
        let topology = StandardBoardTopologyV1.standard()
        let board = BoardSetupV1(
            resourcesByTile: Array(repeating: .wood, count: topology.tiles.count),
            numbersByTile: Array(repeating: 5, count: topology.tiles.count),
            portsByIndex: topology.ports.map(\.kind),
            robberTile: 0,
            generator: .randomV1,
            boardHash: ""
        ).rehashed()

        return CoreGameStateV1(
            gameId: "dev-resolver",
            rev: 11,
            prevHash: "hash-10",
            stateHash: "",
            roster: Array(resourcesByPlayer.keys).sorted(),
            currentPlayer: "A",
            phase: .turn,
            seed: 1,
            diceRngState: 2,
            robberRngState: 3,
            resourcesByPlayer: resourcesByPlayer,
            bankResources: ResourceHandV1(wood: 19, brick: 19, sheep: 19, wheat: 19, ore: 19),
            devDeck: [.knight, .monopoly],
            devCardsByPlayer: devCardsByPlayer,
            newDevCardsByPlayer: newDevCardsByPlayer,
            revealedVictoryPointsByPlayer: revealedVictoryPointsByPlayer,
            settlementsByNode: settlementsByNode,
            roadsByEdge: roadsByEdge,
            boardRules: BoardRulesV1(strategy: .randomV1),
            board: board,
            turnState: turnState
        ).rehashed()
    }
}
