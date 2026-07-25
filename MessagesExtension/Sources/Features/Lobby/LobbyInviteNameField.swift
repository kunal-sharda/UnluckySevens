import SwiftUI

struct LobbyInviteNameField: View {
    @Binding var displayName: String

    var body: some View {
        VStack(alignment: .leading, spacing: GameTheme.chipSpacing) {
            Label("Display Name", systemImage: "person.fill")
                .font(GameTheme.metaFont.bold())
                .foregroundStyle(GameTheme.ink)

            TextField(
                "Display Name",
                text: $displayName,
                prompt: Text("Name")
                    .foregroundStyle(GameTheme.mutedInk)
            )
                .textInputAutocapitalization(.words)
                .disableAutocorrection(true)
                .font(GameTheme.bodyFont)
                .foregroundStyle(GameTheme.ink)
                .tint(GameTheme.outline)
                .padding(.horizontal, GameTheme.compactPadding)
                .frame(minHeight: 48)
                .background {
                    RoundedRectangle(cornerRadius: GameTheme.smallRadius)
                        .fill(LobbyInvitePalette.controlSurface)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: GameTheme.smallRadius)
                        .stroke(GameTheme.outline.opacity(0.48), lineWidth: 1)
                }
                .accessibilityIdentifier("uls.lobby.nameField")
        }
    }
}
