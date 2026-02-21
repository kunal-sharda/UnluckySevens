import XCTest
@testable import ULS_CoreGame

final class CoreGameKernelV1Tests: XCTestCase {
    func testGoldenHashForFixedState() {
        let state = CoreGameStateV1(
            gameId: "game-123",
            rev: 7,
            prevHash: "abc123",
            stateHash: "",
            roster: ["alice", "bob", "carol"],
            currentPlayer: "alice",
            phase: .turn
        )

        let hash = state.rehashed().stateHash
        XCTAssertEqual(hash, "040ceef25be03ba977082745cd0180fc4099c2dbddd5656d90c5dfc732246029")
    }

    func testValidTransitionPasses() throws {
        let from = makeValidState().rehashed()
        let to = makeValidNextState(from: from, actor: from.currentPlayer)

        XCTAssertNoThrow(try validateTransition(from: from, to: to, actor: from.currentPlayer))
    }

    func testTransitionFailsOnRevMismatch() throws {
        let from = makeValidState().rehashed()
        var to = makeValidNextState(from: from, actor: from.currentPlayer)
        to = CoreGameStateV1(
            gameId: to.gameId,
            rev: from.rev + 2,
            prevHash: to.prevHash,
            stateHash: to.stateHash,
            roster: to.roster,
            currentPlayer: to.currentPlayer,
            phase: to.phase
        ).rehashed()

        XCTAssertThrowsError(try validateTransition(from: from, to: to, actor: from.currentPlayer)) { error in
            XCTAssertEqual(error as? CoreGameError, .revMismatch)
        }
    }

    func testTransitionFailsOnPrevHashMismatch() throws {
        let from = makeValidState().rehashed()
        let tampered = CoreGameStateV1(
            gameId: from.gameId,
            rev: from.rev + 1,
            prevHash: "wrong-hash",
            stateHash: "",
            roster: from.roster,
            currentPlayer: from.currentPlayer,
            phase: .turn
        ).rehashed()

        XCTAssertThrowsError(try validateTransition(from: from, to: tampered, actor: from.currentPlayer)) { error in
            XCTAssertEqual(error as? CoreGameError, .prevHashMismatch)
        }
    }

    func testTransitionFailsOnActorMismatch() throws {
        let from = makeValidState().rehashed()
        let to = makeValidNextState(from: from, actor: from.currentPlayer)

        XCTAssertThrowsError(try validateTransition(from: from, to: to, actor: "not-current-player")) { error in
            XCTAssertEqual(error as? CoreGameError, .actorMismatch)
        }
    }

    func testTransitionFailsOnRosterChanged() throws {
        let from = makeValidState().rehashed()
        let tampered = CoreGameStateV1(
            gameId: from.gameId,
            rev: from.rev + 1,
            prevHash: from.stateHash,
            stateHash: "",
            roster: ["alice", "bob", "dave"],
            currentPlayer: from.currentPlayer,
            phase: .turn
        ).rehashed()

        XCTAssertThrowsError(try validateTransition(from: from, to: tampered, actor: from.currentPlayer)) { error in
            XCTAssertEqual(error as? CoreGameError, .rosterChanged)
        }
    }

    func testTransitionFailsOnInvalidStateHash() throws {
        let from = makeValidState().rehashed()
        let to = makeValidNextState(from: from, actor: from.currentPlayer)
        let tampered = CoreGameStateV1(
            gameId: to.gameId,
            rev: to.rev,
            prevHash: to.prevHash,
            stateHash: "deadbeef",
            roster: to.roster,
            currentPlayer: to.currentPlayer,
            phase: to.phase
        )

        XCTAssertThrowsError(try validateTransition(from: from, to: tampered, actor: from.currentPlayer)) { error in
            XCTAssertEqual(error as? CoreGameError, .invalidStateHash)
        }
    }

    func testTransitionFailsOnGameIdMismatch() throws {
        let from = makeValidState().rehashed()
        let tampered = CoreGameStateV1(
            gameId: "different-game",
            rev: from.rev + 1,
            prevHash: from.stateHash,
            stateHash: "",
            roster: from.roster,
            currentPlayer: from.currentPlayer,
            phase: .turn
        ).rehashed()

        XCTAssertThrowsError(try validateTransition(from: from, to: tampered, actor: from.currentPlayer)) { error in
            XCTAssertEqual(error as? CoreGameError, .gameIdMismatch)
        }
    }

    private func makeValidState() -> CoreGameStateV1 {
        CoreGameStateV1(
            gameId: "game-123",
            rev: 3,
            prevHash: "prev-hash-2",
            stateHash: "",
            roster: ["alice", "bob", "carol"],
            currentPlayer: "alice",
            phase: .turn
        )
    }

    private func makeValidNextState(from: CoreGameStateV1, actor: String) -> CoreGameStateV1 {
        CoreGameStateV1(
            gameId: from.gameId,
            rev: from.rev + 1,
            prevHash: from.stateHash,
            stateHash: "",
            roster: from.roster,
            currentPlayer: actor,
            phase: .turn
        ).rehashed()
    }
}
