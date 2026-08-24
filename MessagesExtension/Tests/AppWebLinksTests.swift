import XCTest
@testable import MessagesExtensionSupport

final class AppWebLinksTests: XCTestCase {
    func testProductURLUsesOwnedHTTPSPath() {
        XCTAssertEqual(AppWebLinks.productURL.scheme, "https")
        XCTAssertEqual(AppWebLinks.productURL.host, "ksharda.me")
        XCTAssertEqual(AppWebLinks.productURL.path, "/unluckysevens")
    }

    func testPrivacyPolicyURLUsesOwnedHTTPSPath() {
        XCTAssertEqual(AppWebLinks.privacyPolicyURL.scheme, "https")
        XCTAssertEqual(AppWebLinks.privacyPolicyURL.host, "ksharda.me")
        XCTAssertEqual(AppWebLinks.privacyPolicyURL.path, "/unluckysevens/privacy")
    }

    func testMessageURLContractUsesOwnedDomainNamespace() {
        XCTAssertEqual(AppWebLinks.messageHost, "ksharda.me")
        XCTAssertEqual(AppWebLinks.messagePath, "/unluckysevens/msg")
    }
}
