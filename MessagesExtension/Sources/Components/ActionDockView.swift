import SwiftUI

struct ActionDockView: View {
    let model: GameActionDockModel
    let selectedKind: GameActionDockItem.Kind?
    let onSelect: (GameActionDockItem.Kind) -> Void

    var body: some View {
        HStack(spacing: GameTheme.inlineSpacing) {
            ForEach(model.primaryItems) { item in
                ActionDockButton(item: item, isSelected: selectedKind == item.kind) {
                    guard item.isEnabled else { return }
                    onSelect(item.kind)
                }
            }
        }
    }
}

private struct ActionDockButton: View {
    let item: GameActionDockItem
    let isSelected: Bool
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion

    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Image(systemName: item.systemImage)
                    .font(.system(size: 15, weight: .semibold))
                    .frame(height: 18)

                Text(item.title)
                    .font(GameTheme.metaFont.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .frame(maxWidth: .infinity, minHeight: 16)
            }
            .foregroundStyle(item.isEnabled ? GameTheme.ink : GameTheme.mutedInk)
            .frame(maxWidth: .infinity, minHeight: 58)
            .padding(.horizontal, 6)
            .padding(.vertical, 6)
            .background(background)
            .overlay(
                RoundedRectangle(cornerRadius: GameTheme.mediumRadius)
                    .stroke(borderColor, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: GameTheme.mediumRadius))
        }
        .buttonStyle(.plain)
        .disabled(!item.isEnabled)
        .scaleEffect(isSelected ? GameTheme.pressedScale : 1)
        .animation(accessibilityReduceMotion ? nil : GameTheme.quickAnimation, value: isSelected)
        .accessibilityHint(item.isEnabled ? "Selects \(item.title)" : "\(item.title) is not available")
    }

    private var background: Color {
        if isSelected {
            return GameTheme.accent.opacity(0.24)
        }
        return GameTheme.surface.opacity(item.isEnabled ? 0.94 : 0.72)
    }

    private var borderColor: Color {
        if isSelected {
            return GameTheme.accent.opacity(0.45)
        }
        return GameTheme.outline.opacity(0.15)
    }
}
