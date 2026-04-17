import SwiftUI

struct MessagesRootView: View {
    @ObservedObject var viewModel: LobbyDriverViewModel

    var body: some View {
        ZStack {
            GameTheme.appBackground
                .ignoresSafeArea()

            switch viewModel.rootRoute {
            case .lobby:
                LobbyShellView(viewModel: viewModel)
            case .game:
                GameShellView(viewModel: viewModel)
            }
        }
        .overlay(alignment: .topLeading) {
            ActiveGamesOverlayView(viewModel: viewModel)
        }
        .overlay(alignment: .topTrailing) {
            if viewModel.shouldShowTemporaryDiagnosticsOverlay {
                TemporaryDiagnosticsOverlayView(viewModel: viewModel)
            }
        }
    }
}
