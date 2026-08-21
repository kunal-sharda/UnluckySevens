import XCTest

final class MessagesLaunchRouteTests: XCTestCase {
    func testDrawerLaunchWithoutSelectedMessageStartsFreshLobby() {
        XCTAssertEqual(
            MessagesLaunchRoute.resolve(hasSelectedMessage: false),
            .freshLobby
        )
    }

    func testSelectedGameBubbleResumesMessageContext() {
        XCTAssertEqual(
            MessagesLaunchRoute.resolve(hasSelectedMessage: true),
            .selectedMessage
        )
    }

    func testFreshDrawerLaunchRemainsCompact() {
        XCTAssertFalse(MessagesLaunchRoute.freshLobby.requestsExpandedPresentation)
    }

    func testSelectedGameBubbleRequestsExpandedPresentation() {
        XCTAssertTrue(MessagesLaunchRoute.selectedMessage.requestsExpandedPresentation)
    }
}
