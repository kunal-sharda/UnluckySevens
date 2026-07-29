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
            board: nil,
            turnState: TurnStateV1(step: .needsRoll, lastRoll: nil)
        )

        let hash = state.rehashed().stateHash
        XCTAssertEqual(hash, "482df5fd46988107ca63c4d0000c6b663df20ba50289530a3d0bb402fd934c1c")
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
            board: nil,
            turnState: TurnStateV1(step: .needsRoll, lastRoll: nil)
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
            board: base.board,
            turnState: base.turnState
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
            board: nil,
            turnState: TurnStateV1(step: .needsRoll, lastRoll: nil)
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
            board: base.board,
            turnState: base.turnState
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
        let setupState = initializeSetupState(roster: ["alice", "bob", "carol"])
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
            board: board,
            setupState: setupState
        ).rehashed()

        XCTAssertNoThrow(try validateTransition(from: from, to: to, actor: "alice"))
    }

    func testTransitionAllowsDiceRngStateChangeOutsideStart() {
        let from = makeValidState().rehashed()
        let to = makeValidNextState(from: from, actor: from.currentPlayer)

        XCTAssertNotEqual(to.diceRngState, from.diceRngState)
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
            board: from.board,
            turnState: from.turnState
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
            board: from.board,
            turnState: from.turnState
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
            board: from.board,
            turnState: from.turnState
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
            board: from.board,
            turnState: from.turnState
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
            board: from.board,
            turnState: from.turnState
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
            board: alternateBoard,
            turnState: from.turnState
        ).rehashed()

        XCTAssertThrowsError(try validateTransition(from: from, to: tampered, actor: from.currentPlayer)) { error in
            XCTAssertEqual(error as? CoreGameError, .boardChanged)
        }
    }

    func testTransitionFailsOnResourcesByPlayerChangedOutsideAllowedSetupPayout() {
        let from = makeValidState().rehashed()
        let validNext = makeValidNextState(from: from, actor: from.currentPlayer)
        let tamperedResources = validNext.resourcesByPlayer.merging([
            "alice": ResourceHandV1(wood: 1),
        ]) { _, new in new }
        let tampered = CoreGameStateV1(
            gameId: validNext.gameId,
            rev: validNext.rev,
            prevHash: validNext.prevHash,
            stateHash: "",
            roster: validNext.roster,
            currentPlayer: validNext.currentPlayer,
            phase: .turn,
            seed: validNext.seed,
            diceRngState: validNext.diceRngState,
            robberRngState: validNext.robberRngState,
            resourcesByPlayer: tamperedResources,
            bankResources: validNext.bankResources,
            devDeck: validNext.devDeck,
            devCardsByPlayer: validNext.devCardsByPlayer,
            newDevCardsByPlayer: validNext.newDevCardsByPlayer,
            revealedVictoryPointsByPlayer: validNext.revealedVictoryPointsByPlayer,
            devCardActionPlayedThisTurn: validNext.devCardActionPlayedThisTurn,
            knightsPlayedByPlayer: validNext.knightsPlayedByPlayer,
            largestArmyOwner: validNext.largestArmyOwner,
            largestArmySize: validNext.largestArmySize,
            longestRoadOwner: validNext.longestRoadOwner,
            longestRoadLength: validNext.longestRoadLength,
            winnerPlayer: validNext.winnerPlayer,
            winningVictoryPoints: validNext.winningVictoryPoints,
            auditLog: validNext.auditLog,
            lastTurnRecap: validNext.lastTurnRecap,
            activeTradeOffer: validNext.activeTradeOffer,
            tradeResponses: validNext.tradeResponses,
            settlementsByNode: validNext.settlementsByNode,
            citiesByNode: validNext.citiesByNode,
            roadsByEdge: validNext.roadsByEdge,
            boardRules: validNext.boardRules,
            board: validNext.board,
            turnState: validNext.turnState
        ).rehashed()

        XCTAssertThrowsError(try validateTransition(from: from, to: tampered, actor: from.currentPlayer)) { error in
            XCTAssertEqual(error as? CoreGameError, .resourcesByPlayerInvalid)
        }
    }

    func testStartTransitionFailsWhenResourcesByPlayerIsNotZeroedForRoster() {
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
        let setupState = initializeSetupState(roster: ["alice", "bob"])
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
            resourcesByPlayer: [
                "alice": ResourceHandV1(wood: 1),
                "bob": .zero,
            ],
            boardRules: boardRules,
            board: board,
            setupState: setupState
        ).rehashed()

        XCTAssertThrowsError(try validateTransition(from: from, to: to, actor: "alice")) { error in
            XCTAssertEqual(error as? CoreGameError, .resourcesByPlayerInvalid)
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
        let setupState = initializeSetupState(roster: ["alice", "bob"])
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
            board: invalidBoard,
            setupState: setupState
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
            robberRngState: to.robberRngState,
            resourcesByPlayer: to.resourcesByPlayer,
            bankResources: to.bankResources,
            devDeck: to.devDeck,
            devCardsByPlayer: to.devCardsByPlayer,
            newDevCardsByPlayer: to.newDevCardsByPlayer,
            revealedVictoryPointsByPlayer: to.revealedVictoryPointsByPlayer,
            devCardActionPlayedThisTurn: to.devCardActionPlayedThisTurn,
            knightsPlayedByPlayer: to.knightsPlayedByPlayer,
            largestArmyOwner: to.largestArmyOwner,
            largestArmySize: to.largestArmySize,
            longestRoadOwner: to.longestRoadOwner,
            longestRoadLength: to.longestRoadLength,
            winnerPlayer: to.winnerPlayer,
            winningVictoryPoints: to.winningVictoryPoints,
            auditLog: to.auditLog,
            lastTurnRecap: to.lastTurnRecap,
            activeTradeOffer: to.activeTradeOffer,
            tradeResponses: to.tradeResponses,
            settlementsByNode: to.settlementsByNode,
            citiesByNode: to.citiesByNode,
            roadsByEdge: to.roadsByEdge,
            boardRules: to.boardRules,
            board: to.board,
            turnState: to.turnState
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
            board: from.board,
            turnState: from.turnState
        ).rehashed()

        XCTAssertThrowsError(try validateTransition(from: from, to: tampered, actor: from.currentPlayer)) { error in
            XCTAssertEqual(error as? CoreGameError, .gameIdMismatch)
        }
    }

    func testTransitionFailsOnSetupCurrentPlayerMismatch() {
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
        let setupState = initializeSetupState(roster: ["alice", "bob"])
        let to = CoreGameStateV1(
            gameId: from.gameId,
            rev: 1,
            prevHash: from.stateHash,
            stateHash: "",
            roster: ["alice", "bob"],
            currentPlayer: "bob",
            phase: .setup,
            seed: 12345,
            diceRngState: 67890,
            boardRules: boardRules,
            board: board,
            setupState: setupState
        ).rehashed()

        XCTAssertThrowsError(try validateTransition(from: from, to: to, actor: "alice")) { error in
            XCTAssertEqual(error as? CoreGameError, .setupCurrentPlayerMismatch)
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
            board: board,
            turnState: TurnStateV1(step: .needsRoll, lastRoll: nil)
        )
    }

    private func makeValidNextState(from: CoreGameStateV1, actor: String) -> CoreGameStateV1 {
        guard let next = try? apply(intent: .rollDice, to: from, actor: actor) else {
            preconditionFailure("Expected deterministic roll transition to succeed in test fixture.")
        }
        return next
    }
}
