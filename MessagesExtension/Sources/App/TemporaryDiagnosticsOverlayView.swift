import SwiftUI

struct TemporaryDiagnosticsOverlayView: View {
    @ObservedObject var viewModel: LobbyDriverViewModel

    var body: some View {
        VStack(alignment: .trailing, spacing: 8) {
            TransportBadgeChip(model: viewModel.transportBadgeModel)
                .allowsHitTesting(false)

            if viewModel.rootRoute == .game {
                Button("Reload Board") {
                    viewModel.requestBoardReload()
                }
                .font(GameTheme.metaFont.weight(.semibold))
                .foregroundStyle(GameTheme.surface)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(GameTheme.ink.opacity(0.86))
                )
                .overlay(
                    Capsule()
                        .stroke(GameTheme.surface.opacity(0.18), lineWidth: 1)
                )
            }

            if viewModel.shouldShowDebugHUD {
                DebugHUDView(viewModel: viewModel)
            }
        }
        .padding(.top, 8)
        .padding(.horizontal, 12)
    }
}

private struct TransportBadgeChip: View {
    let model: TransportBadgeModel

    var body: some View {
        Text(model.text)
            .font(GameTheme.metaFont.weight(.semibold))
            .foregroundStyle(GameTheme.surface)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(model.tone.fillColor)
            )
            .overlay(
                Capsule()
                    .stroke(GameTheme.surface.opacity(0.18), lineWidth: 1)
            )
    }
}
