import SwiftUI

struct LobbyInviteGameSettingsButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: GameTheme.chipSpacing) {
                HStack(spacing: GameTheme.inlineSpacing) {
                    Label("Game Settings", systemImage: "gearshape.fill")
                        .font(GameTheme.headingFont)

                    Spacer(minLength: GameTheme.inlineSpacing)

                    Image(systemName: "chevron.right")
                        .font(GameTheme.metaFont.bold())
                        .accessibilityHidden(true)
                }

                Text("Standard rules · Balanced board · 10 points")
                    .font(GameTheme.metaFont)
                    .foregroundStyle(GameTheme.mutedInk)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .foregroundStyle(GameTheme.ink)
            .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
            .padding(.horizontal, GameTheme.compactPadding)
            .padding(.vertical, GameTheme.inlineSpacing)
            .background {
                RoundedRectangle(cornerRadius: GameTheme.smallRadius)
                    .fill(LobbyInvitePalette.controlSurface)
            }
            .overlay {
                RoundedRectangle(cornerRadius: GameTheme.smallRadius)
                    .stroke(GameTheme.outline.opacity(0.32), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityHint("Shows the rules selected for this game")
        .accessibilityIdentifier("uls.lobby.gameSettings")
    }
}
