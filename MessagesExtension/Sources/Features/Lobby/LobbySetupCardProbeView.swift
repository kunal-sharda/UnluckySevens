import SwiftUI

struct LobbySetupCardProbeView: View {
    @Binding var displayNameDraft: String
    let invite: () -> Void

    var body: some View {
        LobbyInviteProbeSurface {
            VStack(spacing: GameTheme.blockSpacing) {
                header

                LobbyInvitePaperCard {
                    VStack(alignment: .leading, spacing: GameTheme.blockSpacing) {
                        title
                        Divider().overlay(GameTheme.outline.opacity(0.24))
                        LobbyInviteProgressRail()
                        Divider().overlay(GameTheme.outline.opacity(0.24))
                        LobbyInviteNameField(
                            editor: LobbyNameEditorModel(
                                title: "Display Name",
                                placeholder: "Name",
                                helperText: "",
                                saveButton: nil
                            ),
                            displayName: $displayNameDraft,
                            canSaveDisplayName: false,
                            saveDisplayName: {}
                        )
                    }
                }

                LobbyInvitePrimaryButton(
                    model: LobbyActionButtonModel(
                        title: "Send Invite",
                        systemImage: "plus.message.fill",
                        isEnabled: true
                    ),
                    action: invite
                )

                Text("Friends join from the invite bubble. You begin setup when the table is ready.")
                    .font(GameTheme.metaFont)
                    .foregroundStyle(GamePhysicalTurnPalette.secondaryText)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var header: some View {
        HStack(spacing: GameTheme.inlineSpacing) {
            Image(systemName: "dice.fill")
                .font(.title3.bold())
                .foregroundStyle(GamePhysicalTurnPalette.selectedKeyline)
                .frame(width: 44, height: 44)
                .background {
                    RoundedRectangle(cornerRadius: 7)
                        .fill(GamePhysicalTurnPalette.nameTileFill)
                }
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text("Unlucky Sevens")
                    .font(GameTheme.headingFont)
                    .foregroundStyle(GamePhysicalTurnPalette.primaryText)
                Text("New game in this conversation")
                    .font(GameTheme.metaFont)
                    .foregroundStyle(GamePhysicalTurnPalette.secondaryText)
            }

            Spacer(minLength: 8)

            Label("3–4", systemImage: "person.2.fill")
                .font(GameTheme.metaFont.bold())
                .foregroundStyle(GamePhysicalTurnPalette.primaryText)
        }
    }

    private var title: some View {
        VStack(alignment: .leading, spacing: GameTheme.chipSpacing) {
            Text("Open a New Game")
                .font(GameTheme.displayFont)
                .foregroundStyle(GameTheme.ink)
                .accessibilityIdentifier("uls.lobby.inviteTitle")

            Text("Send one invitation, let friends join, then begin board setup.")
                .font(GameTheme.bodyFont)
                .foregroundStyle(GameTheme.mutedInk)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
