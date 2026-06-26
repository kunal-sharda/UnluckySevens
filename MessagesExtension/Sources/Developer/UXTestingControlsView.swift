#if DEBUG
import SwiftUI

struct UXTestingControlsView: View {
    @ObservedObject var viewModel: LobbyDriverViewModel
    @State private var isExpanded = false

    var body: some View {
        if viewModel.uxTestingChromeHiddenForScreenshot {
            restoreChromeButton
        } else {
            chrome
        }
    }

    private var chrome: some View {
        VStack(alignment: .trailing, spacing: 8) {
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

            if isExpanded {
                controlsPanel
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(.top, 10)
        .padding(.trailing, 10)
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
        .frame(width: 316, alignment: .leading)
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

            Button {
                viewModel.activateCleanUXTestingFixture(id: UXTestFixtures.setupPlacementID)
            } label: {
                Image(systemName: "camera.viewfinder")
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
            .accessibilityLabel("Clean setup screenshot")
            .accessibilityIdentifier("uls.uxLab.cleanShot.setupPlacement")
        }
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
