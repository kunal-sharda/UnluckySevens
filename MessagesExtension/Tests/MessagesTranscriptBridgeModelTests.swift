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
        XCTAssertTrue(model.canOpenGame)
    }

    func testBridgeHasUsefulEmptyState() {
        let model = MessagesTranscriptBridgeModel.resolve(
            currentGameId: nil,
            recoveredGames: []
        )

        XCTAssertEqual(model.title, "Unlucky Sevens")
        XCTAssertEqual(model.status, "Select a game bubble to continue")
        XCTAssertFalse(model.canOpenGame)
    }

    func testBridgeDoesNotFallBackToSavedRecordWithoutCurrentGame() {
        let model = MessagesTranscriptBridgeModel.resolve(
            currentGameId: nil,
            recoveredGames: [summary(id: "saved", current: true, lastActive: true)]
        )

        XCTAssertEqual(model.title, "Unlucky Sevens")
        XCTAssertFalse(model.canOpenGame)
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
