import SwiftUI
import ULS_CoreGame

struct LobbyCocktailTableView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let model: LobbyScreenModel
    let settingsSummary: GameSettingsSummary
    let boardStrategy: BoardGenStrategyV1
    @Binding var displayNameDraft: String
    let canSaveDisplayName: Bool
    let settings: () -> Void
    let tutorial: () -> Void
    let games: (() -> Void)?
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
                    VStack(spacing: 0) {
                        brandHeader

                        inviteTitle
                            .padding(.top, 20)
                            .padding(.bottom, 14)

                        CocktailLobbyTableScene(model: model, boardStrategy: boardStrategy)
                            .frame(
                                height: dynamicTypeSize.isAccessibilitySize
                                    ? 400
                                    : min(320, max(280, proxy.size.height * 0.40))
                            )

                        lobbyOptions

                        Spacer(minLength: 24)

                        if model.showsInviteEntryHero, model.nameEditor != nil {
                            compactEntryName
                                .frame(maxWidth: 320)
                        } else if let editor = model.nameEditor {
                            LobbyInviteNameField(
                                editor: editor,
                                displayName: $displayNameDraft,
                                canSaveDisplayName: canSaveDisplayName,
                                saveDisplayName: saveDisplayName
                            )
                            .frame(maxWidth: 320)
                        }

                        if let action = primaryAction {
                            LobbyInvitePrimaryButton(model: action.model, action: action.perform)
                                .frame(maxWidth: 320)
                                .padding(.top, GameTheme.blockSpacing)
                        }

                        if !model.helperText.isEmpty {
                            Text(model.helperText)
                                .font(GameTheme.metaFont)
                                .foregroundStyle(LobbyInvitePalette.mutedPaper.opacity(0.78))
                                .multilineTextAlignment(.center)
                                .padding(.top, GameTheme.inlineSpacing)
                        }
                    }
                    .frame(minHeight: max(0, proxy.size.height - 36), alignment: .top)
                    .padding(.horizontal, 20)
                    .padding(.top, GameTheme.inlineSpacing)
                    .padding(.bottom, 12)
                }
            }
        }
        .accessibilityIdentifier("uls.lobby.tableSurface")
    }

    private var brandHeader: some View {
        ViewThatFits(in: .horizontal) {
            brandHeaderRow

            VStack(alignment: .leading, spacing: 4) {
                brandIdentity
                gamesAction
            }
        }
    }

    private var brandHeaderRow: some View {
        HStack {
            brandIdentity
            Spacer(minLength: GameTheme.inlineSpacing)
            gamesAction
        }
    }

    private var brandIdentity: some View {
        HStack(spacing: 7) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(GameTheme.feltRaised)

                LobbyRobberIdentityMark()
                    .padding(4)
            }
            .frame(width: 32, height: 32)
            .accessibilityHidden(true)

            Text("Unlucky Sevens")
                .font(GameTheme.metaFont.bold())
                .foregroundStyle(LobbyInvitePalette.mutedPaper)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .layoutPriority(1)
    }

    @ViewBuilder
    private var gamesAction: some View {
        if let games {
            Button("Games", systemImage: "die.face.5.fill", action: games)
                .labelStyle(.iconOnly)
                .font(GameTheme.bodyFont.bold())
                .foregroundStyle(LobbyInvitePalette.mutedPaper)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
                .buttonStyle(.plain)
                .accessibilityHint("Opens saved active and finished games")
                .accessibilityIdentifier("uls.lobby.games")
        }
    }

    private var inviteTitle: some View {
        VStack(spacing: 9) {
            Text(model.showsInviteEntryHero ? "Invite Friends to Table" : model.title)
                .font(GameTheme.displayFont)
                .foregroundStyle(LobbyInvitePalette.mutedPaper)
                .multilineTextAlignment(.center)
                .accessibilityIdentifier("uls.lobby.inviteTitle")

            Rectangle()
                .fill(GameTheme.accent.opacity(0.86))
                .frame(width: 42, height: 2)
                .accessibilityHidden(true)
        }
        .frame(maxWidth: .infinity)
    }

    private var lobbyOptions: some View {
        VStack(spacing: 0) {
            gameSettingsAction

            Rectangle()
                .fill(LobbyInvitePalette.mutedPaper.opacity(0.20))
                .frame(height: 1)
                .accessibilityHidden(true)

            tutorialAction
        }
        .frame(maxWidth: 340)
    }

    private var gameSettingsAction: some View {
        Button(action: settings) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: GameTheme.inlineSpacing) {
                    Text("Game Settings")
                        .font(GameTheme.metaFont.bold())

                    Spacer(minLength: GameTheme.inlineSpacing)

                    settingsSummaryText
                    rulesChevron
                }

                HStack(spacing: GameTheme.inlineSpacing) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Game Settings")
                            .font(GameTheme.metaFont.bold())
                        settingsSummaryText
                    }

                    Spacer(minLength: GameTheme.inlineSpacing)

                    rulesChevron
                }
            }
            .foregroundStyle(LobbyInvitePalette.mutedPaper)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            "Game Settings, \(settingsSummary.rules) rules, \(settingsSummary.board) board, \(settingsSummary.victory)"
        )
        .accessibilityHint("Opens game settings")
        .accessibilityIdentifier("uls.lobby.gameSettings")
    }

    private var tutorialAction: some View {
        Button(action: tutorial) {
            HStack(spacing: GameTheme.inlineSpacing) {
                Text("Tutorial")
                Spacer(minLength: GameTheme.inlineSpacing)
                rulesChevron
            }
                .font(GameTheme.metaFont.bold())
                .foregroundStyle(LobbyInvitePalette.mutedPaper)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens a short game tutorial")
        .accessibilityIdentifier("uls.lobby.tutorial")
    }

    private var settingsSummaryText: some View {
        Text("\(settingsSummary.rules) · \(settingsSummary.board) · \(settingsSummary.victory)")
            .font(GameTheme.metaFont)
            .foregroundStyle(LobbyInvitePalette.mutedPaper.opacity(0.78))
            .lineLimit(1)
            .minimumScaleFactor(0.84)
    }

    private var rulesChevron: some View {
        Image(systemName: "chevron.right")
            .font(.caption.bold())
            .accessibilityHidden(true)
    }

    private var primaryAction: (model: LobbyActionButtonModel, perform: () -> Void)? {
        if let button = model.joinButton {
            return (button, join)
        }
        if let button = model.startButton {
            return (button, start)
        }
        if let button = model.inviteButton {
            return (button, invite)
        }
        return nil
    }

    private var compactEntryName: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Playing as")
                .font(GameTheme.metaFont.bold())
                .foregroundStyle(LobbyInvitePalette.mutedPaper)

            TextField(
                "Display Name",
                text: $displayNameDraft,
                prompt: Text(model.nameEditor?.placeholder ?? "Name")
                    .foregroundStyle(LobbyInvitePalette.mutedPaper.opacity(0.72))
            )
            .textInputAutocapitalization(.words)
            .disableAutocorrection(true)
            .submitLabel(.done)
            .font(GameTheme.bodyFont.bold())
            .foregroundStyle(LobbyInvitePalette.mutedPaper)
            .tint(GameTheme.accent)
            .frame(minHeight: 44)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(LobbyInvitePalette.mutedPaper.opacity(0.42))
                    .frame(height: 1)
            }
            .accessibilityIdentifier("uls.lobby.nameField")
        }
    }
}

private struct CocktailLobbyTableScene: View {
    let model: LobbyScreenModel
    let boardStrategy: BoardGenStrategyV1

    private var boardModel: GameBoardRenderModel {
        let topology = StandardBoardTopologyV1.standard()
        let board = StandardBoardGeneratorV1.generate(
            boardSeed: 70_707,
            rules: BoardRulesV1(strategy: boardStrategy)
        )

        return GameBoardRenderModel(
            topology: topology,
            geometry: StandardBoardTopologyV1.renderGeometry(),
            playerOrder: [],
            tiles: topology.tiles.indices.map { tileID in
                GameBoardTileRenderModel(
                    tileID: tileID,
                    resource: board.resourcesByTile[tileID],
                    number: nil,
                    hasRobber: board.robberTile == tileID
                )
            },
            ports: [],
            structures: [],
            roads: []
        )
    }

    var body: some View {
        GeometryReader { proxy in
            let tableSide = min(proxy.size.width - 104, proxy.size.height - 92)
            let center = CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2)

            ZStack {
                    CocktailTableTop(renderModel: boardModel)
                    .frame(width: tableSide, height: tableSide)
                    .position(center)

                station(slot: slots[0], orientation: .top)
                    .position(x: center.x, y: center.y - tableSide / 2 - 10)

                station(slot: slots[1], orientation: .left)
                    .position(x: center.x - tableSide / 2 - 19, y: center.y)

                station(slot: slots[2], orientation: .right)
                    .position(x: center.x + tableSide / 2 + 19, y: center.y)

                station(slot: slots[3], orientation: .bottom)
                    .position(x: center.x, y: center.y + tableSide / 2 + 10)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("uls.lobby.roster")
    }

    private func station(
        slot: CocktailLobbySlot,
        orientation: CocktailSeatOrientation
    ) -> some View {
        CocktailPlayerStation(
            title: slot.title,
            isHost: slot.isHost,
            isOptional: slot.isOptional,
            orientation: orientation
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(slot.accessibilityLabel)
    }

    private var slots: [CocktailLobbySlot] {
        if model.showsInviteEntryHero {
            return [
                CocktailLobbySlot(title: "You", isHost: true, isOptional: false, accessibilityLabel: "You, Host"),
                CocktailLobbySlot.open(title: "Open"),
                CocktailLobbySlot.open(title: "Open"),
                CocktailLobbySlot.open(title: "Optional", isOptional: true),
            ]
        }

        var result = model.participants.map { participant in
            CocktailLobbySlot(
                title: participant.isLocalActor ? "You" : participant.displayName,
                isHost: participant.isHost,
                isOptional: false,
                accessibilityLabel: [
                    participant.displayName,
                    participant.isLocalActor ? "You" : nil,
                    participant.detailText,
                ]
                .compactMap { $0 }
                .joined(separator: ", ")
            )
        }
        if model.joinButton != nil, result.count < 4 {
            result.append(
                CocktailLobbySlot(
                    title: "You",
                    isHost: false,
                    isOptional: false,
                    accessibilityLabel: "You, ready to join"
                )
            )
        }
        while result.count < 4 {
            let isOptional = result.count == 3
            result.append(
                CocktailLobbySlot.open(
                    title: isOptional ? "Optional" : "Open",
                    isOptional: isOptional
                )
            )
        }
        return Array(result.prefix(4))
    }
}

private struct CocktailLobbySlot {
    let title: String
    let isHost: Bool
    let isOptional: Bool
    let accessibilityLabel: String

    static func open(title: String, isOptional: Bool = false) -> Self {
        Self(
            title: title,
            isHost: false,
            isOptional: isOptional,
            accessibilityLabel: isOptional ? "Optional fourth seat" : "Open seat"
        )
    }
}

private struct CocktailTableTop: View {
    let renderModel: GameBoardRenderModel

    var body: some View {
        ZStack {
            CocktailTableShape(cornerCut: 0.13)
                .fill(GameTheme.outline)
                .offset(y: 6)

            CocktailTableShape(cornerCut: 0.13)
                .fill(GamePhysicalTurnPalette.nameTileFill)

            CocktailTableShape(cornerCut: 0.10)
                .fill(GameTheme.felt)
                .padding(10)

            BoardSceneView(
                renderModel: renderModel,
                overlayModel: .empty,
                interactionMode: .idle,
                bottomOcclusionHeight: 0,
                reloadToken: 0,
                onInteractionChanged: nil,
                onResizeFreezeChanged: nil,
                onFreezeRecoveryReloadRequested: nil,
                onTargetTap: nil
            )
            .allowsHitTesting(false)
            .clipShape(CocktailTableShape(cornerCut: 0.08))
            .padding(17)

            CocktailTableShape(cornerCut: 0.10)
                .stroke(GameTheme.accent.opacity(0.72), lineWidth: 1.5)
                .padding(10)
        }
        .accessibilityHidden(true)
    }
}

private enum CocktailSeatOrientation {
    case top
    case left
    case right
    case bottom
}

private struct CocktailPlayerStation: View {
    private let horizontalHeight: CGFloat = 28
    private let verticalWidth: CGFloat = 48
    let title: String
    let isHost: Bool
    let isOptional: Bool
    let orientation: CocktailSeatOrientation

    var body: some View {
        Group {
            switch orientation {
            case .top, .bottom:
                HStack(spacing: 5) {
                    indicator
                    Text(title)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .padding(.horizontal, isOptional ? 6 : 7)
                .frame(minHeight: max(26, horizontalHeight))
            case .left, .right:
                VStack(spacing: 2) {
                    indicator
                    Text(title)
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 4)
                .frame(minWidth: max(48, verticalWidth))
            }
        }
        .font(isOptional ? .caption.bold() : GameTheme.chipFont)
        .foregroundStyle(
            isHost
                ? GameTheme.ink
                : LobbyInvitePalette.mutedPaper.opacity(isOptional ? 0.82 : 1)
        )
        .background {
            CocktailTableShape(cornerCut: 0.16)
                .fill(
                    isHost
                        ? GameTheme.accent
                        : GameTheme.feltRaised.opacity(isOptional ? 0.88 : 1)
                )
        }
        .overlay {
            CocktailTableShape(cornerCut: 0.16)
                .stroke(
                    isHost
                        ? GameTheme.outline
                        : GameTheme.accent.opacity(isOptional ? 0.28 : 0.46),
                    lineWidth: 1
                )
        }
    }

    private var indicator: some View {
        Circle()
            .fill(isHost ? GameTheme.ink : LobbyInvitePalette.controlSurface)
            .frame(width: isOptional ? 8 : 10, height: isOptional ? 8 : 10)
            .overlay {
                Circle()
                    .stroke(
                        isHost ? GameTheme.ink : GameTheme.accent.opacity(isOptional ? 0.36 : 0.56),
                        lineWidth: 1
                    )
            }
            .accessibilityHidden(true)
    }
}

private struct CocktailTableShape: Shape {
    let cornerCut: CGFloat

    func path(in rect: CGRect) -> Path {
        let cut = min(rect.width, rect.height) * cornerCut
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + cut, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - cut, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + cut))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - cut))
        path.addLine(to: CGPoint(x: rect.maxX - cut, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + cut, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - cut))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + cut))
        path.closeSubpath()
        return path
    }
}
