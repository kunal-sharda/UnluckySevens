import Foundation
import UIKit

struct HostGestureRecognizerSnapshot: Equatable {
    let recognizerClass: String
    let delegateClass: String
    let cancelsTouchesInView: Bool
    let delaysTouchesBegan: Bool
    let delaysTouchesEnded: Bool

    var summaryLine: String {
        "\(recognizerClass) delegate=\(delegateClass) cancel=\(cancelsTouchesInView) beginDelay=\(delaysTouchesBegan) endDelay=\(delaysTouchesEnded)"
    }
}

struct HostGestureViewSnapshot: Equatable {
    let viewClass: String
    let frameDescription: String
    let isUserInteractionEnabled: Bool
    let recognizers: [HostGestureRecognizerSnapshot]

    var summaryLine: String {
        "\(viewClass) frame=\(frameDescription) interactive=\(isUserInteractionEnabled) recognizers=\(recognizers.count)"
    }
}

struct HostGestureHierarchySnapshot: Equatable {
    let views: [HostGestureViewSnapshot]

    static let empty = HostGestureHierarchySnapshot(views: [])

    static func capture(from rootView: UIView) -> HostGestureHierarchySnapshot {
        var snapshots: [HostGestureViewSnapshot] = []
        var currentView: UIView? = rootView

        while let view = currentView {
            let recognizers = (view.gestureRecognizers ?? []).map { recognizer in
                HostGestureRecognizerSnapshot(
                    recognizerClass: String(describing: type(of: recognizer)),
                    delegateClass: recognizer.delegate.map { String(describing: type(of: $0)) } ?? "-",
                    cancelsTouchesInView: recognizer.cancelsTouchesInView,
                    delaysTouchesBegan: recognizer.delaysTouchesBegan,
                    delaysTouchesEnded: recognizer.delaysTouchesEnded
                )
            }

            snapshots.append(
                HostGestureViewSnapshot(
                    viewClass: String(describing: type(of: view)),
                    frameDescription: describe(frame: view.frame),
                    isUserInteractionEnabled: view.isUserInteractionEnabled,
                    recognizers: recognizers
                )
            )

            currentView = view.superview
        }

        return HostGestureHierarchySnapshot(views: snapshots)
    }

    var summaryLines: [String] {
        views.enumerated().flatMap { index, snapshot in
            [
                "[\(index)] \(snapshot.summaryLine)",
            ] + snapshot.recognizers.map { "  - \($0.summaryLine)" }
        }
    }

    private static func describe(frame: CGRect) -> String {
        let originX = Int(frame.origin.x.rounded())
        let originY = Int(frame.origin.y.rounded())
        let width = Int(frame.size.width.rounded())
        let height = Int(frame.size.height.rounded())
        return "{{\(originX),\(originY)},{\(width),\(height)}}"
    }
}

struct HostGestureEvent: Equatable, Identifiable {
    enum Kind: String, Equatable {
        case boardPanBegan = "boardPan.began"
        case boardPanEnded = "boardPan.ended"
        case boardPinchBegan = "boardPinch.began"
        case boardPinchEnded = "boardPinch.ended"
        case boardTap = "boardTap"
        case boardSurfaceReloaded = "boardSurface.reloaded"
        case resizeFreezeBegan = "resizeFreeze.began"
        case resizeFreezeEnded = "resizeFreeze.ended"
        case hostShieldBegan = "hostShield.began"
        case hostShieldEnded = "hostShield.ended"
        case hostShieldCancelled = "hostShield.cancelled"
    }

    let id: UUID
    let kind: Kind
    let detail: String

    init(kind: Kind, detail: String) {
        self.id = UUID()
        self.kind = kind
        self.detail = detail
    }

    var summaryLine: String {
        detail.isEmpty ? kind.rawValue : "\(kind.rawValue) \(detail)"
    }
}

struct BoardInteractionDiagnosticsSnapshot: Equatable {
    let isBoardInteracting: Bool
    let isResizeFrozen: Bool
    let viewportSize: CGSize?
    let largestSettledViewportSize: CGSize?

    static let empty = BoardInteractionDiagnosticsSnapshot(
        isBoardInteracting: false,
        isResizeFrozen: false,
        viewportSize: nil,
        largestSettledViewportSize: nil
    )

    var summaryLines: [String] {
        [
            "boardInteracting=\(isBoardInteracting)",
            "resizeFrozen=\(isResizeFrozen)",
            "viewport=\(describe(size: viewportSize))",
            "largestSettled=\(describe(size: largestSettledViewportSize))",
        ]
    }

    private func describe(size: CGSize?) -> String {
        guard let size else {
            return "-"
        }

        return "\(Int(size.width.rounded()))x\(Int(size.height.rounded()))"
    }
}
