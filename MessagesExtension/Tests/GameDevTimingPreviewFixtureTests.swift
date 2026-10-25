#if DEBUG
import XCTest
@testable import MessagesExtensionSupport

final class GameDevTimingPreviewFixtureTests: XCTestCase {
    func testNewKnightFixtureIsOwnedButCannotBePlayedYet() throws {
        let fixture = UXTestFixtures.fixture(id: "preview-dev-timing-knight")
        let panel = try XCTUnwrap(GameDevCardPanelModelBuilder.build(state: fixture.state, actingAs: fixture.defaultActorID))
        XCTAssertEqual(panel.newCounts, [GameDevCardCount(title: "Knight", count: 1)])
        let card = try XCTUnwrap(panel.cards.first { $0.kind == .knight })
        XCTAssertFalse(card.isEnabled)
        XCTAssertNil(card.actionKind)
        XCTAssertTrue(panel.playActions.isEmpty)
    }

    func testNewVictoryPointFixtureHasNoPlayOrRevealAction() throws {
        let fixture = UXTestFixtures.fixture(id: "preview-dev-timing-vp")
        let panel = try XCTUnwrap(GameDevCardPanelModelBuilder.build(state: fixture.state, actingAs: fixture.defaultActorID))
        XCTAssertEqual(panel.newCounts, [GameDevCardCount(title: "Victory Point", count: 1)])
        let card = try XCTUnwrap(panel.cards.first { $0.kind == .victoryPoint })
        XCTAssertFalse(card.isEnabled)
        XCTAssertNil(card.actionKind)
        XCTAssertTrue(panel.playActions.isEmpty)
    }

    func testTimingFixturesDoNotExposeNewCardKindToOtherViewers() throws {
        for id in ["preview-dev-timing-knight", "preview-dev-timing-vp"] {
            let fixture = UXTestFixtures.fixture(id: id)
            let otherViewer = try XCTUnwrap(fixture.state.roster.first { $0 != fixture.defaultActorID })
            let panel = try XCTUnwrap(GameDevCardPanelModelBuilder.build(state: fixture.state, actingAs: otherViewer))
            XCTAssertTrue(panel.newCounts.isEmpty)
            XCTAssertTrue(panel.cards.isEmpty)
        }
    }
}
#endif
