import UIKit

@MainActor
final class MessagesHostResizeShield: NSObject, UIGestureRecognizerDelegate {
    private let captureRecognizer = HostBoundaryDragGestureRecognizer()
    private weak var protectedView: UIView?
    private var topExclusionHeight: CGFloat = 0
    private var linkedAncestorPans: [UIPanGestureRecognizer] = []
    var onEvent: ((HostGestureEvent) -> Void)?

    override init() {
        super.init()
        captureRecognizer.delegate = self
        captureRecognizer.cancelsTouchesInView = false
        captureRecognizer.delaysTouchesBegan = false
        captureRecognizer.delaysTouchesEnded = false
        captureRecognizer.addTarget(self, action: #selector(handleCaptureRecognizerStateChange(_:)))
    }

    func attach(to view: UIView, topExclusionHeight: CGFloat) {
        self.topExclusionHeight = topExclusionHeight

        if protectedView !== view {
            protectedView?.removeGestureRecognizer(captureRecognizer)
            view.addGestureRecognizer(captureRecognizer)
            protectedView = view
        }

        relinkAncestorPanRecognizers()
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard let protectedView else {
            return false
        }

        let location = touch.location(in: protectedView)
        return location.y > topExclusionHeight
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        guard let protectedView, let otherView = otherGestureRecognizer.view else {
            return false
        }

        return otherView.isDescendant(of: protectedView)
    }

    private func relinkAncestorPanRecognizers() {
        linkedAncestorPans.removeAll()

        guard let protectedView else {
            return
        }

        var ancestor = protectedView.superview
        while let current = ancestor {
            for gestureRecognizer in current.gestureRecognizers ?? [] {
                guard let panGestureRecognizer = gestureRecognizer as? UIPanGestureRecognizer else {
                    continue
                }
                guard panGestureRecognizer !== captureRecognizer else {
                    continue
                }

                panGestureRecognizer.require(toFail: captureRecognizer)
                linkedAncestorPans.append(panGestureRecognizer)
            }
            ancestor = current.superview
        }
    }

    @objc
    private func handleCaptureRecognizerStateChange(_ recognizer: UIGestureRecognizer) {
        switch recognizer.state {
        case .began:
            onEvent?(HostGestureEvent(kind: .hostShieldBegan, detail: "protected-area"))
        case .ended:
            onEvent?(HostGestureEvent(kind: .hostShieldEnded, detail: "protected-area"))
        case .cancelled, .failed:
            onEvent?(HostGestureEvent(kind: .hostShieldCancelled, detail: "protected-area"))
        default:
            break
        }
    }
}

private final class HostBoundaryDragGestureRecognizer: UIGestureRecognizer {
    private let movementThreshold: CGFloat = 2
    private var trackingTouch: UITouch?
    private var initialLocation: CGPoint = .zero

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        guard state == .possible,
              trackingTouch == nil,
              let touch = touches.first,
              let view else {
            state = .failed
            return
        }

        trackingTouch = touch
        initialLocation = touch.location(in: view)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        guard let trackingTouch,
              touches.contains(trackingTouch),
              let view else {
            return
        }

        let location = trackingTouch.location(in: view)
        let distance = hypot(location.x - initialLocation.x, location.y - initialLocation.y)
        guard distance >= movementThreshold else {
            return
        }

        switch state {
        case .possible:
            state = .began
        case .began, .changed:
            state = .changed
        default:
            break
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        guard let trackingTouch,
              touches.contains(trackingTouch) else {
            return
        }

        switch state {
        case .began, .changed:
            state = .ended
        default:
            state = .failed
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        guard let trackingTouch,
              touches.contains(trackingTouch) else {
            return
        }

        state = .cancelled
    }

    override func reset() {
        super.reset()
        trackingTouch = nil
        initialLocation = .zero
    }

    override func canBePrevented(by preventingGestureRecognizer: UIGestureRecognizer) -> Bool {
        false
    }

    override func canPrevent(_ preventedGestureRecognizer: UIGestureRecognizer) -> Bool {
        false
    }
}
