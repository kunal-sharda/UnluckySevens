import XCTest
@testable import MessagesExtensionSupport

final class LobbyReconciliationPublicationTransactionTests: XCTestCase {
    func testFailureLeavesSameFrontierRetryableWithoutCommitting() throws {
        let firstID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let retryID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        var transaction = LobbyReconciliationPublicationTransaction()
        let first = try XCTUnwrap(
            transaction.begin(
                gameId: "game",
                anchorHash: "anchor",
                targetHash: "target",
                frontierDigest: "frontier",
                id: firstID
            )
        )

        XCTAssertNil(
            transaction.begin(
                gameId: "game",
                anchorHash: "anchor",
                targetHash: "target",
                frontierDigest: "frontier"
            )
        )
        XCTAssertEqual(
            transaction.resolveSend(attemptID: first.id, outcome: .failed),
            .retry(first)
        )
        XCTAssertFalse(transaction.isSending)
        XCTAssertFalse(
            LobbyReconciliationStartGate.allowsStart(
                isBaseEligible: true,
                isPublicationInFlight: transaction.isSending,
                hasUnresolvedFrontier: true
            )
        )
        XCTAssertNotNil(
            transaction.begin(
                gameId: "game",
                anchorHash: "anchor",
                targetHash: "target",
                frontierDigest: "frontier",
                id: retryID
            )
        )
    }

    func testOnlyMatchingSuccessfulAttemptCommits() throws {
        let attemptID = UUID(uuidString: "00000000-0000-0000-0000-000000000003")!
        let staleID = UUID(uuidString: "00000000-0000-0000-0000-000000000004")!
        var transaction = LobbyReconciliationPublicationTransaction()
        let attempt = try XCTUnwrap(
            transaction.begin(
                gameId: "game",
                anchorHash: "anchor",
                targetHash: "target",
                frontierDigest: "frontier",
                id: attemptID
            )
        )

        XCTAssertEqual(
            transaction.resolveSend(attemptID: staleID, outcome: .succeeded),
            .ignore
        )
        XCTAssertTrue(transaction.isSending)
        XCTAssertEqual(
            transaction.resolveSend(attemptID: attemptID, outcome: .succeeded),
            .verifyPersistence(attempt)
        )
        XCTAssertTrue(transaction.isSending)
        XCTAssertEqual(
            transaction.resolvePersistence(attemptID: attemptID, didPersist: true),
            .commit(attempt)
        )
        XCTAssertFalse(transaction.isSending)
        XCTAssertTrue(
            LobbyReconciliationStartGate.allowsStart(
                isBaseEligible: true,
                isPublicationInFlight: transaction.isSending,
                hasUnresolvedFrontier: false
            )
        )
    }

    func testPersistenceFailureDoesNotCommitAndLeavesFrontierRetryable() throws {
        let attemptID = UUID(uuidString: "00000000-0000-0000-0000-000000000005")!
        var transaction = LobbyReconciliationPublicationTransaction()
        let attempt = try XCTUnwrap(
            transaction.begin(
                gameId: "game",
                anchorHash: "anchor",
                targetHash: "target",
                frontierDigest: "frontier",
                id: attemptID
            )
        )

        XCTAssertEqual(
            transaction.resolveSend(attemptID: attemptID, outcome: .succeeded),
            .verifyPersistence(attempt)
        )
        XCTAssertEqual(
            transaction.resolvePersistence(attemptID: attemptID, didPersist: false),
            .retry(attempt)
        )
        XCTAssertFalse(transaction.isSending)
        XCTAssertNotNil(
            transaction.begin(
                gameId: "game",
                anchorHash: "anchor",
                targetHash: "target",
                frontierDigest: "frontier"
            )
        )
    }
}
