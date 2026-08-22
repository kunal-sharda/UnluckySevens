@testable import MessagesExtensionSupport
import XCTest

final class MessagesRootRouteTests: XCTestCase {
    func testResolveReturnsLobbyWhenPhaseIsNilOrLobby() {
        XCTAssertEqual(MessagesRootRoute.resolve(phase: nil), .lobby)
        XCTAssertEqual(MessagesRootRoute.resolve(phase: .lobby), .lobby)
    }

    func testResolveReturnsGameForPlayableAndTerminalPhases() {
        XCTAssertEqual(MessagesRootRoute.resolve(phase: .setup), .game)
        XCTAssertEqual(MessagesRootRoute.resolve(phase: .turn), .game)
        XCTAssertEqual(MessagesRootRoute.resolve(phase: .gameOver), .game)
    }
}
