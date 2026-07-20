import SwiftUI

struct LobbyInviteProgressRail: View {
    var body: some View {
        HStack(alignment: .top, spacing: GameTheme.chipSpacing) {
            LobbyInviteProgressStep(number: "1", title: "Invite", detail: "Send to chat", isCurrent: true)
            connector
            LobbyInviteProgressStep(number: "2", title: "Join", detail: "Friends enter", isCurrent: false)
            connector
            LobbyInviteProgressStep(number: "3", title: "Setup", detail: "Host begins", isCurrent: false)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Invite, friends join, then the host begins setup")
    }

    private var connector: some View {
        Rectangle()
            .fill(GameTheme.outline.opacity(0.24))
            .frame(maxWidth: .infinity, minHeight: 1, maxHeight: 1)
            .padding(.top, 14)
    }
}
