@testable import MessagesExtensionSupport
import XCTest

@MainActor
final class AppPreferencesTests: XCTestCase {
    private var userDefaults: UserDefaults!
    private var suiteName: String!

    override func setUp() {
        super.setUp()
        suiteName = "AppPreferencesTests.\(UUID().uuidString)"
        userDefaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        userDefaults.removePersistentDomain(forName: suiteName)
        userDefaults = nil
        suiteName = nil
        super.tearDown()
    }

    func testTutorialPopupsDefaultOn() {
        XCTAssertTrue(AppPreferences(userDefaults: userDefaults).tutorialPopupsEnabled)
    }

    func testTutorialDisableAndReenablePersistAcrossPreferenceInstances() {
        let initial = AppPreferences(userDefaults: userDefaults)
        initial.tutorialPopupsEnabled = false
        let reopened = AppPreferences(userDefaults: userDefaults)
        XCTAssertFalse(reopened.tutorialPopupsEnabled)
        XCTAssertFalse(userDefaults.bool(forKey: AppPreferences.tutorialPopupsKey))
        reopened.tutorialPopupsEnabled = true
        XCTAssertTrue(AppPreferences(userDefaults: userDefaults).tutorialPopupsEnabled)
        XCTAssertFalse(reopened.skipsAnimations, "Tutorial preferences must not change animation settings")
    }

    func testSkipAnimationsDefaultsOff() {
        XCTAssertFalse(AppPreferences(userDefaults: userDefaults).skipsAnimations)
    }

    func testSkipAnimationsPersistsLocally() {
        let preferences = AppPreferences(userDefaults: userDefaults)
        preferences.skipsAnimations = true

        XCTAssertTrue(AppPreferences(userDefaults: userDefaults).skipsAnimations)
        XCTAssertTrue(userDefaults.bool(forKey: AppPreferences.skipAnimationsKey))
    }
}
