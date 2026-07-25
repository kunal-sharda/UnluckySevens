import XCTest

final class GameTutorialStepTests: XCTestCase {
    func testTutorialHasExactlySixteenOrderedGameplaySteps() {
        XCTAssertEqual(GameTutorialStep.all.count, 16)
        XCTAssertEqual(GameTutorialStep.all.map(\.id), GameTutorialStep.ID.allCases)
        XCTAssertTrue(GameTutorialStep.all.allSatisfy { $0.callouts.count <= 3 })
    }

    func testFinalStepCombinesStrategyAndScoring() {
        let final = GameTutorialStep.all.last

        XCTAssertEqual(final?.id, .strategy)
        XCTAssertEqual(final?.title, "Strategy")
        XCTAssertTrue(final?.guidance.contains("Roads") == true)
        XCTAssertTrue(final?.guidance.contains("Settlements") == true)
        XCTAssertTrue(final?.guidance.contains("cities") == true)
        XCTAssertTrue(final?.callouts.isEmpty == true)
    }

    func testTutorialContainsOnlyReadOnlyPresentationData() {
        XCTAssertTrue(GameTutorialStep.all.allSatisfy { !$0.title.isEmpty })
        XCTAssertTrue(GameTutorialStep.all.allSatisfy { !$0.guidance.isEmpty })
        XCTAssertTrue(GameTutorialStep.all.allSatisfy { !$0.previewAccessibilityLabel.isEmpty })
    }

    func testPreviewAccessibilityLabelsDoNotUseSyntheticRealSurfaceCopy() {
        XCTAssertTrue(
            GameTutorialStep.all.allSatisfy {
                !$0.previewAccessibilityLabel.localizedCaseInsensitiveContains("the real")
            }
        )
    }

    func testEveryTradeStepHasVisibleGuidanceAnchoredToProductionControls() throws {
        let steps = Dictionary(
            uniqueKeysWithValues: GameTutorialStep.all.map { ($0.id, $0) }
        )

        XCTAssertEqual(
            try XCTUnwrap(steps[.playerTrade]).callouts.map(\.target),
            [.tradeGive]
        )
        XCTAssertEqual(
            try XCTUnwrap(steps[.tradeRecipients]).callouts.map(\.target),
            [.tradeRecipients]
        )
        XCTAssertEqual(
            try XCTUnwrap(steps[.bankTrade]).callouts.map(\.target),
            [.maritimeOptions]
        )
    }
}
