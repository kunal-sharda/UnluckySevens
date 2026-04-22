import Combine
import Foundation
import Messages
import ULS_CoreGame
import ULS_Transport

@MainActor
final class LobbyDriverViewModel: ObservableObject {
    @Published private(set) var gameplayShellProjection: GameShellProjection = .empty
    @Published var observedJoinersDebug: String = "[]"
    @Published var selectionStatus: String = "No message selected"
    @Published var selectedTrigger: String = "-"
    @Published var selectedMessagePresence: String = "missing"
    @Published var selectedURLPresence: String = "missing"
    @Published var selectedURLString: String = "-"
    @Published var selectedPayloadQueryPresence: String = "missing"
    @Published var selectedPayloadLength: String = "-"
    @Published var selectedSummaryText: String = "-"
    @Published var selectedLayoutCaption: String = "-"
    @Published var selectedSessionPresence: String = "missing"
    @Published var selectedDecodeSource: String = "-"
    @Published var selectedDecodeResult: String = "No message selected"
    @Published var lastPublishSelectionSnapshot: String = "-"
    @Published var didReceiveCount: String = "0"
    @Published var lastDidReceiveTransport: String = "-"
    @Published var lastDidReceiveGameId: String = "-"
    @Published var lastDidReceiveDisposition: String = "-"
    @Published var lastDidReceiveOutcome: String = "-"
    @Published var didReceiveHistory: [String] = []
    @Published var lifecycleState: String = "initial"
    @Published var lastLifecycleEvent: String = "-"
    @Published var lifecycleHistory: [String] = []
    @Published var lastSessionResolve: String = "-"
    @Published var sessionCacheSummary: String = "empty"
    @Published var localParticipantDebug: String = "-"
    @Published var resolvedActorDebug: String = "-"
    @Published var localInRosterDebug: String = "-"
    @Published var localObservedJoinDebug: String = "-"
    @Published var canJoinDebug: String = "false"
    @Published var isInviterDebug: String = "-"
    @Published var lastError: String = "-"
    @Published var actingAs: String = "-"
    @Published var useSingleSessionDebug: Bool = false
    @Published var activeContextSource: String = "-"
    @Published var activeContextUpdatedAgo: String = "-"
    @Published var staleContextWarning: String = "-"
    @Published var latestUpdateNotice: String = "-"
    @Published var uiLog: [String] = []
    @Published var boardStrategy: BoardGenStrategyV1
    @Published private(set) var transportBadgeModel: TransportBadgeModel = .initial
    @Published private(set) var hostGestureHierarchySnapshot: HostGestureHierarchySnapshot = .empty
    @Published private(set) var hostGestureEvents: [HostGestureEvent] = []
    @Published private(set) var boardDiagnosticsSnapshot: BoardInteractionDiagnosticsSnapshot = .empty
    @Published private(set) var boardReloadToken: Int = 0
    @Published private(set) var recoveredGames: [ActiveGameRecoverySummary] = []
    @Published private(set) var dismissRequestToken: Int = 0

    private let summaryPayloadPrefix = "ulsenv:"
    private let boardStrategyKey = "uls.boardStrategy"
    private let userDefaults: UserDefaults
    private let gameLedgerStore: TranscriptGameLedgerStore
    private let diagnosticsConfig = TemporaryDiagnosticsConfig.live
    private let allowsRuntimeDebugControls = false
    private let allowsLocalLedgerStateRecovery = true
    private let showsLatestUpdateNotices = false

    private weak var activeConversation: MSConversation?
    var onRequestDismiss: (() -> Void)?
    private var selectedState: CoreGameStateV1?
    private var selectedJoinIntent: JoinIntentV1?
    private var selectedSetupIntent: SetupPlacementIntentV1?
    private var selectedTurnIntent: ULS_Transport.TurnIntentV1?
    private var latestKnownStatesByGameId: [String: CoreGameStateV1] = [:]
    private var latestUpdateNoticeToken: Int = 0
    private var activeUpdatedAt: Date?
    private var activeSource: ActiveContextSource?
    private var stateSessionsByGameId: [String: MSSession] = [:]
    private var lastResolvedSelectionSignature: String?
    private var didReceiveInvocationCount: Int = 0
    private var cachedBoardOverlayModelKey: BoardOverlayModelCacheKey?
    private var cachedBoardOverlayModelValue: GameBoardOverlayModel?
    private var cachedDevCardPanelModelKey: DevCardPanelModelCacheKey?
    private var cachedDevCardPanelModelValue: GameDevCardPanelModel??
    private var cachedBankTrayModelKey: BankTrayModelCacheKey?
    private var cachedBankTrayModelValue: GameBankTrayModel?

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        gameLedgerStore = TranscriptGameLedgerStore(userDefaults: userDefaults)
        if let rawValue = userDefaults.string(forKey: boardStrategyKey),
           let parsed = BoardGenStrategyV1(rawValue: rawValue) {
            boardStrategy = parsed
        } else {
            boardStrategy = .randomV1
        }
        let ledgerSnapshot = gameLedgerStore.bootstrapSnapshot()
        latestKnownStatesByGameId = ledgerSnapshot.latestKnownStatesByGameId
        refreshRecoveredGames()
    }

    private var diagnosticsEnabled: Bool {
        diagnosticsConfig.isEnabled
    }

    private func mutateGameplayShellProjection(
        _ mutate: (inout GameShellProjection) -> Void
    ) {
        var projection = gameplayShellProjection
        mutate(&projection)
        gameplayShellProjection = projection
    }

    var kind: String {
        get { gameplayShellProjection.kind }
        set { mutateGameplayShellProjection { $0.kind = newValue } }
    }
    var gameId: String {
        get { gameplayShellProjection.gameId }
        set { mutateGameplayShellProjection { $0.gameId = newValue } }
    }
    var rev: String {
        get { gameplayShellProjection.rev }
        set { mutateGameplayShellProjection { $0.rev = newValue } }
    }
    var prevHash: String {
        get { gameplayShellProjection.prevHash }
        set { mutateGameplayShellProjection { $0.prevHash = newValue } }
    }
    var stateHash: String {
        get { gameplayShellProjection.stateHash }
        set { mutateGameplayShellProjection { $0.stateHash = newValue } }
    }
    var roster: String {
        get { gameplayShellProjection.roster }
        set { mutateGameplayShellProjection { $0.roster = newValue } }
    }
    var currentPlayer: String {
        get { gameplayShellProjection.currentPlayer }
        set { mutateGameplayShellProjection { $0.currentPlayer = newValue } }
    }
    var phase: String {
        get { gameplayShellProjection.phase }
        set { mutateGameplayShellProjection { $0.phase = newValue } }
    }
    var seed: String {
        get { gameplayShellProjection.seed }
        set { mutateGameplayShellProjection { $0.seed = newValue } }
    }
    var diceRngState: String {
        get { gameplayShellProjection.diceRngState }
        set { mutateGameplayShellProjection { $0.diceRngState = newValue } }
    }
    var turnStep: String {
        get { gameplayShellProjection.turnStep }
        set { mutateGameplayShellProjection { $0.turnStep = newValue } }
    }
    var lastRoll: String {
        get { gameplayShellProjection.lastRoll }
        set { mutateGameplayShellProjection { $0.lastRoll = newValue } }
    }
    var pendingDiscardRequirements: String {
        get { gameplayShellProjection.pendingDiscardRequirements }
        set { mutateGameplayShellProjection { $0.pendingDiscardRequirements = newValue } }
    }
    var submittedDiscardsStatus: String {
        get { gameplayShellProjection.submittedDiscardsStatus }
        set { mutateGameplayShellProjection { $0.submittedDiscardsStatus = newValue } }
    }
    var robberMoveReadiness: String {
        get { gameplayShellProjection.robberMoveReadiness }
        set { mutateGameplayShellProjection { $0.robberMoveReadiness = newValue } }
    }
    var eligibleStealVictims: String {
        get { gameplayShellProjection.eligibleStealVictims }
        set { mutateGameplayShellProjection { $0.eligibleStealVictims = newValue } }
    }
    var remainingPieces: String {
        get { gameplayShellProjection.remainingPieces }
        set { mutateGameplayShellProjection { $0.remainingPieces = newValue } }
    }
    var activeTradeOffer: String {
        get { gameplayShellProjection.activeTradeOffer }
        set { mutateGameplayShellProjection { $0.activeTradeOffer = newValue } }
    }
    var tradeResponses: String {
        get { gameplayShellProjection.tradeResponses }
        set { mutateGameplayShellProjection { $0.tradeResponses = newValue } }
    }
    var maritimeTradePreview: String {
        get { gameplayShellProjection.maritimeTradePreview }
        set { mutateGameplayShellProjection { $0.maritimeTradePreview = newValue } }
    }
    var largestArmyStatus: String {
        get { gameplayShellProjection.largestArmyStatus }
        set { mutateGameplayShellProjection { $0.largestArmyStatus = newValue } }
    }
    var longestRoadStatus: String {
        get { gameplayShellProjection.longestRoadStatus }
        set { mutateGameplayShellProjection { $0.longestRoadStatus = newValue } }
    }
    var victoryPointsSummary: String {
        get { gameplayShellProjection.victoryPointsSummary }
        set { mutateGameplayShellProjection { $0.victoryPointsSummary = newValue } }
    }
    var gameOverSummary: String {
        get { gameplayShellProjection.gameOverSummary }
        set { mutateGameplayShellProjection { $0.gameOverSummary = newValue } }
    }
    var lastTurnRecapSummary: String {
        get { gameplayShellProjection.lastTurnRecapSummary }
        set { mutateGameplayShellProjection { $0.lastTurnRecapSummary = newValue } }
    }
    var boardHash: String {
        get { gameplayShellProjection.boardHash }
        set { mutateGameplayShellProjection { $0.boardHash = newValue } }
    }
    var boardGenerator: String {
        get { gameplayShellProjection.boardGenerator }
        set { mutateGameplayShellProjection { $0.boardGenerator = newValue } }
    }
    var boardRobberTile: String {
        get { gameplayShellProjection.boardRobberTile }
        set { mutateGameplayShellProjection { $0.boardRobberTile = newValue } }
    }
    var boardResourcesByTile: String {
        get { gameplayShellProjection.boardResourcesByTile }
        set { mutateGameplayShellProjection { $0.boardResourcesByTile = newValue } }
    }
    var boardNumbersByTile: String {
        get { gameplayShellProjection.boardNumbersByTile }
        set { mutateGameplayShellProjection { $0.boardNumbersByTile = newValue } }
    }
    var boardPortsByIndex: String {
        get { gameplayShellProjection.boardPortsByIndex }
        set { mutateGameplayShellProjection { $0.boardPortsByIndex = newValue } }
    }
    var visibleHands: String {
        get { gameplayShellProjection.visibleHands }
        set { mutateGameplayShellProjection { $0.visibleHands = newValue } }
    }
    var bankResources: String {
        get { gameplayShellProjection.bankResources }
        set { mutateGameplayShellProjection { $0.bankResources = newValue } }
    }
    var devDeckRemaining: String {
        get { gameplayShellProjection.devDeckRemaining }
        set { mutateGameplayShellProjection { $0.devDeckRemaining = newValue } }
    }
    var visibleDevCards: String {
        get { gameplayShellProjection.visibleDevCards }
        set { mutateGameplayShellProjection { $0.visibleDevCards = newValue } }
    }
    var setupPlacement: String {
        get { gameplayShellProjection.setupPlacement }
        set { mutateGameplayShellProjection { $0.setupPlacement = newValue } }
    }
    var turnIntent: String {
        get { gameplayShellProjection.turnIntent }
        set { mutateGameplayShellProjection { $0.turnIntent = newValue } }
    }

    private var allowIncomingSummaryPayloadFallback: Bool {
        // Legacy decode support stays enabled until repeated device validation
        // proves the old mirrored payload carrier can be retired safely.
        true
    }

    private var includeOutgoingSummaryPayloadMirror: Bool {
        // Fresh publishes are URL-only again after the `https` scheme fix.
        // Legacy decode support stays enabled separately for older bubbles that
        // were published while the broken custom-scheme transport was live.
        false
    }

    var canInvite: Bool {
        activeConversation != nil
    }

    var rootRoute: MessagesRootRoute {
        MessagesRootRoute.resolve(phase: selectedState?.phase)
    }

    var hasRecoveredGames: Bool {
        !recoveredGames.isEmpty
    }

    var lobbyScreenModel: LobbyScreenModel {
        LobbyScreenModelBuilder.build(
            context: LobbyScreenContext(
                selectedState: selectedState,
                selectedJoinIntent: selectedJoinIntent,
                localActor: localParticipantIdentifier(),
                activeContextSource: activeContextSource,
                contextMeta: activeContextMeta,
                staleWarning: staleContextWarning,
                lastError: lastError,
                canInvite: canInvite,
                canJoin: canJoin,
                canStartGame: canStartGame
            )
        )
    }

    var gameScreenModel: GameScreenModel {
        gameplayShellProjection.gameScreenModel
    }

    var setupGuidanceText: String? {
        gameplayShellProjection.setupGuidanceText
    }

    var discardPanelModel: GameDiscardPanelModel? {
        gameplayShellProjection.discardPanelModel
    }

    var robberVictimOptions: [GameRobberVictimOption] {
        gameplayShellProjection.robberVictimOptions
    }

    var tradePanelModel: GameTradePanelModel? {
        gameplayShellProjection.tradePanelModel
    }

    func makeBoardOverlayModel(
        mode: GameMode,
        devCardDraft: GameDevCardDraft? = nil,
        selectedTarget: GameBoardTarget?
    ) -> GameBoardOverlayModel {
        let key = BoardOverlayModelCacheKey(
            stateHash: selectedState?.stateHash,
            actor: localActorIdentifier(),
            mode: mode,
            draft: devCardDraft,
            selectedTarget: selectedTarget
        )
        if let cachedBoardOverlayModelKey,
           cachedBoardOverlayModelKey == key,
           let cachedBoardOverlayModelValue {
            return cachedBoardOverlayModelValue
        }

        let model = GameBoardOverlayModelBuilder.build(
            state: selectedState,
            actingAs: localActorIdentifier(),
            mode: mode,
            devCardDraft: devCardDraft,
            selectedTarget: selectedTarget
        )
        cachedBoardOverlayModelKey = key
        cachedBoardOverlayModelValue = model
        return model
    }

    func makeDevCardPanelModel(
        mode: GameMode,
        draft: GameDevCardDraft?
    ) -> GameDevCardPanelModel? {
        let key = DevCardPanelModelCacheKey(
            stateHash: selectedState?.stateHash,
            actor: localActorIdentifier(),
            mode: mode,
            draft: draft
        )
        if let cachedDevCardPanelModelKey, cachedDevCardPanelModelKey == key {
            return cachedDevCardPanelModelValue ?? nil
        }

        let model = GameDevCardPanelModelBuilder.build(
            state: selectedState,
            actingAs: localActorIdentifier(),
            mode: mode,
            draft: draft
        )
        cachedDevCardPanelModelKey = key
        cachedDevCardPanelModelValue = .some(model)
        return model
    }

    func makeBankTrayModel(
        mode: GameMode,
        draft: GameDevCardDraft?
    ) -> GameBankTrayModel {
        let key = BankTrayModelCacheKey(
            stateHash: selectedState?.stateHash,
            actor: localActorIdentifier(),
            mode: mode,
            draft: draft
        )
        if let cachedBankTrayModelKey,
           cachedBankTrayModelKey == key,
           let cachedBankTrayModelValue {
            return cachedBankTrayModelValue
        }

        let model = GameBankTrayModelBuilder.build(
            state: selectedState,
            actingAs: localActorIdentifier(),
            mode: mode,
            draft: draft
        )
        cachedBankTrayModelKey = key
        cachedBankTrayModelValue = model
        return model
    }

    func legalKnightVictims(for tileID: TileID) -> [String] {
        guard let state = selectedState, let actor = localActorIdentifier() else {
            return []
        }
        return state.legalKnightVictims(for: tileID, actor: actor)
    }

    func knightVictimPlayer(for nodeID: NodeID, tileID: TileID) -> String? {
        guard let state = selectedState, let actor = localActorIdentifier() else {
            return nil
        }

        let victims = Set(state.legalKnightVictims(for: tileID, actor: actor))
        if let cityOwner = state.citiesByNode[nodeID], victims.contains(cityOwner) {
            return cityOwner
        }
        if let settlementOwner = state.settlementsByNode[nodeID], victims.contains(settlementOwner) {
            return settlementOwner
        }
        return nil
    }

    private var shellActionAvailability: GameActionAvailability {
        GameActionAvailability(
            canRoll: canPublishRollState,
            canBuild: canPublishRoadBuildState || canPublishSettlementBuildState || canPublishCityBuildState,
            canTrade: canOpenTradePanel,
            canBuyDevCard: canPublishDevCardPurchaseState,
            canPlayDevCards: canPublishKnightState
                || canPublishMonopolyState
                || canPublishYearOfPlentyState
                || canPublishRoadBuildingState
                || canPublishVictoryPointRevealState,
            canEndTurn: canPublishEndTurnState
        )
    }

    private var shellModeAvailability: GameModeAvailability {
        guard let state = selectedState else {
            return .none
        }

        let isCurrentActor = localActorIdentifier() == state.currentPlayer

        return GameModeAvailability(
            canSetup: state.phase == .setup && isCurrentActor,
            canBuildRoad: canPublishRoadBuildState,
            canBuildSettlement: canPublishSettlementBuildState,
            canBuildCity: canPublishCityBuildState,
            canRobberMove: canPublishRobberMoveState,
            canRobberVictim: state.phase == .turn
                && state.turnState?.step == .needsRobberSteal
                && isCurrentActor
                && !stealVictimOptions.isEmpty,
            canTrade: canOpenTradePanel,
            canPlayDevCard: shellActionAvailability.canPlayDevCards,
            canDiscard: state.phase == .turn && state.turnState?.step == .pendingDiscards
        )
    }

    private var canOpenTradePanel: Bool {
        guard
            let state = selectedState,
            state.phase == .turn,
            state.turnState?.step == .afterRoll
        else {
            return false
        }

        if state.activeTradeOffer != nil {
            return true
        }

        return localActorIdentifier() == state.currentPlayer
    }

    var actingAsOptions: [String] {
        guard diagnosticsEnabled else {
            return []
        }
        return selectedState?.roster ?? []
    }

    var shouldShowDebugHUD: Bool {
        diagnosticsEnabled
    }

    var shouldShowTemporaryDiagnosticsOverlay: Bool {
        diagnosticsEnabled
    }

    var hostGestureSummaryLines: [String] {
        let lines = hostGestureHierarchySnapshot.summaryLines
        return lines.isEmpty ? ["-"] : lines
    }

    var hostGestureEventSummaryLines: [String] {
        if hostGestureEvents.isEmpty {
            return ["-"]
        }
        return hostGestureEvents.map(\.summaryLine)
    }

    var boardDiagnosticsSummaryLines: [String] {
        boardDiagnosticsSnapshot.summaryLines
    }

    var hasActiveContext: Bool {
        selectedState != nil
    }

    var activeContextBanner: String {
        guard let state = selectedState else {
            return "Active Context: none"
        }
        let step = state.turnState?.step.rawValue ?? "-"
        return "Active Context: rev=\(state.rev) phase=\(state.phase.rawValue) step=\(step) current=\(shortIdentifier(state.currentPlayer))"
    }

    var activeContextMeta: String {
        guard selectedState != nil else {
            return "Source: -"
        }
        let source = activeContextSource == "-" ? "unknown" : activeContextSource
        guard diagnosticsEnabled else {
            return "Source: \(source)"
        }
        let age = activeContextUpdatedAgo == "-" ? "0s ago" : activeContextUpdatedAgo
        return "Source: \(source), updated \(age)"
    }

    var canJoin: Bool {
        LobbyMembershipResolver.canJoin(
            state: selectedState,
            localParticipant: localParticipantIdentifier()
        )
    }

    var canRecordJoin: Bool {
        diagnosticsEnabled && selectedJoinIntent != nil
    }

    var canReloadSelectedBubble: Bool {
        activeConversation?.selectedMessage != nil
    }

    var canClearActiveContext: Bool {
        selectedState != nil
    }

    var isTurnSelectedState: Bool {
        selectedState?.phase == .turn
    }

    private var canPublishRollState: Bool {
        guard
            let state = selectedState,
            state.phase == .turn,
            let actor = localActorIdentifier(),
            actor == state.currentPlayer
        else {
            return false
        }
        return state.turnState?.step == .needsRoll
    }

    private var canPublishRobberMoveState: Bool {
        guard
            let state = selectedState,
            state.phase == .turn,
            let actor = localActorIdentifier(),
            actor == state.currentPlayer
        else {
            return false
        }
        return state.turnState?.step == .needsRobberMove && state.board != nil
    }

    var stealVictimOptions: [String] {
        guard
            let state = selectedState,
            state.phase == .turn,
            state.turnState?.step == .needsRobberSteal
        else {
            return []
        }
        return state.turnState?.eligibleStealVictims.sorted() ?? []
    }

    private var canPublishRoadBuildState: Bool {
        guard
            let state = selectedState,
            state.phase == .turn,
            state.turnState?.step == .afterRoll,
            let actor = localActorIdentifier(),
            actor == state.currentPlayer
        else {
            return false
        }
        return firstLegalRoadEdge(for: actor, in: state) != nil
    }

    private var canPublishSettlementBuildState: Bool {
        guard
            let state = selectedState,
            state.phase == .turn,
            state.turnState?.step == .afterRoll,
            let actor = localActorIdentifier(),
            actor == state.currentPlayer
        else {
            return false
        }
        return firstLegalSettlementNode(for: actor, in: state) != nil
    }

    private var canPublishCityBuildState: Bool {
        guard
            let state = selectedState,
            state.phase == .turn,
            state.turnState?.step == .afterRoll,
            let actor = localActorIdentifier(),
            actor == state.currentPlayer
        else {
            return false
        }
        return firstUpgradeableCityNode(for: actor, in: state) != nil
    }

    var canSendProposeTradeIntentDebug: Bool {
        guard
            let state = selectedState,
            state.phase == .turn,
            state.turnState?.step == .afterRoll,
            state.activeTradeOffer == nil,
            let actor = localActorIdentifier(),
            actor == state.currentPlayer
        else {
            return false
        }
        return defaultTradeProposal(for: actor, from: state) != nil
    }

    var canSendAcceptTradeIntentDebug: Bool {
        guard
            let state = selectedState,
            state.phase == .turn,
            state.turnState?.step == .afterRoll,
            let offer = state.activeTradeOffer,
            let actor = localActorIdentifier(),
            actor != state.currentPlayer,
            offer.recipients.contains(actor),
            !state.tradeResponses.contains(where: { $0.respondingPlayer == actor && $0.offerHash == offer.offerHash })
        else {
            return false
        }
        let hand = state.resourcesByPlayer[actor] ?? .zero
        return hand.wood >= offer.receive.wood
            && hand.brick >= offer.receive.brick
            && hand.sheep >= offer.receive.sheep
            && hand.wheat >= offer.receive.wheat
            && hand.ore >= offer.receive.ore
    }

    var canSendExecuteTradeIntentDebug: Bool {
        guard
            let state = selectedState,
            state.phase == .turn,
            state.turnState?.step == .afterRoll,
            let offer = state.activeTradeOffer,
            let actor = localActorIdentifier()
        else {
            return false
        }
        return actor == state.currentPlayer
            && state.tradeResponses.contains {
                $0.offerHash == offer.offerHash && $0.kind == .accept
            }
    }

    private var canPublishDevCardPurchaseState: Bool {
        guard
            let state = selectedState,
            state.phase == .turn,
            state.turnState?.step == .afterRoll,
            let actor = localActorIdentifier(),
            actor == state.currentPlayer,
            !state.devDeck.isEmpty
        else {
            return false
        }
        let hand = state.resourcesByPlayer[actor] ?? .zero
        return hand.sheep >= 1 && hand.wheat >= 1 && hand.ore >= 1
    }

    private var canPublishKnightState: Bool {
        guard
            let state = selectedState,
            state.phase == .turn,
            state.turnState?.step.allowsDevCardPlay == true,
            let actor = localActorIdentifier(),
            actor == state.currentPlayer
        else {
            return false
        }
        return !state.legalKnightMoveTilesForDevCard(for: actor).isEmpty
    }

    private var canPublishMonopolyState: Bool {
        guard canPublishNamedDevCardState({ $0.monopoly > 0 }),
              let state = selectedState,
              let actor = localActorIdentifier()
        else {
            return false
        }
        return !state.monopolyPreviews(for: actor).isEmpty
    }

    private var canPublishYearOfPlentyState: Bool {
        guard canPublishNamedDevCardState({ $0.yearOfPlenty > 0 }),
              let state = selectedState,
              let actor = localActorIdentifier()
        else {
            return false
        }
        return state.yearOfPlentyBankOptions(for: actor).reduce(0) { $0 + $1.remainingCount } >= 2
    }

    private var canPublishRoadBuildingState: Bool {
        guard canPublishNamedDevCardState({ $0.roadBuilding > 0 }),
              let state = selectedState,
              let actor = localActorIdentifier()
        else {
            return false
        }
        return !state.legalRoadBuildingFirstEdges(for: actor).isEmpty
    }

    private var canPublishVictoryPointRevealState: Bool {
        guard
            let state = selectedState,
            state.phase == .turn,
            state.turnState?.step.allowsDevCardPlay == true,
            let actor = localActorIdentifier(),
            actor == state.currentPlayer
        else {
            return false
        }
        return state.canRevealVictoryPoint(for: actor)
    }

    private var canPublishEndTurnState: Bool {
        guard
            let state = selectedState,
            state.phase == .turn,
            let actor = localActorIdentifier(),
            actor == state.currentPlayer
        else {
            return false
        }
        return state.turnState?.step == .afterRoll
    }

    var canStartGame: Bool {
        LobbyMembershipResolver.canStart(
            state: selectedState,
            localParticipant: localParticipantIdentifier()
        )
    }

    var canClearObservedJoiners: Bool {
        diagnosticsEnabled && currentGameId() != nil
    }

    var shouldMaintainSelectionWatch: Bool {
        activeConversation?.selectedMessage != nil || currentGameId() != nil
    }

    var canApplySelectedTurnIntentAsState: Bool {
        guard
            let state = selectedState,
            let intent = selectedTurnIntent,
            let actor = localActorIdentifier(),
            actor == state.currentPlayer
        else {
            return false
        }
        return intent.gameId == state.gameId &&
            intent.anchorRev == state.rev &&
            intent.anchorHash == state.stateHash
    }

    var hasBoardDebug: Bool {
        selectedState?.board != nil
    }

    func disabledReason(requiresCurrentPlayer: Bool, isEnabled: Bool) -> String {
        if isEnabled {
            return ""
        }
        guard let state = selectedState else {
            return "No Active Context — tap a STATE bubble."
        }
        guard let actor = localActorIdentifier() else {
            return "This device has not joined the selected game."
        }
        if requiresCurrentPlayer, actor != state.currentPlayer {
            return "Only current player can do this."
        }
        if state.phase == .gameOver {
            return "Game is over."
        }
        return "Not legal in current phase/step."
    }

    func setBoardStrategy(_ strategy: BoardGenStrategyV1) {
        boardStrategy = strategy
        userDefaults.set(strategy.rawValue, forKey: boardStrategyKey)
    }

    func setActingAs(_ actor: String) {
        guard allowsRuntimeDebugControls else {
            return
        }
        actingAs = actor
        refreshParticipantIdentityDebug()
    }

    func setUseSingleSessionDebug(_ enabled: Bool) {
        guard allowsRuntimeDebugControls else {
            return
        }
        useSingleSessionDebug = enabled
    }

    @discardableResult
    func updateContext(
        conversation: MSConversation?,
        selectedMessage: MSMessage?,
        trigger: TranscriptSelectionTrigger
    ) -> Bool {
        activeConversation = conversation
        if trigger == .didReceive {
            recordDidReceiveInvocation(
                message: selectedMessage,
                selectedMessage: conversation?.selectedMessage
            )
        }
        if
            trigger == .selectionPoll,
            let selectedMessage,
            let signature = selectionSignature(for: selectedMessage),
            signature == lastResolvedSelectionSignature
        {
            return false
        }
        refreshActiveContextMetadata()
        refreshParticipantIdentityDebug()
        return decodeSelectedMessage(
            selectedMessage,
            trigger: trigger
        )
    }

    @discardableResult
    func reloadSelectedBubble() -> Bool {
        decodeSelectedMessage(
            activeConversation?.selectedMessage,
            trigger: .reload
        )
    }

    func clearActiveContext() {
        selectedState = nil
        activeSource = nil
        activeUpdatedAt = nil
        activeContextSource = "-"
        activeContextUpdatedAgo = "-"
        staleContextWarning = "-"
        clearLatestUpdateNotice()
        gameLedgerStore.markActiveGame(nil)
        refreshRecoveredGames()
        if selectedTurnIntent == nil, selectedSetupIntent == nil, selectedJoinIntent == nil {
            resetDisplayedFields()
        }
        selectionStatus = "Active context cleared"
        selectedDecodeResult = selectionStatus
        refreshParticipantIdentityDebug()
        appendLog("Cleared Active Context")
    }

    func inviteNewGame() {
        guard let actor = localParticipantIdentifier() else {
            setLastError("Missing local participant identifier.")
            return
        }

        let state = CoreGameStateV1(
            gameId: UUID().uuidString,
            rev: 0,
            prevHash: nil,
            stateHash: "",
            roster: [actor],
            currentPlayer: actor,
            phase: .lobby,
            seed: nil,
            diceRngState: nil,
            resourcesByPlayer: [actor: .zero],
            boardRules: nil,
            board: nil
        ).rehashed()

        do {
            let payload = try jsonString(from: state)
            let envelope = EnvelopeV1(kind: .state, body: .state(payload: payload))
            try sendEnvelope(
                envelope,
                caption: "ULS STATE rev0",
                sessionPolicy: .state(gameId: state.gameId),
                postPublishEffect: .dismissExtension
            )
            setActiveContext(state, source: .lastSentState)
            selectionStatus = "Invite sent: lobby rev0"
            setLastError(nil)
        } catch {
            setLastError("Invite failed: \(error.localizedDescription)")
        }
    }

    func publishLobbyJoinState() {
        guard let state = selectedState else {
            setLastError("Select a lobby STATE first.")
            return
        }

        guard state.phase == .lobby else {
            setLastError("Join is only available from lobby STATE messages.")
            return
        }

        guard let actor = localParticipantIdentifier() else {
            setLastError("Missing local participant identifier.")
            return
        }

        guard let joinedState = LobbyMembershipResolver.joinedLobbyState(
            state: state,
            localParticipant: actor
        ) else {
            setLastError("Join is only available from lobby STATE messages.")
            return
        }

        do {
            let payload = try jsonString(from: joinedState)
            let envelope = EnvelopeV1(kind: .state, body: .state(payload: payload))
            try sendEnvelope(
                envelope,
                caption: "ULS STATE rev\(joinedState.rev)",
                sessionPolicy: .state(gameId: joinedState.gameId)
            )
            setActiveContext(joinedState, source: .lastSentState)
            refreshObservedJoinersDebug(for: joinedState.gameId)
            selectionStatus = "Joined lobby rev\(joinedState.rev)"
            appendLog(
                "Published lobby join actor=\(shortIdentifier(actor)) rev=\(joinedState.rev) anchorRev=\(state.rev)"
            )
            setLastError(nil)
        } catch {
            setLastError("Join failed: \(error.localizedDescription)")
        }
    }

    func recordJoin() {
        guard diagnosticsEnabled else {
            setLastError("Debug join tools are disabled on this branch.")
            return
        }
        guard let intent = selectedJoinIntent else {
            setLastError("Select a JOIN intent first.")
            return
        }

        rememberObservedJoiner(intent.actor, for: intent.gameId)
        refreshObservedJoinersDebug(for: intent.gameId)
        selectionStatus = "Recorded join actor: \(intent.actor)"
        setLastError(nil)
    }

    func startGame() {
        guard let fromState = selectedState else {
            setLastError("Select the latest lobby STATE first.")
            return
        }

        guard fromState.phase == .lobby else {
            setLastError("Start is only available from lobby STATE.")
            return
        }

        guard let inviter = fromState.roster.first else {
            setLastError("Selected state has no inviter.")
            return
        }

        guard inviter == localParticipantIdentifier() else {
            setLastError("Only the inviter can start the game.")
            return
        }

        let finalRoster = fromState.roster

        guard finalRoster.count >= 2 else {
            setLastError("At least two players must be in the lobby before starting.")
            return
        }

        let masterSeed = UInt64.random(in: .min ... .max)
        let seedDeriver = SeedDeriver(masterSeed: masterSeed)
        let diceSeed = seedDeriver.seed(for: .dice)
        let robberSeed = seedDeriver.seed(for: .robber)
        let boardSeed = seedDeriver.seed(for: .board)
        let devDeck = makeDeterministicDevDeck(masterSeed: masterSeed)
        let rules = BoardRulesV1(strategy: boardStrategy)
        let board = StandardBoardGeneratorV1.generate(boardSeed: boardSeed, rules: rules)
        let setupState = initializeSetupState(roster: finalRoster)
        guard let setupPlayer = setupState.order.first else {
            setLastError("Could not initialize setup state.")
            return
        }

        let toState = CoreGameStateV1(
            gameId: fromState.gameId,
            rev: fromState.rev + 1,
            prevHash: fromState.stateHash,
            stateHash: "",
            roster: finalRoster,
            currentPlayer: setupPlayer,
            phase: .setup,
            seed: masterSeed,
            diceRngState: diceSeed,
            robberRngState: robberSeed,
            resourcesByPlayer: Dictionary(
                uniqueKeysWithValues: finalRoster.map { ($0, ResourceHandV1.zero) }
            ),
            devDeck: devDeck,
            boardRules: rules,
            board: board,
            setupState: setupState
        ).rehashed()

        do {
            try validateTransition(from: fromState, to: toState, actor: inviter)
            let payload = try jsonString(from: toState)
            let envelope = EnvelopeV1(kind: .state, body: .state(payload: payload))
            try sendEnvelope(
                envelope,
                caption: "ULS STATE rev\(toState.rev)",
                sessionPolicy: .state(gameId: toState.gameId)
            )
            gameLedgerStore.clearObservedJoiners(for: toState.gameId)
            refreshRecoveredGames()
            refreshObservedJoinersDebug(for: toState.gameId)
            setActiveContext(toState, source: .lastSentState)
            selectionStatus = "Start sent: setup rev\(toState.rev)"
            setLastError(nil)
        } catch {
            setLastError("Start failed: \(error.localizedDescription)")
        }
    }

    func clearObservedJoiners() {
        guard diagnosticsEnabled else {
            setLastError("Debug join tools are disabled on this branch.")
            return
        }
        guard let gameId = currentGameId() else {
            setLastError("Select a message with a gameId first.")
            return
        }

        gameLedgerStore.clearObservedJoiners(for: gameId)
        refreshRecoveredGames()
        refreshObservedJoinersDebug(for: gameId)
        selectionStatus = "Cleared observed joiners for \(gameId)"
        setLastError(nil)
    }

    func sendProposeTradeIntentDebug() {
        guard let state = selectedState else {
            setLastError("Select a turn STATE first.")
            return
        }
        guard state.phase == .turn, state.turnState?.step == .afterRoll else {
            setLastError("Propose trade intent is only available in post-roll step.")
            return
        }
        guard state.activeTradeOffer == nil else {
            setLastError("An active trade offer already exists.")
            return
        }
        guard let actor = localActorIdentifier(), actor == state.currentPlayer else {
            setLastError("Only current player can propose a trade.")
            return
        }
        guard let proposal = defaultTradeProposal(for: actor, from: state) else {
            setLastError("No valid default trade proposal available.")
            return
        }
        let recipients = state.roster
            .filter { $0 != actor }
            .sorted()
        guard !recipients.isEmpty else {
            setLastError("No eligible trade recipients are available.")
            return
        }

        let intent = ULS_Transport.TurnIntentV1(
            proposeTradeGive: proposal.give,
            receive: proposal.receive,
            targetPlayers: recipients,
            gameId: state.gameId,
            anchorRev: state.rev,
            anchorHash: state.stateHash,
            actor: actor
        )

        do {
            let payload = try jsonString(from: intent)
            let envelope = EnvelopeV1(kind: .intent, body: .intent(payload: payload))
            try sendEnvelope(envelope, caption: "ULS LEGACY INTENT proposeTrade", sessionPolicy: .new)
            selectionStatus = "Propose trade legacy intent sent"
            setLastError(nil)
        } catch {
            setLastError("Propose trade intent failed: \(error.localizedDescription)")
        }
    }

    func sendAcceptTradeIntentDebug() {
        guard let state = selectedState else {
            setLastError("Select a turn STATE first.")
            return
        }
        guard state.phase == .turn, state.turnState?.step == .afterRoll else {
            setLastError("Accept trade intent is only available in post-roll step.")
            return
        }
        guard let offer = state.activeTradeOffer else {
            setLastError("No active trade offer to accept.")
            return
        }
        guard let actor = localActorIdentifier(), actor != state.currentPlayer else {
            setLastError("Only non-current players can send accept trade intent.")
            return
        }
        guard offer.recipients.contains(actor) else {
            setLastError("Only targeted recipients can accept a trade.")
            return
        }
        guard !state.tradeResponses.contains(where: { $0.respondingPlayer == actor && $0.offerHash == offer.offerHash }) else {
            setLastError("You already responded to this trade.")
            return
        }

        let intent = ULS_Transport.TurnIntentV1(
            acceptTradePlayer: actor,
            offerHash: offer.offerHash,
            gameId: state.gameId,
            anchorRev: state.rev,
            anchorHash: state.stateHash,
            actor: actor
        )

        do {
            let payload = try jsonString(from: intent)
            let envelope = EnvelopeV1(kind: .intent, body: .intent(payload: payload))
            try sendEnvelope(envelope, caption: "ULS TRADE RESPONSE accept", sessionPolicy: .new)
            selectionStatus = "Accept trade response sent"
            setLastError(nil)
        } catch {
            setLastError("Accept trade intent failed: \(error.localizedDescription)")
        }
    }

    func sendExecuteTradeIntentDebug() {
        guard let state = selectedState else {
            setLastError("Select a turn STATE first.")
            return
        }
        guard state.phase == .turn, state.turnState?.step == .afterRoll else {
            setLastError("Execute trade intent is only available in post-roll step.")
            return
        }
        guard let offer = state.activeTradeOffer else {
            setLastError("No active trade offer to execute.")
            return
        }
        guard let actor = localActorIdentifier(), actor == state.currentPlayer else {
            setLastError("Only current player can execute a trade accept.")
            return
        }
        guard let acceptPlayer = state.tradeResponses
            .filter({ $0.offerHash == offer.offerHash && $0.kind == .accept })
            .sorted(by: { $0.respondingPlayer < $1.respondingPlayer })
            .first?.respondingPlayer
        else {
            setLastError("No pending trade accepts to execute.")
            return
        }

        let intent = ULS_Transport.TurnIntentV1(
            executeTradePlayer: acceptPlayer,
            offerHash: offer.offerHash,
            gameId: state.gameId,
            anchorRev: state.rev,
            anchorHash: state.stateHash,
            actor: actor
        )

        do {
            let payload = try jsonString(from: intent)
            let envelope = EnvelopeV1(kind: .intent, body: .intent(payload: payload))
            try sendEnvelope(envelope, caption: "ULS LEGACY INTENT executeTrade", sessionPolicy: .new)
            selectionStatus = "Execute trade legacy intent sent"
            setLastError(nil)
        } catch {
            setLastError("Execute trade intent failed: \(error.localizedDescription)")
        }
    }


    @discardableResult
    func publishSetupState(for target: GameBoardTarget) -> Bool {
        let resolution = actionAuthoringStateResolution()
        guard let fromState = resolution.state else {
            setLastError("No Active Context — tap a STATE bubble.")
            return false
        }
        activateAuthoringStateIfNeeded(resolution)

        guard let actor = localActorIdentifier(for: fromState), actor == fromState.currentPlayer else {
            setLastError("Only current player can publish canonical STATE.")
            return false
        }

        guard let setupIntent = SetupInteractionResolver.draftIntent(
            state: fromState,
            actingAs: actor,
            target: target
        ) else {
            setLastError("Selected setup target is not legal.")
            return false
        }

        do {
            try applyAndPublishSetupIntent(
                setupIntent,
                from: fromState,
                actor: actor,
                successStatus: "Published setup placement"
            )
            return true
        } catch {
            setLastError("Setup placement failed: \(error.localizedDescription)")
            return false
        }
    }

    @discardableResult
    func publishTurnState(for actionKind: GameActionDockItem.Kind) -> Bool {
        guard let intent = immediateTurnIntent(for: actionKind) else {
            return false
        }

        do {
            try applyAndPublishTurnIntent(intent, successStatus: successStatus(for: intent.kind))
            return true
        } catch {
            setLastError("Turn action failed: \(error.localizedDescription)")
            return false
        }
    }

    @discardableResult
    func publishTurnState(for target: GameBoardTarget, mode: GameMode) -> Bool {
        let resolution = actionAuthoringStateResolution()
        let authoringState = resolution.state
        let intent: ULS_Transport.TurnIntentV1?
        let failureMessage: String

        switch mode {
        case .buildRoad, .buildSettlement, .buildCity:
            intent = TurnInteractionResolver.draftBuildIntent(
                state: authoringState,
                actingAs: localActorIdentifier(for: authoringState),
                mode: mode,
                target: target
            )
            failureMessage = "Selected build target is not legal."
        case .robberMove:
            intent = TurnInteractionResolver.draftRobberMoveIntent(
                state: authoringState,
                actingAs: localActorIdentifier(for: authoringState),
                target: target
            )
            failureMessage = "Selected robber tile is not legal."
        case .robberVictim:
            intent = TurnInteractionResolver.draftStealVictimIntent(
                state: authoringState,
                actingAs: localActorIdentifier(for: authoringState),
                target: target
            )
            failureMessage = "Selected robber victim is not legal."
        default:
            intent = nil
            failureMessage = "Selected turn target is not legal."
        }

        guard let intent else {
            setLastError(failureMessage)
            return false
        }
        activateAuthoringStateIfNeeded(resolution)

        do {
            try applyAndPublishTurnIntent(intent, successStatus: successStatus(for: intent.kind))
            return true
        } catch {
            setLastError("Turn action failed: \(error.localizedDescription)")
            return false
        }
    }

    @discardableResult
    func handleDiscardFlowAction(discarded: ResourceHandV1) -> Bool {
        let resolution = actionAuthoringStateResolution()
        guard let state = resolution.state else {
            setLastError("No Active Context — tap a STATE bubble.")
            return false
        }
        activateAuthoringStateIfNeeded(resolution)

        guard let actor = localActorIdentifier(for: state) else {
            setLastError("Missing local participant identifier.")
            return false
        }

        guard let intent = TurnInteractionResolver.draftDiscardIntent(
            state: state,
            actingAs: actor,
            discarded: discarded
        ) else {
            setLastError("No valid discard action is currently available.")
            return false
        }

        do {
            try applyAndPublishTurnIntent(intent, successStatus: successStatus(for: intent.kind))
            return true
        } catch {
            setLastError("Discard publication failed: \(error.localizedDescription)")
            return false
        }
    }

    @discardableResult
    func publishTradeOffer(
        give: ResourceHandV1,
        receive: ResourceHandV1,
        targetPlayers: [String]
    ) -> Bool {
        let resolution = actionAuthoringStateResolution()
        guard let intent = TradeInteractionResolver.draftTradeOfferIntent(
            state: resolution.state,
            actingAs: localActorIdentifier(for: resolution.state),
            give: give,
            receive: receive,
            targetPlayers: targetPlayers
        ) else {
            setLastError("Selected trade offer is not legal.")
            return false
        }
        activateAuthoringStateIfNeeded(resolution)

        do {
            try applyAndPublishTurnIntent(intent, successStatus: "Published trade offer")
            return true
        } catch {
            setLastError("Trade offer failed: \(error.localizedDescription)")
            return false
        }
    }

    @discardableResult
    func publishMaritimeTrade(give: ResourceHandV1, receive: ResourceHandV1) -> Bool {
        let resolution = actionAuthoringStateResolution()
        guard let intent = TradeInteractionResolver.draftMaritimeTradeIntent(
            state: resolution.state,
            actingAs: localActorIdentifier(for: resolution.state),
            give: give,
            receive: receive
        ) else {
            setLastError("Selected maritime trade is not legal.")
            return false
        }
        activateAuthoringStateIfNeeded(resolution)

        do {
            try applyAndPublishTurnIntent(intent, successStatus: "Published maritime trade")
            return true
        } catch {
            setLastError("Maritime trade failed: \(error.localizedDescription)")
            return false
        }
    }

    @discardableResult
    func sendAcceptTradeResponse() -> Bool {
        let resolution = actionAuthoringStateResolution()
        guard let intent = TradeInteractionResolver.draftAcceptTradeIntent(
            state: resolution.state,
            actingAs: localActorIdentifier(for: resolution.state)
        ) else {
            setLastError("No legal trade accept is available.")
            return false
        }
        activateAuthoringStateIfNeeded(resolution)

        do {
            try publishTradeResponse(intent)
            return true
        } catch {
            setLastError("Accept trade failed: \(error.localizedDescription)")
            return false
        }
    }

    @discardableResult
    func sendDeclineTradeResponse() -> Bool {
        let resolution = actionAuthoringStateResolution()
        guard let intent = TradeInteractionResolver.draftDeclineTradeIntent(
            state: resolution.state,
            actingAs: localActorIdentifier(for: resolution.state)
        ) else {
            setLastError("No legal trade decline is available.")
            return false
        }
        activateAuthoringStateIfNeeded(resolution)

        do {
            try publishTradeResponse(intent)
            return true
        } catch {
            setLastError("Decline trade failed: \(error.localizedDescription)")
            return false
        }
    }

    @discardableResult
    func sendCounterTradeResponse(give: ResourceHandV1, receive: ResourceHandV1) -> Bool {
        let resolution = actionAuthoringStateResolution()
        guard let intent = TradeInteractionResolver.draftCounterTradeIntent(
            state: resolution.state,
            actingAs: localActorIdentifier(for: resolution.state),
            give: give,
            receive: receive
        ) else {
            setLastError("No legal counter trade is available.")
            return false
        }
        activateAuthoringStateIfNeeded(resolution)

        do {
            try publishTradeResponse(intent)
            return true
        } catch {
            setLastError("Counter trade failed: \(error.localizedDescription)")
            return false
        }
    }

    @discardableResult
    func handleDevCardAction(_ action: GameDevCardActionKind) -> Bool {
        switch action {
        case .buyDevCard:
            let resolution = actionAuthoringStateResolution()
            guard let intent = DevCardInteractionResolver.draftBuyDevCardIntent(
                state: resolution.state,
                actingAs: localActorIdentifier(for: resolution.state)
            ) else {
                setLastError("Selected dev-card action is not legal.")
                return false
            }
            activateAuthoringStateIfNeeded(resolution)
            do {
                try applyAndPublishTurnIntent(intent, successStatus: "Published dev-card purchase")
                return true
            } catch {
                setLastError("Dev-card action failed: \(error.localizedDescription)")
                return false
            }
        case .revealVictoryPoint:
            let resolution = actionAuthoringStateResolution()
            guard let intent = DevCardInteractionResolver.draftRevealVictoryPointIntent(
                state: resolution.state,
                actingAs: localActorIdentifier(for: resolution.state)
            ) else {
                setLastError("Selected dev-card action is not legal.")
                return false
            }
            activateAuthoringStateIfNeeded(resolution)
            do {
                try applyAndPublishTurnIntent(intent, successStatus: "Published victory-point reveal")
                return true
            } catch {
                setLastError("Dev-card action failed: \(error.localizedDescription)")
                return false
            }
        case .playKnight, .playMonopoly, .playYearOfPlenty, .playRoadBuilding:
            setLastError("Selected dev-card action needs additional choices first.")
            return false
        }
    }

    @discardableResult
    func publishDevCardDraft(_ draft: GameDevCardDraft) -> Bool {
        let resolution = actionAuthoringStateResolution()
        let authoringState = resolution.state
        let authoringActor = localActorIdentifier(for: authoringState)
        let intent: ULS_Transport.TurnIntentV1?
        let successStatus: String

        switch draft {
        case let .knight(tileID, victimPlayer):
            guard let tileID else {
                setLastError("Knight play needs a robber tile.")
                return false
            }
            intent = DevCardInteractionResolver.draftPlayKnightIntent(
                state: authoringState,
                actingAs: authoringActor,
                tileID: tileID,
                victimPlayer: victimPlayer
            )
            successStatus = "Published knight play"
        case let .monopoly(resource):
            guard let resource else {
                setLastError("Monopoly needs a selected resource.")
                return false
            }
            intent = DevCardInteractionResolver.draftPlayMonopolyIntent(
                state: authoringState,
                actingAs: authoringActor,
                resource: resource
            )
            successStatus = "Published monopoly play"
        case let .yearOfPlenty(first, second):
            guard let first, let second else {
                setLastError("Year Of Plenty needs two resources.")
                return false
            }
            intent = DevCardInteractionResolver.draftPlayYearOfPlentyIntent(
                state: authoringState,
                actingAs: authoringActor,
                firstResource: first,
                secondResource: second
            )
            successStatus = "Published year-of-plenty play"
        case let .roadBuilding(firstEdgeID, secondEdgeID):
            guard let firstEdgeID, let secondEdgeID else {
                setLastError("Road Building needs two roads.")
                return false
            }
            intent = DevCardInteractionResolver.draftPlayRoadBuildingIntent(
                state: authoringState,
                actingAs: authoringActor,
                firstEdgeID: firstEdgeID,
                secondEdgeID: secondEdgeID
            )
            successStatus = "Published road-building play"
        }

        guard let intent else {
            setLastError("Selected dev-card action is not legal.")
            return false
        }
        activateAuthoringStateIfNeeded(resolution)

        do {
            try applyAndPublishTurnIntent(intent, successStatus: successStatus)
            return true
        } catch {
            setLastError("Dev-card action failed: \(error.localizedDescription)")
            return false
        }
    }

    @discardableResult
    func publishRobberVictimState(victimPlayer: String) -> Bool {
        let resolution = actionAuthoringStateResolution()
        guard let intent = TurnInteractionResolver.draftStealVictimIntent(
            state: resolution.state,
            actingAs: localActorIdentifier(for: resolution.state),
            victimPlayer: victimPlayer
        ) else {
            setLastError("Selected robber victim is not legal.")
            return false
        }
        activateAuthoringStateIfNeeded(resolution)

        do {
            try applyAndPublishTurnIntent(intent, successStatus: successStatus(for: intent.kind))
            return true
        } catch {
            setLastError("Steal selection failed: \(error.localizedDescription)")
            return false
        }
    }

    private func applyAndPublishSetupIntent(
        _ setupIntent: SetupPlacementIntentV1,
        from fromState: CoreGameStateV1,
        actor: String,
        successStatus: String
    ) throws {
        let coreIntent = try setupIntentForTransport(setupIntent)
        let toState = try ULS_CoreGame.apply(intent: coreIntent, to: fromState, actor: actor)
        try validateTransition(from: fromState, to: toState, actor: actor)

        let payload = try jsonString(from: toState)
        let envelope = EnvelopeV1(kind: .state, body: .state(payload: payload))
        try sendEnvelope(
            envelope,
            caption: "ULS STATE rev\(toState.rev)",
            sessionPolicy: .state(gameId: toState.gameId)
        )
        selectedSetupIntent = nil
        setActiveContext(toState, source: .lastSentState)
        selectionStatus = "\(successStatus) rev\(toState.rev)"
        setLastError(nil)
    }

    func applySelectedTurnIntentAsState() {
        guard let fromState = selectedState else {
            setLastError("No Active Context — tap a STATE bubble.")
            return
        }
        guard let turnIntent = selectedTurnIntent else {
            setLastError("Select a turn intent bubble first.")
            return
        }
        guard turnIntent.gameId == fromState.gameId,
              turnIntent.anchorRev == fromState.rev,
              turnIntent.anchorHash == fromState.stateHash else {
            setLastError("Selected turn intent anchor does not match Active Context.")
            return
        }
        guard let actor = localActorIdentifier(), actor == fromState.currentPlayer else {
            setLastError("Only current player can publish canonical STATE.")
            return
        }

        do {
            try applyAndPublishTurnIntent(turnIntent, successStatus: "Applied turn intent into STATE")
        } catch {
            setLastError("Apply turn intent failed: \(error.localizedDescription)")
        }
    }

    @discardableResult
    func publishSelectedTurnIntentState() -> Bool {
        guard let turnIntent = selectedTurnIntent else {
            setLastError("Select a turn intent bubble first.")
            return false
        }

        guard let fromState = selectedState else {
            setLastError("No Active Context — tap a STATE bubble.")
            return false
        }

        guard
            turnIntent.gameId == fromState.gameId,
            turnIntent.anchorRev == fromState.rev,
            turnIntent.anchorHash == fromState.stateHash
        else {
            setLastError("Selected turn intent anchor does not match Active Context.")
            return false
        }

        do {
            try applyAndPublishTurnIntent(turnIntent, successStatus: successStatus(for: turnIntent.kind))
            return true
        } catch {
            setLastError("Apply turn intent failed: \(error.localizedDescription)")
            return false
        }
    }

    private func decodeSelectedMessage(
        _ message: MSMessage?,
        trigger: TranscriptSelectionTrigger
    ) -> Bool {
        updateSelectedTransportSnapshot(message, trigger: trigger)

        if
            trigger == .selectionPoll,
            let message,
            let signature = selectionSignature(for: message),
            signature == lastResolvedSelectionSignature
        {
            return false
        }

        guard let message else {
            if selectedState == nil, restoreLocalLedgerStateIfAvailable(trigger: trigger) {
                if trigger == .didReceive {
                    recordDidReceiveOutcome(
                        incomingGameId: nil,
                        disposition: .applyToActiveContext,
                        outcome: "restored cached state after empty callback"
                    )
                }
                return false
            }
            selectionStatus = "No message selected"
            selectedDecodeResult = selectionStatus
            if selectedState == nil {
                if diagnosticsEnabled {
                    resetDisplayedFields()
                    refreshObservedJoinersDebug(for: nil)
                }
            }
            appendLog("Selection \(trigger.label): no message selected")
            if trigger == .didReceive {
                recordDidReceiveOutcome(
                    incomingGameId: nil,
                    disposition: .applyToActiveContext,
                    outcome: "no message payload surfaced"
                )
            }
            return true
        }

        guard let encodedEnvelope = payloadValue(from: message) else {
            if selectedState == nil, restoreLocalLedgerStateIfAvailable(trigger: trigger) {
                if trigger == .didReceive {
                    recordDidReceiveOutcome(
                        incomingGameId: nil,
                        disposition: .applyToActiveContext,
                        outcome: "restored cached state after missing transport"
                    )
                }
                return false
            }
            selectionStatus = "Selected message has no transport payload"
            selectedDecodeResult = selectionStatus
            if selectedState == nil {
                if diagnosticsEnabled {
                    resetDisplayedFields()
                    refreshObservedJoinersDebug(for: nil)
                }
            }
            appendLog(
                "Selection \(trigger.label): no transport payload url=\(selectedURLPresence) payload=\(selectedPayloadQueryPresence)"
            )
            if trigger == .didReceive {
                recordDidReceiveOutcome(
                    incomingGameId: nil,
                    disposition: .applyToActiveContext,
                    outcome: "missing transport payload"
                )
            }
            return true
        }

        do {
            let envelope = try decode(encodedEnvelope.payload)
            try apply(
                envelope: envelope,
                message: message,
                source: encodedEnvelope.source,
                trigger: trigger
            )
            lastResolvedSelectionSignature = selectionSignature(for: message)
            selectedDecodeSource = encodedEnvelope.source.label
            selectedDecodeResult = selectionStatus
            appendLog("Selection \(trigger.label): decoded \(envelope.kind.rawValue) via \(encodedEnvelope.source.label)")
            setLastError(nil)
            return false
        } catch {
            selectionStatus = "Failed to decode selected message"
            selectedDecodeSource = encodedEnvelope.source.label
            selectedDecodeResult = selectionStatus
            if selectedState == nil {
                if diagnosticsEnabled {
                    resetDisplayedFields()
                    refreshObservedJoinersDebug(for: nil)
                }
            }
            setLastError("Decode failed: \(error.localizedDescription)")
            appendLog("Selection \(trigger.label): decode failed via \(encodedEnvelope.source.label)")
            if trigger == .didReceive {
                recordDidReceiveOutcome(
                    incomingGameId: nil,
                    disposition: .applyToActiveContext,
                    outcome: "decode failed via \(encodedEnvelope.source.label)"
                )
            }
            return false
        }
    }

    private func apply(
        envelope: EnvelopeV1,
        message: MSMessage,
        source: TranscriptPayloadSource,
        trigger: TranscriptSelectionTrigger
    ) throws {
        switch envelope.body {
        case let .state(payload):
            let state = try decodePayload(CoreGameStateV1.self, from: payload)
            let didReceiveDisposition = didReceiveDisposition(
                for: state.gameId,
                trigger: trigger
            )
            latestKnownStatesByGameId = TranscriptStateSelection.recording(
                state,
                in: latestKnownStatesByGameId
            )
            gameLedgerStore.record(state: state, payload: payload)
            refreshRecoveredGames()
            stateSessionsByGameId[state.gameId] = message.session
            selectedJoinIntent = nil
            selectedSetupIntent = nil
            selectedTurnIntent = nil
            let transcriptActiveSource: TranscriptActiveContextSource?
            switch activeSource {
            case .selectedBubble:
                transcriptActiveSource = .selectedBubble
            case .receivedMessage:
                transcriptActiveSource = .receivedMessage
            case .latestKnownState:
                transcriptActiveSource = .latestKnownState
            case .lastSentState:
                transcriptActiveSource = .lastSentState
            case .localLedgerState:
                transcriptActiveSource = .localLedgerState
            case nil:
                transcriptActiveSource = nil
            }

            let stateSelection = TranscriptStateSelection.resolve(
                decodedState: state,
                latestKnownStatesByGameId: latestKnownStatesByGameId,
                activeState: selectedState,
                activeSource: transcriptActiveSource,
                source: source,
                trigger: trigger
            )

            if
                didReceiveDisposition == .applyToActiveContext,
                stateSelection.shouldActivate
            {
                let activationSource: ActiveContextSource = switch trigger {
                case .didReceive:
                    .receivedMessage
                case .didSelect, .selectionPoll, .viewDidLoad, .reload:
                    .selectedBubble
                }
                setActiveContext(stateSelection.preferredState, source: activationSource)
            }

            if didReceiveDisposition == .storeForRecoveryOnly {
                selectionStatus = "Stored received STATE rev\(stateSelection.preferredState.rev) for another game"
            } else {
                selectionStatus = stateSelection.selectionStatus
            }

            if
                didReceiveDisposition == .applyToActiveContext,
                stateSelection.redirectedToLatestKnown
            {
                if stateSelection.shouldShowLatestUpdateNotice {
                    showLatestUpdateNotice("Opened latest game update.")
                }
                appendLog(
                    "Selection \(trigger.label): redirected stale rev=\(state.rev) -> latest rev=\(stateSelection.preferredState.rev)"
                )
            } else if
                didReceiveDisposition == .applyToActiveContext,
                stateSelection.shouldShowLatestUpdateNotice
            {
                showLatestUpdateNotice("Opened latest game update.")
            }
            appendLog("Decoded STATE rev=\(state.rev)")
            if trigger == .didReceive {
                let outcome: String
                switch didReceiveDisposition {
                case .applyToActiveContext:
                    outcome = stateSelection.shouldActivate
                        ? "activated state rev\(stateSelection.preferredState.rev)"
                        : "decoded state rev\(stateSelection.preferredState.rev) without activation"
                case .storeForRecoveryOnly:
                    outcome = "stored state rev\(stateSelection.preferredState.rev) for other game"
                }
                recordDidReceiveOutcome(
                    incomingGameId: state.gameId,
                    disposition: didReceiveDisposition,
                    outcome: outcome
                )
            }
            refreshStaleContextWarning()
        case let .intent(payload):
            if let setupIntent = try? decodePayload(SetupPlacementIntentV1.self, from: payload) {
                selectedSetupIntent = setupIntent
                selectedJoinIntent = nil
                selectedTurnIntent = nil
                render(setupIntent: setupIntent, source: source)
                return
            }

            if let turnIntent = try? decodePayload(ULS_Transport.TurnIntentV1.self, from: payload) {
                let didReceiveDisposition = didReceiveDisposition(
                    for: turnIntent.gameId,
                    trigger: trigger
                )
                if didReceiveDisposition == .storeForRecoveryOnly {
                    selectionStatus = "Stored received \(turnIntent.kind.rawValue) for another game"
                    selectedDecodeResult = selectionStatus
                    if trigger == .didReceive {
                        recordDidReceiveOutcome(
                            incomingGameId: turnIntent.gameId,
                            disposition: didReceiveDisposition,
                            outcome: "stored \(turnIntent.kind.rawValue) for other game"
                        )
                    }
                    return
                }

                let contextResolution = TurnIntentContextResolver.resolve(
                    turnIntent: turnIntent,
                    selectedState: selectedState,
                    latestKnownStatesByGameId: latestKnownStatesByGameId,
                    localLedgerState: localLedgerStateForIntentContext(gameId: turnIntent.gameId)
                )
                recoverActiveContextIfNeeded(for: turnIntent, resolution: contextResolution)

                if autoApplyTurnIntentIfPossible(
                    turnIntent,
                    resolution: contextResolution,
                    source: source,
                    trigger: trigger
                ) {
                    if trigger == .didReceive {
                        recordDidReceiveOutcome(
                            incomingGameId: turnIntent.gameId,
                            disposition: didReceiveDisposition,
                            outcome: "auto-applied \(turnIntent.kind.rawValue)"
                        )
                    }
                    return
                }

                if shouldPreferRecoveredState(
                    for: turnIntent,
                    resolution: contextResolution
                ) {
                    selectedTurnIntent = nil
                    selectedSetupIntent = nil
                    selectedJoinIntent = nil
                    let recoveredRev = contextResolution.bestAvailable?.state.rev ?? turnIntent.anchorRev
                    selectionStatus = "Opened latest STATE rev\(recoveredRev) via \(source.label)"
                    selectedDecodeResult = selectionStatus
                    appendLog(
                        "Ignored stale \(turnIntent.kind.rawValue) response anchorRev=\(turnIntent.anchorRev) latestRev=\(recoveredRev)"
                    )
                    refreshObservedJoinersDebug(for: turnIntent.gameId)
                    if trigger == .didReceive {
                        recordDidReceiveOutcome(
                            incomingGameId: turnIntent.gameId,
                            disposition: didReceiveDisposition,
                            outcome: "preferred recovered state for \(turnIntent.kind.rawValue)"
                        )
                    }
                    return
                }

                selectedTurnIntent = turnIntent
                selectedSetupIntent = nil
                selectedJoinIntent = nil
                render(turnIntent: turnIntent, source: source)
                if trigger == .didReceive {
                    recordDidReceiveOutcome(
                        incomingGameId: turnIntent.gameId,
                        disposition: didReceiveDisposition,
                        outcome: "rendered \(turnIntent.kind.rawValue) responder transport"
                    )
                }
                return
            }

            let intent = try decodePayload(JoinIntentV1.self, from: payload)
            let didReceiveDisposition = didReceiveDisposition(
                for: intent.gameId,
                trigger: trigger
            )
            if didReceiveDisposition == .storeForRecoveryOnly {
                rememberObservedJoiner(intent.actor, for: intent.gameId)
                selectionStatus = "Stored received legacy join for another game"
                selectedDecodeResult = selectionStatus
                if trigger == .didReceive {
                    recordDidReceiveOutcome(
                        incomingGameId: intent.gameId,
                        disposition: didReceiveDisposition,
                        outcome: "stored legacy join actor=\(shortIdentifier(intent.actor))"
                    )
                }
                return
            }
            if bridgeJoinIntentIfPossible(
                intent,
                source: source,
                trigger: trigger
            ) {
                if trigger == .didReceive {
                    recordDidReceiveOutcome(
                        incomingGameId: intent.gameId,
                        disposition: didReceiveDisposition,
                        outcome: "bridged legacy join actor=\(shortIdentifier(intent.actor))"
                    )
                }
                return
            }
            selectedJoinIntent = intent
            selectedSetupIntent = nil
            selectedTurnIntent = nil
            render(joinIntent: intent, source: source)
            if trigger == .didReceive {
                recordDidReceiveOutcome(
                    incomingGameId: intent.gameId,
                    disposition: didReceiveDisposition,
                    outcome: "rendered legacy join bubble"
                )
            }
        }
    }

    private func setActiveContext(_ state: CoreGameStateV1, source: ActiveContextSource) {
        latestKnownStatesByGameId = TranscriptStateSelection.recording(
            state,
            in: latestKnownStatesByGameId
        )
        selectedState = state
        activeSource = source
        activeUpdatedAt = Date()
        gameLedgerStore.markActiveGame(state.gameId)
        refreshRecoveredGames()
        syncActingAs(with: state)
        refreshActiveContextMetadata()
        refreshStaleContextWarning()

        let payloadSource: TranscriptPayloadSource
        switch source {
        case .selectedBubble:
            payloadSource = .url
        case .receivedMessage:
            payloadSource = .url
        case .latestKnownState:
            payloadSource = .url
        case .lastSentState:
            payloadSource = .local
        case .localLedgerState:
            payloadSource = .localCache
        }
        render(state: state, source: payloadSource)
        appendLog("Set Active Context rev=\(state.rev) source=\(source.label)")
    }

    private func syncActingAs(with state: CoreGameStateV1) {
        if state.roster.contains(actingAs) {
            return
        }
        if let local = localParticipantIdentifier(), state.roster.contains(local) {
            actingAs = local
        } else {
            actingAs = "-"
        }
    }

    private func refreshActiveContextMetadata() {
        activeContextSource = activeSource?.label ?? "-"
        if diagnosticsEnabled, let updatedAt = activeUpdatedAt {
            let seconds = max(0, Int(Date().timeIntervalSince(updatedAt)))
            activeContextUpdatedAgo = "\(seconds)s ago"
        } else {
            activeContextUpdatedAgo = "-"
        }
        refreshParticipantIdentityDebug()
    }

    private func refreshStaleContextWarning() {
        guard
            let active = selectedState,
            let latest = TranscriptStateSelection.latestKnownState(
                for: active.gameId,
                in: latestKnownStatesByGameId
            ),
            latest.rev > active.rev
        else {
            staleContextWarning = "-"
            return
        }
        staleContextWarning = "A newer update is available for this game."
    }

    private func updateSelectedTransportSnapshot(
        _ message: MSMessage?,
        trigger: TranscriptSelectionTrigger
    ) {
        guard diagnosticsEnabled else {
            return
        }
        let snapshot = TranscriptTransportSupport.selectionSnapshot(
            for: message,
            summaryPayloadPrefix: summaryPayloadPrefix,
            allowSummaryFallback: allowIncomingSummaryPayloadFallback
        )
        selectedTrigger = trigger.label
        selectedMessagePresence = snapshot.messagePresence
        selectedURLPresence = snapshot.urlPresence
        selectedURLString = snapshot.urlString
        selectedPayloadQueryPresence = snapshot.payloadQueryPresence
        selectedPayloadLength = snapshot.payloadLength
        selectedSummaryText = snapshot.summaryText
        selectedLayoutCaption = snapshot.layoutCaption
        selectedSessionPresence = snapshot.sessionPresence
        selectedDecodeSource = snapshot.decodeSource
        transportBadgeModel = TransportBadgeModel.build(
            triggerLabel: trigger.label,
            snapshot: snapshot
        )
    }

    private func recordDidReceiveInvocation(
        message: MSMessage?,
        selectedMessage: MSMessage?
    ) {
        didReceiveInvocationCount += 1
        didReceiveCount = String(didReceiveInvocationCount)

        let incomingMessagePresence = message == nil ? "missing" : "present"
        let incomingSessionPresence = message?.session == nil ? "missing" : "present"
        let selectedMessagePresence = selectedMessage == nil ? "missing" : "present"
        let selectedSessionPresence = selectedMessage?.session == nil ? "missing" : "present"

        let incomingSessionId = message?.session.map(Self.sessionIdentity) ?? "-"
        let selectedSessionId = selectedMessage?.session.map(Self.sessionIdentity) ?? "-"
        let currentGame = currentGameId()
        let cachedSessionId = currentGame
            .flatMap { stateSessionsByGameId[$0] }
            .map(Self.sessionIdentity) ?? "-"
        let incomingMatchesCached: String
        if
            let message,
            let incomingSession = message.session,
            let currentGame,
            let cached = stateSessionsByGameId[currentGame]
        {
            incomingMatchesCached = incomingSession === cached ? "yes" : "no"
        } else {
            incomingMatchesCached = "n/a"
        }

        lastDidReceiveTransport =
            "incomingMsg=\(incomingMessagePresence) incomingSession=\(incomingSessionPresence) "
            + "selectedMsg=\(selectedMessagePresence) selectedSession=\(selectedSessionPresence) "
            + "incomingSessionId=\(incomingSessionId) selectedSessionId=\(selectedSessionId) "
            + "cachedSessionId=\(cachedSessionId) incomingMatchesCached=\(incomingMatchesCached)"
        lastDidReceiveGameId = currentGame ?? "-"
        lastDidReceiveDisposition = "pending"
        lastDidReceiveOutcome = "callback received"
        appendDidReceiveHistory(
            "#\(didReceiveInvocationCount) callback "
                + "incomingMsg=\(incomingMessagePresence) incomingSession=\(incomingSessionPresence) "
                + "selectedMsg=\(selectedMessagePresence) selectedSession=\(selectedSessionPresence) "
                + "incomingSessionId=\(incomingSessionId) selectedSessionId=\(selectedSessionId) "
                + "cachedSessionId=\(cachedSessionId) incomingMatchesCached=\(incomingMatchesCached)"
        )

        appendLog(
            "didReceive callback currentGame=\(shortIdentifier(currentGame ?? "-")) "
                + "incomingSession=\(incomingSessionPresence) selectedSession=\(selectedSessionPresence) "
                + "incomingSessionId=\(incomingSessionId) selectedSessionId=\(selectedSessionId) "
                + "cachedSessionId=\(cachedSessionId) incomingMatchesCached=\(incomingMatchesCached)"
        )
    }

    private func recordDidReceiveOutcome(
        incomingGameId: String?,
        disposition: TranscriptDidReceiveDisposition,
        outcome: String
    ) {
        guard didReceiveInvocationCount > 0 else {
            return
        }

        lastDidReceiveGameId = incomingGameId ?? "-"
        lastDidReceiveDisposition = disposition.label
        lastDidReceiveOutcome = outcome
        appendDidReceiveHistory(
            "#\(didReceiveInvocationCount) \(disposition.label) "
                + "game=\(shortIdentifier(incomingGameId ?? "-")) \(outcome)"
        )
        appendLog(
            "didReceive outcome game=\(shortIdentifier(incomingGameId ?? "-")) "
                + "disposition=\(disposition.label) \(outcome)"
        )
    }

    private func appendDidReceiveHistory(_ entry: String) {
        didReceiveHistory.append(entry)
        if didReceiveHistory.count > 8 {
            didReceiveHistory.removeFirst(didReceiveHistory.count - 8)
        }
    }

    private func didReceiveDisposition(
        for incomingGameId: String?,
        trigger: TranscriptSelectionTrigger
    ) -> TranscriptDidReceiveDisposition {
        TranscriptDidReceiveContract.disposition(
            trigger: trigger,
            incomingGameId: incomingGameId,
            currentGameId: currentGameId()
        )
    }

    private func refreshParticipantIdentityDebug() {
        guard diagnosticsEnabled else {
            return
        }
        let localParticipant = localParticipantIdentifier()
        let observedJoiners = currentObservedJoiners()

        localParticipantDebug = localParticipant ?? "-"
        resolvedActorDebug = debugActorIdentifier() ?? "-"
        canJoinDebug = canJoin ? "true" : "false"

        guard let state = selectedState, let localParticipant else {
            localInRosterDebug = "-"
            localObservedJoinDebug = "-"
            isInviterDebug = "-"
            return
        }

        localInRosterDebug = state.roster.contains(localParticipant) ? "true" : "false"
        localObservedJoinDebug = observedJoiners.contains(localParticipant) ? "true" : "false"
        isInviterDebug = state.roster.first == localParticipant ? "true" : "false"
    }

    private func appendLog(_ message: String) {
        guard diagnosticsEnabled else {
            return
        }
        uiLog.append(message)
        if uiLog.count > 40 {
            uiLog.removeFirst(uiLog.count - 40)
        }
    }

    func recordHostGestureHierarchySnapshot(_ snapshot: HostGestureHierarchySnapshot) {
        guard diagnosticsEnabled else {
            return
        }
        guard hostGestureHierarchySnapshot != snapshot else {
            return
        }
        hostGestureHierarchySnapshot = snapshot
    }

    func recordHostGestureEvent(_ event: HostGestureEvent) {
        guard diagnosticsEnabled else {
            return
        }
        hostGestureEvents.append(event)
        if hostGestureEvents.count > 24 {
            hostGestureEvents.removeFirst(hostGestureEvents.count - 24)
        }
        appendLog("Gesture \(event.summaryLine)")
    }

    func recordBoardDiagnosticsSnapshot(_ snapshot: BoardInteractionDiagnosticsSnapshot) {
        guard diagnosticsEnabled else {
            return
        }
        boardDiagnosticsSnapshot = snapshot
    }

    func requestBoardReload(detail: String = "manual") {
        boardReloadToken &+= 1
        recordHostGestureEvent(
            HostGestureEvent(kind: .boardSurfaceReloaded, detail: "\(detail) token=\(boardReloadToken)")
        )
    }

    func resumeRecoveredGame(_ gameId: String) {
        guard let recoveredState = gameLedgerStore.latestState(for: gameId) else {
            setLastError("No locally recovered state for \(gameId).")
            return
        }

        selectedJoinIntent = nil
        selectedSetupIntent = nil
        selectedTurnIntent = nil
        setActiveContext(recoveredState, source: .localLedgerState)
        selectionStatus = "Recovered latest STATE rev\(recoveredState.rev)"
        selectedDecodeSource = TranscriptPayloadSource.localCache.label
        selectedDecodeResult = selectionStatus
        appendLog("Recovered game \(shortIdentifier(gameId)) rev=\(recoveredState.rev) from local ledger")
        setLastError(nil)
    }

    private func restoreLocalLedgerStateIfAvailable(
        trigger: TranscriptSelectionTrigger
    ) -> Bool {
        guard allowsLocalLedgerStateRecovery else {
            return false
        }
        guard let ledgerState = localLedgerState() else {
            return false
        }

        setActiveContext(ledgerState, source: .localLedgerState)
        selectionStatus = "Restored local ledger STATE rev\(ledgerState.rev)"
        selectedDecodeSource = TranscriptPayloadSource.localCache.label
        selectedDecodeResult = selectionStatus
        appendLog("Selection \(trigger.label): restored local ledger state rev=\(ledgerState.rev)")
        setLastError(nil)
        return true
    }

    private func cacheLocalLedgerStateRecord(_ data: Data) {
        guard allowsLocalLedgerStateRecovery else {
            return
        }
        guard
            let cached = try? JSONDecoder().decode(LocalLedgerStateRecord.self, from: data),
            let gameId = cached.gameId,
            let state = try? decodePayload(CoreGameStateV1.self, from: cached.payload),
            state.gameId == gameId
        else {
            return
        }
        gameLedgerStore.record(state: state, payload: cached.payload)
        refreshRecoveredGames()
    }

    private func localLedgerState() -> CoreGameStateV1? {
        guard allowsLocalLedgerStateRecovery else {
            return nil
        }
        if let lastActiveGameId = currentGameId() ?? gameLedgerStore.lastActiveGameId() {
            return gameLedgerStore.latestState(for: lastActiveGameId)
        }
        return gameLedgerStore.mostRecentState()
    }

    private func localLedgerStateForIntentContext(gameId: String) -> CoreGameStateV1? {
        if let latestState = gameLedgerStore.latestState(for: gameId) {
            return latestState
        }

        guard let fallback = localLedgerState(), fallback.gameId == gameId else {
            return nil
        }

        return fallback
    }

    private func actionAuthoringStateResolution(
        for gameId: String? = nil
    ) -> ActionAuthoringStateResolution {
        let resolvedGameId = gameId ?? selectedState?.gameId
        return ActionAuthoringStateResolver.resolve(
            gameId: resolvedGameId,
            selectedState: selectedState,
            latestKnownStatesByGameId: latestKnownStatesByGameId,
            localLedgerState: resolvedGameId.flatMap(localLedgerStateForIntentContext(gameId:))
        )
    }

    private func activateAuthoringStateIfNeeded(_ resolution: ActionAuthoringStateResolution) {
        guard
            resolution.prefersRecoveredState,
            let state = resolution.state,
            let source = resolution.source,
            shouldRecoverActiveContext(to: state)
        else {
            return
        }

        setActiveContext(state, source: resolvedActiveContextSource(for: source))
    }

    private func showLatestUpdateNotice(_ message: String) {
        guard showsLatestUpdateNotices else {
            return
        }
        latestUpdateNoticeToken += 1
        let token = latestUpdateNoticeToken
        latestUpdateNotice = message

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            guard let self, self.latestUpdateNoticeToken == token else {
                return
            }

            self.latestUpdateNotice = "-"
        }
    }

    private func clearLatestUpdateNotice() {
        guard showsLatestUpdateNotices else {
            latestUpdateNotice = "-"
            return
        }
        latestUpdateNoticeToken += 1
        latestUpdateNotice = "-"
    }

    private func updateGameplayShellProjection(_ projection: GameShellProjection) {
        guard gameplayShellProjection != projection else {
            return
        }
        gameplayShellProjection = projection
    }

    private func shortIdentifier(_ value: String) -> String {
        String(value.prefix(8))
    }

    private func render(state: CoreGameStateV1, source: TranscriptPayloadSource) {
        selectionStatus = "Decoded STATE rev\(state.rev) via \(source.label)"
        selectedDecodeResult = selectionStatus
        updateGameplayShellProjection(
            GameShellProjectionBuilder.build(
                state: state,
                actingAs: localActorIdentifier(),
                actionAvailability: shellActionAvailability,
                modeAvailability: shellModeAvailability
            )
        )
        refreshObservedJoinersDebug(for: state.gameId)
    }

    private func render(joinIntent: JoinIntentV1, source: TranscriptPayloadSource) {
        rememberObservedJoiner(joinIntent.actor, for: joinIntent.gameId)
        selectionStatus = "Decoded legacy join bubble via \(source.label)"
        selectedDecodeResult = selectionStatus
        updateGameplayShellProjection(GameShellProjectionBuilder.build(joinIntent: joinIntent))
        refreshObservedJoinersDebug(for: joinIntent.gameId)
        appendLog("Decoded LEGACY_JOIN actor=\(shortIdentifier(joinIntent.actor))")
    }

    private func render(setupIntent: SetupPlacementIntentV1, source: TranscriptPayloadSource) {
        selectionStatus = "Decoded legacy setup bubble via \(source.label)"
        selectedDecodeResult = selectionStatus
        updateGameplayShellProjection(GameShellProjectionBuilder.build(setupIntent: setupIntent))
        refreshObservedJoinersDebug(for: setupIntent.gameId)
        appendLog("Decoded LEGACY_SETUP kind=\(setupIntent.kind.rawValue) actor=\(shortIdentifier(setupIntent.actor))")
    }

    private func render(turnIntent decodedTurnIntent: ULS_Transport.TurnIntentV1, source: TranscriptPayloadSource) {
        switch TurnIntentTransportRoleResolver.resolve(decodedTurnIntent) {
        case .responderMessage(.discardResponse):
            selectionStatus = "Decoded discard response via \(source.label)"
        case .responderMessage(.tradeResponse):
            selectionStatus = "Decoded trade response via \(source.label)"
        case .legacyIntent:
            selectionStatus = "Decoded legacy \(decodedTurnIntent.kind.rawValue) intent via \(source.label)"
        }
        selectedDecodeResult = selectionStatus
        if let selectedState, selectedState.gameId == decodedTurnIntent.gameId {
            updateGameplayShellProjection(
                GameShellProjectionBuilder.build(
                    state: selectedState,
                    actingAs: localActorIdentifier(),
                    actionAvailability: shellActionAvailability,
                    modeAvailability: shellModeAvailability,
                    contextBanner: activeContextBanner,
                    contextMeta: activeContextMeta
                )
            )
        } else {
            updateGameplayShellProjection(GameShellProjectionBuilder.build(turnIntent: decodedTurnIntent))
        }
        refreshObservedJoinersDebug(for: decodedTurnIntent.gameId)
        switch TurnIntentTransportRoleResolver.resolve(decodedTurnIntent) {
        case .responderMessage(.discardResponse):
            appendLog("Decoded DISCARD_RESPONSE actor=\(shortIdentifier(decodedTurnIntent.actor))")
        case .responderMessage(.tradeResponse):
            appendLog("Decoded TRADE_RESPONSE actor=\(shortIdentifier(decodedTurnIntent.actor)) kind=\(decodedTurnIntent.kind.rawValue)")
        case .legacyIntent:
            appendLog("Decoded LEGACY_INTENT kind=\(decodedTurnIntent.kind.rawValue) actor=\(shortIdentifier(decodedTurnIntent.actor))")
        }
    }

    private func bridgeJoinIntentIfPossible(
        _ joinIntent: JoinIntentV1,
        source: TranscriptPayloadSource,
        trigger: TranscriptSelectionTrigger
    ) -> Bool {
        let decision = JoinIntentContextResolver.resolve(
            joinIntent: joinIntent,
            selectedState: selectedState,
            latestKnownStatesByGameId: latestKnownStatesByGameId,
            localLedgerState: localLedgerStateForIntentContext(gameId: joinIntent.gameId),
            localParticipant: localParticipantIdentifier()
        )

        guard let recovered = decision.recoveredContext else {
            return false
        }

        if shouldRecoverActiveContext(to: recovered.state) {
            setActiveContext(recovered.state, source: resolvedActiveContextSource(for: recovered.source))
        }

        selectedJoinIntent = nil
        selectedSetupIntent = nil
        selectedTurnIntent = nil

        if decision.shouldRecordJoiner {
            rememberObservedJoiner(joinIntent.actor, for: joinIntent.gameId)
            setActiveContext(recovered.state, source: resolvedActiveContextSource(for: recovered.source))
            refreshObservedJoinersDebug(for: joinIntent.gameId)
            selectionStatus = "Updated lobby from join via \(source.label)"
            appendLog(
                "Selection \(trigger.label): bridged join actor=\(shortIdentifier(joinIntent.actor)) rev=\(recovered.state.rev) via \(source.label)"
            )
        } else {
            refreshObservedJoinersDebug(for: recovered.state.gameId)
            selectionStatus = "Opened latest STATE rev\(recovered.state.rev) via \(source.label)"
            appendLog(
                "Selection \(trigger.label): recovered state for join actor=\(shortIdentifier(joinIntent.actor)) rev=\(recovered.state.rev) via \(source.label)"
            )
        }

        selectedDecodeResult = selectionStatus
        setLastError(nil)
        return true
    }

    private func recoverActiveContextIfNeeded(
        for turnIntent: ULS_Transport.TurnIntentV1,
        resolution: TurnIntentContextResolution
    ) {
        guard let recovered = resolution.bestAvailable else {
            return
        }
        guard shouldRecoverActiveContext(to: recovered.state) else {
            return
        }

        setActiveContext(recovered.state, source: resolvedActiveContextSource(for: recovered.source))
        appendLog(
            "Recovered context for \(turnIntent.kind.rawValue) rev=\(recovered.state.rev) source=\(recovered.source)"
        )
    }

    private func autoApplyTurnIntentIfPossible(
        _ turnIntent: ULS_Transport.TurnIntentV1,
        resolution: TurnIntentContextResolution,
        source: TranscriptPayloadSource,
        trigger: TranscriptSelectionTrigger
    ) -> Bool {
        guard
            let applyContext = TurnIntentContextResolver.autoApplyContext(
                turnIntent,
                resolution: resolution,
                localParticipant: localParticipantIdentifier()
            )
        else {
            return false
        }

        if shouldRecoverActiveContext(to: applyContext.state) {
            setActiveContext(applyContext.state, source: resolvedActiveContextSource(for: applyContext.source))
        }

        do {
            let rebasedIntent = try discardIntentReanchoredIfNeeded(turnIntent, to: applyContext.state)
            try applyAndPublishTurnIntent(rebasedIntent, successStatus: successStatus(for: turnIntent.kind))
            let reanchored = rebasedIntent.anchorRev != turnIntent.anchorRev
                || rebasedIntent.anchorHash != turnIntent.anchorHash
            appendLog(
                reanchored
                    ? "Selection \(trigger.label): auto-applied \(turnIntent.kind.rawValue) via \(source.label) reanchored r\(turnIntent.anchorRev)->r\(rebasedIntent.anchorRev)"
                    : "Selection \(trigger.label): auto-applied \(turnIntent.kind.rawValue) via \(source.label)"
            )
            return true
        } catch {
            appendLog(
                "Auto-apply failed kind=\(turnIntent.kind.rawValue) error=\(error.localizedDescription)"
            )
            setLastError("Automatic intent apply failed: \(error.localizedDescription)")
            return false
        }
    }

    private func shouldPreferRecoveredState(
        for turnIntent: ULS_Transport.TurnIntentV1,
        resolution: TurnIntentContextResolution
    ) -> Bool {
        TurnIntentContextResolver.shouldPreferRecoveredState(
            turnIntent,
            resolution: resolution,
            localParticipant: localParticipantIdentifier()
        )
    }

    private func resetDisplayedFields() {
        updateGameplayShellProjection(.empty)
    }

    private func visibleHandsSummary(for state: CoreGameStateV1) -> String {
        state.visibleResourceHands(for: localActorIdentifier())
            .map { playerView in
                if let revealedHand = playerView.revealedHand {
                    return "\(playerView.player): \(resourceHandDescription(revealedHand))"
                }
                return "\(playerView.player): \(playerView.totalCount)"
            }
            .joined(separator: " | ")
    }

    private func visibleDevCardsSummary(for state: CoreGameStateV1) -> String {
        state.visibleDevCards(for: localActorIdentifier())
            .map { playerView in
                if let playable = playerView.revealedPlayable,
                   let newCards = playerView.revealedNew
                {
                    return "\(playerView.player): \(devCardInventoryDescription(playable))/new:\(devCardInventoryDescription(newCards))"
                }
                return "\(playerView.player): \(playerView.totalCount)"
            }
            .joined(separator: " | ")
    }

    private func resourceHandDescription(_ hand: ResourceHandV1) -> String {
        "w:\(hand.wood), b:\(hand.brick), s:\(hand.sheep), wh:\(hand.wheat), o:\(hand.ore)"
    }

    private func resourceHandDescription(_ hand: TransportResourceHandV1) -> String {
        "w:\(hand.wood), b:\(hand.brick), s:\(hand.sheep), wh:\(hand.wheat), o:\(hand.ore)"
    }

    private func devCardInventoryDescription(_ inventory: DevCardInventoryV1) -> String {
        "k:\(inventory.knight), m:\(inventory.monopoly), yop:\(inventory.yearOfPlenty), rb:\(inventory.roadBuilding), vp:\(inventory.victoryPoint)"
    }

    private func discardRequirementsSummary(for turnState: TurnStateV1?) -> String {
        guard let turnState else {
            return "-"
        }
        if turnState.discardRequirementsByPlayer.isEmpty {
            return "none"
        }
        return turnState.discardRequirementsByPlayer.keys.sorted().map { player in
            "\(player):\(turnState.discardRequirementsByPlayer[player] ?? 0)"
        }.joined(separator: ", ")
    }

    private func discardSubmissionSummary(for turnState: TurnStateV1?) -> String {
        guard let turnState else {
            return "-"
        }
        let requiredCount = turnState.discardRequirementsByPlayer.count
        let submittedCount = turnState.submittedDiscardsByPlayer.count
        if requiredCount == 0 {
            return "0/0"
        }
        let submittedPlayers = turnState.submittedDiscardsByPlayer.keys.sorted().joined(separator: ",")
        return "\(submittedCount)/\(requiredCount) [\(submittedPlayers)]"
    }

    private func robberReadinessSummary(for turnState: TurnStateV1?) -> String {
        guard let turnState else {
            return "-"
        }
        switch turnState.step {
        case .needsRobberMove:
            return "ready"
        case .pendingDiscards:
            return "waiting"
        default:
            return "n/a"
        }
    }

    private func stealVictimsSummary(for turnState: TurnStateV1?) -> String {
        guard let turnState else {
            return "-"
        }
        if turnState.eligibleStealVictims.isEmpty {
            return "none"
        }
        return turnState.eligibleStealVictims.sorted().joined(separator: ", ")
    }

    private func remainingPiecesSummary(for state: CoreGameStateV1) -> String {
        state.roster.map { player in
            let roadsUsed = state.roadsByEdge.values.filter { $0 == player }.count
            let settlementsUsed = state.settlementsByNode.values.filter { $0 == player }.count
            let citiesUsed = state.citiesByNode.values.filter { $0 == player }.count
            return "\(player):R\(max(0, 15 - roadsUsed))/S\(max(0, 5 - settlementsUsed))/C\(max(0, 4 - citiesUsed))"
        }.joined(separator: " | ")
    }

    private func activeTradeOfferSummary(for state: CoreGameStateV1) -> String {
        guard let offer = state.activeTradeOffer else {
            return "none"
        }
        let shortHash = String(offer.offerHash.prefix(8))
        return "\(offer.proposer) \(resourceHandDescription(offer.give)) -> \(resourceHandDescription(offer.receive)) [\(shortHash)]"
    }

    private func tradeResponsesSummary(for state: CoreGameStateV1) -> String {
        if state.tradeResponses.isEmpty {
            return "none"
        }
        return state.tradeResponses
            .sorted { lhs, rhs in
                if lhs.respondingPlayer == rhs.respondingPlayer {
                    return lhs.kind.rawValue < rhs.kind.rawValue
                }
                return lhs.respondingPlayer < rhs.respondingPlayer
            }
            .map { "\($0.respondingPlayer):\($0.kind.rawValue)" }
            .joined(separator: ", ")
    }

    private func maritimeTradeSummary(for state: CoreGameStateV1) -> String {
        guard
            state.phase == .turn,
            state.turnState?.step == .afterRoll,
            let actor = localActorIdentifier(),
            actor == state.currentPlayer,
            let maritime = defaultMaritimeTrade(for: actor, from: state)
        else {
            return "none"
        }
        return "give: \(resourceHandDescription(maritime.give)) receive: \(resourceHandDescription(maritime.receive)) ratio: \(maritime.ratio):1"
    }

    private func largestArmySummary(for state: CoreGameStateV1) -> String {
        let owner = state.largestArmyOwner ?? "none"
        return "\(owner) (\(state.largestArmySize))"
    }

    private func longestRoadSummary(for state: CoreGameStateV1) -> String {
        let owner = state.longestRoadOwner ?? "none"
        return "\(owner) (\(state.longestRoadLength))"
    }

    private func vpSummary(for state: CoreGameStateV1) -> String {
        state.roster
            .map { "\($0):\(victoryPoints(for: $0, in: state))" }
            .joined(separator: " | ")
    }

    private func gameOverStateSummary(for state: CoreGameStateV1) -> String {
        guard state.phase == .gameOver else {
            return "no"
        }
        let winner = state.winnerPlayer ?? "none"
        return "winner: \(winner) vp: \(state.winningVictoryPoints)"
    }

    private func recapSummary(for state: CoreGameStateV1) -> String {
        guard let recap = state.lastTurnRecap else {
            return "none"
        }
        let actions = recap.actions.map(\.rawValue).joined(separator: "->")
        let roll = recap.rollTotal.map(String.init) ?? "n/a"
        return "actor: \(recap.actor) rev: \(recap.startRev)-\(recap.endRev) roll: \(roll) actions: \(actions)"
    }

    private func canPublishNamedDevCardState(
        _ hasCard: (DevCardInventoryV1) -> Bool
    ) -> Bool {
        guard
            let state = selectedState,
            state.phase == .turn,
            state.turnState?.step.allowsDevCardPlay == true,
            let actor = localActorIdentifier(),
            actor == state.currentPlayer,
            !state.devCardActionPlayedThisTurn
        else {
            return false
        }
        return hasCard(state.devCardsByPlayer[actor] ?? .zero)
    }

    private func defaultKnightVictim(for tileID: Int, in state: CoreGameStateV1) -> String? {
        state.defaultKnightVictim(for: tileID, actor: state.currentPlayer)
    }

    private func defaultMonopolyResource(for actor: String, in state: CoreGameStateV1) -> ResourceV1? {
        state.defaultMonopolyResource(for: actor)
    }

    private func defaultYearOfPlentyResources(from state: CoreGameStateV1) -> (first: ResourceV1, second: ResourceV1)? {
        guard let selection = state.defaultYearOfPlentyResources() else {
            return nil
        }
        return (selection.first, selection.second)
    }

    private func defaultRoadBuildingEdges(for player: String, in state: CoreGameStateV1) -> (first: Int, second: Int)? {
        guard let edges = state.defaultRoadBuildingEdges(for: player) else {
            return nil
        }
        return (edges.firstEdgeID, edges.secondEdgeID)
    }

    private func firstLegalRoadEdge(for player: String, in state: CoreGameStateV1) -> Int? {
        state.firstLegalRoadEdge(for: player)
    }

    private func firstLegalSettlementNode(for player: String, in state: CoreGameStateV1) -> Int? {
        state.firstLegalSettlementNode(for: player)
    }

    private func firstUpgradeableCityNode(for player: String, in state: CoreGameStateV1) -> Int? {
        state.firstUpgradeableCityNode(for: player)
    }

    private func defaultDiscardForLocalActor(from state: CoreGameStateV1) -> TransportResourceHandV1? {
        guard let actor = localActorIdentifier() else {
            return nil
        }
        return state.defaultDiscard(for: actor).map(transportHand(from:))
    }

    private func defaultTradeProposal(
        for actor: String,
        from state: CoreGameStateV1
    ) -> (give: TransportResourceHandV1, receive: TransportResourceHandV1)? {
        guard let proposal = state.defaultTradeProposal(for: actor) else {
            return nil
        }
        return (
            give: transportHand(from: proposal.give),
            receive: transportHand(from: proposal.receive)
        )
    }

    private func defaultMaritimeTrade(
        for actor: String,
        from state: CoreGameStateV1
    ) -> (give: TransportResourceHandV1, receive: TransportResourceHandV1, ratio: Int)? {
        guard let maritime = state.defaultMaritimeTrade(for: actor) else {
            return nil
        }
        return (
            give: transportHand(from: maritime.give),
            receive: transportHand(from: maritime.receive),
            ratio: maritime.ratio
        )
    }

    private func transportHand(from hand: ResourceHandV1) -> TransportResourceHandV1 {
        TransportResourceHandV1(
            wood: hand.wood,
            brick: hand.brick,
            sheep: hand.sheep,
            wheat: hand.wheat,
            ore: hand.ore
        )
    }

    private func transportResource(from resource: ResourceV1) -> TransportResourceV1 {
        switch resource {
        case .wood:
            return .wood
        case .brick:
            return .brick
        case .sheep:
            return .sheep
        case .wheat:
            return .wheat
        case .ore:
            return .ore
        case .desert:
            return .wood
        }
    }

    private func payloadValue(from message: MSMessage) -> TranscriptDecodedPayload? {
        TranscriptTransportSupport.decodePayload(
            from: message.url,
            summaryText: message.summaryText,
            summaryPayloadPrefix: summaryPayloadPrefix,
            allowSummaryFallback: allowIncomingSummaryPayloadFallback
        )
    }

    private func sendEnvelope(
        _ envelope: EnvelopeV1,
        caption: String,
        sessionPolicy: TranscriptSessionPolicy,
        postPublishEffect: PostPublishEffect = .none
    ) throws {
        guard let conversation = activeConversation else {
            throw SendError.noActiveConversation
        }

        let encodedEnvelope = try encode(envelope)
        let resolvedPolicy = TranscriptTransportSupport.resolveSessionPolicy(
            requestedPolicy: sessionPolicy,
            envelopeKind: envelope.kind,
            useSingleSessionDebug: false,
            currentGameId: currentGameId()
        )
        let builtMessage = try TranscriptTransportSupport.buildMessage(
            encodedEnvelope: encodedEnvelope,
            caption: caption,
            summaryLabel: summaryLabel(for: envelope),
            session: session(for: resolvedPolicy),
            sessionPolicy: resolvedPolicy,
            summaryPayloadPrefix: summaryPayloadPrefix,
            includeSummaryPayloadMirror: includeOutgoingSummaryPayloadMirror
        )
        let localLedgerStateRecord = localLedgerStateRecord(from: envelope)

        appendLog(
            "Publish \(envelope.kind.rawValue) session=\(builtMessage.sessionPolicy.label) payload=\(builtMessage.payloadLength) summaryPayload=\(builtMessage.mirroredPayloadLength) url=\(builtMessage.urlString)"
        )
        appendLog("Publish summary: \(builtMessage.summaryText)")

        publish(
            builtMessage.message,
            into: conversation,
            envelopeKind: envelope.kind,
            sessionPolicy: builtMessage.sessionPolicy,
            localLedgerStateRecord: localLedgerStateRecord,
            postPublishEffect: postPublishEffect
        )
    }

    private func publish(
        _ message: MSMessage,
        into conversation: MSConversation,
        envelopeKind: EnvelopeV1.Kind,
        sessionPolicy: TranscriptSessionPolicy,
        localLedgerStateRecord: Data?,
        postPublishEffect: PostPublishEffect
    ) {
        let envelopeKindLabel = envelopeKind.rawValue
        let sessionPolicyLabel = sessionPolicy.label
        let sentSessionID = message.session.map(Self.sessionIdentity) ?? "-"
        conversation.send(message) { [weak self] error in
            Task { @MainActor in
                guard let self else { return }
                if let error {
                    self.setLastError("Publish failed: \(error.localizedDescription)")
                    self.appendLog(
                        "Error: publish failed kind=\(envelopeKindLabel) session=\(sessionPolicyLabel)"
                    )
                } else {
                    self.recordPublishSelectionSnapshot(
                        envelopeKindLabel: envelopeKindLabel,
                        sessionPolicyLabel: sessionPolicyLabel,
                        sentSessionID: sentSessionID
                    )
                    if let localLedgerStateRecord {
                        self.cacheLocalLedgerStateRecord(localLedgerStateRecord)
                        self.appendLog("Stored local ledger STATE record")
                    }
                    self.appendLog(
                        "Published kind=\(envelopeKindLabel) session=\(sessionPolicyLabel)"
                    )
                    self.apply(postPublishEffect: postPublishEffect)
                }
            }
        }
    }

    func requestExtensionDismissal() {
        dismissRequestToken += 1
        onRequestDismiss?()
        appendLog("Requested extension dismiss")
    }

    private func apply(postPublishEffect: PostPublishEffect) {
        switch postPublishEffect {
        case .none:
            break
        case .dismissExtension:
            requestExtensionDismissal()
        }
    }

    private func recordPublishSelectionSnapshot(
        envelopeKindLabel: String,
        sessionPolicyLabel: String,
        sentSessionID: String
    ) {
        guard diagnosticsEnabled else {
            return
        }

        let selectedMessage = activeConversation?.selectedMessage
        let snapshot = TranscriptTransportSupport.selectionSnapshot(
            for: selectedMessage,
            summaryPayloadPrefix: summaryPayloadPrefix,
            allowSummaryFallback: allowIncomingSummaryPayloadFallback
        )
        let selectedSessionID = selectedMessage?.session.map(Self.sessionIdentity) ?? "-"
        let matchesSentSession =
            sentSessionID != "-" && selectedSessionID == sentSessionID ? "yes" : "no"

        lastPublishSelectionSnapshot =
            "kind=\(envelopeKindLabel) policy=\(sessionPolicyLabel) "
            + "selectedMsg=\(snapshot.messagePresence) "
            + "selectedSession=\(snapshot.sessionPresence) "
            + "selectedSessionId=\(selectedSessionID) "
            + "sentSessionId=\(sentSessionID) "
            + "matchesSent=\(matchesSentSession) "
            + "selectedURL=\(snapshot.urlPresence) "
            + "decode=\(snapshot.decodeSource)"
        appendLog("postPublish \(lastPublishSelectionSnapshot)")
    }

    private func localLedgerStateRecord(from envelope: EnvelopeV1) -> Data? {
        guard case let .state(payload) = envelope.body else {
            return nil
        }

        let state = try? decodePayload(CoreGameStateV1.self, from: payload)

        return try? JSONEncoder().encode(
            LocalLedgerStateRecord(
                gameId: state?.gameId,
                payload: payload,
                savedAt: Date().timeIntervalSince1970
            )
        )
    }

    private func summaryLabel(for envelope: EnvelopeV1) -> String {
        switch envelope.body {
        case let .state(payload):
            if let state = try? decodePayload(CoreGameStateV1.self, from: payload) {
                let step = state.turnState?.step.rawValue ?? "-"
                return "STATE r\(state.rev) p=\(state.phase.rawValue) cur=\(shortIdentifier(state.currentPlayer)) step=\(step)"
            }
            return "STATE"
        case let .intent(payload):
            if let turnIntent = try? decodePayload(ULS_Transport.TurnIntentV1.self, from: payload) {
                if TurnIntentContextResolver.isTradeResponse(turnIntent.kind) {
                    return "TRADE_RESPONSE actor=\(shortIdentifier(turnIntent.actor)) kind=\(turnIntent.kind.rawValue) a=r\(turnIntent.anchorRev)"
                }
                if case .responderMessage(.discardResponse) = TurnIntentTransportRoleResolver.resolve(turnIntent) {
                    return "DISCARD_RESPONSE actor=\(shortIdentifier(turnIntent.actor)) a=r\(turnIntent.anchorRev)"
                }
                return "LEGACY_INTENT actor=\(shortIdentifier(turnIntent.actor)) kind=\(turnIntent.kind.rawValue) a=r\(turnIntent.anchorRev)"
            }
            if let setupIntent = try? decodePayload(SetupPlacementIntentV1.self, from: payload) {
                return "LEGACY_SETUP actor=\(shortIdentifier(setupIntent.actor)) kind=\(setupIntent.kind.rawValue) a=r\(setupIntent.anchorRev)"
            }
            if let joinIntent = try? decodePayload(JoinIntentV1.self, from: payload) {
                return "LEGACY_JOIN actor=\(shortIdentifier(joinIntent.actor)) a=r\(joinIntent.anchorRev)"
            }
            return "LEGACY_INTENT"
        }
    }

    private func setupIntentForTransport(_ intent: SetupPlacementIntentV1) throws -> SetupIntentV1 {
        switch intent.kind {
        case .placeSetupSettlement:
            guard let node = intent.node else {
                throw SendError.invalidIntentPayload
            }
            return .placeSetupSettlement(node: node)
        case .placeSetupRoad:
            guard let edge = intent.edge else {
                throw SendError.invalidIntentPayload
            }
            return .placeSetupRoad(edge: edge)
        case .placeSetupPair:
            guard let node = intent.node, let edge = intent.edge else {
                throw SendError.invalidIntentPayload
            }
            return .placeSetupPair(settlementNode: node, roadEdge: edge)
        }
    }

    private func turnIntentForTransport(_ intent: ULS_Transport.TurnIntentV1) throws -> ULS_CoreGame.TurnIntentV1 {
        switch intent.kind {
        case .rollDice:
            return .rollDice
        case .submitDiscard:
            guard let player = intent.discardPlayer, let discarded = intent.discarded else {
                throw SendError.invalidIntentPayload
            }
            return .submitDiscard(player: player, discarded: resourceHand(from: discarded))
        case .moveRobber:
            guard let tileID = intent.robberTileID else {
                throw SendError.invalidIntentPayload
            }
            return .moveRobber(tileID: tileID)
        case .selectStealVictim:
            guard let victim = intent.stealVictimPlayer else {
                throw SendError.invalidIntentPayload
            }
            return .selectStealVictim(victimPlayer: victim)
        case .buildRoad:
            guard let edgeID = intent.buildEdgeID else {
                throw SendError.invalidIntentPayload
            }
            return .buildRoad(edgeID: edgeID)
        case .buildSettlement:
            guard let nodeID = intent.buildNodeID else {
                throw SendError.invalidIntentPayload
            }
            return .buildSettlement(nodeID: nodeID)
        case .buildCity:
            guard let nodeID = intent.buildNodeID else {
                throw SendError.invalidIntentPayload
            }
            return .buildCity(nodeID: nodeID)
        case .proposeTrade:
            guard
                let give = intent.tradeGive,
                let receive = intent.tradeReceive,
                let recipients = intent.tradeTargetPlayers
            else {
                throw SendError.invalidIntentPayload
            }
            return .proposeTrade(
                give: resourceHand(from: give),
                receive: resourceHand(from: receive),
                recipients: recipients
            )
        case .acceptTrade:
            guard let acceptingPlayer = intent.tradeAcceptPlayer, let offerHash = intent.tradeOfferHash else {
                throw SendError.invalidIntentPayload
            }
            return .acceptTrade(acceptingPlayer: acceptingPlayer, offerHash: offerHash)
        case .declineTrade:
            guard let decliningPlayer = intent.tradeAcceptPlayer, let offerHash = intent.tradeOfferHash else {
                throw SendError.invalidIntentPayload
            }
            return .declineTrade(decliningPlayer: decliningPlayer, offerHash: offerHash)
        case .counterTrade:
            guard
                let counteringPlayer = intent.tradeAcceptPlayer,
                let offerHash = intent.tradeOfferHash,
                let give = intent.tradeGive,
                let receive = intent.tradeReceive
            else {
                throw SendError.invalidIntentPayload
            }
            return .counterTrade(
                counteringPlayer: counteringPlayer,
                offerHash: offerHash,
                give: resourceHand(from: give),
                receive: resourceHand(from: receive)
            )
        case .executeTrade:
            guard let acceptingPlayer = intent.tradeAcceptPlayer, let offerHash = intent.tradeOfferHash else {
                throw SendError.invalidIntentPayload
            }
            return .executeTrade(acceptingPlayer: acceptingPlayer, offerHash: offerHash)
        case .maritimeTrade:
            guard let give = intent.tradeGive, let receive = intent.tradeReceive else {
                throw SendError.invalidIntentPayload
            }
            return .maritimeTrade(give: resourceHand(from: give), receive: resourceHand(from: receive))
        case .buyDevCard:
            return .buyDevCard
        case .playDevCard:
            guard let playKind = intent.devCardPlayKind else {
                throw SendError.invalidIntentPayload
            }
            switch playKind {
            case .knight:
                guard let tileID = intent.devCardTileID else {
                    throw SendError.invalidIntentPayload
                }
                return .playKnight(tileID: tileID, victimPlayer: intent.devCardVictimPlayer)
            case .monopoly:
                guard let resource = intent.devCardResource else {
                    throw SendError.invalidIntentPayload
                }
                return .playMonopoly(resource: resourceValue(from: resource))
            case .yearOfPlenty:
                guard
                    let first = intent.devCardFirstResource,
                    let second = intent.devCardSecondResource
                else {
                    throw SendError.invalidIntentPayload
                }
                return .playYearOfPlenty(
                    first: resourceValue(from: first),
                    second: resourceValue(from: second)
                )
            case .roadBuilding:
                guard
                    let firstEdge = intent.devCardFirstEdgeID,
                    let secondEdge = intent.devCardSecondEdgeID
                else {
                    throw SendError.invalidIntentPayload
                }
                return .playRoadBuilding(firstEdgeID: firstEdge, secondEdgeID: secondEdge)
            case .revealVictoryPoint:
                return .revealVictoryPoint
            }
        case .endTurn:
            return .endTurn
        }
    }

    private func resourceHand(from hand: TransportResourceHandV1) -> ResourceHandV1 {
        ResourceHandV1(
            wood: hand.wood,
            brick: hand.brick,
            sheep: hand.sheep,
            wheat: hand.wheat,
            ore: hand.ore
        )
    }

    private func resourceValue(from resource: TransportResourceV1) -> ResourceV1 {
        switch resource {
        case .wood:
            return .wood
        case .brick:
            return .brick
        case .sheep:
            return .sheep
        case .wheat:
            return .wheat
        case .ore:
            return .ore
        }
    }

    private func decodePayload<T: Decodable>(_ type: T.Type, from payload: String) throws -> T {
        if type == CoreGameStateV1.self {
            let state = try CompactStateTransport.decode(payload)
            guard let typedState = state as? T else {
                throw TransportError.invalidJSON
            }
            return typedState
        }

        let data = Data(payload.utf8)
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            throw TransportError.invalidJSON
        }
    }

    private func jsonString<T: Encodable>(from value: T) throws -> String {
        if let state = value as? CoreGameStateV1 {
            return try CompactStateTransport.encode(state)
        }

        let data = try JSONEncoder().encode(value)
        guard let jsonString = String(data: data, encoding: .utf8) else {
            throw SendError.invalidJSONPayload
        }
        return jsonString
    }

    private func localActorIdentifier() -> String? {
        localActorIdentifier(for: selectedState)
    }

    private func localActorIdentifier(for state: CoreGameStateV1?) -> String? {
        ProductActorResolver.resolve(
            localParticipant: localParticipantIdentifier(),
            state: state
        )
    }

    private func shouldRecoverActiveContext(to state: CoreGameStateV1) -> Bool {
        guard let selectedState else {
            return true
        }

        return selectedState.gameId != state.gameId
            || selectedState.rev != state.rev
            || selectedState.stateHash != state.stateHash
    }

    private func resolvedActiveContextSource(
        for source: TurnIntentContextCandidateSource
    ) -> ActiveContextSource {
        switch source {
        case .selectedState:
            return activeSource ?? .selectedBubble
        case .latestKnownState:
            return .latestKnownState
        case .localLedgerState:
            return .localLedgerState
        }
    }

    private func resolvedActiveContextSource(
        for source: ActionAuthoringStateSource
    ) -> ActiveContextSource {
        switch source {
        case .selectedState:
            return activeSource ?? .selectedBubble
        case .latestKnownState:
            return .latestKnownState
        case .localLedgerState:
            return .localLedgerState
        }
    }

    private func debugActorIdentifier() -> String? {
        if let state = selectedState, state.roster.contains(actingAs) {
            return actingAs
        }
        return localParticipantIdentifier()
    }

    private func localParticipantIdentifier() -> String? {
        activeConversation?.localParticipantIdentifier.uuidString
    }

    private func currentGameId() -> String? {
        if let state = selectedState {
            return state.gameId
        }
        if let intent = selectedJoinIntent {
            return intent.gameId
        }
        if let setupIntent = selectedSetupIntent {
            return setupIntent.gameId
        }
        if let turnIntent = selectedTurnIntent {
            return turnIntent.gameId
        }
        return nil
    }

    private func refreshObservedJoinersDebug(for gameId: String?) {
        guard diagnosticsEnabled else {
            return
        }
        guard let gameId else {
            observedJoinersDebug = "[]"
            refreshParticipantIdentityDebug()
            return
        }

        let joiners = currentObservedJoiners(for: gameId)
        observedJoinersDebug = joiners.isEmpty ? "[]" : joiners.joined(separator: ", ")
        refreshParticipantIdentityDebug()
    }

    private func currentObservedJoiners() -> [String] {
        guard let gameId = currentGameId() else {
            return []
        }
        return currentObservedJoiners(for: gameId)
    }

    private func currentObservedJoiners(for gameId: String) -> [String] {
        gameLedgerStore.observedJoiners(for: gameId)
    }

    private func rememberObservedJoiner(_ joiner: String, for gameId: String) {
        gameLedgerStore.recordJoin(actor: joiner, gameId: gameId)
        refreshRecoveredGames()
    }

    private func refreshRecoveredGames() {
        recoveredGames = gameLedgerStore.recoveredStates().map { recovered in
            ActiveGameRecoveryModelBuilder.build(
                from: recovered.state,
                isLastActive: recovered.isLastActive,
                isCurrentSelection: recovered.state.gameId == selectedState?.gameId
            )
        }
    }

    private func applyAndPublishTurnIntent(
        _ turnIntent: ULS_Transport.TurnIntentV1,
        successStatus: String
    ) throws {
        let resolution = actionAuthoringStateResolution(for: turnIntent.gameId)
        activateAuthoringStateIfNeeded(resolution)

        guard let fromState = resolution.state ?? selectedState else {
            throw NSError(domain: "LobbyDriverViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "No active context."])
        }
        guard let localActor = localActorIdentifier(for: fromState) else {
            throw NSError(domain: "LobbyDriverViewModel", code: 2, userInfo: [NSLocalizedDescriptionKey: "This device has not joined the selected game."])
        }
        guard
            turnIntent.gameId == fromState.gameId,
            turnIntent.anchorRev == fromState.rev,
            turnIntent.anchorHash == fromState.stateHash
        else {
            throw NSError(domain: "LobbyDriverViewModel", code: 3, userInfo: [NSLocalizedDescriptionKey: "Turn intent anchor does not match Active Context."])
        }

        let actor = TurnIntentPublishActorResolver.resolve(turnIntent, localActor: localActor)
        let coreIntent = try turnIntentForTransport(turnIntent)
        let toState = try ULS_CoreGame.apply(intent: coreIntent, to: fromState, actor: actor)
        try validateTransition(from: fromState, to: toState, actor: actor)

        let payload = try jsonString(from: toState)
        let envelope = EnvelopeV1(kind: .state, body: .state(payload: payload))
        try sendEnvelope(
            envelope,
            caption: "ULS STATE rev\(toState.rev)",
            sessionPolicy: .state(gameId: toState.gameId)
        )
        selectedTurnIntent = nil
        setActiveContext(toState, source: .lastSentState)
        selectionStatus = "\(successStatus) rev\(toState.rev)"
        setLastError(nil)
    }

    private func publishTradeResponse(_ turnIntent: ULS_Transport.TurnIntentV1) throws {
        guard TradeResponsePublicationResolver.resolve(turnIntent) != nil else {
            throw SendError.invalidIntentPayload
        }
        try applyAndPublishTurnIntent(
            turnIntent,
            successStatus: successStatus(for: turnIntent.kind)
        )
    }

    private func discardIntentReanchoredIfNeeded(
        _ turnIntent: ULS_Transport.TurnIntentV1,
        to state: CoreGameStateV1
    ) throws -> ULS_Transport.TurnIntentV1 {
        guard
            turnIntent.anchorRev != state.rev || turnIntent.anchorHash != state.stateHash
        else {
            return turnIntent
        }

        guard turnIntent.kind == .submitDiscard else {
            return turnIntent
        }

        guard let discardPlayer = turnIntent.discardPlayer, let discarded = turnIntent.discarded else {
            throw SendError.invalidIntentPayload
        }

        return ULS_Transport.TurnIntentV1(
            submitDiscardFor: discardPlayer,
            discarded: discarded,
            gameId: state.gameId,
            anchorRev: state.rev,
            anchorHash: state.stateHash,
            actor: turnIntent.actor
        )
    }

    private func immediateTurnIntent(for actionKind: GameActionDockItem.Kind) -> ULS_Transport.TurnIntentV1? {
        let resolution = actionAuthoringStateResolution()
        guard
            let authoringState = resolution.state,
            authoringState.phase == .turn,
            let authoringActor = localActorIdentifier(for: authoringState),
            authoringActor == authoringState.currentPlayer
        else {
            return nil
        }
        activateAuthoringStateIfNeeded(resolution)

        switch actionKind {
        case .roll:
            guard authoringState.turnState?.step == .needsRoll else {
                return nil
            }
            return ULS_Transport.TurnIntentV1(
                kind: .rollDice,
                gameId: authoringState.gameId,
                anchorRev: authoringState.rev,
                anchorHash: authoringState.stateHash,
                actor: authoringActor
            )
        case .endTurn:
            guard authoringState.turnState?.step == .afterRoll else {
                return nil
            }
            return ULS_Transport.TurnIntentV1(
                kind: .endTurn,
                gameId: authoringState.gameId,
                anchorRev: authoringState.rev,
                anchorHash: authoringState.stateHash,
                actor: authoringActor
            )
        case .build, .trade, .devCards:
            return nil
        }
    }

    private func selectionSignature(for message: MSMessage) -> String? {
        if let urlString = message.url?.absoluteString, !urlString.isEmpty {
            return "url:\(urlString)"
        }

        let caption = (message.layout as? MSMessageTemplateLayout)?.caption ?? "-"
        let summary = message.summaryText ?? "-"
        return "summary:\(caption)|\(summary)"
    }

    private func successStatus(for kind: ULS_Transport.TurnIntentV1.Kind) -> String {
        switch kind {
        case .rollDice:
            return "Published roll"
        case .submitDiscard:
            return "Published discard"
        case .moveRobber:
            return "Published robber move"
        case .selectStealVictim:
            return "Published steal selection"
        case .buildRoad:
            return "Published road build"
        case .buildSettlement:
            return "Published settlement build"
        case .buildCity:
            return "Published city upgrade"
        case .proposeTrade:
            return "Published trade offer"
        case .acceptTrade:
            return "Applied trade accept"
        case .declineTrade:
            return "Applied trade decline"
        case .counterTrade:
            return "Applied trade counter"
        case .executeTrade:
            return "Published trade execution"
        case .maritimeTrade:
            return "Published maritime trade"
        case .buyDevCard:
            return "Published dev-card purchase"
        case .endTurn:
            return "Published end turn"
        default:
            return "Published turn action"
        }
    }

    private func setLastError(_ message: String?) {
        lastError = message ?? "-"
        if let message {
            appendLog("Error: \(message)")
        }
    }

    private func session(for policy: TranscriptSessionPolicy) -> MSSession {
        switch policy {
        case .new:
            let session = MSSession()
            let resolveLine = "policy=new id=\(Self.sessionIdentity(session))"
            appendLog("session.resolve \(resolveLine)")
            lastSessionResolve = resolveLine
            return session
        case let .state(gameId):
            let selected = activeConversation?.selectedMessage
            let selectedGameId = selectedState?.gameId
            let cached = stateSessionsByGameId[gameId]
            let preferredSession = TranscriptTransportSupport.preferredStateSession(
                gameId: gameId,
                selectedMessage: selected,
                selectedGameId: selectedGameId,
                cachedSession: cached
            )

            let source: String
            if selectedGameId == gameId, let selectedSession = selected?.session, selectedSession === preferredSession {
                source = "selected"
            } else if let cached, cached === preferredSession {
                source = "cached"
            } else {
                source = "new"
            }
            let resolveLine = "policy=state game=\(shortIdentifier(gameId)) source=\(source) "
                + "id=\(Self.sessionIdentity(preferredSession)) "
                + "selectedGame=\(shortIdentifier(selectedGameId ?? "-")) "
                + "selectedSessionPresent=\(selected?.session == nil ? "no" : "yes") "
                + "cachedPresent=\(cached == nil ? "no" : "yes")"
            appendLog("session.resolve \(resolveLine)")
            lastSessionResolve = resolveLine

            stateSessionsByGameId[gameId] = preferredSession
            refreshSessionCacheSummary()
            return preferredSession
        }
    }

    private func refreshSessionCacheSummary() {
        if stateSessionsByGameId.isEmpty {
            sessionCacheSummary = "empty"
            return
        }
        let entries = stateSessionsByGameId
            .sorted { $0.key < $1.key }
            .map { "\(shortIdentifier($0.key))→\(Self.sessionIdentity($0.value))" }
        sessionCacheSummary = entries.joined(separator: " ")
    }

    func recordLifecycleEvent(_ event: String) {
        let timestamp = Self.lifecycleTimeFormatter.string(from: Date())
        let entry = "\(timestamp) \(event)"
        lastLifecycleEvent = entry
        switch event {
        case "willBecomeActive", "didBecomeActive":
            lifecycleState = "active"
        case "willResignActive":
            lifecycleState = "resigned"
        default:
            break
        }
        lifecycleHistory.append(entry)
        if lifecycleHistory.count > 8 {
            lifecycleHistory.removeFirst(lifecycleHistory.count - 8)
        }
        appendLog("lifecycle \(entry)")
    }

    private static let lifecycleTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()

    static func sessionIdentity(_ session: MSSession) -> String {
        let ptr = Unmanaged.passUnretained(session).toOpaque()
        return String(UInt(bitPattern: ptr), radix: 16)
    }

    private enum ActiveContextSource {
        case selectedBubble
        case receivedMessage
        case latestKnownState
        case lastSentState
        case localLedgerState

        var label: String {
            switch self {
            case .selectedBubble:
                return "selectedBubble"
            case .receivedMessage:
                return "receivedMessage"
            case .latestKnownState:
                return "latestKnownState"
            case .lastSentState:
                return "lastSentState"
            case .localLedgerState:
                return "localLedgerState"
            }
        }
    }

    private struct LocalLedgerStateRecord: Codable {
        let gameId: String?
        let payload: String
        let savedAt: TimeInterval
    }

    private struct BoardOverlayModelCacheKey: Equatable {
        let stateHash: String?
        let actor: String?
        let mode: GameMode
        let draft: GameDevCardDraft?
        let selectedTarget: GameBoardTarget?
    }

    private struct DevCardPanelModelCacheKey: Equatable {
        let stateHash: String?
        let actor: String?
        let mode: GameMode
        let draft: GameDevCardDraft?
    }

    private struct BankTrayModelCacheKey: Equatable {
        let stateHash: String?
        let actor: String?
        let mode: GameMode
        let draft: GameDevCardDraft?
    }

    private enum PostPublishEffect {
        case none
        case dismissExtension
    }

    private enum SendError: LocalizedError {
        case noActiveConversation
        case invalidJSONPayload
        case invalidIntentPayload
        case unsupportedResponderTransport

        var errorDescription: String? {
            switch self {
            case .noActiveConversation:
                return "No active conversation."
            case .invalidJSONPayload:
                return "Could not create JSON payload string."
            case .invalidIntentPayload:
                return "Intent payload is missing required fields."
            case .unsupportedResponderTransport:
                return "Only responder-side trade and discard messages may use detached transport."
            }
        }
    }
}
