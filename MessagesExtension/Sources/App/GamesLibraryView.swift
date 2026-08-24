import SwiftUI

struct PlayerRecordView: View {
    @ObservedObject var viewModel: LobbyDriverViewModel
    let dismiss: () -> Void

    private var model: PlayerRecordModel { viewModel.playerRecordModel }

    var body: some View {
        ZStack {
            GameTheme.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                PlayerRecordHeaderView(dismiss: dismiss)

                ScrollView {
                    LazyVStack(alignment: .leading, spacing: GameTheme.blockSpacing + 6) {
                        PlayerRecordScoreSheetView(stats: model.overall.stats)
                        PlayerRecordHonorsView(
                            stats: model.overall.stats,
                            playerColorIndex: model.localPlayerColorIndex
                        )
                        PlayerRecordGroupLedgerView(model: model)

                        if model.overall.unidentifiedGameCount > 0 {
                            Text("\(model.overall.unidentifiedGameCount) older local record\(model.overall.unidentifiedGameCount == 1 ? "" : "s") cannot be included because the saved copy does not identify which player was you.")
                                .font(GameTheme.chipFont)
                                .foregroundStyle(GameTheme.surface.opacity(0.78))
                        }

                        Text("Recorded on this device")
                            .font(GameTheme.chipFont)
                            .foregroundStyle(GameTheme.surface.opacity(0.68))
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.bottom, GameTheme.blockSpacing)
                    }
                    .padding(GameTheme.shellPadding)
                }
            }
        }
        .accessibilityIdentifier("uls.playerRecord")
    }
}
