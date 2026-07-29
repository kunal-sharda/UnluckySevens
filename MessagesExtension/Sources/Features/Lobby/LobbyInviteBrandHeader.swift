import SwiftUI

struct LobbyInviteBrandHeader: View {
    let tutorial: () -> Void
    let games: (() -> Void)?

    var body: some View {
        HStack(spacing: GameTheme.inlineSpacing) {
            ZStack {
                RoundedRectangle(cornerRadius: GameTheme.smallRadius)
                    .fill(GameTheme.felt)

                LobbyRobberIdentityMark()
                    .padding(4)
            }
            .frame(width: 44, height: 44)
            .accessibilityHidden(true)

            Spacer(minLength: GameTheme.inlineSpacing)

            if let games {
                Button(action: games) {
                    Label("Games", systemImage: "square.stack.3d.up.fill")
                        .font(GameTheme.metaFont.bold())
                        .foregroundStyle(GameTheme.ink)
                        .frame(height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .frame(minWidth: 44, minHeight: 44)
                .accessibilityHint("Opens saved active and finished games")
                .accessibilityIdentifier("uls.lobby.games")
            }

            Button(action: tutorial) {
                HStack(spacing: 5) {
                    Image(systemName: "book.closed.fill")
                    Text("Tutorial")
                }
                .font(GameTheme.metaFont.bold())
                .foregroundStyle(GameTheme.ink)
                .frame(height: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .frame(minWidth: 44)
            .frame(height: 44)
            .contentShape(Rectangle())
            .accessibilityHint("Opens a short game tutorial")
            .accessibilityIdentifier("uls.lobby.tutorial")
        }
    }
}
