import SwiftUI

struct ActionDockView: View {
    let model: GameActionDockModel
    let selectedKind: GameActionDockItem.Kind?
    let selectedBuildKind: GameBuildShelfItem.Kind?
    let isBuildShelfPresented: Bool
    let onSelect: (GameActionDockItem.Kind) -> Void
    let onSelectBuild: (GameBuildShelfItem.Kind) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: GameTheme.inlineSpacing) {
            if isBuildShelfPresented, !model.buildShelfItems.isEmpty {
                HStack(spacing: GameTheme.inlineSpacing) {
                    ForEach(model.buildShelfItems) { item in
                        BuildShelfButton(
                            item: item,
                            isSelected: selectedBuildKind == item.kind
                        ) {
                            guard item.isEnabled else { return }
                            withAnimation(GameTheme.quickAnimation) {
                                onSelectBuild(item.kind)
                            }
                        }
                    }
                }
            }

            HStack(spacing: GameTheme.inlineSpacing) {
                ForEach(model.primaryItems) { item in
                    ActionDockButton(item: item, isSelected: selectedKind == item.kind) {
                        guard item.isEnabled else { return }
                        withAnimation(GameTheme.quickAnimation) {
                            onSelect(item.kind)
                        }
                    }
                }
            }

            if !model.utilityItems.isEmpty {
                HStack(spacing: GameTheme.inlineSpacing) {
                    ForEach(model.utilityItems) { item in
                        SecondaryDockButton(item: item, isSelected: selectedKind == item.kind) {
                            guard item.isEnabled else { return }
                            withAnimation(GameTheme.quickAnimation) {
                                onSelect(item.kind)
                            }
                        }
                    }
                    Spacer(minLength: 0)
                }
            }
        }
    }
}

private struct ActionDockButton: View {
    let item: GameActionDockItem
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Image(systemName: item.systemImage)
                    .font(.system(size: 15, weight: .semibold))

                Text(item.title)
                    .font(GameTheme.metaFont.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.80)
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

private struct BuildShelfButton: View {
    let item: GameBuildShelfItem
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: item.systemImage)
                    .font(.system(size: 13, weight: .semibold))

                Text(item.title)
                    .font(GameTheme.metaFont.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)
            }
            .foregroundStyle(item.isEnabled ? GameTheme.ink : GameTheme.mutedInk)
            .frame(maxWidth: .infinity, minHeight: 52)
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .background(background)
            .overlay(
                RoundedRectangle(cornerRadius: GameTheme.mediumRadius)
                    .stroke(borderColor, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: GameTheme.mediumRadius))
        }
        .buttonStyle(.plain)
        .disabled(!item.isEnabled)
    }

    private var background: Color {
        if isSelected {
            return GameTheme.accent.opacity(0.18)
        }
        return GameTheme.surfaceRaised.opacity(item.isEnabled ? 0.9 : 0.72)
    }

    private var borderColor: Color {
        if isSelected {
            return GameTheme.accent.opacity(0.40)
        }
        return GameTheme.outline.opacity(0.12)
    }
}

private struct SecondaryDockButton: View {
    let item: GameActionDockItem
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: item.systemImage)
                    .font(.system(size: 13, weight: .semibold))

                Text(item.title)
                    .font(GameTheme.metaFont.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .foregroundStyle(item.isEnabled ? GameTheme.ink : GameTheme.mutedInk)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(background)
            .overlay(
                Capsule()
                    .stroke(borderColor, lineWidth: 1)
            )
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(!item.isEnabled)
    }

    private var background: Color {
        if isSelected {
            return GameTheme.accent.opacity(0.18)
        }
        return GameTheme.surface.opacity(0.84)
    }

    private var borderColor: Color {
        if isSelected {
            return GameTheme.accent.opacity(0.40)
        }
        return GameTheme.outline.opacity(0.12)
    }
}
