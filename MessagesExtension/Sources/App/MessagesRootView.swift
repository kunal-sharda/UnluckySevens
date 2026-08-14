import SwiftUI

struct MessagesRootView: View {
    @ObservedObject var viewModel: LobbyDriverViewModel
    @ObservedObject var hostLayoutStore: MessagesHostLayoutStore
    let onSettingsTap: () -> Void
    @State private var utilityRoute: AppUtilitySheetRoute?
    @State private var appPreferences: AppPreferences

    init(
        viewModel: LobbyDriverViewModel,
        hostLayoutStore: MessagesHostLayoutStore,
        onSettingsTap: @escaping () -> Void = {}
    ) {
        self.viewModel = viewModel
        self.hostLayoutStore = hostLayoutStore
        self.onSettingsTap = onSettingsTap
        _utilityRoute = State(initialValue: nil)
        _appPreferences = State(initialValue: AppPreferences())
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            GameTheme.appBackground
                .ignoresSafeArea()

            if let hostLayout = hostLayoutStore.snapshot {
                ZStack {
                    switch viewModel.rootRoute {
                    case .lobby:
                        LobbyShellView(
                            viewModel: viewModel,
                            onSettingsTap: showSettings,
                            onTutorialTap: showTutorial,
                            onGamesTap: showGames
                        )
                    case .game:
                #if DEBUG
                        GameShellView(
                            viewModel: viewModel,
                            onSettingsTap: showGameplaySettings,
                            onGamesTap: showGames,
                            preferences: appPreferences,
                            initialMode: viewModel.uxTestingForcesCityTargets
                                ? .buildCity
                                : viewModel.uxTestingInitialGameMode,
                            initialRoute: viewModel.uxTestingForcesCityTargets
                                ? .build
                                : viewModel.uxTestingInitialGameRoute
                        )
                        .id("\(viewModel.gameShellResetToken)-\(viewModel.uxTestingForcesCityTargets)")
                #else
                        GameShellView(
                            viewModel: viewModel,
                            onSettingsTap: showGameplaySettings,
                            onGamesTap: showGames,
                            preferences: appPreferences
                        )
                #endif
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
                .environment(
                    \.messagesHostAdditionalBottomClearance,
                    hostLayout.additionalBottomClearance
                )
                .frame(
                    width: hostLayout.usableSize.width,
                    height: hostLayout.usableSize.height
                )
                .clipped()
                .offset(
                    x: hostLayout.safeAreaInsets.leading,
                    y: hostLayout.safeAreaInsets.top
                )

                #if DEBUG
                Color.clear
                    .frame(
                        width: hostLayout.usableSize.width,
                        height: hostLayout.usableSize.height
                    )
                    .contentShape(Rectangle())
                    .allowsHitTesting(false)
                    .accessibilityElement(children: .ignore)
                    .accessibilityIdentifier("uls.host.usableCanvas")
                    .accessibilityLabel("Messages host usable canvas")
                    .accessibilityValue(hostLayout.diagnosticValue)
                    .offset(
                        x: hostLayout.safeAreaInsets.leading,
                        y: hostLayout.safeAreaInsets.top
                    )
                #endif
            }
        }
        .ignoresSafeArea()
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
