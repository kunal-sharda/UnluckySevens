#if DEBUG
import SwiftUI

struct UXTestingControlsView: View {
    @ObservedObject var viewModel: LobbyDriverViewModel
    @State private var isExpanded = false
    @AppStorage(GameTabletopLayoutStyle.uxTestingDefaultsKey)
    private var tabletopLayoutStyleRawValue = GameTabletopLayoutStyle.framedShelf.rawValue
    @AppStorage(GameBoardOceanStyle.defaultsKey)
    private var oceanStyleRawValue = GameBoardOceanStyle.flat.rawValue
    @AppStorage(LobbyInviteDirection.defaultsKey)
    private var lobbyInviteDirectionRawValue = LobbyInviteDirection.setupCard.rawValue

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
            Menu("Lobby", systemImage: "person.3.fill") {
                Button("Setup Card", systemImage: "list.number") {
                    lobbyInviteDirectionRawValue = LobbyInviteDirection.setupCard.rawValue
                    viewModel.activateCleanLobbyInviteEntry()
                }
                .accessibilityIdentifier("uls.uxLab.cleanShot.lobbyInviteSetupCard")

                Button("Invitation Card", systemImage: "envelope.fill") {
                    lobbyInviteDirectionRawValue = LobbyInviteDirection.invitationCard.rawValue
                    viewModel.activateCleanLobbyInviteEntry()
                }
                .accessibilityIdentifier("uls.uxLab.cleanShot.lobbyInviteInvitationCard")

                Button("Join", systemImage: "person.badge.plus") {
                    activateCleanFixture(
                        id: UXTestFixtures.lobbyInviteID,
                        style: .framedShelf,
                        actingAs: UXTestFixtures.alice
                    )
                }
                .accessibilityIdentifier("uls.uxLab.cleanShot.lobbyJoin")

                Button("Ready", systemImage: "checkmark.seal.fill") {
                    activateCleanFixture(
                        id: UXTestFixtures.lobbyReadyID,
                        style: .framedShelf,
                        actingAs: UXTestFixtures.host
                    )
                }
                .accessibilityIdentifier("uls.uxLab.cleanShot.lobbyReady")
            }
            .accessibilityIdentifier("uls.uxLab.lobbyStates")

            Button("Setup", systemImage: "camera.viewfinder") {
                activateCleanFixture(
                    id: UXTestFixtures.setupPlacementID,
                    style: .physicalProps
                )
            }
            .accessibilityIdentifier("uls.uxLab.cleanShot.setupPlacement")

            Button("Setup Road", systemImage: "point.bottomleft.forward.to.point.topright.scurvepath") {
                activateCleanFixture(
                    id: UXTestFixtures.setupRoadPlacementID,
                    style: .physicalProps
                )
            }
            .accessibilityIdentifier("uls.uxLab.cleanShot.setupRoadPlacement")

            Button("Setup Handoff", systemImage: "arrow.forward.to.line") {
                activateCleanFixture(
                    id: UXTestFixtures.setupHandoffID,
                    style: .physicalProps
                )
            }
            .accessibilityIdentifier("uls.uxLab.cleanShot.setupHandoff")

            Button("Start", systemImage: "dice.fill") {
                activateCleanFixture(
                    id: UXTestFixtures.turnNeedsRollID,
                    style: .physicalProps
                )
            }
            .accessibilityIdentifier("uls.uxLab.cleanShot.turnNeedsRoll")

            Button("Turn", systemImage: "play.rectangle") {
                activateCleanFixture(
                    id: UXTestFixtures.defaultFixtureID,
                    style: .physicalProps
                )
            }
            .accessibilityIdentifier("uls.uxLab.cleanShot.turnAfterRoll")

            Button("Pending", systemImage: "arrow.left.arrow.right") {
                activateCleanFixture(
                    id: UXTestFixtures.tradeOfferID,
                    style: .physicalProps,
                    actingAs: UXTestFixtures.alice
                )
            }
            .accessibilityIdentifier("uls.uxLab.cleanShot.pendingTrade")

            Divider()

            Button("Wait", systemImage: "hourglass") {
                activateCleanFixture(
                    id: UXTestFixtures.waitingOnAliceID,
                    style: .physicalProps
                )
            }
            .accessibilityIdentifier("uls.uxLab.cleanShot.notPrimary.waiting")

            Button("Offer", systemImage: "arrow.left.arrow.right") {
                activateCleanFixture(
                    id: UXTestFixtures.tradeOfferID,
                    style: .physicalProps,
                    actingAs: UXTestFixtures.host
                )
            }
            .accessibilityIdentifier("uls.uxLab.cleanShot.notPrimary.offer")

            Button("Multi Offer", systemImage: "rectangle.stack.fill") {
                activateCleanFixture(
                    id: UXTestFixtures.multiTypeTradeOfferID,
                    style: .physicalProps,
                    actingAs: UXTestFixtures.host
                )
            }
            .accessibilityIdentifier("uls.uxLab.cleanShot.notPrimary.multiOffer")

            Button("Discard Wait", systemImage: "hand.raised.fill") {
                activateCleanFixture(
                    id: UXTestFixtures.waitingOnDiscardID,
                    style: .physicalProps
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
                    title: "Setup card",
                    systemImage: "list.number",
                    accessibilityLabel: "Setup card invite direction",
                    accessibilityIdentifier: "uls.uxLab.cleanShot.lobbyInviteSetupCard"
                ) {
                    lobbyInviteDirectionRawValue = LobbyInviteDirection.setupCard.rawValue
                    viewModel.activateCleanLobbyInviteEntry()
                }

                cleanShotChipButton(
                    title: "Invitation",
                    systemImage: "envelope.fill",
                    accessibilityLabel: "Invitation card invite direction",
                    accessibilityIdentifier: "uls.uxLab.cleanShot.lobbyInviteInvitationCard"
                ) {
                    lobbyInviteDirectionRawValue = LobbyInviteDirection.invitationCard.rawValue
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
                        style: .framedShelf,
                        actingAs: UXTestFixtures.alice
                    )
                }
            }

            HStack(spacing: 8) {
                cleanShotChipButton(
                    title: "No rim",
                    systemImage: "square.dashed",
                    accessibilityLabel: "Frameless shelf comparison",
                    accessibilityIdentifier: "uls.uxLab.cleanShot.tabletopFramelessShelf"
                ) {
                    activateCleanFixture(
                        id: UXTestFixtures.defaultFixtureID,
                        style: .framelessShelf
                    )
                }

                cleanShotChipButton(
                    title: "Felt tools",
                    systemImage: "hammer.fill",
                    accessibilityLabel: "Felt tools comparison",
                    accessibilityIdentifier: "uls.uxLab.cleanShot.tabletopFeltTools"
                ) {
                    activateCleanFixture(
                        id: UXTestFixtures.defaultFixtureID,
                        style: .feltTools
                    )
                }

                cleanShotChipButton(
                    title: "Props",
                    systemImage: "shippingbox.fill",
                    accessibilityLabel: "Physical props comparison",
                    accessibilityIdentifier: "uls.uxLab.cleanShot.tabletopPhysicalProps"
                ) {
                    activateCleanFixture(
                        id: UXTestFixtures.defaultFixtureID,
                        style: .physicalProps
                    )
                }
            }

            HStack(spacing: 6) {
                Text("Ocean")
                    .font(GameTheme.metaFont)
                    .foregroundStyle(GameTheme.mutedInk)

                ForEach(
                    [GameBoardOceanStyle.shallowGlow, .verticalDepth, .edgeVignette],
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
                    systemImage: "camera.viewfinder",
                    accessibilityLabel: "Clean setup screenshot",
                    accessibilityIdentifier: "uls.uxLab.cleanShot.header.setupPlacement"
                ) {
                    activateCleanFixture(
                        id: UXTestFixtures.setupPlacementID,
                        style: .physicalProps
                    )
                }

                cleanShotButton(
                    systemImage: "play.rectangle",
                    accessibilityLabel: "Clean turn screenshot",
                    accessibilityIdentifier: "uls.uxLab.cleanShot.header.turnAfterRoll"
                ) {
                    activateCleanFixture(
                        id: UXTestFixtures.defaultFixtureID,
                        style: .framedShelf
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
        style: GameTabletopLayoutStyle,
        actingAs actorID: String? = nil
    ) {
        tabletopLayoutStyleRawValue = style.rawValue
        viewModel.activateCleanUXTestingFixture(id: id, actingAs: actorID)
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
