import CoreGraphics
import Foundation

struct MessagesHostLayoutSnapshot: Equatable {
    static let minimumVisualEdgeClearance: CGFloat = 12

    let boundsSize: CGSize
    let safeAreaInsets: MessagesHostInsets
    let presentationStyle: MessagesHostPresentationStyle
    let profile: MessagesHostLayoutProfile
    let revision: Int

    var usableSize: CGSize {
        CGSize(
            width: max(boundsSize.width - safeAreaInsets.leading - safeAreaInsets.trailing, 0),
            height: max(boundsSize.height - safeAreaInsets.top - safeAreaInsets.bottom, 0)
        )
    }

    var additionalBottomClearance: CGFloat {
        max(Self.minimumVisualEdgeClearance - safeAreaInsets.bottom, 0)
    }

    var diagnosticValue: String {
        [
            "bounds=\(Self.formatted(boundsSize.width))x\(Self.formatted(boundsSize.height))",
            "safe=\(Self.formatted(safeAreaInsets.top)),\(Self.formatted(safeAreaInsets.leading)),\(Self.formatted(safeAreaInsets.bottom)),\(Self.formatted(safeAreaInsets.trailing))",
            "usable=\(Self.formatted(usableSize.width))x\(Self.formatted(usableSize.height))",
            "style=\(presentationStyle.rawValue)",
            "profile=\(String(describing: profile))",
            "revision=\(revision)",
        ].joined(separator: ";")
    }

    func isEquivalentMeasurement(
        boundsSize candidateBounds: CGSize,
        safeAreaInsets candidateInsets: MessagesHostInsets,
        presentationStyle candidateStyle: MessagesHostPresentationStyle,
        tolerance: CGFloat = 1
    ) -> Bool {
        abs(boundsSize.width - candidateBounds.width) <= tolerance
            && abs(boundsSize.height - candidateBounds.height) <= tolerance
            && abs(safeAreaInsets.top - candidateInsets.top) <= tolerance
            && abs(safeAreaInsets.leading - candidateInsets.leading) <= tolerance
            && abs(safeAreaInsets.bottom - candidateInsets.bottom) <= tolerance
            && abs(safeAreaInsets.trailing - candidateInsets.trailing) <= tolerance
            && presentationStyle == candidateStyle
    }

    private static func formatted(_ value: CGFloat) -> String {
        String(format: "%.1f", Double(value))
    }
}
