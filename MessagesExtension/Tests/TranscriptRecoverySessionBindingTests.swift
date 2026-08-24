import XCTest
@testable import MessagesExtensionSupport

final class TranscriptGameSessionBindingTests: XCTestCase {
    func testCachedSessionWinsWhenSelectedBubbleDoesNotMatch() {
        XCTAssertEqual(
            TranscriptGameSessionBinding.resolve(
                gameId: "game-1",
                selectedMessageGameId: "game-2",
                hasSelectedMessageSession: true,
                hasCachedSession: true
            ),
            .cached
        )
    }

    func testMatchingSelectedBubbleWinsOverCachedSession() {
        XCTAssertEqual(
            TranscriptGameSessionBinding.resolve(
                gameId: "game-1",
                selectedMessageGameId: "game-1",
                hasSelectedMessageSession: true,
                hasCachedSession: true
            ),
            .selectedMessage
        )
    }

    func testMatchingSelectedBubbleCanBindCurrentGame() {
        XCTAssertEqual(
            TranscriptGameSessionBinding.resolve(
                gameId: "game-1",
                selectedMessageGameId: "game-1",
                hasSelectedMessageSession: true,
                hasCachedSession: false
            ),
            .selectedMessage
        )
    }

    func testMismatchedOrMissingBubbleLeavesGameUnbound() {
        XCTAssertEqual(
            TranscriptGameSessionBinding.resolve(
                gameId: "game-1",
                selectedMessageGameId: "game-2",
                hasSelectedMessageSession: true,
                hasCachedSession: false
            ),
            .unbound
        )
        XCTAssertEqual(
            TranscriptGameSessionBinding.resolve(
                gameId: "game-1",
                selectedMessageGameId: nil,
                hasSelectedMessageSession: false,
                hasCachedSession: false
            ),
            .unbound
        )
    }

}
