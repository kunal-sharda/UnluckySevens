#if DEBUG
import ULS_CoreGame
import XCTest

final class UXTestingFixturesTests: XCTestCase {
    func testRecoveryFixtureSupportsPersistedNonTerminalResignation() throws {
        let active = try XCTUnwrap(UXTestFixtures.recoveryStates.first)
        let resigned = try apply(
            intent: .resign(anchoredTo: active),
            to: active,
            actor: UXTestFixtures.host
        )

        try validateCanonicalSnapshot(resigned)
        let compactPayload = try CompactStateTransport.encode(resigned)
        XCTAssertEqual(try CompactStateTransport.decode(compactPayload), resigned)

        let suiteName = "UXTestingFixturesTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        let store = TranscriptGameLedgerStore(userDefaults: defaults)
        store.record(
            state: active,
            payload: try CompactStateTransport.encode(active)
        )
        store.record(state: resigned, payload: compactPayload)

        XCTAssertEqual(store.latestState(for: active.gameId), resigned)
        XCTAssertTrue(
            ActiveGameRecoveryModelBuilder.build(
                from: resigned,
                updatedAt: 0,
                isLastActive: true,
                isCurrentSelection: true
            ).subtitle.contains("Kunal resigned")
        )
    }

    func testFixturesCoverSingleDeviceAuditSurfaces() {
        let fixtureIDs = Set(UXTestFixtures.all.map(\.id))

        XCTAssertTrue(fixtureIDs.contains("lobby-invite"))
        XCTAssertTrue(fixtureIDs.contains("lobby-ready"))
        XCTAssertTrue(fixtureIDs.contains("setup-placement"))
        XCTAssertTrue(fixtureIDs.contains("turn-needs-roll"))
        XCTAssertTrue(fixtureIDs.contains("turn-after-roll"))
        XCTAssertTrue(fixtureIDs.contains("waiting-on-alice"))
        XCTAssertTrue(fixtureIDs.contains("waiting-on-discard"))
        XCTAssertTrue(fixtureIDs.contains("pending-discard"))
        XCTAssertTrue(fixtureIDs.contains("robber-move"))
        XCTAssertTrue(fixtureIDs.contains("trade-offer"))
        XCTAssertTrue(fixtureIDs.contains("multi-type-trade-offer"))
        XCTAssertTrue(fixtureIDs.contains("game-over"))

        for fixture in UXTestFixtures.all {
            XCTAssertTrue(fixture.state.roster.contains(fixture.defaultActorID))
            XCTAssertTrue(fixture.actorIDs.contains(fixture.defaultActorID))
            XCTAssertEqual(fixture.state, fixture.state.rehashed())
        }
    }

    func testMultiTypeTradeOfferFixtureExercisesBothOfferLanes() {
        let fixture = UXTestFixtures.fixture(id: UXTestFixtures.multiTypeTradeOfferID)
        let offer = fixture.state.activeTradeOffer

        XCTAssertEqual(offer?.give, ResourceHandV1(wood: 1, sheep: 2, wheat: 1))
        XCTAssertEqual(offer?.receive, ResourceHandV1(brick: 2, ore: 1))
        XCTAssertEqual(
            Set(offer?.recipients ?? []),
            Set([UXTestFixtures.host, UXTestFixtures.ben])
        )
    }

    func testWaitingOnDiscardFixtureKeepsLocalPlayerPassive() {
        let fixture = UXTestFixtures.fixture(id: UXTestFixtures.waitingOnDiscardID)
        let panel = GameDiscardPanelModelBuilder.build(
            state: fixture.state,
            actingAs: UXTestFixtures.host
        )

        XCTAssertEqual(panel?.waitingPlayers, ["Theo"])
        XCTAssertNil(panel?.action)
        let context = GamePhysicalNotPrimaryPlayerContext.resolve(
            state: fixture.state,
            actingAs: UXTestFixtures.host,
            tradePanel: nil,
            discardPanel: panel
        )
        XCTAssertEqual(context, .waitingForDiscard)
        XCTAssertEqual(context?.headerPrompt, .waitingForDiscard)
        XCTAssertEqual(
            context?.headerTitle(fallback: "Waiting", discardPanel: panel),
            "Waiting"
        )
    }

    func testLobbyInviteFixtureCanBeDrivenByDummyJoiners() {
        let fixture = UXTestFixtures.fixture(id: "lobby-invite")

        XCTAssertEqual(fixture.state.roster, [UXTestFixtures.host])
        XCTAssertTrue(fixture.actorIDs.contains(UXTestFixtures.host))
        XCTAssertTrue(fixture.actorIDs.contains(UXTestFixtures.alice))
        XCTAssertTrue(fixture.actorIDs.contains(UXTestFixtures.ben))
    }

    func testAutoplaySeatsMissingDummyJoiner() {
        let fixture = UXTestFixtures.fixture(id: "lobby-invite")

        guard case let .joinDummy(actorID, displayName) = UXTestingAutoplayResolver.nextAction(
            state: fixture.state,
            fixture: fixture,
            humanActorID: UXTestFixtures.host
        ) else {
            XCTFail("Expected autoplay to seat the first missing dummy player.")
            return
        }

        XCTAssertEqual(actorID, UXTestFixtures.alice)
        XCTAssertEqual(displayName, "Maya")
    }

    func testAutoplayRollsCurrentDummyTurn() {
        let fixture = UXTestFixtures.fixture(id: "waiting-on-alice")

        guard case let .turn(draft) = UXTestingAutoplayResolver.nextAction(
            state: fixture.state,
            fixture: fixture,
            humanActorID: UXTestFixtures.host
        ) else {
            XCTFail("Expected autoplay to draft Maya's roll.")
            return
        }

        XCTAssertEqual(draft.actor, UXTestFixtures.alice)
        XCTAssertEqual(draft.intent, .rollDice)
    }

    func testAutoplayDoesNotControlHumanTurn() {
        let fixture = UXTestFixtures.fixture(id: "turn-needs-roll")

        XCTAssertNil(
            UXTestingAutoplayResolver.nextAction(
                state: fixture.state,
                fixture: fixture,
                humanActorID: UXTestFixtures.host
            )
        )
    }

    func testAutoplayDraftsDiscardForNextDummyPendingDiscard() {
        let fixture = UXTestFixtures.fixture(id: "pending-discard")

        guard case let .turn(draft) = UXTestingAutoplayResolver.nextAction(
            state: fixture.state,
            fixture: fixture,
            humanActorID: UXTestFixtures.ben
        ) else {
            XCTFail("Expected autoplay to draft the next dummy discard.")
            return
        }

        XCTAssertEqual(draft.actor, UXTestFixtures.host)
        guard case let .submitDiscard(player, discarded) = draft.intent else {
            XCTFail("Expected discard intent.")
            return
        }
        XCTAssertEqual(player, UXTestFixtures.host)
        XCTAssertEqual(discarded.totalCount, 5)
    }

    func testFixturesCoverCoreVisualPhases() {
        let fixturesByID = Dictionary(uniqueKeysWithValues: UXTestFixtures.all.map { ($0.id, $0) })

        XCTAssertEqual(fixturesByID["lobby-invite"]?.state.phase, .lobby)
        XCTAssertNil(fixturesByID["lobby-invite"]?.state.board)
        XCTAssertEqual(fixturesByID["setup-placement"]?.state.phase, .setup)
        XCTAssertNotNil(fixturesByID["setup-placement"]?.state.setupState)
        XCTAssertEqual(fixturesByID["turn-after-roll"]?.state.phase, .turn)
        XCTAssertNotNil(fixturesByID["turn-after-roll"]?.state.board)
        XCTAssertNotNil(fixturesByID["trade-offer"]?.state.activeTradeOffer)
        XCTAssertEqual(fixturesByID["game-over"]?.state.phase, .gameOver)
        XCTAssertEqual(fixturesByID["game-over"]?.state.winnerPlayer, UXTestFixtures.host)
    }

    func testTurnAfterRollFixtureExposesTheNormalTurnMatrix() throws {
        let fixture = UXTestFixtures.fixture(id: "turn-after-roll")
        let state = fixture.state

        XCTAssertFalse(state.legalBuildRoadEdges(for: UXTestFixtures.host).isEmpty)
        XCTAssertFalse(state.legalBuildSettlementNodes(for: UXTestFixtures.host).isEmpty)
        XCTAssertFalse(state.legalBuildCityNodes(for: UXTestFixtures.host).isEmpty)
        XCTAssertTrue(state.canInitiatePlayerTrade(for: UXTestFixtures.host))
        XCTAssertFalse(state.legalKnightMoveTilesForDevCard(for: UXTestFixtures.host).isEmpty)
        XCTAssertFalse(state.monopolyPreviews(for: UXTestFixtures.host).isEmpty)
        XCTAssertFalse(state.yearOfPlentyBankOptions(for: UXTestFixtures.host).isEmpty)
        XCTAssertFalse(state.legalRoadBuildingFirstEdges(for: UXTestFixtures.host).isEmpty)
    }

    func testEveryBoardFixtureUsesLegalConnectedPieceGeometry() {
        for fixture in UXTestFixtures.all where fixture.state.board != nil {
            assertLegalPieceGeometry(fixture.state, fixtureID: fixture.id)
        }
        for (index, state) in UXTestFixtures.recoveryStates.enumerated() where state.board != nil {
            assertLegalPieceGeometry(state, fixtureID: "recovery-\(index)")
        }
    }

    private func assertLegalPieceGeometry(
        _ state: CoreGameStateV1,
        fixtureID: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let topology = StandardBoardTopologyV1.standard()
        let settlementNodes = Set(state.settlementsByNode.keys)
        let cityNodes = Set(state.citiesByNode.keys)
        let occupiedNodes = settlementNodes.union(cityNodes)

        XCTAssertTrue(
            settlementNodes.isDisjoint(with: cityNodes),
            "\(fixtureID) overlaps a city and settlement.",
            file: file,
            line: line
        )
        XCTAssertTrue(
            occupiedNodes.allSatisfy { $0 >= 0 && $0 < topology.nodesCount },
            "\(fixtureID) has an invalid building node.",
            file: file,
            line: line
        )
        XCTAssertTrue(
            state.roadsByEdge.keys.allSatisfy { topology.edges.indices.contains($0) },
            "\(fixtureID) has an invalid road edge.",
            file: file,
            line: line
        )

        for nodeID in occupiedNodes {
            XCTAssertTrue(
                Set(topology.nodes(adjacentTo: nodeID)).isDisjoint(with: occupiedNodes),
                "\(fixtureID) violates settlement distance at node \(nodeID).",
                file: file,
                line: line
            )
        }

        for playerID in state.roster {
            let buildingNodes = Set(
                state.settlementsByNode.filter { $0.value == playerID }.map(\.key)
            ).union(
                state.citiesByNode.filter { $0.value == playerID }.map(\.key)
            )
            let ownedRoads = Set(
                state.roadsByEdge.filter { $0.value == playerID }.map(\.key)
            )
            var reachedRoads = Set<EdgeID>()
            var reachedNodes = buildingNodes
            var madeProgress = true

            while madeProgress {
                madeProgress = false
                for edgeID in ownedRoads.subtracting(reachedRoads) {
                    let edge = topology.edges[edgeID]
                    guard reachedNodes.contains(edge.a) || reachedNodes.contains(edge.b) else {
                        continue
                    }
                    reachedRoads.insert(edgeID)
                    reachedNodes.insert(edge.a)
                    reachedNodes.insert(edge.b)
                    madeProgress = true
                }
            }

            XCTAssertEqual(
                reachedRoads,
                ownedRoads,
                "\(fixtureID) gives \(playerID) a road component disconnected from their buildings.",
                file: file,
                line: line
            )
        }
    }
}
#endif
