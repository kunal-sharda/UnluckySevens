import SwiftUI

struct LobbyInviteProgressStep: View {
    let number: String
    let title: String
    let detail: String
    let isCurrent: Bool

    var body: some View {
        VStack(spacing: 4) {
            Text(number)
                .font(GameTheme.metaFont.bold())
                .foregroundStyle(GameTheme.ink)
                .frame(width: 28, height: 28)
                .background {
                    Circle()
                        .fill(isCurrent ? GameTheme.accent : GameTheme.surfaceRaised.opacity(0.46))
                }
                .overlay {
                    Circle()
                        .stroke(
                            isCurrent ? GameTheme.outline : GameTheme.outline.opacity(0.24),
                            lineWidth: 1
                        )
                }

            Text(title)
                .font(GameTheme.metaFont.bold())
                .foregroundStyle(GameTheme.ink)
            Text(detail)
                .font(GameTheme.metaFont)
                .foregroundStyle(GameTheme.mutedInk)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .frame(width: 78)
    }
}
