import XCTest
@testable import MessagesExtensionSupport

final class TranscriptRecoverySessionBindingTests: XCTestCase {
    func testCachedSessionWinsWhenSelectedBubbleDoesNotMatch() {
        XCTAssertEqual(
            TranscriptRecoverySessionBinding.resolve(
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
            TranscriptRecoverySessionBinding.resolve(
                gameId: "game-1",
                selectedMessageGameId: "game-1",
                hasSelectedMessageSession: true,
                hasCachedSession: true
            ),
            .selectedMessage
        )
    }

    func testMatchingSelectedBubbleCanBindRecoveredGame() {
        XCTAssertEqual(
            TranscriptRecoverySessionBinding.resolve(
                gameId: "game-1",
                selectedMessageGameId: "game-1",
                hasSelectedMessageSession: true,
                hasCachedSession: false
            ),
            .selectedMessage
        )
    }

    func testMismatchedOrMissingBubbleLeavesRecoveryUnbound() {
        XCTAssertEqual(
            TranscriptRecoverySessionBinding.resolve(
                gameId: "game-1",
                selectedMessageGameId: "game-2",
                hasSelectedMessageSession: true,
                hasCachedSession: false
            ),
            .unbound
        )
        XCTAssertEqual(
            TranscriptRecoverySessionBinding.resolve(
                gameId: "game-1",
                selectedMessageGameId: nil,
                hasSelectedMessageSession: false,
                hasCachedSession: false
            ),
            .unbound
        )
    }

    func testOnlyExplicitReconnectMayStartSessionForMarkedRecovery() {
        XCTAssertFalse(
            TranscriptRecoverySessionBinding.permitsNewSession(
                isMarkedRecoveryUnbound: true,
                isExplicitReconnect: false
            )
        )
        XCTAssertTrue(
            TranscriptRecoverySessionBinding.permitsNewSession(
                isMarkedRecoveryUnbound: true,
                isExplicitReconnect: true
            )
        )
        XCTAssertTrue(
            TranscriptRecoverySessionBinding.permitsNewSession(
                isMarkedRecoveryUnbound: false,
                isExplicitReconnect: false
            )
        )
    }
}
