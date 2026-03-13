import SwiftUI

struct GameShellView: View {
    @ObservedObject var viewModel: LobbyDriverViewModel
    @State private var selectedActionKind: GameActionDockItem.Kind?

    var body: some View {
        let screenModel = viewModel.gameScreenModel

        ScrollView {
            VStack(alignment: .leading, spacing: GameTheme.sectionSpacing) {
                GameHeaderView(model: screenModel.header)

                PlayerSummaryStripView(summaries: screenModel.opponents)

                BoardContainerView(model: selectedBoardModel(screenModel: screenModel))

                HandTrayView(model: screenModel.handTray)

                ActionDockView(
                    model: screenModel.actionDock,
                    selectedKind: $selectedActionKind
                )

                DebugHUDView(viewModel: viewModel)
            }
            .padding(GameTheme.shellPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func selectedBoardModel(screenModel: GameScreenModel) -> GameBoardPlaceholderModel {
        guard let selectedActionKind else {
            return screenModel.board
        }

        let actionTitle = actionTitle(for: selectedActionKind)
        return GameBoardPlaceholderModel(
            title: actionTitle,
            subtitle: "Stage 10.1 shell preview for \(actionTitle)."
        )
    }

    private func actionTitle(for kind: GameActionDockItem.Kind) -> String {
        switch kind {
        case .roll:
            return "Roll"
        case .build:
            return "Build"
        case .trade:
            return "Trade"
        case .devCards:
            return "Dev Cards"
        case .endTurn:
            return "End Turn"
        }
    }
}
