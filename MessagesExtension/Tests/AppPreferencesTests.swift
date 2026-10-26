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

    func testIndividualTipsDefaultOnAndPersistIndependently() {
        let preferences = AppPreferences(userDefaults: userDefaults)
        XCTAssertTrue(GameTutorialTip.allCases.allSatisfy { preferences.shouldShowTip($0) })
        preferences.setTip(.buildCosts, enabled: false)
        let reopened = AppPreferences(userDefaults: userDefaults)
        XCTAssertFalse(reopened.shouldShowTip(.buildCosts))
        XCTAssertTrue(reopened.shouldShowTip(.devPurchase))
        XCTAssertTrue(reopened.shouldShowTip(.actionCardTiming))
        XCTAssertTrue(reopened.shouldShowTip(.victoryPointScoring))
        reopened.setTip(.buildCosts, enabled: true)
        XCTAssertTrue(AppPreferences(userDefaults: userDefaults).shouldShowTip(.buildCosts))
    }

    func testGlobalPausePreservesIndividualChoicesAndLegacyOffPreference() {
        userDefaults.set(false, forKey: AppPreferences.tutorialPopupsKey)
        let preferences = AppPreferences(userDefaults: userDefaults)
        XCTAssertTrue(GameTutorialTip.allCases.allSatisfy { !preferences.shouldShowTip($0) })
        preferences.setTip(.buildCosts, enabled: false)
        preferences.tutorialPopupsEnabled = true
        XCTAssertFalse(preferences.shouldShowTip(.buildCosts))
        XCTAssertTrue(preferences.shouldShowTip(.devPurchase))
        preferences.tutorialPopupsEnabled = false
        let reopened = AppPreferences(userDefaults: userDefaults)
        reopened.tutorialPopupsEnabled = true
        XCTAssertFalse(reopened.shouldShowTip(.buildCosts))
        XCTAssertTrue(reopened.shouldShowTip(.devPurchase))
    }

    func testEnableAllRestoresMasterAndEveryTipWithoutChangingOtherSettings() {
        let preferences = AppPreferences(userDefaults: userDefaults)
        preferences.skipsAnimations = true
        for tip in GameTutorialTip.allCases { preferences.setTip(tip, enabled: false) }
        preferences.tutorialPopupsEnabled = false
        preferences.enableAllTutorialTips()
        let reopened = AppPreferences(userDefaults: userDefaults)
        XCTAssertTrue(GameTutorialTip.allCases.allSatisfy { reopened.shouldShowTip($0) })
        XCTAssertTrue(reopened.skipsAnimations)
    }

    func testActionTimingAndVictoryPointTipsCanBeDisabledSeparately() {
        let preferences = AppPreferences(userDefaults: userDefaults)
        preferences.setTip(.newCard(.knight), enabled: false)
        for kind: GameDevCardVisualKind in [.knight, .monopoly, .yearOfPlenty, .roadBuilding] {
            XCTAssertFalse(preferences.shouldShowTip(.newCard(kind)))
        }
        XCTAssertTrue(preferences.shouldShowTip(.newCard(.victoryPoint)))
        preferences.setTip(.victoryPointScoring, enabled: false)
        preferences.setTip(.actionCardTiming, enabled: true)
        XCTAssertFalse(preferences.shouldShowTip(.newCard(.victoryPoint)))
        XCTAssertTrue(preferences.shouldShowTip(.newCard(.knight)))
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
