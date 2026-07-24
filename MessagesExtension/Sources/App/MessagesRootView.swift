import SwiftUI

struct MessagesRootView: View {
    @ObservedObject var viewModel: LobbyDriverViewModel
    let onSettingsTap: () -> Void
    @State private var utilityRoute: AppUtilitySheetRoute?
    @State private var appPreferences: AppPreferences

    init(
        viewModel: LobbyDriverViewModel,
        onSettingsTap: @escaping () -> Void = {}
    ) {
        self.viewModel = viewModel
        self.onSettingsTap = onSettingsTap
        _utilityRoute = State(initialValue: nil)
        _appPreferences = State(initialValue: AppPreferences())
    }

    var body: some View {
        ZStack {
            GameTheme.appBackground
                .ignoresSafeArea()

            switch viewModel.rootRoute {
            case .lobby:
                LobbyShellView(
                    viewModel: viewModel,
                    onSettingsTap: showSettings,
                    onTutorialTap: showTutorial
                )
            case .game:
                GameShellView(
                    viewModel: viewModel,
                    onSettingsTap: showGameplaySettings,
                    preferences: appPreferences
                )
            }
        }
        .allowsHitTesting(utilityRoute != .tutorial)
        .accessibilityHidden(utilityRoute == .tutorial)
        .overlay(alignment: .topLeading) {
            if utilityRoute != .tutorial {
                ActiveGamesOverlayView(viewModel: viewModel)
            }
        }
        .overlay {
            if utilityRoute == .settings {
                AppSettingsView(
                    preferences: appPreferences,
                    summary: GameSettingsSummary(boardStrategy: viewModel.boardStrategy),
                    onDismiss: dismissUtility
                )
                .transition(.opacity)
                .zIndex(20)
            }
        }
        .overlay {
            if utilityRoute == .tutorial {
                GameTutorialView(
                    preferences: appPreferences,
                    onDismiss: dismissUtility
                )
                .transition(.opacity)
                .zIndex(30)
            }
        }
        #if DEBUG
        .overlay(alignment: .topTrailing) {
            if utilityRoute != .tutorial {
                UXTestingControlsView(viewModel: viewModel)
            }
        }
        .overlay(alignment: .topLeading) {
            Color.clear
                .frame(width: 1, height: 1)
                .accessibilityElement(children: .ignore)
                .accessibilityIdentifier("uls.settings.hookEvidence")
                .accessibilityLabel("Settings hook invocations")
                .accessibilityValue("\(viewModel.uxTestingSettingsHookInvocationCount)")
        }
        #endif
    }

    private func showSettings() {
        utilityRoute = .settings
    }

    private func showGameplaySettings() {
        onSettingsTap()
        showSettings()
    }

    private func showTutorial() {
        utilityRoute = .tutorial
    }

    private func dismissUtility() {
        utilityRoute = nil
    }

}
