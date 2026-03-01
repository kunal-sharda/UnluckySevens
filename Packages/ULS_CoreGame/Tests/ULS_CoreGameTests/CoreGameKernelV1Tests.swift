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
            diceRngState: nil,
            boardRules: nil,
            board: nil
        )

        let hash = state.rehashed().stateHash
        XCTAssertEqual(hash, "7fa96a969ca8e240730e51ab7296478afa0e215ca04acfe7d1ef73ed29bbb53a")
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
            diceRngState: 222,
            boardRules: nil,
            board: nil
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
            diceRngState: base.diceRngState,
            boardRules: base.boardRules,
            board: base.board
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
            diceRngState: 333,
            boardRules: nil,
            board: nil
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
            diceRngState: 444,
            boardRules: base.boardRules,
            board: base.board
        )

        XCTAssertNotEqual(base.rehashed().stateHash, changed.rehashed().stateHash)
    }

    func testValidTransitionPasses() {
        let from = makeValidState().rehashed()
        let to = makeValidNextState(from: from, actor: from.currentPlayer)

        XCTAssertNoThrow(try validateTransition(from: from, to: to, actor: from.currentPlayer))
    }

    func testValidStartTransitionAllowsRosterSeedBoardRulesAndBoardChange() {
        let from = CoreGameStateV1(
            gameId: "game-123",
            rev: 0,
            prevHash: nil,
            stateHash: "",
            roster: ["alice"],
            currentPlayer: "alice",
            phase: .lobby,
            seed: nil,
            diceRngState: nil,
            boardRules: nil,
            board: nil
        ).rehashed()

        let boardRules = BoardRulesV1(strategy: .randomV1)
        let board = StandardBoardGeneratorV1.generate(
            boardSeed: SeedDeriver(masterSeed: 12345).seed(for: .board),
            rules: boardRules
        )
        let to = CoreGameStateV1(
            gameId: from.gameId,
            rev: 1,
            prevHash: from.stateHash,
            stateHash: "",
            roster: ["alice", "bob", "carol"],
            currentPlayer: "alice",
            phase: .setup,
            seed: 12345,
            diceRngState: 67890,
            boardRules: boardRules,
            board: board
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
            diceRngState: 999,
            boardRules: from.boardRules,
            board: from.board
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
            diceRngState: from.diceRngState,
            boardRules: from.boardRules,
            board: from.board
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
            diceRngState: from.diceRngState,
            boardRules: from.boardRules,
            board: from.board
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
            diceRngState: from.diceRngState,
            boardRules: from.boardRules,
            board: from.board
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
            diceRngState: from.diceRngState,
            boardRules: from.boardRules,
            board: from.board
        ).rehashed()

        XCTAssertThrowsError(try validateTransition(from: from, to: tampered, actor: from.currentPlayer)) { error in
            XCTAssertEqual(error as? CoreGameError, .seedChanged)
        }
    }

    func testTransitionFailsOnBoardRulesChangedOutsideStartTransition() {
        let from = makeValidState().rehashed()
        let tampered = CoreGameStateV1(
            gameId: from.gameId,
            rev: from.rev + 1,
            prevHash: from.stateHash,
            stateHash: "",
            roster: from.roster,
            currentPlayer: from.currentPlayer,
            phase: .turn,
            seed: from.seed,
            diceRngState: from.diceRngState,
            boardRules: BoardRulesV1(strategy: .noRedAdjacentV1),
            board: from.board
        ).rehashed()

        XCTAssertThrowsError(try validateTransition(from: from, to: tampered, actor: from.currentPlayer)) { error in
            XCTAssertEqual(error as? CoreGameError, .boardRulesChanged)
        }
    }

    func testTransitionFailsOnBoardChangedOutsideStartTransition() {
        let from = makeValidState().rehashed()
        let alternateBoard = StandardBoardGeneratorV1.generate(
            boardSeed: SeedDeriver(masterSeed: 556).seed(for: .board),
            rules: from.boardRules ?? BoardRulesV1()
        )
        let tampered = CoreGameStateV1(
            gameId: from.gameId,
            rev: from.rev + 1,
            prevHash: from.stateHash,
            stateHash: "",
            roster: from.roster,
            currentPlayer: from.currentPlayer,
            phase: .turn,
            seed: from.seed,
            diceRngState: from.diceRngState,
            boardRules: from.boardRules,
            board: alternateBoard
        ).rehashed()

        XCTAssertThrowsError(try validateTransition(from: from, to: tampered, actor: from.currentPlayer)) { error in
            XCTAssertEqual(error as? CoreGameError, .boardChanged)
        }
    }

    func testTransitionFailsOnInvalidBoardHash() {
        let from = CoreGameStateV1(
            gameId: "game-123",
            rev: 0,
            prevHash: nil,
            stateHash: "",
            roster: ["alice"],
            currentPlayer: "alice",
            phase: .lobby,
            seed: nil,
            diceRngState: nil,
            boardRules: nil,
            board: nil
        ).rehashed()

        let boardRules = BoardRulesV1(strategy: .randomV1)
        let validBoard = StandardBoardGeneratorV1.generate(
            boardSeed: SeedDeriver(masterSeed: 12345).seed(for: .board),
            rules: boardRules
        )
        let invalidBoard = BoardSetupV1(
            resourcesByTile: validBoard.resourcesByTile,
            numbersByTile: validBoard.numbersByTile,
            portsByIndex: validBoard.portsByIndex,
            robberTile: validBoard.robberTile,
            generator: validBoard.generator,
            boardHash: "deadbeef"
        )
        let to = CoreGameStateV1(
            gameId: from.gameId,
            rev: 1,
            prevHash: from.stateHash,
            stateHash: "",
            roster: ["alice", "bob"],
            currentPlayer: "alice",
            phase: .setup,
            seed: 12345,
            diceRngState: 67890,
            boardRules: boardRules,
            board: invalidBoard
        ).rehashed()

        XCTAssertThrowsError(try validateTransition(from: from, to: to, actor: "alice")) { error in
            XCTAssertEqual(error as? CoreGameError, .invalidBoardHash)
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
            diceRngState: to.diceRngState,
            boardRules: to.boardRules,
            board: to.board
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
            diceRngState: from.diceRngState,
            boardRules: from.boardRules,
            board: from.board
        ).rehashed()

        XCTAssertThrowsError(try validateTransition(from: from, to: tampered, actor: from.currentPlayer)) { error in
            XCTAssertEqual(error as? CoreGameError, .gameIdMismatch)
        }
    }

    private func makeValidState() -> CoreGameStateV1 {
        let rules = BoardRulesV1(strategy: .randomV1)
        let board = StandardBoardGeneratorV1.generate(
            boardSeed: SeedDeriver(masterSeed: 555).seed(for: .board),
            rules: rules
        )

        return CoreGameStateV1(
            gameId: "game-123",
            rev: 3,
            prevHash: "prev-hash-2",
            stateHash: "",
            roster: ["alice", "bob", "carol"],
            currentPlayer: "alice",
            phase: .turn,
            seed: 555,
            diceRngState: 777,
            boardRules: rules,
            board: board
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
            diceRngState: from.diceRngState,
            boardRules: from.boardRules,
            board: from.board
        ).rehashed()
    }
}
