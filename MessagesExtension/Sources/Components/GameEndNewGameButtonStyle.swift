import SwiftUI

struct GameEndNewGameButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(GamePhysicalTurnPalette.nameTileFill)
            .frame(minHeight: 44)
            .padding(.horizontal, GameTheme.compactPadding)
            .background(
                GamePhysicalTurnPalette.nameTileInk.opacity(
                    configuration.isPressed ? 0.78 : 1
                ),
                in: RoundedRectangle(cornerRadius: GameTheme.smallRadius)
            )
    }
}
