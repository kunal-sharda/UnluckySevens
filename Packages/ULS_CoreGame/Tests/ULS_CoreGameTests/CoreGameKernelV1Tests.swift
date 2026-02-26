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
            phase: .turn,
            seed: 42
        )

        let hash = state.rehashed().stateHash
        XCTAssertEqual(hash, "15474f08888778bfd6377c0ef089f4a973b65b12568bc8be8d89c7274357196e")
    }

    func testHashChangesWhenSeedChanges() {
        let base = CoreGameStateV1(
            gameId: "game-123",
            rev: 7,
            prevHash: "abc123",
            stateHash: "",
            roster: ["alice", "bob", "carol"],
            currentPlayer: "alice",
            phase: .turn,
            seed: 111
        )

        let changed = CoreGameStateV1(
            gameId: base.gameId,
            rev: base.rev,
            prevHash: base.prevHash,
            stateHash: "",
            roster: base.roster,
            currentPlayer: base.currentPlayer,
            phase: base.phase,
            seed: 222
        )

        XCTAssertNotEqual(base.rehashed().stateHash, changed.rehashed().stateHash)
    }

    func testValidTransitionPasses() {
        let from = makeValidState().rehashed()
        let to = makeValidNextState(from: from, actor: from.currentPlayer)

        XCTAssertNoThrow(try validateTransition(from: from, to: to, actor: from.currentPlayer))
    }

    func testValidStartTransitionAllowsRosterAndSeedChange() {
        let from = CoreGameStateV1(
            gameId: "game-123",
            rev: 0,
            prevHash: nil,
            stateHash: "",
            roster: ["alice"],
            currentPlayer: "alice",
            phase: .lobby,
            seed: nil
        ).rehashed()

        let to = CoreGameStateV1(
            gameId: from.gameId,
            rev: 1,
            prevHash: from.stateHash,
            stateHash: "",
            roster: ["alice", "bob", "carol"],
            currentPlayer: "alice",
            phase: .setup,
            seed: 12345
        ).rehashed()

        XCTAssertNoThrow(try validateTransition(from: from, to: to, actor: "alice"))
    }

    func testTransitionFailsOnRevMismatch() {
        let from = makeValidState().rehashed()
        let to = CoreGameStateV1(
            gameId: from.gameId,
            rev: from.rev + 2,
            prevHash: from.stateHash,
            stateHash: "",
            roster: from.roster,
            currentPlayer: from.currentPlayer,
            phase: .turn,
            seed: from.seed
        ).rehashed()

        XCTAssertThrowsError(try validateTransition(from: from, to: to, actor: from.currentPlayer)) { error in
            XCTAssertEqual(error as? CoreGameError, .revMismatch)
        }
    }

    func testTransitionFailsOnPrevHashMismatch() {
        let from = makeValidState().rehashed()
        let tampered = CoreGameStateV1(
            gameId: from.gameId,
            rev: from.rev + 1,
            prevHash: "wrong-hash",
            stateHash: "",
            roster: from.roster,
            currentPlayer: from.currentPlayer,
            phase: .turn,
            seed: from.seed
        ).rehashed()

        XCTAssertThrowsError(try validateTransition(from: from, to: tampered, actor: from.currentPlayer)) { error in
            XCTAssertEqual(error as? CoreGameError, .prevHashMismatch)
        }
    }

    func testTransitionFailsOnActorMismatch() {
        let from = makeValidState().rehashed()
        let to = makeValidNextState(from: from, actor: from.currentPlayer)

        XCTAssertThrowsError(try validateTransition(from: from, to: to, actor: "not-current-player")) { error in
            XCTAssertEqual(error as? CoreGameError, .actorMismatch)
        }
    }

    func testTransitionFailsOnRosterChangedOutsideStartTransition() {
        let from = makeValidState().rehashed()
        let tampered = CoreGameStateV1(
            gameId: from.gameId,
            rev: from.rev + 1,
            prevHash: from.stateHash,
            stateHash: "",
            roster: ["alice", "bob", "dave"],
            currentPlayer: from.currentPlayer,
            phase: .turn,
            seed: from.seed
        ).rehashed()

        XCTAssertThrowsError(try validateTransition(from: from, to: tampered, actor: from.currentPlayer)) { error in
            XCTAssertEqual(error as? CoreGameError, .rosterChanged)
        }
    }

    func testTransitionFailsOnSeedChangedOutsideStartTransition() {
        let from = makeValidState().rehashed()
        let tampered = CoreGameStateV1(
            gameId: from.gameId,
            rev: from.rev + 1,
            prevHash: from.stateHash,
            stateHash: "",
            roster: from.roster,
            currentPlayer: from.currentPlayer,
            phase: .turn,
            seed: 999
        ).rehashed()

        XCTAssertThrowsError(try validateTransition(from: from, to: tampered, actor: from.currentPlayer)) { error in
            XCTAssertEqual(error as? CoreGameError, .seedChanged)
        }
    }

    func testTransitionFailsOnInvalidStateHash() {
        let from = makeValidState().rehashed()
        let to = makeValidNextState(from: from, actor: from.currentPlayer)
        let tampered = CoreGameStateV1(
            gameId: to.gameId,
            rev: to.rev,
            prevHash: to.prevHash,
            stateHash: "deadbeef",
            roster: to.roster,
            currentPlayer: to.currentPlayer,
            phase: to.phase,
            seed: to.seed
        )

        XCTAssertThrowsError(try validateTransition(from: from, to: tampered, actor: from.currentPlayer)) { error in
            XCTAssertEqual(error as? CoreGameError, .invalidStateHash)
        }
    }

    func testTransitionFailsOnGameIdMismatch() {
        let from = makeValidState().rehashed()
        let tampered = CoreGameStateV1(
            gameId: "different-game",
            rev: from.rev + 1,
            prevHash: from.stateHash,
            stateHash: "",
            roster: from.roster,
            currentPlayer: from.currentPlayer,
            phase: .turn,
            seed: from.seed
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
            phase: .turn,
            seed: 555
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
            phase: .turn,
            seed: from.seed
        ).rehashed()
    }
}
