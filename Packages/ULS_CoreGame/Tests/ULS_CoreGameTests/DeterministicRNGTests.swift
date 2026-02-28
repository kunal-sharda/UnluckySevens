import XCTest
@testable import ULS_CoreGame

final class DeterministicRNGTests: XCTestCase {
    func testRollDiceGoldenSequence_seed0123456789ABCDEF() {
        var rng = DeterministicRNG(seed: 0x0123456789ABCDEF)
        var rolls: [[Int]] = []

        for _ in 0..<12 {
            let (a, b) = rng.rollDice()
            rolls.append([a, b])
        }

        XCTAssertEqual(
            rolls,
            [
                [4, 6], [3, 3], [3, 5], [6, 4],
                [6, 4], [6, 1], [6, 2], [6, 4],
                [3, 3], [1, 1], [1, 5], [5, 2],
            ]
        )
    }

    func testSameSeedProducesSameSequence() {
        var left = DeterministicRNG(seed: 12345)
        var right = DeterministicRNG(seed: 12345)

        var leftRolls: [[Int]] = []
        var rightRolls: [[Int]] = []

        for _ in 0..<16 {
            let leftPair = left.rollDice()
            let rightPair = right.rollDice()
            leftRolls.append([leftPair.0, leftPair.1])
            rightRolls.append([rightPair.0, rightPair.1])
        }

        XCTAssertEqual(leftRolls, rightRolls)
    }

    func testDifferentSeedsProduceDifferentSequence() {
        var left = DeterministicRNG(seed: 12345)
        var right = DeterministicRNG(seed: 12346)

        var leftRolls: [[Int]] = []
        var rightRolls: [[Int]] = []

        for _ in 0..<16 {
            let leftPair = left.rollDice()
            let rightPair = right.rollDice()
            leftRolls.append([leftPair.0, leftPair.1])
            rightRolls.append([rightPair.0, rightPair.1])
        }

        XCTAssertNotEqual(leftRolls, rightRolls)
    }
}
