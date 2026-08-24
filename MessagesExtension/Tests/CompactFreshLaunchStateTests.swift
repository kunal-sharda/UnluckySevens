@testable import MessagesExtensionSupport
import XCTest

final class CompactFreshLaunchStateTests: XCTestCase {
    func testEachFreshActivationGetsANewToken() {
        var state = CompactFreshLaunchState()

        state.begin()
        let firstToken = state.visibleToken
        XCTAssertNotNil(firstToken)

        XCTAssertTrue(state.consume())
        state.endActivation()
        state.begin()

        XCTAssertNotEqual(state.visibleToken, firstToken)
    }

    func testConsumedLaunchDoesNotReplayWithinTheSameActivation() {
        var state = CompactFreshLaunchState()
        state.begin()

        XCTAssertTrue(state.consume())
        XCTAssertNil(state.visibleToken)
        XCTAssertFalse(state.consume())
    }

    func testRepeatedBeginDoesNotReplayConsumedEntranceWithinOneActivation() {
        var state = CompactFreshLaunchState()
        state.begin()

        XCTAssertTrue(state.consume())
        state.begin()

        XCTAssertNil(state.visibleToken)
    }

    func testSelectedMessageDismissesFreshLaunch() {
        var state = CompactFreshLaunchState()
        state.begin()

        state.dismiss()

        XCTAssertNil(state.visibleToken)

        state.begin()
        XCTAssertNotNil(state.visibleToken)
    }
}
