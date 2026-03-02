import XCTest
@testable import ULS_CoreGame

final class TurnStateMachineV1Tests: XCTestCase {
    func testRollDiceTransitionsNeedsRollToAfterRollDeterministically() throws {
        let initialDiceRngState: UInt64 = 0x0123456789ABCDEF
        let state = makeTurnState(
            roster: ["A", "B"],
            currentPlayer: "A",
            diceRngState: initialDiceRngState,
            turnStep: .needsRoll,
            lastRoll: nil
        )

        var expectedRng = DeterministicRNG(seed: initialDiceRngState)
        let expectedRoll = expectedRng.rollDice()
        let expectedDiceRngState = expectedRng.state

        let updated = try apply(intent: TurnIntentV1.rollDice, to: state, actor: "A")

        XCTAssertEqual(updated.phase, .turn)
        XCTAssertEqual(updated.currentPlayer, "A")
        XCTAssertEqual(updated.turnState?.step, .afterRoll)
        XCTAssertEqual(updated.turnState?.lastRoll, DiceRollV1(d1: expectedRoll.0, d2: expectedRoll.1))
        XCTAssertEqual(updated.diceRngState, expectedDiceRngState)
    }

    func testRollDiceTwiceThrows() throws {
        let initial = makeTurnState(
            roster: ["A", "B"],
            currentPlayer: "A",
            diceRngState: 777,
            turnStep: .needsRoll,
            lastRoll: nil
        )
        let rolled = try apply(intent: TurnIntentV1.rollDice, to: initial, actor: "A")

        XCTAssertThrowsError(try apply(intent: TurnIntentV1.rollDice, to: rolled, actor: "A")) { error in
            XCTAssertEqual(error as? CoreGameError, .turnStepMismatch)
        }
    }

    func testEndTurnBeforeRollThrows() {
        let state = makeTurnState(
            roster: ["A", "B"],
            currentPlayer: "A",
            diceRngState: 555,
            turnStep: .needsRoll,
            lastRoll: nil
        )

        XCTAssertThrowsError(try apply(intent: TurnIntentV1.endTurn, to: state, actor: "A")) { error in
            XCTAssertEqual(error as? CoreGameError, .turnStepMismatch)
        }
    }

    func testEndTurnAfterRollAdvancesCurrentPlayerAndResetsTurnState() throws {
        let initial = makeTurnState(
            roster: ["A", "B", "C"],
            currentPlayer: "A",
            diceRngState: 333,
            turnStep: .needsRoll,
            lastRoll: nil
        )
        let rolled = try apply(intent: TurnIntentV1.rollDice, to: initial, actor: "A")
        let ended = try apply(intent: TurnIntentV1.endTurn, to: rolled, actor: "A")

        XCTAssertEqual(ended.phase, .turn)
        XCTAssertEqual(ended.currentPlayer, "B")
        XCTAssertEqual(ended.turnState?.step, .needsRoll)
        XCTAssertNil(ended.turnState?.lastRoll)
        XCTAssertEqual(ended.diceRngState, rolled.diceRngState)
    }

    func testActorMismatchThrows() {
        let state = makeTurnState(
            roster: ["A", "B"],
            currentPlayer: "A",
            diceRngState: 999,
            turnStep: .needsRoll,
            lastRoll: nil
        )

        XCTAssertThrowsError(try apply(intent: TurnIntentV1.rollDice, to: state, actor: "B")) { error in
            XCTAssertEqual(error as? CoreGameError, .actorMismatch)
        }
    }

    private func makeTurnState(
        roster: [String],
        currentPlayer: String,
        diceRngState: UInt64?,
        turnStep: TurnStepV1,
        lastRoll: DiceRollV1?
    ) -> CoreGameStateV1 {
        CoreGameStateV1(
            gameId: "game-turn",
            rev: 10,
            prevHash: "hash-9",
            stateHash: "",
            roster: roster,
            currentPlayer: currentPlayer,
            phase: .turn,
            seed: 42,
            diceRngState: diceRngState,
            resourcesByPlayer: Dictionary(uniqueKeysWithValues: roster.map { ($0, .zero) }),
            boardRules: nil,
            board: nil,
            setupState: nil,
            turnState: TurnStateV1(step: turnStep, lastRoll: lastRoll)
        ).rehashed()
    }
}
