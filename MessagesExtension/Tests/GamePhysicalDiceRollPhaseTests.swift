import XCTest
@testable import MessagesExtensionSupport

final class GamePhysicalDiceRollPhaseTests: XCTestCase {
    func testRollingPhaseOffersSkipWithoutSettleLanguage() {
        XCTAssertEqual(GamePhysicalDiceRollPhase.rolling.instruction, "Tap to skip")
        XCTAssertFalse(GamePhysicalDiceRollPhase.rolling.instruction.localizedCaseInsensitiveContains("settle"))
        XCTAssertEqual(
            GamePhysicalDiceRollPhase.rolling.accessibilityHint,
            "Skips the remaining dice animation"
        )
    }

    func testSettledPhaseWaitsForExplicitContinuation() {
        XCTAssertEqual(GamePhysicalDiceRollPhase.settled.instruction, "Tap to continue")
        XCTAssertEqual(
            GamePhysicalDiceRollPhase.settled.accessibilityHint,
            "Continues to your turn"
        )
    }
}
