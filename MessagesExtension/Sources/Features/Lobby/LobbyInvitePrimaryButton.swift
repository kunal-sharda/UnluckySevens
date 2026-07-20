import SwiftUI

struct LobbyInvitePrimaryButton: View {
    let invite: () -> Void

    var body: some View {
        Button("Send Invite", systemImage: "paperplane.fill", action: invite)
            .font(GameTheme.headingFont)
            .foregroundStyle(GamePhysicalTurnPalette.primaryText)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background {
                RoundedRectangle(cornerRadius: GameTheme.smallRadius)
                    .fill(GamePhysicalTurnPalette.nameTileFill)
            }
            .overlay {
                RoundedRectangle(cornerRadius: GameTheme.smallRadius)
                    .stroke(GamePhysicalTurnPalette.selectedKeyline, lineWidth: 1.5)
            }
            .buttonStyle(.plain)
            .accessibilityHint("Sends a new game invitation to this Messages conversation")
            .accessibilityIdentifier("uls.lobby.action.Send Invite")
    }
}
