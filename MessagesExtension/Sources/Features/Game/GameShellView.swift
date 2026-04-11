import SwiftUI
import ULS_CoreGame

struct GameShellView: View {
    @ObservedObject var viewModel: LobbyDriverViewModel
    @State private var currentMode: GameMode = .idle
    @State private var selectedBoardTarget: GameBoardTarget?
    @State private var boardHintText: String?
    @State private var devCardDraft: GameDevCardDraft?
    @State private var isBuildShelfExpanded = false

    var body: some View {
        let screenModel = viewModel.gameScreenModel
        let isGameOver = viewModel.phase == PhaseV1.gameOver.rawValue
        let resolvedMode = GameModeResolver.normalized(
            currentMode: currentMode,
            availability: screenModel.modeAvailability
        )
        let isBuildShelfPresented = isBuildShelfExpanded || resolvedMode.isBuildMode
        let bankTrayModel = viewModel.makeBankTrayModel(
            mode: resolvedMode,
            draft: devCardDraft
        )
        let devCardPanelModel = viewModel.makeDevCardPanelModel(
            mode: resolvedMode,
            draft: devCardDraft
        )
        let overlayModel = viewModel.makeBoardOverlayModel(
            mode: resolvedMode,
            devCardDraft: devCardDraft,
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
                                devCardPanel: devCardPanelModel,
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
                                    handleDevCardSelection(action)
                                },
                                onConfirmDevCardDraft: {
                                    handleConfirmDevCardDraft()
                                },
                                onResetDevCardDraft: {
                                    resetDevCardDraft()
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
                    bankTray: bankTrayModel,
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
                } onSelectBankResource: { resource in
                    handleBankResourceSelection(resource, mode: resolvedMode)
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
            if !resolvedMode.isDevCardMode {
                devCardDraft = nil
            }
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
            if !newMode.isDevCardMode {
                devCardDraft = nil
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
                    self.devCardDraft = nil
                    return
                }

                if currentMode.isBuildMode || isBuildShelfExpanded {
                    self.currentMode = .idle
                    self.selectedBoardTarget = nil
                    self.isBuildShelfExpanded = false
                    self.devCardDraft = nil
                } else {
                    self.currentMode = .idle
                    self.selectedBoardTarget = nil
                    self.isBuildShelfExpanded = true
                    self.devCardDraft = nil
                }
            case .trade, .devCards:
                let nextMode = GameModeResolver.nextMode(
                    for: actionKind,
                    currentMode: currentMode,
                    availability: availability
                )
                self.currentMode = nextMode
                self.selectedBoardTarget = nil
                self.isBuildShelfExpanded = false
                self.devCardDraft = nextMode.isDevCardMode ? nil : nil
            case .roll, .endTurn:
                self.currentMode = .idle
                self.selectedBoardTarget = nil
                self.isBuildShelfExpanded = false
                self.devCardDraft = nil
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
                devCardDraft = nil
            case .buildSettlement:
                currentMode = .buildSettlement
                selectedBoardTarget = nil
                boardHintText = nil
                devCardDraft = nil
            case .buildCity:
                currentMode = .buildCity
                selectedBoardTarget = nil
                boardHintText = nil
                devCardDraft = nil
            case .buyDevCard:
                guard viewModel.handleDevCardAction(.buyDevCard) else { return }
                currentMode = .idle
                selectedBoardTarget = nil
                boardHintText = nil
                isBuildShelfExpanded = false
                devCardDraft = nil
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
            devCardDraft: devCardDraft,
            selectedTarget: target
        ).selectedTarget
    }

    private func handleDevCardSelection(_ action: GameDevCardActionKind) {
        withAnimation(GameTheme.quickAnimation) {
            switch action {
            case .buyDevCard, .revealVictoryPoint:
                guard viewModel.handleDevCardAction(action) else { return }
                dismissDevCardFlow()
            case .playKnight:
                devCardDraft = .knight(tileID: nil, victimPlayer: nil)
                currentMode = .devCardKnightMove
                selectedBoardTarget = nil
                boardHintText = nil
            case .playMonopoly:
                devCardDraft = .monopoly(resource: nil)
                currentMode = .devCardMonopoly
                selectedBoardTarget = nil
                boardHintText = nil
            case .playYearOfPlenty:
                devCardDraft = .yearOfPlenty(first: nil, second: nil)
                currentMode = .devCardYearOfPlenty
                selectedBoardTarget = nil
                boardHintText = nil
            case .playRoadBuilding:
                devCardDraft = .roadBuilding(firstEdgeID: nil, secondEdgeID: nil)
                currentMode = .devCardRoadBuildingFirst
                selectedBoardTarget = nil
                boardHintText = nil
            }
        }
    }

    private func handleConfirmDevCardDraft() {
        guard let devCardDraft else {
            return
        }
        guard viewModel.publishDevCardDraft(devCardDraft) else {
            return
        }

        withAnimation(GameTheme.quickAnimation) {
            dismissDevCardFlow()
        }
    }

    private func handleBankResourceSelection(_ resource: ResourceV1, mode: GameMode) {
        guard mode.isDevCardMode else {
            return
        }

        withAnimation(GameTheme.quickAnimation) {
            switch devCardDraft {
            case .monopoly:
                devCardDraft = .monopoly(resource: resource)
            case let .yearOfPlenty(first, second):
                if first == nil {
                    devCardDraft = .yearOfPlenty(first: resource, second: nil)
                } else if second == nil {
                    devCardDraft = .yearOfPlenty(first: first, second: resource)
                } else {
                    devCardDraft = .yearOfPlenty(first: first, second: resource)
                }
            default:
                break
            }
            boardHintText = nil
        }
    }

    private func resetDevCardDraft() {
        withAnimation(GameTheme.quickAnimation) {
            devCardDraft = nil
            currentMode = .playDevCard
            selectedBoardTarget = nil
            boardHintText = nil
        }
    }

    private func dismissDevCardFlow() {
        devCardDraft = nil
        currentMode = .idle
        selectedBoardTarget = nil
        boardHintText = nil
        isBuildShelfExpanded = false
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
        case .devCardKnightMove:
            guard case let .tile(tileID)? = normalizedTarget else {
                boardHintText = failureHint(for: mode)
                return
            }
            let victims = viewModel.legalKnightVictims(for: tileID)
            if victims.count <= 1 {
                if viewModel.publishDevCardDraft(.knight(tileID: tileID, victimPlayer: victims.first)) {
                    dismissDevCardFlow()
                } else {
                    selectedBoardTarget = normalizedTarget
                    boardHintText = normalizedTarget?.selectionLabel(for: mode)
                }
            } else {
                devCardDraft = .knight(tileID: tileID, victimPlayer: nil)
                currentMode = .devCardKnightVictim
                selectedBoardTarget = nil
                boardHintText = "Choose the victim to steal from."
            }
        case .devCardKnightVictim:
            guard
                case let .node(nodeID)? = normalizedTarget,
                case let .knight(tileID?, _) = devCardDraft,
                let victimPlayer = viewModel.knightVictimPlayer(for: nodeID, tileID: tileID)
            else {
                boardHintText = failureHint(for: mode)
                return
            }
            if viewModel.publishDevCardDraft(.knight(tileID: tileID, victimPlayer: victimPlayer)) {
                dismissDevCardFlow()
            } else {
                selectedBoardTarget = normalizedTarget
                boardHintText = normalizedTarget?.selectionLabel(for: mode)
            }
        case .devCardRoadBuildingFirst:
            guard case let .edge(edgeID)? = normalizedTarget else {
                boardHintText = failureHint(for: mode)
                return
            }
            devCardDraft = .roadBuilding(firstEdgeID: edgeID, secondEdgeID: nil)
            currentMode = .devCardRoadBuildingSecond
            selectedBoardTarget = nil
            boardHintText = "Choose the second road."
        case .devCardRoadBuildingSecond:
            guard
                case let .edge(edgeID)? = normalizedTarget,
                case let .roadBuilding(firstEdgeID?, _) = devCardDraft
            else {
                boardHintText = failureHint(for: mode)
                return
            }
            if viewModel.publishDevCardDraft(.roadBuilding(firstEdgeID: firstEdgeID, secondEdgeID: edgeID)) {
                dismissDevCardFlow()
            } else {
                selectedBoardTarget = normalizedTarget
                boardHintText = normalizedTarget?.selectionLabel(for: mode)
            }
        default:
            selectedBoardTarget = nil
            boardHintText = nil
        }
    }

    private func synchronizeBoardSelection(mode: GameMode) {
        let normalizedTarget = viewModel.makeBoardOverlayModel(
            mode: mode,
            devCardDraft: devCardDraft,
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
        case .devCardKnightMove:
            return "Tap a highlighted tile to move the robber."
        case .devCardKnightVictim:
            return "Tap a highlighted victim to steal."
        case .devCardRoadBuildingFirst:
            return "Tap a highlighted edge for the first road."
        case .devCardRoadBuildingSecond:
            return "Tap a highlighted edge for the second road."
        case .idle, .trade, .playDevCard, .devCardMonopoly, .devCardYearOfPlenty, .discard:
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
