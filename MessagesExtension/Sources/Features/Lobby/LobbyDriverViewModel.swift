import Combine
import Foundation
import Messages
import ULS_CoreGame
import ULS_Transport

@MainActor
final class LobbyDriverViewModel: ObservableObject {
    @Published private(set) var gameplayShellProjection: GameShellProjection = .empty
    @Published var pendingJoiners: String = "[]"
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
    @Published var localParticipantDebug: String = "-"
    @Published var resolvedActorDebug: String = "-"
    @Published var localInRosterDebug: String = "-"
    @Published var localPendingJoinDebug: String = "-"
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

    private let summaryPayloadPrefix = "ulsenv:"
    private let boardStrategyKey = "uls.boardStrategy"
    private let userDefaults: UserDefaults
    private let gameLedgerStore: TranscriptGameLedgerStore
    private let diagnosticsConfig = TemporaryDiagnosticsConfig.live
    private let allowsRuntimeDebugControls = false
    private let allowsCachedPublishedStateRecovery = true
    private let showsLatestUpdateNotices = false

    private weak var activeConversation: MSConversation?
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
        latestKnownStatesByGameId = gameLedgerStore.bootstrapSnapshot().latestKnownStatesByGameId
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

    private var allowSummaryPayloadFallback: Bool {
        // Temporary production fallback so phase 12 gameplay can stay playable
        // on real devices while phase 13 redesigns transport rehydration.
        true
    }

    var canInvite: Bool {
        activeConversation != nil
    }

    var rootRoute: MessagesRootRoute {
        MessagesRootRoute.resolve(phase: selectedState?.phase)
    }

    var lobbyScreenModel: LobbyScreenModel {
        LobbyScreenModelBuilder.build(
            context: LobbyScreenContext(
                selectedState: selectedState,
                selectedJoinIntent: selectedJoinIntent,
                localActor: localParticipantIdentifier(),
                pendingJoiners: currentPendingJoiners(),
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
            canRoll: canSendRollDiceIntentDebug,
            canBuild: canSendBuildRoadIntentDebug || canSendBuildSettlementIntentDebug || canSendBuildCityIntentDebug,
            canTrade: canOpenTradePanel,
            canBuyDevCard: canSendBuyDevCardIntentDebug,
            canPlayDevCards: canSendPlayKnightIntentDebug
                || canSendPlayMonopolyIntentDebug
                || canSendPlayYearOfPlentyIntentDebug
                || canSendPlayRoadBuildingIntentDebug
                || canSendRevealVictoryPointIntentDebug,
            canEndTurn: canSendEndTurnIntentDebug
        )
    }

    private var shellModeAvailability: GameModeAvailability {
        guard let state = selectedState else {
            return .none
        }

        let isCurrentActor = localActorIdentifier() == state.currentPlayer

        return GameModeAvailability(
            canSetup: state.phase == .setup && isCurrentActor,
            canBuildRoad: canSendBuildRoadIntentDebug,
            canBuildSettlement: canSendBuildSettlementIntentDebug,
            canBuildCity: canSendBuildCityIntentDebug,
            canRobberMove: canSendMoveRobberIntentDebug,
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
            localParticipant: localParticipantIdentifier(),
            pendingJoiners: currentPendingJoiners()
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

    var isSetupSelectedState: Bool {
        selectedState?.phase == .setup
    }

    var isTurnSelectedState: Bool {
        selectedState?.phase == .turn
    }

    var canSendSetupSettlementIntentDebug: Bool {
        isSetupSelectedState && localActorIdentifier() != nil
    }

    var canSendSetupRoadIntentDebug: Bool {
        isSetupSelectedState && localActorIdentifier() != nil
    }

    var canSendSetupPairIntentDebug: Bool {
        isSetupSelectedState && localActorIdentifier() != nil
    }

    var canSendRollDiceIntentDebug: Bool {
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

    var canSendSubmitDiscardIntentDebug: Bool {
        guard
            let state = selectedState,
            state.phase == .turn,
            state.turnState?.step == .pendingDiscards,
            let actor = localActorIdentifier(),
            let required = state.turnState?.discardRequirementsByPlayer[actor],
            required > 0
        else {
            return false
        }
        return defaultDiscardForLocalActor(from: state) != nil
    }

    var canSendMoveRobberIntentDebug: Bool {
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

    var canSendBuildRoadIntentDebug: Bool {
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

    var canSendBuildSettlementIntentDebug: Bool {
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

    var canSendBuildCityIntentDebug: Bool {
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

    var canSendMaritimeTradeIntentDebug: Bool {
        guard
            let state = selectedState,
            state.phase == .turn,
            state.turnState?.step == .afterRoll,
            let actor = localActorIdentifier(),
            actor == state.currentPlayer
        else {
            return false
        }
        return defaultMaritimeTrade(for: actor, from: state) != nil
    }

    var canSendBuyDevCardIntentDebug: Bool {
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

    var canSendPlayKnightIntentDebug: Bool {
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

    var canSendPlayMonopolyIntentDebug: Bool {
        guard canSendNamedDevCardIntentDebug({ $0.monopoly > 0 }),
              let state = selectedState,
              let actor = localActorIdentifier()
        else {
            return false
        }
        return !state.monopolyPreviews(for: actor).isEmpty
    }

    var canSendPlayYearOfPlentyIntentDebug: Bool {
        guard canSendNamedDevCardIntentDebug({ $0.yearOfPlenty > 0 }),
              let state = selectedState,
              let actor = localActorIdentifier()
        else {
            return false
        }
        return state.yearOfPlentyBankOptions(for: actor).reduce(0) { $0 + $1.remainingCount } >= 2
    }

    var canSendPlayRoadBuildingIntentDebug: Bool {
        guard canSendNamedDevCardIntentDebug({ $0.roadBuilding > 0 }),
              let state = selectedState,
              let actor = localActorIdentifier()
        else {
            return false
        }
        return !state.legalRoadBuildingFirstEdges(for: actor).isEmpty
    }

    var canSendRevealVictoryPointIntentDebug: Bool {
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

    var canSendEndTurnIntentDebug: Bool {
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
            localParticipant: localParticipantIdentifier(),
            pendingJoiners: currentPendingJoiners()
        )
    }

    var canClearPendingJoins: Bool {
        diagnosticsEnabled && currentGameId() != nil
    }

    var canApplySelectedSetupIntentAsState: Bool {
        guard
            let state = selectedState,
            let intent = selectedSetupIntent,
            let actor = localActorIdentifier(),
            actor == state.currentPlayer
        else {
            return false
        }
        return intent.gameId == state.gameId &&
            intent.anchorRev == state.rev &&
            intent.anchorHash == state.stateHash
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
                sessionPolicy: .state(gameId: state.gameId)
            )
            setActiveContext(state, source: .lastSentState)
            selectionStatus = "Invite sent: lobby rev0"
            setLastError(nil)
        } catch {
            setLastError("Invite failed: \(error.localizedDescription)")
        }
    }

    func sendJoinIntent() {
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

        guard let intent = LobbyMembershipResolver.makeJoinIntent(
            state: state,
            localParticipant: actor
        ) else {
            setLastError("Join is only available from lobby STATE messages.")
            return
        }

        do {
            let payload = try jsonString(from: intent)
            let envelope = EnvelopeV1(kind: .intent, body: .intent(payload: payload))
            try sendEnvelope(envelope, caption: "ULS INTENT join", sessionPolicy: .new)
            rememberPendingJoiner(actor, for: state.gameId)
            refreshPendingJoiners(for: state.gameId)
            selectionStatus = "Join intent sent"
            appendLog(
                "Sent INTENT kind=join actor=\(shortIdentifier(actor)) local=\(shortIdentifier(actor)) actingAs=\(shortIdentifier(actingAs)) anchorRev=\(state.rev)"
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

        rememberPendingJoiner(intent.actor, for: intent.gameId)
        refreshPendingJoiners(for: intent.gameId)
        selectionStatus = "Recorded join actor: \(intent.actor)"
        setLastError(nil)
    }

    func startGame() {
        guard let fromState = selectedState else {
            setLastError("Select the invite STATE first.")
            return
        }

        guard fromState.phase == .lobby, fromState.rev == 0 else {
            setLastError("Start is only available from lobby rev0 STATE.")
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

        let finalRoster = LobbyMembershipResolver.finalRoster(
            state: fromState,
            pendingJoiners: currentPendingJoiners(for: fromState.gameId)
        )

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
            resourcesByPlayer: Dictionary(uniqueKeysWithValues: finalRoster.map { ($0, .zero) }),
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
                caption: "ULS STATE rev1",
                sessionPolicy: .state(gameId: toState.gameId)
            )
            gameLedgerStore.clearObservedJoiners(for: toState.gameId)
            refreshPendingJoiners(for: toState.gameId)
            setActiveContext(toState, source: .lastSentState)
            selectionStatus = "Start sent: setup rev1"
            setLastError(nil)
        } catch {
            setLastError("Start failed: \(error.localizedDescription)")
        }
    }

    func clearPendingJoins() {
        guard diagnosticsEnabled else {
            setLastError("Debug join tools are disabled on this branch.")
            return
        }
        guard let gameId = currentGameId() else {
            setLastError("Select a message with a gameId first.")
            return
        }

        gameLedgerStore.clearObservedJoiners(for: gameId)
        refreshPendingJoiners(for: gameId)
        selectionStatus = "Cleared pending joins for \(gameId)"
        setLastError(nil)
    }

    func sendSetupSettlementIntentDebug(node: Int = 0) {
        guard let state = selectedState else {
            setLastError("Select a setup STATE first.")
            return
        }

        guard state.phase == .setup else {
            setLastError("Setup settlement intent is only available in setup phase.")
            return
        }

        guard let actor = localActorIdentifier() else {
            setLastError("Missing local participant identifier.")
            return
        }

        let intent = SetupPlacementIntentV1(
            gameId: state.gameId,
            anchorRev: state.rev,
            anchorHash: state.stateHash,
            actor: actor,
            node: node
        )

        do {
            let payload = try jsonString(from: intent)
            let envelope = EnvelopeV1(kind: .intent, body: .intent(payload: payload))
            try sendEnvelope(envelope, caption: "ULS INTENT setupSettlement", sessionPolicy: .new)
            selectionStatus = "Setup settlement intent sent"
            setLastError(nil)
        } catch {
            setLastError("Setup settlement failed: \(error.localizedDescription)")
        }
    }

    func sendSetupRoadIntentDebug(edge: Int = 0) {
        guard let state = selectedState else {
            setLastError("Select a setup STATE first.")
            return
        }

        guard state.phase == .setup else {
            setLastError("Setup road intent is only available in setup phase.")
            return
        }

        guard let actor = localActorIdentifier() else {
            setLastError("Missing local participant identifier.")
            return
        }

        let intent = SetupPlacementIntentV1(
            gameId: state.gameId,
            anchorRev: state.rev,
            anchorHash: state.stateHash,
            actor: actor,
            edge: edge
        )

        do {
            let payload = try jsonString(from: intent)
            let envelope = EnvelopeV1(kind: .intent, body: .intent(payload: payload))
            try sendEnvelope(envelope, caption: "ULS INTENT setupRoad", sessionPolicy: .new)
            selectionStatus = "Setup road intent sent"
            setLastError(nil)
        } catch {
            setLastError("Setup road failed: \(error.localizedDescription)")
        }
    }

    func sendSetupPairIntentDebug(settlementNode: Int = 0, roadEdge: Int = 0) {
        guard let state = selectedState else {
            setLastError("Select a setup STATE first.")
            return
        }

        guard state.phase == .setup else {
            setLastError("Setup pair intent is only available in setup phase.")
            return
        }

        guard let actor = localActorIdentifier() else {
            setLastError("Missing local participant identifier.")
            return
        }

        let intent = SetupPlacementIntentV1(
            gameId: state.gameId,
            anchorRev: state.rev,
            anchorHash: state.stateHash,
            actor: actor,
            settlementNode: settlementNode,
            roadEdge: roadEdge
        )

        do {
            let payload = try jsonString(from: intent)
            let envelope = EnvelopeV1(kind: .intent, body: .intent(payload: payload))
            try sendEnvelope(envelope, caption: "ULS INTENT setupPair", sessionPolicy: .new)
            selectionStatus = "Setup pair intent sent"
            setLastError(nil)
        } catch {
            setLastError("Setup pair failed: \(error.localizedDescription)")
        }
    }

    func sendRollDiceIntentDebug() {
        guard let state = selectedState else {
            setLastError("Select a turn STATE first.")
            return
        }

        guard state.phase == .turn else {
            setLastError("Roll intent is only available in turn phase.")
            return
        }

        guard let actor = localActorIdentifier() else {
            setLastError("Missing local participant identifier.")
            return
        }

        let intent = ULS_Transport.TurnIntentV1(
            kind: .rollDice,
            gameId: state.gameId,
            anchorRev: state.rev,
            anchorHash: state.stateHash,
            actor: actor
        )

        do {
            let payload = try jsonString(from: intent)
            let envelope = EnvelopeV1(kind: .intent, body: .intent(payload: payload))
            try sendEnvelope(envelope, caption: "ULS INTENT rollDice", sessionPolicy: .new)
            selectionStatus = "Turn roll intent sent"
            setLastError(nil)
        } catch {
            setLastError("Roll intent failed: \(error.localizedDescription)")
        }
    }

    func sendSubmitDiscardIntentDebug() {
        guard let state = selectedState else {
            setLastError("Select a turn STATE first.")
            return
        }

        guard state.phase == .turn, state.turnState?.step == .pendingDiscards else {
            setLastError("Discard intent is only available when pending discards are active.")
            return
        }

        guard let actor = localActorIdentifier() else {
            setLastError("Missing local participant identifier.")
            return
        }

        guard let discarded = defaultDiscardForLocalActor(from: state) else {
            setLastError("No valid discard payload for local actor.")
            return
        }

        let intent = ULS_Transport.TurnIntentV1(
            submitDiscardFor: actor,
            discarded: discarded,
            gameId: state.gameId,
            anchorRev: state.rev,
            anchorHash: state.stateHash,
            actor: actor
        )

        do {
            let payload = try jsonString(from: intent)
            let envelope = EnvelopeV1(kind: .intent, body: .intent(payload: payload))
            try sendEnvelope(envelope, caption: "ULS INTENT submitDiscard", sessionPolicy: .new)
            selectionStatus = "Discard intent sent"
            setLastError(nil)
        } catch {
            setLastError("Discard intent failed: \(error.localizedDescription)")
        }
    }

    func sendMoveRobberIntentDebug() {
        guard let state = selectedState else {
            setLastError("Select a turn STATE first.")
            return
        }

        guard state.phase == .turn, state.turnState?.step == .needsRobberMove else {
            setLastError("Move robber intent is only available when robber move is pending.")
            return
        }

        guard let actor = localActorIdentifier() else {
            setLastError("Missing local participant identifier.")
            return
        }

        guard let board = state.board, !board.resourcesByTile.isEmpty else {
            setLastError("Selected state has no valid board.")
            return
        }

        let targetTile = (board.robberTile + 1) % board.resourcesByTile.count
        let intent = ULS_Transport.TurnIntentV1(
            moveRobberTileID: targetTile,
            gameId: state.gameId,
            anchorRev: state.rev,
            anchorHash: state.stateHash,
            actor: actor
        )

        do {
            let payload = try jsonString(from: intent)
            let envelope = EnvelopeV1(kind: .intent, body: .intent(payload: payload))
            try sendEnvelope(envelope, caption: "ULS INTENT moveRobber", sessionPolicy: .new)
            selectionStatus = "Move robber intent sent"
            setLastError(nil)
        } catch {
            setLastError("Move robber intent failed: \(error.localizedDescription)")
        }
    }

    func sendSelectStealVictimIntentDebug(victimPlayer: String) {
        guard let state = selectedState else {
            setLastError("Select a turn STATE first.")
            return
        }

        guard state.phase == .turn, state.turnState?.step == .needsRobberSteal else {
            setLastError("Steal intent is only available when a robber steal is pending.")
            return
        }

        guard let actor = localActorIdentifier() else {
            setLastError("Missing local participant identifier.")
            return
        }

        let intent = ULS_Transport.TurnIntentV1(
            selectStealVictimPlayer: victimPlayer,
            gameId: state.gameId,
            anchorRev: state.rev,
            anchorHash: state.stateHash,
            actor: actor
        )

        do {
            let payload = try jsonString(from: intent)
            let envelope = EnvelopeV1(kind: .intent, body: .intent(payload: payload))
            try sendEnvelope(envelope, caption: "ULS INTENT selectStealVictim", sessionPolicy: .new)
            selectionStatus = "Steal victim intent sent"
            setLastError(nil)
        } catch {
            setLastError("Steal victim intent failed: \(error.localizedDescription)")
        }
    }

    func sendBuildRoadIntentDebug() {
        guard let state = selectedState else {
            setLastError("Select a turn STATE first.")
            return
        }
        guard state.phase == .turn, state.turnState?.step == .afterRoll else {
            setLastError("Build road intent is only available in post-roll step.")
            return
        }
        guard let actor = localActorIdentifier(), actor == state.currentPlayer else {
            setLastError("Only current player can send build road intent.")
            return
        }
        guard let edgeID = firstLegalRoadEdge(for: actor, in: state) else {
            setLastError("No legal road edge available.")
            return
        }

        let intent = ULS_Transport.TurnIntentV1(
            buildRoadEdgeID: edgeID,
            gameId: state.gameId,
            anchorRev: state.rev,
            anchorHash: state.stateHash,
            actor: actor
        )

        do {
            let payload = try jsonString(from: intent)
            let envelope = EnvelopeV1(kind: .intent, body: .intent(payload: payload))
            try sendEnvelope(envelope, caption: "ULS INTENT buildRoad", sessionPolicy: .new)
            selectionStatus = "Build road intent sent"
            setLastError(nil)
        } catch {
            setLastError("Build road intent failed: \(error.localizedDescription)")
        }
    }

    func sendBuildSettlementIntentDebug() {
        guard let state = selectedState else {
            setLastError("Select a turn STATE first.")
            return
        }
        guard state.phase == .turn, state.turnState?.step == .afterRoll else {
            setLastError("Build settlement intent is only available in post-roll step.")
            return
        }
        guard let actor = localActorIdentifier(), actor == state.currentPlayer else {
            setLastError("Only current player can send build settlement intent.")
            return
        }
        guard let nodeID = firstLegalSettlementNode(for: actor, in: state) else {
            setLastError("No legal settlement node available.")
            return
        }

        let intent = ULS_Transport.TurnIntentV1(
            buildSettlementNodeID: nodeID,
            gameId: state.gameId,
            anchorRev: state.rev,
            anchorHash: state.stateHash,
            actor: actor
        )

        do {
            let payload = try jsonString(from: intent)
            let envelope = EnvelopeV1(kind: .intent, body: .intent(payload: payload))
            try sendEnvelope(envelope, caption: "ULS INTENT buildSettlement", sessionPolicy: .new)
            selectionStatus = "Build settlement intent sent"
            setLastError(nil)
        } catch {
            setLastError("Build settlement intent failed: \(error.localizedDescription)")
        }
    }

    func sendBuildCityIntentDebug() {
        guard let state = selectedState else {
            setLastError("Select a turn STATE first.")
            return
        }
        guard state.phase == .turn, state.turnState?.step == .afterRoll else {
            setLastError("Build city intent is only available in post-roll step.")
            return
        }
        guard let actor = localActorIdentifier(), actor == state.currentPlayer else {
            setLastError("Only current player can send build city intent.")
            return
        }
        guard let nodeID = firstUpgradeableCityNode(for: actor, in: state) else {
            setLastError("No settlement available for city upgrade.")
            return
        }

        let intent = ULS_Transport.TurnIntentV1(
            buildCityNodeID: nodeID,
            gameId: state.gameId,
            anchorRev: state.rev,
            anchorHash: state.stateHash,
            actor: actor
        )

        do {
            let payload = try jsonString(from: intent)
            let envelope = EnvelopeV1(kind: .intent, body: .intent(payload: payload))
            try sendEnvelope(envelope, caption: "ULS INTENT buildCity", sessionPolicy: .new)
            selectionStatus = "Build city intent sent"
            setLastError(nil)
        } catch {
            setLastError("Build city intent failed: \(error.localizedDescription)")
        }
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
            try sendEnvelope(envelope, caption: "ULS INTENT proposeTrade", sessionPolicy: .new)
            selectionStatus = "Propose trade intent sent"
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
            try sendEnvelope(envelope, caption: "ULS INTENT acceptTrade", sessionPolicy: .new)
            selectionStatus = "Accept trade intent sent"
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
            try sendEnvelope(envelope, caption: "ULS INTENT executeTrade", sessionPolicy: .new)
            selectionStatus = "Execute trade intent sent"
            setLastError(nil)
        } catch {
            setLastError("Execute trade intent failed: \(error.localizedDescription)")
        }
    }

    func sendMaritimeTradeIntentDebug() {
        guard let state = selectedState else {
            setLastError("Select a turn STATE first.")
            return
        }
        guard canSendMaritimeTradeIntentDebug else {
            setLastError("Maritime trade intent is not currently legal.")
            return
        }
        guard let actor = localActorIdentifier(), actor == state.currentPlayer else {
            setLastError("Only current player can send maritime trade intent.")
            return
        }
        guard let maritime = defaultMaritimeTrade(for: actor, from: state) else {
            setLastError("No legal maritime trade available.")
            return
        }

        let intent = ULS_Transport.TurnIntentV1(
            maritimeTradeGive: maritime.give,
            receive: maritime.receive,
            gameId: state.gameId,
            anchorRev: state.rev,
            anchorHash: state.stateHash,
            actor: actor
        )

        do {
            let payload = try jsonString(from: intent)
            let envelope = EnvelopeV1(kind: .intent, body: .intent(payload: payload))
            try sendEnvelope(envelope, caption: "ULS INTENT maritimeTrade", sessionPolicy: .new)
            selectionStatus = "Maritime trade intent sent"
            setLastError(nil)
        } catch {
            setLastError("Maritime trade intent failed: \(error.localizedDescription)")
        }
    }

    func sendBuyDevCardIntentDebug() {
        guard let state = selectedState else {
            setLastError("Select a turn STATE first.")
            return
        }
        guard canSendBuyDevCardIntentDebug else {
            setLastError("Buy dev card intent is not currently legal.")
            return
        }
        guard let actor = localActorIdentifier() else {
            setLastError("Missing local participant identifier.")
            return
        }

        let intent = ULS_Transport.TurnIntentV1(
            kind: .buyDevCard,
            gameId: state.gameId,
            anchorRev: state.rev,
            anchorHash: state.stateHash,
            actor: actor
        )

        do {
            let payload = try jsonString(from: intent)
            let envelope = EnvelopeV1(kind: .intent, body: .intent(payload: payload))
            try sendEnvelope(envelope, caption: "ULS INTENT buyDevCard", sessionPolicy: .new)
            selectionStatus = "Buy dev card intent sent"
            setLastError(nil)
        } catch {
            setLastError("Buy dev card intent failed: \(error.localizedDescription)")
        }
    }

    func sendPlayKnightIntentDebug() {
        guard let state = selectedState else {
            setLastError("Select a turn STATE first.")
            return
        }
        guard canSendPlayKnightIntentDebug else {
            setLastError("Play Knight intent is not currently legal.")
            return
        }
        guard let actor = localActorIdentifier() else {
            setLastError("Missing local participant identifier.")
            return
        }
        guard let board = state.board else {
            setLastError("Selected state has no board.")
            return
        }

        let tileID = (board.robberTile + 1) % board.resourcesByTile.count
        let victim = defaultKnightVictim(for: tileID, in: state)
        let intent = ULS_Transport.TurnIntentV1(
            playDevCardKind: .knight,
            tileID: tileID,
            victimPlayer: victim,
            gameId: state.gameId,
            anchorRev: state.rev,
            anchorHash: state.stateHash,
            actor: actor
        )

        do {
            let payload = try jsonString(from: intent)
            let envelope = EnvelopeV1(kind: .intent, body: .intent(payload: payload))
            try sendEnvelope(envelope, caption: "ULS INTENT playKnight", sessionPolicy: .new)
            selectionStatus = "Play Knight intent sent"
            setLastError(nil)
        } catch {
            setLastError("Play Knight intent failed: \(error.localizedDescription)")
        }
    }

    func sendPlayMonopolyIntentDebug() {
        guard let state = selectedState else {
            setLastError("Select a turn STATE first.")
            return
        }
        guard canSendPlayMonopolyIntentDebug else {
            setLastError("Play Monopoly intent is not currently legal.")
            return
        }
        guard let actor = localActorIdentifier() else {
            setLastError("Missing local participant identifier.")
            return
        }
        guard let resource = defaultMonopolyResource(for: actor, in: state) else {
            setLastError("No legal monopoly resource available.")
            return
        }

        let intent = ULS_Transport.TurnIntentV1(
            playDevCardKind: .monopoly,
            resource: transportResource(from: resource),
            gameId: state.gameId,
            anchorRev: state.rev,
            anchorHash: state.stateHash,
            actor: actor
        )

        do {
            let payload = try jsonString(from: intent)
            let envelope = EnvelopeV1(kind: .intent, body: .intent(payload: payload))
            try sendEnvelope(envelope, caption: "ULS INTENT playMonopoly", sessionPolicy: .new)
            selectionStatus = "Play Monopoly intent sent"
            setLastError(nil)
        } catch {
            setLastError("Play Monopoly intent failed: \(error.localizedDescription)")
        }
    }

    func sendPlayYearOfPlentyIntentDebug() {
        guard let state = selectedState else {
            setLastError("Select a turn STATE first.")
            return
        }
        guard canSendPlayYearOfPlentyIntentDebug else {
            setLastError("Play Year of Plenty intent is not currently legal.")
            return
        }
        guard let actor = localActorIdentifier() else {
            setLastError("Missing local participant identifier.")
            return
        }
        guard let selection = defaultYearOfPlentyResources(from: state) else {
            setLastError("Bank cannot satisfy Year of Plenty.")
            return
        }

        let intent = ULS_Transport.TurnIntentV1(
            playDevCardKind: .yearOfPlenty,
            firstResource: transportResource(from: selection.first),
            secondResource: transportResource(from: selection.second),
            gameId: state.gameId,
            anchorRev: state.rev,
            anchorHash: state.stateHash,
            actor: actor
        )

        do {
            let payload = try jsonString(from: intent)
            let envelope = EnvelopeV1(kind: .intent, body: .intent(payload: payload))
            try sendEnvelope(envelope, caption: "ULS INTENT playYearOfPlenty", sessionPolicy: .new)
            selectionStatus = "Play Year of Plenty intent sent"
            setLastError(nil)
        } catch {
            setLastError("Play Year of Plenty intent failed: \(error.localizedDescription)")
        }
    }

    func sendPlayRoadBuildingIntentDebug() {
        guard let state = selectedState else {
            setLastError("Select a turn STATE first.")
            return
        }
        guard canSendPlayRoadBuildingIntentDebug else {
            setLastError("Play Road Building intent is not currently legal.")
            return
        }
        guard let actor = localActorIdentifier() else {
            setLastError("Missing local participant identifier.")
            return
        }
        guard let edges = defaultRoadBuildingEdges(for: actor, in: state) else {
            setLastError("No legal pair of roads for Road Building.")
            return
        }

        let intent = ULS_Transport.TurnIntentV1(
            playDevCardKind: .roadBuilding,
            firstEdgeID: edges.first,
            secondEdgeID: edges.second,
            gameId: state.gameId,
            anchorRev: state.rev,
            anchorHash: state.stateHash,
            actor: actor
        )

        do {
            let payload = try jsonString(from: intent)
            let envelope = EnvelopeV1(kind: .intent, body: .intent(payload: payload))
            try sendEnvelope(envelope, caption: "ULS INTENT playRoadBuilding", sessionPolicy: .new)
            selectionStatus = "Play Road Building intent sent"
            setLastError(nil)
        } catch {
            setLastError("Play Road Building intent failed: \(error.localizedDescription)")
        }
    }

    func sendRevealVictoryPointIntentDebug() {
        guard let state = selectedState else {
            setLastError("Select a turn STATE first.")
            return
        }
        guard canSendRevealVictoryPointIntentDebug else {
            setLastError("Reveal VP intent is not currently legal.")
            return
        }
        guard let actor = localActorIdentifier() else {
            setLastError("Missing local participant identifier.")
            return
        }

        let intent = ULS_Transport.TurnIntentV1(
            playDevCardKind: .revealVictoryPoint,
            gameId: state.gameId,
            anchorRev: state.rev,
            anchorHash: state.stateHash,
            actor: actor
        )

        do {
            let payload = try jsonString(from: intent)
            let envelope = EnvelopeV1(kind: .intent, body: .intent(payload: payload))
            try sendEnvelope(envelope, caption: "ULS INTENT revealVP", sessionPolicy: .new)
            selectionStatus = "Reveal VP intent sent"
            setLastError(nil)
        } catch {
            setLastError("Reveal VP intent failed: \(error.localizedDescription)")
        }
    }

    func sendEndTurnIntentDebug() {
        guard let state = selectedState else {
            setLastError("Select a turn STATE first.")
            return
        }

        guard state.phase == .turn else {
            setLastError("End turn intent is only available in turn phase.")
            return
        }

        guard let actor = localActorIdentifier() else {
            setLastError("Missing local participant identifier.")
            return
        }

        let intent = ULS_Transport.TurnIntentV1(
            kind: .endTurn,
            gameId: state.gameId,
            anchorRev: state.rev,
            anchorHash: state.stateHash,
            actor: actor
        )

        do {
            let payload = try jsonString(from: intent)
            let envelope = EnvelopeV1(kind: .intent, body: .intent(payload: payload))
            try sendEnvelope(envelope, caption: "ULS INTENT endTurn", sessionPolicy: .new)
            selectionStatus = "Turn end intent sent"
            setLastError(nil)
        } catch {
            setLastError("End turn intent failed: \(error.localizedDescription)")
        }
    }

    func applySelectedSetupIntentAsState() {
        guard let fromState = selectedState else {
            setLastError("No Active Context — tap a STATE bubble.")
            return
        }
        guard let setupIntent = selectedSetupIntent else {
            setLastError("Select a setup intent bubble first.")
            return
        }
        guard setupIntent.gameId == fromState.gameId,
              setupIntent.anchorRev == fromState.rev,
              setupIntent.anchorHash == fromState.stateHash else {
            setLastError("Selected setup intent anchor does not match Active Context.")
            return
        }
        guard let actor = localActorIdentifier(), actor == fromState.currentPlayer else {
            setLastError("Only current player can publish canonical STATE.")
            return
        }

        do {
            try applyAndPublishSetupIntent(
                setupIntent,
                from: fromState,
                actor: actor,
                successStatus: "Applied setup intent into STATE"
            )
        } catch {
            setLastError("Apply setup intent failed: \(error.localizedDescription)")
        }
    }

    @discardableResult
    func publishSetupState(for target: GameBoardTarget) -> Bool {
        guard let fromState = selectedState else {
            setLastError("No Active Context — tap a STATE bubble.")
            return false
        }

        guard let actor = localActorIdentifier(), actor == fromState.currentPlayer else {
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
        let intent: ULS_Transport.TurnIntentV1?
        let failureMessage: String

        switch mode {
        case .buildRoad, .buildSettlement, .buildCity:
            intent = TurnInteractionResolver.draftBuildIntent(
                state: selectedState,
                actingAs: localActorIdentifier(),
                mode: mode,
                target: target
            )
            failureMessage = "Selected build target is not legal."
        case .robberMove:
            intent = TurnInteractionResolver.draftRobberMoveIntent(
                state: selectedState,
                actingAs: localActorIdentifier(),
                target: target
            )
            failureMessage = "Selected robber tile is not legal."
        case .robberVictim:
            intent = TurnInteractionResolver.draftStealVictimIntent(
                state: selectedState,
                actingAs: localActorIdentifier(),
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

        do {
            try applyAndPublishTurnIntent(intent, successStatus: successStatus(for: intent.kind))
            return true
        } catch {
            setLastError("Turn action failed: \(error.localizedDescription)")
            return false
        }
    }

    @discardableResult
    func handleDiscardFlowAction() -> Bool {
        guard let state = selectedState else {
            setLastError("No Active Context — tap a STATE bubble.")
            return false
        }

        guard let actor = localActorIdentifier() else {
            setLastError("Missing local participant identifier.")
            return false
        }

        guard let intent = TurnInteractionResolver.draftDiscardIntent(
            state: state,
            actingAs: actor
        ) else {
            setLastError("No valid discard action is currently available.")
            return false
        }

        if actor == state.currentPlayer {
            do {
                try applyAndPublishTurnIntent(intent, successStatus: successStatus(for: intent.kind))
                return true
            } catch {
                setLastError("Discard publication failed: \(error.localizedDescription)")
                return false
            }
        }

        do {
            try sendTurnIntentEnvelope(
                intent,
                caption: "ULS INTENT submitDiscard",
                successStatus: "Discard intent sent"
            )
            return true
        } catch {
            setLastError("Discard intent failed: \(error.localizedDescription)")
            return false
        }
    }

    @discardableResult
    func publishTradeOffer(
        give: ResourceHandV1,
        receive: ResourceHandV1,
        targetPlayers: [String]
    ) -> Bool {
        guard let intent = TradeInteractionResolver.draftTradeOfferIntent(
            state: selectedState,
            actingAs: localActorIdentifier(),
            give: give,
            receive: receive,
            targetPlayers: targetPlayers
        ) else {
            setLastError("Selected trade offer is not legal.")
            return false
        }

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
        guard let intent = TradeInteractionResolver.draftMaritimeTradeIntent(
            state: selectedState,
            actingAs: localActorIdentifier(),
            give: give,
            receive: receive
        ) else {
            setLastError("Selected maritime trade is not legal.")
            return false
        }

        do {
            try applyAndPublishTurnIntent(intent, successStatus: "Published maritime trade")
            return true
        } catch {
            setLastError("Maritime trade failed: \(error.localizedDescription)")
            return false
        }
    }

    @discardableResult
    func sendAcceptTradeIntent() -> Bool {
        guard let intent = TradeInteractionResolver.draftAcceptTradeIntent(
            state: selectedState,
            actingAs: localActorIdentifier()
        ) else {
            setLastError("No legal trade accept is available.")
            return false
        }

        do {
            try sendTurnIntentEnvelope(
                intent,
                caption: "ULS TRADE RESPONSE accept",
                successStatus: "Sent trade accept"
            )
            return true
        } catch {
            setLastError("Accept trade failed: \(error.localizedDescription)")
            return false
        }
    }

    @discardableResult
    func sendDeclineTradeIntent() -> Bool {
        guard let intent = TradeInteractionResolver.draftDeclineTradeIntent(
            state: selectedState,
            actingAs: localActorIdentifier()
        ) else {
            setLastError("No legal trade decline is available.")
            return false
        }

        do {
            try sendTurnIntentEnvelope(
                intent,
                caption: "ULS TRADE RESPONSE decline",
                successStatus: "Sent trade decline"
            )
            return true
        } catch {
            setLastError("Decline trade failed: \(error.localizedDescription)")
            return false
        }
    }

    @discardableResult
    func sendCounterTradeIntent(give: ResourceHandV1, receive: ResourceHandV1) -> Bool {
        guard let intent = TradeInteractionResolver.draftCounterTradeIntent(
            state: selectedState,
            actingAs: localActorIdentifier(),
            give: give,
            receive: receive
        ) else {
            setLastError("No legal counter trade is available.")
            return false
        }

        do {
            try sendTurnIntentEnvelope(
                intent,
                caption: "ULS TRADE RESPONSE counter",
                successStatus: "Sent trade counter"
            )
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
            guard let intent = DevCardInteractionResolver.draftBuyDevCardIntent(
                state: selectedState,
                actingAs: localActorIdentifier()
            ) else {
                setLastError("Selected dev-card action is not legal.")
                return false
            }
            do {
                try applyAndPublishTurnIntent(intent, successStatus: "Published dev-card purchase")
                return true
            } catch {
                setLastError("Dev-card action failed: \(error.localizedDescription)")
                return false
            }
        case .revealVictoryPoint:
            guard let intent = DevCardInteractionResolver.draftRevealVictoryPointIntent(
                state: selectedState,
                actingAs: localActorIdentifier()
            ) else {
                setLastError("Selected dev-card action is not legal.")
                return false
            }
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
        let intent: ULS_Transport.TurnIntentV1?
        let successStatus: String

        switch draft {
        case let .knight(tileID, victimPlayer):
            guard let tileID else {
                setLastError("Knight play needs a robber tile.")
                return false
            }
            intent = DevCardInteractionResolver.draftPlayKnightIntent(
                state: selectedState,
                actingAs: localActorIdentifier(),
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
                state: selectedState,
                actingAs: localActorIdentifier(),
                resource: resource
            )
            successStatus = "Published monopoly play"
        case let .yearOfPlenty(first, second):
            guard let first, let second else {
                setLastError("Year Of Plenty needs two resources.")
                return false
            }
            intent = DevCardInteractionResolver.draftPlayYearOfPlentyIntent(
                state: selectedState,
                actingAs: localActorIdentifier(),
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
                state: selectedState,
                actingAs: localActorIdentifier(),
                firstEdgeID: firstEdgeID,
                secondEdgeID: secondEdgeID
            )
            successStatus = "Published road-building play"
        }

        guard let intent else {
            setLastError("Selected dev-card action is not legal.")
            return false
        }

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
        guard let intent = TurnInteractionResolver.draftStealVictimIntent(
            state: selectedState,
            actingAs: localActorIdentifier(),
            victimPlayer: victimPlayer
        ) else {
            setLastError("Selected robber victim is not legal.")
            return false
        }

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
            if selectedState == nil, restoreCachedPublishedStateIfAvailable(trigger: trigger) {
                return false
            }
            selectionStatus = "No message selected"
            selectedDecodeResult = selectionStatus
            if selectedState == nil {
                if diagnosticsEnabled {
                    resetDisplayedFields()
                    refreshPendingJoiners(for: nil)
                }
            }
            appendLog("Selection \(trigger.label): no message selected")
            return true
        }

        guard let encodedEnvelope = payloadValue(from: message) else {
            if selectedState == nil, restoreCachedPublishedStateIfAvailable(trigger: trigger) {
                return false
            }
            selectionStatus = "Selected message has no transport payload"
            selectedDecodeResult = selectionStatus
            if selectedState == nil {
                if diagnosticsEnabled {
                    resetDisplayedFields()
                    refreshPendingJoiners(for: nil)
                }
            }
            appendLog(
                "Selection \(trigger.label): no transport payload url=\(selectedURLPresence) payload=\(selectedPayloadQueryPresence)"
            )
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
                    refreshPendingJoiners(for: nil)
                }
            }
            setLastError("Decode failed: \(error.localizedDescription)")
            appendLog("Selection \(trigger.label): decode failed via \(encodedEnvelope.source.label)")
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
            latestKnownStatesByGameId = TranscriptStateSelection.recording(
                state,
                in: latestKnownStatesByGameId
            )
            stateSessionsByGameId[state.gameId] = message.session
            selectedJoinIntent = nil
            selectedSetupIntent = nil
            selectedTurnIntent = nil
            let transcriptActiveSource: TranscriptActiveContextSource?
            switch activeSource {
            case .selectedBubble:
                transcriptActiveSource = .selectedBubble
            case .lastSentState:
                transcriptActiveSource = .lastSentState
            case .cachedPublishedState:
                transcriptActiveSource = .cachedPublishedState
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

            if stateSelection.shouldActivate {
                setActiveContext(stateSelection.preferredState, source: .selectedBubble)
            }

            selectionStatus = stateSelection.selectionStatus

            if stateSelection.redirectedToLatestKnown {
                if stateSelection.shouldShowLatestUpdateNotice {
                    showLatestUpdateNotice("Opened latest game update.")
                }
                appendLog(
                    "Selection \(trigger.label): redirected stale rev=\(state.rev) -> latest rev=\(stateSelection.preferredState.rev)"
                )
            } else if stateSelection.shouldShowLatestUpdateNotice {
                showLatestUpdateNotice("Opened latest game update.")
            }
            appendLog("Decoded STATE rev=\(state.rev)")
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
                let contextResolution = TurnIntentContextResolver.resolve(
                    turnIntent: turnIntent,
                    selectedState: selectedState,
                    latestKnownStatesByGameId: latestKnownStatesByGameId,
                    cachedPublishedState: cachedPublishedStateForIntentContext(gameId: turnIntent.gameId)
                )
                recoverActiveContextIfNeeded(for: turnIntent, resolution: contextResolution)

                if autoApplyTurnIntentIfPossible(
                    turnIntent,
                    resolution: contextResolution,
                    source: source,
                    trigger: trigger
                ) {
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
                    refreshPendingJoiners(for: turnIntent.gameId)
                    return
                }

                selectedTurnIntent = turnIntent
                selectedSetupIntent = nil
                selectedJoinIntent = nil
                render(turnIntent: turnIntent, source: source)
                return
            }

            let intent = try decodePayload(JoinIntentV1.self, from: payload)
            if bridgeJoinIntentIfPossible(
                intent,
                source: source,
                trigger: trigger
            ) {
                return
            }
            selectedJoinIntent = intent
            selectedSetupIntent = nil
            selectedTurnIntent = nil
            render(joinIntent: intent, source: source)
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
        syncActingAs(with: state)
        refreshActiveContextMetadata()
        refreshStaleContextWarning()

        let payloadSource: TranscriptPayloadSource
        switch source {
        case .selectedBubble:
            payloadSource = .url
        case .lastSentState:
            payloadSource = .local
        case .cachedPublishedState:
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
            allowSummaryFallback: allowSummaryPayloadFallback
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

    private func refreshParticipantIdentityDebug() {
        guard diagnosticsEnabled else {
            return
        }
        let localParticipant = localParticipantIdentifier()
        let pending = currentPendingJoiners()

        localParticipantDebug = localParticipant ?? "-"
        resolvedActorDebug = debugActorIdentifier() ?? "-"
        canJoinDebug = canJoin ? "true" : "false"

        guard let state = selectedState, let localParticipant else {
            localInRosterDebug = "-"
            localPendingJoinDebug = "-"
            isInviterDebug = "-"
            return
        }

        localInRosterDebug = state.roster.contains(localParticipant) ? "true" : "false"
        localPendingJoinDebug = pending.contains(localParticipant) ? "true" : "false"
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

    private func restoreCachedPublishedStateIfAvailable(
        trigger: TranscriptSelectionTrigger
    ) -> Bool {
        guard allowsCachedPublishedStateRecovery else {
            return false
        }
        guard let cachedState = cachedPublishedState() else {
            return false
        }

        setActiveContext(cachedState, source: .cachedPublishedState)
        selectionStatus = "Restored cached STATE rev\(cachedState.rev)"
        selectedDecodeSource = TranscriptPayloadSource.localCache.label
        selectedDecodeResult = selectionStatus
        appendLog("Selection \(trigger.label): restored cached state rev=\(cachedState.rev)")
        setLastError(nil)
        return true
    }

    private func cachePublishedStateRecord(_ data: Data) {
        guard allowsCachedPublishedStateRecovery else {
            return
        }
        guard
            let cached = try? JSONDecoder().decode(CachedPublishedState.self, from: data),
            let gameId = cached.gameId,
            let state = try? decodePayload(CoreGameStateV1.self, from: cached.payload),
            state.gameId == gameId
        else {
            return
        }
        gameLedgerStore.record(state: state, payload: cached.payload)
    }

    private func cachedPublishedState() -> CoreGameStateV1? {
        guard allowsCachedPublishedStateRecovery else {
            return nil
        }
        if let lastActiveGameId = currentGameId() ?? gameLedgerStore.lastActiveGameId() {
            return gameLedgerStore.latestState(for: lastActiveGameId)
        }
        return gameLedgerStore.mostRecentState()
    }

    private func cachedPublishedStateForIntentContext(gameId: String) -> CoreGameStateV1? {
        gameLedgerStore.latestState(for: gameId)
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
                selectedTurnIntent: selectedTurnIntent,
                actionAvailability: shellActionAvailability,
                modeAvailability: shellModeAvailability
            )
        )
        refreshPendingJoiners(for: state.gameId)
    }

    private func render(joinIntent: JoinIntentV1, source: TranscriptPayloadSource) {
        rememberPendingJoiner(joinIntent.actor, for: joinIntent.gameId)
        selectionStatus = "Decoded JOIN intent via \(source.label)"
        selectedDecodeResult = selectionStatus
        updateGameplayShellProjection(GameShellProjectionBuilder.build(joinIntent: joinIntent))
        refreshPendingJoiners(for: joinIntent.gameId)
        appendLog("Decoded INTENT kind=join actor=\(shortIdentifier(joinIntent.actor))")
    }

    private func render(setupIntent: SetupPlacementIntentV1, source: TranscriptPayloadSource) {
        selectionStatus = "Decoded \(setupIntent.kind.rawValue) intent via \(source.label)"
        selectedDecodeResult = selectionStatus
        updateGameplayShellProjection(GameShellProjectionBuilder.build(setupIntent: setupIntent))
        refreshPendingJoiners(for: setupIntent.gameId)
        appendLog("Decoded INTENT kind=\(setupIntent.kind.rawValue) actor=\(shortIdentifier(setupIntent.actor))")
    }

    private func render(turnIntent decodedTurnIntent: ULS_Transport.TurnIntentV1, source: TranscriptPayloadSource) {
        selectionStatus = "Decoded \(decodedTurnIntent.kind.rawValue) intent via \(source.label)"
        selectedDecodeResult = selectionStatus
        if let selectedState, selectedState.gameId == decodedTurnIntent.gameId {
            updateGameplayShellProjection(
                GameShellProjectionBuilder.build(
                    state: selectedState,
                    actingAs: localActorIdentifier(),
                    selectedTurnIntent: decodedTurnIntent,
                    actionAvailability: shellActionAvailability,
                    modeAvailability: shellModeAvailability,
                    contextBanner: activeContextBanner,
                    contextMeta: activeContextMeta
                )
            )
        } else {
            updateGameplayShellProjection(GameShellProjectionBuilder.build(turnIntent: decodedTurnIntent))
        }
        refreshPendingJoiners(for: decodedTurnIntent.gameId)
        appendLog("Decoded INTENT kind=\(decodedTurnIntent.kind.rawValue) actor=\(shortIdentifier(decodedTurnIntent.actor))")
    }

    private func bridgeJoinIntentIfPossible(
        _ joinIntent: JoinIntentV1,
        source: TranscriptPayloadSource,
        trigger: TranscriptSelectionTrigger
    ) -> Bool {
        let resolution = TurnIntentContextResolver.resolve(
            gameId: joinIntent.gameId,
            anchorRev: joinIntent.anchorRev,
            anchorHash: joinIntent.anchorHash,
            selectedState: selectedState,
            latestKnownStatesByGameId: latestKnownStatesByGameId,
            cachedPublishedState: cachedPublishedStateForIntentContext(gameId: joinIntent.gameId)
        )

        guard
            let recovered = resolution.anchorMatched ?? resolution.bestAvailable,
            recovered.state.phase == .lobby,
            let localParticipant = localParticipantIdentifier(),
            recovered.state.roster.first == localParticipant
        else {
            return false
        }

        if shouldRecoverActiveContext(to: recovered.state) {
            setActiveContext(recovered.state, source: resolvedActiveContextSource(for: recovered.source))
        }

        rememberPendingJoiner(joinIntent.actor, for: joinIntent.gameId)
        refreshPendingJoiners(for: joinIntent.gameId)
        selectedJoinIntent = nil
        selectedSetupIntent = nil
        selectedTurnIntent = nil
        selectionStatus = "Updated lobby from join via \(source.label)"
        selectedDecodeResult = selectionStatus
        appendLog(
            "Selection \(trigger.label): bridged join actor=\(shortIdentifier(joinIntent.actor)) rev=\(recovered.state.rev) via \(source.label)"
        )
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
            TurnIntentContextResolver.shouldAutoApply(
                turnIntent,
                resolution: resolution,
                localParticipant: localParticipantIdentifier()
            ),
            let matchedContext = resolution.anchorMatched
        else {
            return false
        }

        if shouldRecoverActiveContext(to: matchedContext.state) {
            setActiveContext(matchedContext.state, source: resolvedActiveContextSource(for: matchedContext.source))
        }

        do {
            try applyAndPublishTurnIntent(turnIntent, successStatus: successStatus(for: turnIntent.kind))
            appendLog(
                "Selection \(trigger.label): auto-applied \(turnIntent.kind.rawValue) via \(source.label)"
            )
            return true
        } catch {
            appendLog(
                "Auto-apply failed kind=\(turnIntent.kind.rawValue) error=\(error.localizedDescription)"
            )
            setLastError("Automatic trade response apply failed: \(error.localizedDescription)")
            return false
        }
    }

    private func shouldPreferRecoveredState(
        for turnIntent: ULS_Transport.TurnIntentV1,
        resolution: TurnIntentContextResolution
    ) -> Bool {
        guard
            TurnIntentContextResolver.isTradeResponse(turnIntent.kind),
            let recovered = resolution.bestAvailable
        else {
            return false
        }

        return recovered.state.gameId == turnIntent.gameId
            && recovered.state.rev > turnIntent.anchorRev
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

    private func canSendNamedDevCardIntentDebug(
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
            allowSummaryFallback: allowSummaryPayloadFallback
        )
    }

    private func sendEnvelope(
        _ envelope: EnvelopeV1,
        caption: String,
        sessionPolicy: TranscriptSessionPolicy
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
            includeSummaryPayloadMirror: allowSummaryPayloadFallback
        )
        let cachedPublishedStateRecord = cachedPublishedStateRecord(from: envelope)

        appendLog(
            "Publish \(envelope.kind.rawValue) session=\(builtMessage.sessionPolicy.label) payload=\(builtMessage.payloadLength) summaryPayload=\(builtMessage.mirroredPayloadLength) url=\(builtMessage.urlString)"
        )
        appendLog("Publish summary: \(builtMessage.summaryText)")

        publish(
            builtMessage.message,
            into: conversation,
            envelopeKind: envelope.kind,
            sessionPolicy: builtMessage.sessionPolicy,
            cachedPublishedStateRecord: cachedPublishedStateRecord
        )
    }

    private func publish(
        _ message: MSMessage,
        into conversation: MSConversation,
        envelopeKind: EnvelopeV1.Kind,
        sessionPolicy: TranscriptSessionPolicy,
        cachedPublishedStateRecord: Data?
    ) {
        let envelopeKindLabel = envelopeKind.rawValue
        let sessionPolicyLabel = sessionPolicy.label
        conversation.send(message) { [weak self] error in
            Task { @MainActor in
                guard let self else { return }
                if let error {
                    self.setLastError("Publish failed: \(error.localizedDescription)")
                    self.appendLog(
                        "Error: publish failed kind=\(envelopeKindLabel) session=\(sessionPolicyLabel)"
                    )
                } else {
                    if let cachedPublishedStateRecord {
                        self.cachePublishedStateRecord(cachedPublishedStateRecord)
                        self.appendLog("Cached published STATE record")
                    }
                    self.appendLog(
                        "Published kind=\(envelopeKindLabel) session=\(sessionPolicyLabel)"
                    )
                }
            }
        }
    }

    private func cachedPublishedStateRecord(from envelope: EnvelopeV1) -> Data? {
        guard case let .state(payload) = envelope.body else {
            return nil
        }

        let state = try? decodePayload(CoreGameStateV1.self, from: payload)

        return try? JSONEncoder().encode(
            CachedPublishedState(
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
                return "INTENT actor=\(shortIdentifier(turnIntent.actor)) kind=\(turnIntent.kind.rawValue) a=r\(turnIntent.anchorRev)"
            }
            if let setupIntent = try? decodePayload(SetupPlacementIntentV1.self, from: payload) {
                return "INTENT actor=\(shortIdentifier(setupIntent.actor)) kind=\(setupIntent.kind.rawValue) a=r\(setupIntent.anchorRev)"
            }
            if let joinIntent = try? decodePayload(JoinIntentV1.self, from: payload) {
                return "INTENT actor=\(shortIdentifier(joinIntent.actor)) kind=join a=r\(joinIntent.anchorRev)"
            }
            return "INTENT"
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
        let data = Data(payload.utf8)
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            throw TransportError.invalidJSON
        }
    }

    private func jsonString<T: Encodable>(from value: T) throws -> String {
        let data = try JSONEncoder().encode(value)
        guard let jsonString = String(data: data, encoding: .utf8) else {
            throw SendError.invalidJSONPayload
        }
        return jsonString
    }

    private func localActorIdentifier() -> String? {
        ProductActorResolver.resolve(
            localParticipant: localParticipantIdentifier(),
            state: selectedState
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
            return .selectedBubble
        case .cachedPublishedState:
            return .cachedPublishedState
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

    private func refreshPendingJoiners(for gameId: String?) {
        guard diagnosticsEnabled else {
            return
        }
        guard let gameId else {
            pendingJoiners = "[]"
            refreshParticipantIdentityDebug()
            return
        }

        let joiners = currentPendingJoiners(for: gameId)
        pendingJoiners = joiners.isEmpty ? "[]" : joiners.joined(separator: ", ")
        refreshParticipantIdentityDebug()
    }

    private func currentPendingJoiners() -> [String] {
        guard let gameId = currentGameId() else {
            return []
        }
        return currentPendingJoiners(for: gameId)
    }

    private func currentPendingJoiners(for gameId: String) -> [String] {
        gameLedgerStore.observedJoiners(for: gameId)
    }

    private func rememberPendingJoiner(_ joiner: String, for gameId: String) {
        gameLedgerStore.recordJoin(actor: joiner, gameId: gameId)
    }

    private func applyAndPublishTurnIntent(
        _ turnIntent: ULS_Transport.TurnIntentV1,
        successStatus: String
    ) throws {
        guard let fromState = selectedState else {
            throw NSError(domain: "LobbyDriverViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "No active context."])
        }
        guard let actor = localActorIdentifier(), actor == fromState.currentPlayer else {
            throw NSError(domain: "LobbyDriverViewModel", code: 2, userInfo: [NSLocalizedDescriptionKey: "Only current player can publish canonical STATE."])
        }
        guard
            turnIntent.gameId == fromState.gameId,
            turnIntent.anchorRev == fromState.rev,
            turnIntent.anchorHash == fromState.stateHash
        else {
            throw NSError(domain: "LobbyDriverViewModel", code: 3, userInfo: [NSLocalizedDescriptionKey: "Turn intent anchor does not match Active Context."])
        }

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

    private func sendTurnIntentEnvelope(
        _ turnIntent: ULS_Transport.TurnIntentV1,
        caption: String,
        successStatus: String
    ) throws {
        let payload = try jsonString(from: turnIntent)
        let envelope = EnvelopeV1(kind: .intent, body: .intent(payload: payload))
        try sendEnvelope(envelope, caption: caption, sessionPolicy: .new)
        selectionStatus = successStatus
        setLastError(nil)
    }

    private func immediateTurnIntent(for actionKind: GameActionDockItem.Kind) -> ULS_Transport.TurnIntentV1? {
        guard
            let state = selectedState,
            state.phase == .turn,
            let actor = localActorIdentifier(),
            actor == state.currentPlayer
        else {
            return nil
        }

        switch actionKind {
        case .roll:
            guard canSendRollDiceIntentDebug else {
                return nil
            }
            return ULS_Transport.TurnIntentV1(
                kind: .rollDice,
                gameId: state.gameId,
                anchorRev: state.rev,
                anchorHash: state.stateHash,
                actor: actor
            )
        case .endTurn:
            guard canSendEndTurnIntentDebug else {
                return nil
            }
            return ULS_Transport.TurnIntentV1(
                kind: .endTurn,
                gameId: state.gameId,
                anchorRev: state.rev,
                anchorHash: state.stateHash,
                actor: actor
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
            return MSSession()
        case let .state(gameId):
            if let existing = stateSessionsByGameId[gameId] {
                return existing
            }

            let newSession = MSSession()
            stateSessionsByGameId[gameId] = newSession
            return newSession
        }
    }

    private enum ActiveContextSource {
        case selectedBubble
        case lastSentState
        case cachedPublishedState

        var label: String {
            switch self {
            case .selectedBubble:
                return "selectedBubble"
            case .lastSentState:
                return "lastSentState"
            case .cachedPublishedState:
                return "cachedPublishedState"
            }
        }
    }

    private struct CachedPublishedState: Codable {
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

    private enum SendError: LocalizedError {
        case noActiveConversation
        case invalidJSONPayload
        case invalidIntentPayload

        var errorDescription: String? {
            switch self {
            case .noActiveConversation:
                return "No active conversation."
            case .invalidJSONPayload:
                return "Could not create JSON payload string."
            case .invalidIntentPayload:
                return "Intent payload is missing required fields."
            }
        }
    }
}
