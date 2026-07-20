import SwiftUI

struct LobbyInviteDirectionProbeView: View {
    let direction: LobbyInviteDirection
    @Binding var displayNameDraft: String
    let tutorial: () -> Void
    let invite: () -> Void

    var body: some View {
        Group {
            switch direction {
            case .setupCard:
                LobbySetupCardProbeView(
                    displayNameDraft: $displayNameDraft,
                    invite: invite
                )
            case .invitationCard:
                LobbyInvitationCardProbeView(
                    displayNameDraft: $displayNameDraft,
                    tutorial: tutorial,
                    invite: invite
                )
            }
        }
        .accessibilityIdentifier("uls.lobby.inviteDirection.\(direction.rawValue)")
    }
}
