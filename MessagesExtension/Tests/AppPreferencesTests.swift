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
