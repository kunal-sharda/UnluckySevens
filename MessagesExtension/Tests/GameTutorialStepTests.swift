import XCTest

final class GameTutorialStepTests: XCTestCase {
    func testTutorialHasExactlySeventeenOrderedGameplaySteps() {
        XCTAssertEqual(GameTutorialStep.all.count, 17)
        XCTAssertEqual(GameTutorialStep.all.map(\.id), GameTutorialStep.ID.allCases)
        XCTAssertTrue(GameTutorialStep.all.allSatisfy { $0.callouts.count <= 3 })
    }

    func testFinalStepsSeparateStrategyFromAwardsAndWinning() {
        let strategy = GameTutorialStep.all.dropLast().last
        let final = GameTutorialStep.all.last

        XCTAssertEqual(strategy?.id, .strategy)
        XCTAssertTrue(strategy?.guidance.contains("ports") == true)
        XCTAssertEqual(final?.id, .victoryAwards)
        XCTAssertTrue(final?.title.contains("Ten") == true)
        XCTAssertTrue(final?.guidance.contains("Settlements") == true)
        XCTAssertTrue(final?.guidance.contains("Largest Army") == true)
        XCTAssertTrue(final?.guidance.contains("Longest Road") == true)
    }

    func testTutorialContainsOnlyReadOnlyPresentationData() {
        XCTAssertTrue(GameTutorialStep.all.allSatisfy { !$0.title.isEmpty })
        XCTAssertTrue(GameTutorialStep.all.allSatisfy { !$0.guidance.isEmpty })
        XCTAssertTrue(GameTutorialStep.all.allSatisfy { !$0.previewAccessibilityLabel.isEmpty })
    }
}
