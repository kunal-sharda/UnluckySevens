import XCTest
@testable import ULS_CoreGame
@testable import ULS_Transport

final class CanonicalStatePayloadBudgetTests: XCTestCase {
    func testStressStateEnvelopeStaysUnder64KB() throws {
        let state = makeStressState()
        let payload = try jsonString(state)
        let envelope = EnvelopeV1(kind: .state, body: .state(payload: payload))

        let bytes = try encodedByteCount(of: envelope)

        XCTAssertGreaterThan(bytes, 12 * 1024)
        XCTAssertLessThanOrEqual(bytes, 64 * 1024)
    }

    func testStressStateEnvelopeRoundTripsCoreGamePayload() throws {
        let state = makeStressState()
        let payload = try jsonString(state)
        let envelope = EnvelopeV1(kind: .state, body: .state(payload: payload))

        let encoded = try encode(envelope)
        let decoded = try decode(encoded)

        guard case let .state(decodedPayload) = decoded.body else {
            XCTFail("Expected STATE body.")
            return
        }

        let decodedState = try JSONDecoder().decode(CoreGameStateV1.self, from: Data(decodedPayload.utf8))
        XCTAssertEqual(decodedState, state)
    }

    private func makeStressState() -> CoreGameStateV1 {
        let roster = ["A", "B", "C", "D"]
        let masterSeed: UInt64 = 0xD00DFEED
        let gameId = "payload-budget-stress"
        let rev = 240
        let boardRules = BoardRulesV1(strategy: .noRedAdjacentV1)
        let boardSeed = SeedDeriver(masterSeed: masterSeed).seed(for: .board)
        let board = StandardBoardGeneratorV1.generate(boardSeed: boardSeed, rules: boardRules)
        let devDeck = Array(makeDeterministicDevDeck(masterSeed: masterSeed).dropFirst(20))

        let resourcesByPlayer: [String: ResourceHandV1] = [
            "A": ResourceHandV1(wood: 4, brick: 4, sheep: 4, wheat: 4, ore: 3),
            "B": ResourceHandV1(wood: 4, brick: 3, sheep: 3, wheat: 3, ore: 4),
            "C": ResourceHandV1(wood: 3, brick: 4, sheep: 3, wheat: 4, ore: 4),
            "D": ResourceHandV1(wood: 3, brick: 3, sheep: 4, wheat: 4, ore: 3),
        ]
        let bankResources = ResourceHandV1(wood: 5, brick: 5, sheep: 5, wheat: 4, ore: 5)

        let devCardsByPlayer: [String: DevCardInventoryV1] = [
            "A": DevCardInventoryV1(knight: 2, monopoly: 1, yearOfPlenty: 0, roadBuilding: 1, victoryPoint: 1),
            "B": DevCardInventoryV1(knight: 3, monopoly: 0, yearOfPlenty: 1, roadBuilding: 0, victoryPoint: 1),
            "C": DevCardInventoryV1(knight: 1, monopoly: 1, yearOfPlenty: 1, roadBuilding: 0, victoryPoint: 1),
            "D": DevCardInventoryV1(knight: 2, monopoly: 0, yearOfPlenty: 0, roadBuilding: 1, victoryPoint: 1),
        ]
        let newDevCardsByPlayer: [String: DevCardInventoryV1] = [
            "A": DevCardInventoryV1(victoryPoint: 1),
            "B": .zero,
            "C": DevCardInventoryV1(knight: 1),
            "D": .zero,
        ]
        let revealedVictoryPointsByPlayer = ["A": 1, "B": 1, "C": 0, "D": 1]
        let knightsPlayedByPlayer = ["A": 2, "B": 5, "C": 3, "D": 2]

        let cityNodes = [
            "A": [0, 4, 8, 12],
            "B": [16, 20, 24, 28],
            "C": [32, 36, 40, 44],
            "D": [48, 49, 50, 51],
        ]
        let settlementNodes = [
            "A": [1, 5, 9, 13, 17],
            "B": [18, 21, 25, 29, 33],
            "C": [34, 37, 41, 45, 52],
            "D": [2, 6, 10, 14, 53],
        ]
        let roadEdges = [
            "A": Array(0..<15),
            "B": Array(15..<30),
            "C": Array(30..<45),
            "D": Array(45..<60),
        ]

        var citiesByNode: [NodeID: String] = [:]
        var settlementsByNode: [NodeID: String] = [:]
        var roadsByEdge: [EdgeID: String] = [:]

        for (player, nodes) in cityNodes {
            for node in nodes {
                citiesByNode[node] = player
            }
        }
        for (player, nodes) in settlementNodes {
            for node in nodes {
                settlementsByNode[node] = player
            }
        }
        for (player, edges) in roadEdges {
            for edge in edges {
                roadsByEdge[edge] = player
            }
        }

        let auditLog = makeAuditLog(roster: roster, endRev: rev)
        let offerHash = deterministicTradeOfferHash(
            gameId: gameId,
            proposer: "A",
            give: ResourceHandV1(wood: 2),
            receive: ResourceHandV1(ore: 1),
            anchorRev: rev - 1,
            anchorHash: String(repeating: "a", count: 64)
        )
        let activeTradeOffer = TradeOfferV1(
            offerHash: offerHash,
            proposer: "A",
            give: ResourceHandV1(wood: 2),
            receive: ResourceHandV1(ore: 1),
            createdRev: rev
        )
        let pendingTradeAccepts = [
            TradeAcceptV1(acceptingPlayer: "B", offerHash: offerHash, acceptedAtRev: rev),
            TradeAcceptV1(acceptingPlayer: "D", offerHash: offerHash, acceptedAtRev: rev),
        ]

        return CoreGameStateV1(
            gameId: gameId,
            rev: rev,
            prevHash: String(repeating: "b", count: 64),
            stateHash: "",
            roster: roster,
            currentPlayer: "A",
            phase: .turn,
            seed: masterSeed,
            diceRngState: SeedDeriver(masterSeed: masterSeed).seed(for: .dice),
            robberRngState: SeedDeriver(masterSeed: masterSeed).seed(for: .robber),
            resourcesByPlayer: resourcesByPlayer,
            bankResources: bankResources,
            devDeck: devDeck,
            devCardsByPlayer: devCardsByPlayer,
            newDevCardsByPlayer: newDevCardsByPlayer,
            revealedVictoryPointsByPlayer: revealedVictoryPointsByPlayer,
            devCardActionPlayedThisTurn: false,
            knightsPlayedByPlayer: knightsPlayedByPlayer,
            largestArmyOwner: "B",
            largestArmySize: 5,
            longestRoadOwner: "C",
            longestRoadLength: 11,
            winnerPlayer: nil,
            winningVictoryPoints: 0,
            auditLog: auditLog,
            lastTurnRecap: computeLastTurnRecap(from: auditLog),
            activeTradeOffer: activeTradeOffer,
            pendingTradeAccepts: pendingTradeAccepts,
            settlementsByNode: settlementsByNode,
            citiesByNode: citiesByNode,
            roadsByEdge: roadsByEdge,
            boardRules: boardRules,
            board: board,
            setupState: nil,
            turnState: TurnStateV1(step: .afterRoll, lastRoll: DiceRollV1(d1: 5, d2: 3))
        ).rehashed()
    }

    private func makeAuditLog(roster: [String], endRev: Int) -> [AuditEntryV1] {
        let actions: [AuditActionV1] = [
            .rollDice,
            .buildRoad,
            .proposeTrade,
            .acceptTrade,
            .executeTrade,
            .buyDevCard,
            .playKnight,
            .maritimeTrade,
            .buildSettlement,
            .buildCity,
            .endTurn,
        ]

        return (1...endRev).map { rev in
            let action = actions[(rev - 1) % actions.count]
            let actor = roster[((rev - 1) / 6) % roster.count]
            let rollTotal: Int? = action == .rollDice ? (rev % 11) + 2 : nil
            return AuditEntryV1(rev: rev, actor: actor, action: action, rollTotal: rollTotal)
        }
    }

    private func jsonString<T: Encodable>(_ value: T) throws -> String {
        let data = try JSONEncoder().encode(value)
        guard let string = String(data: data, encoding: .utf8) else {
            XCTFail("Expected UTF-8 JSON payload.")
            throw NSError(domain: "CanonicalStatePayloadBudgetTests", code: 1)
        }
        return string
    }
}
