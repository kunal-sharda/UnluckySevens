import XCTest
@testable import MessagesExtensionSupport

final class GamePublicPileLevelTests: XCTestCase {
    func testResourceLevelsUseThirdsOfTheStandardPile() {
        XCTAssertEqual(GamePublicPileLevel.resource(remaining: 19), .high)
        XCTAssertEqual(GamePublicPileLevel.resource(remaining: 13), .high)
        XCTAssertEqual(GamePublicPileLevel.resource(remaining: 12), .medium)
        XCTAssertEqual(GamePublicPileLevel.resource(remaining: 7), .medium)
        XCTAssertEqual(GamePublicPileLevel.resource(remaining: 6), .low)
        XCTAssertEqual(GamePublicPileLevel.resource(remaining: 0), .low)
    }

    func testResourceSupplyBoundariesAndEmptyPresentation() {
        for (count, segments, description) in [
            (-1, 0, "Bank supply empty"), (0, 0, "Bank supply empty"),
            (1, 1, "Bank supply Low"), (6, 1, "Bank supply Low"),
            (7, 2, "Bank supply Medium"), (12, 2, "Bank supply Medium"),
            (13, 3, "Bank supply High"), (19, 3, "Bank supply High"),
            (20, 3, "Bank supply High"),
        ] {
            XCTAssertEqual(GamePublicPileLevel.resourceFilledSegments(remaining: count), segments)
            XCTAssertEqual(GamePublicPileLevel.resourceSupplyDescription(remaining: count), description)
        }
    }

    func testSupplyDescriptionsNeverExposeExactInventory() {
        for count in 0...19 {
            let text = GamePublicPileLevel.resourceSupplyDescription(remaining: count)
            XCTAssertFalse(text.contains(where: { $0.isNumber }))
        }
        XCTAssertEqual(GamePublicPileLevel.devCards(remaining: 25).symbol, "H")
    }

    func testDevSupplyBarsUseCoarseBandsAndAnEmptyTrack() {
        for (count, filled) in [(-1, 0), (0, 0), (1, 1), (8, 1), (9, 2), (16, 2), (17, 3), (25, 3), (26, 3)] {
            XCTAssertEqual(GamePublicPileLevel.devCardFilledSegments(remaining: count), filled)
            XCTAssertFalse(GamePublicPileLevel.devCardSupplyDescription(remaining: count).contains(where: { $0.isNumber }))
        }
        XCTAssertEqual(GamePublicPileLevel.devCardSupplyDescription(remaining: 0), "Dev Card supply empty")
        XCTAssertEqual(GamePublicPileLevel.devCardSupplyDescription(remaining: 9), "Dev Card supply Medium")
    }

    func testDevCardLevelsUseThirdsOfTheStandardPile() {
        XCTAssertEqual(GamePublicPileLevel.devCards(remaining: 25), .high)
        XCTAssertEqual(GamePublicPileLevel.devCards(remaining: 17), .high)
        XCTAssertEqual(GamePublicPileLevel.devCards(remaining: 16), .medium)
        XCTAssertEqual(GamePublicPileLevel.devCards(remaining: 9), .medium)
        XCTAssertEqual(GamePublicPileLevel.devCards(remaining: 8), .low)
    }
}
