import SwiftUI

struct LobbyInviteBrandHeader: View {
    let tutorial: () -> Void

    var body: some View {
        HStack(spacing: GameTheme.inlineSpacing) {
            ZStack {
                RoundedRectangle(cornerRadius: GameTheme.smallRadius)
                    .fill(GamePhysicalTurnPalette.nameTileFill)

                Image(systemName: "dice.fill")
                    .font(.title3.bold())
                    .foregroundStyle(GamePhysicalTurnPalette.selectedKeyline)
            }
            .frame(width: 44, height: 44)
            .accessibilityHidden(true)

            Text("Unlucky Sevens")
                .font(GameTheme.headingFont)
                .foregroundStyle(GameTheme.ink)

            Spacer(minLength: GameTheme.inlineSpacing)

            Button("Tutorial", systemImage: "book.closed.fill", action: tutorial)
                .font(GameTheme.metaFont.bold())
                .foregroundStyle(GameTheme.ink)
                .frame(minHeight: 44)
                .buttonStyle(.plain)
                .accessibilityHint("Opens a short game tutorial")
                .accessibilityIdentifier("uls.lobby.tutorial")
        }
    }
}
