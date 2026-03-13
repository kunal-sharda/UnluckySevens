import SwiftUI

struct GameShellView: View {
    @ObservedObject var viewModel: LobbyDriverViewModel
    @State private var currentMode: GameMode = .idle

    var body: some View {
        let screenModel = viewModel.gameScreenModel
        let resolvedMode = GameModeResolver.normalized(
            currentMode: currentMode,
            availability: screenModel.modeAvailability
        )

        ScrollView {
            VStack(alignment: .leading, spacing: GameTheme.sectionSpacing) {
                GameHeaderView(model: screenModel.header)

                PlayerSummaryStripView(summaries: screenModel.opponents)

                BoardContainerView(model: selectedBoardModel(screenModel: screenModel, mode: resolvedMode))

                HandTrayView(model: screenModel.handTray)

                ActionDockView(
                    model: screenModel.actionDock,
                    selectedKind: resolvedMode.actionKind
                ) { actionKind in
                    handleActionSelection(
                        actionKind,
                        currentMode: resolvedMode,
                        availability: screenModel.modeAvailability
                    )
                }

                DebugHUDView(viewModel: viewModel)
            }
            .padding(GameTheme.shellPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .onAppear {
            synchronizeMode(with: screenModel.modeAvailability)
        }
        .onChange(of: screenModel.modeAvailability) { _, availability in
            synchronizeMode(with: availability)
        }
    }

    private func selectedBoardModel(
        screenModel: GameScreenModel,
        mode: GameMode
    ) -> GameBoardPlaceholderModel {
        guard mode != .idle else {
            return screenModel.board
        }

        return GameBoardPlaceholderModel(
            title: mode.title,
            subtitle: mode.subtitle
        )
    }

    private func handleActionSelection(
        _ actionKind: GameActionDockItem.Kind,
        currentMode: GameMode,
        availability: GameModeAvailability
    ) {
        withAnimation(GameTheme.quickAnimation) {
            self.currentMode = GameModeResolver.nextMode(
                for: actionKind,
                currentMode: currentMode,
                availability: availability
            )
        }
    }

    private func synchronizeMode(with availability: GameModeAvailability) {
        let normalizedMode = GameModeResolver.normalized(
            currentMode: currentMode,
            availability: availability
        )
        guard normalizedMode != currentMode else {
            return
        }

        currentMode = normalizedMode
    }
}
