import SwiftUI
import ULS_CoreGame

struct GameShellView: View {
    @ObservedObject var viewModel: LobbyDriverViewModel
    @State private var currentMode: GameMode = .idle
    @State private var selectedBoardTarget: GameBoardTarget?
    @State private var boardHintText: String?
    @State private var devCardDraft: GameDevCardDraft?
    @State private var manualShelfPresentation: GameShelfPresentation = .none
    @State private var lastUtilityShelf: GameLowerShelf = .hand

    var body: some View {
        let screenModel = viewModel.gameScreenModel
        let isGameOver = viewModel.phase == PhaseV1.gameOver.rawValue
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
                let shellLayout = GameShellLayoutMetrics.resolve(
                    availableHeight: max(geometry.size.height - (GameTheme.shellPadding * 2), 0),
                    spacing: GameTheme.sectionSpacing
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
                                    handleUtilityHandleToggle(currentMode: resolvedMode)
                                }
                            )
                            .frame(height: shellLayout.trayHeight, alignment: .top)
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
                                handTray: screenModel.handTray,
                                bankTray: bankTrayModel,
                                opponents: screenModel.opponents,
                                actionDock: screenModel.actionDock,
                                selectedBuildKind: resolvedMode.buildShelfKind,
                                mode: resolvedMode,
                                setupInstruction: viewModel.setupGuidanceText,
                                discardPanel: viewModel.discardPanelModel,
                                tradePanel: viewModel.tradePanelModel,
                                devCardPanel: devCardPanelModel,
                                robberVictimOptions: viewModel.robberVictimOptions,
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
                                onSelectStealVictim: { victimPlayer in
                                    guard viewModel.publishRobberVictimState(victimPlayer: victimPlayer) else { return }
                                    currentMode = .idle
                                    selectedBoardTarget = nil
                                }
                            )
                        }
                        .frame(height: shellLayout.overlayShelf.totalHeight, alignment: .top)
                        .padding(.horizontal, GameTheme.shellPadding)
                        .padding(.bottom, GameTheme.shellPadding + shellLayout.lowerRail.dockHeight)
                        .zIndex(1)
                    }
                }
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
                manualShelfPresentation = .none
            }
        }
        .onChange(of: screenModel.boardRenderModel) { _, _ in
            synchronizeBoardSelection(mode: resolvedMode)
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
            self.selectedBoardTarget = nil
            self.boardHintText = nil
            self.manualShelfPresentation = .none
            self.devCardDraft = nil
            return
        }

        self.boardHintText = nil
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
                self.selectedBoardTarget = nil
                self.manualShelfPresentation = .none
                self.devCardDraft = nil
            } else {
                self.currentMode = .idle
                self.selectedBoardTarget = nil
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
            self.selectedBoardTarget = nil
            self.manualShelfPresentation = .none
            self.devCardDraft = nil
        case .trade:
            self.currentMode = .trade
            self.selectedBoardTarget = nil
            self.manualShelfPresentation = .utility(.hand)
            self.lastUtilityShelf = .hand
        case .roll, .endTurn:
            self.currentMode = .idle
            self.selectedBoardTarget = nil
            self.manualShelfPresentation = .none
            self.devCardDraft = nil
        }
    }

    private func handleUtilityHandleToggle(currentMode: GameMode) {
        let presentation = resolvedShelfPresentation(mode: currentMode)
        if case .utility = presentation {
            if currentMode == .trade {
                self.currentMode = .idle
            }
            self.manualShelfPresentation = .none
        } else {
            if currentMode == .trade {
                self.currentMode = .idle
            }
            self.manualShelfPresentation = .utility(lastUtilityShelf)
        }
        self.selectedBoardTarget = nil
        self.boardHintText = nil
    }

    private func handleUtilityShelfSelection(_ shelf: GameLowerShelf, currentMode: GameMode) {
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
        self.selectedBoardTarget = nil
        self.boardHintText = nil
    }

    private func handleCloseShelf(currentMode: GameMode) {
        switch resolvedShelfPresentation(mode: currentMode) {
        case .utility:
            if currentMode == .trade {
                self.currentMode = .idle
            }
            self.manualShelfPresentation = .none
            self.selectedBoardTarget = nil
            self.boardHintText = nil
        case let .action(shelf):
            if shelf == .devCards {
                dismissDevCardFlow()
            } else {
                self.currentMode = .idle
                self.manualShelfPresentation = .none
                self.selectedBoardTarget = nil
                self.boardHintText = nil
            }
        case .forcedFlow, .none:
            break
        }
    }

    private func handleTradeShelfSelection() {
        guard viewModel.tradePanelModel != nil else {
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
        selectedBoardTarget = nil
        boardHintText = nil
    }

    private func handleBuildShelfSelection(_ buildKind: GameBuildShelfItem.Kind) {
        manualShelfPresentation = .action(.build)
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
        selectedBoardTarget = nil
        boardHintText = nil
    }

    private func dismissDevCardFlow() {
        devCardDraft = nil
        currentMode = .idle
        selectedBoardTarget = nil
        boardHintText = nil
        manualShelfPresentation = .none
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
                    .padding(GameTheme.compactPadding)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .scrollBounceBehavior(.basedOnSize)
        } else {
            content
                .padding(GameTheme.compactPadding)
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
