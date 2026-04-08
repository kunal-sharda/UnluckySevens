import SwiftUI

struct LobbyShellView: View {
    @ObservedObject var viewModel: LobbyDriverViewModel

    var body: some View {
        let model = viewModel.lobbyScreenModel

        ZStack {
            GameTheme.appBackground
                .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: GameTheme.sectionSpacing) {
                    GameHeaderView(
                        model: GameHeaderModel(
                            statusLine: GameShellStatusLine(
                                title: model.title,
                                subtitle: model.subtitle
                            ),
                            metaText: model.metaText
                        )
                    )

                    if let warningText = model.warningText {
                        warningCard(text: warningText)
                    }

                    participantsSection(model: model)
                    actionsSection(model: model)
                    contextActions
                }
                .padding(GameTheme.shellPadding)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    @ViewBuilder
    private func participantsSection(model: LobbyScreenModel) -> some View {
        VStack(alignment: .leading, spacing: GameTheme.inlineSpacing) {
            Text(model.participantsTitle)
                .font(GameTheme.headingFont)
                .foregroundStyle(GameTheme.ink)

            if model.participants.isEmpty {
                ContentUnavailableView(
                    "No Lobby Selected",
                    systemImage: "person.3.sequence.fill",
                    description: Text("Select an invite bubble or send a new one to open the lobby.")
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            } else {
                VStack(alignment: .leading, spacing: GameTheme.inlineSpacing) {
                    ForEach(model.participants) { participant in
                        participantRow(participant)
                    }
                }
            }
        }
        .padding(GameTheme.compactPadding)
        .background(GameTheme.surface.opacity(0.90))
        .overlay(
            RoundedRectangle(cornerRadius: GameTheme.mediumRadius)
                .stroke(GameTheme.outline.opacity(0.14), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: GameTheme.mediumRadius))
        .shadow(color: GameTheme.sectionShadow, radius: 8, x: 0, y: 2)
    }

    private func participantRow(_ participant: LobbyParticipantSummary) -> some View {
        HStack(spacing: GameTheme.inlineSpacing) {
            Circle()
                .fill(participant.isHost ? GameTheme.accent : GameTheme.outline.opacity(0.35))
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 2) {
                Text(participant.displayName)
                    .font(GameTheme.headingFont)
                    .foregroundStyle(GameTheme.ink)
                    .lineLimit(1)

                Text(participant.detailText)
                    .font(GameTheme.metaFont)
                    .foregroundStyle(GameTheme.mutedInk)
            }

            Spacer()

            if participant.isLocalActor {
                Text("You")
                    .font(GameTheme.chipFont)
                    .foregroundStyle(GameTheme.ink)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(GameTheme.surfaceRaised.opacity(0.95))
                    )
            }
        }
        .padding(.vertical, 4)
    }

    private func actionsSection(model: LobbyScreenModel) -> some View {
        VStack(alignment: .leading, spacing: GameTheme.inlineSpacing) {
            if let inviteButton = model.inviteButton {
                actionButton(inviteButton, accent: false) {
                    viewModel.inviteNewGame()
                }
            }

            if let joinButton = model.joinButton {
                actionButton(joinButton, accent: true) {
                    viewModel.sendJoinIntent()
                }
            }

            if let startButton = model.startButton {
                actionButton(startButton, accent: true) {
                    viewModel.startGame()
                }
            }

            Text(model.helperText)
                .font(GameTheme.metaFont)
                .foregroundStyle(GameTheme.mutedInk)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 4)
        }
        .padding(GameTheme.compactPadding)
        .background(GameTheme.surface.opacity(0.92))
        .overlay(
            RoundedRectangle(cornerRadius: GameTheme.mediumRadius)
                .stroke(GameTheme.outline.opacity(0.14), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: GameTheme.mediumRadius))
        .shadow(color: GameTheme.sectionShadow, radius: 8, x: 0, y: 2)
    }

    private func actionButton(
        _ model: LobbyActionButtonModel,
        accent: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(model.title, systemImage: model.systemImage)
                .font(GameTheme.headingFont)
                .foregroundStyle(accent ? GameTheme.surface : GameTheme.ink)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: GameTheme.mediumRadius)
                        .fill(accent ? GameTheme.accent : GameTheme.surfaceRaised.opacity(0.95))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: GameTheme.mediumRadius)
                        .stroke(GameTheme.outline.opacity(accent ? 0.0 : 0.14), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .opacity(model.isEnabled ? 1.0 : 0.55)
        .disabled(!model.isEnabled)
        .accessibilityHint(model.isEnabled ? "" : "Action unavailable in the current lobby state")
    }

    private var contextActions: some View {
        EmptyView()
    }

    private func warningCard(text: String) -> some View {
        HStack(alignment: .top, spacing: GameTheme.inlineSpacing) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(GameTheme.accent)

            Text(text)
                .font(GameTheme.metaFont)
                .foregroundStyle(GameTheme.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(GameTheme.compactPadding)
        .background(GameTheme.surface.opacity(0.94))
        .overlay(
            RoundedRectangle(cornerRadius: GameTheme.mediumRadius)
                .stroke(GameTheme.accent.opacity(0.22), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: GameTheme.mediumRadius))
    }
}
