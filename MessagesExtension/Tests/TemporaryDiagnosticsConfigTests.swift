import XCTest
@testable import MessagesExtension

final class TemporaryDiagnosticsConfigTests: XCTestCase {
    func testLiveConfigIsGatedDownForReleaseReadiness() {
        XCTAssertFalse(TemporaryDiagnosticsConfig.live.isEnabled)
    }

    func testDisabledConfigSupportsFutureGateDown() {
        XCTAssertFalse(TemporaryDiagnosticsConfig.disabled.isEnabled)
    }
}
