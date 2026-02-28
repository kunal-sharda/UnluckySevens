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
            seed: 42,
            diceRngState: nil
        )

        let hash = state.rehashed().stateHash
        XCTAssertEqual(hash, "fc5e70118d70019ea2781766fff9cd3b2deae255125d4688d92fb2903203995a")
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
            seed: 111,
            diceRngState: 222
        )

        let changed = CoreGameStateV1(
            gameId: base.gameId,
            rev: base.rev,
            prevHash: base.prevHash,
            stateHash: "",
            roster: base.roster,
            currentPlayer: base.currentPlayer,
            phase: base.phase,
            seed: 222,
            diceRngState: base.diceRngState
        )

        XCTAssertNotEqual(base.rehashed().stateHash, changed.rehashed().stateHash)
    }

    func testHashChangesWhenDiceRngStateChanges() {
        let base = CoreGameStateV1(
            gameId: "game-123",
            rev: 7,
            prevHash: "abc123",
            stateHash: "",
            roster: ["alice", "bob", "carol"],
            currentPlayer: "alice",
            phase: .turn,
            seed: 111,
            diceRngState: 333
        )

        let changed = CoreGameStateV1(
            gameId: base.gameId,
            rev: base.rev,
            prevHash: base.prevHash,
            stateHash: "",
            roster: base.roster,
            currentPlayer: base.currentPlayer,
            phase: base.phase,
            seed: base.seed,
            diceRngState: 444
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
            seed: nil,
            diceRngState: nil
        ).rehashed()

        let to = CoreGameStateV1(
            gameId: from.gameId,
            rev: 1,
            prevHash: from.stateHash,
            stateHash: "",
            roster: ["alice", "bob", "carol"],
            currentPlayer: "alice",
            phase: .setup,
            seed: 12345,
            diceRngState: 67890
        ).rehashed()

        XCTAssertNoThrow(try validateTransition(from: from, to: to, actor: "alice"))
    }

    func testTransitionAllowsDiceRngStateChangeOutsideStart() {
        let from = makeValidState().rehashed()
        let to = CoreGameStateV1(
            gameId: from.gameId,
            rev: from.rev + 1,
            prevHash: from.stateHash,
            stateHash: "",
            roster: from.roster,
            currentPlayer: from.currentPlayer,
            phase: .turn,
            seed: from.seed,
            diceRngState: 999
        ).rehashed()

        XCTAssertNoThrow(try validateTransition(from: from, to: to, actor: from.currentPlayer))
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
            seed: from.seed,
            diceRngState: from.diceRngState
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
            seed: from.seed,
            diceRngState: from.diceRngState
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
            seed: from.seed,
            diceRngState: from.diceRngState
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
            seed: 999,
            diceRngState: from.diceRngState
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
            seed: to.seed,
            diceRngState: to.diceRngState
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
            seed: from.seed,
            diceRngState: from.diceRngState
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
            seed: 555,
            diceRngState: 777
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
            seed: from.seed,
            diceRngState: from.diceRngState
        ).rehashed()
    }
}
