import XCTest
@testable import MessagesExtension

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

    func testTechnicalTermsDoNotReachPlayerCopy() {
        let copy = PlayerFacingErrorCopy.message(
            for: "Publish failed: canonical STATE payload has invalid phase/step"
        )

        XCTAssertFalse(copy.localizedCaseInsensitiveContains("payload"))
        XCTAssertFalse(copy.localizedCaseInsensitiveContains("state"))
        XCTAssertFalse(copy.localizedCaseInsensitiveContains("phase"))
    }
}
