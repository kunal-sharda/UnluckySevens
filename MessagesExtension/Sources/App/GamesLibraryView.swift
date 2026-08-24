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
                    LazyVStack(alignment: .leading, spacing: GameTheme.blockSpacing * 2) {
                        PlayerRecordScoreSheetView(stats: model.overall.stats)
                        PlayerRecordHonorsView(
                            stats: model.overall.stats,
                            playerColorIndex: model.localPlayerColorIndex
                        )
                        PlayerRecordGroupLedgerView(model: model)

                        if model.overall.unidentifiedGameCount > 0 {
                            Text("\(model.overall.unidentifiedGameCount) earlier game\(model.overall.unidentifiedGameCount == 1 ? "" : "s") can’t be counted because \(model.overall.unidentifiedGameCount == 1 ? "it doesn’t" : "they don’t") identify you.")
                                .font(GameTheme.chipFont)
                                .foregroundStyle(GameTheme.surface.opacity(0.78))
                                .frame(maxWidth: .infinity, alignment: .center)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(GameTheme.shellPadding)
                }
            }
        }
        .accessibilityIdentifier("uls.playerRecord")
    }
}
