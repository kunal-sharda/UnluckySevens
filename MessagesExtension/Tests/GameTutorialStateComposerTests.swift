@testable import MessagesExtensionSupport
#if DEBUG
import ULS_CoreGame
import XCTest

final class GameTutorialStateComposerTests: XCTestCase {
    func testEveryTutorialStepUsesLegalPieceGeometry() throws {
        for step in GameTutorialStep.all {
            let state = GameTutorialStateComposer.state(for: step.id)
            try validateCanonicalSnapshot(state)
            assertLegalPieceGeometry(state, step: step.id)
        }
    }

    func testPostSetupTutorialStepsUseCompleteReachablePieceCounts() {
        for step in GameTutorialStep.all where ![.setupSettlement, .setupRoad].contains(step.id) {
            let state = GameTutorialStateComposer.state(for: step.id)

            for player in state.roster {
                let buildings = state.settlementsByNode.values.count(where: { $0 == player })
                    + state.citiesByNode.values.count(where: { $0 == player })
                let roads = state.roadsByEdge.values.count(where: { $0 == player })

                XCTAssertGreaterThanOrEqual(buildings, 2, "\(step.id) leaves \(player) short of completed setup.")
                XCTAssertGreaterThanOrEqual(roads, 2, "\(step.id) leaves \(player) short of completed setup.")
            }

            XCTAssertNil(state.longestRoadOwner)
            XCTAssertEqual(state.longestRoadLength, 0)
            XCTAssertTrue(state.roster.allSatisfy { player in
                state.roadsByEdge.values.count(where: { $0 == player }) < 5
            })
            XCTAssertEqual(state.largestArmyOwner, GameTutorialStateComposer.localPlayer)
            XCTAssertEqual(state.largestArmySize, 3)
            XCTAssertEqual(state.knightsPlayedByPlayer[GameTutorialStateComposer.localPlayer], 3)
        }
    }

    func testDefaultPositionComesFromCompletedSetupAndCoreBuilds() {
        let completedSetup = GameTutorialStateComposer.completedSetupStateForTesting
        let builtPosition = GameTutorialStateComposer.defaultPositionStateForTesting

        XCTAssertEqual(completedSetup.phase, .turn)
        XCTAssertNil(completedSetup.setupState)
        XCTAssertEqual(completedSetup.turnState?.step, .needsRoll)
        XCTAssertTrue(completedSetup.citiesByNode.isEmpty)

        for player in completedSetup.roster {
            XCTAssertEqual(completedSetup.settlementsByNode.values.count(where: { $0 == player }), 2)
            XCTAssertEqual(completedSetup.roadsByEdge.values.count(where: { $0 == player }), 2)
        }

        let localPlayer = GameTutorialStateComposer.localPlayer
        XCTAssertEqual(
            builtPosition.roadsByEdge.values.count(where: { $0 == localPlayer }),
            completedSetup.roadsByEdge.values.count(where: { $0 == localPlayer }) + 1
        )
        XCTAssertEqual(builtPosition.citiesByNode.values.count(where: { $0 == localPlayer }), 1)
        XCTAssertEqual(
            builtPosition.settlementsByNode.values.count(where: { $0 == localPlayer }),
            completedSetup.settlementsByNode.values.count(where: { $0 == localPlayer }) - 1
        )
        XCTAssertTrue(Set(completedSetup.roadsByEdge.keys).isSubset(of: builtPosition.roadsByEdge.keys))
        XCTAssertTrue(Set(builtPosition.citiesByNode.keys).isSubset(of: completedSetup.settlementsByNode.keys))
    }

    func testTutorialBuildAndRobberLessonsExposeTheirPromisedChoices() {
        let buildState = GameTutorialStateComposer.state(for: .legalPlacement)
        XCTAssertFalse(buildState.legalBuildRoadEdges(for: GameTutorialStateComposer.localPlayer).isEmpty)
        XCTAssertFalse(buildState.legalBuildSettlementNodes(for: GameTutorialStateComposer.localPlayer).isEmpty)
        XCTAssertFalse(buildState.legalBuildCityNodes(for: GameTutorialStateComposer.localPlayer).isEmpty)

        let victimState = GameTutorialStateComposer.state(for: .chooseVictim)
        XCTAssertEqual(
            Set(victimState.turnState?.eligibleStealVictims ?? []),
            Set(["tutorial-maya", "tutorial-theo"])
        )
    }

    func testTutorialMaritimePreviewUsesAnEngineDerivedLegalQuote() {
        let state = GameTutorialStateComposer.state(for: .bankTrade)
        let quote = state.maritimeTradeQuotes(for: GameTutorialStateComposer.localPlayer).first

        XCTAssertEqual(quote?.give, ResourceHandV1(wood: 3))
        XCTAssertEqual(quote?.receive, ResourceHandV1(brick: 1))
        XCTAssertEqual(quote?.ratio, 3)
    }

    private func assertLegalPieceGeometry(
        _ state: CoreGameStateV1,
        step: GameTutorialStep.ID,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let topology = StandardBoardTopologyV1.standard()
        let settlementNodes = Set(state.settlementsByNode.keys)
        let cityNodes = Set(state.citiesByNode.keys)
        let occupiedNodes = settlementNodes.union(cityNodes)

        XCTAssertTrue(settlementNodes.isDisjoint(with: cityNodes), "\(step) overlaps a city and settlement.", file: file, line: line)
        XCTAssertTrue(occupiedNodes.allSatisfy { topology.nodesCount > $0 && $0 >= 0 }, "\(step) has an invalid building node.", file: file, line: line)
        XCTAssertTrue(state.roadsByEdge.keys.allSatisfy { topology.edges.indices.contains($0) }, "\(step) has an invalid road edge.", file: file, line: line)

        for node in occupiedNodes {
            XCTAssertTrue(
                Set(topology.nodes(adjacentTo: node)).isDisjoint(with: occupiedNodes),
                "\(step) violates settlement distance at node \(node).",
                file: file,
                line: line
            )
        }

        for player in state.roster {
            let buildingNodes = Set(state.settlementsByNode.filter { $0.value == player }.map(\.key))
                .union(state.citiesByNode.filter { $0.value == player }.map(\.key))
            let ownedRoads = Set(state.roadsByEdge.filter { $0.value == player }.map(\.key))
            var reachedRoads = Set<EdgeID>()
            var reachedNodes = buildingNodes
            var madeProgress = true

            while madeProgress {
                madeProgress = false
                for edgeID in ownedRoads.subtracting(reachedRoads) {
                    let edge = topology.edges[edgeID]
                    guard reachedNodes.contains(edge.a) || reachedNodes.contains(edge.b) else { continue }
                    reachedRoads.insert(edgeID)
                    reachedNodes.insert(edge.a)
                    reachedNodes.insert(edge.b)
                    madeProgress = true
                }
            }

            XCTAssertEqual(
                reachedRoads,
                ownedRoads,
                "\(step) gives \(player) a road component disconnected from their buildings.",
                file: file,
                line: line
            )
        }
    }
}
#endif
