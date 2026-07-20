import SwiftUI

struct LobbyInviteProbeSurface<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        ZStack {
            GameTheme.appBackground
                .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                content
                    .padding(.horizontal, GameTheme.shellPadding)
                    .padding(.top, 16)
                    .padding(.bottom, 24)
            }
        }
    }
}
