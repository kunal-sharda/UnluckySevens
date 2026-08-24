@_spi(MessagesHost) import MessagesExtensionSupport
import UIKit

@MainActor
final class MessagesHostResizeShield: NSObject, UIGestureRecognizerDelegate {
    private let captureRecognizer = HostBoundaryDragGestureRecognizer()
    private weak var protectedView: UIView?
    private var topExclusionHeight: CGFloat = 0
    private var linkedAncestorPans: [UIPanGestureRecognizer] = []

    override init() {
        super.init()
        captureRecognizer.delegate = self
        captureRecognizer.cancelsTouchesInView = false
        captureRecognizer.delaysTouchesBegan = false
        captureRecognizer.delaysTouchesEnded = false
        captureRecognizer.shouldPreventGesture = { [weak self] gestureRecognizer in
            MessagesHostResizeGesturePolicy.shouldPrevent(
                protectedView: self?.protectedView,
                gestureRecognizer: gestureRecognizer
            )
        }
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
}

private final class HostBoundaryDragGestureRecognizer: UIGestureRecognizer {
    private let movementThreshold: CGFloat = 2
    private var trackedTouches: [ObjectIdentifier: UITouch] = [:]
    private var initialLocations: [ObjectIdentifier: CGPoint] = [:]
    var shouldPreventGesture: ((UIGestureRecognizer) -> Bool)?

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        guard let view else {
            state = .failed
            return
        }

        switch state {
        case .possible, .began, .changed:
            for touch in touches {
                let key = ObjectIdentifier(touch)
                trackedTouches[key] = touch
                initialLocations[key] = touch.location(in: view)
            }
        default:
            state = .failed
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        guard let view else {
            return
        }

        let movedBeyondThreshold = touches.contains { touch in
            let key = ObjectIdentifier(touch)
            guard let trackedTouch = trackedTouches[key],
                  let initialLocation = initialLocations[key],
                  trackedTouch === touch else {
                return false
            }

            let location = trackedTouch.location(in: view)
            let distance = hypot(location.x - initialLocation.x, location.y - initialLocation.y)
            return distance >= movementThreshold
        }

        guard movedBeyondThreshold else {
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
        removeTrackedTouches(touches)

        guard trackedTouches.isEmpty else {
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
        removeTrackedTouches(touches)
        state = .cancelled
    }

    override func reset() {
        super.reset()
        trackedTouches.removeAll()
        initialLocations.removeAll()
    }

    private func removeTrackedTouches(_ touches: Set<UITouch>) {
        for touch in touches {
            let key = ObjectIdentifier(touch)
            trackedTouches.removeValue(forKey: key)
            initialLocations.removeValue(forKey: key)
        }
    }

    override func canBePrevented(by preventingGestureRecognizer: UIGestureRecognizer) -> Bool {
        false
    }

    override func canPrevent(_ preventedGestureRecognizer: UIGestureRecognizer) -> Bool {
        shouldPreventGesture?(preventedGestureRecognizer) ?? false
    }
}
