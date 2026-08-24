import XCTest
@testable import MessagesExtensionSupport

final class TranscriptGameSessionBindingTests: XCTestCase {
    func testNewStateStartsFreshSessionWithoutExistingBinding() {
        XCTAssertEqual(
            TranscriptGameSessionBinding.resolve(
                policy: .newState(gameId: "new-game"),
                selectedMessageGameId: nil,
                hasSelectedMessageSession: false,
                hasCachedSession: false
            ),
            .new
        )
    }

    func testGenericNewMessageStartsFreshSessionWithoutExistingBinding() {
        XCTAssertEqual(
            TranscriptGameSessionBinding.resolve(
                policy: .new,
                selectedMessageGameId: "other-game",
                hasSelectedMessageSession: true,
                hasCachedSession: true
            ),
            .new
        )
    }

    func testCachedSessionWinsWhenSelectedBubbleDoesNotMatch() {
        XCTAssertEqual(
            TranscriptGameSessionBinding.resolve(
                policy: .state(gameId: "game-1"),
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
                policy: .state(gameId: "game-1"),
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
                policy: .state(gameId: "game-1"),
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
                policy: .state(gameId: "game-1"),
                selectedMessageGameId: "game-2",
                hasSelectedMessageSession: true,
                hasCachedSession: false
            ),
            .unbound
        )
        XCTAssertEqual(
            TranscriptGameSessionBinding.resolve(
                policy: .state(gameId: "game-1"),
                selectedMessageGameId: nil,
                hasSelectedMessageSession: false,
                hasCachedSession: false
            ),
            .unbound
        )
    }

}
