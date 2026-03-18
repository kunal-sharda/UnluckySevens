import ULS_CoreGame
import XCTest

final class GameShellStatusLineResolverTests: XCTestCase {
    func testTradePendingOverridesTurnOwnershipStatus() {
        let line = GameShellStatusLineResolver.resolve(
            hasTradePending: true,
            actingAs: "A",
            currentPlayer: "A",
            currentPlayerDisplay: "A",
            subtitle: "subtitle",
            turnStep: .pendingDiscards,
            discardRequiredForActingPlayer: true
        )

        XCTAssertEqual(line.title, "Trade pending")
    }

    func testYourTurnShownForCurrentActorWithoutTrade() {
        let line = GameShellStatusLineResolver.resolve(
            hasTradePending: false,
            actingAs: "A",
            currentPlayer: "A",
            currentPlayerDisplay: "A",
            subtitle: "subtitle",
            turnStep: .afterRoll
        )

        XCTAssertEqual(line.title, "Your turn")
    }

    func testWaitingOnShownForNonCurrentActorWithoutTrade() {
        let line = GameShellStatusLineResolver.resolve(
            hasTradePending: false,
            actingAs: "B",
            currentPlayer: "A",
            currentPlayerDisplay: "A",
            subtitle: "subtitle",
            turnStep: .afterRoll
        )

        XCTAssertEqual(line.title, "Waiting on A")
    }

    func testDiscardRequiredShownForActingPlayerDuringPendingDiscards() {
        let line = GameShellStatusLineResolver.resolve(
            hasTradePending: false,
            actingAs: "A",
            currentPlayer: "B",
            currentPlayerDisplay: "B",
            subtitle: "subtitle",
            turnStep: .pendingDiscards,
            discardRequiredForActingPlayer: true
        )

        XCTAssertEqual(line.title, "Discard required")
    }

    func testRobberMoveShownForCurrentActor() {
        let line = GameShellStatusLineResolver.resolve(
            hasTradePending: false,
            actingAs: "A",
            currentPlayer: "A",
            currentPlayerDisplay: "A",
            subtitle: "subtitle",
            turnStep: .needsRobberMove
        )

        XCTAssertEqual(line.title, "Move the robber")
    }

    func testStealCardShownForCurrentActor() {
        let line = GameShellStatusLineResolver.resolve(
            hasTradePending: false,
            actingAs: "A",
            currentPlayer: "A",
            currentPlayerDisplay: "A",
            subtitle: "subtitle",
            turnStep: .needsRobberSteal
        )

        XCTAssertEqual(line.title, "Steal a card")
    }
}
