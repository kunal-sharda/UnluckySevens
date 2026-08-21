import SwiftUI

struct LobbyInvitePrimaryButton: View {
    let model: LobbyActionButtonModel
    let isWorking: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: GameTheme.inlineSpacing) {
                if isWorking {
                    ProgressView()
                        .tint(GamePhysicalTurnPalette.primaryText)
                } else {
                    Image(systemName: model.systemImage)
                }
                Text(isWorking ? "Sending…" : model.title)
            }
            .frame(maxWidth: .infinity, minHeight: 52)
            .contentShape(Rectangle())
        }
            .font(GameTheme.headingFont)
            .foregroundStyle(GamePhysicalTurnPalette.primaryText)
            .background {
                RoundedRectangle(cornerRadius: GameTheme.smallRadius)
                    .fill(GamePhysicalTurnPalette.nameTileFill)
            }
            .overlay {
                RoundedRectangle(cornerRadius: GameTheme.smallRadius)
                    .stroke(GamePhysicalTurnPalette.selectedKeyline, lineWidth: 1.5)
            }
            .buttonStyle(LobbyInvitePrimaryButtonStyle())
            .disabled(!model.isEnabled || isWorking)
            .opacity(model.isEnabled ? 1 : 0.5)
            .accessibilityIdentifier("uls.lobby.action.\(model.title)")
    }
}

private struct LobbyInvitePrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.72 : 1)
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
    }
}
