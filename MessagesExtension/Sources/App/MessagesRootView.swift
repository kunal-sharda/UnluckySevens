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
                    onTutorialTap: showTutorial,
                    onGamesTap: showGames
                )
            case .game:
                GameShellView(
                    viewModel: viewModel,
                    onSettingsTap: showGameplaySettings,
                    onGamesTap: showGames,
                    preferences: appPreferences
                )
            }
        }
        .allowsHitTesting(utilityRoute == nil)
        .accessibilityHidden(utilityRoute != nil)
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
        .overlay {
            if utilityRoute == .games {
                GamesLibraryView(
                    viewModel: viewModel,
                    dismiss: dismissUtility
                )
                .transition(.move(edge: .leading).combined(with: .opacity))
                .zIndex(25)
            }
        }
        #if DEBUG
        .overlay(alignment: .topTrailing) {
            if utilityRoute != .tutorial {
                UXTestingControlsView(viewModel: viewModel)
                    .padding(.top, 48)
                    .zIndex(100)
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

    private func showGames() {
        utilityRoute = .games
    }

    private func dismissUtility() {
        utilityRoute = nil
    }

}
