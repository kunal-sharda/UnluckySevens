import Messages
import XCTest
import ULS_CoreGame
import ULS_Transport
@testable import MessagesExtensionSupport

final class CompactStateTransportTests: XCTestCase {
    func testCompactStateTransportRoundTripsExactState() throws {
        let state = makeState()

        let payload = try CompactStateTransport.encode(state)
        let decoded = try CompactStateTransport.decode(payload)

        XCTAssertEqual(decoded.gameId, state.gameId)
        XCTAssertEqual(decoded.rev, state.rev)
        XCTAssertEqual(decoded.prevHash, state.prevHash)
        XCTAssertEqual(decoded.roster, state.roster)
        XCTAssertEqual(decoded.currentPlayer, state.currentPlayer)
        XCTAssertEqual(decoded.playerDisplayNamesByPlayer, state.playerDisplayNamesByPlayer)
        XCTAssertEqual(decoded.phase, state.phase)
        XCTAssertEqual(decoded.resourcesByPlayer, state.resourcesByPlayer)
        XCTAssertEqual(decoded.bankResources, state.bankResources)
        XCTAssertEqual(decoded.devDeck, state.devDeck)
        XCTAssertEqual(decoded.devCardsByPlayer, state.devCardsByPlayer)
        XCTAssertEqual(decoded.newDevCardsByPlayer, state.newDevCardsByPlayer)
        XCTAssertEqual(decoded.gameResult, state.gameResult)
        XCTAssertEqual(decoded.resignedPlayers, state.resignedPlayers)
        XCTAssertEqual(decoded.drawVote, state.drawVote)
        XCTAssertEqual(decoded.hasAttemptedDrawVote, state.hasAttemptedDrawVote)
        XCTAssertEqual(decoded.auditLog, state.auditLog)
        XCTAssertEqual(decoded.lastTurnRecap, state.lastTurnRecap)
        XCTAssertEqual(decoded.settlementsByNode, state.settlementsByNode)
        XCTAssertEqual(decoded.citiesByNode, state.citiesByNode)
        XCTAssertEqual(decoded.roadsByEdge, state.roadsByEdge)
        XCTAssertEqual(decoded.boardRules, state.boardRules)
        XCTAssertEqual(decoded.board, state.board)
        XCTAssertEqual(decoded.turnState, state.turnState)
    }

    func testCompactStateTransportRoundTripsInactivePlayerAndDrawVote() throws {
        let activeState = makeState()
        let resigned = try apply(
            intent: GameLifecycleIntentV1.resign(anchoredTo: activeState),
            to: activeState,
            actor: "B"
        )
        let state = try apply(
            intent: .proposeDraw(anchoredTo: resigned),
            to: resigned,
            actor: "A"
        )

        let payload = try CompactStateTransport.encode(state)
        let decoded = try CompactStateTransport.decode(payload)

        XCTAssertEqual(decoded, state)
        XCTAssertEqual(decoded.phase, .turn)
        XCTAssertEqual(decoded.resignedPlayers, ["B"])
        XCTAssertEqual(decoded.drawVote, DrawVoteV1(proposedBy: "A", approvals: ["A"]))
        XCTAssertNoThrow(try validateCanonicalSnapshot(decoded))
    }

    func testCompactStateTransportRoundTripsNeutralHostEndResult() throws {
        let activeState = makeState()
        let state = try apply(
            intent: .endGame(anchoredTo: activeState),
            to: activeState,
            actor: "A"
        )

        let payload = try CompactStateTransport.encode(state)
        let decoded = try CompactStateTransport.decode(payload)

        XCTAssertEqual(decoded, state)
        XCTAssertEqual(decoded.gameResult?.reason, .hostEnded)
        XCTAssertEqual(decoded.gameResult?.endedByPlayer, "A")
        XCTAssertTrue(decoded.gameResult?.winnerPlayers.isEmpty == true)
        XCTAssertNoThrow(try validateCanonicalSnapshot(decoded))
    }

    func testCompactStateTransportShrinksEnvelopePayload() throws {
        let state = makeState()

        let rawPayload = try rawJSONString(from: state)
        let compactPayload = try CompactStateTransport.encode(state)

        let rawEnvelope = EnvelopeV1(kind: .state, body: .state(payload: rawPayload))
        let compactEnvelope = EnvelopeV1(kind: .state, body: .state(payload: compactPayload))

        let rawEncodedLength = try encodedStringLength(of: rawEnvelope)
        let compactEncodedLength = try encodedStringLength(of: compactEnvelope)

        XCTAssertLessThan(compactPayload.count, rawPayload.count)
        XCTAssertLessThan(compactEncodedLength, rawEncodedLength)
        XCTAssertLessThan(compactEncodedLength, 2048)
    }

    func testCompactStateTransportKeepsStressStateUnderURLBudgetWithoutSummaryMirror() throws {
        let state = makeStressState()
        let compactPayload = try CompactStateTransport.encode(state)
        let compactEnvelope = EnvelopeV1(kind: .state, body: .state(payload: compactPayload))
        let compactEncoded = try encode(compactEnvelope)

        let builtMessage = try TranscriptTransportSupport.buildMessage(
            encodedEnvelope: compactEncoded,
            caption: "Unlucky Sevens: Game updated",
            summaryLabel: "Latest game state is ready.",
            session: MSSession(),
            sessionPolicy: .state(gameId: state.gameId)
        )

        XCTAssertLessThan(compactPayload.count, try rawJSONString(from: state).count)
        XCTAssertLessThan(compactEncoded.count, 2048)
        XCTAssertLessThan(builtMessage.urlString.count, 2300)
        XCTAssertEqual(builtMessage.summaryText, "Latest game state is ready.")
    }

    private func rawJSONString(from state: CoreGameStateV1) throws -> String {
        let data = try JSONEncoder().encode(state)
        guard let string = String(data: data, encoding: .utf8) else {
            throw TransportError.invalidJSON
        }
        return string
    }

    private func makeState() -> CoreGameStateV1 {
        let roster = ["A", "B", "C"]
        let seed: UInt64 = 0x1234ABCD
        let rules = BoardRulesV1(strategy: .noRedAdjacentV1)
        let boardSeed = SeedDeriver(masterSeed: seed).seed(for: .board)
        let board = StandardBoardGeneratorV1.generate(boardSeed: boardSeed, rules: rules)

        let auditLog = (1...48).map { rev in
            AuditEntryV1(
                rev: rev,
                actor: roster[(rev - 1) % roster.count],
                action: rev.isMultiple(of: 6) ? .endTurn : .buildRoad,
                rollTotal: rev.isMultiple(of: 6) ? 8 : nil
            )
        }

        return CoreGameStateV1(
            gameId: "compact-transport-game",
            rev: 48,
            prevHash: String(repeating: "a", count: 64),
            stateHash: "",
            roster: roster,
            currentPlayer: "A",
            playerDisplayNamesByPlayer: [
                "A": "Host Alpha",
                "B": "Trader Beta",
            ],
            phase: .turn,
            seed: seed,
            diceRngState: SeedDeriver(masterSeed: seed).seed(for: .dice),
            robberRngState: SeedDeriver(masterSeed: seed).seed(for: .robber),
            resourcesByPlayer: [
                "A": ResourceHandV1(wood: 4, brick: 3, sheep: 2, wheat: 2, ore: 1),
                "B": ResourceHandV1(wood: 2, brick: 4, sheep: 3, wheat: 1, ore: 2),
                "C": ResourceHandV1(wood: 3, brick: 2, sheep: 4, wheat: 2, ore: 1),
            ],
            bankResources: ResourceHandV1(wood: 8, brick: 6, sheep: 5, wheat: 7, ore: 10),
            devDeck: [.knight, .monopoly, .roadBuilding, .yearOfPlenty, .victoryPoint],
            devCardsByPlayer: [
                "A": DevCardInventoryV1(knight: 1, victoryPoint: 1),
                "B": DevCardInventoryV1(monopoly: 1),
                "C": DevCardInventoryV1(yearOfPlenty: 1),
            ],
            newDevCardsByPlayer: [
                "A": .zero,
                "B": .zero,
                "C": DevCardInventoryV1(knight: 1),
            ],
            revealedVictoryPointsByPlayer: ["A": 1, "B": 0, "C": 0],
            devCardActionPlayedThisTurn: false,
            knightsPlayedByPlayer: ["A": 2, "B": 1, "C": 0],
            largestArmyOwner: "A",
            largestArmySize: 2,
            longestRoadOwner: "B",
            longestRoadLength: 5,
            winnerPlayer: nil,
            winningVictoryPoints: 0,
            auditLog: auditLog,
            lastTurnRecap: TurnRecapV1(
                actor: "C",
                startRev: 43,
                endRev: 48,
                rollTotal: 8,
                actions: [.buildRoad, .buildRoad, .buildRoad, .buildRoad, .buildRoad, .endTurn]
            ),
            activeTradeOffer: nil,
            tradeResponses: [],
            settlementsByNode: [0: "A", 10: "B", 20: "C"],
            citiesByNode: [5: "A"],
            roadsByEdge: [1: "A", 2: "A", 14: "B", 15: "B", 28: "C"],
            boardRules: rules,
            board: board,
            setupState: nil,
            turnState: TurnStateV1(step: .afterRoll, lastRoll: DiceRollV1(d1: 3, d2: 5))
        ).rehashed()
    }

    private func makeStressState() -> CoreGameStateV1 {
        let roster = ["A", "B", "C", "D"]
        let masterSeed: UInt64 = 0xD00DFEED
        let gameId = "compact-transport-stress"
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

        let auditLog = (1...rev).map { entryRev in
            let actions: [AuditActionV1] = [
                .rollDice,
                .buildRoad,
                .proposeTrade,
                .acceptTrade,
                .buyDevCard,
                .playKnight,
                .maritimeTrade,
                .buildSettlement,
                .buildCity,
                .endTurn,
            ]
            let action = actions[(entryRev - 1) % actions.count]
            let actor = roster[((entryRev - 1) / 6) % roster.count]
            let rollTotal: Int? = action == .rollDice ? (entryRev % 11) + 2 : nil
            return AuditEntryV1(rev: entryRev, actor: actor, action: action, rollTotal: rollTotal)
        }

        let offerHash = "stress-offer-hash-\(rev)"
        let activeTradeOffer = TradeOfferV1(
            offerHash: offerHash,
            proposer: "A",
            give: ResourceHandV1(wood: 2),
            receive: ResourceHandV1(ore: 1),
            recipients: ["B", "D"],
            createdRev: rev
        )
        let tradeResponses = [
            TradeResponseV1(respondingPlayer: "B", offerHash: offerHash, kind: .accept, respondedAtRev: rev),
            TradeResponseV1(respondingPlayer: "D", offerHash: offerHash, kind: .accept, respondedAtRev: rev),
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
            lastTurnRecap: TurnRecapV1(
                actor: "D",
                startRev: 235,
                endRev: rev,
                rollTotal: 8,
                actions: [.buildRoad, .buildSettlement, .buildCity, .buyDevCard, .playKnight, .endTurn]
            ),
            activeTradeOffer: activeTradeOffer,
            tradeResponses: tradeResponses,
            settlementsByNode: settlementsByNode,
            citiesByNode: citiesByNode,
            roadsByEdge: roadsByEdge,
            boardRules: boardRules,
            board: board,
            setupState: nil,
            turnState: TurnStateV1(step: .afterRoll, lastRoll: DiceRollV1(d1: 5, d2: 3))
        ).rehashed()
    }
}
