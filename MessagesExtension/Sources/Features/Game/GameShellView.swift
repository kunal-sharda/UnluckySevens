import SwiftUI

struct GameShellView: View {
    @ObservedObject var viewModel: LobbyDriverViewModel
    @State private var selectedActionKind: GameActionDockItem.Kind?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: GameTheme.sectionSpacing) {
                GameHeaderView(
                    statusLine: viewModel.shellStatusLine,
                    metaText: viewModel.activeContextMeta
                )

                PlayerSummaryStripView(summaries: viewModel.shellOpponentSummaries)

                BoardContainerView(
                    title: selectedBoardTitle,
                    subtitle: selectedBoardSubtitle
                )

                HandTrayView(chips: viewModel.shellHandChips)

                ActionDockView(
                    items: viewModel.shellActionItems,
                    selectedKind: $selectedActionKind
                )

                DebugHUDView(viewModel: viewModel)
            }
            .padding(GameTheme.shellPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var selectedBoardTitle: String {
        if let selectedActionKind {
            return actionTitle(for: selectedActionKind)
        }
        return viewModel.shellStatusLine.title
    }

    private var selectedBoardSubtitle: String {
        if let selectedActionKind {
            return "Stage 10.1 shell preview for \(actionTitle(for: selectedActionKind))."
        }
        return viewModel.activeContextBanner
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
