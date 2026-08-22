import XCTest
import ULS_CoreGame
@testable import MessagesExtensionSupport

final class GameResourceHandDraftTransformTests: XCTestCase {
    func testHandConversionsAndUpdatesPreserveResourceCounts() {
        let hand = ResourceHandV1(wood: 2, brick: 1, sheep: 0, wheat: 3, ore: 4)

        XCTAssertEqual(
            GameResourceHandDraftTransform.countMap(for: hand),
            [.wood: 2, .brick: 1, .wheat: 3, .ore: 4]
        )
        XCTAssertEqual(
            GameResourceHandDraftTransform.resourceHand(from: [
                GameHandChip(resource: .wood, count: 2),
                GameHandChip(resource: .wheat, count: 3),
            ]),
            ResourceHandV1(wood: 2, wheat: 3)
        )
        XCTAssertEqual(
            GameResourceHandDraftTransform.updating(resource: .wood, in: hand, delta: -5),
            ResourceHandV1(brick: 1, wheat: 3, ore: 4)
        )
    }

    func testDiscardSanitizingClampsAvailabilityAndRejectsOverSelection() {
        let available = [
            GameHandChip(resource: .wood, count: 2),
            GameHandChip(resource: .brick, count: 1),
        ]

        XCTAssertEqual(
            GameResourceHandDraftTransform.sanitizingDiscardDraft(
                ResourceHandV1(wood: 5, brick: 1),
                requiredCount: 3,
                availableHand: available
            ),
            ResourceHandV1(wood: 2, brick: 1)
        )
        XCTAssertEqual(
            GameResourceHandDraftTransform.sanitizingDiscardDraft(
                ResourceHandV1(wood: 2, brick: 1),
                requiredCount: 2,
                availableHand: available
            ),
            .zero
        )
    }

    func testRecipientToggleIsSortedAndCounterDraftIsImmutable() {
        let offer = GameTradeDraft(
            kind: .offer,
            give: ResourceHandV1(wood: 1),
            receive: ResourceHandV1(brick: 1),
            recipients: ["C"]
        )

        let added = GameResourceHandDraftTransform.togglingRecipient("A", in: offer)
        XCTAssertEqual(added.recipients, ["A", "C"])
        XCTAssertEqual(
            GameResourceHandDraftTransform.togglingRecipient("C", in: added).recipients,
            ["A"]
        )

        let counter = GameTradeDraft(
            kind: .counter(originalProposerID: "A"),
            give: .zero,
            receive: .zero,
            recipients: ["A"]
        )
        XCTAssertEqual(
            GameResourceHandDraftTransform.togglingRecipient("B", in: counter),
            counter
        )
    }
}
