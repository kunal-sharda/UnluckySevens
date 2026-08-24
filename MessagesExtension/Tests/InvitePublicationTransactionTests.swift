import Foundation
import XCTest
@testable import MessagesExtensionSupport

final class InvitePublicationTransactionTests: XCTestCase {
    func testBeginPreventsOverlappingInviteAttempts() throws {
        var transaction = InvitePublicationTransaction()
        let firstID = try XCTUnwrap(
            UUID(uuidString: "00000000-0000-0000-0000-000000000001")
        )
        let secondID = try XCTUnwrap(
            UUID(uuidString: "00000000-0000-0000-0000-000000000002")
        )

        let first = try XCTUnwrap(transaction.begin(gameId: "game-1", id: firstID))

        XCTAssertEqual(first, InvitePublicationAttempt(id: firstID, gameId: "game-1"))
        XCTAssertNil(transaction.begin(gameId: "game-2", id: secondID))
        XCTAssertTrue(transaction.isSending)
    }

    func testMatchingSuccessCommitsExactlyOnce() throws {
        var transaction = InvitePublicationTransaction()
        let attemptID = try XCTUnwrap(
            UUID(uuidString: "00000000-0000-0000-0000-000000000001")
        )
        let attempt = try XCTUnwrap(transaction.begin(gameId: "game-1", id: attemptID))

        XCTAssertEqual(
            transaction.resolve(attemptID: attemptID, outcome: .succeeded),
            .commit(attempt)
        )
        XCTAssertEqual(
            transaction.resolve(attemptID: attemptID, outcome: .succeeded),
            .ignore
        )
        XCTAssertFalse(transaction.isSending)
    }

    func testFailureRollsBackAndAllowsFreshRetry() throws {
        var transaction = InvitePublicationTransaction()
        let failedID = try XCTUnwrap(
            UUID(uuidString: "00000000-0000-0000-0000-000000000001")
        )
        let retryID = try XCTUnwrap(
            UUID(uuidString: "00000000-0000-0000-0000-000000000002")
        )
        let failedAttempt = try XCTUnwrap(transaction.begin(gameId: "game-1", id: failedID))

        XCTAssertEqual(
            transaction.resolve(attemptID: failedID, outcome: .failed),
            .rollback(failedAttempt)
        )

        let retryAttempt = try XCTUnwrap(transaction.begin(gameId: "game-2", id: retryID))
        XCTAssertEqual(retryAttempt.gameId, "game-2")
        XCTAssertTrue(transaction.isSending)
    }

    func testStaleCompletionCannotResolveNewerAttempt() throws {
        var transaction = InvitePublicationTransaction()
        let staleID = try XCTUnwrap(
            UUID(uuidString: "00000000-0000-0000-0000-000000000001")
        )
        let currentID = try XCTUnwrap(
            UUID(uuidString: "00000000-0000-0000-0000-000000000002")
        )
        _ = try XCTUnwrap(transaction.begin(gameId: "game-1", id: staleID))
        _ = transaction.resolve(attemptID: staleID, outcome: .failed)
        let currentAttempt = try XCTUnwrap(
            transaction.begin(gameId: "game-2", id: currentID)
        )

        XCTAssertEqual(
            transaction.resolve(attemptID: staleID, outcome: .succeeded),
            .ignore
        )
        XCTAssertEqual(transaction.activeAttempt, currentAttempt)
        XCTAssertTrue(transaction.isSending)
    }

    func testHostContextInvalidationRejectsOldCompletionAndAllowsNewAttempt() throws {
        var transaction = InvitePublicationTransaction()
        let oldID = try XCTUnwrap(
            UUID(uuidString: "00000000-0000-0000-0000-000000000001")
        )
        let newID = try XCTUnwrap(
            UUID(uuidString: "00000000-0000-0000-0000-000000000002")
        )
        let oldAttempt = try XCTUnwrap(transaction.begin(gameId: "old-game", id: oldID))

        XCTAssertEqual(transaction.invalidate(), oldAttempt)
        let newAttempt = try XCTUnwrap(transaction.begin(gameId: "new-game", id: newID))

        XCTAssertEqual(
            transaction.resolve(attemptID: oldID, outcome: .succeeded),
            .ignore
        )
        XCTAssertEqual(transaction.activeAttempt, newAttempt)
        XCTAssertTrue(transaction.isSending)
    }
}
