import SwiftUI

struct CompactLaunchButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(GameTheme.headingFont)
            .foregroundStyle(GamePhysicalTurnPalette.nameTileInk)
            .padding(.top, 16)
            .frame(maxWidth: 340, minHeight: 96)
            .contentShape(Rectangle())
            .background {
                RoundedRectangle(cornerRadius: GameTheme.mediumRadius)
                    .fill(GamePhysicalTurnPalette.nameTileFill)
                    .shadow(
                        color: GameTheme.trayShadow,
                        radius: configuration.isPressed ? 4 : 9,
                        y: configuration.isPressed ? 2 : 5
                    )
            }
            .overlay {
                RoundedRectangle(cornerRadius: GameTheme.mediumRadius)
                    .stroke(
                        GamePhysicalTurnPalette.selectedKeyline,
                        lineWidth: 2
                    )
            }
            .scaleEffect(configuration.isPressed ? GameTheme.pressedScale : 1)
            .offset(y: configuration.isPressed ? 2 : 0)
            .animation(GameTheme.quickAnimation, value: configuration.isPressed)
    }
}
