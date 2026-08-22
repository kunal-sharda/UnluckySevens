@testable import MessagesExtensionSupport
import XCTest

final class GameMotionPolicyTests: XCTestCase {
    func testNormalPolicyAllowsSpatialMotionAndAnimation() {
        let policy = GameMotionPolicy(skipsAnimations: false, reducesMotion: false)

        XCTAssertTrue(policy.animatesSpatialMotion)
        XCTAssertFalse(policy.skipsAppAuthoredMotion)
        XCTAssertNotNil(policy.resolvedAnimation())
    }

    func testReduceMotionUsesNonSpatialAnimation() {
        let policy = GameMotionPolicy(skipsAnimations: false, reducesMotion: true)

        XCTAssertFalse(policy.animatesSpatialMotion)
        XCTAssertFalse(policy.skipsAppAuthoredMotion)
        XCTAssertNotNil(policy.resolvedAnimation())
    }

    func testExplicitSkipDisablesAuthoredAnimation() {
        let policy = GameMotionPolicy(skipsAnimations: true, reducesMotion: false)

        XCTAssertFalse(policy.animatesSpatialMotion)
        XCTAssertTrue(policy.skipsAppAuthoredMotion)
        XCTAssertNil(policy.resolvedAnimation())
    }

    func testCompactLaunchSpatialMotionIsSuppressedByEitherPreference() {
        XCTAssertFalse(
            GameMotionPolicy(
                skipsAnimations: true,
                reducesMotion: false
            ).animatesSpatialMotion
        )
        XCTAssertFalse(
            GameMotionPolicy(
                skipsAnimations: false,
                reducesMotion: true
            ).animatesSpatialMotion
        )
    }
}
