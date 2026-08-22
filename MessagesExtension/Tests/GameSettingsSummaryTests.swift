@testable import MessagesExtensionSupport
import ULS_CoreGame
import XCTest

final class GameSettingsSummaryTests: XCTestCase {
    func testDefaultSummaryUsesFirstBetaContract() {
        let summary = GameSettingsSummary()

        XCTAssertEqual(summary.rules, "Standard")
        XCTAssertEqual(summary.board, "Balanced")
        XCTAssertEqual(summary.victory, "10 points")
    }

    func testLegacyRandomBoardIsDescribedHonestly() {
        XCTAssertEqual(
            GameSettingsSummary(boardStrategy: .randomV1).board,
            "Classic random"
        )
    }
}
