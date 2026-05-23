#if DEBUG
import ULS_CoreGame
import XCTest

final class UXTestingFixturesTests: XCTestCase {
    func testFixturesCoverSingleDeviceAuditSurfaces() {
        let fixtureIDs = Set(UXTestFixtures.all.map(\.id))

        XCTAssertTrue(fixtureIDs.contains("lobby-invite"))
        XCTAssertTrue(fixtureIDs.contains("lobby-ready"))
        XCTAssertTrue(fixtureIDs.contains("setup-placement"))
        XCTAssertTrue(fixtureIDs.contains("turn-needs-roll"))
        XCTAssertTrue(fixtureIDs.contains("turn-after-roll"))
        XCTAssertTrue(fixtureIDs.contains("waiting-on-alice"))
        XCTAssertTrue(fixtureIDs.contains("pending-discard"))
        XCTAssertTrue(fixtureIDs.contains("robber-move"))
        XCTAssertTrue(fixtureIDs.contains("trade-offer"))
        XCTAssertTrue(fixtureIDs.contains("game-over"))

        for fixture in UXTestFixtures.all {
            XCTAssertTrue(fixture.state.roster.contains(fixture.defaultActorID))
            XCTAssertTrue(fixture.actorIDs.contains(fixture.defaultActorID))
            XCTAssertEqual(fixture.state, fixture.state.rehashed())
        }
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
}
#endif
