import SwiftUI

struct LobbyShellView: View {
    @ObservedObject var viewModel: LobbyDriverViewModel
    @State private var showsRulesHelp = false

    var body: some View {
        let model = viewModel.lobbyScreenModel

        ZStack {
            background(for: model)
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

    @ViewBuilder
    private func background(for model: LobbyScreenModel) -> some View {
        if model.showsInviteEntryHero {
            LinearGradient(
                colors: [
                    InvitePalette.feltTop,
                    InvitePalette.feltBottom,
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .overlay(alignment: .topTrailing) {
                HexagonCluster()
                    .foregroundStyle(InvitePalette.moss.opacity(0.16))
                    .frame(width: 168, height: 136)
                    .padding(.top, 18)
                    .padding(.trailing, -24)
            }
        } else {
            GameTheme.appBackground
        }
    }

    private func inviteEntrySection(model: LobbyScreenModel) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                inviteBadge

                #if DEBUG
                rulesHelpButton

                Spacer()
                #else
                Spacer()

                rulesHelpButton
                #endif
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(model.title)
                    .font(GameTheme.displayFont)
                    .foregroundStyle(InvitePalette.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("uls.lobby.inviteTitle")

                Text(model.subtitle)
                    .font(GameTheme.bodyFont)
                    .foregroundStyle(InvitePalette.mutedInk)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, 2)

            inviteSetupSummary

            if let nameEditor = model.nameEditor {
                inviteNameEditor(nameEditor)
            }

            if let inviteButton = model.inviteButton {
                inviteActionButton(inviteButton) {
                    viewModel.inviteNewGame()
                }
            }

            Text(model.helperText)
                .font(GameTheme.metaFont)
                .foregroundStyle(InvitePalette.mutedInk)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .background(InvitePalette.paper)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(InvitePalette.paperEdge, lineWidth: 1)
        )
        .overlay(alignment: .topLeading) {
            Rectangle()
                .fill(InvitePalette.clay)
                .frame(width: 54, height: 3)
                .padding(.leading, 18)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: InvitePalette.cardShadow, radius: 18, x: 0, y: 10)
        .accessibilityIdentifier("uls.lobby.inviteCard")
    }

    private var inviteBadge: some View {
        HStack(spacing: 8) {
            InviteTableMark()
                .frame(width: 42, height: 42)

            VStack(alignment: .leading, spacing: 2) {
                Text("Unlucky Sevens")
                    .font(GameTheme.chipFont)
                    .foregroundStyle(InvitePalette.ink)

                Text("Messages table invite")
                    .font(GameTheme.metaFont)
                    .foregroundStyle(InvitePalette.mutedInk)
            }
        }
    }

    private var rulesHelpButton: some View {
        Button {
            showsRulesHelp = true
        } label: {
            Image(systemName: "questionmark")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(InvitePalette.ink)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(InvitePalette.paperRaised)
                )
                .overlay(
                    Circle()
                        .stroke(InvitePalette.paperEdge, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Game rules")
        .accessibilityIdentifier("uls.lobby.rulesHelp")
    }

    private var inviteSetupSummary: some View {
        HStack(spacing: 6) {
            setupChip(tint: InvitePalette.moss, title: "Standard", detail: "board")
            setupChip(tint: InvitePalette.slate, title: "3-4", detail: "players")
            setupChip(tint: InvitePalette.clay, title: "Async", detail: "turns")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 2)
    }

    private func setupChip(tint: Color, title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            InviteHexagonShape()
                .fill(tint)
                .frame(width: 13, height: 12)

            Text(title)
                .font(GameTheme.chipFont)
                .foregroundStyle(InvitePalette.ink)
                .lineLimit(1)

            Text(detail)
                .font(.caption2)
                .foregroundStyle(InvitePalette.mutedInk)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .background(InvitePalette.paperRaised)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(InvitePalette.paperEdge, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func inviteNameEditor(_ model: LobbyNameEditorModel) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(model.title)
                .font(GameTheme.chipFont)
                .foregroundStyle(InvitePalette.mutedInk)
                .textCase(.uppercase)

            TextField(model.placeholder, text: $viewModel.lobbyDisplayNameDraft)
                .textInputAutocapitalization(.words)
                .disableAutocorrection(true)
                .submitLabel(.done)
                .font(GameTheme.bodyFont.weight(.semibold))
                .padding(.vertical, 8)
                .overlay(
                    Rectangle()
                        .fill(InvitePalette.paperEdge)
                        .frame(height: 1),
                    alignment: .bottom
                )
                .foregroundStyle(InvitePalette.ink)
                .accessibilityIdentifier("uls.lobby.nameField")

            Text(model.helperText)
                .font(.caption)
                .foregroundStyle(InvitePalette.mutedInk)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func inviteActionButton(
        _ model: LobbyActionButtonModel,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(model.title, systemImage: model.systemImage)
                .font(GameTheme.headingFont)
                .foregroundStyle(InvitePalette.paper)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(InvitePalette.clay)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .opacity(model.isEnabled ? 1.0 : 0.55)
        .disabled(!model.isEnabled)
        .accessibilityHint(model.isEnabled ? "" : "Action unavailable in the current lobby state")
        .accessibilityIdentifier("uls.lobby.action.\(model.title)")
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

private enum InvitePalette {
    static let feltTop = Color(red: 0.18, green: 0.30, blue: 0.25)
    static let feltBottom = Color(red: 0.10, green: 0.20, blue: 0.18)
    static let paper = Color(red: 0.98, green: 0.95, blue: 0.88)
    static let paperRaised = Color(red: 0.94, green: 0.89, blue: 0.79)
    static let paperEdge = Color(red: 0.72, green: 0.64, blue: 0.52).opacity(0.58)
    static let ink = Color(red: 0.16, green: 0.12, blue: 0.09)
    static let mutedInk = Color(red: 0.39, green: 0.32, blue: 0.25)
    static let clay = Color(red: 0.66, green: 0.32, blue: 0.18)
    static let moss = Color(red: 0.36, green: 0.46, blue: 0.31)
    static let slate = Color(red: 0.22, green: 0.39, blue: 0.42)
    static let cardShadow = Color.black.opacity(0.24)
}

private struct InviteTableMark: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 7)
                .fill(InvitePalette.clay)

            HStack(spacing: 3) {
                InviteHexagonShape()
                    .fill(InvitePalette.paper)
                InviteHexagonShape()
                    .fill(InvitePalette.paper.opacity(0.84))
            }
            .frame(width: 24, height: 15)
            .offset(y: -5)

            DicePips()
                .stroke(InvitePalette.paper, lineWidth: 2)
                .frame(width: 20, height: 18)
                .offset(y: 8)
        }
    }
}

private struct DicePips: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let radius = min(rect.width, rect.height) * 0.09
        let points = [
            CGPoint(x: rect.minX + rect.width * 0.24, y: rect.minY + rect.height * 0.26),
            CGPoint(x: rect.midX, y: rect.midY),
            CGPoint(x: rect.minX + rect.width * 0.76, y: rect.minY + rect.height * 0.74),
        ]

        for point in points {
            path.addEllipse(in: CGRect(
                x: point.x - radius,
                y: point.y - radius,
                width: radius * 2,
                height: radius * 2
            ))
        }

        return path
    }
}

private struct HexagonCluster: View {
    var body: some View {
        VStack(spacing: -2) {
            HStack(spacing: 4) {
                hex
                hex
            }
            HStack(spacing: 4) {
                hex
                hex
                hex
            }
            HStack(spacing: 4) {
                hex
                hex
            }
        }
    }

    private var hex: some View {
        InviteHexagonShape()
            .frame(width: 44, height: 38)
    }
}

private struct InviteHexagonShape: Shape {
    func path(in rect: CGRect) -> Path {
        let width = rect.width
        let height = rect.height
        let x = rect.minX
        let y = rect.minY

        var path = Path()
        path.move(to: CGPoint(x: x + width * 0.50, y: y))
        path.addLine(to: CGPoint(x: x + width, y: y + height * 0.25))
        path.addLine(to: CGPoint(x: x + width, y: y + height * 0.75))
        path.addLine(to: CGPoint(x: x + width * 0.50, y: y + height))
        path.addLine(to: CGPoint(x: x, y: y + height * 0.75))
        path.addLine(to: CGPoint(x: x, y: y + height * 0.25))
        path.closeSubpath()
        return path
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
                .font(.system(size: 16, weight: .bold))
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
