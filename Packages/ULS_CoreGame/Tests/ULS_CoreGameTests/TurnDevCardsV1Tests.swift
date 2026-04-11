import XCTest
@testable import ULS_CoreGame

final class TurnDevCardsV1Tests: XCTestCase {
    private let topology = StandardBoardTopologyV1.standard()

    func testCannotPlayBoughtKnightOnSameTurn() throws {
        let state = makeState(
            resourcesByPlayer: [
                "A": ResourceHandV1(sheep: 1, wheat: 1, ore: 1),
                "B": .zero,
            ],
            devDeck: [.knight]
        )

        let bought = try apply(intent: .buyDevCard, to: state, actor: "A")
        XCTAssertEqual(bought.newDevCardsByPlayer["A"]?.knight, 1)

        XCTAssertThrowsError(
            try apply(intent: .playKnight(tileID: 0, victimPlayer: nil), to: bought, actor: "A")
        ) { error in
            XCTAssertEqual(error as? CoreGameError, .devCardNotOwned)
        }
    }

    func testRevealVictoryPointAllowedOnSameTurnAsPurchase() throws {
        let state = makeState(
            resourcesByPlayer: [
                "A": ResourceHandV1(sheep: 1, wheat: 1, ore: 1),
                "B": .zero,
            ],
            devDeck: [.victoryPoint]
        )

        let bought = try apply(intent: .buyDevCard, to: state, actor: "A")
        let revealed = try apply(intent: .revealVictoryPoint, to: bought, actor: "A")

        XCTAssertEqual(revealed.revealedVictoryPointsByPlayer["A"], 1)
        XCTAssertEqual(revealed.newDevCardsByPlayer["A"]?.victoryPoint, 0)
        XCTAssertNoThrow(try validateTransition(from: bought, to: revealed, actor: "A"))
    }

    func testKnightMovesRobberStealsDeterministicallyAndBlocksSecondDevPlay() throws {
        let seed: UInt64 = 0x0F0E0D0C
        let robbedTile = 0
        let victim = "B"
        let victimHand = ResourceHandV1(wood: 1, brick: 1, sheep: 1)
        let state = makeState(
            resourcesByPlayer: [
                "A": ResourceHandV1(),
                "B": victimHand,
            ],
            devCardsByPlayer: [
                "A": DevCardInventoryV1(knight: 1, monopoly: 1),
                "B": .zero,
            ],
            robberRngState: seed,
            settlementsByNode: [topology.tiles[robbedTile].nodes[0]: victim],
            turnState: TurnStateV1(step: .needsRoll, lastRoll: nil)
        )

        var expectedRng = DeterministicRNG(seed: seed)
        let expectedResource = deterministicStolenResource(from: victimHand, rng: &expectedRng)
        let played = try apply(
            intent: .playKnight(tileID: robbedTile, victimPlayer: victim),
            to: state,
            actor: "A"
        )

        XCTAssertEqual(played.board?.robberTile, robbedTile)
        XCTAssertEqual(played.robberRngState, expectedRng.state)
        XCTAssertEqual(played.devCardsByPlayer["A"]?.knight, 0)
        XCTAssertEqual(played.knightsPlayedByPlayer["A"], 1)
        XCTAssertTrue(played.devCardActionPlayedThisTurn)
        XCTAssertEqual(played.resourcesByPlayer["A"], ResourceHandV1().addingOne(for: expectedResource))
        XCTAssertEqual(played.resourcesByPlayer["B"], victimHand.subtracting(1, for: expectedResource))
        XCTAssertNoThrow(try validateTransition(from: state, to: played, actor: "A"))

        XCTAssertThrowsError(try apply(intent: .playMonopoly(resource: .wood), to: played, actor: "A")) { error in
            XCTAssertEqual(error as? CoreGameError, .devCardAlreadyPlayedThisTurn)
        }

        let rolled = try apply(intent: .rollDice, to: played, actor: "A")
        XCTAssertEqual(rolled.turnState?.step, .afterRoll)
    }

    func testRevealVictoryPointCanHappenBeforeRollingAfterSameTurnDevCardPlay() throws {
        let state = makeState(
            resourcesByPlayer: [
                "A": ResourceHandV1(),
                "B": ResourceHandV1(wood: 1),
            ],
            devCardsByPlayer: [
                "A": DevCardInventoryV1(knight: 1),
                "B": .zero,
            ],
            newDevCardsByPlayer: [
                "A": DevCardInventoryV1(victoryPoint: 1),
                "B": .zero,
            ],
            robberRngState: 0x0F0E0D0C,
            settlementsByNode: [topology.tiles[0].nodes[0]: "B"],
            turnState: TurnStateV1(step: .needsRoll, lastRoll: nil)
        )

        let playedKnight = try apply(
            intent: .playKnight(tileID: 0, victimPlayer: "B"),
            to: state,
            actor: "A"
        )
        XCTAssertTrue(playedKnight.devCardActionPlayedThisTurn)

        let revealed = try apply(intent: .revealVictoryPoint, to: playedKnight, actor: "A")

        XCTAssertEqual(revealed.revealedVictoryPointsByPlayer["A"], 1)
        XCTAssertEqual(revealed.newDevCardsByPlayer["A"]?.victoryPoint, 0)
        XCTAssertTrue(revealed.devCardActionPlayedThisTurn)
    }

    func testMonopolyCollectsAllOfSelectedResource() throws {
        let state = makeState(
            resourcesByPlayer: [
                "A": ResourceHandV1(wood: 1),
                "B": ResourceHandV1(brick: 2, sheep: 1),
                "C": ResourceHandV1(brick: 1, ore: 1),
            ],
            devCardsByPlayer: [
                "A": DevCardInventoryV1(monopoly: 1),
                "B": .zero,
                "C": .zero,
            ]
        )

        let played = try apply(intent: .playMonopoly(resource: .brick), to: state, actor: "A")

        XCTAssertEqual(played.resourcesByPlayer["A"], ResourceHandV1(wood: 1, brick: 3))
        XCTAssertEqual(played.resourcesByPlayer["B"], ResourceHandV1(sheep: 1))
        XCTAssertEqual(played.resourcesByPlayer["C"], ResourceHandV1(ore: 1))
        XCTAssertNoThrow(try validateTransition(from: state, to: played, actor: "A"))
    }

    func testYearOfPlentyRespectsBankAndTransfersTwoResources() throws {
        let state = makeState(
            resourcesByPlayer: [
                "A": .zero,
                "B": .zero,
            ],
            bankResources: ResourceHandV1(wood: 19, brick: 19, sheep: 19, wheat: 19, ore: 2),
            devCardsByPlayer: [
                "A": DevCardInventoryV1(yearOfPlenty: 1),
                "B": .zero,
            ]
        )

        let played = try apply(intent: .playYearOfPlenty(first: .ore, second: .ore), to: state, actor: "A")

        XCTAssertEqual(played.resourcesByPlayer["A"], ResourceHandV1(ore: 2))
        XCTAssertEqual(played.bankResources.ore, 0)
        XCTAssertNoThrow(try validateTransition(from: state, to: played, actor: "A"))
    }

    func testRoadBuildingPlacesTwoRoadsWithoutResourceCost() throws {
        let node = topology.tiles[0].nodes[0]
        let incidentEdges = topology.edges(incidentTo: node)
        let firstEdge = incidentEdges[0]
        let secondEdge = incidentEdges[1]
        let state = makeState(
            resourcesByPlayer: [
                "A": ResourceHandV1(wood: 1, brick: 1, sheep: 1, wheat: 1),
                "B": .zero,
            ],
            devCardsByPlayer: [
                "A": DevCardInventoryV1(roadBuilding: 1),
                "B": .zero,
            ],
            settlementsByNode: [node: "A"]
        )

        let played = try apply(
            intent: .playRoadBuilding(firstEdgeID: firstEdge, secondEdgeID: secondEdge),
            to: state,
            actor: "A"
        )

        XCTAssertEqual(played.roadsByEdge[firstEdge], "A")
        XCTAssertEqual(played.roadsByEdge[secondEdge], "A")
        XCTAssertEqual(played.resourcesByPlayer, state.resourcesByPlayer)
        XCTAssertEqual(played.bankResources, state.bankResources)
        XCTAssertNoThrow(try validateTransition(from: state, to: played, actor: "A"))
    }

    func testFixedSeedAndActionSequenceIsDeterministic() throws {
        let seed: UInt64 = 0xDEADBEEF
        let tile = 0
        let initial = makeState(
            resourcesByPlayer: [
                "A": .zero,
                "B": ResourceHandV1(wood: 1, brick: 1),
            ],
            devCardsByPlayer: [
                "A": DevCardInventoryV1(knight: 1),
                "B": .zero,
            ],
            robberRngState: seed,
            settlementsByNode: [topology.tiles[tile].nodes[0]: "B"]
        )

        let firstRun = try apply(intent: .playKnight(tileID: tile, victimPlayer: "B"), to: initial, actor: "A")
        let secondRun = try apply(intent: .playKnight(tileID: tile, victimPlayer: "B"), to: initial, actor: "A")

        XCTAssertEqual(firstRun, secondRun)
    }

    private func makeState(
        resourcesByPlayer: [String: ResourceHandV1],
        bankResources: ResourceHandV1 = .standardBank,
        devDeck: [DevCardV1] = [],
        devCardsByPlayer: [String: DevCardInventoryV1] = [:],
        newDevCardsByPlayer: [String: DevCardInventoryV1] = [:],
        robberRngState: UInt64 = 0x1234,
        settlementsByNode: [NodeID: String] = [:],
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
            gameId: "game-dev-cards",
            rev: 70,
            prevHash: "hash-69",
            stateHash: "",
            roster: roster,
            currentPlayer: "A",
            phase: .turn,
            seed: 7,
            diceRngState: 8,
            robberRngState: robberRngState,
            resourcesByPlayer: resourcesByPlayer,
            bankResources: bankResources,
            devDeck: devDeck,
            devCardsByPlayer: devCardsByPlayer,
            newDevCardsByPlayer: newDevCardsByPlayer,
            settlementsByNode: settlementsByNode,
            citiesByNode: [:],
            roadsByEdge: roadsByEdge,
            boardRules: BoardRulesV1(strategy: .randomV1),
            board: board,
            setupState: nil,
            turnState: turnState
        ).rehashed()
    }

    private func deterministicStolenResource(from hand: ResourceHandV1, rng: inout DeterministicRNG) -> ResourceV1 {
        let total = hand.totalCount
        let pick = Int(rng.nextUInt64() % UInt64(total))

        let ordered: [(ResourceV1, Int)] = [
            (.wood, hand.wood),
            (.brick, hand.brick),
            (.sheep, hand.sheep),
            (.wheat, hand.wheat),
            (.ore, hand.ore),
        ]

        var cursor = 0
        for (resource, count) in ordered {
            if pick < cursor + count {
                return resource
            }
            cursor += count
        }
        return .wood
    }
}
