import SwiftUI

struct LobbyInvitationCardProbeView: View {
    @Binding var displayNameDraft: String
    let settings: () -> Void
    let tutorial: () -> Void
    let invite: () -> Void

    var body: some View {
        ZStack {
            GameTheme.appBackground
                .ignoresSafeArea()

            GeometryReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    LobbyInvitePaperCard(
                        minContentHeight: max(0, proxy.size.height - 64),
                        fill: LobbyInvitePalette.mutedPaper
                    ) {
                        VStack(alignment: .leading, spacing: 0) {
                            LobbyInviteBrandHeader(tutorial: tutorial)

                            Divider()
                                .overlay(GameTheme.outline.opacity(0.32))
                                .padding(.top, GameTheme.blockSpacing)

                            Text("Invite Your Table")
                                .font(GameTheme.displayFont)
                                .foregroundStyle(GameTheme.ink)
                                .padding(.top, GameTheme.blockSpacing)
                                .accessibilityIdentifier("uls.lobby.inviteTitle")

                            VStack(spacing: 0) {
                                Spacer(minLength: GameTheme.blockSpacing)

                                LobbyInvitePlayerStrip(isExpanded: true)

                                LobbyInviteGameSettingsButton {
                                    settings()
                                }
                                .padding(.top, GameTheme.blockSpacing)

                                Spacer(minLength: GameTheme.blockSpacing)
                            }
                            .frame(maxHeight: .infinity)

                            Divider()
                                .overlay(GameTheme.outline.opacity(0.24))

                            VStack(alignment: .leading, spacing: GameTheme.blockSpacing) {
                                LobbyInviteNameField(displayName: $displayNameDraft)
                                LobbyInvitePrimaryButton(invite: invite)
                            }
                            .padding(.top, GameTheme.blockSpacing)
                        }
                    }
                    .padding(.horizontal, GameTheme.shellPadding)
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                }
            }
        }
    }

}
