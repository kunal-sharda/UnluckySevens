import Combine
import Foundation
import Messages
import ULS_CoreGame
import ULS_Transport

@MainActor
final class LobbyDriverViewModel: ObservableObject {
    @Published var kind: String = "-"
    @Published var gameId: String = "-"
    @Published var rev: String = "-"
    @Published var prevHash: String = "-"
    @Published var stateHash: String = "-"
    @Published var roster: String = "-"
    @Published var currentPlayer: String = "-"
    @Published var phase: String = "-"
    @Published var seed: String = "-"
    @Published var diceRngState: String = "-"
    @Published var turnStep: String = "-"
    @Published var lastRoll: String = "-"
    @Published var pendingDiscardRequirements: String = "-"
    @Published var submittedDiscardsStatus: String = "-"
    @Published var robberMoveReadiness: String = "-"
    @Published var eligibleStealVictims: String = "-"
    @Published var remainingPieces: String = "-"
    @Published var activeTradeOffer: String = "-"
    @Published var pendingTradeAccepts: String = "-"
    @Published var maritimeTradePreview: String = "-"
    @Published var largestArmyStatus: String = "-"
    @Published var longestRoadStatus: String = "-"
    @Published var victoryPointsSummary: String = "-"
    @Published var gameOverSummary: String = "-"
    @Published var lastTurnRecapSummary: String = "-"
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
    @Published var boardHash: String = "-"
    @Published var boardGenerator: String = "-"
    @Published var boardRobberTile: String = "-"
    @Published var boardResourcesByTile: String = "-"
    @Published var boardNumbersByTile: String = "-"
    @Published var boardPortsByIndex: String = "-"
    @Published var visibleHands: String = "-"
    @Published var bankResources: String = "-"
    @Published var devDeckRemaining: String = "-"
    @Published var visibleDevCards: String = "-"
    @Published var setupPlacement: String = "-"
    @Published var turnIntent: String = "-"

    private let summaryPayloadPrefix = "ulsenv:"
    private let boardStrategyKey = "uls.boardStrategy"
    private let lastPublishedStateKey = "uls.lastPublishedState"
    private let lastPublishedStateMaxAge: TimeInterval = 600
    private let userDefaults: UserDefaults
    private let diagnosticsEnabled = false
    private let allowsRuntimeDebugControls = false
    private let allowsCachedPublishedStateRecovery = false
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
    private var cachedGameScreenModelKey: GameScreenModelCacheKey?
    private var cachedGameScreenModelValue: GameScreenModel?

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        if let rawValue = userDefaults.string(forKey: boardStrategyKey),
           let parsed = BoardGenStrategyV1(rawValue: rawValue) {
            boardStrategy = parsed
        } else {
            boardStrategy = .randomV1
        }
    }

    private var allowSummaryPayloadFallback: Bool {
        #if DEBUG
        true
        #else
        false
        #endif
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
        let context = GameScreenContext(
            selectedState: selectedState,
            actingAs: localActorIdentifier(),
            contextBanner: activeContextBanner,
            contextMeta: activeContextMeta,
            actionAvailability: shellActionAvailability,
            modeAvailability: shellModeAvailability
        )
        let key = GameScreenModelCacheKey(
            gameId: context.selectedState?.gameId,
            stateHash: context.selectedState?.stateHash,
            actor: context.actingAs,
            contextBanner: context.contextBanner,
            contextMeta: context.contextMeta,
            actionAvailability: context.actionAvailability,
            modeAvailability: context.modeAvailability
        )

        if let cachedGameScreenModelKey, cachedGameScreenModelKey == key, let cachedGameScreenModelValue {
            return cachedGameScreenModelValue
        }

        let model = GameScreenModelBuilder.build(context: context)
        cachedGameScreenModelKey = key
        cachedGameScreenModelValue = model
        return model
    }

    var setupGuidanceText: String? {
        SetupInteractionResolver.guidanceText(
            state: selectedState,
            actingAs: localActorIdentifier()
        )
    }

    var discardPanelModel: GameDiscardPanelModel? {
        GameDiscardPanelModelBuilder.build(
            state: selectedState,
            actingAs: localActorIdentifier(),
            selectedTurnIntent: selectedTurnIntent
        )
    }

    var robberVictimOptions: [GameRobberVictimOption] {
        GameRobberVictimOptionBuilder.build(
            state: selectedState,
            actingAs: localActorIdentifier()
        )
    }

    var tradePanelModel: GameTradePanelModel? {
        GameTradePanelModelBuilder.build(
            state: selectedState,
            actingAs: localActorIdentifier(),
            selectedTurnIntent: selectedTurnIntent
        )
    }

    func makeBoardOverlayModel(
        mode: GameMode,
        devCardDraft: GameDevCardDraft? = nil,
        selectedTarget: GameBoardTarget?
    ) -> GameBoardOverlayModel {
        GameBoardOverlayModelBuilder.build(
            state: selectedState,
            actingAs: localActorIdentifier(),
            mode: mode,
            devCardDraft: devCardDraft,
            selectedTarget: selectedTarget
        )
    }

    func makeDevCardPanelModel(
        mode: GameMode,
        draft: GameDevCardDraft?
    ) -> GameDevCardPanelModel? {
        GameDevCardPanelModelBuilder.build(
            state: selectedState,
            actingAs: localActorIdentifier(),
            mode: mode,
            draft: draft
        )
    }

    func makeBankTrayModel(
        mode: GameMode,
        draft: GameDevCardDraft?
    ) -> GameBankTrayModel {
        GameBankTrayModelBuilder.build(
            state: selectedState,
            actingAs: localActorIdentifier(),
            mode: mode,
            draft: draft
        )
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
            canTrade: canSendProposeTradeIntentDebug || canSendAcceptTradeIntentDebug || canSendExecuteTradeIntentDebug || canSendMaritimeTradeIntentDebug,
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
            canTrade: canSendProposeTradeIntentDebug
                || canSendAcceptTradeIntentDebug
                || canSendExecuteTradeIntentDebug
                || canSendMaritimeTradeIntentDebug,
            canPlayDevCard: shellActionAvailability.canPlayDevCards,
            canDiscard: state.phase == .turn && state.turnState?.step == .pendingDiscards
        )
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
            state.activeTradeOffer != nil,
            let actor = localActorIdentifier()
        else {
            return false
        }
        return actor != state.currentPlayer
    }

    var canSendExecuteTradeIntentDebug: Bool {
        guard
            let state = selectedState,
            state.phase == .turn,
            state.turnState?.step == .afterRoll,
            state.activeTradeOffer != nil,
            !state.pendingTradeAccepts.isEmpty,
            let actor = localActorIdentifier()
        else {
            return false
        }
        return actor == state.currentPlayer
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
        userDefaults.removeObject(forKey: lastPublishedStateKey)
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

        var joiners = loadPendingJoiners(for: intent.gameId)
        if !joiners.contains(intent.actor) {
            joiners.append(intent.actor)
            savePendingJoiners(joiners, for: intent.gameId)
        }

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
            pendingJoiners: loadPendingJoiners(for: fromState.gameId)
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
            userDefaults.removeObject(forKey: pendingJoinersKey(for: toState.gameId))
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

        userDefaults.removeObject(forKey: pendingJoinersKey(for: gameId))
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

        let intent = ULS_Transport.TurnIntentV1(
            proposeTradeGive: proposal.give,
            receive: proposal.receive,
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
        guard let acceptPlayer = state.pendingTradeAccepts
            .sorted(by: { $0.acceptingPlayer < $1.acceptingPlayer })
            .first?.acceptingPlayer
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
    func handleTradeAction(_ action: GameTradeActionKind) -> Bool {
        switch action {
        case .publishSuggestedOffer:
            guard let intent = TradeInteractionResolver.draftSuggestedTradeOfferIntent(
                state: selectedState,
                actingAs: localActorIdentifier()
            ) else {
                setLastError("No legal suggested player trade is available.")
                return false
            }
            do {
                try applyAndPublishTurnIntent(intent, successStatus: "Published trade offer")
                return true
            } catch {
                setLastError("Trade offer failed: \(error.localizedDescription)")
                return false
            }
        case .publishSuggestedMaritime:
            guard let intent = TradeInteractionResolver.draftSuggestedMaritimeTradeIntent(
                state: selectedState,
                actingAs: localActorIdentifier()
            ) else {
                setLastError("No legal maritime trade is available.")
                return false
            }
            do {
                try applyAndPublishTurnIntent(intent, successStatus: "Published maritime trade")
                return true
            } catch {
                setLastError("Maritime trade failed: \(error.localizedDescription)")
                return false
            }
        case .sendAcceptOffer:
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
                    caption: "ULS INTENT acceptTrade",
                    successStatus: "Accept trade intent sent"
                )
                return true
            } catch {
                setLastError("Accept trade failed: \(error.localizedDescription)")
                return false
            }
        case .applySelectedAccept:
            return publishSelectedTurnIntentState()
        }
    }

    @discardableResult
    func publishTradeExecution(acceptingPlayer: String) -> Bool {
        guard let intent = TradeInteractionResolver.draftExecuteTradeIntent(
            state: selectedState,
            actingAs: localActorIdentifier(),
            acceptingPlayer: acceptingPlayer
        ) else {
            setLastError("Selected trade execution is not legal.")
            return false
        }

        do {
            try applyAndPublishTurnIntent(intent, successStatus: "Published trade execution")
            return true
        } catch {
            setLastError("Trade execution failed: \(error.localizedDescription)")
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
                selectedTurnIntent = turnIntent
                selectedSetupIntent = nil
                selectedJoinIntent = nil
                render(turnIntent: turnIntent, source: source)
                return
            }

            let intent = try decodePayload(JoinIntentV1.self, from: payload)
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
        if uiLog.count > 20 {
            uiLog.removeFirst(uiLog.count - 20)
        }
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
        userDefaults.set(data, forKey: lastPublishedStateKey)
    }

    private func cachedPublishedState() -> CoreGameStateV1? {
        guard allowsCachedPublishedStateRecovery else {
            return nil
        }
        guard
            let data = userDefaults.data(forKey: lastPublishedStateKey),
            let cached = try? JSONDecoder().decode(CachedPublishedState.self, from: data)
        else {
            return nil
        }

        guard Date().timeIntervalSince1970 - cached.savedAt <= lastPublishedStateMaxAge else {
            userDefaults.removeObject(forKey: lastPublishedStateKey)
            return nil
        }

        guard let state = try? decodePayload(CoreGameStateV1.self, from: cached.payload) else {
            userDefaults.removeObject(forKey: lastPublishedStateKey)
            return nil
        }

        return state
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

    private func shortIdentifier(_ value: String) -> String {
        String(value.prefix(8))
    }

    private func render(state: CoreGameStateV1, source: TranscriptPayloadSource) {
        selectionStatus = "Decoded STATE rev\(state.rev) via \(source.label)"
        selectedDecodeResult = selectionStatus
        guard diagnosticsEnabled else {
            return
        }

        kind = "STATE"
        gameId = state.gameId
        rev = String(state.rev)
        prevHash = state.prevHash ?? "nil"
        stateHash = state.stateHash
        roster = state.roster.joined(separator: ", ")
        currentPlayer = state.currentPlayer
        phase = state.phase.rawValue
        seed = state.seed.map(String.init) ?? "nil"
        diceRngState = state.diceRngState.map(String.init) ?? "nil"
        turnStep = state.turnState?.step.rawValue ?? "nil"
        if let lastRollValue = state.turnState?.lastRoll {
            lastRoll = "\(lastRollValue.d1)+\(lastRollValue.d2)"
        } else {
            lastRoll = "nil"
        }
        pendingDiscardRequirements = discardRequirementsSummary(for: state.turnState)
        submittedDiscardsStatus = discardSubmissionSummary(for: state.turnState)
        robberMoveReadiness = robberReadinessSummary(for: state.turnState)
        eligibleStealVictims = stealVictimsSummary(for: state.turnState)
        remainingPieces = remainingPiecesSummary(for: state)
        activeTradeOffer = activeTradeOfferSummary(for: state)
        pendingTradeAccepts = pendingTradeAcceptsSummary(for: state)
        maritimeTradePreview = maritimeTradeSummary(for: state)
        largestArmyStatus = largestArmySummary(for: state)
        longestRoadStatus = longestRoadSummary(for: state)
        victoryPointsSummary = vpSummary(for: state)
        gameOverSummary = gameOverStateSummary(for: state)
        lastTurnRecapSummary = recapSummary(for: state)
        setupPlacement = "-"
        turnIntent = "-"
        visibleHands = visibleHandsSummary(for: state)
        bankResources = resourceHandDescription(state.bankResources)
        devDeckRemaining = String(state.devDeck.count)
        visibleDevCards = visibleDevCardsSummary(for: state)
        render(board: state.board)
        refreshPendingJoiners(for: state.gameId)
    }

    private func render(joinIntent: JoinIntentV1, source: TranscriptPayloadSource) {
        rememberPendingJoiner(joinIntent.actor, for: joinIntent.gameId)
        selectionStatus = "Decoded JOIN intent via \(source.label)"
        selectedDecodeResult = selectionStatus
        guard diagnosticsEnabled else {
            return
        }

        kind = "INTENT(join)"
        gameId = joinIntent.gameId
        rev = String(joinIntent.anchorRev)
        prevHash = "-"
        stateHash = joinIntent.anchorHash
        roster = "-"
        currentPlayer = joinIntent.actor
        phase = "-"
        seed = "-"
        diceRngState = "-"
        turnStep = "-"
        lastRoll = "-"
        pendingDiscardRequirements = "-"
        submittedDiscardsStatus = "-"
        robberMoveReadiness = "-"
        eligibleStealVictims = "-"
        remainingPieces = "-"
        activeTradeOffer = "-"
        pendingTradeAccepts = "-"
        maritimeTradePreview = "-"
        largestArmyStatus = "-"
        longestRoadStatus = "-"
        victoryPointsSummary = "-"
        gameOverSummary = "-"
        lastTurnRecapSummary = "-"
        setupPlacement = "-"
        turnIntent = "-"
        visibleHands = "-"
        bankResources = "-"
        devDeckRemaining = "-"
        visibleDevCards = "-"
        resetBoardDebugFields()
        refreshPendingJoiners(for: joinIntent.gameId)
        appendLog("Decoded INTENT kind=join actor=\(shortIdentifier(joinIntent.actor))")
    }

    private func render(setupIntent: SetupPlacementIntentV1, source: TranscriptPayloadSource) {
        selectionStatus = "Decoded \(setupIntent.kind.rawValue) intent via \(source.label)"
        selectedDecodeResult = selectionStatus
        guard diagnosticsEnabled else {
            return
        }

        kind = "INTENT(\(setupIntent.kind.rawValue))"
        gameId = setupIntent.gameId
        rev = String(setupIntent.anchorRev)
        prevHash = "-"
        stateHash = setupIntent.anchorHash
        roster = "-"
        currentPlayer = setupIntent.actor
        phase = "-"
        seed = "-"
        diceRngState = "-"
        turnStep = "-"
        lastRoll = "-"
        pendingDiscardRequirements = "-"
        submittedDiscardsStatus = "-"
        robberMoveReadiness = "-"
        eligibleStealVictims = "-"
        remainingPieces = "-"
        activeTradeOffer = "-"
        pendingTradeAccepts = "-"
        maritimeTradePreview = "-"
        largestArmyStatus = "-"
        longestRoadStatus = "-"
        victoryPointsSummary = "-"
        gameOverSummary = "-"
        lastTurnRecapSummary = "-"
        turnIntent = "-"
        visibleHands = "-"
        bankResources = "-"
        devDeckRemaining = "-"
        visibleDevCards = "-"
        switch setupIntent.kind {
        case .placeSetupSettlement:
            setupPlacement = "node: \(setupIntent.node.map(String.init) ?? "-")"
        case .placeSetupRoad:
            setupPlacement = "edge: \(setupIntent.edge.map(String.init) ?? "-")"
        case .placeSetupPair:
            let node = setupIntent.node.map(String.init) ?? "-"
            let edge = setupIntent.edge.map(String.init) ?? "-"
            setupPlacement = "node: \(node), edge: \(edge)"
        }
        resetBoardDebugFields()
        refreshPendingJoiners(for: setupIntent.gameId)
        appendLog("Decoded INTENT kind=\(setupIntent.kind.rawValue) actor=\(shortIdentifier(setupIntent.actor))")
    }

    private func render(turnIntent decodedTurnIntent: ULS_Transport.TurnIntentV1, source: TranscriptPayloadSource) {
        selectionStatus = "Decoded \(decodedTurnIntent.kind.rawValue) intent via \(source.label)"
        selectedDecodeResult = selectionStatus
        guard diagnosticsEnabled else {
            return
        }

        kind = "INTENT(\(decodedTurnIntent.kind.rawValue))"
        gameId = decodedTurnIntent.gameId
        rev = String(decodedTurnIntent.anchorRev)
        prevHash = "-"
        stateHash = decodedTurnIntent.anchorHash
        roster = "-"
        currentPlayer = decodedTurnIntent.actor
        phase = "-"
        seed = "-"
        diceRngState = "-"
        turnStep = "-"
        lastRoll = "-"
        pendingDiscardRequirements = "-"
        submittedDiscardsStatus = "-"
        robberMoveReadiness = "-"
        eligibleStealVictims = "-"
        remainingPieces = "-"
        activeTradeOffer = "-"
        pendingTradeAccepts = "-"
        maritimeTradePreview = "-"
        largestArmyStatus = "-"
        longestRoadStatus = "-"
        victoryPointsSummary = "-"
        gameOverSummary = "-"
        lastTurnRecapSummary = "-"
        setupPlacement = "-"
        switch decodedTurnIntent.kind {
        case .rollDice, .endTurn:
            turnIntent = "kind: \(decodedTurnIntent.kind.rawValue)"
        case .submitDiscard:
            let player = decodedTurnIntent.discardPlayer ?? "-"
            let hand = decodedTurnIntent.discarded.map(resourceHandDescription) ?? "-"
            turnIntent = "kind: submitDiscard player: \(player) hand: \(hand)"
        case .moveRobber:
            let tile = decodedTurnIntent.robberTileID.map(String.init) ?? "-"
            turnIntent = "kind: moveRobber tile: \(tile)"
        case .selectStealVictim:
            let victim = decodedTurnIntent.stealVictimPlayer ?? "-"
            turnIntent = "kind: selectStealVictim victim: \(victim)"
        case .buildRoad:
            let edge = decodedTurnIntent.buildEdgeID.map(String.init) ?? "-"
            turnIntent = "kind: buildRoad edge: \(edge)"
        case .buildSettlement:
            let node = decodedTurnIntent.buildNodeID.map(String.init) ?? "-"
            turnIntent = "kind: buildSettlement node: \(node)"
        case .buildCity:
            let node = decodedTurnIntent.buildNodeID.map(String.init) ?? "-"
            turnIntent = "kind: buildCity node: \(node)"
        case .proposeTrade:
            let give = decodedTurnIntent.tradeGive.map(resourceHandDescription) ?? "-"
            let receive = decodedTurnIntent.tradeReceive.map(resourceHandDescription) ?? "-"
            turnIntent = "kind: proposeTrade give: \(give) receive: \(receive)"
        case .acceptTrade:
            let player = decodedTurnIntent.tradeAcceptPlayer ?? "-"
            let offer = decodedTurnIntent.tradeOfferHash ?? "-"
            turnIntent = "kind: acceptTrade player: \(player) offer: \(offer)"
        case .executeTrade:
            let player = decodedTurnIntent.tradeAcceptPlayer ?? "-"
            let offer = decodedTurnIntent.tradeOfferHash ?? "-"
            turnIntent = "kind: executeTrade player: \(player) offer: \(offer)"
        case .maritimeTrade:
            let give = decodedTurnIntent.tradeGive.map(resourceHandDescription) ?? "-"
            let receive = decodedTurnIntent.tradeReceive.map(resourceHandDescription) ?? "-"
            turnIntent = "kind: maritimeTrade give: \(give) receive: \(receive)"
        case .buyDevCard:
            turnIntent = "kind: buyDevCard"
        case .playDevCard:
            let playKind = decodedTurnIntent.devCardPlayKind?.rawValue ?? "-"
            switch decodedTurnIntent.devCardPlayKind {
            case .knight:
                let tile = decodedTurnIntent.devCardTileID.map(String.init) ?? "-"
                let victim = decodedTurnIntent.devCardVictimPlayer ?? "none"
                turnIntent = "kind: playDevCard card: \(playKind) tile: \(tile) victim: \(victim)"
            case .monopoly:
                let resource = decodedTurnIntent.devCardResource?.rawValue ?? "-"
                turnIntent = "kind: playDevCard card: \(playKind) resource: \(resource)"
            case .yearOfPlenty:
                let first = decodedTurnIntent.devCardFirstResource?.rawValue ?? "-"
                let second = decodedTurnIntent.devCardSecondResource?.rawValue ?? "-"
                turnIntent = "kind: playDevCard card: \(playKind) first: \(first) second: \(second)"
            case .roadBuilding:
                let first = decodedTurnIntent.devCardFirstEdgeID.map(String.init) ?? "-"
                let second = decodedTurnIntent.devCardSecondEdgeID.map(String.init) ?? "-"
                turnIntent = "kind: playDevCard card: \(playKind) firstEdge: \(first) secondEdge: \(second)"
            case .revealVictoryPoint:
                turnIntent = "kind: playDevCard card: \(playKind)"
            case .none:
                turnIntent = "kind: playDevCard card: -"
            }
        }
        visibleHands = "-"
        bankResources = "-"
        devDeckRemaining = "-"
        visibleDevCards = "-"
        resetBoardDebugFields()
        refreshPendingJoiners(for: decodedTurnIntent.gameId)
        appendLog("Decoded INTENT kind=\(decodedTurnIntent.kind.rawValue) actor=\(shortIdentifier(decodedTurnIntent.actor))")
    }

    private func render(board: BoardSetupV1?) {
        guard let board else {
            resetBoardDebugFields()
            return
        }

        boardHash = board.boardHash
        boardGenerator = board.generator.rawValue
        boardRobberTile = String(board.robberTile)
        boardResourcesByTile = board.resourcesByTile.enumerated()
            .map { "\($0.offset): \($0.element.rawValue)" }
            .joined(separator: ", ")
        boardNumbersByTile = board.numbersByTile.enumerated()
            .map { "\($0.offset): \($0.element.map(String.init) ?? "nil")" }
            .joined(separator: ", ")
        boardPortsByIndex = board.portsByIndex.enumerated()
            .map { "\($0.offset): \(portKindDescription($0.element))" }
            .joined(separator: ", ")
    }

    private func resetDisplayedFields() {
        guard diagnosticsEnabled else {
            return
        }
        kind = "-"
        gameId = "-"
        rev = "-"
        prevHash = "-"
        stateHash = "-"
        roster = "-"
        currentPlayer = "-"
        phase = "-"
        seed = "-"
        diceRngState = "-"
        turnStep = "-"
        lastRoll = "-"
        pendingDiscardRequirements = "-"
        submittedDiscardsStatus = "-"
        robberMoveReadiness = "-"
        eligibleStealVictims = "-"
        remainingPieces = "-"
        activeTradeOffer = "-"
        pendingTradeAccepts = "-"
        maritimeTradePreview = "-"
        largestArmyStatus = "-"
        longestRoadStatus = "-"
        victoryPointsSummary = "-"
        gameOverSummary = "-"
        lastTurnRecapSummary = "-"
        setupPlacement = "-"
        turnIntent = "-"
        visibleHands = "-"
        bankResources = "-"
        devDeckRemaining = "-"
        visibleDevCards = "-"
        resetBoardDebugFields()
    }

    private func resetBoardDebugFields() {
        guard diagnosticsEnabled else {
            return
        }
        boardHash = "-"
        boardGenerator = "-"
        boardRobberTile = "-"
        boardResourcesByTile = "-"
        boardNumbersByTile = "-"
        boardPortsByIndex = "-"
    }

    private func portKindDescription(_ kind: PortKindV1) -> String {
        switch kind {
        case .threeToOne:
            return "3:1"
        case let .twoToOne(resource):
            return "2:1 \(resource.rawValue)"
        }
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

    private func pendingTradeAcceptsSummary(for state: CoreGameStateV1) -> String {
        if state.pendingTradeAccepts.isEmpty {
            return "none"
        }
        return state.pendingTradeAccepts
            .sorted { $0.acceptingPlayer < $1.acceptingPlayer }
            .map(\.acceptingPlayer)
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

        return try? JSONEncoder().encode(
            CachedPublishedState(payload: payload, savedAt: Date().timeIntervalSince1970)
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
            guard let give = intent.tradeGive, let receive = intent.tradeReceive else {
                throw SendError.invalidIntentPayload
            }
            return .proposeTrade(give: resourceHand(from: give), receive: resourceHand(from: receive))
        case .acceptTrade:
            guard let acceptingPlayer = intent.tradeAcceptPlayer, let offerHash = intent.tradeOfferHash else {
                throw SendError.invalidIntentPayload
            }
            return .acceptTrade(acceptingPlayer: acceptingPlayer, offerHash: offerHash)
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

        let joiners = loadPendingJoiners(for: gameId)
        pendingJoiners = joiners.isEmpty ? "[]" : joiners.joined(separator: ", ")
        refreshParticipantIdentityDebug()
    }

    private func loadPendingJoiners(for gameId: String) -> [String] {
        userDefaults.stringArray(forKey: pendingJoinersKey(for: gameId)) ?? []
    }

    private func currentPendingJoiners() -> [String] {
        guard let gameId = currentGameId() else {
            return []
        }
        return loadPendingJoiners(for: gameId)
    }

    private func rememberPendingJoiner(_ joiner: String, for gameId: String) {
        var joiners = loadPendingJoiners(for: gameId)
        guard !joiners.contains(joiner) else {
            return
        }
        joiners.append(joiner)
        savePendingJoiners(joiners, for: gameId)
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

    private func savePendingJoiners(_ joiners: [String], for gameId: String) {
        userDefaults.set(joiners, forKey: pendingJoinersKey(for: gameId))
    }

    private func pendingJoinersKey(for gameId: String) -> String {
        "uls.pendingJoiners.\(gameId)"
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
        let payload: String
        let savedAt: TimeInterval
    }

    private struct GameScreenModelCacheKey: Equatable {
        let gameId: String?
        let stateHash: String?
        let actor: String?
        let contextBanner: String
        let contextMeta: String
        let actionAvailability: GameActionAvailability
        let modeAvailability: GameModeAvailability
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
