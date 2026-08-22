import XCTest
@testable import MessagesExtensionSupport

final class GamePhysicalTurnTopBarViewTests: XCTestCase {
    func testDiceUseConventionalPipCounts() {
        for value in 1...6 {
            XCTAssertEqual(GameDiePipLayout.positions(for: value).count, value)
        }

        XCTAssertTrue(GameDiePipLayout.positions(for: 0).isEmpty)
        XCTAssertTrue(GameDiePipLayout.positions(for: 7).isEmpty)
    }
}
