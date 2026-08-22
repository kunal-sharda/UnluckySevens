@testable import MessagesExtensionSupport
import XCTest

final class GameDiceRollCompletionGateTests: XCTestCase {
    func testCompletionRunsExactlyOnce() {
        var gate = GameDiceRollCompletionGate()
        var completionCount = 0

        gate.complete { completionCount += 1 }
        gate.complete { completionCount += 1 }

        XCTAssertEqual(completionCount, 1)
        XCTAssertTrue(gate.hasCompleted)
    }
}
