import SwiftUI
import ULS_CoreGame

struct GameShellView: View {
    @ObservedObject var viewModel: LobbyDriverViewModel
    @State private var currentMode: GameMode = .idle
    @State private var selectedBoardTarget: GameBoardTarget?
    @State private var boardHintText: String?
    @State private var devCardDraft: GameDevCardDraft?
    @State private var manualLowerShelf: GameLowerShelf?

    var body: some View {
        let screenModel = viewModel.gameScreenModel
        let isGameOver = viewModel.phase == PhaseV1.gameOver.rawValue
        let resolvedMode = GameModeResolver.normalized(
            currentMode: currentMode,
            availability: screenModel.modeAvailability
        )
        let activeLowerShelf = resolvedLowerShelf(mode: resolvedMode)
        let isShelfPresented = activeLowerShelf != nil
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
        let headerModel = GameHeaderModel(
            statusLine: screenModel.header.statusLine,
            metaText: ""
        )

        ZStack {
            GameTheme.appBackground
                .ignoresSafeArea()

            GeometryReader { geometry in
                let shellLayout = GameShellLayoutMetrics.resolve(
                    availableHeight: max(geometry.size.height - (GameTheme.shellPadding * 2), 0),
                    spacing: GameTheme.sectionSpacing,
                    isShelfPresented: isShelfPresented && !isGameOver
                )

                VStack(alignment: .leading, spacing: GameTheme.sectionSpacing) {
                    GameHeaderView(model: headerModel)
                        .frame(height: shellLayout.headerHeight, alignment: .topLeading)

                    BoardContainerView(
                        model: selectedBoardModel(screenModel: screenModel, mode: resolvedMode),
                        renderModel: screenModel.boardRenderModel,
                        overlayModel: overlayModel,
                        interactionMode: resolvedMode,
                        selectionText: resolvedBoardHintText(
                            mode: resolvedMode,
                            overlayModel: overlayModel
                        ),
                        onInteractionChanged: nil,
                        onTargetTap: { target in
                            handleBoardTap(target, mode: resolvedMode)
                        }
                    )
                    .frame(height: shellLayout.boardHeight, alignment: .top)
                    .clipped()

                    if !isGameOver {
                        GameBottomTrayView(
                            layout: shellLayout.lowerRail,
                            activeShelf: activeLowerShelf,
                            selectedUtilityShelf: selectedUtilityShelf(mode: resolvedMode),
                            handTray: screenModel.handTray,
                            bankTray: bankTrayModel,
                            opponents: screenModel.opponents,
                            actionDock: screenModel.actionDock,
                            selectedDockKind: selectedDockKind(activeShelf: activeLowerShelf),
                            selectedBuildKind: resolvedMode.buildShelfKind,
                            mode: resolvedMode,
                            setupInstruction: viewModel.setupGuidanceText,
                            discardPanel: viewModel.discardPanelModel,
                            tradePanel: viewModel.tradePanelModel,
                            devCardPanel: devCardPanelModel,
                            robberVictimOptions: viewModel.robberVictimOptions,
                            onSelectDock: { actionKind in
                                handleActionSelection(
                                    actionKind,
                                    currentMode: resolvedMode,
                                    availability: screenModel.modeAvailability,
                                    actionDock: screenModel.actionDock
                                )
                            },
                            onSelectBuild: { buildKind in
                                handleBuildShelfSelection(buildKind)
                            },
                            onSelectUtilityShelf: { shelf in
                                handleUtilityShelfSelection(shelf, currentMode: resolvedMode)
                            },
                            onSelectBankResource: { resource in
                                handleBankResourceSelection(resource, mode: resolvedMode)
                            },
                            onOpenTrade: {
                                handleTradeShelfSelection()
                            },
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
                        .frame(height: shellLayout.trayHeight, alignment: .top)
                    }
                }
                .padding(GameTheme.shellPadding)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
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
        }
        .onChange(of: resolvedMode) { _, newMode in
            boardHintText = nil
            synchronizeBoardSelection(mode: newMode)
            if !newMode.isDevCardMode {
                devCardDraft = nil
            }
            if newMode.isForcedBoardMode {
                manualLowerShelf = nil
            }
        }
        .onChange(of: screenModel.boardRenderModel) { _, _ in
            synchronizeBoardSelection(mode: resolvedMode)
        }
    }

    private func resolvedLowerShelf(mode: GameMode) -> GameLowerShelf? {
        if mode == .discard || mode == .robberVictim {
            return .forcedFlow
        }
        if mode.isDevCardMode {
            return .devCards
        }
        if mode.isBuildMode || manualLowerShelf == .build {
            return .build
        }
        if mode == .trade {
            return .hand
        }
        switch manualLowerShelf {
        case .hand, .bank, .players:
            return manualLowerShelf
        default:
            return nil
        }
    }

    private func selectedUtilityShelf(mode: GameMode) -> GameLowerShelf? {
        if mode == .trade {
            return .hand
        }
        switch manualLowerShelf {
        case .hand, .bank, .players:
            return manualLowerShelf
        default:
            return nil
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

    private func resolvedBoardHintText(
        mode: GameMode,
        overlayModel: GameBoardOverlayModel
    ) -> String? {
        if let selectedTarget = overlayModel.selectedTarget {
            return selectedTarget.selectionLabel(for: mode)
        }

        if let boardHintText {
            return boardHintText
        }

        switch mode {
        case .setup:
            return viewModel.setupGuidanceText ?? "Tap a highlighted settlement or road."
        case .buildRoad, .buildSettlement, .buildCity, .robberMove, .devCardKnightMove, .devCardKnightVictim, .devCardRoadBuildingFirst, .devCardRoadBuildingSecond:
            return failureHint(for: mode)
        case .idle, .trade, .playDevCard, .devCardMonopoly, .devCardYearOfPlenty, .discard, .robberVictim:
            return nil
        }
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
                self.manualLowerShelf = nil
            }
            return
        }

        withAnimation(GameTheme.quickAnimation) {
            self.boardHintText = nil
            switch actionKind {
            case .build:
                guard !actionDock.buildShelfItems.isEmpty else {
                    self.currentMode = .idle
                    self.manualLowerShelf = nil
                    self.devCardDraft = nil
                    return
                }

                if resolvedLowerShelf(mode: currentMode) == .build {
                    self.currentMode = .idle
                    self.selectedBoardTarget = nil
                    self.manualLowerShelf = nil
                    self.devCardDraft = nil
                } else {
                    self.currentMode = .idle
                    self.selectedBoardTarget = nil
                    self.manualLowerShelf = .build
                    self.devCardDraft = nil
                }
            case .devCards:
                let nextMode = GameModeResolver.nextMode(
                    for: actionKind,
                    currentMode: currentMode,
                    availability: availability
                )
                self.currentMode = nextMode
                self.selectedBoardTarget = nil
                self.manualLowerShelf = nil
                self.devCardDraft = nil
            case .trade:
                self.currentMode = .trade
                self.selectedBoardTarget = nil
                self.manualLowerShelf = .hand
            case .roll, .endTurn:
                self.currentMode = .idle
                self.selectedBoardTarget = nil
                self.manualLowerShelf = nil
                self.devCardDraft = nil
            }
        }
    }

    private func handleUtilityShelfSelection(_ shelf: GameLowerShelf, currentMode: GameMode) {
        withAnimation(GameTheme.quickAnimation) {
            if selectedUtilityShelf(mode: currentMode) == shelf {
                if currentMode == .trade {
                    self.currentMode = .idle
                }
                self.manualLowerShelf = nil
            } else {
                if currentMode == .trade {
                    self.currentMode = .idle
                }
                self.manualLowerShelf = shelf
            }
            self.selectedBoardTarget = nil
            self.boardHintText = nil
        }
    }

    private func handleTradeShelfSelection() {
        guard viewModel.tradePanelModel != nil else {
            return
        }

        withAnimation(GameTheme.quickAnimation) {
            if currentMode == .trade {
                currentMode = .idle
            } else {
                currentMode = .trade
                manualLowerShelf = .hand
            }
            selectedBoardTarget = nil
            boardHintText = nil
        }
    }

    private func handleBuildShelfSelection(_ buildKind: GameBuildShelfItem.Kind) {
        withAnimation(GameTheme.quickAnimation) {
            manualLowerShelf = .build
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
                manualLowerShelf = nil
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
        manualLowerShelf = nil
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
                manualLowerShelf = nil
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

    private func selectedDockKind(activeShelf: GameLowerShelf?) -> GameActionDockItem.Kind? {
        activeShelf?.actionKind
    }
}

private extension GameMode {
    var isForcedBoardMode: Bool {
        switch self {
        case .setup, .robberMove, .robberVictim, .discard:
            return true
        default:
            return false
        }
    }
}
