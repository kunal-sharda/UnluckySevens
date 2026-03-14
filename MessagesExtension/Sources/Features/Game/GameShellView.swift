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

        ZStack {
            GameTheme.appBackground
                .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: GameTheme.sectionSpacing) {
                    VStack(alignment: .leading, spacing: GameTheme.inlineSpacing) {
                        HStack {
                            Spacer()
                            DebugHUDView(viewModel: viewModel)
                        }

                        GameHeaderView(model: screenModel.header)
                    }

                    BoardContainerView(
                        model: selectedBoardModel(screenModel: screenModel, mode: resolvedMode),
                        renderModel: screenModel.boardRenderModel
                    )

                    GameModalHostView(mode: resolvedMode)

                    PlayerSummaryStripView(summaries: screenModel.opponents)
                }
                .padding(GameTheme.shellPadding)
                .padding(.bottom, 196)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .safeAreaInset(edge: .bottom) {
            GameBottomTrayView(
                handTray: screenModel.handTray,
                actionDock: screenModel.actionDock,
                selectedKind: resolvedMode.actionKind
            ) { actionKind in
                handleActionSelection(
                    actionKind,
                    currentMode: resolvedMode,
                    availability: screenModel.modeAvailability
                )
            }
            .padding(.horizontal, GameTheme.shellPadding)
            .padding(.top, 8)
            .padding(.bottom, 8)
            .background(GameTheme.appBackground)
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
