import XCTest
@testable import ULS_CoreGame

final class TurnRollSevenV1Tests: XCTestCase {
    private let topology = StandardBoardTopologyV1.standard()
    private static let rollSevenSeed: UInt64 = {
        var seed: UInt64 = 0
        while seed < 1_000_000 {
            var rng = DeterministicRNG(seed: seed)
            let roll = rng.rollDice()
            if roll.0 + roll.1 == 7 {
                return seed
            }
            seed += 1
        }
        preconditionFailure("Expected to find a deterministic seed for a first-roll seven.")
    }()

    func testRollSevenComputesFloorHalfDiscardRequirements() throws {
        let initial = makeTurnState(
            diceSeed: Self.rollSevenSeed,
            resourcesByPlayer: [
                "A": ResourceHandV1(wood: 9),
                "B": ResourceHandV1(wood: 7),
                "C": ResourceHandV1(ore: 11),
            ]
        )

        let rolled = try apply(intent: .rollDice, to: initial, actor: "A")

        XCTAssertEqual(rolled.turnState?.lastRoll.map { $0.d1 + $0.d2 }, 7)
        XCTAssertEqual(rolled.turnState?.step, .pendingDiscards)
        XCTAssertEqual(rolled.turnState?.discardRequirementsByPlayer, ["A": 4, "C": 5])
        XCTAssertEqual(rolled.turnState?.submittedDiscardsByPlayer, [:])
        XCTAssertNoThrow(try validateTransition(from: initial, to: rolled, actor: "A"))
    }

    func testOnlyRequiredPlayersCanSubmitDiscard() throws {
        let initial = makeTurnState(
            diceSeed: Self.rollSevenSeed,
            resourcesByPlayer: [
                "A": ResourceHandV1(wood: 8),
                "B": ResourceHandV1(wood: 7),
                "C": .zero,
            ]
        )
        let rolled = try apply(intent: .rollDice, to: initial, actor: "A")

        XCTAssertThrowsError(
            try apply(intent: .submitDiscard(player: "B", discarded: ResourceHandV1(wood: 3)), to: rolled, actor: "A")
        ) { error in
            XCTAssertEqual(error as? CoreGameError, .discardSubmissionNotRequired)
        }
    }

    func testDiscardCompletionGatesNeedsRobberMove() throws {
        let initial = makeTurnState(
            diceSeed: Self.rollSevenSeed,
            resourcesByPlayer: [
                "A": ResourceHandV1(wood: 8),
                "B": ResourceHandV1(brick: 8),
                "C": ResourceHandV1(wheat: 6),
            ]
        )
        let rolled = try apply(intent: .rollDice, to: initial, actor: "A")

        let afterFirstDiscard = try apply(
            intent: .submitDiscard(player: "A", discarded: ResourceHandV1(wood: 4)),
            to: rolled,
            actor: "A"
        )
        XCTAssertEqual(afterFirstDiscard.turnState?.step, .pendingDiscards)
        XCTAssertNoThrow(try validateTransition(from: rolled, to: afterFirstDiscard, actor: "A"))

        let afterSecondDiscard = try apply(
            intent: .submitDiscard(player: "B", discarded: ResourceHandV1(brick: 4)),
            to: afterFirstDiscard,
            actor: "A"
        )
        XCTAssertEqual(afterSecondDiscard.turnState?.step, .needsRobberMove)
        XCTAssertNoThrow(try validateTransition(from: afterFirstDiscard, to: afterSecondDiscard, actor: "A"))
    }

    func testRobberMoveRejectedBeforeAllDiscardsSubmittedStateUnchanged() throws {
        let initial = makeTurnState(
            diceSeed: Self.rollSevenSeed,
            resourcesByPlayer: [
                "A": ResourceHandV1(wood: 8),
                "B": ResourceHandV1(brick: 8),
                "C": .zero,
            ]
        )
        let rolled = try apply(intent: .rollDice, to: initial, actor: "A")
        let rolledSnapshot = rolled

        XCTAssertThrowsError(try apply(intent: .moveRobber(tileID: 1), to: rolled, actor: "A")) { error in
            XCTAssertEqual(error as? CoreGameError, .turnStepMismatch)
        }
        XCTAssertEqual(rolled, rolledSnapshot)
    }

    private func makeTurnState(
        diceSeed: UInt64,
        resourcesByPlayer: [String: ResourceHandV1]
    ) -> CoreGameStateV1 {
        let rules = BoardRulesV1(strategy: .randomV1)
        let board = StandardBoardGeneratorV1.generate(
            boardSeed: SeedDeriver(masterSeed: 1234).seed(for: .board),
            rules: rules
        )
        return CoreGameStateV1(
            gameId: "game-roll-7",
            rev: 12,
            prevHash: "hash-11",
            stateHash: "",
            roster: ["A", "B", "C"],
            currentPlayer: "A",
            phase: .turn,
            seed: 1234,
            diceRngState: diceSeed,
            resourcesByPlayer: resourcesByPlayer,
            bankResources: .standardBank,
            settlementsByNode: [topology.tiles[0].nodes[0]: "A"],
            citiesByNode: [:],
            roadsByEdge: [:],
            boardRules: rules,
            board: board,
            setupState: nil,
            turnState: TurnStateV1(step: .needsRoll, lastRoll: nil)
        ).rehashed()
    }
}
