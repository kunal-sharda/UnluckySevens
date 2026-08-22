import XCTest
@testable import MessagesExtensionSupport

final class PlayerFacingErrorCopyTests: XCTestCase {
    func testKnownFailuresReceiveSpecificRecoveryCopy() {
        XCTAssertEqual(
            PlayerFacingErrorCopy.message(for: "Invite failed: network unavailable"),
            "Couldn't send the invite. Check your connection and try again."
        )
        XCTAssertEqual(
            PlayerFacingErrorCopy.message(for: "Selected maritime trade is not legal."),
            "That trade is no longer available. Reopen the latest game message."
        )
        XCTAssertEqual(
            PlayerFacingErrorCopy.message(for: "Decode failed: malformed payload"),
            "Couldn't open this game message. Ask the sender to resend it."
        )
    }

    func testUnknownFailureUsesOneGenericRecoveryMessage() {
        XCTAssertEqual(
            PlayerFacingErrorCopy.message(for: "Unexpected subsystem failure"),
            "Something went wrong. Reopen the latest game message and try again."
        )
    }

    func testRecoveryFailuresHaveDistinctGuidance() {
        XCTAssertEqual(
            PlayerFacingErrorCopy.message(for: "Missing message payload."),
            "This message doesn't contain a game. Ask the sender to resend the latest game state."
        )
        XCTAssertEqual(
            PlayerFacingErrorCopy.message(for: "Unsupported transport version."),
            "This game message uses an unsupported version. Update Unlucky Sevens, then ask the sender to resend it."
        )
        XCTAssertEqual(
            PlayerFacingErrorCopy.message(for: "Invalid canonical state hash."),
            "This game message failed its integrity check. Ask the sender to resend the latest state."
        )
        XCTAssertEqual(
            PlayerFacingErrorCopy.message(for: "Corrupt local recovery record."),
            "The saved copy on this device is damaged. Open a valid game bubble or ask a player to resend it."
        )
        XCTAssertEqual(
            PlayerFacingErrorCopy.message(for: "Malformed game payload."),
            "This game message is damaged. Ask the sender to resend the latest state."
        )
    }

    func testTechnicalTermsDoNotReachPlayerCopy() {
        let copy = PlayerFacingErrorCopy.message(
            for: "Publish failed: canonical STATE payload has invalid phase/step"
        )

        XCTAssertFalse(copy.localizedCaseInsensitiveContains("payload"))
        XCTAssertFalse(copy.localizedCaseInsensitiveContains("state"))
        XCTAssertFalse(copy.localizedCaseInsensitiveContains("phase"))
    }
}
