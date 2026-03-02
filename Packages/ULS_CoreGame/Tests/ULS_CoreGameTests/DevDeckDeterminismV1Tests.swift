import XCTest
@testable import ULS_CoreGame

final class DevDeckDeterminismV1Tests: XCTestCase {
    func testGoldenDrawSequence_masterSeed0123456789ABCDEF() {
        let deck = makeDeterministicDevDeck(masterSeed: 0x0123456789ABCDEF)
        let firstTen = Array(deck.prefix(10)).map(\.rawValue)

        XCTAssertEqual(
            firstTen,
            [
                "knight",
                "victoryPoint",
                "knight",
                "victoryPoint",
                "knight",
                "roadBuilding",
                "knight",
                "victoryPoint",
                "knight",
                "monopoly",
            ]
        )
    }

    func testStateHashContinuityAcrossDeterministicDraws() throws {
        let initial = CoreGameStateV1(
            gameId: "game-devdeck-hash",
            rev: 70,
            prevHash: "hash-69",
            stateHash: "",
            roster: ["A", "B"],
            currentPlayer: "A",
            phase: .turn,
            seed: 0x0123456789ABCDEF,
            diceRngState: 5,
            robberRngState: 6,
            resourcesByPlayer: [
                "A": .zero,
                "B": .zero,
            ],
            bankResources: .standardBank,
            devDeck: makeDeterministicDevDeck(masterSeed: 0x0123456789ABCDEF),
            boardRules: nil,
            board: nil,
            setupState: nil,
            turnState: TurnStateV1(step: .afterRoll, lastRoll: DiceRollV1(d1: 4, d2: 3))
        ).rehashed()

        let draw1 = try XCTUnwrap(drawTopDevCard(from: initial.devDeck))
        let afterFirstDraw = CoreGameStateV1(
            gameId: initial.gameId,
            rev: initial.rev + 1,
            prevHash: initial.stateHash,
            stateHash: "",
            roster: initial.roster,
            currentPlayer: initial.currentPlayer,
            phase: initial.phase,
            seed: initial.seed,
            diceRngState: initial.diceRngState,
            robberRngState: initial.robberRngState,
            resourcesByPlayer: initial.resourcesByPlayer,
            bankResources: initial.bankResources,
            devDeck: draw1.remaining,
            settlementsByNode: initial.settlementsByNode,
            citiesByNode: initial.citiesByNode,
            roadsByEdge: initial.roadsByEdge,
            boardRules: initial.boardRules,
            board: initial.board,
            setupState: initial.setupState,
            turnState: initial.turnState
        ).rehashed()

        let draw2 = try XCTUnwrap(drawTopDevCard(from: afterFirstDraw.devDeck))
        let afterSecondDraw = CoreGameStateV1(
            gameId: afterFirstDraw.gameId,
            rev: afterFirstDraw.rev + 1,
            prevHash: afterFirstDraw.stateHash,
            stateHash: "",
            roster: afterFirstDraw.roster,
            currentPlayer: afterFirstDraw.currentPlayer,
            phase: afterFirstDraw.phase,
            seed: afterFirstDraw.seed,
            diceRngState: afterFirstDraw.diceRngState,
            robberRngState: afterFirstDraw.robberRngState,
            resourcesByPlayer: afterFirstDraw.resourcesByPlayer,
            bankResources: afterFirstDraw.bankResources,
            devDeck: draw2.remaining,
            settlementsByNode: afterFirstDraw.settlementsByNode,
            citiesByNode: afterFirstDraw.citiesByNode,
            roadsByEdge: afterFirstDraw.roadsByEdge,
            boardRules: afterFirstDraw.boardRules,
            board: afterFirstDraw.board,
            setupState: afterFirstDraw.setupState,
            turnState: afterFirstDraw.turnState
        ).rehashed()

        XCTAssertEqual(afterFirstDraw.prevHash, initial.stateHash)
        XCTAssertEqual(afterSecondDraw.prevHash, afterFirstDraw.stateHash)
        XCTAssertNotEqual(afterFirstDraw.stateHash, initial.stateHash)
        XCTAssertNotEqual(afterSecondDraw.stateHash, afterFirstDraw.stateHash)
    }

    func testSameSeedAndDrawCountProduceIdenticalDeckState() throws {
        let masterSeed: UInt64 = 0xABCDEF
        let draws = 5

        var first = makeDeterministicDevDeck(masterSeed: masterSeed)
        var second = makeDeterministicDevDeck(masterSeed: masterSeed)

        for _ in 0 ..< draws {
            first = try XCTUnwrap(drawTopDevCard(from: first)).remaining
            second = try XCTUnwrap(drawTopDevCard(from: second)).remaining
        }

        XCTAssertEqual(first, second)
    }
}
