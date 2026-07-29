import SwiftUI

struct LobbyInvitationCardView: View {
    let model: LobbyScreenModel
    @Binding var displayNameDraft: String
    let canSaveDisplayName: Bool
    let showSettings: () -> Void
    let showTutorial: () -> Void
    let showGames: (() -> Void)?
    let invite: () -> Void
    let join: () -> Void
    let saveDisplayName: () -> Void
    let start: () -> Void

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
                            LobbyInviteBrandHeader(
                                tutorial: showTutorial,
                                games: showGames
                            )

                            titleBlock
                                .padding(.top, GameTheme.blockSpacing)

                            if let warningText = model.warningText {
                                warning(text: warningText)
                                    .padding(.top, GameTheme.blockSpacing)
                            }

                            VStack(spacing: 0) {
                                Spacer(minLength: GameTheme.blockSpacing)

                                LobbyInvitePlayerStrip(model: model)

                                LobbyInviteGameSettingsButton(action: showSettings)
                                    .padding(.top, GameTheme.blockSpacing)
                                    .padding(.bottom, GameTheme.blockSpacing)

                                Spacer(minLength: GameTheme.blockSpacing)
                            }
                            .frame(maxHeight: .infinity)

                            if model.nameEditor != nil || hasPrimaryAction {
                                Divider()
                                    .overlay(GameTheme.outline.opacity(0.24))
                            }

                            VStack(alignment: .leading, spacing: GameTheme.blockSpacing) {
                                if let editor = model.nameEditor {
                                    LobbyInviteNameField(
                                        editor: editor,
                                        displayName: $displayNameDraft,
                                        canSaveDisplayName: canSaveDisplayName,
                                        saveDisplayName: saveDisplayName
                                    )
                                }

                                primaryButton

                                if !model.helperText.isEmpty {
                                    Text(model.helperText)
                                        .font(GameTheme.metaFont)
                                        .foregroundStyle(GameTheme.mutedInk)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                            .padding(.top, model.nameEditor != nil || hasPrimaryAction ? GameTheme.blockSpacing : 0)
                        }
                    }
                    .padding(.horizontal, GameTheme.shellPadding)
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                }
                .id(cardIdentity)
            }
        }
        .accessibilityIdentifier("uls.lobby.tableSurface")
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: GameTheme.chipSpacing) {
            Text(model.title)
                .font(GameTheme.displayFont)
                .foregroundStyle(GameTheme.ink)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier(
                    model.showsInviteEntryHero ? "uls.lobby.inviteTitle" : "uls.lobby.title"
                )

            if !model.subtitle.isEmpty {
                Text(model.subtitle)
                    .font(GameTheme.bodyFont)
                    .foregroundStyle(GameTheme.mutedInk)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    @ViewBuilder
    private var primaryButton: some View {
        if let button = model.joinButton {
            LobbyInvitePrimaryButton(model: button, action: join)
        } else if let button = model.startButton {
            LobbyInvitePrimaryButton(model: button, action: start)
        } else if let button = model.inviteButton {
            LobbyInvitePrimaryButton(model: button, action: invite)
        }
    }

    private var hasPrimaryAction: Bool {
        model.joinButton != nil || model.startButton != nil || model.inviteButton != nil
    }

    private var cardIdentity: String {
        let participantIDs = model.participants.map(\.id).joined(separator: ",")
        let actionTitle = model.joinButton?.title
            ?? model.startButton?.title
            ?? model.inviteButton?.title
            ?? "passive"
        return "\(model.title)|\(participantIDs)|\(actionTitle)"
    }

    private func warning(text: String) -> some View {
        Label(text, systemImage: "exclamationmark.triangle.fill")
            .font(GameTheme.metaFont)
            .foregroundStyle(GameTheme.ink)
            .fixedSize(horizontal: false, vertical: true)
            .padding(GameTheme.compactPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: GameTheme.smallRadius)
                    .fill(GameTheme.accent.opacity(0.28))
            }
            .overlay {
                RoundedRectangle(cornerRadius: GameTheme.smallRadius)
                    .stroke(GameTheme.outline.opacity(0.32), lineWidth: 1)
            }
    }
}
