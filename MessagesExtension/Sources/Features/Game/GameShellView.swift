import Combine
import SwiftUI
import ULS_CoreGame

struct GameShellView: View {
    let viewModel: LobbyDriverViewModel
    private static let shellResizeFreezeWatchdogNanoseconds: UInt64 = 1_200_000_000

    @State private var shellProjection: GameShellProjection
    @State private var currentMode: GameMode = .idle
    @State private var selectedBoardTarget: GameBoardTarget?
    @State private var boardCommitDraft: GameBoardCommitDraft?
    @State private var boardHintText: String?
    @State private var devCardDraft: GameDevCardDraft?
    @State private var tradeOverlayRoute: GameTradeOverlayRoute?
    @State private var manualShelfPresentation: GameShelfPresentation = .none
    @State private var lastUtilityShelf: GameLowerShelf = .hand
    @State private var shellResizeFreezeSnapshot: GameShellFreezeSnapshot?
    @State private var shellResizeFreezeEpoch: Int = 0
    @State private var shellResizeFreezeTask: Task<Void, Never>?

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
        let boardModel = selectedBoardModel(screenModel: screenModel, mode: resolvedMode)
        let selectionText = resolvedBoardHintText(
            mode: resolvedMode,
            overlayModel: overlayModel
        )
        let freezeShelfStyle = freezeShelfStyle(
            for: shelfPresentation,
            currentMode: resolvedMode
        )
        let selectedDockKind = resolvedMode == .trade ? GameActionDockItem.Kind.trade : shelfPresentation.selectedDockKind
        let selectedHandCounts = tradeSelectedHandCounts(route: tradeOverlayRoute)
        let selectedRecipients = tradeSelectedRecipients(route: tradeOverlayRoute)

        ZStack {
            GameTheme.appBackground
                .ignoresSafeArea()

            GeometryReader { geometry in
                let shellSize = geometry.size
                let shellLayout = GameShellLayoutMetrics.resolve(
                    availableSize: shellSize,
                    spacing: GameTheme.sectionSpacing
                )
                let canPresentUtilityShelf = GameShellLayoutMetrics.supportsUtilityShelf(
                    availableSize: shellSize,
                    spacing: GameTheme.sectionSpacing
                )
                let lowerRailWidth = min(
                    GameShellLayoutMetrics.lowerRailWidth(
                        for: max(shellSize.width - (GameTheme.shellPadding * 2), 0)
                    ),
                    max(shellSize.width - (GameTheme.shellPadding * 2), 0)
                )
                let utilityContentInset = GameTheme.inlineSpacing
                let shelfBodySize = CGSize(
                    width: max(lowerRailWidth - (utilityContentInset * 2), 0),
                    height: max(shellLayout.overlayShelf.contentHeight - (utilityContentInset * 2), 0)
                )
                let tradePanelHeight = GameTradeOverlayLayout.panelHeight(for: lowerRailWidth)
                let isTradePanelPresented = resolvedMode == .trade
                    && projection.tradePanelModel != nil
                    && tradeOverlayRoute != nil
                let shouldShowPendingTradeBanner = !isTradePanelPresented
                    && projection.tradePanelModel?.pendingBannerText != nil
                let boardHintBottomInset = resolvedBoardHintBottomInset(
                    isShelfPresented: isShelfPresented,
                    isTradePanelPresented: isTradePanelPresented,
                    shouldShowPendingTradeBanner: shouldShowPendingTradeBanner,
                    shellLayout: shellLayout,
                    tradePanelHeight: tradePanelHeight
                )

                ZStack(alignment: .topLeading) {
                    ZStack(alignment: .bottom) {
                        VStack(alignment: .leading, spacing: GameTheme.sectionSpacing) {
                            GameHeaderView(model: headerModel)
                                .frame(height: shellLayout.headerHeight, alignment: .topLeading)

                            BoardContainerView(
                                model: boardModel,
                                renderModel: screenModel.boardRenderModel,
                                overlayModel: overlayModel,
                                interactionMode: resolvedMode,
                                selectionText: selectionText,
                                hintBottomInset: boardHintBottomInset,
                                frozenBoardImage: nil,
                                reloadToken: viewModel.boardReloadToken,
                                onInteractionChanged: nil,
                                onDiagnosticsChanged: { snapshot in
                                    viewModel.recordBoardDiagnosticsSnapshot(snapshot)
                                },
                                onGestureEvent: { event in
                                    viewModel.recordHostGestureEvent(event)
                                },
                                onResizeFreezeChanged: { freezeState in
                                    if freezeState.isFrozen {
                                        clearBoardSelection()
                                    }
                                    handleShellResizeFreezeChange(
                                        freezeState,
                                        snapshot: freezeState.snapshot.map { boardImage in
                                            GameShellFreezeSnapshot(
                                                size: shellSize,
                                                layout: shellLayout,
                                                lowerRailWidth: lowerRailWidth,
                                                shelfBodySize: shelfBodySize,
                                                isGameOver: isGameOver,
                                                headerModel: headerModel,
                                                boardModel: boardModel,
                                                boardRenderModel: screenModel.boardRenderModel,
                                                overlayModel: overlayModel,
                                                selectionText: selectionText,
                                                hintBottomInset: boardHintBottomInset,
                                                boardImage: boardImage,
                                                actionDock: screenModel.actionDock,
                                                selectedDockKind: selectedDockKind,
                                                activeLowerShelf: activeLowerShelf,
                                                shelfStyle: freezeShelfStyle,
                                                mode: resolvedMode,
                                                handTray: screenModel.handTray,
                                                bankTray: bankTrayModel,
                                                opponents: screenModel.opponents,
                                                selectedBuildKind: resolvedMode.buildShelfKind,
                                                setupInstruction: projection.setupGuidanceText,
                                                discardPanel: projection.discardPanelModel,
                                                tradePanelModel: projection.tradePanelModel,
                                                devCardPanel: devCardPanelModel,
                                                robberVictimOptions: projection.robberVictimOptions,
                                                tradeOverlayRoute: tradeOverlayRoute,
                                                tradeSelectedHandCounts: selectedHandCounts,
                                                tradeSelectedRecipients: selectedRecipients,
                                                pendingTradeBannerText: projection.tradePanelModel?.pendingBannerText
                                            )
                                        }
                                    )
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
                                    selectedDockKind: selectedDockKind,
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
                        .contentShape(Rectangle())

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
                                    devCardPanel: devCardPanelModel,
                                    robberVictimOptions: projection.robberVictimOptions,
                                    selectedHandCounts: selectedHandCounts,
                                    onSelectHandResource: tradeHandResourceSelectionAction(route: tradeOverlayRoute),
                                    selectedRecipients: selectedRecipients,
                                    onSelectRecipient: tradeRecipientSelectionAction(route: tradeOverlayRoute),
                                    onSelectBuild: { buildKind in
                                        handleBuildShelfSelection(buildKind)
                                    },
                                    onSelectBankResource: { resource in
                                        handleBankResourceSelection(resource, mode: resolvedMode)
                                    },
                                    onDiscardAction: {
                                        guard viewModel.handleDiscardFlowAction() else { return }
                                        selectedBoardTarget = nil
                                    },
                                    onApplySelectedTurnIntent: {
                                        guard viewModel.publishSelectedTurnIntentState() else { return }
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
                            .contentShape(Rectangle())
                        }

                        if !isGameOver, let pendingBannerText = projection.tradePanelModel?.pendingBannerText, shouldShowPendingTradeBanner {
                            GameTradePendingBannerView(text: pendingBannerText) {
                                openTradePanel()
                            }
                            .frame(maxWidth: lowerRailWidth)
                            .padding(.horizontal, GameTheme.shellPadding)
                            .padding(
                                .bottom,
                                tradePanelBottomPadding(
                                    isShelfPresented: isShelfPresented,
                                    shellLayout: shellLayout
                                )
                            )
                            .zIndex(2)
                        }

                        if !isGameOver,
                           let tradePanelModel = projection.tradePanelModel,
                           let tradeOverlayRoute,
                           isTradePanelPresented {
                            GameTradeOverlayView(
                                route: tradeOverlayRoute,
                                panelModel: tradePanelModel,
                                availableWidth: lowerRailWidth,
                                recipientSummaries: screenModel.opponents,
                                onClose: {
                                    closeTradePanel(resetDraft: true)
                                },
                                onChoosePlayerTrade: {
                                    startPlayerTradeDraft()
                                },
                                onChooseMaritimeTrade: {
                                    startMaritimeTrade()
                                },
                                onReplaceOffer: {
                                    startPlayerTradeDraft()
                                },
                                onStartCounterDraft: {
                                    startCounterTradeDraft(using: tradePanelModel)
                                },
                                onApplySelectedResponse: {
                                    guard viewModel.publishSelectedTurnIntentState() else { return }
                                    closeTradePanel(resetDraft: true)
                                    selectedBoardTarget = nil
                                },
                                onSendDraft: {
                                    submitTradeDraft()
                                },
                                onBackDraftStep: {
                                    stepBackTradeDraft()
                                },
                                onNextDraftStep: {
                                    advanceTradeDraft()
                                },
                                onAddGiveResource: { resource in
                                    addGiveResource(resource)
                                },
                                onRemoveGiveResource: { resource in
                                    removeGiveResource(resource)
                                },
                                onAddWantResource: { resource in
                                    addWantResource(resource)
                                },
                                onRemoveWantResource: { resource in
                                    removeWantResource(resource)
                                },
                                onAcceptOffer: {
                                    guard viewModel.sendAcceptTradeIntent() else { return }
                                    closeTradePanel(resetDraft: true)
                                },
                                onDeclineOffer: {
                                    guard viewModel.sendDeclineTradeIntent() else { return }
                                    closeTradePanel(resetDraft: true)
                                },
                                onSendMaritimeTrade: { option in
                                    let give = resourceHand(from: option.give)
                                    let receive = resourceHand(from: option.receive)
                                    guard viewModel.publishMaritimeTrade(give: give, receive: receive) else { return }
                                    closeTradePanel(resetDraft: true)
                                }
                            )
                            .frame(height: tradePanelHeight, alignment: .top)
                            .frame(maxWidth: lowerRailWidth)
                            .padding(.horizontal, GameTheme.shellPadding)
                            .padding(
                                .bottom,
                                tradePanelBottomPadding(
                                    isShelfPresented: isShelfPresented,
                                    shellLayout: shellLayout
                                )
                            )
                            .zIndex(3)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .opacity(shellResizeFreezeSnapshot == nil ? 1 : 0)
                    .allowsHitTesting(shellResizeFreezeSnapshot == nil)

                    if let shellResizeFreezeSnapshot {
                        GameShellFreezeOverlayView(snapshot: shellResizeFreezeSnapshot)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                            .clipped()
                            .zIndex(10)
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
                        observedSize: shellSize,
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
            synchronizeTradeOverlay(with: projection)
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
            if newMode != .trade {
                tradeOverlayRoute = nil
            }
        }
        .onChange(of: screenModel.boardRenderModel) { _, _ in
            synchronizeBoardSelection(mode: resolvedMode)
        }
        .onDisappear {
            clearShellResizeFreeze()
        }
    }

    private func resolvedShelfPresentation(mode: GameMode) -> GameShelfPresentation {
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
            switch manualShelfPresentation {
            case let .utility(shelf):
                return .utility(shelf)
            default:
                return .utility(lastUtilityShelf)
            }
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
            if currentMode == .trade {
                closeTradePanel(resetDraft: true)
            } else {
                openTradePanel()
            }
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
        if currentMode == .trade {
            guard canPresentUtilityShelf else {
                closeTradePanel(resetDraft: true)
                return
            }
            manualShelfPresentation = .utility(lastUtilityShelf)
            clearBoardSelection()
            return
        }

        let presentation = resolvedShelfPresentation(mode: currentMode)
        if case .utility = presentation {
            self.manualShelfPresentation = .none
        } else {
            guard canPresentUtilityShelf else {
                return
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

        if currentMode == .trade {
            self.manualShelfPresentation = .utility(shelf)
        } else if resolvedShelfPresentation(mode: currentMode) == .utility(shelf) {
            self.manualShelfPresentation = .none
        } else {
            self.manualShelfPresentation = .utility(shelf)
        }
        clearBoardSelection()
    }

    private func handleCloseShelf(currentMode: GameMode) {
        switch resolvedShelfPresentation(mode: currentMode) {
        case .utility:
            if currentMode == .trade {
                closeTradePanel(resetDraft: true)
            } else {
                self.manualShelfPresentation = .none
            }
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
        if currentMode == .trade {
            closeTradePanel(resetDraft: true)
        } else {
            openTradePanel()
        }
    }

    private func openTradePanel() {
        guard shellProjection.tradePanelModel != nil else {
            return
        }

        currentMode = .trade
        if case .utility = manualShelfPresentation {
            // Preserve the visible shelf.
        } else {
            lastUtilityShelf = .hand
            manualShelfPresentation = .utility(.hand)
        }

        if shellProjection.tradePanelModel?.activeOffer != nil {
            tradeOverlayRoute = .liveOffer
        } else {
            tradeOverlayRoute = .chooser
        }
        clearBoardSelection()
    }

    private func closeTradePanel(resetDraft: Bool) {
        currentMode = .idle
        if resetDraft {
            tradeOverlayRoute = nil
        }
        clearBoardSelection()
    }

    private func startPlayerTradeDraft() {
        tradeOverlayRoute = .playerDraft(
            GameTradeDraft(
                kind: .offer,
                step: .give,
                give: .zero,
                receive: .zero,
                recipients: []
            )
        )
        lastUtilityShelf = .hand
        manualShelfPresentation = .utility(.hand)
        clearBoardSelection()
    }

    private func startCounterTradeDraft(using panelModel: GameTradePanelModel) {
        guard let offer = panelModel.activeOffer else {
            return
        }

        tradeOverlayRoute = .playerDraft(
            GameTradeDraft(
                kind: .counter(originalProposerID: offer.proposerPlayerID),
                step: .give,
                give: .zero,
                receive: .zero,
                recipients: [offer.proposerPlayerID]
            )
        )
        lastUtilityShelf = .hand
        manualShelfPresentation = .utility(.hand)
        clearBoardSelection()
    }

    private func startMaritimeTrade() {
        tradeOverlayRoute = .maritime
        clearBoardSelection()
    }

    private func advanceTradeDraft() {
        guard case let .playerDraft(draft)? = tradeOverlayRoute else {
            return
        }

        var nextDraft = draft
        switch draft.step {
        case .give:
            guard !draft.give.isZero else { return }
            nextDraft.step = .want
            lastUtilityShelf = .hand
            manualShelfPresentation = .utility(.hand)
        case .want:
            guard !draft.receive.isZero else { return }
            nextDraft.step = .recipients
            lastUtilityShelf = .players
            manualShelfPresentation = .utility(.players)
        case .recipients:
            submitTradeDraft()
            return
        }
        tradeOverlayRoute = .playerDraft(nextDraft)
        clearBoardSelection()
    }

    private func stepBackTradeDraft() {
        switch tradeOverlayRoute {
        case .chooser, nil:
            closeTradePanel(resetDraft: true)
        case .maritime:
            tradeOverlayRoute = .chooser
        case let .playerDraft(draft):
            var previousDraft = draft
            switch draft.step {
            case .give:
                closeTradePanel(resetDraft: true)
                return
            case .want:
                previousDraft.step = .give
                lastUtilityShelf = .hand
                manualShelfPresentation = .utility(.hand)
            case .recipients:
                previousDraft.step = .want
                lastUtilityShelf = .hand
                manualShelfPresentation = .utility(.hand)
            }
            tradeOverlayRoute = .playerDraft(previousDraft)
        case .liveOffer:
            closeTradePanel(resetDraft: true)
        }
        clearBoardSelection()
    }

    private func submitTradeDraft() {
        guard case let .playerDraft(draft)? = tradeOverlayRoute else {
            return
        }

        let didSend: Bool
        switch draft.kind {
        case .offer:
            didSend = viewModel.publishTradeOffer(
                give: draft.give,
                receive: draft.receive,
                targetPlayers: draft.recipients
            )
        case .counter:
            didSend = viewModel.sendCounterTradeIntent(
                give: draft.give,
                receive: draft.receive
            )
        }

        guard didSend else {
            return
        }

        closeTradePanel(resetDraft: true)
        selectedBoardTarget = nil
    }

    private func addGiveResource(_ resource: ResourceV1) {
        guard case let .playerDraft(draft)? = tradeOverlayRoute, draft.step == .give else {
            return
        }
        let available = tradeResourceCount(resource, in: shellProjection.gameScreenModel.handTray.chips)
        let selected = tradeResourceCount(resource, in: draft.give)
        guard selected < available else {
            return
        }

        mutateTradeDraft { draft in
            draft.give = updating(resource: resource, in: draft.give, delta: 1)
        }
    }

    private func removeGiveResource(_ resource: ResourceV1) {
        mutateTradeDraft { draft in
            draft.give = updating(resource: resource, in: draft.give, delta: -1)
        }
    }

    private func addWantResource(_ resource: ResourceV1) {
        mutateTradeDraft { draft in
            draft.receive = updating(resource: resource, in: draft.receive, delta: 1)
        }
    }

    private func removeWantResource(_ resource: ResourceV1) {
        mutateTradeDraft { draft in
            draft.receive = updating(resource: resource, in: draft.receive, delta: -1)
        }
    }

    private func mutateTradeDraft(_ mutate: (inout GameTradeDraft) -> Void) {
        guard case let .playerDraft(draft)? = tradeOverlayRoute else {
            return
        }

        var nextDraft = draft
        mutate(&nextDraft)
        tradeOverlayRoute = .playerDraft(nextDraft)
    }

    private func tradeHandResourceSelectionAction(route: GameTradeOverlayRoute?) -> ((ResourceV1) -> Void)? {
        guard case let .playerDraft(draft)? = route, draft.step == .give else {
            return nil
        }
        return { resource in
            addGiveResource(resource)
        }
    }

    private func tradeRecipientSelectionAction(route: GameTradeOverlayRoute?) -> ((String) -> Void)? {
        guard case let .playerDraft(draft)? = route, draft.step == .recipients else {
            return nil
        }
        if draft.isCounter {
            return nil
        }
        return { playerID in
            mutateTradeDraft { draft in
                if let existingIndex = draft.recipients.firstIndex(of: playerID) {
                    draft.recipients.remove(at: existingIndex)
                } else {
                    draft.recipients.append(playerID)
                    draft.recipients.sort()
                }
            }
        }
    }

    private func tradeSelectedHandCounts(route: GameTradeOverlayRoute?) -> [ResourceV1: Int] {
        guard case let .playerDraft(draft)? = route, draft.step == .give else {
            return [:]
        }
        return tradeCountMap(for: draft.give)
    }

    private func tradeSelectedRecipients(route: GameTradeOverlayRoute?) -> Set<String> {
        guard case let .playerDraft(draft)? = route, draft.step == .recipients else {
            return []
        }
        return Set(draft.recipients)
    }

    private func tradeCountMap(for hand: ResourceHandV1) -> [ResourceV1: Int] {
        [
            .wood: hand.wood,
            .brick: hand.brick,
            .sheep: hand.sheep,
            .wheat: hand.wheat,
            .ore: hand.ore,
        ]
        .filter { $0.value > 0 }
    }

    private func tradeResourceCount(_ resource: ResourceV1, in chips: [GameHandChip]) -> Int {
        chips.first(where: { $0.resource == resource })?.count ?? 0
    }

    private func tradeResourceCount(_ resource: ResourceV1, in hand: ResourceHandV1) -> Int {
        switch resource {
        case .wood:
            return hand.wood
        case .brick:
            return hand.brick
        case .sheep:
            return hand.sheep
        case .wheat:
            return hand.wheat
        case .ore:
            return hand.ore
        case .desert:
            return 0
        }
    }

    private func updating(resource: ResourceV1, in hand: ResourceHandV1, delta: Int) -> ResourceHandV1 {
        ResourceHandV1(
            wood: resource == .wood ? max(hand.wood + delta, 0) : hand.wood,
            brick: resource == .brick ? max(hand.brick + delta, 0) : hand.brick,
            sheep: resource == .sheep ? max(hand.sheep + delta, 0) : hand.sheep,
            wheat: resource == .wheat ? max(hand.wheat + delta, 0) : hand.wheat,
            ore: resource == .ore ? max(hand.ore + delta, 0) : hand.ore
        )
    }

    private func resourceHand(from chips: [GameHandChip]) -> ResourceHandV1 {
        let wood = chips.first(where: { $0.resource == .wood })?.count ?? 0
        let brick = chips.first(where: { $0.resource == .brick })?.count ?? 0
        let sheep = chips.first(where: { $0.resource == .sheep })?.count ?? 0
        let wheat = chips.first(where: { $0.resource == .wheat })?.count ?? 0
        let ore = chips.first(where: { $0.resource == .ore })?.count ?? 0

        return ResourceHandV1(
            wood: wood,
            brick: brick,
            sheep: sheep,
            wheat: wheat,
            ore: ore
        )
    }

    private func synchronizeTradeOverlay(with projection: GameShellProjection) {
        guard currentMode == .trade else {
            return
        }

        guard let tradePanelModel = projection.tradePanelModel else {
            tradeOverlayRoute = nil
            currentMode = .idle
            return
        }

        switch tradeOverlayRoute {
        case .none:
            tradeOverlayRoute = tradePanelModel.activeOffer != nil ? .liveOffer : .chooser
        case .liveOffer where tradePanelModel.activeOffer == nil:
            tradeOverlayRoute = .chooser
        default:
            break
        }
    }

    private func resolvedBoardHintBottomInset(
        isShelfPresented: Bool,
        isTradePanelPresented: Bool,
        shouldShowPendingTradeBanner: Bool,
        shellLayout: GameShellLayoutMetrics,
        tradePanelHeight: CGFloat
    ) -> CGFloat {
        if isTradePanelPresented {
            let baseInset = isShelfPresented
                ? shellLayout.overlayShelf.overlapIntoBoardHeight
                : 0
            return baseInset + tradePanelHeight + GameTradeOverlayLayout.verticalSpacing + 12
        }

        if shouldShowPendingTradeBanner {
            let baseInset = isShelfPresented
                ? shellLayout.overlayShelf.overlapIntoBoardHeight
                : 0
            return max(baseInset + GameTradeOverlayLayout.bannerHeight + GameTradeOverlayLayout.verticalSpacing + 8, 18)
        }

        return isShelfPresented
            ? shellLayout.overlayShelf.overlapIntoBoardHeight + 12
            : 18
    }

    private func tradePanelBottomPadding(
        isShelfPresented: Bool,
        shellLayout: GameShellLayoutMetrics
    ) -> CGFloat {
        let shelfOffset = isShelfPresented
            ? shellLayout.trayHeight + shellLayout.overlayShelf.overlapIntoBoardHeight
            : shellLayout.trayHeight
        return GameTheme.shellPadding + shelfOffset + GameTradeOverlayLayout.verticalSpacing
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
        guard !GameShellLayoutMetrics.supportsUtilityShelf(
            availableSize: observedSize,
            spacing: GameTheme.sectionSpacing
        ) else {
            return
        }

        if case .utility = resolvedShelfPresentation(mode: currentMode) {
            if currentMode == .trade {
                closeTradePanel(resetDraft: true)
            } else {
                self.manualShelfPresentation = .none
            }
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

    private func handleShellResizeFreezeChange(
        _ state: BoardResizeFreezeState,
        snapshot: GameShellFreezeSnapshot?
    ) {
        shellResizeFreezeTask?.cancel()

        guard state.isFrozen, let snapshot else {
            clearShellResizeFreeze()
            return
        }

        shellResizeFreezeEpoch += 1
        let epoch = shellResizeFreezeEpoch
        shellResizeFreezeSnapshot = snapshot
        shellResizeFreezeTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: Self.shellResizeFreezeWatchdogNanoseconds)
            guard !Task.isCancelled, shellResizeFreezeEpoch == epoch else {
                return
            }
            clearShellResizeFreeze()
        }
    }

    private func clearShellResizeFreeze() {
        shellResizeFreezeTask?.cancel()
        shellResizeFreezeTask = nil
        shellResizeFreezeSnapshot = nil
    }

    private func freezeShelfStyle(
        for presentation: GameShelfPresentation,
        currentMode: GameMode
    ) -> GameShellFreezeShelfStyle {
        switch presentation {
        case let .utility(selectedShelf):
            return .utility(selected: selectedShelf)
        case let .action(shelf):
            return .action(shelf: shelf)
        case .forcedFlow:
            return .forcedFlow(title: currentMode.title)
        case .none:
            return .utility(selected: lastUtilityShelf)
        }
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
        .contentShape(RoundedRectangle(cornerRadius: GameTheme.largeRadius))
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
            return currentMode == .trade || layout.contentHeight < GameShellLayoutMetrics.minimumUtilityShelfScrollHeight
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

enum GameTradeOverlayLayout {
    static func panelHeight(for availableWidth: CGFloat) -> CGFloat {
        availableWidth >= 520 ? 252 : 224
    }

    static let bannerHeight: CGFloat = 44
    static let verticalSpacing: CGFloat = 10
}

enum GameTradeOverlayRoute: Equatable {
    case chooser
    case playerDraft(GameTradeDraft)
    case maritime
    case liveOffer
}

struct GameTradeDraft: Equatable {
    enum Kind: Equatable {
        case offer
        case counter(originalProposerID: String)
    }

    enum Step: Int, CaseIterable, Equatable {
        case give
        case want
        case recipients
    }

    var kind: Kind
    var step: Step
    var give: ResourceHandV1
    var receive: ResourceHandV1
    var recipients: [String]

    var isCounter: Bool {
        if case .counter = kind {
            return true
        }
        return false
    }
}

struct GameTradeOverlayView: View {
    let route: GameTradeOverlayRoute
    let panelModel: GameTradePanelModel
    let availableWidth: CGFloat
    let recipientSummaries: [GameOpponentSummary]
    let onClose: () -> Void
    let onChoosePlayerTrade: () -> Void
    let onChooseMaritimeTrade: () -> Void
    let onReplaceOffer: () -> Void
    let onStartCounterDraft: () -> Void
    let onApplySelectedResponse: () -> Void
    let onSendDraft: () -> Void
    let onBackDraftStep: () -> Void
    let onNextDraftStep: () -> Void
    let onAddGiveResource: (ResourceV1) -> Void
    let onRemoveGiveResource: (ResourceV1) -> Void
    let onAddWantResource: (ResourceV1) -> Void
    let onRemoveWantResource: (ResourceV1) -> Void
    let onAcceptOffer: () -> Void
    let onDeclineOffer: () -> Void
    let onSendMaritimeTrade: (GameTradeMaritimeOption) -> Void

    private let tradeableResources: [ResourceV1] = [.wood, .brick, .sheep, .wheat, .ore]

    var body: some View {
        let density = ResourceChipDensity.resolve(
            availableWidth: max(availableWidth - (GameTheme.compactPadding * 2), 0),
            availableHeight: 160
        )

        VStack(alignment: .leading, spacing: GameTheme.inlineSpacing) {
            header

            switch route {
            case .chooser:
                chooserBody
            case let .playerDraft(draft):
                composerBody(draft: draft, density: density)
            case .maritime:
                maritimeBody
            case .liveOffer:
                liveOfferBody
            }
        }
        .padding(GameTheme.compactPadding)
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
        .contentShape(RoundedRectangle(cornerRadius: GameTheme.largeRadius))
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private var header: some View {
        HStack(alignment: .top, spacing: GameTheme.inlineSpacing) {
            VStack(alignment: .leading, spacing: 4) {
                Text(titleText)
                    .font(GameTheme.headingFont)
                    .foregroundStyle(GameTheme.ink)

                Text(panelModel.message)
                    .font(GameTheme.metaFont)
                    .foregroundStyle(GameTheme.mutedInk)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(GameTheme.mutedInk)
                    .frame(width: 28, height: 28)
                    .background(GameTheme.surface.opacity(0.88))
                    .overlay(
                        Circle()
                            .stroke(GameTheme.outline.opacity(0.14), lineWidth: 1)
                    )
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
    }

    private var chooserBody: some View {
        VStack(alignment: .leading, spacing: GameTheme.inlineSpacing) {
            chooserCard(
                title: "Player Trade",
                detail: "Build what you give, what you want, and who should see the offer.",
                systemImage: "person.2.fill",
                action: onChoosePlayerTrade
            )

            chooserCard(
                title: "Maritime / Bank",
                detail: panelModel.maritimeOptions.isEmpty
                    ? "No legal port or bank trades are available from your current hand."
                    : "Pick from the legal mixed list of quick trades.",
                systemImage: "ferry.fill",
                isDisabled: panelModel.maritimeOptions.isEmpty,
                action: onChooseMaritimeTrade
            )
        }
    }

    private func composerBody(
        draft: GameTradeDraft,
        density: ResourceChipDensity
    ) -> some View {
        VStack(alignment: .leading, spacing: GameTheme.inlineSpacing) {
            breadcrumbRow(for: draft)

            switch draft.step {
            case .give:
                VStack(alignment: .leading, spacing: GameTheme.inlineSpacing) {
                    Text("Tap resources in your hand below to add them to the offer.")
                        .font(GameTheme.metaFont)
                        .foregroundStyle(GameTheme.mutedInk)
                        .fixedSize(horizontal: false, vertical: true)

                    editableResourceSection(
                        title: "You Give",
                        hand: draft.give,
                        density: density,
                        action: onRemoveGiveResource
                    )
                }
            case .want:
                VStack(alignment: .leading, spacing: GameTheme.inlineSpacing) {
                    Text("Ask for any resource type, even if you do not hold one right now.")
                        .font(GameTheme.metaFont)
                        .foregroundStyle(GameTheme.mutedInk)
                        .fixedSize(horizontal: false, vertical: true)

                    resourcePickerRow(
                        title: "You Want",
                        selection: draft.receive,
                        density: density,
                        onAdd: onAddWantResource
                    )

                    editableResourceSection(
                        title: "Requested",
                        hand: draft.receive,
                        density: density,
                        action: onRemoveWantResource
                    )
                }
            case .recipients:
                VStack(alignment: .leading, spacing: GameTheme.inlineSpacing) {
                    Text(recipientCopy(for: draft))
                        .font(GameTheme.metaFont)
                        .foregroundStyle(GameTheme.mutedInk)
                        .fixedSize(horizontal: false, vertical: true)

                    recipientSummaryRow(draft.recipients)
                    draftSummary(draft: draft)
                }
            }

            if draft.step != .recipients {
                draftSummary(draft: draft)
            }

            HStack(spacing: GameTheme.inlineSpacing) {
                Button(draft.step == .give ? "Cancel" : "Back") {
                    onBackDraftStep()
                }
                .frame(maxWidth: .infinity)
                .buttonStyle(.bordered)

                Button(primaryDraftButtonTitle(for: draft)) {
                    if draft.step == .recipients {
                        onSendDraft()
                    } else {
                        onNextDraftStep()
                    }
                }
                .frame(maxWidth: .infinity)
                .buttonStyle(.borderedProminent)
                .disabled(!canAdvance(draft: draft))
            }
        }
    }

    private var maritimeBody: some View {
        VStack(alignment: .leading, spacing: GameTheme.inlineSpacing) {
            if panelModel.maritimeOptions.isEmpty {
                Text("No legal maritime or bank trades are available right now.")
                    .font(GameTheme.metaFont)
                    .foregroundStyle(GameTheme.mutedInk)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                ForEach(panelModel.maritimeOptions) { option in
                    Button {
                        onSendMaritimeTrade(option)
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Give \(compactChipLine(option.give)) for \(compactChipLine(option.receive))")
                                .font(GameTheme.metaFont.weight(.semibold))
                                .foregroundStyle(GameTheme.ink)
                            Text("\(option.ratio):1 trade")
                                .font(GameTheme.metaFont)
                                .foregroundStyle(GameTheme.mutedInk)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.bordered)
                }
            }

            Button("Back") {
                onBackDraftStep()
            }
            .frame(maxWidth: .infinity)
            .buttonStyle(.bordered)
        }
    }

    private var liveOfferBody: some View {
        VStack(alignment: .leading, spacing: GameTheme.inlineSpacing) {
            if let activeOffer = panelModel.activeOffer {
                offerCard(activeOffer)
            }

            if let selectedResponse = panelModel.selectedResponse {
                selectedResponseCard(selectedResponse)
            }

            if !panelModel.participantStatuses.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Responses")
                        .font(GameTheme.metaFont.weight(.semibold))
                        .foregroundStyle(GameTheme.ink)

                    ForEach(panelModel.participantStatuses) { status in
                        participantStatusRow(status)
                    }
                }
            }

            if let responderActions = panelModel.responderActions {
                responderActionRow(responderActions)
            }

            if panelModel.selectedResponse != nil {
                Button("Apply Selected Response") {
                    onApplySelectedResponse()
                }
                .frame(maxWidth: .infinity)
                .buttonStyle(.borderedProminent)
            } else if panelModel.canReplaceOffer {
                Button("Replace Offer") {
                    onReplaceOffer()
                }
                .frame(maxWidth: .infinity)
                .buttonStyle(.bordered)
            }
        }
    }

    private var titleText: String {
        switch route {
        case .chooser:
            return "Trade"
        case let .playerDraft(draft):
            return draft.isCounter ? "Counter Trade" : "Player Trade"
        case .maritime:
            return "Maritime / Bank"
        case .liveOffer:
            return panelModel.roleTitle
        }
    }

    private func chooserCard(
        title: String,
        detail: String,
        systemImage: String,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: GameTheme.inlineSpacing) {
                Image(systemName: systemImage)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(isDisabled ? GameTheme.mutedInk : GameTheme.accent)
                    .frame(width: 20, height: 20)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(GameTheme.metaFont.weight(.semibold))
                        .foregroundStyle(GameTheme.ink)
                    Text(detail)
                        .font(GameTheme.metaFont)
                        .foregroundStyle(GameTheme.mutedInk)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(GameTheme.compactPadding)
            .background(GameTheme.surface.opacity(0.92))
            .overlay(
                RoundedRectangle(cornerRadius: GameTheme.mediumRadius)
                    .stroke(GameTheme.outline.opacity(0.14), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: GameTheme.mediumRadius))
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.68 : 1)
    }

    private func breadcrumbRow(for draft: GameTradeDraft) -> some View {
        HStack(spacing: 6) {
            ForEach(Array(GameTradeDraft.Step.allCases.enumerated()), id: \.offset) { _, step in
                let isCurrent = step == draft.step
                Text(stepLabel(step, for: draft))
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(isCurrent ? .white : GameTheme.mutedInk)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(isCurrent ? GameTheme.accent : GameTheme.surface.opacity(0.9))
                    .overlay(
                        Capsule()
                            .stroke(isCurrent ? GameTheme.accent : GameTheme.outline.opacity(0.14), lineWidth: 1)
                    )
                    .clipShape(Capsule())
            }
        }
    }

    private func editableResourceSection(
        title: String,
        hand: ResourceHandV1,
        density: ResourceChipDensity,
        action: @escaping (ResourceV1) -> Void
    ) -> some View {
        let chips = chips(from: hand)

        return VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(GameTheme.metaFont.weight(.semibold))
                .foregroundStyle(GameTheme.ink)

            if chips.isEmpty {
                Text("Nothing selected yet.")
                    .font(GameTheme.metaFont)
                    .foregroundStyle(GameTheme.mutedInk)
            } else {
                ResourceChipGridView(items: chips, density: density) { chip in
                    ResourceCountChipView(
                        resource: chip.resource,
                        label: chip.shortLabel,
                        count: chip.count,
                        isEnabled: true,
                        isSelected: true,
                        selectionBadge: nil,
                        detailBadge: "-",
                        density: density,
                        action: {
                            action(chip.resource)
                        },
                        accessibilityLabel: "\(chip.shortLabel) \(chip.count)"
                    )
                }
            }
        }
    }

    private func resourcePickerRow(
        title: String,
        selection: ResourceHandV1,
        density: ResourceChipDensity,
        onAdd: @escaping (ResourceV1) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(GameTheme.metaFont.weight(.semibold))
                .foregroundStyle(GameTheme.ink)

            ResourceChipGridView(
                items: tradeableResources.map { GameHandChip(resource: $0, count: count(for: $0, in: selection)) },
                density: density
            ) { chip in
                ResourceCountChipView(
                    resource: chip.resource,
                    label: chip.shortLabel,
                    count: chip.count,
                    isEnabled: true,
                    isSelected: chip.count > 0,
                    selectionBadge: nil,
                    detailBadge: "+",
                    density: density,
                    action: {
                        onAdd(chip.resource)
                    },
                    accessibilityLabel: "\(chip.shortLabel) \(chip.count)"
                )
            }
        }
    }

    private func draftSummary(draft: GameTradeDraft) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            summaryLine(title: "Give", value: compactHandDescription(draft.give))
            summaryLine(title: "Want", value: compactHandDescription(draft.receive))
            summaryLine(title: "To", value: recipientSummaryText(draft.recipients))
        }
        .padding(GameTheme.compactPadding)
        .background(GameTheme.surface.opacity(0.92))
        .overlay(
            RoundedRectangle(cornerRadius: GameTheme.mediumRadius)
                .stroke(GameTheme.outline.opacity(0.14), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: GameTheme.mediumRadius))
    }

    private func offerCard(_ offer: GameTradeOfferSummary) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(offer.proposerDisplay)
                .font(GameTheme.metaFont.weight(.semibold))
                .foregroundStyle(GameTheme.ink)
            Text(offer.recipientsLabel)
                .font(GameTheme.metaFont)
                .foregroundStyle(GameTheme.mutedInk)
            Text("\(offer.giveLabel): \(compactChipLine(offer.give))")
                .font(GameTheme.metaFont)
                .foregroundStyle(GameTheme.ink)
            Text("\(offer.receiveLabel): \(compactChipLine(offer.receive))")
                .font(GameTheme.metaFont)
                .foregroundStyle(GameTheme.ink)
        }
        .padding(GameTheme.compactPadding)
        .background(GameTheme.surface.opacity(0.92))
        .overlay(
            RoundedRectangle(cornerRadius: GameTheme.mediumRadius)
                .stroke(GameTheme.outline.opacity(0.14), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: GameTheme.mediumRadius))
    }

    private func selectedResponseCard(_ selectedResponse: GameTradeSelectedResponseSummary) -> some View {
        HStack(alignment: .center, spacing: GameTheme.inlineSpacing) {
            Image(systemName: "arrowshape.turn.up.left.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(GameTheme.accent)

            Text("\(selectedResponse.displayName) sent a \(selectedResponse.kind.rawValue).")
                .font(GameTheme.metaFont.weight(.semibold))
                .foregroundStyle(GameTheme.ink)

            Spacer(minLength: 0)
        }
        .padding(GameTheme.compactPadding)
        .background(GameTheme.surface.opacity(0.92))
        .overlay(
            RoundedRectangle(cornerRadius: GameTheme.mediumRadius)
                .stroke(GameTheme.outline.opacity(0.14), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: GameTheme.mediumRadius))
    }

    private func participantStatusRow(_ status: GameTradeParticipantStatus) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: GameTheme.inlineSpacing) {
                Text(status.displayName)
                    .font(GameTheme.metaFont.weight(.semibold))
                    .foregroundStyle(GameTheme.ink)

                if status.isTargeted {
                    Text("Targeted")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(GameTheme.accent)
                        .clipShape(Capsule())
                }

                Spacer(minLength: 0)

                Text(status.detailText)
                    .font(GameTheme.metaFont)
                    .foregroundStyle(GameTheme.mutedInk)
            }

            if status.state == .countered {
                Text("Counter: \(compactChipLine(status.counterGive)) for \(compactChipLine(status.counterReceive))")
                    .font(GameTheme.metaFont)
                    .foregroundStyle(GameTheme.mutedInk)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, GameTheme.compactPadding)
        .padding(.vertical, 8)
        .background(GameTheme.surface.opacity(0.88))
        .overlay(
            RoundedRectangle(cornerRadius: GameTheme.smallRadius)
                .stroke(GameTheme.outline.opacity(0.12), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: GameTheme.smallRadius))
    }

    private func responderActionRow(_ responderActions: GameTradeResponderActions) -> some View {
        HStack(spacing: GameTheme.inlineSpacing) {
            Button("Accept") {
                onAcceptOffer()
            }
            .frame(maxWidth: .infinity)
            .buttonStyle(.borderedProminent)
            .disabled(!responderActions.canAccept)

            Button("Decline") {
                onDeclineOffer()
            }
            .frame(maxWidth: .infinity)
            .buttonStyle(.bordered)
            .disabled(!responderActions.canDecline)

            Button("Counter") {
                onStartCounterDraft()
            }
            .frame(maxWidth: .infinity)
            .buttonStyle(.bordered)
            .disabled(!responderActions.canCounter)
        }
    }

    private func recipientSummaryRow(_ recipients: [String]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Selected recipients")
                .font(GameTheme.metaFont.weight(.semibold))
                .foregroundStyle(GameTheme.ink)

            if recipients.isEmpty {
                Text("Nobody selected yet.")
                    .font(GameTheme.metaFont)
                    .foregroundStyle(GameTheme.mutedInk)
            } else {
                Text(recipientSummaryText(recipients))
                    .font(GameTheme.metaFont)
                    .foregroundStyle(GameTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func recipientCopy(for draft: GameTradeDraft) -> String {
        switch draft.kind {
        case .offer:
            return "The Players shelf is live. Tap one or more opponents there, then send the offer from here."
        case let .counter(originalProposerID):
            let proposer = recipientSummaries.first(where: { $0.id == originalProposerID })?.displayName
                ?? panelModel.activeOffer?.proposerDisplay
                ?? "the proposer"
            return "Counters go back only to \(proposer)."
        }
    }

    private func primaryDraftButtonTitle(for draft: GameTradeDraft) -> String {
        if draft.step == .recipients {
            return draft.isCounter ? "Send Counter" : "Send Offer"
        }
        return "Next"
    }

    private func canAdvance(draft: GameTradeDraft) -> Bool {
        switch draft.step {
        case .give:
            return !draft.give.isZero
        case .want:
            return !draft.receive.isZero
        case .recipients:
            return !draft.give.isZero && !draft.receive.isZero && !draft.recipients.isEmpty
        }
    }

    private func stepLabel(_ step: GameTradeDraft.Step, for draft: GameTradeDraft) -> String {
        switch step {
        case .give:
            return "Give"
        case .want:
            return "Want"
        case .recipients:
            if case let .counter(originalProposerID) = draft.kind {
                let proposer = recipientSummaries.first(where: { $0.id == originalProposerID })?.displayName ?? "Proposer"
                return "To \(proposer)"
            }
            return "Send"
        }
    }

    private func summaryLine(title: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(title)
                .font(GameTheme.metaFont.weight(.semibold))
                .foregroundStyle(GameTheme.ink)

            Text(value)
                .font(GameTheme.metaFont)
                .foregroundStyle(GameTheme.mutedInk)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func chips(from hand: ResourceHandV1) -> [GameHandChip] {
        tradeableResources
            .map { GameHandChip(resource: $0, count: count(for: $0, in: hand)) }
            .filter { $0.count > 0 }
    }

    private func compactChipLine(_ chips: [GameHandChip]) -> String {
        if chips.isEmpty {
            return "nothing"
        }
        return chips.map { "\($0.count) \($0.shortLabel.lowercased())" }.joined(separator: ", ")
    }

    private func compactHandDescription(_ hand: ResourceHandV1) -> String {
        compactChipLine(chips(from: hand))
    }

    private func recipientSummaryText(_ recipients: [String]) -> String {
        if recipients.isEmpty {
            return "nobody"
        }
        return recipients
            .compactMap { id in
                recipientSummaries.first(where: { $0.id == id })?.displayName
                    ?? panelModel.activeOffer?.proposerDisplay
            }
            .joined(separator: ", ")
    }

    private func count(for resource: ResourceV1, in hand: ResourceHandV1) -> Int {
        switch resource {
        case .wood:
            return hand.wood
        case .brick:
            return hand.brick
        case .sheep:
            return hand.sheep
        case .wheat:
            return hand.wheat
        case .ore:
            return hand.ore
        case .desert:
            return 0
        }
    }
}

struct GameTradePendingBannerView: View {
    let text: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: GameTheme.inlineSpacing) {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(GameTheme.accent)

                Text(text)
                    .font(GameTheme.metaFont.weight(.semibold))
                    .foregroundStyle(GameTheme.ink)
                    .lineLimit(1)

                Spacer(minLength: 0)

                Text("Open")
                    .font(GameTheme.metaFont)
                    .foregroundStyle(GameTheme.mutedInk)
            }
            .padding(.horizontal, GameTheme.compactPadding)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: GameTheme.mediumRadius)
                    .fill(GameTheme.surface.opacity(0.96))
            )
            .overlay(
                RoundedRectangle(cornerRadius: GameTheme.mediumRadius)
                    .stroke(GameTheme.outline.opacity(0.14), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: GameTheme.mediumRadius))
        }
        .buttonStyle(.plain)
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

private extension ResourceHandV1 {
    var isZero: Bool {
        wood == 0 && brick == 0 && sheep == 0 && wheat == 0 && ore == 0
    }
}
