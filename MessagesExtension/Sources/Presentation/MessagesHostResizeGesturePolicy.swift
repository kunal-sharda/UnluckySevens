import UIKit

@MainActor
@_spi(MessagesHost)
public enum MessagesHostResizeGesturePolicy {
    public static func shouldPrevent(
        protectedView: UIView?,
        gestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        guard gestureRecognizer is UIPanGestureRecognizer,
              let protectedView,
              let gestureView = gestureRecognizer.view,
              gestureView !== protectedView else {
            return false
        }

        return protectedView.isDescendant(of: gestureView)
    }
}
