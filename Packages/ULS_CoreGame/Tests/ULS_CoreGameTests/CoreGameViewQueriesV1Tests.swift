import XCTest
@testable import ULS_CoreGame

final class CoreGameViewQueriesV1Tests: XCTestCase {
    private let topology = StandardBoardTopologyV1.standard()

    func testVisibleProjectionRevealsLocalDetailOnly() throws {
        let state = makeState(
            resourcesByPlayer: [
                "A": ResourceHandV1(wood: 1, brick: 2),
                "B": ResourceHandV1(sheep: 3),
                "C": ResourceHandV1(wheat: 1, ore: 1),
            ],
            devCardsByPlayer: [
                "A": DevCardInventoryV1(knight: 1, monopoly: 1),
                "B": DevCardInventoryV1(roadBuilding: 1),
                "C": .zero,
            ],
            newDevCardsByPlayer: [
                "A": DevCardInventoryV1(victoryPoint: 1),
                "B": DevCardInventoryV1(yearOfPlenty: 1),
                "C": .zero,
            ]
        )

        let visibleResources = state.visibleResourceHands(for: "A")
        let aResources = try XCTUnwrap(visibleResources.first { $0.player == "A" })
        let bResources = try XCTUnwrap(visibleResources.first { $0.player == "B" })
        XCTAssertEqual(aResources.revealedHand, ResourceHandV1(wood: 1, brick: 2))
        XCTAssertEqual(aResources.totalCount, 3)
        XCTAssertNil(bResources.revealedHand)
        XCTAssertEqual(bResources.totalCount, 3)
        XCTAssertNil(state.visibleResourceHands(for: nil).first { $0.player == "A" }?.revealedHand)

        let visibleDevCards = state.visibleDevCards(for: "A")
        let aDevCards = try XCTUnwrap(visibleDevCards.first { $0.player == "A" })
        let bDevCards = try XCTUnwrap(visibleDevCards.first { $0.player == "B" })
        XCTAssertEqual(aDevCards.revealedPlayable, DevCardInventoryV1(knight: 1, monopoly: 1))
        XCTAssertEqual(aDevCards.revealedNew, DevCardInventoryV1(victoryPoint: 1))
        XCTAssertEqual(aDevCards.totalCount, 3)
        XCTAssertNil(bDevCards.revealedPlayable)
        XCTAssertNil(bDevCards.revealedNew)
        XCTAssertEqual(bDevCards.totalCount, 2)
    }

    func testBuildQueriesExposeReducerLegalTargets() throws {
        let homeNode = topology.tiles[0].nodes[0]
        let firstRoad = topology.edges(incidentTo: homeNode)[0]
        let firstRoadEdge = topology.edges[firstRoad]
        let intermediateNode = firstRoadEdge.a == homeNode ? firstRoadEdge.b : firstRoadEdge.a
        let settlementReachRoad = try XCTUnwrap(
            topology.edges(incidentTo: intermediateNode).first { edgeID in
                guard edgeID != firstRoad else {
                    return false
                }
                let edge = topology.edges[edgeID]
                let farNode = edge.a == intermediateNode ? edge.b : edge.a
                return farNode != homeNode && !topology.nodes(adjacentTo: homeNode).contains(farNode)
            }
        )
        let state = makeState(
            resourcesByPlayer: [
                "A": ResourceHandV1(wood: 5, brick: 5, sheep: 5, wheat: 5, ore: 5),
                "B": .zero,
            ],
            devCardsByPlayer: [
                "A": DevCardInventoryV1(roadBuilding: 1),
                "B": .zero,
            ],
            settlementsByNode: [homeNode: "A"],
            roadsByEdge: [firstRoad: "A", settlementReachRoad: "A"]
        )

        let roadEdge = try XCTUnwrap(state.firstLegalRoadEdge(for: "A"))
        let settlementNode = try XCTUnwrap(state.firstLegalSettlementNode(for: "A"))
        let cityNode = try XCTUnwrap(state.firstUpgradeableCityNode(for: "A"))
        let roadBuilding = try XCTUnwrap(state.defaultRoadBuildingEdges(for: "A"))

        let roadBuilt = try apply(intent: .buildRoad(edgeID: roadEdge), to: state, actor: "A")
        XCTAssertEqual(roadBuilt.roadsByEdge[roadEdge], "A")

        let settlementBuilt = try apply(intent: .buildSettlement(nodeID: settlementNode), to: state, actor: "A")
        XCTAssertEqual(settlementBuilt.settlementsByNode[settlementNode], "A")

        let cityBuilt = try apply(intent: .buildCity(nodeID: cityNode), to: state, actor: "A")
        XCTAssertEqual(cityBuilt.citiesByNode[cityNode], "A")

        let roadBuildingPlayed = try apply(
            intent: .playRoadBuilding(
                firstEdgeID: roadBuilding.firstEdgeID,
                secondEdgeID: roadBuilding.secondEdgeID
            ),
            to: state,
            actor: "A"
        )
        XCTAssertEqual(roadBuildingPlayed.roadsByEdge[roadBuilding.firstEdgeID], "A")
        XCTAssertEqual(roadBuildingPlayed.roadsByEdge[roadBuilding.secondEdgeID], "A")
    }

    func testBuildQueriesRespectTurnContextAndAffordability() throws {
        let homeNode = topology.tiles[0].nodes[0]
        let firstRoad = topology.edges(incidentTo: homeNode)[0]
        let state = makeState(
            resourcesByPlayer: [
                "A": ResourceHandV1(wood: 1),
                "B": .zero,
            ],
            settlementsByNode: [homeNode: "A"],
            roadsByEdge: [firstRoad: "A"]
        )

        XCTAssertTrue(state.legalBuildRoadEdges(for: "A").isEmpty)
        XCTAssertTrue(state.legalBuildSettlementNodes(for: "A").isEmpty)
        XCTAssertTrue(state.legalBuildCityNodes(for: "A").isEmpty)
        XCTAssertNil(state.firstLegalRoadEdge(for: "A"))
        XCTAssertNil(state.firstLegalSettlementNode(for: "A"))
        XCTAssertNil(state.firstUpgradeableCityNode(for: "A"))
    }

    func testSetupAndRobberQueriesExposeLegalTargetSets() throws {
        let setupSettlementState = makeSetupState()
        let settlementTargets = setupSettlementState.legalSetupSettlementNodes(for: "A")
        XCTAssertFalse(settlementTargets.isEmpty)

        let chosenSettlement = try XCTUnwrap(settlementTargets.first)
        let setupRoadState = makeSetupState(
            step: .placeRoad,
            placements: [
                "A": PlayerSetupPlacementsV1(settlement1: chosenSettlement),
            ],
            lastPlacedSettlementNode: chosenSettlement
        )
        let roadTargets = setupRoadState.legalSetupRoadEdges(for: "A")
        XCTAssertEqual(
            roadTargets,
            topology.edges(incidentTo: chosenSettlement).sorted()
        )

        let victimNode = try XCTUnwrap(topology.tiles[1].nodes.first)
        let robberMoveState = makeState(
            resourcesByPlayer: ["A": .zero, "B": .zero],
            turnState: TurnStateV1(step: .needsRobberMove, lastRoll: DiceRollV1(d1: 4, d2: 3))
        )
        let robberTargets = robberMoveState.legalRobberMoveTiles(for: "A")
        XCTAssertEqual(robberTargets.count, 18)
        XCTAssertFalse(robberTargets.contains(1))

        let robberVictimState = makeState(
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
        XCTAssertEqual(robberVictimState.robberVictimCandidateNodes(for: "A"), [victimNode])
    }

    func testDefaultActionQueriesReturnDeterministicSelections() throws {
        let woodPortNode = try XCTUnwrap(portNode {
            if case .twoToOne(.wood) = $0 {
                return true
            }
            return false
        })
        let victimNode = try XCTUnwrap(topology.tiles[0].nodes.first { $0 != woodPortNode })
        let discardState = makeState(
            resourcesByPlayer: [
                "A": ResourceHandV1(wood: 2, brick: 1, sheep: 1, wheat: 1),
                "B": .zero,
            ],
            turnState: TurnStateV1(
                step: .pendingDiscards,
                lastRoll: DiceRollV1(d1: 3, d2: 4),
                discardRequirementsByPlayer: ["A": 4]
            )
        )
        XCTAssertEqual(
            discardState.defaultDiscard(for: "A"),
            ResourceHandV1(wood: 2, brick: 1, sheep: 1)
        )

        let tradeState = makeState(
            resourcesByPlayer: [
                "A": ResourceHandV1(wood: 2, ore: 2),
                "B": ResourceHandV1(brick: 2),
                "C": ResourceHandV1(brick: 1, sheep: 1),
            ],
            settlementsByNode: [
                woodPortNode: "A",
                victimNode: "B",
            ]
        )

        let tradeProposal = try XCTUnwrap(tradeState.defaultTradeProposal(for: "A"))
        XCTAssertEqual(tradeProposal.give, ResourceHandV1(wood: 1))
        XCTAssertEqual(tradeProposal.receive, ResourceHandV1(brick: 1))

        let maritimeTrade = try XCTUnwrap(tradeState.defaultMaritimeTrade(for: "A"))
        XCTAssertEqual(maritimeTrade.give, ResourceHandV1(wood: 2))
        XCTAssertEqual(maritimeTrade.receive, ResourceHandV1(brick: 1))
        XCTAssertEqual(maritimeTrade.ratio, 2)

        XCTAssertEqual(tradeState.defaultKnightVictim(for: 0, actor: "A"), "B")
        XCTAssertEqual(tradeState.defaultMonopolyResource(for: "A"), .brick)
        XCTAssertEqual(
            tradeState.defaultYearOfPlentyResources(),
            ResourcePairV1(first: .wood, second: .wood)
        )
    }

    func testTradeInitiationQueriesRequireARealExecutableRoute() throws {
        let playerTradeState = makeState(
            resourcesByPlayer: [
                "A": ResourceHandV1(wood: 1),
                "B": .zero,
            ]
        )
        XCTAssertTrue(playerTradeState.canInitiatePlayerTrade(for: "A"))
        XCTAssertFalse(playerTradeState.canInitiatePlayerTrade(for: "B"))

        let emptyHandState = makeState(
            resourcesByPlayer: [
                "A": .zero,
                "B": ResourceHandV1(brick: 1),
            ]
        )
        XCTAssertFalse(emptyHandState.canInitiatePlayerTrade(for: "A"))

        let maritimeState = makeState(
            resourcesByPlayer: [
                "A": ResourceHandV1(wood: 4),
                "B": .zero,
            ]
        )
        XCTAssertTrue(maritimeState.canInitiateMaritimeTrade(for: "A"))

        let offer = TradeOfferV1(
            offerHash: "offer",
            proposer: "A",
            give: ResourceHandV1(wood: 1),
            receive: ResourceHandV1(brick: 1),
            recipients: ["B"],
            createdRev: 120
        )
        let pendingOfferState = makeState(
            resourcesByPlayer: [
                "A": ResourceHandV1(wood: 4),
                "B": ResourceHandV1(brick: 1),
            ],
            activeTradeOffer: offer
        )
        XCTAssertFalse(pendingOfferState.canInitiatePlayerTrade(for: "A"))
        XCTAssertFalse(pendingOfferState.canInitiateMaritimeTrade(for: "A"))
    }

    func testChoiceDrivenDevCardQueriesExposeLegalSelections() throws {
        let homeNode = topology.tiles[0].nodes[0]
        let victimNode = topology.tiles[2].nodes[0]
        let firstRoadOptions = topology.edges(incidentTo: homeNode).sorted()
        let state = makeState(
            resourcesByPlayer: [
                "A": .zero,
                "B": ResourceHandV1(wood: 1, brick: 2),
                "C": ResourceHandV1(ore: 1),
            ],
            bankResources: ResourceHandV1(wood: 2, brick: 0, sheep: 1, wheat: 3, ore: 1),
            devCardsByPlayer: [
                "A": DevCardInventoryV1(knight: 1, monopoly: 1, yearOfPlenty: 1, roadBuilding: 1, victoryPoint: 1),
                "B": .zero,
                "C": .zero,
            ],
            revealedVictoryPointsByPlayer: [
                "A": 9,
                "B": 0,
                "C": 0,
            ],
            settlementsByNode: [
                homeNode: "A",
                victimNode: "B",
            ]
        )

        XCTAssertEqual(state.legalKnightMoveTilesForDevCard(for: "A").count, 18)
        XCTAssertEqual(state.legalKnightVictims(for: 2, actor: "A"), ["B"])
        XCTAssertEqual(state.knightVictimCandidateNodes(for: 2, actor: "A"), [victimNode])

        let monopolyPreviews = state.monopolyPreviews(for: "A")
        XCTAssertEqual(monopolyPreviews.count, 5)
        XCTAssertEqual(monopolyPreviews.first(where: { $0.resource == ResourceV1.brick })?.claimCount, 2)
        XCTAssertEqual(monopolyPreviews.first(where: { $0.resource == ResourceV1.ore })?.claimCount, 1)

        let bankOptions = state.yearOfPlentyBankOptions(for: "A")
        XCTAssertEqual(
            bankOptions.map { $0.resource },
            [ResourceV1.wood, ResourceV1.sheep, ResourceV1.wheat, ResourceV1.ore]
        )
        XCTAssertEqual(bankOptions.first(where: { $0.resource == ResourceV1.wood })?.remainingCount, 2)

        let legalFirstEdges = state.legalRoadBuildingFirstEdges(for: "A")
        XCTAssertFalse(legalFirstEdges.isEmpty)
        XCTAssertEqual(legalFirstEdges, firstRoadOptions)
        let secondEdges = state.legalRoadBuildingSecondEdges(for: "A", firstEdgeID: legalFirstEdges[0])
        XCTAssertFalse(secondEdges.isEmpty)

        XCTAssertTrue(state.canRevealVictoryPoint(for: "A"))
        XCTAssertFalse(state.canRevealVictoryPoint(for: "B"))
    }

    private func makeState(
        resourcesByPlayer: [String: ResourceHandV1],
        bankResources: ResourceHandV1 = .standardBank,
        devCardsByPlayer: [String: DevCardInventoryV1] = [:],
        newDevCardsByPlayer: [String: DevCardInventoryV1] = [:],
        revealedVictoryPointsByPlayer: [String: Int] = [:],
        settlementsByNode: [NodeID: String] = [:],
        citiesByNode: [NodeID: String] = [:],
        roadsByEdge: [EdgeID: String] = [:],
        activeTradeOffer: TradeOfferV1? = nil,
        turnState: TurnStateV1 = TurnStateV1(step: .afterRoll, lastRoll: DiceRollV1(d1: 4, d2: 3))
    ) -> CoreGameStateV1 {
        let roster = Array(resourcesByPlayer.keys).sorted()
        let normalizedDevCards = roster.reduce(into: [String: DevCardInventoryV1]()) { partial, player in
            partial[player] = devCardsByPlayer[player] ?? .zero
        }
        let normalizedNewDevCards = roster.reduce(into: [String: DevCardInventoryV1]()) { partial, player in
            partial[player] = newDevCardsByPlayer[player] ?? .zero
        }
        let board = BoardSetupV1(
            resourcesByTile: [.wood] + Array(repeating: .desert, count: 18),
            numbersByTile: [5] + Array(repeating: nil, count: 18),
            portsByIndex: topology.ports.map(\.kind),
            robberTile: 1,
            generator: .randomV1,
            boardHash: ""
        ).rehashed()

        return CoreGameStateV1(
            gameId: "game-view-queries",
            rev: 120,
            prevHash: "hash-119",
            stateHash: "",
            roster: roster,
            currentPlayer: "A",
            phase: .turn,
            seed: 42,
            diceRngState: 43,
            robberRngState: 44,
            resourcesByPlayer: resourcesByPlayer,
            bankResources: bankResources,
            devDeck: [],
            devCardsByPlayer: normalizedDevCards,
            newDevCardsByPlayer: normalizedNewDevCards,
            revealedVictoryPointsByPlayer: revealedVictoryPointsByPlayer,
            activeTradeOffer: activeTradeOffer,
            settlementsByNode: settlementsByNode,
            citiesByNode: citiesByNode,
            roadsByEdge: roadsByEdge,
            boardRules: BoardRulesV1(strategy: .randomV1),
            board: board,
            setupState: nil,
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
            gameId: "setup-query-view-queries",
            rev: 12,
            prevHash: "hash-11",
            stateHash: "",
            roster: ["A", "B"],
            currentPlayer: "A",
            phase: .setup,
            seed: 7,
            diceRngState: 8,
            robberRngState: 9,
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

    private func portNode(matching predicate: (PortKindV1) -> Bool) -> NodeID? {
        for (index, port) in topology.ports.enumerated() where predicate(port.kind) {
            let edgeID = topology.ports[index].edge
            return topology.edges[edgeID].a
        }
        return nil
    }
}
