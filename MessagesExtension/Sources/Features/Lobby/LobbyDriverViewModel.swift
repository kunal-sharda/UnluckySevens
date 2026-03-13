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
    @Published var lastError: String = "-"
    @Published var actingAs: String = "-"
    @Published var useSingleSessionDebug: Bool = false
    @Published var activeContextSource: String = "-"
    @Published var activeContextUpdatedAgo: String = "-"
    @Published var staleContextWarning: String = "-"
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
    private let userDefaults: UserDefaults

    private weak var activeConversation: MSConversation?
    private var selectedState: CoreGameStateV1?
    private var selectedJoinIntent: JoinIntentV1?
    private var selectedSetupIntent: SetupPlacementIntentV1?
    private var selectedTurnIntent: ULS_Transport.TurnIntentV1?
    private var latestSelectedState: CoreGameStateV1?
    private var activeUpdatedAt: Date?
    private var activeSource: ActiveContextSource?
    private var stateSessionsByGameId: [String: MSSession] = [:]

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        if let rawValue = userDefaults.string(forKey: boardStrategyKey),
           let parsed = BoardGenStrategyV1(rawValue: rawValue) {
            boardStrategy = parsed
        } else {
            boardStrategy = .randomV1
        }
    }

    var canInvite: Bool {
        activeConversation != nil
    }

    var rootRoute: MessagesRootRoute {
        MessagesRootRoute.resolve(phase: selectedState?.phase)
    }

    var gameScreenModel: GameScreenModel {
        GameScreenModelBuilder.build(
            context: GameScreenContext(
                selectedState: selectedState,
                actingAs: localActorIdentifier(),
                contextBanner: activeContextBanner,
                contextMeta: activeContextMeta,
                actionAvailability: shellActionAvailability,
                modeAvailability: shellModeAvailability
            )
        )
    }

    private var shellActionAvailability: GameActionAvailability {
        GameActionAvailability(
            canRoll: canSendRollDiceIntentDebug,
            canBuild: canSendBuildRoadIntentDebug || canSendBuildSettlementIntentDebug || canSendBuildCityIntentDebug,
            canTrade: canSendProposeTradeIntentDebug || canSendAcceptTradeIntentDebug || canSendExecuteTradeIntentDebug || canSendMaritimeTradeIntentDebug,
            canUseDevCards: canSendBuyDevCardIntentDebug
                || canSendPlayKnightIntentDebug
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
            canPlayDevCard: shellActionAvailability.canUseDevCards,
            canDiscard: canSendSubmitDiscardIntentDebug
        )
    }

    var actingAsOptions: [String] {
        selectedState?.roster ?? []
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
        let age = activeContextUpdatedAgo == "-" ? "0s ago" : activeContextUpdatedAgo
        return "Source: \(source), updated \(age)"
    }

    var canJoin: Bool {
        selectedState?.phase == .lobby
    }

    var canRecordJoin: Bool {
        selectedJoinIntent != nil
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
        guard let state = selectedState, state.phase == .turn else {
            return false
        }
        return state.turnState?.step == .needsRoll && localActorIdentifier() != nil
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
        guard let state = selectedState, state.phase == .turn else {
            return false
        }
        return state.turnState?.step == .needsRobberMove && state.board != nil && localActorIdentifier() != nil
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
            state.turnState?.step == .afterRoll,
            let actor = localActorIdentifier(),
            actor == state.currentPlayer
        else {
            return false
        }
        return state.board != nil && (state.devCardsByPlayer[actor] ?? .zero).knight > 0
    }

    var canSendPlayMonopolyIntentDebug: Bool {
        canSendNamedDevCardIntentDebug { $0.monopoly > 0 }
    }

    var canSendPlayYearOfPlentyIntentDebug: Bool {
        canSendNamedDevCardIntentDebug { $0.yearOfPlenty > 0 }
    }

    var canSendPlayRoadBuildingIntentDebug: Bool {
        guard canSendNamedDevCardIntentDebug({ $0.roadBuilding > 0 }),
              let state = selectedState,
              let actor = localActorIdentifier()
        else {
            return false
        }
        return defaultRoadBuildingEdges(for: actor, in: state) != nil
    }

    var canSendRevealVictoryPointIntentDebug: Bool {
        guard
            let state = selectedState,
            state.phase == .turn,
            state.turnState?.step == .afterRoll,
            let actor = localActorIdentifier(),
            actor == state.currentPlayer
        else {
            return false
        }
        let playable = state.devCardsByPlayer[actor] ?? .zero
        let newlyBought = state.newDevCardsByPlayer[actor] ?? .zero
        return playable.victoryPoint > 0 || newlyBought.victoryPoint > 0
    }

    var canSendEndTurnIntentDebug: Bool {
        guard let state = selectedState, state.phase == .turn else {
            return false
        }
        return state.turnState?.step == .afterRoll && localActorIdentifier() != nil
    }

    var canStartGame: Bool {
        guard
            let state = selectedState,
            state.phase == .lobby,
            state.rev == 0,
            let inviter = state.roster.first,
            inviter == localActorIdentifier()
        else {
            return false
        }

        return true
    }

    var canClearPendingJoins: Bool {
        currentGameId() != nil
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
            return "No Active Context — tap a STATE bubble or press Reload."
        }
        guard let actor = localActorIdentifier() else {
            return "Choose Acting As from roster."
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
        actingAs = actor
    }

    func setUseSingleSessionDebug(_ enabled: Bool) {
        useSingleSessionDebug = enabled
    }

    func updateContext(conversation: MSConversation?, selectedMessage: MSMessage?) {
        activeConversation = conversation
        refreshActiveContextMetadata()
        decodeSelectedMessage(selectedMessage, activationMode: .activateIfMissing)
    }

    func reloadSelectedBubble() {
        decodeSelectedMessage(activeConversation?.selectedMessage, activationMode: .force)
    }

    func clearActiveContext() {
        selectedState = nil
        activeSource = nil
        activeUpdatedAt = nil
        activeContextSource = "-"
        activeContextUpdatedAgo = "-"
        staleContextWarning = "-"
        if selectedTurnIntent == nil, selectedSetupIntent == nil, selectedJoinIntent == nil {
            resetDisplayedFields()
        }
        selectionStatus = "Active context cleared"
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

        guard let actor = localActorIdentifier() else {
            setLastError("Missing local participant identifier.")
            return
        }

        let intent = JoinIntentV1(
            gameId: state.gameId,
            anchorRev: state.rev,
            anchorHash: state.stateHash,
            actor: actor
        )

        do {
            let payload = try jsonString(from: intent)
            let envelope = EnvelopeV1(kind: .intent, body: .intent(payload: payload))
            try sendEnvelope(envelope, caption: "ULS INTENT join", sessionPolicy: .new)
            selectionStatus = "Join intent sent"
            appendLog("Sent INTENT kind=join actor=\(shortIdentifier(actor)) anchorRev=\(state.rev)")
            setLastError(nil)
        } catch {
            setLastError("Join failed: \(error.localizedDescription)")
        }
    }

    func recordJoin() {
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

        guard inviter == localActorIdentifier() else {
            setLastError("Only the inviter can start the game.")
            return
        }

        let pending = loadPendingJoiners(for: fromState.gameId)
        var finalRoster: [String] = [inviter]
        for joiner in pending where joiner != inviter {
            if !finalRoster.contains(joiner) {
                finalRoster.append(joiner)
            }
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
            setActiveContext(toState, source: .lastSentState)
            selectionStatus = "Start sent: setup rev1"
            setLastError(nil)
        } catch {
            setLastError("Start failed: \(error.localizedDescription)")
        }
    }

    func clearPendingJoins() {
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
            setLastError("No Active Context — tap a STATE bubble or press Reload.")
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
            setActiveContext(toState, source: .lastSentState)
            selectionStatus = "Applied setup intent into STATE rev\(toState.rev)"
            setLastError(nil)
        } catch {
            setLastError("Apply setup intent failed: \(error.localizedDescription)")
        }
    }

    func applySelectedTurnIntentAsState() {
        guard let fromState = selectedState else {
            setLastError("No Active Context — tap a STATE bubble or press Reload.")
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
            setActiveContext(toState, source: .lastSentState)
            selectionStatus = "Applied turn intent into STATE rev\(toState.rev)"
            setLastError(nil)
        } catch {
            setLastError("Apply turn intent failed: \(error.localizedDescription)")
        }
    }

    private func decodeSelectedMessage(_ message: MSMessage?, activationMode: SelectionActivationMode) {
        guard let message else {
            selectionStatus = "No message selected"
            if selectedState == nil {
                resetDisplayedFields()
                refreshPendingJoiners(for: nil)
            }
            return
        }

        guard let encodedEnvelope = payloadValue(from: message) else {
            selectionStatus = "Selected message has no transport payload"
            if selectedState == nil {
                resetDisplayedFields()
                refreshPendingJoiners(for: nil)
            }
            return
        }

        do {
            let envelope = try decode(encodedEnvelope.payload)
            try apply(
                envelope: envelope,
                message: message,
                source: encodedEnvelope.source,
                activationMode: activationMode
            )
            setLastError(nil)
        } catch {
            selectionStatus = "Failed to decode selected message"
            if selectedState == nil {
                resetDisplayedFields()
                refreshPendingJoiners(for: nil)
            }
            setLastError("Decode failed: \(error.localizedDescription)")
            appendLog("Error: Decode failed")
        }
    }

    private func apply(
        envelope: EnvelopeV1,
        message: MSMessage,
        source: PayloadSource,
        activationMode: SelectionActivationMode
    ) throws {
        switch envelope.body {
        case let .state(payload):
            let state = try decodePayload(CoreGameStateV1.self, from: payload)
            latestSelectedState = state
            stateSessionsByGameId[state.gameId] = message.session
            selectedJoinIntent = nil
            selectedSetupIntent = nil
            selectedTurnIntent = nil
            let shouldActivate =
                activationMode == .force ||
                (activationMode == .activateIfMissing && selectedState == nil)
            if shouldActivate {
                setActiveContext(state, source: .selectedBubble)
            } else {
                selectionStatus = "Decoded STATE rev\(state.rev) via \(source.label)"
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
        selectedState = state
        activeSource = source
        activeUpdatedAt = Date()
        syncActingAs(with: state)
        refreshActiveContextMetadata()
        refreshStaleContextWarning()

        let payloadSource: PayloadSource = source == .lastSentState ? .local : .url
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
            actingAs = state.currentPlayer
        }
    }

    private func refreshActiveContextMetadata() {
        activeContextSource = activeSource?.label ?? "-"
        if let updatedAt = activeUpdatedAt {
            let seconds = max(0, Int(Date().timeIntervalSince(updatedAt)))
            activeContextUpdatedAgo = "\(seconds)s ago"
        } else {
            activeContextUpdatedAgo = "-"
        }
    }

    private func refreshStaleContextWarning() {
        guard
            let active = selectedState,
            let latest = latestSelectedState,
            latest.gameId == active.gameId,
            latest.rev > active.rev
        else {
            staleContextWarning = "-"
            return
        }
        staleContextWarning = "Active Context is stale. Tap latest STATE bubble and Reload."
    }

    private func appendLog(_ message: String) {
        uiLog.append(message)
        if uiLog.count > 20 {
            uiLog.removeFirst(uiLog.count - 20)
        }
    }

    private func shortIdentifier(_ value: String) -> String {
        String(value.prefix(8))
    }

    private func render(state: CoreGameStateV1, source: PayloadSource) {
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
        selectionStatus = "Decoded STATE rev\(state.rev) via \(source.label)"
        refreshPendingJoiners(for: state.gameId)
    }

    private func render(joinIntent: JoinIntentV1, source: PayloadSource) {
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
        selectionStatus = "Decoded JOIN intent via \(source.label)"
        refreshPendingJoiners(for: joinIntent.gameId)
        appendLog("Decoded INTENT kind=join actor=\(shortIdentifier(joinIntent.actor))")
    }

    private func render(setupIntent: SetupPlacementIntentV1, source: PayloadSource) {
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
        selectionStatus = "Decoded \(setupIntent.kind.rawValue) intent via \(source.label)"
        refreshPendingJoiners(for: setupIntent.gameId)
        appendLog("Decoded INTENT kind=\(setupIntent.kind.rawValue) actor=\(shortIdentifier(setupIntent.actor))")
    }

    private func render(turnIntent decodedTurnIntent: ULS_Transport.TurnIntentV1, source: PayloadSource) {
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
        selectionStatus = "Decoded \(decodedTurnIntent.kind.rawValue) intent via \(source.label)"
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
            state.turnState?.step == .afterRoll,
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

    private func payloadValue(from message: MSMessage) -> DecodedPayloadSource? {
        guard
            let url = message.url,
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
            let payload = components.queryItems?.first(where: { $0.name == "payload" })?.value,
            !payload.isEmpty
        else {
            #if DEBUG && targetEnvironment(simulator)
            if
                let summaryText = message.summaryText,
                summaryText.hasPrefix(summaryPayloadPrefix)
            {
                let start = summaryText.index(summaryText.startIndex, offsetBy: summaryPayloadPrefix.count)
                let payload = String(summaryText[start...])
                if !payload.isEmpty {
                    return DecodedPayloadSource(payload: payload, source: .summaryFallback)
                }
            }
            #endif
            return nil
        }

        return DecodedPayloadSource(payload: payload, source: .url)
    }

    private func sendEnvelope(_ envelope: EnvelopeV1, caption: String, sessionPolicy: SessionPolicy) throws {
        guard let conversation = activeConversation else {
            throw SendError.noActiveConversation
        }

        let encodedEnvelope = try encode(envelope)
        let resolvedPolicy = resolveSessionPolicy(policy: sessionPolicy, for: envelope)

        var components = URLComponents()
        components.scheme = "unluckysevens"
        components.host = "msg"
        components.queryItems = [URLQueryItem(name: "payload", value: encodedEnvelope)]

        guard let url = components.url else {
            throw SendError.invalidURL
        }

        let message = MSMessage(session: session(for: resolvedPolicy))
        message.url = url

        let layout = MSMessageTemplateLayout()
        layout.caption = caption
        message.layout = layout
        message.summaryText = summaryLabel(for: envelope)
        appendLog("Sending \(message.summaryText ?? "message")")

        conversation.insert(message) { [weak self] error in
            Task { @MainActor in
                guard let self else { return }
                if let error {
                    self.setLastError("Send failed: \(error.localizedDescription)")
                    self.appendLog("Error: send failed")
                }
            }
        }
    }

    private func resolveSessionPolicy(policy: SessionPolicy, for envelope: EnvelopeV1) -> SessionPolicy {
        guard
            useSingleSessionDebug,
            envelope.kind == .intent,
            case .new = policy,
            let gameId = currentGameId()
        else {
            return policy
        }
        return .state(gameId: gameId)
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
        guard let gameId else {
            pendingJoiners = "[]"
            return
        }

        let joiners = loadPendingJoiners(for: gameId)
        pendingJoiners = joiners.isEmpty ? "[]" : joiners.joined(separator: ", ")
    }

    private func loadPendingJoiners(for gameId: String) -> [String] {
        userDefaults.stringArray(forKey: pendingJoinersKey(for: gameId)) ?? []
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

    private func session(for policy: SessionPolicy) -> MSSession {
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

    private enum SessionPolicy {
        case new
        case state(gameId: String)
    }

    private enum SelectionActivationMode {
        case activateIfMissing
        case force
    }

    private enum ActiveContextSource {
        case selectedBubble
        case lastSentState

        var label: String {
            switch self {
            case .selectedBubble:
                return "selectedBubble"
            case .lastSentState:
                return "lastSentState"
            }
        }
    }

    private struct DecodedPayloadSource {
        let payload: String
        let source: PayloadSource
    }

    private enum PayloadSource {
        case url
        case summaryFallback
        case local

        var label: String {
            switch self {
            case .url:
                return "URL"
            case .summaryFallback:
                return "summary fallback"
            case .local:
                return "local"
            }
        }
    }

    private enum SendError: LocalizedError {
        case noActiveConversation
        case invalidURL
        case invalidJSONPayload
        case invalidIntentPayload

        var errorDescription: String? {
            switch self {
            case .noActiveConversation:
                return "No active conversation."
            case .invalidURL:
                return "Could not build iMessage payload URL."
            case .invalidJSONPayload:
                return "Could not create JSON payload string."
            case .invalidIntentPayload:
                return "Intent payload is missing required fields."
            }
        }
    }
}
