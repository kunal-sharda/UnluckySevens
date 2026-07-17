import SwiftUI

struct GameTurnObjectButton: View {
    let title: String
    let systemImage: String
    let isSelected: Bool
    let statusText: String?
    let accessibilityHint: String
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack(alignment: .topTrailing) {
                    RoundedRectangle(cornerRadius: 9)
                        .fill(isSelected ? GameTheme.accent.opacity(0.72) : GameTheme.surfaceRaised.opacity(0.82))
                        .frame(width: 44, height: 44)
                        .overlay {
                            RoundedRectangle(cornerRadius: 9)
                                .stroke(
                                    isSelected ? GameTheme.surface.opacity(0.72) : GameTheme.outline.opacity(0.26),
                                    lineWidth: isSelected ? 2 : 1
                                )
                        }

                    Image(systemName: systemImage)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(isSelected ? GameTheme.surface : GameTheme.ink)
                        .frame(width: 44, height: 44)

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(GameTheme.surface)
                            .background(Circle().fill(GameTheme.accent))
                            .offset(x: 4, y: -4)
                    }

                    if statusText == "Pending" {
                        Text("Pending")
                            .font(.system(size: 7, weight: .bold))
                            .foregroundStyle(GameTheme.ink)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(GameTheme.surface))
                            .overlay(Capsule().stroke(GameTheme.outline.opacity(0.28), lineWidth: 1))
                            .offset(y: 32)
                    }
                }

                Text(statusText == "Pending" ? title : (statusText ?? title))
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(GameTheme.surface.opacity(0.92))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, minHeight: 62)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .animation(accessibilityReduceMotion ? nil : GameTheme.quickAnimation, value: isSelected)
        .accessibilityLabel(title)
        .accessibilityValue(statusText == "Pending" ? "Pending offer" : "")
        .accessibilityInputLabels([title])
        .accessibilityHint(accessibilityHint)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
