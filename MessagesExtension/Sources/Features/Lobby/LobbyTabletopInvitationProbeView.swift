import SwiftUI

struct LobbyTabletopInvitationProbeView: View {
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
                LobbyInvitePaperCard(fill: LobbyInvitePalette.mutedPaper) {
                    VStack(alignment: .leading, spacing: 0) {
                        LobbyInviteBrandHeader(tutorial: tutorial, games: nil)

                        Text(model.title)
                            .font(GameTheme.displayFont)
                            .foregroundStyle(GameTheme.ink)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, GameTheme.blockSpacing)
                            .accessibilityIdentifier("uls.lobby.inviteTitle")

                        LobbyInviteTabletopRoster()
                            .padding(.top, GameTheme.blockSpacing)

                        Spacer(minLength: GameTheme.blockSpacing)

                        LobbyInviteCompactSettingsButton(action: settings)
                            .padding(.bottom, GameTheme.blockSpacing)

                        Divider()
                            .overlay(GameTheme.outline.opacity(0.24))

                        VStack(alignment: .leading, spacing: GameTheme.blockSpacing) {
                            if let editor = model.nameEditor {
                                LobbyInviteNameField(
                                    editor: editor,
                                    displayName: $displayNameDraft,
                                    canSaveDisplayName: false,
                                    saveDisplayName: {}
                                )
                            }

                            if let button = model.inviteButton {
                                LobbyInvitePrimaryButton(model: button, action: invite)
                            }
                        }
                        .padding(.top, GameTheme.blockSpacing)
                    }
                }
                .padding(.horizontal, GameTheme.shellPadding)
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
        }
        .accessibilityIdentifier("uls.lobby.tableSurface")
    }
}

private struct LobbyInviteTabletopRoster: View {
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                tabletop
                    .frame(width: min(204, proxy.size.width * 0.59), height: 92)
                    .position(x: proxy.size.width / 2, y: 122)

                seat(
                    title: "You",
                    detail: "Host",
                    systemImage: "crown.fill",
                    isHost: true
                )
                .position(x: proxy.size.width / 2, y: 34)

                seat(
                    title: "Friend",
                    detail: "Open seat",
                    systemImage: "plus",
                    isHost: false
                )
                .position(x: 43, y: 122)

                seat(
                    title: "Friend",
                    detail: "Open seat",
                    systemImage: "plus",
                    isHost: false
                )
                .position(x: proxy.size.width - 43, y: 122)

                seat(
                    title: "Optional",
                    detail: "Fourth player",
                    systemImage: "plus",
                    isHost: false
                )
                .position(x: proxy.size.width / 2, y: 211)
            }
        }
        .frame(height: 252)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("uls.lobby.roster")
    }

    private var tabletop: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28)
                .fill(GameTheme.felt)
                .overlay {
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(GameTheme.outline, lineWidth: 3)
                }

            VStack(spacing: GameTheme.chipSpacing) {
                HStack(spacing: 2) {
                    LobbyHexagonShape().fill(GameTheme.wood)
                    LobbyHexagonShape().fill(GameTheme.brick)
                    LobbyHexagonShape().fill(GameTheme.wheat)
                }
                .frame(width: 64, height: 25)

                Text("Your table")
                    .font(GameTheme.chipFont)
                    .foregroundStyle(LobbyInvitePalette.mutedPaper)
            }
        }
        .accessibilityHidden(true)
    }

    private func seat(
        title: String,
        detail: String,
        systemImage: String,
        isHost: Bool
    ) -> some View {
        VStack(spacing: 2) {
            Image(systemName: systemImage)
                .font(.body.bold())
                .foregroundStyle(isHost ? GameTheme.ink : GameTheme.mutedInk)
                .frame(width: 44, height: 44)
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

            Text(detail)
                .font(.caption2)
                .foregroundStyle(GameTheme.mutedInk)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(width: 86)
        .accessibilityElement(children: .combine)
    }
}

private struct LobbyInviteCompactSettingsButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: GameTheme.inlineSpacing) {
                Image(systemName: "gearshape.fill")
                    .font(GameTheme.metaFont.bold())

                VStack(alignment: .leading, spacing: 1) {
                    Text("Game Settings")
                        .font(GameTheme.metaFont.bold())

                    Text("Standard · Balanced · 10 points")
                        .font(GameTheme.metaFont)
                        .foregroundStyle(GameTheme.mutedInk)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                }

                Spacer(minLength: GameTheme.inlineSpacing)

                Image(systemName: "chevron.right")
                    .font(GameTheme.metaFont.bold())
                    .accessibilityHidden(true)
            }
            .foregroundStyle(GameTheme.ink)
            .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
            .contentShape(Rectangle())
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(GameTheme.outline.opacity(0.24))
                    .frame(height: 1)
            }
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(GameTheme.outline.opacity(0.24))
                    .frame(height: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityHint("Shows the rules selected for this game")
        .accessibilityIdentifier("uls.lobby.gameSettings")
    }
}
