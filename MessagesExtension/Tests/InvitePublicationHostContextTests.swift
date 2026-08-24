import Foundation
import XCTest
@testable import MessagesExtensionSupport

final class InvitePublicationHostContextTests: XCTestCase {
    func testInitialAndRepeatedConversationDoNotInvalidateAttempt() {
        var context = InvitePublicationHostContext()
        let conversation = NSObject()
        let identity = ObjectIdentifier(conversation)

        XCTAssertFalse(context.adopt(conversationIdentity: identity))
        XCTAssertFalse(context.adopt(conversationIdentity: identity))
    }

    func testDifferentConversationInvalidatesAttempt() {
        var context = InvitePublicationHostContext()
        let firstConversation = NSObject()
        let secondConversation = NSObject()
        _ = context.adopt(conversationIdentity: ObjectIdentifier(firstConversation))

        XCTAssertTrue(
            context.adopt(conversationIdentity: ObjectIdentifier(secondConversation))
        )
    }

    func testClearingExistingConversationInvalidatesAttempt() {
        var context = InvitePublicationHostContext()
        let conversation = NSObject()
        _ = context.adopt(conversationIdentity: ObjectIdentifier(conversation))

        XCTAssertTrue(context.adopt(conversationIdentity: nil))
    }
}
