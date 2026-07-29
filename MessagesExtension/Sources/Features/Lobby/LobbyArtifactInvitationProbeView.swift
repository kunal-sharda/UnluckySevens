import SwiftUI

struct LobbyArtifactInvitationProbeView: View {
    let model: LobbyScreenModel
    @Binding var displayNameDraft: String
    let settings: () -> Void
    let tutorial: () -> Void
    let invite: () -> Void

    var body: some View {
        ZStack {
            GameTheme.appBackground
                .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: GameTheme.blockSpacing) {
                    tutorialButton
                    invitationArtifact
                    playingAsRow

                    if let button = model.inviteButton {
                        LobbyInvitePrimaryButton(model: button, action: invite)
                    }
                }
                .padding(.horizontal, GameTheme.shellPadding)
                .padding(.top, GameTheme.inlineSpacing)
                .padding(.bottom, 24)
            }
        }
        .accessibilityIdentifier("uls.lobby.tableSurface")
    }

    private var tutorialButton: some View {
        HStack {
            Spacer(minLength: 0)

            Button(action: tutorial) {
                Label("Tutorial", systemImage: "book.closed.fill")
                    .font(GameTheme.metaFont.bold())
                    .foregroundStyle(LobbyInvitePalette.mutedPaper)
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint("Opens a short game tutorial")
            .accessibilityIdentifier("uls.lobby.tutorial")
        }
    }

    private var invitationArtifact: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: GameTheme.blockSpacing) {
                ZStack {
                    RoundedRectangle(cornerRadius: GameTheme.smallRadius)
                        .fill(GameTheme.felt)

                    LobbyRobberIdentityMark()
                        .padding(7)
                }
                .frame(width: 64, height: 64)
                .accessibilityHidden(true)

                Text(model.title)
                    .font(GameTheme.displayFont)
                    .foregroundStyle(GameTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("uls.lobby.inviteTitle")

                Spacer(minLength: 0)
            }

            seatRow
                .padding(.top, 24)

            Button(action: settings) {
                HStack(spacing: GameTheme.inlineSpacing) {
                    Image(systemName: "gearshape.fill")
                        .accessibilityHidden(true)

                    Text("Standard · Balanced · 10 points")
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    Spacer(minLength: GameTheme.inlineSpacing)

                    Image(systemName: "chevron.right")
                        .accessibilityHidden(true)
                }
                .font(GameTheme.metaFont)
                .foregroundStyle(GameTheme.ink)
                .frame(maxWidth: .infinity, minHeight: 48)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.top, GameTheme.blockSpacing)
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(GameTheme.outline.opacity(0.24))
                    .frame(height: 1)
            }
            .accessibilityLabel("Game Settings, Standard rules, Balanced board, 10 points")
            .accessibilityHint("Shows the rules selected for this game")
            .accessibilityIdentifier("uls.lobby.gameSettings")
        }
        .padding(GameTheme.compactPadding)
        .background {
            RoundedRectangle(cornerRadius: GameTheme.smallRadius)
                .fill(LobbyInvitePalette.mutedPaper)
        }
        .overlay {
            RoundedRectangle(cornerRadius: GameTheme.smallRadius)
                .stroke(GameTheme.accent.opacity(0.72), lineWidth: 1.5)
        }
    }

    private var seatRow: some View {
        HStack(spacing: GameTheme.inlineSpacing) {
            seat(title: "You", systemImage: "crown.fill", isHost: true)
            seat(title: "Open", systemImage: "plus", isHost: false)
            seat(title: "Open", systemImage: "plus", isHost: false)
            seat(title: "Optional", systemImage: "plus", isHost: false)
        }
        .frame(maxWidth: .infinity)
        .accessibilityIdentifier("uls.lobby.roster")
    }

    private func seat(title: String, systemImage: String, isHost: Bool) -> some View {
        VStack(spacing: GameTheme.chipSpacing) {
            Image(systemName: systemImage)
                .font(GameTheme.metaFont.bold())
                .foregroundStyle(isHost ? GameTheme.ink : GameTheme.mutedInk)
                .frame(width: 40, height: 40)
                .background {
                    Circle()
                        .fill(isHost ? GameTheme.accent : LobbyInvitePalette.controlSurface)
                }
                .overlay {
                    Circle()
                        .stroke(
                            isHost ? GameTheme.outline : GameTheme.outline.opacity(0.34),
                            lineWidth: isHost ? 1.5 : 1
                        )
                }

            Text(title)
                .font(GameTheme.chipFont)
                .foregroundStyle(GameTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(isHost ? "You, Host" : "\(title) seat")
    }

    private var playingAsRow: some View {
        HStack(spacing: GameTheme.inlineSpacing) {
            Image(systemName: "person.fill")
                .font(GameTheme.metaFont.bold())
                .foregroundStyle(LobbyInvitePalette.mutedPaper)
                .accessibilityHidden(true)

            Text("Playing as")
                .font(GameTheme.metaFont)
                .foregroundStyle(LobbyInvitePalette.mutedPaper.opacity(0.76))

            TextField(
                "Display Name",
                text: $displayNameDraft,
                prompt: Text(model.nameEditor?.placeholder ?? "Name")
                    .foregroundStyle(LobbyInvitePalette.mutedPaper.opacity(0.76))
            )
            .textInputAutocapitalization(.words)
            .disableAutocorrection(true)
            .submitLabel(.done)
            .font(GameTheme.bodyFont.bold())
            .foregroundStyle(LobbyInvitePalette.mutedPaper)
            .tint(GameTheme.accent)
            .multilineTextAlignment(.trailing)
            .accessibilityIdentifier("uls.lobby.nameField")

            Image(systemName: "pencil")
                .font(GameTheme.metaFont)
                .foregroundStyle(LobbyInvitePalette.mutedPaper.opacity(0.76))
                .accessibilityHidden(true)
        }
        .padding(.horizontal, GameTheme.compactPadding)
        .frame(minHeight: 52)
        .background {
            RoundedRectangle(cornerRadius: GameTheme.smallRadius)
                .fill(GameTheme.feltRaised)
        }
        .overlay {
            RoundedRectangle(cornerRadius: GameTheme.smallRadius)
                .stroke(LobbyInvitePalette.mutedPaper.opacity(0.24), lineWidth: 1)
        }
        .accessibilityElement(children: .contain)
    }
}
