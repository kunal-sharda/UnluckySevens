import SwiftUI

struct GameTurnTopBarView: View {
    let title: String
    let subtitle: String
    let isGameInfoOpen: Bool
    let onSettingsTap: () -> Void
    let onGameInfoTap: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            topObjectButton(
                title: "Settings",
                systemImage: "gearshape.fill",
                isSelected: false,
                action: onSettingsTap
            )

            VStack(spacing: 2) {
                Text(title)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(GameTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)

                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(GameTheme.mutedInk)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(GameTheme.surface)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(GameTheme.outline.opacity(0.22), lineWidth: 1)
            }
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("uls.turn.status")

            topObjectButton(
                title: "Game information",
                systemImage: "list.clipboard.fill",
                isSelected: isGameInfoOpen,
                action: onGameInfoTap
            )
        }
        .padding(.horizontal, GameTheme.shellPadding)
    }

    private func topObjectButton(
        title: String,
        systemImage: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(title, systemImage: systemImage, action: action)
            .labelStyle(.iconOnly)
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(isSelected ? GameTheme.surface : GameTheme.ink)
            .frame(width: 44, height: 44)
            .background(
                Circle()
                    .fill(isSelected ? GameTheme.accent : GameTheme.surface)
            )
            .overlay {
                Circle()
                    .stroke(isSelected ? GameTheme.surface.opacity(0.72) : GameTheme.outline.opacity(0.24), lineWidth: isSelected ? 2 : 1)
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
