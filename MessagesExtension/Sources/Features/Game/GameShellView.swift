import Combine
import SwiftUI
import ULS_CoreGame

struct GameShellView: View {
    let viewModel: LobbyDriverViewModel
    @State private var shellProjection: GameShellProjection
    @State private var currentMode: GameMode = .idle
    @State private var selectedBoardTarget: GameBoardTarget?
    @State private var boardCommitDraft: GameBoardCommitDraft?
    @State private var boardHintText: String?
    @State private var devCardDraft: GameDevCardDraft?
    @State private var manualShelfPresentation: GameShelfPresentation = .none
    @State private var lastUtilityShelf: GameLowerShelf = .hand

    init(viewModel: LobbyDriverViewModel) {
        self.viewModel = viewModel
        _shellProjection = State(initialValue: viewModel.gameplayShellProjection)
    }

    var body: some View {
        let projection = shellProjection
        let screenModel = projection.gameScreenModel
        let isGameOver = projection.phase == PhaseV1.gameOver.rawValue
        let resolvedMode = GameModeResolver.normalized(
            currentMode: currentMode,
            availability: screenModel.modeAvailability
        )
        let shelfPresentation = resolvedShelfPresentation(mode: resolvedMode)
        let activeLowerShelf = shelfPresentation.activeShelf
        let isShelfPresented = activeLowerShelf != nil && !isGameOver
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
                let availableHeight = max(geometry.size.height - (GameTheme.shellPadding * 2), 0)
                let shellLayout = GameShellLayoutMetrics.resolve(
                    availableHeight: availableHeight,
                    spacing: GameTheme.sectionSpacing
                )
                let canPresentUtilityShelf = GameShellLayoutMetrics.supportsUtilityShelf(
                    availableHeight: availableHeight,
                    spacing: GameTheme.sectionSpacing
                )
                let lowerRailWidth = min(
                    GameShellLayoutMetrics.lowerRailWidth(
                        for: max(geometry.size.width - (GameTheme.shellPadding * 2), 0)
                    ),
                    max(geometry.size.width - (GameTheme.shellPadding * 2), 0)
                )
                let utilityContentInset = GameTheme.inlineSpacing
                let shelfBodySize = CGSize(
                    width: max(lowerRailWidth - (utilityContentInset * 2), 0),
                    height: max(shellLayout.overlayShelf.contentHeight - (utilityContentInset * 2), 0)
                )

                ZStack(alignment: .bottom) {
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
                            hintBottomInset: isShelfPresented
                                ? shellLayout.overlayShelf.overlapIntoBoardHeight + 12
                                : 18,
                            onInteractionChanged: nil,
                            onResizeFreezeChanged: { isFrozen in
                                if isFrozen {
                                    clearBoardSelection()
                                }
                            },
                            onTargetTap: { target in
                                handleBoardTap(target, mode: resolvedMode)
                            }
                        )
                        .frame(height: shellLayout.boardHeight, alignment: .top)
                        .clipped()

                        if !isGameOver {
                            GameBottomTrayView(
                                layout: shellLayout.lowerRail,
                                actionDock: screenModel.actionDock,
                                selectedDockKind: shelfPresentation.selectedDockKind,
                                onSelectDock: { actionKind in
                                    handleActionSelection(
                                        actionKind,
                                        currentMode: resolvedMode,
                                        availability: screenModel.modeAvailability,
                                        actionDock: screenModel.actionDock
                                    )
                                },
                                onToggleUtilityShelf: {
                                    handleUtilityHandleToggle(
                                        currentMode: resolvedMode,
                                        canPresentUtilityShelf: canPresentUtilityShelf
                                    )
                                }
                            )
                            .frame(height: shellLayout.trayHeight, alignment: .top)
                            .frame(maxWidth: lowerRailWidth)
                            .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }
                    .padding(GameTheme.shellPadding)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

                    if !isGameOver, let activeLowerShelf {
                        GameOverlayShelfView(
                            layout: shellLayout.overlayShelf,
                            presentation: shelfPresentation,
                            currentMode: resolvedMode,
                            onSelectUtilityShelf: { shelf in
                                handleUtilityShelfSelection(shelf, currentMode: resolvedMode)
                            },
                            onClose: {
                                handleCloseShelf(currentMode: resolvedMode)
                            }
                        ) {
                            GameLowerShelfContentView(
                                activeShelf: activeLowerShelf,
                                availableBodySize: shelfBodySize,
                                boardCommitDraft: boardCommitDraft,
                                handTray: screenModel.handTray,
                                bankTray: bankTrayModel,
                                opponents: screenModel.opponents,
                                actionDock: screenModel.actionDock,
                                selectedBuildKind: resolvedMode.buildShelfKind,
                                mode: resolvedMode,
                                setupInstruction: projection.setupGuidanceText,
                                discardPanel: projection.discardPanelModel,
                                tradePanel: projection.tradePanelModel,
                                devCardPanel: devCardPanelModel,
                                robberVictimOptions: projection.robberVictimOptions,
                                onSelectBuild: { buildKind in
                                    handleBuildShelfSelection(buildKind)
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
                                        manualShelfPresentation = .none
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
                                    manualShelfPresentation = .none
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
                                onConfirmBoardCommit: {
                                    if let boardCommitDraft {
                                        publishBoardCommitDraft(boardCommitDraft)
                                    }
                                },
                                onCancelBoardCommit: {
                                    clearBoardSelection()
                                },
                                onSelectStealVictim: { victimPlayer in
                                    guard viewModel.publishRobberVictimState(victimPlayer: victimPlayer) else { return }
                                    currentMode = .idle
                                    clearBoardSelection()
                                }
                            )
                        }
                        .frame(height: shellLayout.overlayShelf.totalHeight, alignment: .top)
                        .frame(maxWidth: lowerRailWidth)
                        .padding(.horizontal, GameTheme.shellPadding)
                        .padding(.bottom, GameTheme.shellPadding + shellLayout.lowerRail.dockHeight)
                        .zIndex(1)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .onChange(of: geometry.size) { _, newValue in
                    enforceVisibleShelfBounds(
                        observedSize: newValue,
                        currentMode: resolvedMode
                    )
                }
                .onAppear {
                    enforceVisibleShelfBounds(
                        observedSize: geometry.size,
                        currentMode: resolvedMode
                    )
                }
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
        .onReceive(viewModel.$gameplayShellProjection.removeDuplicates()) { projection in
            shellProjection = projection
        }
        .onChange(of: screenModel.modeAvailability) { _, availability in
            synchronizeMode(with: availability)
        }
        .onChange(of: resolvedMode) { _, newMode in
            if !GameBoardCommitCoordinator.handles(mode: newMode) {
                boardCommitDraft = nil
            }
            boardHintText = nil
            synchronizeBoardSelection(mode: newMode)
            if !newMode.isDevCardMode {
                devCardDraft = nil
            }
            if newMode.isForcedBoardMode {
                manualShelfPresentation = .none
            }
        }
        .onChange(of: screenModel.boardRenderModel) { _, _ in
            synchronizeBoardSelection(mode: resolvedMode)
        }
    }

    private func resolvedShelfPresentation(mode: GameMode) -> GameShelfPresentation {
        if boardCommitDraft != nil {
            return .forcedFlow
        }
        if mode == .discard || mode == .robberVictim {
            return .forcedFlow
        }
        if mode.isDevCardMode {
            return .action(.devCards)
        }
        if mode.isBuildMode {
            return .action(.build)
        }
        if mode == .trade {
            return .utility(.hand)
        }

        switch manualShelfPresentation {
        case let .utility(shelf):
            return .utility(shelf)
        case let .action(shelf):
            return .action(shelf)
        case .forcedFlow:
            return .forcedFlow
        case .none:
            return .none
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
                ? (shellProjection.setupGuidanceText ?? mode.subtitle)
                : mode.subtitle
        )
    }

    private func resolvedBoardHintText(
        mode: GameMode,
        overlayModel: GameBoardOverlayModel
    ) -> String? {
        if let boardCommitDraft {
            return boardCommitDraft.hintText
        }

        if let selectedTarget = overlayModel.selectedTarget {
            return selectedTarget.selectionLabel(for: mode)
        }

        if let boardHintText {
            return boardHintText
        }

        switch mode {
        case .setup:
            if !overlayModel.legalNodeIDs.isEmpty {
                return "Tap node"
            }
            if !overlayModel.legalEdgeIDs.isEmpty {
                return "Tap road"
            }
            return "Continue setup"
        case .buildRoad:
            return "Tap road"
        case .buildSettlement:
            return "Tap node"
        case .buildCity:
            return "Tap city"
        case .robberMove, .devCardKnightMove:
            return "Tap tile"
        case .robberVictim, .devCardKnightVictim:
            return "Pick victim"
        case .devCardRoadBuildingFirst:
            return "Tap road"
        case .devCardRoadBuildingSecond:
            return "Pick 2nd road"
        case .idle, .trade, .playDevCard, .devCardMonopoly, .devCardYearOfPlenty, .discard:
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
            self.currentMode = .idle
            clearBoardSelection()
            self.manualShelfPresentation = .none
            self.devCardDraft = nil
            return
        }

        clearBoardSelection()
        switch actionKind {
        case .build:
            guard !actionDock.buildShelfItems.isEmpty else {
                self.currentMode = .idle
                self.manualShelfPresentation = .none
                self.devCardDraft = nil
                return
            }

            if resolvedShelfPresentation(mode: currentMode) == .action(.build) {
                self.currentMode = .idle
                self.manualShelfPresentation = .none
                self.devCardDraft = nil
            } else {
                self.currentMode = .idle
                self.manualShelfPresentation = .action(.build)
                self.devCardDraft = nil
            }
        case .devCards:
            let nextMode = GameModeResolver.nextMode(
                for: actionKind,
                currentMode: currentMode,
                availability: availability
            )
            self.currentMode = nextMode
            self.manualShelfPresentation = .none
            self.devCardDraft = nil
        case .trade:
            self.currentMode = .trade
            self.manualShelfPresentation = .utility(.hand)
            self.lastUtilityShelf = .hand
        case .roll, .endTurn:
            self.currentMode = .idle
            self.manualShelfPresentation = .none
            self.devCardDraft = nil
        }
    }

    private func handleUtilityHandleToggle(
        currentMode: GameMode,
        canPresentUtilityShelf: Bool
    ) {
        let presentation = resolvedShelfPresentation(mode: currentMode)
        if case .utility = presentation {
            if currentMode == .trade {
                self.currentMode = .idle
            }
            self.manualShelfPresentation = .none
        } else {
            guard canPresentUtilityShelf else {
                return
            }
            if currentMode == .trade {
                self.currentMode = .idle
            }
            self.manualShelfPresentation = .utility(lastUtilityShelf)
        }
        clearBoardSelection()
    }

    private func handleUtilityShelfSelection(
        _ shelf: GameLowerShelf,
        currentMode: GameMode
    ) {
        lastUtilityShelf = shelf

        if resolvedShelfPresentation(mode: currentMode) == .utility(shelf) {
            if currentMode == .trade {
                self.currentMode = .idle
            }
            self.manualShelfPresentation = .none
        } else {
            if currentMode == .trade {
                self.currentMode = .idle
            }
            self.manualShelfPresentation = .utility(shelf)
        }
        clearBoardSelection()
    }

    private func handleCloseShelf(currentMode: GameMode) {
        switch resolvedShelfPresentation(mode: currentMode) {
        case .utility:
            if currentMode == .trade {
                self.currentMode = .idle
            }
            self.manualShelfPresentation = .none
            clearBoardSelection()
        case let .action(shelf):
            if shelf == .devCards {
                dismissDevCardFlow()
            } else {
                self.currentMode = .idle
                self.manualShelfPresentation = .none
                clearBoardSelection()
            }
        case .forcedFlow, .none:
            break
        }
    }

    private func handleTradeShelfSelection() {
        guard shellProjection.tradePanelModel != nil else {
            return
        }

        if currentMode == .trade {
            currentMode = .idle
            manualShelfPresentation = .none
        } else {
            currentMode = .trade
            manualShelfPresentation = .utility(.hand)
            lastUtilityShelf = .hand
        }
        clearBoardSelection()
    }

    private func handleBuildShelfSelection(_ buildKind: GameBuildShelfItem.Kind) {
        manualShelfPresentation = .action(.build)
        switch buildKind {
        case .buildRoad:
            currentMode = .buildRoad
            clearBoardSelection()
            devCardDraft = nil
        case .buildSettlement:
            currentMode = .buildSettlement
            clearBoardSelection()
            devCardDraft = nil
        case .buildCity:
            currentMode = .buildCity
            clearBoardSelection()
            devCardDraft = nil
        case .buyDevCard:
            guard viewModel.handleDevCardAction(.buyDevCard) else { return }
            currentMode = .idle
            clearBoardSelection()
            manualShelfPresentation = .none
            devCardDraft = nil
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
        clearBoardSelection()
        switch action {
        case .buyDevCard, .revealVictoryPoint:
            guard viewModel.handleDevCardAction(action) else { return }
            dismissDevCardFlow()
        case .playKnight:
            devCardDraft = .knight(tileID: nil, victimPlayer: nil)
            currentMode = .devCardKnightMove
        case .playMonopoly:
            devCardDraft = .monopoly(resource: nil)
            currentMode = .devCardMonopoly
        case .playYearOfPlenty:
            devCardDraft = .yearOfPlenty(first: nil, second: nil)
            currentMode = .devCardYearOfPlenty
        case .playRoadBuilding:
            devCardDraft = .roadBuilding(firstEdgeID: nil, secondEdgeID: nil)
            currentMode = .devCardRoadBuildingFirst
        }
    }

    private func handleConfirmDevCardDraft() {
        guard let devCardDraft else {
            return
        }
        guard viewModel.publishDevCardDraft(devCardDraft) else {
            return
        }

        dismissDevCardFlow()
    }

    private func handleBankResourceSelection(_ resource: ResourceV1, mode: GameMode) {
        guard mode.isDevCardMode else {
            return
        }

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

    private func resetDevCardDraft() {
        devCardDraft = nil
        currentMode = .playDevCard
        clearBoardSelection()
    }

    private func dismissDevCardFlow() {
        devCardDraft = nil
        currentMode = .idle
        clearBoardSelection()
        manualShelfPresentation = .none
    }

    private func handleBoardTap(_ target: GameBoardTarget, mode: GameMode) {
        let normalizedTarget = normalizedBoardTarget(for: target, mode: mode)

        switch mode {
        case .setup, .buildRoad, .buildSettlement, .buildCity:
            guard let decision = GameBoardCommitCoordinator.decision(
                existingDraft: boardCommitDraft,
                normalizedTarget: normalizedTarget,
                mode: mode
            ) else {
                clearBoardSelection()
                return
            }

            switch decision {
            case let .invalid(hint):
                boardHintText = hint
            case let .selected(draft):
                boardCommitDraft = draft
                selectedBoardTarget = draft.target
                boardHintText = draft.hintText
            case let .confirm(draft):
                publishBoardCommitDraft(draft)
            }
        case .robberMove, .robberVictim:
            guard let normalizedTarget else {
                boardHintText = failureHint(for: mode)
                return
            }
            if viewModel.publishTurnState(for: normalizedTarget, mode: mode) {
                currentMode = .idle
                clearBoardSelection()
                manualShelfPresentation = .none
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
                boardHintText = "Pick victim"
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
            boardHintText = "Pick 2nd road"
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
        if let boardCommitDraft, normalizedTarget != boardCommitDraft.target {
            self.boardCommitDraft = nil
        }
        if normalizedTarget == nil, mode != .idle {
            boardHintText = failureHint(for: mode)
        }
    }

    private func failureHint(for mode: GameMode) -> String? {
        switch mode {
        case .setup:
            return "Tap node"
        case .buildRoad:
            return "Tap road"
        case .buildSettlement:
            return "Tap node"
        case .buildCity:
            return "Tap city"
        case .robberMove:
            return "Tap tile"
        case .robberVictim:
            return "Pick victim"
        case .devCardKnightMove:
            return "Tap tile"
        case .devCardKnightVictim:
            return "Pick victim"
        case .devCardRoadBuildingFirst:
            return "Tap road"
        case .devCardRoadBuildingSecond:
            return "Pick 2nd road"
        case .idle, .trade, .playDevCard, .devCardMonopoly, .devCardYearOfPlenty, .discard:
            return nil
        }
    }

    private func enforceVisibleShelfBounds(
        observedSize: CGSize,
        currentMode: GameMode
    ) {
        let availableHeight = max(observedSize.height - (GameTheme.shellPadding * 2), 0)
        guard !GameShellLayoutMetrics.supportsUtilityShelf(
            availableHeight: availableHeight,
            spacing: GameTheme.sectionSpacing
        ) else {
            return
        }

        if case .utility = resolvedShelfPresentation(mode: currentMode) {
            if currentMode == .trade {
                self.currentMode = .idle
            }
            self.manualShelfPresentation = .none
            clearBoardSelection()
        }
    }

    private func publishBoardCommitDraft(_ draft: GameBoardCommitDraft) {
        let didPublish: Bool
        switch draft.mode {
        case .setup:
            didPublish = viewModel.publishSetupState(for: draft.target)
            if didPublish {
                clearBoardSelection()
            }
        case .buildRoad, .buildSettlement, .buildCity:
            didPublish = viewModel.publishTurnState(for: draft.target, mode: draft.mode)
            if didPublish {
                currentMode = .idle
                manualShelfPresentation = .none
                clearBoardSelection()
            }
        case .idle,
             .robberMove,
             .robberVictim,
             .trade,
             .playDevCard,
             .devCardKnightMove,
             .devCardKnightVictim,
             .devCardMonopoly,
             .devCardYearOfPlenty,
             .devCardRoadBuildingFirst,
             .devCardRoadBuildingSecond,
             .discard:
            didPublish = false
        }

        if !didPublish {
            selectedBoardTarget = draft.target
            boardHintText = draft.hintText
            boardCommitDraft = draft
        }
    }

    private func clearBoardSelection() {
        boardCommitDraft = nil
        selectedBoardTarget = nil
        boardHintText = nil
    }
}

private enum GameShelfPresentation: Equatable {
    case none
    case utility(GameLowerShelf)
    case action(GameLowerShelf)
    case forcedFlow

    var activeShelf: GameLowerShelf? {
        switch self {
        case let .utility(shelf), let .action(shelf):
            return shelf
        case .forcedFlow:
            return .forcedFlow
        case .none:
            return nil
        }
    }

    var selectedDockKind: GameActionDockItem.Kind? {
        switch self {
        case let .action(shelf):
            return shelf.actionKind
        case .none, .utility, .forcedFlow:
            return nil
        }
    }

    var selectedUtilityShelf: GameLowerShelf? {
        if case let .utility(shelf) = self {
            return shelf
        }
        return nil
    }

    var isClosable: Bool {
        switch self {
        case .utility, .action:
            return true
        case .forcedFlow, .none:
            return false
        }
    }
}

private struct GameOverlayShelfView<Content: View>: View {
    let layout: GameShellLayoutMetrics.OverlayShelfMetrics
    let presentation: GameShelfPresentation
    let currentMode: GameMode
    let onSelectUtilityShelf: (GameLowerShelf) -> Void
    let onClose: () -> Void
    let content: Content

    init(
        layout: GameShellLayoutMetrics.OverlayShelfMetrics,
        presentation: GameShelfPresentation,
        currentMode: GameMode,
        onSelectUtilityShelf: @escaping (GameLowerShelf) -> Void,
        onClose: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.layout = layout
        self.presentation = presentation
        self.currentMode = currentMode
        self.onSelectUtilityShelf = onSelectUtilityShelf
        self.onClose = onClose
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            header
                .frame(maxWidth: .infinity, minHeight: layout.headerHeight, maxHeight: layout.headerHeight)

            Divider()
                .overlay(GameTheme.outline.opacity(0.10))

            contentContainer
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .frame(maxWidth: .infinity, minHeight: layout.totalHeight, maxHeight: layout.totalHeight, alignment: .top)
        .background(
            RoundedRectangle(cornerRadius: GameTheme.largeRadius)
                .fill(GameTheme.surface.opacity(0.985))
                .shadow(color: GameTheme.trayShadow.opacity(0.86), radius: 14, x: 0, y: -3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: GameTheme.largeRadius)
                .stroke(GameTheme.outline.opacity(0.14), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: GameTheme.largeRadius))
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    @ViewBuilder
    private var contentContainer: some View {
        if usesScrollContainer {
            ScrollView(.vertical, showsIndicators: false) {
                content
                    .padding(contentPadding)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .scrollBounceBehavior(.basedOnSize)
        } else {
            content
                .padding(contentPadding)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .clipped()
        }
    }

    @ViewBuilder
    private var header: some View {
        switch presentation {
        case let .utility(selectedShelf):
            HStack(spacing: GameTheme.inlineSpacing) {
                ForEach([GameLowerShelf.hand, .bank, .players], id: \.rawValue) { shelf in
                    UtilityHeaderTabButton(
                        title: shelf.title,
                        isSelected: selectedShelf == shelf
                    ) {
                        onSelectUtilityShelf(shelf)
                    }
                }

                if presentation.isClosable {
                    closeButton
                }
            }
            .padding(.horizontal, GameTheme.compactPadding)
        case let .action(shelf):
            HStack(spacing: GameTheme.inlineSpacing) {
                Label(shelf.title, systemImage: shelf.systemImage)
                    .font(GameTheme.metaFont.weight(.semibold))
                    .foregroundStyle(GameTheme.ink)
                    .lineLimit(1)

                Spacer(minLength: 0)

                if presentation.isClosable {
                    closeButton
                }
            }
            .padding(.horizontal, GameTheme.compactPadding)
        case .forcedFlow:
            HStack(spacing: GameTheme.inlineSpacing) {
                Label(currentMode.title, systemImage: "arrow.triangle.2.circlepath")
                    .font(GameTheme.metaFont.weight(.semibold))
                    .foregroundStyle(GameTheme.ink)
                    .lineLimit(1)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, GameTheme.compactPadding)
        case .none:
            EmptyView()
        }
    }

    private var closeButton: some View {
        Button(action: onClose) {
            Image(systemName: "chevron.down")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(GameTheme.mutedInk)
                .frame(width: 28, height: 28)
                .background(GameTheme.surface.opacity(0.9))
                .overlay(
                    Circle()
                        .stroke(GameTheme.outline.opacity(0.12), lineWidth: 1)
                )
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }

    private var usesScrollContainer: Bool {
        switch presentation {
        case .utility:
            return currentMode == .trade
        case let .action(shelf):
            return shelf == .devCards
        case .forcedFlow:
            return true
        case .none:
            return false
        }
    }

    private var contentPadding: CGFloat {
        switch presentation {
        case .utility:
            return GameTheme.inlineSpacing
        case .action, .forcedFlow, .none:
            return GameTheme.compactPadding
        }
    }
}

private struct UtilityHeaderTabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(GameTheme.metaFont.weight(.semibold))
                .foregroundStyle(isSelected ? GameTheme.ink : GameTheme.mutedInk)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 8)
                .padding(.vertical, 7)
                .background(background)
                .overlay(
                    Capsule()
                        .stroke(borderColor, lineWidth: 1)
                )
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var background: Color {
        isSelected ? GameTheme.accent.opacity(0.18) : GameTheme.surface.opacity(0.84)
    }

    private var borderColor: Color {
        isSelected ? GameTheme.accent.opacity(0.40) : GameTheme.outline.opacity(0.12)
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
