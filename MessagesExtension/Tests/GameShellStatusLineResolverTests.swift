import ULS_CoreGame
import XCTest

final class GameShellStatusLineResolverTests: XCTestCase {
    func testOpenGameShownWithoutCurrentPlayer() {
        let line = GameShellStatusLineResolver.resolve(
            actingAs: nil,
            currentPlayer: nil,
            currentPlayerDisplay: "player",
            subtitle: "subtitle"
        )

        XCTAssertEqual(line.title, "Open game")
    }

    func testYourTurnShownForCurrentActorWithoutTrade() {
        let line = GameShellStatusLineResolver.resolve(
            actingAs: "A",
            currentPlayer: "A",
            currentPlayerDisplay: "A",
            subtitle: "subtitle"
        )

        XCTAssertEqual(line.title, "Your turn")
    }

    func testNamedTurnShownForNonCurrentActorWithoutTrade() {
        let line = GameShellStatusLineResolver.resolve(
            actingAs: "B",
            currentPlayer: "A",
            currentPlayerDisplay: "A",
            subtitle: "subtitle"
        )

        XCTAssertEqual(line.title, "A's Turn")
    }

    func testGameOverShowsWinnerStatus() {
        let winnerLine = GameShellStatusLineResolver.resolve(
            actingAs: "A",
            currentPlayer: "B",
            currentPlayerDisplay: "B",
            subtitle: "Final score: A 10 | B 7",
            phase: .gameOver,
            winnerDisplay: "A",
            didLocalPlayerWin: true
        )
        XCTAssertEqual(winnerLine.title, "You won")

        let loserLine = GameShellStatusLineResolver.resolve(
            actingAs: "B",
            currentPlayer: "B",
            currentPlayerDisplay: "B",
            subtitle: "Final score: A 10 | B 7",
            phase: .gameOver,
            winnerDisplay: "A",
            didLocalPlayerWin: false
        )
        XCTAssertEqual(loserLine.title, "A won")
    }
}
