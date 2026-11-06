import ULS_CoreGame
import XCTest
@testable import MessagesExtensionSupport

@MainActor
final class GameFlightDeliveryTests: XCTestCase {
    func testReceiptMatchesVerifiedRollAndRejectsUnrelatedState() throws {
        let before = GameTutorialStateComposer.state(for: .rollDice)
        let after = try apply(intent: .rollDice, to: before, actor: before.currentPlayer)
        let viewer = GameTutorialStateComposer.localPlayer
        let receipt = try XCTUnwrap(after.productionReceipt(from: before, for: viewer))
        XCTAssertEqual(receipt.roll, after.turnState?.lastRoll)
        for resource in [ResourceV1.wood, .brick, .sheep, .wheat, .ore] {
            XCTAssertEqual(receipt.gains.count(for: resource),
                           (after.resourcesByPlayer[viewer]?.count(for: resource) ?? 0)
                           - (before.resourcesByPlayer[viewer]?.count(for: resource) ?? 0))
        }
        XCTAssertNil(after.productionReceipt(from: after, for: viewer))
        XCTAssertNil(after.productionReceipt(from: before, for: "spectator"))
        XCTAssertNil(before.productionReceipt(from: after, for: viewer))
    }

    func testReceiptAnnouncementNamesOnlyVerifiedLocalGains() throws {
        let before = GameTutorialStateComposer.state(for: .rollDice)
        let after = try apply(intent: .rollDice, to: before, actor: before.currentPlayer)
        let receipt = try XCTUnwrap(after.productionReceipt(from: before, for: GameTutorialStateComposer.localPlayer))
        let copy = GameRollReceiptView.announcement(receipt: receipt, rollerName: "Roller")
        XCTAssertTrue(copy.hasPrefix("Roller rolled \(receipt.roll.d1) plus \(receipt.roll.d2), total \(receipt.roll.d1 + receipt.roll.d2)."))
        if receipt.roll.d1 + receipt.roll.d2 == 7 {
            XCTAssertTrue(copy.contains("No production."))
        } else if receipt.gains.totalCount == 0 {
            XCTAssertTrue(copy.contains("You received no resources."))
        } else {
            for resource in [ResourceV1.wood, .brick, .sheep, .wheat, .ore] where receipt.gains.count(for: resource) > 0 {
                XCTAssertTrue(copy.contains("\(receipt.gains.count(for: resource)) \(resource.rawValue)"))
            }
        }
        XCTAssertFalse(copy.contains("opponent"))
    }

    func testNoProductionFixtureAnnouncesBankShortageWithoutOpponentPayouts() throws {
        let fixture = UXTestFixtures.fixture(id: "roll-bank-shortage")
        XCTAssertEqual(fixture.id, "roll-bank-shortage")
        let after = try apply(intent: .rollDice, to: fixture.state, actor: fixture.defaultActorID)
        let receipt = try XCTUnwrap(after.productionReceipt(from: fixture.state, for: fixture.defaultActorID))
        XCTAssertEqual(receipt.gains.totalCount, 0)
        XCTAssertTrue(receipt.bankShortage)
        let copy = GameRollReceiptView.announcement(receipt: receipt, rollerName: "Roller")
        XCTAssertTrue(copy.contains("You received no resources."))
        XCTAssertTrue(copy.contains("The Bank could not supply some of your production."))
    }

    func testReceiptPersistsWithoutAttributingLaterTurnToProduction() throws {
        let name = "GameFlightDeliveryTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defer { defaults.removePersistentDomain(forName: name) }
        let store = GameRollReceiptStore(defaults: defaults)
        let before = GameTutorialStateComposer.state(for: .rollDice)
        let after = try apply(intent: .rollDice, to: before, actor: before.currentPlayer)
        let viewer = GameTutorialStateComposer.localPlayer
        let receipt = try XCTUnwrap(store.observe(after, previous: before, viewer: viewer))
        XCTAssertEqual(GameRollReceiptStore(defaults: defaults).observe(after, previous: nil, viewer: viewer), receipt)
        XCTAssertNil(store.observe(before, previous: after, viewer: viewer))
        XCTAssertNil(store.observe(after, previous: nil, viewer: "spectator"))
        let preferences = AppPreferences(userDefaults: defaults)
        XCTAssertTrue(preferences.claimRollReceipt(gameID: after.gameId, revision: after.rev))
        XCTAssertFalse(preferences.claimRollReceipt(gameID: after.gameId, revision: after.rev))
        XCTAssertFalse(preferences.claimRollReceipt(gameID: after.gameId, revision: before.rev))
    }

    func testReceiptRequiresPredecessorAndDoesNotCrossSiblingBranches() throws {
        let name = "GameFlightDeliveryTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defer { defaults.removePersistentDomain(forName: name) }
        let store = GameRollReceiptStore(defaults: defaults)
        let before = GameTutorialStateComposer.state(for: .rollDice)
        let after = try apply(intent: .rollDice, to: before, actor: before.currentPlayer)
        let viewer = GameTutorialStateComposer.localPlayer
        XCTAssertNil(store.observe(after, previous: nil, viewer: viewer))
        let receipt = try XCTUnwrap(store.observe(after, previous: before, viewer: viewer))
        let ended = try apply(intent: .endTurn, to: after, actor: after.currentPlayer)
        XCTAssertEqual(store.observe(ended, previous: after, viewer: viewer), receipt)
        let sibling = try apply(intent: .buyDevCard, to: after, actor: after.currentPlayer)
        XCTAssertNil(store.observe(sibling, previous: after, viewer: viewer))
        XCTAssertEqual(store.observe(ended, previous: nil, viewer: viewer), receipt)
    }

    func testContinuationCoversSetupForcedActionsAndOpenTurn() {
        let fixtures: [(GameTutorialStep.ID, String)] = [
            (.setupSettlement, "places a settlement"),
            (.setupRoad, "places a connected road"),
            (.rollDice, "rolls next"),
            (.discard, "discards next"),
            (.moveRobber, "moves the robber"),
            (.chooseVictim, "chooses a player"),
            (.buildCosts, "continues their turn")
        ]
        for (fixture, expected) in fixtures {
            let state = GameTutorialStateComposer.state(for: fixture)
            XCTAssertTrue(GameContinuation.text(for: state)?.contains(expected) == true, "\(fixture)")
        }
    }

    func testOwnershipMarksAreStableAndDistinctInRosterOrder() {
        let roster = ["Alice", "Alice-2", "long-name", "fallback"]
        let marks = roster.map { GamePlayerMark.resolve(owner: $0, playerOrder: roster) }
        XCTAssertEqual(marks.map(\.rawValue), [0, 1, 2, 3])
        XCTAssertEqual(Set(marks.map(\.name)).count, 4)
        for mark in marks {
            XCTAssertFalse(mark.path(in: CGRect(x: 0, y: 0, width: 10, height: 10)).isEmpty)
        }
    }
}
