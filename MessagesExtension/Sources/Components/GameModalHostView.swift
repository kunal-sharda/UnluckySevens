import SwiftUI

struct GameModalHostView: View {
    let mode: GameMode

    var body: some View {
        if let copy = copy(for: mode) {
            VStack(alignment: .leading, spacing: GameTheme.inlineSpacing) {
                Label(copy.title, systemImage: copy.systemImage)
                    .font(GameTheme.headingFont)
                    .foregroundStyle(GameTheme.ink)

                Text(copy.message)
                    .font(GameTheme.metaFont)
                    .foregroundStyle(GameTheme.mutedInk)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(GameTheme.compactPadding)
            .background(GameTheme.surface.opacity(0.92))
            .overlay(
                RoundedRectangle(cornerRadius: GameTheme.mediumRadius)
                    .stroke(GameTheme.outline.opacity(0.14), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: GameTheme.mediumRadius))
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    private func copy(for mode: GameMode) -> (title: String, message: String, systemImage: String)? {
        switch mode {
        case .trade:
            return ("Trade Mode", "Trade composition stays lightweight in this phase. Full offer and accept UI lands in stage 12.", "arrow.left.arrow.right.circle.fill")
        case .playDevCard:
            return ("Dev Card Mode", "Card-specific flows stay deferred for now. This host is where the phase-12 dev-card sheet will land.", "sparkles.rectangle.stack.fill")
        case .discard:
            return ("Discard Required", "Discard resolution is blocking turn progress. The dedicated discard flow will land after the shell is fully in place.", "exclamationmark.triangle.fill")
        default:
            return nil
        }
    }
}
