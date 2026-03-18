import ULS_CoreGame
import ULS_Transport
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

        XCTAssertEqual(intent?.kind, .buyDevCard)
        XCTAssertEqual(intent?.actor, "A")
    }

    func testDraftPlayKnightIntentUsesDefaultTileAndVictim() {
        let topology = StandardBoardTopologyV1.standard()
        let victimNode = topology.tiles[1].nodes[0]
        let state = makeState(
            resourcesByPlayer: ["A": .zero, "B": ResourceHandV1(wood: 2)],
            devCardsByPlayer: ["A": DevCardInventoryV1(knight: 1)],
            settlementsByNode: [victimNode: "B"]
        )

        let intent = DevCardInteractionResolver.draftPlayKnightIntent(
            state: state,
            actingAs: "A"
        )

        XCTAssertEqual(intent?.kind, .playDevCard)
        XCTAssertEqual(intent?.devCardPlayKind, .knight)
        XCTAssertNotNil(intent?.devCardTileID)
    }

    func testDraftPlayYearOfPlentyIntentUsesDefaultPair() {
        let state = makeState(
            resourcesByPlayer: ["A": .zero, "B": .zero],
            devCardsByPlayer: ["A": DevCardInventoryV1(yearOfPlenty: 1)]
        )

        let intent = DevCardInteractionResolver.draftPlayYearOfPlentyIntent(
            state: state,
            actingAs: "A"
        )

        XCTAssertEqual(intent?.devCardPlayKind, .yearOfPlenty)
        XCTAssertEqual(intent?.devCardFirstResource, .wood)
        XCTAssertEqual(intent?.devCardSecondResource, .wood)
    }

    func testDraftPlayRoadBuildingIntentUsesDefaultEdges() {
        let state = makeState(
            resourcesByPlayer: ["A": .zero, "B": .zero],
            devCardsByPlayer: ["A": DevCardInventoryV1(roadBuilding: 1)],
            roadsByEdge: [0: "A"]
        )

        let intent = DevCardInteractionResolver.draftPlayRoadBuildingIntent(
            state: state,
            actingAs: "A"
        )

        XCTAssertEqual(intent?.devCardPlayKind, .roadBuilding)
        XCTAssertNotNil(intent?.devCardFirstEdgeID)
        XCTAssertNotNil(intent?.devCardSecondEdgeID)
    }

    func testDraftRevealVictoryPointIntentUsesPlayableOrNewCard() {
        let state = makeState(
            resourcesByPlayer: ["A": .zero, "B": .zero],
            newDevCardsByPlayer: ["A": DevCardInventoryV1(victoryPoint: 1)]
        )

        let intent = DevCardInteractionResolver.draftRevealVictoryPointIntent(
            state: state,
            actingAs: "A"
        )

        XCTAssertEqual(intent?.devCardPlayKind, .revealVictoryPoint)
    }

    private func makeState(
        resourcesByPlayer: [String: ResourceHandV1],
        devCardsByPlayer: [String: DevCardInventoryV1] = [:],
        newDevCardsByPlayer: [String: DevCardInventoryV1] = [:],
        settlementsByNode: [Int: String] = [:],
        roadsByEdge: [Int: String] = [:]
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
            settlementsByNode: settlementsByNode,
            roadsByEdge: roadsByEdge,
            boardRules: BoardRulesV1(strategy: .randomV1),
            board: board,
            turnState: TurnStateV1(step: .afterRoll, lastRoll: DiceRollV1(d1: 4, d2: 2))
        ).rehashed()
    }
}
