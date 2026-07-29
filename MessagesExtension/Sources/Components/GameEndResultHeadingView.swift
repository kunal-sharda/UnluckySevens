import SwiftUI

struct GameEndResultHeadingView: View {
    var body: some View {
        Text("Final scores")
            .font(GameTheme.headingFont)
            .foregroundStyle(GamePhysicalTurnPalette.nameTileInk)
    }
}
