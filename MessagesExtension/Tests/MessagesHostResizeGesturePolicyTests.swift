import UIKit
@_spi(MessagesHost) import MessagesExtensionSupport
import XCTest

@MainActor
final class MessagesHostResizeGesturePolicyTests: XCTestCase {
    func testPreventsOnlyAppleOwnedAncestorPanRecognizers() {
        let hostAncestor = UIView()
        let protectedView = UIView()
        let descendantView = UIView()
        hostAncestor.addSubview(protectedView)
        protectedView.addSubview(descendantView)

        let ancestorPan = UIPanGestureRecognizer()
        hostAncestor.addGestureRecognizer(ancestorPan)
        let sameRootPan = UIPanGestureRecognizer()
        protectedView.addGestureRecognizer(sameRootPan)
        let descendantPan = UIPanGestureRecognizer()
        descendantView.addGestureRecognizer(descendantPan)
        let ancestorTap = UITapGestureRecognizer()
        hostAncestor.addGestureRecognizer(ancestorTap)

        XCTAssertTrue(
            MessagesHostResizeGesturePolicy.shouldPrevent(
                protectedView: protectedView,
                gestureRecognizer: ancestorPan
            )
        )
        XCTAssertFalse(
            MessagesHostResizeGesturePolicy.shouldPrevent(
                protectedView: protectedView,
                gestureRecognizer: sameRootPan
            )
        )
        XCTAssertFalse(
            MessagesHostResizeGesturePolicy.shouldPrevent(
                protectedView: protectedView,
                gestureRecognizer: descendantPan
            )
        )
        XCTAssertFalse(
            MessagesHostResizeGesturePolicy.shouldPrevent(
                protectedView: protectedView,
                gestureRecognizer: ancestorTap
            )
        )
    }
}
