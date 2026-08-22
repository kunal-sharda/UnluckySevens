import XCTest
@testable import MessagesExtensionSupport

final class MessagesTranscriptBridgeModelTests: XCTestCase {
    func testBridgePrefersCurrentGame() {
        let games = [
            summary(id: "old", current: false, lastActive: true),
            summary(id: "current", current: true, lastActive: false),
        ]

        let model = MessagesTranscriptBridgeModel.resolve(
            currentGameId: "current",
            recoveredGames: games
        )

        XCTAssertEqual(model.title, "Players current")
        XCTAssertEqual(model.status, "Status current")
    }

    func testBridgeHasUsefulEmptyState() {
        let model = MessagesTranscriptBridgeModel.resolve(
            currentGameId: nil,
            recoveredGames: []
        )

        XCTAssertEqual(model.title, "Unlucky Sevens")
        XCTAssertEqual(model.status, "Open the game to continue")
    }

    private func summary(
        id: String,
        current: Bool,
        lastActive: Bool
    ) -> ActiveGameRecoverySummary {
        ActiveGameRecoverySummary(
            id: id,
            gameId: id,
            title: "Players \(id)",
            subtitle: "Status \(id)",
            detail: "Updated now",
            isFinished: false,
            isLastActive: lastActive,
            isCurrentSelection: current
        )
    }
}
