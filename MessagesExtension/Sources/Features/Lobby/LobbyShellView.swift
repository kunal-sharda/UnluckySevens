import SwiftUI

struct LobbyShellView: View {
    @ObservedObject var viewModel: LobbyDriverViewModel
    @State private var showsRulesHelp = false

    var body: some View {
        let model = viewModel.lobbyScreenModel

        ZStack {
            GameTheme.appBackground
                .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: GameTheme.sectionSpacing) {
                    if model.showsInviteEntryHero {
                        inviteEntrySection(model: model)
                    } else {
                        GameHeaderView(
                            model: GameHeaderModel(
                                statusLine: GameShellStatusLine(
                                    title: model.title,
                                    subtitle: model.subtitle
                                ),
                                metaText: ""
                            )
                        )

                        if let warningText = model.warningText {
                            warningCard(text: warningText)
                        }

                        participantsSection(model: model)
                        actionsSection(model: model)
                        contextActions
                    }
                }
                .padding(GameTheme.shellPadding)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .sheet(isPresented: $showsRulesHelp) {
            LobbyRulesHelpSheet()
        }
    }

    private func inviteEntrySection(model: LobbyScreenModel) -> some View {
        VStack(alignment: .leading, spacing: GameTheme.blockSpacing) {
            HStack(alignment: .top) {
                inviteBadge

                Spacer()

                rulesHelpButton
            }

            Text(model.title)
                .font(.system(.title2, design: .serif).bold())
                .foregroundStyle(GameTheme.ink)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("uls.lobby.inviteTitle")

            Text(model.subtitle)
                .font(GameTheme.bodyFont)
                .foregroundStyle(GameTheme.mutedInk)
                .fixedSize(horizontal: false, vertical: true)

            inviteSetupSummary

            if let nameEditor = model.nameEditor {
                inviteNameEditor(nameEditor)
            }

            if let inviteButton = model.inviteButton {
                actionButton(inviteButton, accent: true) {
                    viewModel.inviteNewGame()
                }
            }

            Text(model.helperText)
                .font(GameTheme.metaFont)
                .foregroundStyle(GameTheme.mutedInk)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .background(GameTheme.surface.opacity(0.92))
        .overlay(
            RoundedRectangle(cornerRadius: GameTheme.largeRadius)
                .stroke(GameTheme.outline.opacity(0.14), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: GameTheme.largeRadius))
        .shadow(color: GameTheme.sectionShadow, radius: 10, x: 0, y: 3)
        .accessibilityIdentifier("uls.lobby.inviteCard")
    }

    private var inviteBadge: some View {
        HStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: GameTheme.smallRadius)
                    .fill(GameTheme.accent)
                    .frame(width: 44, height: 44)

                Image(systemName: "dice.fill")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(GameTheme.surface)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Unlucky Sevens")
                    .font(GameTheme.chipFont)
                    .foregroundStyle(GameTheme.ink)

                Text("Table invite")
                    .font(GameTheme.metaFont)
                    .foregroundStyle(GameTheme.mutedInk)
            }
        }
    }

    private var rulesHelpButton: some View {
        Button {
            showsRulesHelp = true
        } label: {
            Image(systemName: "questionmark")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(GameTheme.ink)
                .frame(width: 34, height: 34)
                .background(
                    Circle()
                        .fill(GameTheme.surfaceRaised.opacity(0.95))
                )
                .overlay(
                    Circle()
                        .stroke(GameTheme.outline.opacity(0.14), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Game rules")
        .accessibilityIdentifier("uls.lobby.rulesHelp")
    }

    private var inviteSetupSummary: some View {
        VStack(alignment: .leading, spacing: GameTheme.inlineSpacing) {
            Text("Game setup")
                .font(GameTheme.headingFont)
                .foregroundStyle(GameTheme.ink)

            VStack(spacing: GameTheme.inlineSpacing) {
                setupFact(
                    systemImage: "hexagon.fill",
                    title: "Standard board",
                    detail: "Balanced resources"
                )
                setupFact(
                    systemImage: "person.3.fill",
                    title: "3-4 players",
                    detail: "Everyone joins from Messages"
                )
                setupFact(
                    systemImage: "clock.arrow.circlepath",
                    title: "Turn-based",
                    detail: "Play when the table reaches you"
                )
            }
        }
        .padding(.vertical, 4)
    }

    private func setupFact(systemImage: String, title: String, detail: String) -> some View {
        HStack(spacing: GameTheme.inlineSpacing) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(GameTheme.accent)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(GameTheme.chipFont)
                    .foregroundStyle(GameTheme.ink)

                Text(detail)
                    .font(GameTheme.metaFont)
                    .foregroundStyle(GameTheme.mutedInk)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 2)
    }

    private func inviteNameEditor(_ model: LobbyNameEditorModel) -> some View {
        VStack(alignment: .leading, spacing: GameTheme.inlineSpacing) {
            Text(model.title)
                .font(GameTheme.headingFont)
                .foregroundStyle(GameTheme.ink)

            TextField(model.placeholder, text: $viewModel.lobbyDisplayNameDraft)
                .textInputAutocapitalization(.words)
                .disableAutocorrection(true)
                .submitLabel(.done)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: GameTheme.mediumRadius)
                        .fill(GameTheme.surfaceRaised.opacity(0.95))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: GameTheme.mediumRadius)
                        .stroke(GameTheme.outline.opacity(0.14), lineWidth: 1)
                )
                .foregroundStyle(GameTheme.ink)
                .accessibilityIdentifier("uls.lobby.nameField")

            Text(model.helperText)
                .font(GameTheme.metaFont)
                .foregroundStyle(GameTheme.mutedInk)
                .fixedSize(horizontal: false, vertical: true)
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
                    model.participantsEmptyTitle,
                    systemImage: model.participantsEmptySystemImage,
                    description: Text(model.participantsEmptyDescription)
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
            if let nameEditor = model.nameEditor {
                lobbyNameEditor(nameEditor)
            }

            if let inviteButton = model.inviteButton {
                actionButton(inviteButton, accent: false) {
                    viewModel.inviteNewGame()
                }
            }

            if let joinButton = model.joinButton {
                actionButton(joinButton, accent: true) {
                    viewModel.publishLobbyJoinState()
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

    private func lobbyNameEditor(_ model: LobbyNameEditorModel) -> some View {
        VStack(alignment: .leading, spacing: GameTheme.inlineSpacing) {
            Text(model.title)
                .font(GameTheme.headingFont)
                .foregroundStyle(GameTheme.ink)

            TextField(model.placeholder, text: $viewModel.lobbyDisplayNameDraft)
                .textInputAutocapitalization(.words)
                .disableAutocorrection(true)
                .submitLabel(.done)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: GameTheme.mediumRadius)
                        .fill(GameTheme.surfaceRaised.opacity(0.95))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: GameTheme.mediumRadius)
                        .stroke(GameTheme.outline.opacity(0.14), lineWidth: 1)
                )
                .foregroundStyle(GameTheme.ink)
                .onSubmit {
                    if viewModel.canPublishLobbyDisplayName {
                        viewModel.publishLobbyDisplayName()
                    }
                }

            if let saveButton = model.saveButton {
                actionButton(
                    LobbyActionButtonModel(
                        title: saveButton.title,
                        systemImage: saveButton.systemImage,
                        isEnabled: viewModel.canPublishLobbyDisplayName
                    ),
                    accent: false
                ) {
                    viewModel.publishLobbyDisplayName()
                }
            }

            Text(model.helperText)
                .font(GameTheme.metaFont)
                .foregroundStyle(GameTheme.mutedInk)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.bottom, 2)
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
        .accessibilityIdentifier("uls.lobby.action.\(model.title)")
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

private struct LobbyRulesHelpSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: GameTheme.blockSpacing) {
                    Text("Build roads, settlements, and cities by collecting resources from dice rolls.")
                        .font(GameTheme.bodyFont)
                        .foregroundStyle(GameTheme.ink)
                        .fixedSize(horizontal: false, vertical: true)

                    rulesRow(
                        systemImage: "dice.fill",
                        title: "Roll",
                        detail: "Dice decide which board tiles produce resources."
                    )
                    rulesRow(
                        systemImage: "arrow.left.arrow.right",
                        title: "Trade",
                        detail: "Swap resources with the table when you need a better hand."
                    )
                    rulesRow(
                        systemImage: "hammer.fill",
                        title: "Build",
                        detail: "Spend resources to expand toward ten victory points."
                    )
                    rulesRow(
                        systemImage: "figure.wave",
                        title: "Robber",
                        detail: "A seven moves the robber and can force large hands to discard."
                    )
                }
                .padding(GameTheme.shellPadding)
            }
            .background(GameTheme.appBackground.ignoresSafeArea())
            .navigationTitle("Game rules")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func rulesRow(systemImage: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: GameTheme.inlineSpacing) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(GameTheme.accent)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(GameTheme.headingFont)
                    .foregroundStyle(GameTheme.ink)

                Text(detail)
                    .font(GameTheme.metaFont)
                    .foregroundStyle(GameTheme.mutedInk)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(GameTheme.compactPadding)
        .background(GameTheme.surface.opacity(0.92))
        .clipShape(RoundedRectangle(cornerRadius: GameTheme.mediumRadius))
    }
}
