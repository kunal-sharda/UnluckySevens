import Combine
import SwiftUI
import ULS_CoreGame

struct GameShellView: View {
    private static let displayCoordinateSpaceName = "uls.gameShell.display"

    let viewModel: LobbyDriverViewModel
    let onSettingsTap: () -> Void
    let onGamesTap: () -> Void
    let preferences: AppPreferences
    private let initialModeOnReset: GameMode
    private let initialRouteOnReset: GameShellRoute
    private let minimumActionSurfaceHeight: CGFloat?
    private let tutorialTradeTarget: GameTutorialTarget?
    private let tutorialHeaderTitle: String?

    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var shellProjection: GameShellProjection
    @State private var currentMode: GameMode = .idle
    @State private var selectedBoardTarget: GameBoardTarget?
    @State private var boardCommitDraft: GameBoardCommitDraft?
    @State private var boardHintText: String?
    @State private var discardDraft: ResourceHandV1 = .zero
    @State private var devCardDraft: GameDevCardDraft?
    @State private var shellRoute: GameShellRoute = .none
    @State private var isHandOpen = true
    @State private var physicalBankCountsRevealed = false
    @State private var normalTurnContextSnapshot: GameNormalTurnContextSnapshot
    @State private var physicalBoardCenteringOffset: CGFloat = 0
    @State private var physicalBoardMeasuredFrame: CGRect = .zero
    @State private var physicalDiceRollResult: GameDiceRollResult?
    @State private var physicalDiceCompletionGate = GameDiceRollCompletionGate()
    @State private var showsPhysicalTradeRecipients = false

    init(
        viewModel: LobbyDriverViewModel,
        onSettingsTap: @escaping () -> Void = {},
        onGamesTap: @escaping () -> Void = {},
        preferences: AppPreferences,
        initialMode: GameMode = .idle,
        initialRoute: GameShellRoute = .none,
        minimumActionSurfaceHeight: CGFloat? = nil,
        tutorialTradeTarget: GameTutorialTarget? = nil,
        tutorialHeaderTitle: String? = nil
    ) {
        self.viewModel = viewModel
        self.onSettingsTap = onSettingsTap
        self.onGamesTap = onGamesTap
        self.preferences = preferences
        initialModeOnReset = initialMode
        initialRouteOnReset = initialRoute
        self.minimumActionSurfaceHeight = minimumActionSurfaceHeight
        self.tutorialTradeTarget = tutorialTradeTarget
        self.tutorialHeaderTitle = tutorialHeaderTitle
        let initialProjection = viewModel.gameplayShellProjection
        _shellProjection = State(initialValue: initialProjection)
        _currentMode = State(initialValue: initialMode)
        _shellRoute = State(initialValue: initialRoute)
        _isHandOpen = State(initialValue: initialRoute == .none)
        _normalTurnContextSnapshot = State(
            initialValue: GameNormalTurnContextSnapshot(
                projection: initialProjection,
                isLocalActivePostRoll: viewModel.isNormalPostRollActiveTurn
            )
        )
    }

    var body: some View {
        let projection = shellProjection
        let screenModel = projection.gameScreenModel
        let isGameOver = projection.phase == PhaseV1.gameOver.rawValue
        let isNormalPostRollTurn = viewModel.isNormalPostRollActiveTurn
        let isNormalPreRollTurn = viewModel.isNormalPreRollActiveTurn
        let notPrimaryPlayerContext = viewModel.physicalNotPrimaryPlayerContext
        let setupPlacementModel = projection.setupPlacementModel
        let isSetup = setupPlacementModel != nil
        let resolvedMode = GameModeResolver.normalized(
            currentMode: currentMode,
            availability: screenModel.modeAvailability
        )
        let isShelfPresented = false
        let activeTradeRoute = shellRoute.tradeOverlayRoute
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
        let selectedDockKind = shellRoute.selectedDockKind
        let selectedDiscardHandCounts = discardSelectedHandCounts()
        let isGameInfoOpen = shellRoute == .gameInfo
        let hasPendingTrade = projection.tradePanelModel?.activeOffer != nil
        let visibleBoardSelectionText = resolvedMode.usesPhysicalHeaderTargetPrompt
            ? nil
            : selectionText
        let isPhysicalSetup = isSetup
        let isPhysicalStartTurn = isNormalPreRollTurn
        let isPhysicalNotPrimaryPlayer = notPrimaryPlayerContext != nil
        let isPhysicalDiscard = resolvedMode == .discard
        let isPhysicalRobberFlow = resolvedMode == .robberMove || resolvedMode == .robberVictim
        let isActionablePhysicalDiscard = isPhysicalDiscard
            && projection.discardPanelModel?.action != nil
        let isPhysicalGameOver = isGameOver && screenModel.endScreen != nil
        // Every production game phase uses the canonical physical-tabletop shell.
        let isPhysicalGameplayTurn = true
        let showsPhysicalPublicRail = true
        let physicalHeaderPrompt: GamePhysicalTurnHeaderPrompt? = if isPhysicalStartTurn {
            nil
        } else if let notPrimaryPlayerContext {
            notPrimaryPlayerContext.headerPrompt
        } else {
            GamePhysicalTurnHeaderPromptResolver.prompt(
                route: shellRoute,
                mode: resolvedMode,
                hasBoardCommitDraft: boardCommitDraft != nil,
                devCardDraft: devCardDraft
            )
        }
        let physicalHeaderTitle = isPhysicalGameOver
            ? "Game over"
            : isActionablePhysicalDiscard
            ? "Discard cards"
            : notPrimaryPlayerContext?.headerTitle(
                fallback: headerModel.statusLine.title,
                discardPanel: projection.discardPanelModel
            ) ?? headerModel.statusLine.title
        let physicalPlayerColor = screenModel.gameInfo.players
            .first(where: \.isLocalPlayer)
            .map { tint in
                Color(
                    red: tint.playerTint.red,
                    green: tint.playerTint.green,
                    blue: tint.playerTint.blue
                )
            } ?? GameTheme.accent

        let shell = ZStack {
            GameTheme.appBackground
                .ignoresSafeArea()

            GeometryReader { geometry in
                let shellSize = geometry.size
                let physicalDisplayFrame = CGRect(
                    x: 0,
                    y: 0,
                    width: shellSize.width,
                    height: shellSize.height + geometry.safeAreaInsets.bottom
                )
                let physicalLayout = GamePhysicalTurnLayout.resolve(
                    availableSize: shellSize
                )
                let tabletopSectionSpacing = physicalLayout.interZoneSpacing
                let shellLayout = GameShellLayoutMetrics.resolve(
                    availableSize: shellSize,
                    spacing: GameTheme.sectionSpacing,
                    overlayKind: .utility
                )
                let lowerRailWidth = min(
                    GameShellLayoutMetrics.lowerRailWidth(
                        for: max(shellSize.width - (GameTheme.shellPadding * 2), 0)
                    ),
                    max(shellSize.width - (GameTheme.shellPadding * 2), 0)
                )
                let tradePanelHeight = GameTradeOverlayLayout.panelHeight(
                    for: lowerRailWidth,
                    route: activeTradeRoute
                )
                let actionSurfaceHeight = max(
                    physicalLayout.actionSpreadHeight,
                    minimumActionSurfaceHeight ?? 0
                )
                let isTradePanelPresented = projection.tradePanelModel != nil
                    && activeTradeRoute != nil
                let shouldShowPendingTradeBanner = !isTradePanelPresented
                    && !isNormalPostRollTurn
                    && projection.tradePanelModel?.pendingBannerText != nil
                let endScreenHeight = GameShellLayoutMetrics.endResultRailHeight(
                    availableHeight: shellSize.height,
                    isAccessibilitySize: dynamicTypeSize.isAccessibilitySize
                )
                let bottomTrayHeight = isPhysicalGameOver
                    ? endScreenHeight
                    : physicalLayout.propRailHeight
                let physicalDiscardSurfaceHeight = actionSurfaceHeight + bottomTrayHeight
                let physicalTradeSurfaceHeight = notPrimaryPlayerContext == .incomingTrade
                    ? max(actionSurfaceHeight, GamePhysicalIncomingTradeView.minimumHeight)
                    : actionSurfaceHeight
                let usesExpandedPhysicalTradeOverlay = shouldUseExpandedPhysicalTradeOverlay(
                    route: activeTradeRoute
                )
                let recipientScrimTopInset = GameTheme.shellPadding
                    + physicalLayout.topBarHeight
                    + tabletopSectionSpacing
                let physicalTradeBottomPadding = GameTheme.shellPadding
                    + bottomTrayHeight
                    + (notPrimaryPlayerContext == .incomingTrade ? 6 : 0)
                // The 44-point handle extends six points beyond the legacy
                // 38-point visual width; reserve that clearance above the tray.
                let reservedTrayHeight = isPhysicalGameOver
                    ? bottomTrayHeight
                    : physicalLayout.propRailHeight
                let baseBoardPresentationHeight = visibleBoardHeight(
                    layout: shellLayout,
                    bottomTrayHeight: reservedTrayHeight
                ) + max(
                    shellLayout.headerHeight - physicalLayout.topBarHeight,
                    0
                )
                let feltToolSurfaceReservation = !isPhysicalSetup
                    && !isPhysicalGameOver
                    ? actionSurfaceHeight + tabletopSectionSpacing
                    : 0
                let endBoardContractCorrection = isPhysicalGameOver
                    ? max(
                        actionSurfaceHeight
                            + tabletopSectionSpacing
                            - (bottomTrayHeight - physicalLayout.propRailHeight),
                        0
                    )
                    : 0
                let boardPresentationHeight = max(
                    baseBoardPresentationHeight
                        - feltToolSurfaceReservation
                        - endBoardContractCorrection,
                    0
                )
                let publicRailHeight: CGFloat = showsPhysicalPublicRail
                    ? physicalLayout.publicRailHeight
                    : 0
                let boardCanvasPresentationHeight = max(
                    boardPresentationHeight
                        - publicRailHeight
                        - (showsPhysicalPublicRail ? tabletopSectionSpacing : 0),
                    0
                )
                let boardHostPresentationHeight = max(
                    boardCanvasPresentationHeight
                        - (physicalLayout.boardFrameVerticalInset * 2),
                    0
                )
                let boardBottomOcclusionHeight = isGameInfoOpen
                    ? GameTurnGameInfoView.boardClearanceHeight
                    : CGFloat.zero
                let boardHintBottomInset = resolvedBoardHintBottomInset(
                    isShelfPresented: isShelfPresented,
                    isTradePanelPresented: isTradePanelPresented,
                    shouldShowPendingTradeBanner: shouldShowPendingTradeBanner,
                    shellLayout: shellLayout,
                    tradePanelHeight: tradePanelHeight
                )

                ZStack(alignment: .topLeading) {
                    ZStack(alignment: .bottom) {
                        VStack(alignment: .leading, spacing: tabletopSectionSpacing) {
                            Group {
                                if let setupPlacementModel, isPhysicalSetup {
                                        GamePhysicalSetupTopBarView(
                                            model: setupPlacementModel,
                                            onSettingsTap: onSettingsTap,
                                            onGameInfoTap: handleGameInfoToggle
                                        )
                                } else if isPhysicalGameOver,
                                              let endScreen = screenModel.endScreen {
                                        GameEndTopTableauView(model: endScreen)
                                } else {
                                        if let tutorialHeaderTitle {
                                            GamePhysicalTurnPromptView(text: tutorialHeaderTitle)
                                                .frame(maxWidth: .infinity, minHeight: 44)
                                                .accessibilityElement(children: .ignore)
                                                .accessibilityLabel(tutorialHeaderTitle)
                                                .accessibilityValue("Tutorial")
                                                .accessibilityIdentifier("uls.tutorial.progress")
                                        } else {
                                            GamePhysicalTurnTopBarView(
                                                title: physicalHeaderTitle,
                                                subtitle: headerModel.statusLine.subtitle,
                                                prompt: physicalHeaderPrompt,
                                                isGameInfoOpen: isGameInfoOpen,
                                                onSettingsTap: onSettingsTap,
                                                onGameInfoTap: handleGameInfoToggle
                                            )
                                        }
                                }
                            }
                            .frame(
                                height: isPhysicalGameOver
                                    ? (
                                        dynamicTypeSize.isAccessibilitySize
                                            ? GamePhysicalTurnLayout.accessibilityEndTopBarHeight
                                            : physicalLayout.topBarHeight
                                    )
                                        + tabletopSectionSpacing
                                        + publicRailHeight
                                    : physicalLayout.topBarHeight,
                                alignment: .center
                            )
                            .accessibilityHidden(isPhysicalStartTurn)

                            if showsPhysicalPublicRail && !isPhysicalGameOver {
                                Group {
                                    if let setupPlacementModel, isPhysicalSetup {
                                        GamePhysicalSetupOrderRailView(model: setupPlacementModel)
                                    } else {
                                        GamePhysicalPublicRackView(
                                            bank: bankTrayModel,
                                            revealsBankCounts: physicalBankCountsRevealed,
                                            developmentDeckCount: screenModel.devDeckCount,
                                            canBuyDevelopmentCard: screenModel.canBuyDevCard,
                                            onToggleBankCounts: {
                                                withAnimation(motionPolicy.resolvedAnimation(GameTheme.quickAnimation)) {
                                                    physicalBankCountsRevealed.toggle()
                                                }
                                            },
                                        onBuyDevelopmentCard: handlePublicDevDeckPurchase
                                    )
                                    .scaleEffect(physicalLayout.contentScale)
                                    }
                                }
                                .frame(height: publicRailHeight)
                                .frame(maxWidth: .infinity)
                                .allowsHitTesting(!isPhysicalStartTurn)
                                .accessibilityHidden(isPhysicalStartTurn)
                                .accessibilityElement(children: .contain)
                                .accessibilityIdentifier(
                                    isPhysicalSetup
                                        ? "uls.setup.orderRail"
                                        : "uls.turn.publicRail"
                                )
                            }

                            BoardContainerView(
                                model: boardModel,
                                renderModel: screenModel.boardRenderModel,
                                overlayModel: overlayModel,
                                interactionMode: resolvedMode,
                                selectionText: visibleBoardSelectionText,
                                hintBottomInset: boardHintBottomInset,
                                showsCreamFrame: false,
                                boardContentVerticalOffset: isPhysicalSetup
                                    ? 0
                                    : physicalBoardCenteringOffset,
                                frozenBoardImage: nil,
                                bottomOcclusionHeight: boardBottomOcclusionHeight,
                                reloadToken: viewModel.boardReloadToken,
                                onInteractionChanged: nil,
                                onResizeFreezeChanged: nil,
                                onFreezeRecoveryReloadRequested: { detail in
                                    viewModel.requestBoardReload(detail: detail)
                                },
                                onTargetTap: { target in
                                    handleBoardTap(target, mode: resolvedMode)
                                }
                            )
                            .frame(height: boardHostPresentationHeight, alignment: .top)
                            .allowsHitTesting(!isGameInfoOpen)
                            .gameTutorialTarget(.board)
                            .accessibilityHidden(isPhysicalStartTurn)
                            .clipped()
                            .background {
                                GeometryReader { boardGeometry in
                                    Color.clear.preference(
                                        key: GamePhysicalBoardFramePreferenceKey.self,
                                        value: boardGeometry.frame(
                                            in: .named(Self.displayCoordinateSpaceName)
                                        )
                                    )
                                }
                            }
                            .padding(
                                .top,
                                physicalLayout.boardFrameVerticalInset
                                    + physicalLayout.boardFrameVerticalOffset
                            )
                            .padding(
                                .bottom,
                                max(
                                    physicalLayout.boardFrameVerticalInset
                                        - physicalLayout.boardFrameVerticalOffset,
                                    0
                                )
                            )
                            .frame(height: boardCanvasPresentationHeight, alignment: .top)
                            .mask {
                                RoundedRectangle(cornerRadius: GameTheme.largeRadius + 8)
                                    .padding(
                                        .horizontal,
                                        physicalLayout.boardFrameHorizontalMaskInset
                                    )
                            }
                            .padding(
                                .horizontal,
                                -physicalLayout.boardHorizontalOverflow
                            )
                            .onPreferenceChange(GamePhysicalBoardFramePreferenceKey.self) { boardFrame in
                                updatePhysicalBoardCentering(
                                    boardFrame: boardFrame,
                                    displayFrame: physicalDisplayFrame,
                                    layout: physicalLayout
                                )
                            }
                            .onChange(of: physicalDisplayFrame) { _, newDisplayFrame in
                                updatePhysicalBoardCentering(
                                    boardFrame: physicalBoardMeasuredFrame,
                                    displayFrame: newDisplayFrame,
                                    layout: physicalLayout
                                )
                            }
                            .transaction { transaction in
                                transaction.animation = nil
                            }
                        }
                        .padding(GameTheme.shellPadding)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .contentShape(Rectangle())

                        if !isGameOver, !isPhysicalStartTurn, !isActionablePhysicalDiscard {
                            Group {
                                if let setupPlacementModel, isPhysicalSetup {
                                    GamePhysicalSetupPieceRailView(
                                        model: setupPlacementModel,
                                        playerColor: physicalPlayerColor
                                    )
                                    .scaleEffect(physicalLayout.contentScale, anchor: .bottom)
                                } else {
                                    GamePhysicalTurnPropRailView(
                                        actionDock: screenModel.actionDock,
                                        selectedDockKind: selectedDockKind,
                                        isHandOpen: isHandOpen,
                                        handCount: screenModel.handTray.totalCount,
                                        hasPendingTrade: hasPendingTrade,
                                        playerColor: physicalPlayerColor,
                                        centersAvailableProps: isPhysicalNotPrimaryPlayer
                                            || isPhysicalDiscard
                                            || isPhysicalRobberFlow,
                                        isHandInteractive: !isPhysicalDiscard
                                            && !isPhysicalRobberFlow
                                            && notPrimaryPlayerContext?.isWaitingForDiscard != true,
                                        onSelectDock: { actionKind in
                                            handleActionSelection(
                                                actionKind,
                                                currentMode: resolvedMode,
                                                availability: screenModel.modeAvailability,
                                                actionDock: screenModel.actionDock
                                            )
                                        },
                                        onToggleHand: handleHandToggle
                                    )
                                    .scaleEffect(physicalLayout.contentScale, anchor: .bottom)
                                }
                            }
                            .frame(
                                height: bottomTrayHeight,
                                alignment: .bottom
                            )
                            .frame(maxWidth: lowerRailWidth)
                            .padding(.horizontal, GameTheme.shellPadding)
                            .padding(
                                .bottom,
                                physicalLayout.bottomRailPadding
                            )
                            .zIndex(0.5)
                        }

                        if isPhysicalGameOver, let endScreen = screenModel.endScreen {
                            GameEndResultRailView(
                                model: endScreen,
                                onNewGame: viewModel.prepareNewGame
                            )
                                .frame(height: bottomTrayHeight)
                                .frame(maxWidth: lowerRailWidth)
                                .padding(.horizontal, GameTheme.shellPadding)
                                .offset(y: GameTheme.inlineSpacing)
                                .zIndex(1)
                        }

#if DEBUG
                        if !isGameOver, isPhysicalGameplayTurn {
                            Rectangle()
                                .fill(Color.clear)
                                .frame(height: actionSurfaceHeight)
                                .frame(maxWidth: lowerRailWidth)
                                .contentShape(Rectangle())
                                .allowsHitTesting(false)
                                .padding(.horizontal, GameTheme.shellPadding)
                                .padding(
                                    .bottom,
                                    GameTheme.shellPadding + bottomTrayHeight
                                )
                                .accessibilityElement(children: .ignore)
                                .accessibilityIdentifier("uls.turn.actionWell")
                                .accessibilityLabel("Reserved turn action well")
                                .zIndex(0.6)

                        }
#endif

                        if !isGameOver,
                           !isPhysicalStartTurn,
                           !isPhysicalSetup,
                           notPrimaryPlayerContext?.isWaitingForDiscard != true {
                            if isPhysicalDiscard {
                                GameDiscardComposerView(
                                    panel: projection.discardPanelModel,
                                    fallbackMessage: "Discard resolution is required.",
                                    selectedCountsByResource: selectedDiscardHandCounts,
                                    onAddResource: addDiscardResource,
                                    onRemoveResource: removeDiscardResource,
                                    onSubmit: {
                                        guard viewModel.handleDiscardFlowAction(discarded: discardDraft) else { return }
                                        discardDraft = .zero
                                        selectedBoardTarget = nil
                                    }
                                )
                                .gameTutorialTarget(.discardSurface)
                                .scaleEffect(physicalLayout.contentScale)
                                .frame(height: physicalDiscardSurfaceHeight)
                                .frame(maxWidth: lowerRailWidth)
                                .padding(.horizontal, GameTheme.shellPadding)
                                .padding(.bottom, GameTheme.shellPadding)
                                .transition(.opacity)
                                .zIndex(0.75)
                            } else if isHandOpen {
                                GamePhysicalTurnActionSpreadView(
                                    content: .hand,
                                    hand: screenModel.handTray,
                                    ownedDevelopmentCards: screenModel.ownedDevCards,
                                    buildItems: screenModel.actionDock.buildShelfItems,
                                    devCardPanel: devCardPanelModel,
                                    canOpenDevCards: screenModel.actionDock.primaryItems.contains {
                                        $0.kind == .devCards && $0.isEnabled
                                    },
                                    playerColor: physicalPlayerColor,
                                    onSelectBuild: handleBuildShelfSelection,
                                    onOpenDevCards: {
                                        handleActionSelection(
                                            .devCards,
                                            currentMode: resolvedMode,
                                            availability: screenModel.modeAvailability,
                                            actionDock: screenModel.actionDock
                                        )
                                    },
                                    onSelectDevCard: handleDevCardSelection
                                )
                                .scaleEffect(physicalLayout.contentScale)
                                .frame(height: actionSurfaceHeight)
                                .frame(maxWidth: lowerRailWidth)
                                .padding(.horizontal, GameTheme.shellPadding)
                                .padding(.bottom, GameTheme.shellPadding + bottomTrayHeight)
                                .transition(.opacity)
                                .zIndex(0.75)
                            } else if shellRoute == .build, resolvedMode == .idle {
                                GamePhysicalTurnActionSpreadView(
                                    content: .build,
                                    hand: screenModel.handTray,
                                    ownedDevelopmentCards: screenModel.ownedDevCards,
                                    buildItems: screenModel.actionDock.buildShelfItems,
                                    devCardPanel: devCardPanelModel,
                                    canOpenDevCards: false,
                                    playerColor: physicalPlayerColor,
                                    onSelectBuild: handleBuildShelfSelection,
                                    onOpenDevCards: {},
                                    onSelectDevCard: handleDevCardSelection
                                )
                                .scaleEffect(physicalLayout.contentScale)
                                .frame(height: actionSurfaceHeight)
                                .frame(maxWidth: lowerRailWidth)
                                .padding(.horizontal, GameTheme.shellPadding)
                                .padding(.bottom, GameTheme.shellPadding + bottomTrayHeight)
                                .transition(.opacity)
                                .zIndex(0.75)
                            } else if shellRoute == .devCards, resolvedMode == .playDevCard {
                                GamePhysicalTurnActionSpreadView(
                                    content: .devCards,
                                    hand: screenModel.handTray,
                                    ownedDevelopmentCards: screenModel.ownedDevCards,
                                    buildItems: screenModel.actionDock.buildShelfItems,
                                    devCardPanel: devCardPanelModel,
                                    canOpenDevCards: true,
                                    playerColor: physicalPlayerColor,
                                    onSelectBuild: handleBuildShelfSelection,
                                    onOpenDevCards: {},
                                    onSelectDevCard: handleDevCardSelection
                                )
                                .scaleEffect(physicalLayout.contentScale)
                                .frame(height: actionSurfaceHeight)
                                .frame(maxWidth: lowerRailWidth)
                                .padding(.horizontal, GameTheme.shellPadding)
                                .padding(.bottom, GameTheme.shellPadding + bottomTrayHeight)
                                .transition(.opacity)
                                .zIndex(0.75)
                            } else if shellRoute == .devCards,
                                      resolvedMode == .devCardMonopoly
                                        || resolvedMode == .devCardYearOfPlenty {
                                GamePhysicalDevResourceSpreadView(
                                    bank: bankTrayModel,
                                    confirmTitle: devCardPanelModel?.confirmTitle,
                                    canConfirm: devCardPanelModel?.canConfirm ?? false,
                                    onSelectResource: {
                                        handleBankResourceSelection($0, mode: resolvedMode)
                                    },
                                    onConfirm: handleConfirmDevCardDraft
                                )
                                .scaleEffect(physicalLayout.contentScale)
                                .frame(height: actionSurfaceHeight)
                                .frame(maxWidth: lowerRailWidth)
                                .padding(.horizontal, GameTheme.shellPadding)
                                .padding(.bottom, GameTheme.shellPadding + bottomTrayHeight)
                                .transition(.opacity)
                                .zIndex(0.75)
                            }
                        }

                        if !isGameOver,
                           isPhysicalGameplayTurn,
                           shellRoute == .gameInfo {
                            ZStack {
                                GamePhysicalTurnPalette.focusVeil
                                    .opacity(0.8)
                                    .accessibilityHidden(true)

                                GameTurnGameInfoView(
                                    model: screenModel.gameInfo,
                                    games: viewModel.recoveredGames,
                                    onOpenGame: { gameId in
                                        viewModel.resumeRecoveredGame(gameId)
                                        shellRoute = .none
                                    },
                                    onManageGamesTap: onGamesTap,
                                    onClose: handleGameInfoToggle
                                )
                                .gameTutorialTarget(.gameInfo)
                                .frame(
                                    height: GameTurnGameInfoView.preferredHeight(
                                        for: screenModel.gameInfo
                                    ),
                                    alignment: .top
                                )
                                .frame(maxWidth: 346)
                                .padding(.horizontal, 20)
                            }
                            .frame(
                                width: shellSize.width,
                                height: shellSize.height + geometry.safeAreaInsets.bottom
                            )
                            .padding(.bottom, -geometry.safeAreaInsets.bottom)
                            .ignoresSafeArea(edges: .bottom)
                            .zIndex(3)
                        }

                        if !isGameOver,
                           isNormalPostRollTurn,
                           shellRoute == .endTurnConfirmation {
                            GameTurnEndConfirmationView(
                                onCancel: handleEndTurnConfirmationCancel,
                                onConfirm: handleEndTurnConfirmationConfirm
                            )
                            .gameTutorialTarget(.endTurnConfirmation)
                            .frame(height: actionSurfaceHeight)
                            .frame(maxWidth: lowerRailWidth)
                            .padding(.horizontal, GameTheme.shellPadding)
                            .padding(
                                .bottom,
                                GameTheme.shellPadding
                                    + bottomTrayHeight
                            )
                            .zIndex(1)
                        }

                        if showsPhysicalTradeRecipients, usesExpandedPhysicalTradeOverlay {
                            GamePhysicalTurnPalette.focusVeil
                                .frame(
                                    width: shellSize.width,
                                    height: shellSize.height + geometry.safeAreaInsets.bottom
                                )
                                .mask {
                                    GeometryReader { scrimGeometry in
                                        Rectangle()
                                            .fill(Color.white)
                                            .frame(
                                                width: scrimGeometry.size.width,
                                                height: max(
                                                    scrimGeometry.size.height - recipientScrimTopInset,
                                                    0
                                                )
                                            )
                                            .offset(y: recipientScrimTopInset)
                                    }
                                }
                                .padding(.bottom, -geometry.safeAreaInsets.bottom)
                                .ignoresSafeArea(edges: .bottom)
                                .accessibilityHidden(true)
                                .zIndex(2.5)
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
                           let tradeOverlayRoute = activeTradeRoute,
                           isTradePanelPresented {
                            GameTradeOverlayView(
                                route: tradeOverlayRoute,
                                panelModel: tradePanelModel,
                                bankChips: bankTrayModel.chips,
                                handChips: screenModel.handTray.chips,
                                recipientSummaries: screenModel.opponents,
                                tutorialScrollTarget: tutorialTradeTarget,
                                showsRecipients: $showsPhysicalTradeRecipients,
                                recipientScrimTopInset: recipientScrimTopInset,
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
                                onSendDraft: {
                                    submitTradeDraft()
                                },
                                onBackDraftStep: {
                                    stepBackTradeDraft()
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
                                onToggleRecipient: { playerID in
                                    toggleTradeRecipient(playerID)
                                },
                                onAcceptOffer: {
                                    guard viewModel.sendAcceptTradeResponse() else { return }
                                    closeTradePanel(resetDraft: true)
                                },
                                onDeclineOffer: {
                                    guard viewModel.sendDeclineTradeResponse() else { return }
                                    closeTradePanel(resetDraft: true)
                                },
                                onSendMaritimeTrade: { option in
                                    let give = resourceHand(from: option.give)
                                    let receive = resourceHand(from: option.receive)
                                    guard viewModel.publishMaritimeTrade(give: give, receive: receive) else { return }
                                    closeTradePanel(resetDraft: true)
                                }
                            )
                            .frame(
                                height: usesExpandedPhysicalTradeOverlay
                                    ? shellSize.height + geometry.safeAreaInsets.bottom
                                    : physicalTradeSurfaceHeight,
                                alignment: .top
                            )
                            .clipped()
                            .frame(
                                maxWidth: usesExpandedPhysicalTradeOverlay
                                    ? shellSize.width
                                    : lowerRailWidth
                            )
                            .padding(
                                .horizontal,
                                usesExpandedPhysicalTradeOverlay ? 0 : GameTheme.shellPadding
                            )
                            .padding(
                                .bottom,
                                usesExpandedPhysicalTradeOverlay
                                    ? -geometry.safeAreaInsets.bottom
                                    : physicalTradeBottomPadding
                            )
                            .zIndex(3)
                        }

                        if !isGameOver,
                           usesExpandedPhysicalTradeOverlay,
                           activeTradeRoute == .maritime {
                            GamePhysicalTurnActionSpreadView(
                                content: .hand,
                                hand: screenModel.handTray,
                                ownedDevelopmentCards: screenModel.ownedDevCards,
                                buildItems: screenModel.actionDock.buildShelfItems,
                                devCardPanel: devCardPanelModel,
                                canOpenDevCards: false,
                                playerColor: physicalPlayerColor,
                                onSelectBuild: handleBuildShelfSelection,
                                onOpenDevCards: {},
                                onSelectDevCard: handleDevCardSelection
                            )
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel("Resource hand")
                            .accessibilityValue("Shown in the normal turn position")
                            .accessibilityIdentifier("uls.physicalTrade.maritimeHandSpread")
                            .scaleEffect(physicalLayout.contentScale)
                            .frame(height: actionSurfaceHeight)
                            .frame(maxWidth: lowerRailWidth)
                            .padding(.horizontal, GameTheme.shellPadding)
                            .padding(.bottom, GameTheme.shellPadding + bottomTrayHeight)
                            .zIndex(3.5)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

                    if !isGameOver, isPhysicalStartTurn, physicalDiceRollResult == nil,
                       resolvedMode == .idle || resolvedMode == .playDevCard {
                        GamePhysicalStartTurnView(
                            devCardPanel: devCardPanelModel?.executableSelectionOnly(),
                            canPlayDevCards: screenModel.actionDock.primaryItems.contains {
                                $0.kind == .devCards && $0.isEnabled
                            },
                            canRoll: screenModel.actionDock.primaryItems.contains {
                                $0.kind == .roll && $0.isEnabled
                            },
                            isDevChooserOpen: shellRoute == .devCards
                                && resolvedMode == .playDevCard,
                            contentScale: physicalLayout.contentScale,
                            onToggleDevCards: {
                                handleActionSelection(
                                    .devCards,
                                    currentMode: resolvedMode,
                                    availability: screenModel.modeAvailability,
                                    actionDock: screenModel.actionDock
                                )
                            },
                            onSelectDevCard: handleDevCardSelection,
                            onRoll: beginPhysicalDiceRoll
                        )
                        .frame(width: shellSize.width, height: shellSize.height)
                        .transition(.opacity)
                        .zIndex(4)
                    }

                    if isPhysicalStartTurn || physicalDiceRollResult != nil {
                        GamePhysicalDiceRollOverlayView(
                            result: physicalDiceRollResult,
                            skipsAnimations: preferences.skipsAnimations,
                            onComplete: completePhysicalDiceRoll
                        )
                        .frame(width: shellSize.width, height: shellSize.height)
                        .zIndex(5)
                    }

                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }
                .coordinateSpace(.named(Self.displayCoordinateSpaceName))
        }
        return shell
        .onAppear {
            synchronizeMode(with: screenModel.modeAvailability)
            synchronizeBoardSelection(mode: resolvedMode)
            synchronizeHandTrayVisibility(for: resolvedMode)
            if notPrimaryPlayerContext != nil {
                isHandOpen = false
            }
            boardHintText = nil
            if !resolvedMode.isDevCardMode {
                devCardDraft = nil
            }
        }
        .onReceive(viewModel.$gameplayShellProjection.removeDuplicates()) { projection in
            shellProjection = projection
            synchronizeNormalTurnContext(with: projection)
            synchronizeTradeOverlay(with: projection)
            synchronizeDiscardDraft(with: projection.discardPanelModel)
        }
        .onChange(of: screenModel.modeAvailability) { _, availability in
            synchronizeMode(with: availability)
            reconcileNormalTurnRoute(with: projection)
        }
        .onChange(of: notPrimaryPlayerContext) { _, newContext in
            guard newContext != nil else { return }
            isHandOpen = false
            shellRoute = .none
            clearBoardSelection()
        }
        .onChange(of: viewModel.gameShellResetToken) { _, _ in
            resetLocalShellInteractionState()
            currentMode = initialModeOnReset
            shellRoute = initialRouteOnReset
            if initialRouteOnReset != .none {
                isHandOpen = false
            }
        }
        .onChange(of: resolvedMode) { _, newMode in
            handleResolvedModeChange(newMode)
        }
        .onChange(of: shellRoute) { _, newRoute in
            NotificationCenter.default.post(
                name: .gameBoardPanelOcclusionChanged,
                object: nil,
                userInfo: [
                    "height": newRoute == .gameInfo
                        ? GameTurnGameInfoView.boardClearanceHeight
                        : CGFloat.zero
                ]
            )
        }
        .onChange(of: screenModel.boardRenderModel) { _, _ in
            synchronizeBoardSelection(mode: resolvedMode)
        }
        .onDisappear {
            NotificationCenter.default.post(
                name: .gameBoardPanelOcclusionChanged,
                object: nil,
                userInfo: ["height": CGFloat.zero]
            )
        }
        .transaction { transaction in
            if preferences.skipsAnimations {
                transaction.disablesAnimations = true
                transaction.animation = nil
            }
        }
    }

    private var motionPolicy: GameMotionPolicy {
        GameMotionPolicy(
            skipsAnimations: preferences.skipsAnimations,
            reducesMotion: accessibilityReduceMotion
        )
    }

    private func handleResolvedModeChange(_ newMode: GameMode) {
        if !GameBoardCommitCoordinator.handles(mode: newMode) {
            boardCommitDraft = nil
        }
        boardHintText = nil
        synchronizeBoardSelection(mode: newMode)
        if !newMode.isDevCardMode {
            devCardDraft = nil
        }
        if newMode != .discard {
            discardDraft = .zero
        }
        if newMode.isForcedBoardMode {
            shellRoute = .none
        }
        synchronizeHandTrayVisibility(for: newMode)
    }

    private func updatePhysicalBoardCentering(
        boardFrame: CGRect,
        displayFrame: CGRect,
        layout: GamePhysicalTurnLayout
    ) {
        guard boardFrame.height > 0 else { return }
        physicalBoardMeasuredFrame = boardFrame
        let correction = layout.boardCenteringCorrection(
            boardGlobalFrame: boardFrame,
            displayGlobalFrame: displayFrame
        )
        let resolvedOffset = min(max(correction, -48), 48)
        guard abs(resolvedOffset - physicalBoardCenteringOffset) > (1.0 / 3.0) else {
            return
        }
        physicalBoardCenteringOffset = resolvedOffset
    }

    private func shouldUseExpandedPhysicalTradeOverlay(
        route: GameTradeOverlayRoute?
    ) -> Bool {
        switch route {
        case .playerDraft, .maritime:
            return true
        case .chooser, .liveOffer, nil:
            return false
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

    private func tabletopCommandTitle(
        mode: GameMode,
        statusLine: GameShellStatusLine,
        overlayModel: GameBoardOverlayModel
    ) -> String {
        switch mode {
        case .setup:
            if !overlayModel.legalNodeIDs.isEmpty {
                return "Place settlement"
            }
            if !overlayModel.legalEdgeIDs.isEmpty {
                return "Place road"
            }
            return "Finish setup"
        case .buildRoad, .devCardRoadBuildingFirst, .devCardRoadBuildingSecond:
            return "Place road"
        case .buildSettlement:
            return "Place settlement"
        case .buildCity:
            return "Upgrade city"
        case .robberMove, .devCardKnightMove:
            return "Move robber"
        case .robberVictim, .devCardKnightVictim:
            return "Choose player"
        case .discard:
            return "Discard cards"
        case .trade:
            return "Trade cards"
        case .playDevCard,
             .devCardMonopoly,
             .devCardYearOfPlenty:
            return "Choose a Dev Card"
        case .idle:
            return statusLine.title
        }
    }

    private func tabletopProgressIndex(
        mode: GameMode,
        overlayModel: GameBoardOverlayModel
    ) -> Int? {
        guard mode == .setup else {
            return nil
        }

        if !overlayModel.legalNodeIDs.isEmpty {
            return 0
        }
        if !overlayModel.legalEdgeIDs.isEmpty {
            return 1
        }
        return 2
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
        if actionKind == .endTurn, viewModel.isNormalPostRollActiveTurn {
            clearBoardSelection()
            isHandOpen = false
            self.currentMode = .idle
            devCardDraft = nil
            shellRoute = shellRoute == .endTurnConfirmation
                ? .none
                : .endTurnConfirmation
            return
        }

        if actionKind == .roll || actionKind == .endTurn {
            clearBoardSelection()
        }

        if viewModel.publishTurnState(for: actionKind) {
            self.currentMode = .idle
            self.shellRoute = .none
            clearBoardSelection()
            self.devCardDraft = nil
            return
        }

        clearBoardSelection()
        switch actionKind {
        case .build:
            isHandOpen = false
            guard !actionDock.buildShelfItems.isEmpty else {
                self.currentMode = .idle
                self.shellRoute = .none
                self.devCardDraft = nil
                return
            }

            if shellRoute == .build {
                self.currentMode = .idle
                self.shellRoute = .none
                self.devCardDraft = nil
            } else {
                self.currentMode = .idle
                self.shellRoute = .build
                self.devCardDraft = nil
            }
        case .devCards:
            isHandOpen = false
            if shellRoute == .devCards {
                dismissDevCardFlow()
                return
            }
            let nextMode = GameModeResolver.nextMode(
                for: actionKind,
                currentMode: currentMode,
                availability: availability
            )
            self.currentMode = nextMode
            self.devCardDraft = nil
            self.shellRoute = nextMode.isDevCardMode ? .devCards : .none
        case .trade:
            isHandOpen = false
            if case .trade = shellRoute {
                closeTradePanel(resetDraft: true)
            } else {
                openTradePanel()
            }
        case .roll, .endTurn:
            self.currentMode = .idle
            self.shellRoute = .none
            self.devCardDraft = nil
        }
    }

    private func beginPhysicalDiceRoll() {
        guard physicalDiceRollResult == nil else { return }
        clearBoardSelection()
        guard let result = viewModel.previewDiceRoll() else { return }
        currentMode = .idle
        shellRoute = .none
        devCardDraft = nil
        physicalDiceCompletionGate = GameDiceRollCompletionGate()
        physicalDiceRollResult = result

        Task { @MainActor in
            await Task.yield()
            guard physicalDiceRollResult == result else { return }
            guard viewModel.publishDiceRoll() == result else {
                physicalDiceRollResult = nil
                return
            }
            if preferences.skipsAnimations {
                completePhysicalDiceRoll()
            }
        }
    }

    private func completePhysicalDiceRoll() {
        physicalDiceCompletionGate.complete {
            physicalDiceRollResult = nil
        }
    }

    private func handleHandToggle() {
        if viewModel.isNormalPostRollActiveTurn {
            if isHandOpen {
                withAnimation(motionPolicy.resolvedAnimation(GameTheme.quickAnimation)) {
                    isHandOpen = false
                }
                clearBoardSelection()
                return
            }

            if case .trade = shellRoute {
                closeTradePanel(resetDraft: true)
            } else {
                currentMode = .idle
                shellRoute = .none
                devCardDraft = nil
                clearBoardSelection()
            }

            withAnimation(motionPolicy.resolvedAnimation(GameTheme.quickAnimation)) {
                isHandOpen = true
            }
            return
        }

        withAnimation(motionPolicy.resolvedAnimation(GameTheme.quickAnimation)) {
            isHandOpen.toggle()
        }
        clearBoardSelection()
    }

    private func handleGameInfoToggle() {
        if shellRoute == .gameInfo {
            GameBoardPanelOcclusionController.setHeight(0)
            NotificationCenter.default.post(
                name: .gameBoardPanelOcclusionChanged,
                object: nil,
                userInfo: ["height": CGFloat.zero]
            )
            shellRoute = .none
        } else {
            if case .trade = shellRoute {
                closeTradePanel(resetDraft: true)
            }
            currentMode = .idle
            devCardDraft = nil
            isHandOpen = false
            GameBoardPanelOcclusionController.setHeight(
                GameTurnGameInfoView.boardClearanceHeight
            )
            NotificationCenter.default.post(
                name: .gameBoardPanelOcclusionChanged,
                object: nil,
                userInfo: ["height": GameTurnGameInfoView.boardClearanceHeight]
            )
            shellRoute = .gameInfo
        }
        clearBoardSelection()
    }

    private func handlePublicDevDeckPurchase() {
        guard viewModel.handleDevCardAction(.buyDevCard) else { return }
        currentMode = .idle
        shellRoute = .none
        isHandOpen = true
        devCardDraft = nil
        clearBoardSelection()
    }

    private func handleEndTurnConfirmationCancel() {
        shellRoute = .none
        clearBoardSelection()
    }

    private func handleEndTurnConfirmationConfirm() {
        guard viewModel.publishTurnState(for: .endTurn) else { return }
        currentMode = .idle
        shellRoute = .none
        isHandOpen = true
        devCardDraft = nil
        clearBoardSelection()
    }

    private func openTradePanel() {
        guard shellProjection.tradePanelModel != nil else {
            return
        }

        currentMode = .idle
        devCardDraft = nil
        if shellProjection.tradePanelModel?.activeOffer != nil {
            shellRoute = .trade(.liveOffer)
        } else {
            shellRoute = .trade(.chooser)
        }
        clearBoardSelection()
    }

    private func closeTradePanel(resetDraft: Bool) {
        currentMode = .idle
        showsPhysicalTradeRecipients = false
        if resetDraft {
            shellRoute = .none
        }
        clearBoardSelection()
    }

    private func startPlayerTradeDraft() {
        showsPhysicalTradeRecipients = false
        shellRoute = .trade(.playerDraft(
            GameTradeDraft(
                kind: .offer,
                give: .zero,
                receive: .zero,
                recipients: []
            )
        ))
        clearBoardSelection()
    }

    private func startCounterTradeDraft(using panelModel: GameTradePanelModel) {
        guard let offer = panelModel.activeOffer else {
            return
        }

        shellRoute = .trade(.playerDraft(
            GameTradeDraft(
                kind: .counter(originalProposerID: offer.proposerPlayerID),
                give: .zero,
                receive: .zero,
                recipients: [offer.proposerPlayerID]
            )
        ))
        clearBoardSelection()
    }

    private func startMaritimeTrade() {
        showsPhysicalTradeRecipients = false
        shellRoute = .trade(.maritime)
        clearBoardSelection()
    }

    private func stepBackTradeDraft() {
        switch shellRoute.tradeOverlayRoute {
        case .chooser, nil:
            closeTradePanel(resetDraft: true)
        case .maritime:
            shellRoute = .trade(.chooser)
        case .playerDraft:
            closeTradePanel(resetDraft: true)
        case .liveOffer:
            closeTradePanel(resetDraft: true)
        }
        clearBoardSelection()
    }

    private func submitTradeDraft() {
        guard case let .trade(.playerDraft(draft)) = shellRoute else {
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
            didSend = viewModel.sendCounterTradeResponse(
                give: draft.give,
                receive: draft.receive
            )
        }

        guard didSend else {
            return
        }

        if viewModel.isNormalPostRollActiveTurn {
            shellRoute = .trade(.liveOffer)
            isHandOpen = false
        } else {
            closeTradePanel(resetDraft: true)
        }
        selectedBoardTarget = nil
    }

    private func addGiveResource(_ resource: ResourceV1) {
        guard case let .trade(.playerDraft(draft)) = shellRoute else {
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
        guard case let .trade(.playerDraft(draft)) = shellRoute else {
            return
        }

        var nextDraft = draft
        mutate(&nextDraft)
        shellRoute = .trade(.playerDraft(nextDraft))
    }

    private func toggleTradeRecipient(_ playerID: String) {
        mutateTradeDraft { draft in
            guard !draft.isCounter else {
                return
            }
            if let existingIndex = draft.recipients.firstIndex(of: playerID) {
                draft.recipients.remove(at: existingIndex)
            } else {
                draft.recipients.append(playerID)
                draft.recipients.sort()
            }
        }
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

    private func discardSelectedHandCounts() -> [ResourceV1: Int] {
        tradeCountMap(for: discardDraft)
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

    private func addDiscardResource(_ resource: ResourceV1) {
        guard let discardChoice = discardSelectionAction(from: shellProjection.discardPanelModel) else {
            return
        }

        let available = discardChoice.availableHand.first(where: { $0.resource == resource })?.count ?? 0
        let selected = tradeResourceCount(resource, in: discardDraft)
        guard selected < available, discardDraft.totalCount < discardChoice.requiredCount else {
            return
        }

        discardDraft = updating(resource: resource, in: discardDraft, delta: 1)
    }

    private func removeDiscardResource(_ resource: ResourceV1) {
        discardDraft = updating(resource: resource, in: discardDraft, delta: -1)
    }

    private func discardSelectionAction(
        from panel: GameDiscardPanelModel?
    ) -> (requiredCount: Int, availableHand: [GameHandChip])? {
        guard let panel else {
            return nil
        }

        switch panel.action {
        case let .publishDiscard(requiredCount, availableHand):
            return (requiredCount, availableHand)
        case .none:
            return nil
        }
    }

    private func synchronizeDiscardDraft(with panel: GameDiscardPanelModel?) {
        guard let discardChoice = discardSelectionAction(from: panel) else {
            discardDraft = .zero
            return
        }

        var sanitized = ResourceHandV1.zero
        for resource in ResourceV1.tradeableCases {
            let selected = tradeResourceCount(resource, in: discardDraft)
            let available = discardChoice.availableHand.first(where: { $0.resource == resource })?.count ?? 0
            if selected > 0, available > 0 {
                sanitized = sanitized.adding(min(selected, available), for: resource)
            }
        }

        if sanitized.totalCount > discardChoice.requiredCount {
            discardDraft = .zero
        } else {
            discardDraft = sanitized
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
        guard case let .trade(route) = shellRoute else {
            return
        }

        guard let tradePanelModel = projection.tradePanelModel else {
            shellRoute = .none
            return
        }

        switch route {
        case .liveOffer where tradePanelModel.activeOffer == nil:
            shellRoute = .trade(.chooser)
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

    private func visibleBoardHeight(
        layout: GameShellLayoutMetrics,
        bottomTrayHeight: CGFloat
    ) -> CGFloat {
        let additionalTrayHeight = max(bottomTrayHeight - layout.trayHeight, 0)
        return max(layout.boardHeight - additionalTrayHeight, 0)
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
        shellRoute = .build
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

    private func synchronizeNormalTurnContext(with projection: GameShellProjection) {
        let nextSnapshot = GameNormalTurnContextSnapshot(
            projection: projection,
            isLocalActivePostRoll: viewModel.isNormalPostRollActiveTurn
        )
        let transition = GameNormalTurnInteractionResolver.transition(
            from: normalTurnContextSnapshot,
            to: nextSnapshot
        )
        normalTurnContextSnapshot = nextSnapshot

        switch transition {
        case .entered, .replaced:
            resetLocalShellInteractionState()
        case .left:
            resetLocalShellInteractionState()
        case .updated:
            reconcileNormalTurnRoute(with: projection)
        case .inactive:
            break
        }
    }

    private func reconcileNormalTurnRoute(with projection: GameShellProjection) {
        guard viewModel.isNormalPostRollActiveTurn else {
            return
        }

        let normalizedRoute = GameNormalTurnInteractionResolver.normalizedRoute(
            shellRoute,
            availability: GameNormalTurnRouteAvailability(
                screenModel: projection.gameScreenModel,
                hasTradePanel: projection.tradePanelModel != nil
            )
        )
        guard normalizedRoute != shellRoute else {
            return
        }

        shellRoute = normalizedRoute
        currentMode = .idle
        devCardDraft = nil
        isHandOpen = false
        clearBoardSelection()
    }

    private func handleCancelBoardCommit(
        isNormalPostRollTurn: Bool,
        mode: GameMode
    ) {
        clearBoardSelection()
        guard isNormalPostRollTurn, mode.buildShelfKind != nil else {
            return
        }

        currentMode = .idle
        shellRoute = .build
        devCardDraft = nil
        isHandOpen = false
    }

    private func synchronizeHandTrayVisibility(for mode: GameMode) {
        guard mode.prefersCollapsedHandTray else {
            return
        }

        isHandOpen = false
    }

    private func resetLocalShellInteractionState() {
        currentMode = .idle
        selectedBoardTarget = nil
        boardCommitDraft = nil
        boardHintText = nil
        discardDraft = .zero
        devCardDraft = nil
        shellRoute = .none
        isHandOpen = true
        physicalBankCountsRevealed = false
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
        shellRoute = .devCards
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
        shellRoute = .devCards
        clearBoardSelection()
    }

    private func dismissDevCardFlow() {
        devCardDraft = nil
        currentMode = .idle
        shellRoute = .none
        clearBoardSelection()
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
                shellRoute = .none
                clearBoardSelection()
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
                shellRoute = .none
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

private extension GameMode {
    var usesPhysicalHeaderTargetPrompt: Bool {
        switch self {
        case .buildRoad,
             .buildSettlement,
             .buildCity,
             .robberMove,
             .robberVictim,
             .devCardKnightMove,
             .devCardKnightVictim,
             .devCardRoadBuildingFirst,
             .devCardRoadBuildingSecond:
            return true
        case .idle,
             .setup,
             .trade,
             .playDevCard,
             .devCardMonopoly,
             .devCardYearOfPlenty,
             .discard:
            return false
        }
    }
}

private struct GamePhysicalBoardFramePreferenceKey: PreferenceKey {
    static let defaultValue: CGRect = .zero

    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        let next = nextValue()
        if next.height > 0 {
            value = next
        }
    }
}

private extension GameMode {
    var prefersCollapsedHandTray: Bool {
        switch self {
        case .idle:
            return false
        case .setup,
             .buildRoad,
             .buildSettlement,
             .buildCity,
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
            return true
        }
    }
}

enum GameTradeOverlayLayout {
    static func panelHeight(
        for availableWidth: CGFloat,
        route: GameTradeOverlayRoute?
    ) -> CGFloat {
        let isWide = availableWidth >= 520
        switch route {
        case .chooser, nil:
            return isWide ? 220 : 236
        case .maritime:
            return isWide ? 264 : 292
        case .liveOffer:
            return isWide ? 300 : 336
        case .playerDraft:
            return isWide ? 364 : 408
        }
    }

    static let bannerHeight: CGFloat = 44
    static let verticalSpacing: CGFloat = 10
}

struct GameTradeOverlayView: View {
    let route: GameTradeOverlayRoute
    let panelModel: GameTradePanelModel
    let bankChips: [GameBankChip]
    let handChips: [GameHandChip]
    let recipientSummaries: [GameOpponentSummary]
    let tutorialScrollTarget: GameTutorialTarget?
    @Binding var showsRecipients: Bool
    let recipientScrimTopInset: CGFloat
    let onClose: () -> Void
    let onChoosePlayerTrade: () -> Void
    let onChooseMaritimeTrade: () -> Void
    let onReplaceOffer: () -> Void
    let onStartCounterDraft: () -> Void
    let onSendDraft: () -> Void
    let onBackDraftStep: () -> Void
    let onAddGiveResource: (ResourceV1) -> Void
    let onRemoveGiveResource: (ResourceV1) -> Void
    let onAddWantResource: (ResourceV1) -> Void
    let onRemoveWantResource: (ResourceV1) -> Void
    let onToggleRecipient: (String) -> Void
    let onAcceptOffer: () -> Void
    let onDeclineOffer: () -> Void
    let onSendMaritimeTrade: (GameTradeMaritimeOption) -> Void

    var body: some View {
        GamePhysicalTradeSurfaceView(
            route: route,
            panelModel: panelModel,
            bankChips: bankChips,
            handChips: handChips,
            recipientSummaries: recipientSummaries,
            tutorialTarget: tutorialScrollTarget,
            showsRecipients: $showsRecipients,
            recipientScrimTopInset: recipientScrimTopInset,
            onClose: onClose,
            onChoosePlayerTrade: onChoosePlayerTrade,
            onChooseMaritimeTrade: onChooseMaritimeTrade,
            onReplaceOffer: onReplaceOffer,
            onStartCounterDraft: onStartCounterDraft,
            onSendDraft: onSendDraft,
            onBack: onBackDraftStep,
            onAddGiveResource: onAddGiveResource,
            onRemoveGiveResource: onRemoveGiveResource,
            onAddWantResource: onAddWantResource,
            onRemoveWantResource: onRemoveWantResource,
            onToggleRecipient: onToggleRecipient,
            onAcceptOffer: onAcceptOffer,
            onDeclineOffer: onDeclineOffer,
            onSendMaritimeTrade: onSendMaritimeTrade
        )
        .transition(.opacity)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("uls.turn.tradeSurface")
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
        .accessibilityLabel(text)
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

private extension ResourceV1 {
    static var tradeableCases: [ResourceV1] {
        [.wood, .brick, .sheep, .wheat, .ore]
    }
}

private extension ResourceHandV1 {
    var isZero: Bool {
        wood == 0 && brick == 0 && sheep == 0 && wheat == 0 && ore == 0
    }
}
