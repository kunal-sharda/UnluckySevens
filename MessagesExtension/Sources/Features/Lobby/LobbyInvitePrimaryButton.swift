import SwiftUI

struct LobbyInvitePrimaryButton: View {
    let model: LobbyActionButtonModel
    let action: () -> Void

    var body: some View {
        Button(model.title, systemImage: model.systemImage, action: action)
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
            .disabled(!model.isEnabled)
            .opacity(model.isEnabled ? 1 : 0.5)
            .accessibilityIdentifier("uls.lobby.action.\(model.title)")
    }
}
