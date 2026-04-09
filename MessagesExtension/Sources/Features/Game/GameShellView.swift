import SwiftUI

struct GameShellView: View {
    @ObservedObject var viewModel: LobbyDriverViewModel
    @State private var currentMode: GameMode = .idle
    @State private var selectedBoardTarget: GameBoardTarget?

    var body: some View {
        let screenModel = viewModel.gameScreenModel
        let resolvedMode = GameModeResolver.normalized(
            currentMode: currentMode,
            availability: screenModel.modeAvailability
        )
        let overlayModel = viewModel.makeBoardOverlayModel(
            mode: resolvedMode,
            selectedTarget: selectedBoardTarget
        )

        ZStack {
            GameTheme.appBackground
                .ignoresSafeArea()

            GeometryReader { geometry in
                let boardHeight = resolvedBoardHeight(for: geometry.size.height)
                let railMaxHeight = resolvedRailHeight(
                    totalHeight: geometry.size.height,
                    boardHeight: boardHeight
                )

                VStack(alignment: .leading, spacing: GameTheme.sectionSpacing) {
                    GameHeaderView(model: screenModel.header)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    BoardContainerView(
                        model: selectedBoardModel(screenModel: screenModel, mode: resolvedMode),
                        renderModel: screenModel.boardRenderModel,
                        overlayModel: overlayModel,
                        interactionMode: resolvedMode,
                        selectionText: overlayModel.selectedTarget?.debugLabel,
                        onInteractionChanged: nil,
                        onTargetTap: { target in
                            handleBoardTap(target, mode: resolvedMode)
                        }
                    )
                    .frame(height: boardHeight)

                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(alignment: .leading, spacing: GameTheme.sectionSpacing) {
                            PlayerSummaryStripView(summaries: screenModel.opponents)

                            GameModalHostView(
                                mode: resolvedMode,
                                setupInstruction: viewModel.setupGuidanceText,
                                discardPanel: viewModel.discardPanelModel,
                                tradePanel: viewModel.tradePanelModel,
                                devCardPanel: viewModel.devCardPanelModel,
                                robberVictimOptions: viewModel.robberVictimOptions,
                                onDiscardAction: {
                                    guard viewModel.handleDiscardFlowAction() else { return }
                                    selectedBoardTarget = nil
                                },
                                onTradeAction: { action in
                                    guard viewModel.handleTradeAction(action) else { return }
                                    if action != .applySelectedAccept {
                                        currentMode = .idle
                                    }
                                    selectedBoardTarget = nil
                                },
                                onApplySelectedTurnIntent: {
                                    guard viewModel.publishSelectedTurnIntentState() else { return }
                                    selectedBoardTarget = nil
                                },
                                onExecuteTrade: { playerID in
                                    guard viewModel.publishTradeExecution(acceptingPlayer: playerID) else { return }
                                    currentMode = .idle
                                    selectedBoardTarget = nil
                                },
                                onDevCardAction: { action in
                                    guard viewModel.handleDevCardAction(action) else { return }
                                    currentMode = .idle
                                    selectedBoardTarget = nil
                                },
                                onSelectStealVictim: { victimPlayer in
                                    guard viewModel.publishRobberVictimState(victimPlayer: victimPlayer) else { return }
                                    currentMode = .idle
                                    selectedBoardTarget = nil
                                }
                            )
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxWidth: .infinity, maxHeight: railMaxHeight, alignment: .top)
                    .background(GameTheme.surface.opacity(0.58))
                    .overlay(
                        RoundedRectangle(cornerRadius: GameTheme.mediumRadius)
                            .stroke(GameTheme.outline.opacity(0.10), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: GameTheme.mediumRadius))
                }
                .padding(GameTheme.shellPadding)
                .padding(.bottom, 168)
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
            synchronizeBoardSelection(mode: resolvedMode)
        }
        .onChange(of: screenModel.modeAvailability) { _, availability in
            synchronizeMode(with: availability)
        }
        .onChange(of: resolvedMode) { _, newMode in
            synchronizeBoardSelection(mode: newMode)
        }
        .onChange(of: screenModel.boardRenderModel) { _, _ in
            synchronizeBoardSelection(mode: resolvedMode)
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
            subtitle: mode == .setup
                ? (viewModel.setupGuidanceText ?? mode.subtitle)
                : mode.subtitle
        )
    }

    private func handleActionSelection(
        _ actionKind: GameActionDockItem.Kind,
        currentMode: GameMode,
        availability: GameModeAvailability
    ) {
        if viewModel.publishTurnState(for: actionKind) {
            withAnimation(GameTheme.quickAnimation) {
                self.currentMode = .idle
                self.selectedBoardTarget = nil
            }
            return
        }

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

    private func normalizedBoardTarget(
        for target: GameBoardTarget,
        mode: GameMode
    ) -> GameBoardTarget? {
        viewModel.makeBoardOverlayModel(
            mode: mode,
            selectedTarget: target
        ).selectedTarget
    }

    private func handleBoardTap(_ target: GameBoardTarget, mode: GameMode) {
        let normalizedTarget = normalizedBoardTarget(for: target, mode: mode)

        switch mode {
        case .setup:
            guard let normalizedTarget else {
                return
            }
            if viewModel.publishSetupState(for: normalizedTarget) {
                selectedBoardTarget = nil
            } else {
                selectedBoardTarget = normalizedTarget
            }
        case .buildRoad, .buildSettlement, .buildCity, .robberMove, .robberVictim:
            guard let normalizedTarget else {
                return
            }
            if viewModel.publishTurnState(for: normalizedTarget, mode: mode) {
                currentMode = .idle
                selectedBoardTarget = nil
            } else {
                selectedBoardTarget = normalizedTarget
            }
        default:
            selectedBoardTarget = normalizedTarget
        }
    }

    private func synchronizeBoardSelection(mode: GameMode) {
        let normalizedTarget = viewModel.makeBoardOverlayModel(
            mode: mode,
            selectedTarget: selectedBoardTarget
        ).selectedTarget

        guard normalizedTarget != selectedBoardTarget else {
            return
        }

        selectedBoardTarget = normalizedTarget
    }

    private func resolvedBoardHeight(for totalHeight: CGFloat) -> CGFloat {
        min(max(totalHeight * 0.46, 296), 430)
    }

    private func resolvedRailHeight(totalHeight: CGFloat, boardHeight: CGFloat) -> CGFloat {
        let remaining = totalHeight - boardHeight - 260
        return max(remaining, 96)
    }
}
