import SwiftUI

struct LobbyInvitePaperCard<Content: View>: View {
    let minContentHeight: CGFloat?
    let fill: Color
    @ViewBuilder let content: Content

    init(
        minContentHeight: CGFloat? = nil,
        fill: Color = GameTheme.surface,
        @ViewBuilder content: () -> Content
    ) {
        self.minContentHeight = minContentHeight
        self.fill = fill
        self.content = content()
    }

    var body: some View {
        content
            .frame(
                maxWidth: .infinity,
                minHeight: minContentHeight,
                alignment: .topLeading
            )
            .padding(GameTheme.compactPadding)
            .background {
                RoundedRectangle(cornerRadius: GameTheme.smallRadius)
                    .fill(fill)
                    .shadow(color: GameTheme.sectionShadow, radius: 4, y: 2)
            }
    }
}
