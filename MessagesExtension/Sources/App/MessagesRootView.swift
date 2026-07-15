import SwiftUI

struct MessagesRootView: View {
    @ObservedObject var viewModel: LobbyDriverViewModel
    let onSettingsTap: () -> Void

    init(
        viewModel: LobbyDriverViewModel,
        onSettingsTap: @escaping () -> Void = {}
    ) {
        self.viewModel = viewModel
        self.onSettingsTap = onSettingsTap
    }

    var body: some View {
        ZStack {
            GameTheme.appBackground
                .ignoresSafeArea()

            switch viewModel.rootRoute {
            case .lobby:
                LobbyShellView(viewModel: viewModel)
            case .game:
                GameShellView(
                    viewModel: viewModel,
                    onSettingsTap: onSettingsTap
                )
            }
        }
        .overlay(alignment: .topLeading) {
            ActiveGamesOverlayView(viewModel: viewModel)
        }
        #if DEBUG
        .overlay(alignment: .topTrailing) {
            UXTestingControlsView(viewModel: viewModel)
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
}
