import XCTest
@testable import MessagesExtension

final class GamePublicPileLevelTests: XCTestCase {
    func testResourceLevelsUseThirdsOfTheStandardPile() {
        XCTAssertEqual(GamePublicPileLevel.resource(remaining: 19), .high)
        XCTAssertEqual(GamePublicPileLevel.resource(remaining: 13), .high)
        XCTAssertEqual(GamePublicPileLevel.resource(remaining: 12), .medium)
        XCTAssertEqual(GamePublicPileLevel.resource(remaining: 7), .medium)
        XCTAssertEqual(GamePublicPileLevel.resource(remaining: 6), .low)
        XCTAssertEqual(GamePublicPileLevel.resource(remaining: 0), .low)
    }

    func testDevCardLevelsUseThirdsOfTheStandardPile() {
        XCTAssertEqual(GamePublicPileLevel.devCards(remaining: 25), .high)
        XCTAssertEqual(GamePublicPileLevel.devCards(remaining: 17), .high)
        XCTAssertEqual(GamePublicPileLevel.devCards(remaining: 16), .medium)
        XCTAssertEqual(GamePublicPileLevel.devCards(remaining: 9), .medium)
        XCTAssertEqual(GamePublicPileLevel.devCards(remaining: 8), .low)
    }
}
