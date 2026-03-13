import XCTest

final class GameShellStatusLineResolverTests: XCTestCase {
    func testTradePendingOverridesTurnOwnershipStatus() {
        let line = GameShellStatusLineResolver.resolve(
            hasTradePending: true,
            actingAs: "A",
            currentPlayer: "A",
            currentPlayerDisplay: "A",
            subtitle: "subtitle"
        )

        XCTAssertEqual(line.title, "Trade pending")
    }

    func testYourTurnShownForCurrentActorWithoutTrade() {
        let line = GameShellStatusLineResolver.resolve(
            hasTradePending: false,
            actingAs: "A",
            currentPlayer: "A",
            currentPlayerDisplay: "A",
            subtitle: "subtitle"
        )

        XCTAssertEqual(line.title, "Your turn")
    }

    func testWaitingOnShownForNonCurrentActorWithoutTrade() {
        let line = GameShellStatusLineResolver.resolve(
            hasTradePending: false,
            actingAs: "B",
            currentPlayer: "A",
            currentPlayerDisplay: "A",
            subtitle: "subtitle"
        )

        XCTAssertEqual(line.title, "Waiting on A")
    }
}
