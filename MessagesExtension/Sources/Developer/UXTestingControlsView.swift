#if DEBUG
import SwiftUI

struct UXTestingControlsView: View {
    @ObservedObject var viewModel: LobbyDriverViewModel
    @State private var isExpanded = true
    @AppStorage(GameBoardOceanStyle.defaultsKey)
    private var oceanStyleRawValue = GameBoardOceanStyle.flat.rawValue

    var body: some View {
        if viewModel.uxTestingChromeHiddenForScreenshot {
            restoreChromeButton
        } else {
            chrome
        }
    }

    private var chrome: some View {
        VStack(alignment: .trailing, spacing: 8) {
            HStack(spacing: 8) {
                quickStateMenu
                startTurnDevChooserButton
                toggleButton
            }

            if isExpanded {
                controlsPanel
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(.top, 10)
        .padding(.trailing, 10)
    }

    private var quickStateMenu: some View {
        Menu {
            Button("Recovery Games", systemImage: "square.stack.3d.up.fill") {
                viewModel.seedUXTestingRecoveryGames()
            }
            .accessibilityIdentifier("uls.uxLab.recoveryGames")

            Menu("Lobby", systemImage: "person.3.fill") {
                Button("Invitation", systemImage: "table.furniture.fill") {
                    viewModel.activateCleanLobbyInviteEntry()
                }
                .accessibilityIdentifier("uls.uxLab.cleanShot.lobbyInvite")

                Button("Join", systemImage: "person.badge.plus") {
                    activateCleanFixture(
                        id: UXTestFixtures.lobbyInviteID,
                        actingAs: UXTestFixtures.alice
                    )
                }
                .accessibilityIdentifier("uls.uxLab.cleanShot.lobbyJoin")

                Button("Ready", systemImage: "checkmark.seal.fill") {
                    activateCleanFixture(
                        id: UXTestFixtures.lobbyReadyID,
                        actingAs: UXTestFixtures.host
                    )
                }
                .accessibilityIdentifier("uls.uxLab.cleanShot.lobbyReady")
            }
            .accessibilityIdentifier("uls.uxLab.lobbyStates")

            Button("Discard Now", systemImage: "hand.raised.fill") {
                activateCleanFixture(
                    id: "pending-discard",
                    actingAs: UXTestFixtures.host
                )
            }
            .accessibilityIdentifier("uls.uxLab.cleanShot.pendingDiscard")

            Button("Robber Move", systemImage: "figure.fall") {
                activateCleanFixture(
                    id: "robber-move",
                    actingAs: UXTestFixtures.host
                )
            }
            .accessibilityIdentifier("uls.uxLab.cleanShot.robberMove")

            Button("Robber Victim", systemImage: "person.crop.circle.badge.questionmark") {
                activateCleanFixture(
                    id: UXTestFixtures.robberVictimID,
                    actingAs: UXTestFixtures.host
                )
            }
            .accessibilityIdentifier("uls.uxLab.cleanShot.robberVictim")

            Button("Setup", systemImage: "camera.viewfinder") {
                activateCleanFixture(
                    id: UXTestFixtures.setupPlacementID,
                )
            }
            .accessibilityIdentifier("uls.uxLab.cleanShot.setupPlacement")

            Button("Setup Road", systemImage: "point.bottomleft.forward.to.point.topright.scurvepath") {
                activateCleanFixture(
                    id: UXTestFixtures.setupRoadPlacementID,
                )
            }
            .accessibilityIdentifier("uls.uxLab.cleanShot.setupRoadPlacement")

            Button("Setup Handoff", systemImage: "arrow.forward.to.line") {
                activateCleanFixture(
                    id: UXTestFixtures.setupHandoffID,
                )
            }
            .accessibilityIdentifier("uls.uxLab.cleanShot.setupHandoff")

            Button("Pending", systemImage: "arrow.left.arrow.right") {
                activateCleanFixture(
                    id: UXTestFixtures.tradeOfferID,
                    actingAs: UXTestFixtures.alice
                )
            }
            .accessibilityIdentifier("uls.uxLab.cleanShot.pendingTrade")

            Button("Start", systemImage: "dice.fill") {
                activateCleanFixture(
                    id: UXTestFixtures.turnNeedsRollID,
                )
            }
            .accessibilityIdentifier("uls.uxLab.cleanShot.turnNeedsRoll")

            Button("Start Dev", systemImage: "rectangle.stack.fill") {
                viewModel.activateCleanUXTestingFixture(
                    id: UXTestFixtures.turnNeedsRollID,
                    initialMode: .playDevCard,
                    initialRoute: .devCards
                )
            }
            .accessibilityIdentifier("uls.uxLab.cleanShot.turnNeedsRollDevChooser.menu")

            Button("Turn", systemImage: "play.rectangle") {
                activateCleanFixture(
                    id: UXTestFixtures.defaultFixtureID,
                )
            }
            .accessibilityIdentifier("uls.uxLab.cleanShot.turnAfterRoll")

            Button("End", systemImage: "trophy.fill") {
                activateCleanFixture(
                    id: "game-over",
                )
            }
            .accessibilityIdentifier("uls.uxLab.cleanShot.gameOver")

            Divider()

            Button("Wait", systemImage: "hourglass") {
                activateCleanFixture(
                    id: UXTestFixtures.waitingOnAliceID,
                )
            }
            .accessibilityIdentifier("uls.uxLab.cleanShot.notPrimary.waiting")

            Button("Offer", systemImage: "arrow.left.arrow.right") {
                activateCleanFixture(
                    id: UXTestFixtures.tradeOfferID,
                    actingAs: UXTestFixtures.host
                )
            }
            .accessibilityIdentifier("uls.uxLab.cleanShot.notPrimary.offer")

            Button("Multi Offer", systemImage: "rectangle.stack.fill") {
                activateCleanFixture(
                    id: UXTestFixtures.multiTypeTradeOfferID,
                    actingAs: UXTestFixtures.host
                )
            }
            .accessibilityIdentifier("uls.uxLab.cleanShot.notPrimary.multiOffer")

            Button("Discard Wait", systemImage: "hand.raised.fill") {
                activateCleanFixture(
                    id: UXTestFixtures.waitingOnDiscardID,
                )
            }
            .accessibilityIdentifier("uls.uxLab.cleanShot.notPrimary.discard")

        } label: {
            Label("States", systemImage: "square.grid.2x2")
                .font(GameTheme.chipFont)
                .foregroundStyle(GameTheme.ink)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(GameTheme.surfaceRaised.opacity(0.96))
                )
                .overlay(
                    Capsule()
                        .stroke(GameTheme.outline.opacity(0.18), lineWidth: 1)
                )
        }
        .accessibilityIdentifier("uls.uxLab.quickStates")
    }

    private var startTurnDevChooserButton: some View {
        Button {
            viewModel.activateCleanUXTestingCityFixture()
        } label: {
            Image(systemName: "building.2.fill")
                .frame(width: 36, height: 36)
        }
        .buttonStyle(.bordered)
        .accessibilityLabel("City Targets")
        .accessibilityIdentifier("uls.uxLab.cleanShot.turnNeedsRollDevChooser")
    }

    private var toggleButton: some View {
        Button {
            withAnimation(.snappy(duration: 0.18)) {
                isExpanded.toggle()
            }
        } label: {
            Label(
                viewModel.uxTestingIsActive ? "UX Lab" : "Preview",
                systemImage: "testtube.2"
            )
            .font(GameTheme.chipFont)
            .foregroundStyle(GameTheme.ink)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(GameTheme.surfaceRaised.opacity(0.96))
            )
            .overlay(
                Capsule()
                    .stroke(GameTheme.outline.opacity(0.18), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("uls.uxLab.toggle")
    }

    private var restoreChromeButton: some View {
        Button {
            viewModel.restoreUXTestingChrome()
        } label: {
            Color.clear
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Show UX Lab")
        .accessibilityIdentifier("uls.uxLab.restoreChrome")
    }

    private var controlsPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            header

            HStack(spacing: 8) {
                cleanShotChipButton(
                    title: "Invitation",
                    systemImage: "table.furniture.fill",
                    accessibilityLabel: "Clean lobby invitation",
                    accessibilityIdentifier: "uls.uxLab.cleanShot.lobbyInvite"
                ) {
                    viewModel.activateCleanLobbyInviteEntry()
                }

                cleanShotChipButton(
                    title: "Join",
                    systemImage: "person.badge.plus",
                    accessibilityLabel: "Clean lobby join",
                    accessibilityIdentifier: "uls.uxLab.cleanShot.lobbyJoin"
                ) {
                    activateCleanFixture(
                        id: UXTestFixtures.lobbyInviteID,
                        actingAs: UXTestFixtures.alice
                    )
                }
            }

            HStack(spacing: 8) {
                cleanShotChipButton(
                    title: "Props",
                    systemImage: "shippingbox.fill",
                    accessibilityLabel: "Physical props comparison",
                    accessibilityIdentifier: "uls.uxLab.cleanShot.tabletopPhysicalProps"
                ) {
                    activateCleanFixture(
                        id: UXTestFixtures.defaultFixtureID,
                    )
                }
            }

            HStack(spacing: 6) {
                Text("Ocean")
                    .font(GameTheme.metaFont)
                    .foregroundStyle(GameTheme.mutedInk)

                ForEach(
                    [GameBoardOceanStyle.flat, .shallowGlow, .verticalDepth, .edgeVignette],
                    id: \.rawValue
                ) { style in
                    Button(style.shortLabel) {
                        oceanStyleRawValue = style.rawValue
                    }
                    .buttonStyle(UXTestingControlButtonStyle(accent: oceanStyleRawValue == style.rawValue))
                    .accessibilityIdentifier("uls.uxLab.oceanStyle.\(style.rawValue)")
                }
            }

            Picker("State", selection: $viewModel.uxTestingSelectedFixtureID) {
                ForEach(viewModel.uxTestingFixtures) { fixture in
                    Text(fixture.title).tag(fixture.id)
                }
            }
            .pickerStyle(.menu)
            .accessibilityIdentifier("uls.uxLab.statePicker")
            .onChange(of: viewModel.uxTestingSelectedFixtureID) { _, _ in
                guard viewModel.uxTestingIsActive else { return }
                viewModel.activateUXTestingFixture()
            }

            Picker("Actor", selection: $viewModel.uxTestingActorID) {
                ForEach(viewModel.uxTestingActorOptions, id: \.self) { actorID in
                    Text(viewModel.uxTestingDisplayName(for: actorID)).tag(actorID)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityIdentifier("uls.uxLab.actorPicker")
            .onChange(of: viewModel.uxTestingActorID) { _, _ in
                guard viewModel.uxTestingIsActive else { return }
                viewModel.refreshUXTestingActorView()
            }

            Picker("You", selection: $viewModel.uxTestingHumanActorID) {
                ForEach(viewModel.uxTestingActorOptions, id: \.self) { actorID in
                    Text(viewModel.uxTestingDisplayName(for: actorID)).tag(actorID)
                }
            }
            .pickerStyle(.menu)
            .accessibilityIdentifier("uls.uxLab.humanPicker")
            .onChange(of: viewModel.uxTestingHumanActorID) { _, _ in
                viewModel.refreshUXTestingHumanActor()
            }

            Toggle(isOn: $viewModel.uxTestingFollowsTurnOwner) {
                Label("Follow turn owner", systemImage: "arrow.triangle.2.circlepath")
                    .font(GameTheme.metaFont)
                    .foregroundStyle(GameTheme.ink)
            }
            .toggleStyle(.switch)
            .tint(GameTheme.accent)

            Toggle(isOn: $viewModel.uxTestingAutoplaysDummyTurns) {
                Label("Auto dummy turns", systemImage: "sparkles")
                    .font(GameTheme.metaFont)
                    .foregroundStyle(GameTheme.ink)
            }
            .toggleStyle(.switch)
            .tint(GameTheme.accent)
            .onChange(of: viewModel.uxTestingAutoplaysDummyTurns) { _, _ in
                viewModel.refreshUXTestingAutoplay()
            }

            Text(viewModel.uxTestingSelectedFixture.detail)
                .font(GameTheme.metaFont)
                .foregroundStyle(GameTheme.mutedInk)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                Button {
                    viewModel.activateUXTestingFixture()
                } label: {
                    Label("Load", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(UXTestingControlButtonStyle(accent: true))
                .accessibilityIdentifier("uls.uxLab.load")

                Button {
                    viewModel.exitUXTesting()
                } label: {
                    Label("Exit", systemImage: "xmark")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(UXTestingControlButtonStyle(accent: false))
                .disabled(!viewModel.uxTestingIsActive)
                .opacity(viewModel.uxTestingIsActive ? 1 : 0.55)
                .accessibilityIdentifier("uls.uxLab.exit")
            }
        }
        .padding(12)
        .frame(maxWidth: 316, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: GameTheme.mediumRadius)
                .fill(GameTheme.surface.opacity(0.98))
        )
        .overlay(
            RoundedRectangle(cornerRadius: GameTheme.mediumRadius)
                .stroke(GameTheme.outline.opacity(0.18), lineWidth: 1)
        )
        .shadow(color: GameTheme.sectionShadow, radius: 12, x: 0, y: 4)
        .accessibilityIdentifier("uls.uxLab.panel")
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "iphone.gen3")
                .foregroundStyle(GameTheme.accent)

            VStack(alignment: .leading, spacing: 2) {
                Text("Single-device UX Lab")
                    .font(GameTheme.headingFont)
                    .foregroundStyle(GameTheme.ink)

                Text(viewModel.uxTestingIsActive ? "Local fixture active" : "No Messages send")
                    .font(GameTheme.metaFont)
                    .foregroundStyle(GameTheme.mutedInk)
            }

            Spacer(minLength: 0)

            HStack(spacing: 6) {
                cleanShotButton(
                    systemImage: "square.stack.3d.up.fill",
                    accessibilityLabel: "Recovery Games",
                    accessibilityIdentifier: "uls.uxLab.recoveryGames.direct"
                ) {
                    viewModel.seedUXTestingRecoveryGames(hideChrome: true)
                }

                cleanShotButton(
                    systemImage: "hand.raised.fill",
                    accessibilityLabel: "Clean actionable discard",
                    accessibilityIdentifier: "uls.uxLab.cleanShot.pendingDiscard.direct"
                ) {
                    activateCleanFixture(
                        id: "pending-discard",
                        actingAs: UXTestFixtures.host
                    )
                }

                cleanShotButton(
                    systemImage: "play.rectangle",
                    accessibilityLabel: "Clean turn screenshot",
                    accessibilityIdentifier: "uls.uxLab.cleanShot.header.turnAfterRoll"
                ) {
                    activateCleanFixture(
                        id: UXTestFixtures.defaultFixtureID,
                    )
                }

            }
        }
    }

    private func cleanShotButton(
        systemImage: String,
        accessibilityLabel: String,
        accessibilityIdentifier: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .semibold))
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
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityIdentifier(accessibilityIdentifier)
    }

    private func cleanShotChipButton(
        title: String,
        systemImage: String,
        accessibilityLabel: String,
        accessibilityIdentifier: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(GameTheme.chipFont)
                .foregroundStyle(GameTheme.ink)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(GameTheme.surfaceRaised.opacity(0.96))
                )
                .overlay(
                    Capsule()
                        .stroke(GameTheme.outline.opacity(0.18), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityIdentifier(accessibilityIdentifier)
    }

    private func activateCleanFixture(
        id: String,
        actingAs actorID: String? = nil,
        initialMode: GameMode = .idle,
        initialRoute: GameShellRoute = .none
    ) {
        viewModel.activateCleanUXTestingFixture(
            id: id,
            actingAs: actorID,
            initialMode: initialMode,
            initialRoute: initialRoute
        )
    }

}

private struct UXTestingControlButtonStyle: ButtonStyle {
    let accent: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(GameTheme.chipFont)
            .foregroundStyle(accent ? GameTheme.surface : GameTheme.ink)
            .padding(.vertical, 10)
            .padding(.horizontal, 10)
            .background(
                RoundedRectangle(cornerRadius: GameTheme.smallRadius)
                    .fill(accent ? GameTheme.accent : GameTheme.surfaceRaised.opacity(0.95))
            )
            .overlay(
                RoundedRectangle(cornerRadius: GameTheme.smallRadius)
                    .stroke(GameTheme.outline.opacity(accent ? 0 : 0.14), lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.76 : 1)
    }
}
#endif
