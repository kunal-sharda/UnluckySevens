import XCTest
import ULS_CoreGame
@testable import MessagesExtensionSupport

final class StatePublicationTransactionTests: XCTestCase {
    func testFailureDoesNotCommitAndAllowsRetryOfSameSnapshot() throws {
        var transaction = StatePublicationTransaction()
        let state = snapshot()
        let first = try XCTUnwrap(transaction.begin(state: state))
        XCTAssertNil(transaction.begin(state: state), "Do not submit overlapping actions")
        XCTAssertNil(transaction.finish(id: first.id, accepted: false))
        let retry = try XCTUnwrap(transaction.begin(state: state))
        XCTAssertNotEqual(first.id, retry.id)
        XCTAssertEqual(transaction.finish(id: retry.id, accepted: true), state)
        XCTAssertNil(transaction.finish(id: retry.id, accepted: true), "Duplicate callback cannot commit twice")
    }

    func testOldConversationCallbackCannotCommitOrClearNewAttempt() throws {
        var transaction = StatePublicationTransaction()
        let old = try XCTUnwrap(transaction.begin(state: snapshot()))
        transaction.invalidate()
        let current = try XCTUnwrap(transaction.begin(state: snapshot()))
        XCTAssertNil(transaction.finish(id: old.id, accepted: true))
        XCTAssertEqual(transaction.attempt?.id, current.id)
        XCTAssertEqual(transaction.finish(id: current.id, accepted: true), current.state)
    }

    func testResendingPreservesExactCanonicalSnapshot() throws {
        var transaction = StatePublicationTransaction()
        let original = snapshot()
        let resend = try XCTUnwrap(transaction.begin(state: original))
        let accepted = try XCTUnwrap(transaction.finish(id: resend.id, accepted: true))
        XCTAssertEqual(accepted, original)
        XCTAssertEqual(accepted.rev, original.rev)
        XCTAssertEqual(accepted.stateHash, original.stateHash)
    }

    private func snapshot() -> CoreGameStateV1 {
        CoreGameStateV1(gameId: "publication", rev: 0, prevHash: nil, stateHash: "",
                        roster: ["A"], currentPlayer: "A", phase: .lobby,
                        seed: nil, diceRngState: nil, resourcesByPlayer: ["A": .zero],
                        boardRules: nil, board: nil).rehashed()
    }
}
