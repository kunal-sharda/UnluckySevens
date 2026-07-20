import Combine
import SwiftUI
import ULS_CoreGame

struct GameShellView: View {
    let viewModel: LobbyDriverViewModel
    let onSettingsTap: () -> Void
    private static let shellResizeFreezeWatchdogNanoseconds: UInt64 = 1_200_000_000

    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
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
    @State private var lastUtilityShelf: GameLowerShelf = .bank
    @State private var normalTurnContextSnapshot: GameNormalTurnContextSnapshot
    @State private var shellResizeFreezeSnapshot: GameShellFreezeSnapshot?
    @State private var physicalBoardCenteringOffset: CGFloat = 0
    @State private var shellResizeFreezeEpoch: Int = 0
    @State private var shellResizeFreezeTask: Task<Void, Never>?
    @State private var physicalDiceRollResult: GameDiceRollResult?
#if DEBUG
    @AppStorage(GameTabletopLayoutStyle.uxTestingDefaultsKey)
    private var uxTestingTabletopLayoutStyleRawValue = GameTabletopLayoutStyle.framedShelf.rawValue
#endif

    init(
        viewModel: LobbyDriverViewModel,
        onSettingsTap: @escaping () -> Void = {}
    ) {
        self.viewModel = viewModel
        self.onSettingsTap = onSettingsTap
        let initialProjection = viewModel.gameplayShellProjection
        _shellProjection = State(initialValue: initialProjection)
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
        let tabletopLayoutStyle = resolvedTabletopLayoutStyle(
            isNormalPostRollTurn: isNormalPostRollTurn,
            isNormalPreRollTurn: isNormalPreRollTurn,
            hasNotPrimaryPlayerContext: notPrimaryPlayerContext != nil,
            isSetupPlacement: isSetup,
            isForcedDiscard: resolvedMode == .discard
        )
        let shelfPresentation = resolvedShelfPresentation(
            mode: resolvedMode,
            usesPhysicalProps: tabletopLayoutStyle.usesPhysicalProps
        )
        let activeLowerShelf = shelfPresentation.activeShelf
        let isShelfPresented = activeLowerShelf != nil && !isGameOver
        let activeTradeRoute = shellRoute.tradeOverlayRoute
        let bankTrayModel = viewModel.makeBankTrayModel(
            mode: resolvedMode,
            draft: devCardDraft
        )
        let rawDevCardPanelModel = viewModel.makeDevCardPanelModel(
            mode: resolvedMode,
            draft: devCardDraft
        )
        let devCardPanelModel = isNormalPostRollTurn && !tabletopLayoutStyle.usesPhysicalProps
            ? rawDevCardPanelModel?.executableSelectionOnly()
            : rawDevCardPanelModel
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
        let selectedDockKind = shellRoute.selectedDockKind ?? shelfPresentation.selectedDockKind
        let selectedTradeHandCounts = tradeSelectedHandCounts(route: activeTradeRoute)
        let selectedDiscardHandCounts = discardSelectedHandCounts()
        let selectedRecipients = tradeSelectedRecipients(route: activeTradeRoute)
        let isBankOpen = shellRoute.utilityShelf == .bank
        let isGameInfoOpen = shellRoute == .gameInfo
        let hasPendingTrade = projection.tradePanelModel?.activeOffer != nil
        let usesPhysicalProps = tabletopLayoutStyle.usesPhysicalProps
        let isPhysicalSetup = usesPhysicalProps && isSetup
        let isPhysicalStartTurn = usesPhysicalProps && isNormalPreRollTurn
        let isPhysicalNotPrimaryPlayer = usesPhysicalProps && notPrimaryPlayerContext != nil
        let isPhysicalDiscard = usesPhysicalProps && resolvedMode == .discard
        let isActionablePhysicalDiscard = isPhysicalDiscard
            && projection.discardPanelModel?.action != nil
        let isPhysicalGameplayTurn = isNormalPostRollTurn
            || isPhysicalStartTurn
            || isPhysicalNotPrimaryPlayer
            || isPhysicalSetup
            || isPhysicalDiscard
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
        let physicalHeaderTitle = isActionablePhysicalDiscard
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

        ZStack {
            GameTheme.appBackground
                .ignoresSafeArea()

            GeometryReader { geometry in
                let shellSize = geometry.size
                let shellGlobalFrame = geometry.frame(in: .global)
                let physicalDisplayHeight = shellGlobalFrame.maxY
                    + geometry.safeAreaInsets.bottom
                let physicalLayout = GamePhysicalTurnLayout.resolve(
                    availableSize: shellSize
                )
                let tabletopSectionSpacing = usesPhysicalProps
                    ? physicalLayout.interZoneSpacing
                    : GameTheme.sectionSpacing
                let shellLayout = GameShellLayoutMetrics.resolve(
                    availableSize: shellSize,
                    spacing: GameTheme.sectionSpacing,
                    overlayKind: overlayShelfKind(for: shelfPresentation)
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
                let tradePanelHeight = GameTradeOverlayLayout.panelHeight(
                    for: lowerRailWidth,
                    route: activeTradeRoute
                )
                let feltToolSurfaceHeight = GameFeltToolSurfaceLayout.height(
                    for: lowerRailWidth
                )
                let actionSurfaceHeight = usesPhysicalProps
                    ? physicalLayout.actionSpreadHeight
                    : feltToolSurfaceHeight
                let isTradePanelPresented = projection.tradePanelModel != nil
                    && activeTradeRoute != nil
                let shouldShowPendingTradeBanner = !isTradePanelPresented
                    && !isNormalPostRollTurn
                    && projection.tradePanelModel?.pendingBannerText != nil
                let bottomTrayHeight = usesPhysicalProps
                    ? physicalLayout.propRailHeight
                    : tabletopLayoutStyle.usesFeltTools
                    ? shellLayout.trayHeight
                    : (isHandOpen ? shellLayout.expandedTrayHeight : shellLayout.trayHeight)
                let physicalDiscardSurfaceHeight = actionSurfaceHeight + bottomTrayHeight
                let physicalTradeSurfaceHeight = notPrimaryPlayerContext == .incomingTrade
                    ? max(actionSurfaceHeight, GamePhysicalIncomingTradeView.minimumHeight)
                    : actionSurfaceHeight
                let physicalTradeBottomPadding = GameTheme.shellPadding
                    + bottomTrayHeight
                    + (notPrimaryPlayerContext == .incomingTrade ? 6 : 0)
                // The 44-point handle extends six points beyond the legacy
                // 38-point visual width; reserve that clearance above the tray.
                let reservedTrayHeight = usesPhysicalProps
                    ? physicalLayout.propRailHeight
                    : tabletopLayoutStyle.usesFeltTools
                    ? shellLayout.trayHeight
                    : shellLayout.expandedTrayHeight + 6
                let baseBoardPresentationHeight = visibleBoardHeight(
                    layout: shellLayout,
                    bottomTrayHeight: reservedTrayHeight
                ) + (usesPhysicalProps
                    ? max(
                        shellLayout.headerHeight
                            - physicalLayout.topBarHeight,
                        0
                    )
                    : 0)
                let feltToolSurfaceReservation = tabletopLayoutStyle.usesFeltTools && !isPhysicalSetup
                    ? actionSurfaceHeight + tabletopSectionSpacing
                    : 0
                let boardPresentationHeight = max(
                    baseBoardPresentationHeight - feltToolSurfaceReservation,
                    0
                )
                let publicRailHeight: CGFloat = isPhysicalGameplayTurn
                        ? (usesPhysicalProps
                        ? physicalLayout.publicRailHeight
                        : 86)
                    : 0
                let boardCanvasPresentationHeight = max(
                    boardPresentationHeight
                        - publicRailHeight
                        - (isPhysicalGameplayTurn ? tabletopSectionSpacing : 0),
                    0
                )
                let boardHostPresentationHeight = usesPhysicalProps
                    ? max(
                        boardCanvasPresentationHeight
                            - (physicalLayout.boardFrameVerticalInset * 2),
                        0
                    )
                    : boardCanvasPresentationHeight
                let overlayShelfLayout = tabletopLayoutStyle.usesFeltTools
                    ? shellLayout.overlayShelf.fittedToTabletopSurface(
                        height: actionSurfaceHeight
                    )
                    : shellLayout.overlayShelf
                let shelfContentInset = tabletopLayoutStyle.usesFeltTools
                    ? 4
                    : GameTheme.inlineSpacing
                let shelfBodySize = CGSize(
                    width: max(lowerRailWidth - (shelfContentInset * 2), 0),
                    height: max(overlayShelfLayout.contentHeight - (shelfContentInset * 2), 0)
                )
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
                                if isPhysicalGameplayTurn {
                                    if let setupPlacementModel, isPhysicalSetup {
                                        GamePhysicalSetupTopBarView(
                                            model: setupPlacementModel,
                                            onSettingsTap: onSettingsTap,
                                            onGameInfoTap: handleGameInfoToggle
                                        )
                                    } else if usesPhysicalProps {
                                        GamePhysicalTurnTopBarView(
                                            title: physicalHeaderTitle,
                                            subtitle: headerModel.statusLine.subtitle,
                                            prompt: physicalHeaderPrompt,
                                            isGameInfoOpen: isGameInfoOpen,
                                            onSettingsTap: onSettingsTap,
                                            onGameInfoTap: handleGameInfoToggle
                                        )
                                    } else {
                                        GameTurnTopBarView(
                                            title: headerModel.statusLine.title,
                                            subtitle: headerModel.statusLine.subtitle,
                                            isGameInfoOpen: isGameInfoOpen,
                                            onSettingsTap: onSettingsTap,
                                            onGameInfoTap: handleGameInfoToggle
                                        )
                                    }
                                } else {
                                    GameCommandBarView(
                                        title: tabletopCommandTitle(
                                            mode: resolvedMode,
                                            statusLine: headerModel.statusLine,
                                            overlayModel: overlayModel
                                        ),
                                        progressIndex: tabletopProgressIndex(
                                            mode: resolvedMode,
                                            overlayModel: overlayModel
                                        ),
                                        progressCount: 4,
                                        onMenuTap: {
                                            handleUtilityHandleToggle(canPresentUtilityShelf: canPresentUtilityShelf)
                                        }
                                    )
                                }
                            }
                            .frame(
                                height: usesPhysicalProps
                                    ? physicalLayout.topBarHeight
                                    : shellLayout.headerHeight,
                                alignment: .center
                            )
                            .accessibilityHidden(isPhysicalStartTurn)

                            if isPhysicalGameplayTurn {
                                Group {
                                    if let setupPlacementModel, isPhysicalSetup {
                                        GamePhysicalSetupOrderRailView(model: setupPlacementModel)
                                    } else if usesPhysicalProps {
                                        GamePhysicalPublicRackView(
                                            bank: bankTrayModel,
                                            revealsBankCounts: physicalBankCountsRevealed,
                                            developmentDeckCount: screenModel.devDeckCount,
                                            canBuyDevelopmentCard: screenModel.canBuyDevCard,
                                            onToggleBankCounts: {
                                                withAnimation(
                                                    accessibilityReduceMotion
                                                        ? .linear(duration: 0.01)
                                                        : GameTheme.quickAnimation
                                                ) {
                                                    physicalBankCountsRevealed.toggle()
                                                }
                                            },
                                        onBuyDevelopmentCard: handlePublicDevDeckPurchase
                                    )
                                    .scaleEffect(physicalLayout.contentScale)
                                } else {
                                        GameTabletopBankRackView(
                                            model: bankTrayModel,
                                            showsBankCounts: false,
                                            isBankOpen: isBankOpen,
                                            devDeckCount: screenModel.devDeckCount,
                                            isDevDeckEnabled: screenModel.canBuyDevCard,
                                            onOpenBank: {
                                                handleUtilityShelfSelection(.bank)
                                            },
                                            onOpenDevCards: {
                                                handlePublicDevDeckPurchase()
                                            }
                                        )
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
                                bankTray: bankTrayModel,
                                showsTabletopRack: !isPhysicalGameplayTurn,
                                showsBankCounts: true,
                                isBankOpen: isBankOpen,
                                devDeckCount: screenModel.devDeckCount,
                                isDevDeckEnabled: screenModel.actionDock.primaryItems.contains {
                                    $0.kind == .devCards && $0.isEnabled
                                },
                                selectionText: selectionText,
                                hintBottomInset: boardHintBottomInset,
                                showsCreamFrame: tabletopLayoutStyle.showsCreamBoardFrame,
                                boardContentVerticalOffset: usesPhysicalProps
                                    ? (isPhysicalSetup ? 0 : physicalBoardCenteringOffset)
                                    : 0,
                                frozenBoardImage: nil,
                                reloadToken: viewModel.boardReloadToken,
                                onInteractionChanged: nil,
                                onResizeFreezeChanged: isPhysicalGameplayTurn ? nil : { freezeState in
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
                                                isHandOpen: isHandOpen,
                                                tabletopLayoutStyle: tabletopLayoutStyle,
                                                activeLowerShelf: activeLowerShelf,
                                                shelfStyle: freezeShelfStyle,
                                                mode: resolvedMode,
                                                handTray: screenModel.handTray,
                                                bankTray: bankTrayModel,
                                                opponents: screenModel.opponents,
                                                selectedBuildKind: resolvedMode.buildShelfKind,
                                                setupInstruction: projection.setupGuidanceText,
                                                discardPanel: projection.discardPanelModel,
                                                discardSelectedHandCounts: selectedDiscardHandCounts,
                                                tradePanelModel: projection.tradePanelModel,
                                                devCardPanel: devCardPanelModel,
                                                robberVictimOptions: projection.robberVictimOptions,
                                                tradeOverlayRoute: activeTradeRoute,
                                                tradeSelectedHandCounts: selectedTradeHandCounts,
                                                tradeSelectedRecipients: selectedRecipients,
                                                pendingTradeBannerText: projection.tradePanelModel?.pendingBannerText
                                            )
                                        }
                                    )
                                },
                                onFreezeRecoveryReloadRequested: { detail in
                                    viewModel.requestBoardReload(detail: detail)
                                },
                                onTargetTap: { target in
                                    handleBoardTap(target, mode: resolvedMode)
                                },
                                onOpenBank: {
                                    handleUtilityShelfSelection(.bank)
                                },
                                onOpenDevCards: {
                                    handleActionSelection(
                                        .devCards,
                                        currentMode: resolvedMode,
                                        availability: screenModel.modeAvailability,
                                        actionDock: screenModel.actionDock
                                    )
                                }
                            )
                            .frame(height: boardHostPresentationHeight, alignment: .top)
                            .accessibilityHidden(isPhysicalStartTurn)
                            .clipped()
                            .background {
                                if usesPhysicalProps {
                                    GeometryReader { boardGeometry in
                                        Color.clear.preference(
                                            key: GamePhysicalBoardFramePreferenceKey.self,
                                            value: boardGeometry.frame(in: .global)
                                        )
                                    }
                                }
                            }
                            .padding(
                                .top,
                                usesPhysicalProps
                                    ? physicalLayout.boardFrameVerticalInset
                                        + physicalLayout.boardFrameVerticalOffset
                                    : 0
                            )
                            .padding(
                                .bottom,
                                usesPhysicalProps
                                    ? max(
                                        physicalLayout.boardFrameVerticalInset
                                            - physicalLayout.boardFrameVerticalOffset,
                                        0
                                    )
                                    : 0
                            )
                            .frame(height: boardCanvasPresentationHeight, alignment: .top)
                            .mask {
                                if usesPhysicalProps {
                                    RoundedRectangle(cornerRadius: GameTheme.largeRadius + 8)
                                        .padding(
                                            .horizontal,
                                            physicalLayout.boardFrameHorizontalMaskInset
                                        )
                                } else {
                                    Rectangle()
                                }
                            }
                            .padding(
                                .horizontal,
                                usesPhysicalProps ? -physicalLayout.boardHorizontalOverflow : 0
                            )
                            .onPreferenceChange(GamePhysicalBoardFramePreferenceKey.self) { boardFrame in
                                guard usesPhysicalProps else { return }
                                let correction = physicalLayout.boardCenteringCorrection(
                                    boardGlobalFrame: boardFrame,
                                    displayHeight: physicalDisplayHeight
                                )
                                let resolvedOffset = min(max(correction, -48), 48)
                                guard abs(resolvedOffset - physicalBoardCenteringOffset) > (1.0 / 3.0) else {
                                    return
                                }
                                physicalBoardCenteringOffset = resolvedOffset
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
                                } else if usesPhysicalProps {
                                    GamePhysicalTurnPropRailView(
                                        actionDock: screenModel.actionDock,
                                        selectedDockKind: selectedDockKind,
                                        isHandOpen: isHandOpen,
                                        hasPendingTrade: hasPendingTrade,
                                        playerColor: physicalPlayerColor,
                                        centersAvailableProps: isPhysicalNotPrimaryPlayer || isPhysicalDiscard,
                                        isHandInteractive: !isPhysicalDiscard
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
                                } else {
                                    GameBottomTrayView(
                                        layout: shellLayout.lowerRail,
                                        handTray: screenModel.handTray,
                                        actionDock: screenModel.actionDock,
                                        selectedDockKind: selectedDockKind,
                                        isHandOpen: isHandOpen,
                                        hasPendingTrade: hasPendingTrade,
                                        presentationStyle: tabletopLayoutStyle,
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
                                }
                            }
                            .frame(
                                height: bottomTrayHeight,
                                alignment: tabletopLayoutStyle.usesFeltTools ? .bottom : .top
                            )
                            .frame(maxWidth: lowerRailWidth)
                            .padding(.horizontal, GameTheme.shellPadding)
                            .padding(
                                .bottom,
                                usesPhysicalProps
                                    ? physicalLayout.bottomRailPadding
                                    : GameTheme.shellPadding
                            )
                            .zIndex(0.5)
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
                           usesPhysicalProps,
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
                           tabletopLayoutStyle.usesFeltTools,
                           !usesPhysicalProps,
                           isHandOpen {
                            GameFeltHandOverlayView(
                                handTray: screenModel.handTray,
                                ownedDevCards: screenModel.ownedDevCards
                            )
                                .frame(
                                    height: feltToolSurfaceHeight,
                                    alignment: .bottom
                                )
                                .frame(maxWidth: lowerRailWidth)
                                .padding(.horizontal, GameTheme.shellPadding)
                                .padding(
                                    .bottom,
                                    GameTheme.shellPadding
                                        + shellLayout.trayHeight
                                )
                                .zIndex(0.75)
                        }

                        if !isGameOver, !usesPhysicalProps, let activeLowerShelf {
                            GameOverlayShelfView(
                                layout: overlayShelfLayout,
                                presentation: shelfPresentation,
                                currentMode: resolvedMode,
                                tabletopLayoutStyle: tabletopLayoutStyle,
                                onSelectUtilityShelf: { shelf in
                                    handleUtilityShelfSelection(shelf)
                                },
                                onClose: {
                                    handleCloseShelf()
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
                                    presentationStyle: tabletopLayoutStyle,
                                    mode: resolvedMode,
                                    setupInstruction: projection.setupGuidanceText,
                                    discardPanel: projection.discardPanelModel,
                                    devCardPanel: devCardPanelModel,
                                    robberVictimOptions: projection.robberVictimOptions,
                                    selectedHandCounts: selectedTradeHandCounts,
                                    onSelectHandResource: nil,
                                    selectedRecipients: selectedRecipients,
                                    onSelectRecipient: nil,
                                    discardSelectedHandCounts: selectedDiscardHandCounts,
                                    onSelectDiscardResource: { resource in
                                        addDiscardResource(resource)
                                    },
                                    onRemoveDiscardResource: { resource in
                                        removeDiscardResource(resource)
                                    },
                                    onSelectBuild: { buildKind in
                                        handleBuildShelfSelection(buildKind)
                                    },
                                    onSelectBankResource: { resource in
                                        handleBankResourceSelection(resource, mode: resolvedMode)
                                    },
                                    onDiscardAction: {
                                        guard viewModel.handleDiscardFlowAction(discarded: discardDraft) else { return }
                                        discardDraft = .zero
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
                                        handleCancelBoardCommit(
                                            isNormalPostRollTurn: isNormalPostRollTurn,
                                            mode: resolvedMode
                                        )
                                    },
                                    onSelectStealVictim: { victimPlayer in
                                        guard viewModel.publishRobberVictimState(victimPlayer: victimPlayer) else { return }
                                        currentMode = .idle
                                        clearBoardSelection()
                                    }
                                )
                            }
                            .frame(height: overlayShelfLayout.totalHeight, alignment: .top)
                            .frame(maxWidth: lowerRailWidth)
                            .padding(.horizontal, GameTheme.shellPadding)
                            .padding(
                                .bottom,
                                GameTheme.shellPadding
                                    + (tabletopLayoutStyle.usesFeltTools
                                        ? shellLayout.trayHeight
                                        : shellLayout.lowerRail.dockHeight)
                            )
                            .zIndex(1)
                        }

                        if !isGameOver,
                           isPhysicalGameplayTurn,
                           shellRoute == .gameInfo {
                            GameTurnGameInfoView(
                                model: screenModel.gameInfo,
                                onClose: handleGameInfoToggle
                            )
                            .frame(
                                height: usesPhysicalProps
                                    ? actionSurfaceHeight
                                    : feltToolSurfaceHeight
                            )
                            .frame(maxWidth: lowerRailWidth)
                            .padding(.horizontal, GameTheme.shellPadding)
                            .padding(
                                .bottom,
                                GameTheme.shellPadding
                                    + (usesPhysicalProps ? bottomTrayHeight : shellLayout.trayHeight)
                            )
                            .zIndex(1)
                        }

                        if !isGameOver,
                           isNormalPostRollTurn,
                           shellRoute == .endTurnConfirmation {
                            GameTurnEndConfirmationView(
                                onCancel: handleEndTurnConfirmationCancel,
                                onConfirm: handleEndTurnConfirmationConfirm
                            )
                            .frame(
                                height: usesPhysicalProps
                                    ? actionSurfaceHeight
                                    : feltToolSurfaceHeight
                            )
                            .frame(maxWidth: lowerRailWidth)
                            .padding(.horizontal, GameTheme.shellPadding)
                            .padding(
                                .bottom,
                                GameTheme.shellPadding
                                    + (usesPhysicalProps ? bottomTrayHeight : shellLayout.trayHeight)
                            )
                            .zIndex(1)
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
                                usesFixedActionWell: tabletopLayoutStyle.usesFeltTools,
                                usesPhysicalProps: usesPhysicalProps,
                                availableWidth: lowerRailWidth,
                                bankChips: bankTrayModel.chips,
                                handChips: screenModel.handTray.chips,
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
                                height: usesPhysicalProps
                                    ? physicalTradeSurfaceHeight
                                    : tabletopLayoutStyle.usesFeltTools
                                        ? feltToolSurfaceHeight
                                        : tradePanelHeight,
                                alignment: .top
                            )
                            .clipped()
                            .frame(maxWidth: lowerRailWidth)
                            .padding(.horizontal, GameTheme.shellPadding)
                            .padding(
                                .bottom,
                                usesPhysicalProps
                                    ? physicalTradeBottomPadding
                                    : tabletopLayoutStyle.usesFeltTools
                                        ? GameTheme.shellPadding + shellLayout.trayHeight
                                    : tradePanelBottomPadding(
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
                            onComplete: {
                                self.physicalDiceRollResult = nil
                            }
                        )
                        .frame(width: shellSize.width, height: shellSize.height)
                        .zIndex(5)
                    }

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
            if newMode != .discard {
                discardDraft = .zero
            }
            if newMode.isForcedBoardMode {
                shellRoute = .none
            }
            synchronizeHandTrayVisibility(for: newMode)
        }
        .onChange(of: screenModel.boardRenderModel) { _, _ in
            synchronizeBoardSelection(mode: resolvedMode)
        }
        .onDisappear {
            clearShellResizeFreeze()
        }
    }

    private func resolvedTabletopLayoutStyle(
        isNormalPostRollTurn: Bool,
        isNormalPreRollTurn: Bool,
        hasNotPrimaryPlayerContext: Bool,
        isSetupPlacement: Bool,
        isForcedDiscard: Bool
    ) -> GameTabletopLayoutStyle {
#if DEBUG
        let testingStyle = GameTabletopLayoutStyle(
            rawValue: uxTestingTabletopLayoutStyleRawValue
        )
        return GameTabletopLayoutStyleResolver.resolve(
            isNormalPostRollTurn: isNormalPostRollTurn,
            isNormalPreRollTurn: isNormalPreRollTurn,
            hasNotPrimaryPlayerContext: hasNotPrimaryPlayerContext,
            isSetupPlacement: isSetupPlacement,
            isForcedDiscard: isForcedDiscard,
            testingStyle: testingStyle
        )
#else
        return GameTabletopLayoutStyleResolver.resolve(
            isNormalPostRollTurn: isNormalPostRollTurn,
            isNormalPreRollTurn: isNormalPreRollTurn,
            hasNotPrimaryPlayerContext: hasNotPrimaryPlayerContext,
            isSetupPlacement: isSetupPlacement,
            isForcedDiscard: isForcedDiscard
        )
#endif
    }

    private func resolvedShelfPresentation(
        mode: GameMode,
        usesPhysicalProps: Bool
    ) -> GameShelfPresentation {
        if mode == .discard, usesPhysicalProps {
            return .none
        }
        if mode == .discard || mode == .robberVictim {
            return .forcedFlow
        }
        switch shellRoute {
        case let .utility(shelf):
            return .utility(shelf)
        case .build:
            return .action(.build)
        case .devCards:
            return .action(.devCards)
        case .trade, .endTurnConfirmation, .gameInfo, .none:
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
            return "Play dev card"
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
        physicalDiceRollResult = result

        Task { @MainActor in
            await Task.yield()
            guard physicalDiceRollResult == result else { return }
            guard viewModel.publishDiceRoll() == result else {
                physicalDiceRollResult = nil
                return
            }
        }
    }

    private func handleUtilityHandleToggle(canPresentUtilityShelf: Bool) {
        if case .trade = shellRoute {
            return
        }

        if case .utility = shellRoute {
            shellRoute = .none
        } else {
            guard canPresentUtilityShelf else {
                return
            }
            switchToUtilityShelf(lastUtilityShelf)
        }
        clearBoardSelection()
    }

    private func handleHandToggle() {
        if viewModel.isNormalPostRollActiveTurn {
            if isHandOpen {
                withAnimation(accessibilityReduceMotion ? .linear(duration: 0.01) : GameTheme.quickAnimation) {
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

            withAnimation(accessibilityReduceMotion ? .linear(duration: 0.01) : GameTheme.quickAnimation) {
                isHandOpen = true
            }
            return
        }

        if case .utility = shellRoute {
            shellRoute = .none
        }

        withAnimation(accessibilityReduceMotion ? .linear(duration: 0.01) : GameTheme.quickAnimation) {
            isHandOpen.toggle()
        }
        clearBoardSelection()
    }

    private func handleUtilityShelfSelection(_ shelf: GameLowerShelf) {
        if shelf != .hand {
            lastUtilityShelf = shelf
            isHandOpen = false
        }
        if shellRoute.utilityShelf == shelf {
            shellRoute = .none
        } else {
            switchToUtilityShelf(shelf)
        }
        clearBoardSelection()
    }

    private func handleCloseShelf() {
        switch shellRoute {
        case .utility:
            self.shellRoute = .none
            clearBoardSelection()
        case .build:
            self.currentMode = .idle
            self.shellRoute = .none
            clearBoardSelection()
        case .devCards:
            dismissDevCardFlow()
        case .trade:
            closeTradePanel(resetDraft: true)
        case .endTurnConfirmation, .gameInfo:
            self.currentMode = .idle
            self.shellRoute = .none
            clearBoardSelection()
        case .none:
            break
        }
    }

    private func handleGameInfoToggle() {
        if shellRoute == .gameInfo {
            shellRoute = .none
        } else {
            if case .trade = shellRoute {
                closeTradePanel(resetDraft: true)
            }
            currentMode = .idle
            devCardDraft = nil
            isHandOpen = false
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
        if resetDraft {
            shellRoute = .none
        }
        clearBoardSelection()
    }

    private func startPlayerTradeDraft() {
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

    private func switchToUtilityShelf(_ shelf: GameLowerShelf) {
        currentMode = .idle
        devCardDraft = nil

        if shelf == .hand {
            isHandOpen = true
            shellRoute = .none
            return
        }

        shellRoute = .utility(shelf)
    }

    private func tradeSelectedHandCounts(route: GameTradeOverlayRoute?) -> [ResourceV1: Int] {
        guard case let .playerDraft(draft)? = route else {
            return [:]
        }
        return tradeCountMap(for: draft.give)
    }

    private func tradeSelectedRecipients(route: GameTradeOverlayRoute?) -> Set<String> {
        guard case let .playerDraft(draft)? = route else {
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

    private func overlayShelfKind(for presentation: GameShelfPresentation) -> GameShellLayoutMetrics.OverlayShelfKind {
        switch presentation {
        case .utility, .none:
            return .utility
        case let .action(shelf):
            return shelf == .devCards ? .devCards : .build
        case .forcedFlow:
            return .forcedFlow
        }
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
        lastUtilityShelf = .bank
        clearShellResizeFreeze()
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

        if case .utility = resolvedShelfPresentation(
            mode: currentMode,
            usesPhysicalProps: false
        ) {
            self.shellRoute = .none
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

private struct GamePhysicalBoardFramePreferenceKey: PreferenceKey {
    static let defaultValue: CGRect = .zero

    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        let next = nextValue()
        if next.height > 0 {
            value = next
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

private struct GameOverlayShelfView<Content: View>: View {
    let layout: GameShellLayoutMetrics.OverlayShelfMetrics
    let presentation: GameShelfPresentation
    let currentMode: GameMode
    let tabletopLayoutStyle: GameTabletopLayoutStyle
    let onSelectUtilityShelf: (GameLowerShelf) -> Void
    let onClose: () -> Void
    let content: Content

    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion

    init(
        layout: GameShellLayoutMetrics.OverlayShelfMetrics,
        presentation: GameShelfPresentation,
        currentMode: GameMode,
        tabletopLayoutStyle: GameTabletopLayoutStyle,
        onSelectUtilityShelf: @escaping (GameLowerShelf) -> Void,
        onClose: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.layout = layout
        self.presentation = presentation
        self.currentMode = currentMode
        self.tabletopLayoutStyle = tabletopLayoutStyle
        self.onSelectUtilityShelf = onSelectUtilityShelf
        self.onClose = onClose
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            header
                .frame(maxWidth: .infinity, minHeight: layout.headerHeight, maxHeight: layout.headerHeight)

            Divider()
                .overlay(panelDividerColor)

            contentContainer
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .frame(maxWidth: .infinity, minHeight: layout.totalHeight, maxHeight: layout.totalHeight, alignment: .top)
        .background(panelBackground)
        .overlay(panelOverlay)
        .clipShape(panelShape)
        .contentShape(panelShape)
        .transition(
            accessibilityReduceMotion
                ? .opacity
                : .move(edge: .bottom).combined(with: .opacity)
        )
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(
            tabletopLayoutStyle.usesFeltTools
                ? "uls.feltTools.componentSurface"
                : "uls.overlayShelf"
        )
    }

    @ViewBuilder
    private var contentContainer: some View {
        if usesScrollContainer {
            ScrollView(
                .vertical,
                showsIndicators: tabletopLayoutStyle.usesFeltTools
            ) {
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
            if tabletopLayoutStyle.usesFeltTools {
                HStack(spacing: GameTheme.inlineSpacing) {
                    Label(selectedShelf.title, systemImage: selectedShelf.systemImage)
                        .font(GameTheme.metaFont.weight(.semibold))
                        .foregroundStyle(panelInk)

                    Spacer(minLength: 0)

                    if presentation.isClosable {
                        closeButton
                    }
                }
                .padding(.horizontal, GameTheme.compactPadding)
            } else {
                HStack(spacing: GameTheme.inlineSpacing) {
                    ForEach([GameLowerShelf.hand, .bank, .players], id: \.rawValue) { shelf in
                        UtilityHeaderTabButton(
                            title: shelf.title,
                            isSelected: selectedShelf == shelf,
                            usesFeltTools: false
                        ) {
                            onSelectUtilityShelf(shelf)
                        }
                    }

                    if presentation.isClosable {
                        closeButton
                    }
                }
                .padding(.horizontal, GameTheme.compactPadding)
            }
        case let .action(shelf):
            HStack(spacing: GameTheme.inlineSpacing) {
                Label(shelf.title, systemImage: shelf.systemImage)
                    .font(GameTheme.metaFont.weight(.semibold))
                    .foregroundStyle(panelInk)
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
                    .foregroundStyle(panelInk)
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
            Image(systemName: "arrow.down")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(tabletopLayoutStyle.usesFeltTools ? GameTheme.surface : GameTheme.mutedInk)
                .frame(width: 44, height: 44)
                .background(
                    tabletopLayoutStyle.usesFeltTools
                        ? GameTheme.felt
                        : GameTheme.surface.opacity(0.9)
                )
                .overlay(
                    Circle()
                        .stroke(
                            tabletopLayoutStyle.usesFeltTools
                                ? GameTheme.surface.opacity(0.20)
                                : GameTheme.outline.opacity(0.12),
                            lineWidth: 1
                        )
                )
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tabletopLayoutStyle.usesFeltTools ? "Close tools" : "Close shelf")
    }

    private var panelInk: Color {
        tabletopLayoutStyle.usesFeltTools ? GameTheme.surface : GameTheme.ink
    }

    private var panelDividerColor: Color {
        tabletopLayoutStyle.usesFeltTools
            ? .clear
            : GameTheme.outline.opacity(0.10)
    }

    @ViewBuilder
    private var panelBackground: some View {
        if tabletopLayoutStyle.usesFeltTools {
            Color.clear
        } else {
            RoundedRectangle(cornerRadius: GameTheme.largeRadius)
                .fill(GameTheme.surface.opacity(0.985))
                .shadow(color: GameTheme.trayShadow.opacity(0.86), radius: 14, x: 0, y: -3)
        }
    }

    @ViewBuilder
    private var panelOverlay: some View {
        if tabletopLayoutStyle.usesFeltTools {
            Color.clear
        } else {
            RoundedRectangle(cornerRadius: GameTheme.largeRadius)
                .stroke(GameTheme.outline.opacity(0.14), lineWidth: 1)
        }
    }

    private var panelShape: AnyShape {
        if tabletopLayoutStyle.usesFeltTools {
            return AnyShape(Rectangle())
        }
        return AnyShape(RoundedRectangle(cornerRadius: GameTheme.largeRadius))
    }

    private var usesScrollContainer: Bool {
        switch presentation {
        case .utility:
            return layout.contentHeight < GameShellLayoutMetrics.minimumUtilityShelfScrollHeight
        case let .action(shelf):
            return shelf == .devCards
        case .forcedFlow:
            return true
        case .none:
            return false
        }
    }

    private var contentPadding: CGFloat {
        if tabletopLayoutStyle.usesFeltTools {
            return 4
        }

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
    let usesFeltTools: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(GameTheme.metaFont.weight(.semibold))
                .foregroundStyle(textColor)
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
        if usesFeltTools {
            return isSelected ? GameTheme.accent.opacity(0.60) : GameTheme.felt.opacity(0.84)
        }
        return isSelected ? GameTheme.accent.opacity(0.18) : GameTheme.surface.opacity(0.84)
    }

    private var borderColor: Color {
        if usesFeltTools {
            return isSelected ? GameTheme.surface.opacity(0.34) : GameTheme.surface.opacity(0.14)
        }
        return isSelected ? GameTheme.accent.opacity(0.40) : GameTheme.outline.opacity(0.12)
    }

    private var textColor: Color {
        if usesFeltTools {
            return isSelected ? GameTheme.surface : GameTheme.surface.opacity(0.72)
        }
        return isSelected ? GameTheme.ink : GameTheme.mutedInk
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
    let usesFixedActionWell: Bool
    let usesPhysicalProps: Bool
    let availableWidth: CGFloat
    let bankChips: [GameBankChip]
    let handChips: [GameHandChip]
    let recipientSummaries: [GameOpponentSummary]
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

    private let tradeableResources: [ResourceV1] = [.wood, .brick, .sheep, .wheat, .ore]
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion

    var body: some View {
        let density = ResourceChipDensity.resolve(
            availableWidth: max(availableWidth - (GameTheme.compactPadding * 2), 0),
            availableHeight: 160
        )

        VStack(alignment: .leading, spacing: GameTheme.inlineSpacing) {
            if !usesPhysicalProps {
                header
            }

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
        .padding(usesPhysicalProps ? 0 : GameTheme.compactPadding)
        .frame(
            maxWidth: usesFixedActionWell ? .infinity : nil,
            maxHeight: usesFixedActionWell ? .infinity : nil,
            alignment: .topLeading
        )
        .background(surfaceBackground)
        .overlay(surfaceOverlay)
        .clipShape(surfaceShape)
        .contentShape(surfaceShape)
        .transition(
            accessibilityReduceMotion || usesPhysicalProps
                ? .opacity
                : .move(edge: .bottom).combined(with: .opacity)
        )
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("uls.turn.tradeSurface")
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
                    .frame(width: 44, height: 44)
                    .background(GameTheme.surface.opacity(0.88))
                    .overlay(
                        Circle()
                            .stroke(GameTheme.outline.opacity(0.14), lineWidth: 1)
                    )
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close trade panel")
        }
    }

    @ViewBuilder
    private var chooserBody: some View {
        if usesPhysicalProps {
            HStack(spacing: 24) {
                physicalTradeChoice(
                    title: "Player Trade",
                    systemImage: "person.2.fill",
                    action: onChoosePlayerTrade
                )

                physicalTradeChoice(
                    title: "Maritime / Bank",
                    assetName: "merchant_ship_colored",
                    isDisabled: panelModel.maritimeOptions.isEmpty,
                    action: onChooseMaritimeTrade
                )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        } else if usesFixedActionWell {
            ScrollView(.vertical, showsIndicators: true) {
                chooserCards
            }
            .scrollBounceBehavior(.basedOnSize)
        } else {
            chooserCards
        }
    }

    private func physicalTradeChoice(
        title: String,
        systemImage: String? = nil,
        assetName: String? = nil,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Group {
                    if let assetName {
                        Image(assetName)
                            .resizable()
                            .scaledToFit()
                    } else if let systemImage {
                        Image(systemName: systemImage)
                            .resizable()
                            .scaledToFit()
                    }
                }
                .frame(width: 42, height: 34)
                .foregroundStyle(GamePhysicalTurnPalette.primaryText)

                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(GamePhysicalTurnPalette.primaryText)
                    .lineLimit(1)
            }
            .frame(width: 128)
            .frame(minHeight: 72)
            .contentShape(Rectangle())
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        GamePhysicalTurnPalette.selectedKeyline.opacity(isDisabled ? 0.20 : 0.72),
                        lineWidth: 1.25
                    )
            }
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.45 : 1)
    }

    @ViewBuilder
    private var surfaceBackground: some View {
        if usesPhysicalProps {
            Color.clear
        } else {
            RoundedRectangle(cornerRadius: GameTheme.largeRadius)
                .fill(GameTheme.surface.opacity(0.985))
                .shadow(color: GameTheme.trayShadow.opacity(0.86), radius: 14, x: 0, y: -3)
        }
    }

    @ViewBuilder
    private var surfaceOverlay: some View {
        if usesPhysicalProps {
            Color.clear
        } else {
            RoundedRectangle(cornerRadius: GameTheme.largeRadius)
                .stroke(GameTheme.outline.opacity(0.14), lineWidth: 1)
        }
    }

    private var surfaceShape: AnyShape {
        usesPhysicalProps
            ? AnyShape(Rectangle())
            : AnyShape(RoundedRectangle(cornerRadius: GameTheme.largeRadius))
    }

    private var chooserCards: some View {
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
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func composerBody(
        draft: GameTradeDraft,
        density: ResourceChipDensity
    ) -> some View {
        VStack(alignment: .leading, spacing: GameTheme.inlineSpacing) {
            ScrollView(
                .vertical,
                showsIndicators: usesFixedActionWell
            ) {
                VStack(alignment: .leading, spacing: GameTheme.inlineSpacing) {
                    giveComposerSection(draft: draft, density: density)
                    wantComposerSection(draft: draft, density: density)
                    recipientsComposerSection(draft: draft)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .scrollBounceBehavior(.basedOnSize)

            HStack(spacing: GameTheme.inlineSpacing) {
                Button("Cancel") {
                    onBackDraftStep()
                }
                .frame(maxWidth: .infinity, minHeight: 44)
                .buttonStyle(.bordered)

                Button(primaryDraftButtonTitle(for: draft)) {
                    onSendDraft()
                }
                .frame(maxWidth: .infinity, minHeight: 44)
                .buttonStyle(.borderedProminent)
                .disabled(!canAdvance(draft: draft))
            }
        }
    }

    private var maritimeBody: some View {
        VStack(alignment: .leading, spacing: GameTheme.inlineSpacing) {
            if usesFixedActionWell {
                ScrollView(.vertical, showsIndicators: true) {
                    maritimeOptionsList
                }
                .scrollBounceBehavior(.basedOnSize)
            } else {
                maritimeOptionsList
            }

            Button("Back") {
                onBackDraftStep()
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .buttonStyle(.bordered)
        }
    }

    @ViewBuilder
    private var maritimeOptionsList: some View {
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
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var liveOfferBody: some View {
        if usesPhysicalProps,
           let activeOffer = panelModel.activeOffer,
           let responderActions = panelModel.responderActions {
            GamePhysicalIncomingTradeView(
                offer: activeOffer,
                actions: responderActions,
                onAccept: onAcceptOffer,
                onDecline: onDeclineOffer,
                onCounter: onStartCounterDraft
            )
        } else {
            VStack(alignment: .leading, spacing: GameTheme.inlineSpacing) {
                ScrollView(
                    .vertical,
                    showsIndicators: usesFixedActionWell
                ) {
                    VStack(alignment: .leading, spacing: GameTheme.inlineSpacing) {
                        if usesPhysicalProps {
                            Text(panelModel.roleTitle)
                                .font(.caption.weight(.bold))
                                .foregroundStyle(GamePhysicalTurnPalette.primaryText)
                        }

                        if let activeOffer = panelModel.activeOffer {
                            offerCard(activeOffer)
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
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .scrollBounceBehavior(.basedOnSize)

                if let responderActions = panelModel.responderActions {
                    responderActionRow(responderActions)
                } else if panelModel.canReplaceOffer {
                    if usesPhysicalProps {
                        Button("Replace Offer", action: onReplaceOffer)
                            .buttonStyle(GameTabletopActionButtonStyle(emphasis: .primary))
                            .frame(width: 144)
                            .frame(maxWidth: .infinity)
                    } else {
                        Button("Replace Offer", action: onReplaceOffer)
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .buttonStyle(.bordered)
                    }
                }
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

    private func giveComposerSection(
        draft: GameTradeDraft,
        density: ResourceChipDensity
    ) -> some View {
        tradeComposerSection(title: "You Give", detail: "Tap your hand to add cards to the offer.") {
            if handChips.isEmpty {
                Text("No resources in hand.")
                    .font(GameTheme.metaFont)
                    .foregroundStyle(GameTheme.mutedInk)
            } else {
                ResourceChipGridView(items: handChips, density: density) { chip in
                    giveResourceChip(chip, draft: draft, density: density)
                }
            }

            selectedResourceSection(
                title: "Selected",
                hand: draft.give,
                density: density,
                emptyText: "Nothing selected yet.",
                action: onRemoveGiveResource
            )
        }
    }

    private func wantComposerSection(
        draft: GameTradeDraft,
        density: ResourceChipDensity
    ) -> some View {
        tradeComposerSection(title: "You Want", detail: "Bank counts stay visible while you build the ask.") {
            ResourceChipGridView(items: bankChips, density: density) { chip in
                wantResourceChip(chip, draft: draft, density: density)
            }

            selectedResourceSection(
                title: "Requested",
                hand: draft.receive,
                density: density,
                emptyText: "Nothing requested yet.",
                action: onRemoveWantResource
            )
        }
    }

    private func recipientsComposerSection(draft: GameTradeDraft) -> some View {
        tradeComposerSection(title: "Recipients", detail: recipientCopy(for: draft)) {
            if draft.isCounter {
                recipientLockup(for: draft.recipients)
            } else if usesFixedActionWell {
                recipientRows(draft: draft)
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    recipientRows(draft: draft)
                }
                .frame(maxHeight: 104)
            }
        }
    }

    private func recipientRows(draft: GameTradeDraft) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(recipientSummaries) { summary in
                recipientToggleRow(
                    summary: summary,
                    isSelected: draft.recipients.contains(summary.id)
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func tradeComposerSection<Content: View>(
        title: String,
        detail: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(GameTheme.metaFont.weight(.semibold))
                .foregroundStyle(GameTheme.ink)

            Text(detail)
                .font(GameTheme.metaFont)
                .foregroundStyle(GameTheme.mutedInk)
                .fixedSize(horizontal: false, vertical: true)

            content()
        }
        .padding(GameTheme.compactPadding)
        .background(GameTheme.surface.opacity(0.92))
        .overlay(
            RoundedRectangle(cornerRadius: GameTheme.mediumRadius)
                .stroke(GameTheme.outline.opacity(0.14), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: GameTheme.mediumRadius))
    }

    private func selectedResourceSection(
        title: String,
        hand: ResourceHandV1,
        density: ResourceChipDensity,
        emptyText: String,
        action: @escaping (ResourceV1) -> Void
    ) -> some View {
        let chips = chips(from: hand)

        return VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(GameTheme.metaFont.weight(.semibold))
                .foregroundStyle(GameTheme.ink)

            if chips.isEmpty {
                Text(emptyText)
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
                        accessibilityLabel: "\(chip.shortLabel), remove one from selection"
                    )
                }
            }
        }
    }

    private func giveResourceChip(
        _ chip: GameHandChip,
        draft: GameTradeDraft,
        density: ResourceChipDensity
    ) -> some View {
        let selected = count(for: chip.resource, in: draft.give)
        let canAdd = selected < chip.count
        return ResourceCountChipView(
            resource: chip.resource,
            label: chip.shortLabel,
            count: chip.count,
            isEnabled: canAdd,
            isSelected: selected > 0,
            selectionBadge: selected > 0 ? String(selected) : nil,
            detailBadge: canAdd ? "+" : nil,
            density: density,
            action: canAdd ? {
                onAddGiveResource(chip.resource)
            } : nil,
            accessibilityLabel: "\(chip.shortLabel), \(chip.count) in hand, \(selected) selected"
        )
    }

    private func wantResourceChip(
        _ chip: GameBankChip,
        draft: GameTradeDraft,
        density: ResourceChipDensity
    ) -> some View {
        let selected = count(for: chip.resource, in: draft.receive)
        let canAdd = selected < chip.count
        return ResourceCountChipView(
            resource: chip.resource,
            label: chip.resource.shortLabel,
            count: chip.count,
            isEnabled: canAdd,
            isSelected: selected > 0,
            selectionBadge: selected > 0 ? String(selected) : nil,
            detailBadge: canAdd ? "+" : nil,
            density: density,
            action: canAdd ? {
                onAddWantResource(chip.resource)
            } : nil,
            accessibilityLabel: "\(chip.resource.shortLabel), \(chip.count) left in bank, \(selected) requested"
        )
    }

    private func recipientLockup(for recipients: [String]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(recipients, id: \.self) { recipientID in
                Text(displayName(for: recipientID))
                    .font(GameTheme.metaFont.weight(.semibold))
                    .foregroundStyle(GameTheme.ink)
            }
        }
    }

    private func recipientToggleRow(
        summary: GameOpponentSummary,
        isSelected: Bool
    ) -> some View {
        Button {
            onToggleRecipient(summary.id)
        } label: {
            HStack(spacing: GameTheme.inlineSpacing) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(summary.displayName)
                        .font(GameTheme.metaFont.weight(.semibold))
                        .foregroundStyle(GameTheme.ink)
                    Text("\(summary.victoryPoints) VP · \(summary.handCount) cards")
                        .font(GameTheme.metaFont)
                        .foregroundStyle(GameTheme.mutedInk)
                }

                Spacer(minLength: 0)

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(GameTheme.accent)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, GameTheme.compactPadding)
            .padding(.vertical, 8)
            .background(isSelected ? GameTheme.accent.opacity(0.14) : GameTheme.surface.opacity(0.84))
            .overlay(
                RoundedRectangle(cornerRadius: GameTheme.smallRadius)
                    .stroke(isSelected ? GameTheme.accent.opacity(0.40) : GameTheme.outline.opacity(0.12), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: GameTheme.smallRadius))
        }
        .buttonStyle(.plain)
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

    private func participantStatusRow(_ status: GameTradeParticipantStatus) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: GameTheme.inlineSpacing) {
                Text(status.displayName)
                    .font(GameTheme.metaFont.weight(.semibold))
                    .foregroundStyle(GameTheme.ink)

                if status.isTargeted {
                    Text("Targeted")
                        .font(.system(size: 10, weight: .bold))
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
        GameTradeResponderActionRow(
            actions: responderActions,
            usesPhysicalProps: usesPhysicalProps,
            onAccept: onAcceptOffer,
            onDecline: onDeclineOffer,
            onCounter: onStartCounterDraft
        )
    }

    private func recipientCopy(for draft: GameTradeDraft) -> String {
        switch draft.kind {
        case .offer:
            return "Choose one or more players who should receive this offer."
        case let .counter(originalProposerID):
            let proposer = displayName(for: originalProposerID)
            return "Counters go back only to \(proposer)."
        }
    }

    private func primaryDraftButtonTitle(for draft: GameTradeDraft) -> String {
        draft.isCounter ? "Send Counter" : "Send Offer"
    }

    private func canAdvance(draft: GameTradeDraft) -> Bool {
        !draft.give.isZero && !draft.receive.isZero && !draft.recipients.isEmpty
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

    private func displayName(for playerID: String) -> String {
        recipientSummaries.first(where: { $0.id == playerID })?.displayName
            ?? panelModel.activeOffer?.proposerDisplay
            ?? "Player"
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
