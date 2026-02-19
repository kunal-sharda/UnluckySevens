import XCTest
@testable import ULS_CoreGame

final class ULS_CoreGameTests: XCTestCase {
    func testStageMarker() {
        XCTAssertEqual(CoreGameStub.stage, "0.B")
    }
}
