import XCTest
@testable import MessagesExtension

final class TemporaryDiagnosticsConfigTests: XCTestCase {
    func testLiveConfigIsEnabledByDefault() {
        XCTAssertTrue(TemporaryDiagnosticsConfig.live.isEnabled)
    }

    func testDisabledConfigSupportsFutureGateDown() {
        XCTAssertFalse(TemporaryDiagnosticsConfig.disabled.isEnabled)
    }
}
