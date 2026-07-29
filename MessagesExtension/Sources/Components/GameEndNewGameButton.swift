import SwiftUI

struct GameEndNewGameButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label("New game", systemImage: "arrow.clockwise")
                .font(GameTheme.metaFont)
                .bold()
                .imageScale(.medium)
        }
            .buttonStyle(GameEndNewGameButtonStyle())
            .accessibilityIdentifier("uls.endScreen.newGame")
    }
}
