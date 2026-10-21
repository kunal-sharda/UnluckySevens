import XCTest
@testable import MessagesExtensionSupport

final class GameLifecycleMenuGuidanceTests: XCTestCase {
    func testAvailableActionNeedsNoRecoveryGuidance() {
        XCTAssertNil(
            GameLifecycleMenuGuidance.message(
                hasCurrentGame: true,
                hasLocalActor: true,
                hasCompatibleActiveConversation: true,
                hasAvailableAction: true
            )
        )
    }

    func testUnboundCurrentGameDirectsPlayerBackToItsBubble() {
        XCTAssertEqual(
            GameLifecycleMenuGuidance.message(
                hasCurrentGame: true,
                hasLocalActor: true,
                hasCompatibleActiveConversation: false,
                hasAvailableAction: false
            ),
            "Open this game from its Messages bubble to use game actions."
        )
    }

    func testUnknownLocalActorExplainsReadOnlyState() {
        XCTAssertEqual(
            GameLifecycleMenuGuidance.message(
                hasCurrentGame: true,
                hasLocalActor: false,
                hasCompatibleActiveConversation: true,
                hasAvailableAction: false
            ),
            "Game actions are read-only because this device cannot identify you as a player."
        )
    }

    func testLegalButInactiveStateDoesNotMisstateSessionRecovery() {
        XCTAssertEqual(
            GameLifecycleMenuGuidance.message(
                hasCurrentGame: true,
                hasLocalActor: true,
                hasCompatibleActiveConversation: true,
                hasAvailableAction: false
            ),
            "No current game actions are available."
        )
    }
}
