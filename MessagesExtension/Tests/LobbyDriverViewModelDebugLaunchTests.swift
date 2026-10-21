#if DEBUG
import XCTest
@testable import MessagesExtensionSupport

@MainActor
final class LobbyDriverViewModelDebugLaunchTests: XCTestCase {
    func testDebugLaunchDefaultsActivateCleanFixtureWithoutTutorialState() {
        let suiteName = "LobbyDriverViewModelDebugLaunchTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defaults.set(
            UXTestFixtures.setupPlacementID,
            forKey: UXTestFixtures.launchFixtureIDDefaultsKey
        )
        defaults.set(UXTestFixtures.alice, forKey: UXTestFixtures.launchActorIDDefaultsKey)

        let viewModel = LobbyDriverViewModel(userDefaults: defaults)

        XCTAssertTrue(viewModel.uxTestingIsActive)
        XCTAssertTrue(viewModel.uxTestingChromeHiddenForScreenshot)
        XCTAssertEqual(viewModel.uxTestingSelectedFixtureID, UXTestFixtures.setupPlacementID)
        XCTAssertEqual(viewModel.uxTestingActorID, UXTestFixtures.alice)
        XCTAssertEqual(viewModel.rootRoute, .game)
    }
}
#endif
