import SwiftUI

struct LobbyInvitePlayerStrip: View {
    var isExpanded = false

    var body: some View {
        Group {
            if isExpanded {
                VStack(spacing: 0) {
                    playerRow(systemImage: "person.fill", label: "You", detail: "Host", isHost: true)
                    Divider().padding(.leading, 52)
                    playerRow(systemImage: "plus", label: "Friend", detail: "Open seat", isHost: false)
                    Divider().padding(.leading, 52)
                    playerRow(systemImage: "plus", label: "Friend", detail: "Open seat", isHost: false)
                    Divider().padding(.leading, 52)
                    playerRow(systemImage: "plus", label: "Optional", detail: "Fourth player", isHost: false)
                }
            } else {
                HStack(spacing: GameTheme.inlineSpacing) {
                    playerToken(systemImage: "person.fill", label: "You", isHost: true)
                    playerToken(systemImage: "plus", label: "Friend", isHost: false)
                    playerToken(systemImage: "plus", label: "Friend", isHost: false)
                    playerToken(systemImage: "plus", label: "Optional", isHost: false)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("You are the host. Two friends are required and one additional friend is optional.")
    }

    private func playerRow(
        systemImage: String,
        label: String,
        detail: String,
        isHost: Bool
    ) -> some View {
        HStack(spacing: GameTheme.inlineSpacing) {
            Image(systemName: systemImage)
                .font(.body.bold())
                .foregroundStyle(isHost ? GameTheme.ink : GameTheme.mutedInk)
                .frame(width: 44, height: 44)
                .background {
                    Circle()
                        .fill(isHost ? GameTheme.accent : LobbyInvitePalette.controlSurface)
                }
                .overlay {
                    Circle()
                        .stroke(
                            isHost ? GameTheme.outline : GameTheme.outline.opacity(0.26),
                            lineWidth: isHost ? 1.5 : 1
                        )
                }

            Text(label)
                .font(GameTheme.bodyFont.bold())
                .foregroundStyle(GameTheme.ink)

            Spacer(minLength: GameTheme.inlineSpacing)

            Text(detail)
                .font(GameTheme.metaFont)
                .foregroundStyle(GameTheme.mutedInk)
        }
        .frame(minHeight: 52)
    }

    private func playerToken(systemImage: String, label: String, isHost: Bool) -> some View {
        VStack(spacing: 4) {
            Image(systemName: systemImage)
                .font(.body.bold())
                .foregroundStyle(isHost ? GameTheme.ink : GameTheme.mutedInk)
                .frame(width: 44, height: 44)
                .background {
                    Circle()
                        .fill(isHost ? GameTheme.accent : LobbyInvitePalette.controlSurface)
                }
                .overlay {
                    Circle()
                        .stroke(
                            isHost ? GameTheme.outline : GameTheme.outline.opacity(0.26),
                            lineWidth: isHost ? 1.5 : 1
                        )
                }

            Text(label)
                .font(GameTheme.metaFont)
                .foregroundStyle(GameTheme.mutedInk)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
        }
        .frame(maxWidth: .infinity)
    }
}
