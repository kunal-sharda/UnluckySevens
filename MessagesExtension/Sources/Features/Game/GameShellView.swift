import SwiftUI
import ULS_CoreGame

struct GameShellView: View {
    @ObservedObject var viewModel: LobbyDriverViewModel
    @State private var currentMode: GameMode = .idle
    @State private var selectedBoardTarget: GameBoardTarget?
    @State private var boardHintText: String?
    @State private var isBuildShelfExpanded = false

    var body: some View {
        let screenModel = viewModel.gameScreenModel
        let isGameOver = viewModel.phase == PhaseV1.gameOver.rawValue
        let resolvedMode = GameModeResolver.normalized(
            currentMode: currentMode,
            availability: screenModel.modeAvailability
        )
        let isBuildShelfPresented = isBuildShelfExpanded || resolvedMode.isBuildMode
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
                        selectionText: overlayModel.selectedTarget?.selectionLabel(for: resolvedMode) ?? boardHintText,
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
            if !isGameOver {
                GameBottomTrayView(
                    handTray: screenModel.handTray,
                    actionDock: screenModel.actionDock,
                    selectedKind: selectedDockKind(mode: resolvedMode, isBuildShelfPresented: isBuildShelfPresented),
                    selectedBuildKind: resolvedMode.buildShelfKind,
                    isBuildShelfPresented: isBuildShelfPresented
                ) { actionKind in
                    handleActionSelection(
                        actionKind,
                        currentMode: resolvedMode,
                        availability: screenModel.modeAvailability,
                        actionDock: screenModel.actionDock
                    )
                } onSelectBuild: { buildKind in
                    handleBuildShelfSelection(buildKind)
                }
                .padding(.horizontal, GameTheme.shellPadding)
                .padding(.top, 8)
                .padding(.bottom, 8)
                .background(GameTheme.appBackground)
            }
        }
        .onAppear {
            synchronizeMode(with: screenModel.modeAvailability)
            synchronizeBoardSelection(mode: resolvedMode)
            boardHintText = nil
        }
        .onChange(of: screenModel.modeAvailability) { _, availability in
            synchronizeMode(with: availability)
            if !resolvedMode.isBuildMode, screenModel.actionDock.buildShelfItems.isEmpty {
                isBuildShelfExpanded = false
            }
        }
        .onChange(of: resolvedMode) { _, newMode in
            boardHintText = nil
            synchronizeBoardSelection(mode: newMode)
            if !newMode.isBuildMode, !isBuildShelfExpanded {
                selectedBoardTarget = nil
            }
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
        availability: GameModeAvailability,
        actionDock: GameActionDockModel
    ) {
        if viewModel.publishTurnState(for: actionKind) {
            withAnimation(GameTheme.quickAnimation) {
                self.currentMode = .idle
                self.selectedBoardTarget = nil
                self.boardHintText = nil
                self.isBuildShelfExpanded = false
            }
            return
        }

        withAnimation(GameTheme.quickAnimation) {
            self.boardHintText = nil
            switch actionKind {
            case .build:
                guard !actionDock.buildShelfItems.isEmpty else {
                    self.currentMode = .idle
                    self.isBuildShelfExpanded = false
                    return
                }

                if currentMode.isBuildMode || isBuildShelfExpanded {
                    self.currentMode = .idle
                    self.selectedBoardTarget = nil
                    self.isBuildShelfExpanded = false
                } else {
                    self.currentMode = .idle
                    self.selectedBoardTarget = nil
                    self.isBuildShelfExpanded = true
                }
            case .trade, .devCards:
                self.currentMode = GameModeResolver.nextMode(
                    for: actionKind,
                    currentMode: currentMode,
                    availability: availability
                )
                self.selectedBoardTarget = nil
                self.isBuildShelfExpanded = false
            case .roll, .endTurn:
                self.currentMode = .idle
                self.selectedBoardTarget = nil
                self.isBuildShelfExpanded = false
            }
        }
    }

    private func handleBuildShelfSelection(_ buildKind: GameBuildShelfItem.Kind) {
        withAnimation(GameTheme.quickAnimation) {
            switch buildKind {
            case .buildRoad:
                currentMode = .buildRoad
                selectedBoardTarget = nil
                boardHintText = nil
            case .buildSettlement:
                currentMode = .buildSettlement
                selectedBoardTarget = nil
                boardHintText = nil
            case .buildCity:
                currentMode = .buildCity
                selectedBoardTarget = nil
                boardHintText = nil
            case .buyDevCard:
                guard viewModel.handleDevCardAction(.buyDevCard) else { return }
                currentMode = .idle
                selectedBoardTarget = nil
                boardHintText = nil
                isBuildShelfExpanded = false
            }
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
                boardHintText = failureHint(for: mode)
                return
            }
            if viewModel.publishSetupState(for: normalizedTarget) {
                selectedBoardTarget = nil
                boardHintText = nil
            } else {
                selectedBoardTarget = normalizedTarget
                boardHintText = normalizedTarget.selectionLabel(for: mode)
            }
        case .buildRoad, .buildSettlement, .buildCity, .robberMove, .robberVictim:
            guard let normalizedTarget else {
                boardHintText = failureHint(for: mode)
                return
            }
            if viewModel.publishTurnState(for: normalizedTarget, mode: mode) {
                currentMode = .idle
                selectedBoardTarget = nil
                boardHintText = nil
            } else {
                selectedBoardTarget = normalizedTarget
                boardHintText = normalizedTarget.selectionLabel(for: mode)
            }
        default:
            selectedBoardTarget = nil
            boardHintText = nil
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
        if normalizedTarget == nil, mode != .idle {
            boardHintText = failureHint(for: mode)
        }
    }

    private func resolvedBoardHeight(for totalHeight: CGFloat) -> CGFloat {
        min(max(totalHeight * 0.46, 296), 430)
    }

    private func resolvedRailHeight(totalHeight: CGFloat, boardHeight: CGFloat) -> CGFloat {
        let remaining = totalHeight - boardHeight - 260
        return max(remaining, 96)
    }

    private func failureHint(for mode: GameMode) -> String? {
        switch mode {
        case .setup:
            return "Tap a highlighted settlement or road."
        case .buildRoad:
            return "Tap a highlighted edge to build a road."
        case .buildSettlement:
            return "Tap a highlighted node to build a settlement."
        case .buildCity:
            return "Tap one of your highlighted settlements."
        case .robberMove:
            return "Tap a highlighted tile to move the robber."
        case .robberVictim:
            return "Tap a highlighted victim to steal."
        case .idle, .trade, .playDevCard, .discard:
            return nil
        }
    }

    private func selectedDockKind(
        mode: GameMode,
        isBuildShelfPresented: Bool
    ) -> GameActionDockItem.Kind? {
        if isBuildShelfPresented || mode.isBuildMode {
            return .build
        }
        return mode.actionKind
    }
}
