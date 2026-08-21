import Combine
import Foundation
import Messages
import ULS_CoreGame
import ULS_Transport

@MainActor
final class LobbyDriverViewModel: ObservableObject {
    @Published private(set) var gameplayShellProjection: GameShellProjection = .empty
    @Published var lastError: String = "-"
    @Published var activeContextSource: String = "-"
    @Published var staleContextWarning: String = "-"
    @Published var boardStrategy: BoardGenStrategyV1
    @Published private(set) var boardReloadToken: Int = 0
    @Published private(set) var gameShellResetToken: Int = 0
    @Published private(set) var recoveredGames: [ActiveGameRecoverySummary] = []
    @Published private(set) var dismissRequestToken: Int = 0
    @Published var lobbyDisplayNameDraft: String = ""
    @Published private(set) var isSendingInvite = false

    private let boardStrategyKey = "uls.boardStrategy"
    private let userDefaults: UserDefaults
    private let gameLedgerStore: TranscriptGameLedgerStore
    private let lobbyDisplayNamePreferenceStore: LobbyDisplayNamePreferenceStore
    private let allowsLocalLedgerStateRecovery = true
    private let tutorialActorID: String?

    private weak var activeConversation: MSConversation?
    var onRequestDismiss: (() -> Void)?
    var onRequestExpanded: (() -> Void)?
    private var selectedState: CoreGameStateV1?
    private var selectionStatus: String = "No message selected"
    private var latestKnownStatesByGameId: [String: CoreGameStateV1] = [:]
    private var activeSource: ActiveContextSource?
    private var stateSessionsByGameId: [String: MSSession] = [:]
    private var unboundRecoveredGameIds: Set<String> = []
    private var selectedTranscriptGameId: String?
    private var lastResolvedSelectionSignature: String?
    private var cachedBoardOverlayModelKey: BoardOverlayModelCacheKey?
    private var cachedBoardOverlayModelValue: GameBoardOverlayModel?
    private var cachedDevCardPanelModelKey: DevCardPanelModelCacheKey?
    private var cachedDevCardPanelModelValue: GameDevCardPanelModel??
    private var cachedBankTrayModelKey: BankTrayModelCacheKey?
    private var cachedBankTrayModelValue: GameBankTrayModel?
    #if DEBUG
    @Published var uxTestingSelectedFixtureID: String = UXTestFixtures.defaultFixtureID
    @Published var uxTestingActorID: String = UXTestFixtures.defaultActorID
    @Published var uxTestingHumanActorID: String = UXTestFixtures.defaultActorID
    @Published var uxTestingFollowsTurnOwner: Bool = true
    @Published var uxTestingAutoplaysDummyTurns: Bool = false
    @Published private(set) var uxTestingIsActive: Bool = false
    @Published private(set) var uxTestingChromeHiddenForScreenshot: Bool = false
    @Published private(set) var uxTestingSettingsHookInvocationCount: Int = 0
    @Published private(set) var uxTestingInitialGameMode: GameMode = .idle
    @Published private(set) var uxTestingInitialGameRoute: GameShellRoute = .none
    @Published private(set) var uxTestingForcesCityTargets: Bool = false
    @Published private(set) var uxTestingLastRawError: String = "-"
    private var uxTestingAutoplayIsRunning = false
    private static let uxTestingChromeHiddenKey = "uls.debug.uxTestingChromeHidden"
    #endif

    init(
        userDefaults: UserDefaults = .standard,
        tutorialState: CoreGameStateV1? = nil,
        tutorialActorID: String? = nil
    ) {
        self.userDefaults = userDefaults
        self.tutorialActorID = tutorialActorID
        #if DEBUG
        uxTestingChromeHiddenForScreenshot = userDefaults.bool(
            forKey: Self.uxTestingChromeHiddenKey
        )
        #endif
        lobbyDisplayNamePreferenceStore = LobbyDisplayNamePreferenceStore(userDefaults: userDefaults)
        gameLedgerStore = TranscriptGameLedgerStore(userDefaults: userDefaults)
        if let rawValue = userDefaults.string(forKey: boardStrategyKey),
           let parsed = BoardGenStrategyV1(rawValue: rawValue) {
            boardStrategy = parsed
        } else {
            boardStrategy = BoardStrategyDefaults.newGame
        }
        lobbyDisplayNameDraft = lobbyDisplayNamePreferenceStore.load() ?? ""
        let ledgerSnapshot = gameLedgerStore.bootstrapSnapshot()
        latestKnownStatesByGameId = ledgerSnapshot.latestKnownStatesByGameId
        refreshRecoveredGames()

        if let tutorialState {
            selectedState = tutorialState
            activeSource = .tutorial
            render(state: tutorialState, source: .local)
        }
    }

    #if DEBUG
    var uxTestingFixtures: [UXTestFixture] {
        UXTestFixtures.all
    }

    var uxTestingGameplayEvidence: String {
        [
            "game=\(gameId)",
            "rev=\(rev)",
            "phase=\(phase)",
            "winner=\(selectedState?.winnerPlayer ?? "-")",
            "winningVP=\(selectedState?.winningVictoryPoints ?? 0)",
            "step=\(gameplayShellProjection.turnStep)",
            "current=\(currentPlayer)",
            "hash=\(stateHash)",
            "hand=\(visibleHands)",
            "dev=\(visibleDevCards)",
            "pieces=\(remainingPieces)",
            "discard=\(gameplayShellProjection.pendingDiscardRequirements)",
            "submitted=\(gameplayShellProjection.submittedDiscardsStatus)",
            "robber=\(gameplayShellProjection.boardRobberTile)",
            "victims=\(gameplayShellProjection.eligibleStealVictims)",
            "setup=\(gameplayShellProjection.setupPlacement)",
            "trade=\(gameplayShellProjection.activeTradeOffer)",
            "responses=\(gameplayShellProjection.tradeResponses)",
            "status=\(selectionStatus)",
            "error=\(lastError)",
            "rawError=\(uxTestingLastRawError)",
        ]
        .joined(separator: ";")
    }

    var uxTestingSelectedFixture: UXTestFixture {
        UXTestFixtures.fixture(id: uxTestingSelectedFixtureID)
    }

    var uxTestingActorOptions: [String] {
        var actorIDs = uxTestingSelectedFixture.actorIDs
        if let selectedState {
            for actorID in selectedState.roster where !actorIDs.contains(actorID) {
                actorIDs.append(actorID)
            }
        }
        return actorIDs
    }

    func uxTestingDisplayName(for actorID: String) -> String {
        PlayerPseudonymResolver.displayName(
            for: actorID,
            in: selectedState ?? uxTestingSelectedFixture.state
        )
    }

    func activateUXTestingFixture() {
        activateUXTestingFixture(
            id: uxTestingSelectedFixtureID,
            actingAs: uxTestingActorID
        )
    }

    func activateUXTestingFixture(
        id: String,
        actingAs actorID: String? = nil,
        initialMode: GameMode = .idle,
        initialRoute: GameShellRoute = .none
    ) {
        let fixture = UXTestFixtures.fixture(id: id)
        uxTestingForcesCityTargets = false
        uxTestingInitialGameMode = initialMode
        uxTestingInitialGameRoute = initialRoute
        uxTestingSelectedFixtureID = fixture.id
        uxTestingHumanActorID = resolvedUXTestingActorID(
            requestedActorID: uxTestingHumanActorID,
            fixture: fixture
        )
        uxTestingActorID = resolvedUXTestingActorID(
            requestedActorID: actorID ?? uxTestingActorID,
            fixture: fixture
        )
        uxTestingIsActive = true
        setActiveContext(fixture.state, source: .uxTesting)
        selectionStatus = "UX Lab loaded \(fixture.title)"
        setLastError(nil)
        runUXTestingAutoplayIfNeeded()
        gameShellResetToken &+= 1
    }

    func activateCleanUXTestingFixture(
        id: String,
        actingAs actorID: String? = nil,
        initialMode: GameMode = .idle,
        initialRoute: GameShellRoute = .none
    ) {
        activateUXTestingFixture(
            id: id,
            actingAs: actorID,
            initialMode: initialMode,
            initialRoute: initialRoute
        )
        setUXTestingChromeHidden(true)
    }

    func activateCleanUXTestingCityFixture() {
        uxTestingAutoplaysDummyTurns = false
        activateCleanUXTestingFixture(
            id: UXTestFixtures.defaultFixtureID,
            actingAs: UXTestFixtures.host,
            initialMode: .buildCity,
            initialRoute: .build
        )
        uxTestingForcesCityTargets = true
        gameShellResetToken &+= 1
    }

    func restoreUXTestingChrome() {
        setUXTestingChromeHidden(false)
    }

    func hideUXTestingChrome() {
        setUXTestingChromeHidden(true)
    }

    private func setUXTestingChromeHidden(_ isHidden: Bool) {
        uxTestingChromeHiddenForScreenshot = isHidden
        userDefaults.set(isHidden, forKey: Self.uxTestingChromeHiddenKey)
    }

    func activateCleanLobbyInviteEntry() {
        // Keep DEBUG fixture ownership active while the selected state is
        // intentionally nil. Otherwise the next Messages selection poll may
        // restore the last local-ledger game over the requested clean lobby.
        uxTestingIsActive = true
        clearActiveContext()
        selectionStatus = "UX Lab loaded clean lobby invite entry"
        setLastError(nil)
        setUXTestingChromeHidden(true)
    }

    func seedUXTestingRecoveryGames(hideChrome: Bool = false) {
        let states = UXTestFixtures.recoveryStates
        guard let activeState = states.first else {
            setLastError("UX Lab recovery fixtures are unavailable.")
            return
        }

        for state in states {
            gameLedgerStore.archive(gameId: state.gameId)
        }
        for state in states {
            do {
                let payload = try CompactStateTransport.encode(state)
                gameLedgerStore.record(state: state, payload: payload)
            } catch {
                setLastError("UX Lab could not seed recovery fixtures.")
                return
            }
        }

        uxTestingSelectedFixtureID = UXTestFixtures.defaultFixtureID
        uxTestingActorID = UXTestFixtures.host
        uxTestingHumanActorID = UXTestFixtures.host
        uxTestingIsActive = true
        setUXTestingChromeHidden(hideChrome)
        setActiveContext(activeState, source: .uxTesting)
        gameLedgerStore.markActiveGame(activeState.gameId)
        refreshRecoveredGames()
        selectionStatus = "UX Lab seeded Active and Finished games"
        setLastError(nil)
    }

    func recordUXTestingSettingsHookInvocation() {
        uxTestingSettingsHookInvocationCount &+= 1
    }

    func refreshUXTestingActorView() {
        guard uxTestingIsActive, let state = selectedState else {
            return
        }
        if !uxTestingActorOptions.contains(uxTestingActorID) {
            uxTestingActorID = resolvedUXTestingActorID(
                requestedActorID: uxTestingActorID,
                fixture: uxTestingSelectedFixture
            )
        }
        syncLobbyDisplayNameDraft(with: state)
        refreshActiveContextMetadata()
        render(state: state, source: .local)
    }

    func refreshUXTestingHumanActor() {
        uxTestingHumanActorID = resolvedUXTestingActorID(
            requestedActorID: uxTestingHumanActorID,
            fixture: uxTestingSelectedFixture
        )
        guard uxTestingIsActive else {
            return
        }
        if uxTestingActorID == uxTestingHumanActorID {
            refreshUXTestingActorView()
        }
        runUXTestingAutoplayIfNeeded()
    }

    func refreshUXTestingAutoplay() {
        runUXTestingAutoplayIfNeeded()
    }

    func exitUXTesting() {
        uxTestingIsActive = false
        setUXTestingChromeHidden(false)
        clearActiveContext()
        selectionStatus = "UX Lab exited"
        setLastError(nil)
    }

    private func resolvedUXTestingActorID(
        requestedActorID: String,
        fixture: UXTestFixture
    ) -> String {
        if fixture.actorIDs.contains(requestedActorID) {
            return requestedActorID
        }
        if fixture.actorIDs.contains(fixture.defaultActorID) {
            return fixture.defaultActorID
        }
        return fixture.actorIDs.first ?? UXTestFixtures.defaultActorID
    }

    private func runUXTestingAutoplayIfNeeded() {
        guard
            uxTestingIsActive,
            uxTestingAutoplaysDummyTurns,
            !uxTestingAutoplayIsRunning
        else {
            return
        }

        uxTestingAutoplayIsRunning = true
        defer {
            uxTestingAutoplayIsRunning = false
        }

        let maxActions = 24
        var appliedActions = 0
        var stoppedErrorMessage: String?
        while appliedActions < maxActions {
            guard
                let state = selectedState,
                let action = UXTestingAutoplayResolver.nextAction(
                    state: state,
                    fixture: uxTestingSelectedFixture,
                    humanActorID: uxTestingHumanActorID
                )
            else {
                break
            }

            do {
                try applyUXTestingAutoplayAction(action)
                appliedActions += 1
            } catch {
                stoppedErrorMessage = "UX Lab autoplay stopped: \(error.localizedDescription)"
                break
            }
        }

        guard appliedActions > 0 else {
            if let stoppedErrorMessage {
                setLastError(stoppedErrorMessage)
            }
            return
        }

        if let stoppedErrorMessage {
            setLastError(stoppedErrorMessage)
        } else if appliedActions == maxActions {
            setLastError("UX Lab autoplay paused after \(maxActions) actions.")
        } else {
            setLastError(nil)
        }

        if let state = selectedState, state.roster.contains(uxTestingHumanActorID) {
            uxTestingActorID = uxTestingHumanActorID
            refreshUXTestingActorView()
        }
        selectionStatus = "UX Lab autoplayed \(appliedActions) dummy action\(appliedActions == 1 ? "" : "s")"
    }

    private func applyUXTestingAutoplayAction(_ action: UXTestingAutoplayResolver.Action) throws {
        switch action {
        case let .joinDummy(actorID, displayName):
            guard
                let fromState = selectedState,
                let joinedState = LobbyMembershipResolver.joinedLobbyState(
                    state: fromState,
                    localParticipant: actorID,
                    displayName: displayName
                )
            else {
                throw SendError.invalidIntentPayload
            }

            try validateTransition(from: fromState, to: joinedState, actor: actorID)
            let payload = try jsonString(from: joinedState)
            let envelope = EnvelopeV1(kind: .state, body: .state(payload: payload))
            try sendEnvelope(
                envelope,
                bubbleCopy: TranscriptBubbleCopyBuilder.lobbyJoin(
                    to: joinedState,
                    joiningPlayer: actorID
                ),
                sessionPolicy: .state(gameId: joinedState.gameId)
            )
        case let .setup(intent, actor):
            guard let fromState = selectedState else {
                throw SendError.invalidIntentPayload
            }
            uxTestingActorID = actor
            try applyAndPublishSetupIntent(
                intent,
                from: fromState,
                actor: actor,
                successStatus: "UX Lab autoplayed setup"
            )
        case let .turn(draft):
            uxTestingActorID = draft.actor
            try applyAndPublishTurnIntent(
                draft,
                successStatus: "UX Lab autoplayed turn"
            )
        }
    }
    #endif

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

    var canInvite: Bool {
        activeConversation != nil
    }

    var rootRoute: MessagesRootRoute {
        MessagesRootRoute.resolve(phase: selectedState?.phase)
    }

    var hasRecoveredGames: Bool {
        !recoveredGames.isEmpty
    }

    var activeRecoveredGames: [ActiveGameRecoverySummary] {
        recoveredGames.filter { !$0.isFinished }
    }

    var finishedRecoveredGames: [ActiveGameRecoverySummary] {
        recoveredGames.filter(\.isFinished)
    }

    var lobbyScreenModel: LobbyScreenModel {
        LobbyScreenModelBuilder.build(
            context: LobbyScreenContext(
                selectedState: selectedState,
                localActor: localParticipantIdentifier(),
                activeContextSource: activeContextSource,
                staleWarning: staleContextWarning,
                lastError: lastError,
                canInvite: canInvite,
                canJoin: canJoin,
                canStartGame: canStartGame
            )
        )
    }

    var canPublishLobbyDisplayName: Bool {
        guard
            let state = selectedState,
            state.phase == .lobby,
            let localParticipant = localParticipantIdentifier(),
            state.roster.contains(localParticipant),
            let normalizedDraft = normalizedLobbyDisplayNameDraft()
        else {
            return false
        }

        return state.playerDisplayNamesByPlayer[localParticipant] != normalizedDraft
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

        guard let actor = localActorIdentifier(), actor == state.currentPlayer else {
            return false
        }

        return state.canInitiatePlayerTrade(for: actor)
            || state.canInitiateMaritimeTrade(for: actor)
    }

    var hasActiveContext: Bool {
        selectedState != nil
    }

    var isNormalPostRollActiveTurn: Bool {
        guard
            let state = selectedState,
            state.phase == .turn,
            state.turnState?.step == .afterRoll,
            let actor = localActorIdentifier()
        else {
            return false
        }

        return actor == state.currentPlayer
    }

    var isNormalPreRollActiveTurn: Bool {
        guard
            let state = selectedState,
            state.phase == .turn,
            state.turnState?.step == .needsRoll,
            let actor = localActorIdentifier()
        else {
            return false
        }

        return actor == state.currentPlayer
    }

    var physicalNotPrimaryPlayerContext: GamePhysicalNotPrimaryPlayerContext? {
        GamePhysicalNotPrimaryPlayerContext.resolve(
            state: selectedState,
            actingAs: localActorIdentifier(),
            tradePanel: tradePanelModel,
            discardPanel: discardPanelModel
        )
    }

    var canJoin: Bool {
        LobbyMembershipResolver.canJoin(
            state: selectedState,
            localParticipant: localParticipantIdentifier()
        )
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

    private var canPublishDevCardPurchaseState: Bool {
        DevCardInteractionResolver.draftBuyDevCardIntent(
            state: selectedState,
            actingAs: localActorIdentifier()
        ) != nil
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

    var shouldMaintainSelectionWatch: Bool {
        activeConversation?.selectedMessage != nil || currentGameId() != nil
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

    @discardableResult
    func updateContext(
        conversation: MSConversation?,
        selectedMessage: MSMessage?,
        trigger: TranscriptSelectionTrigger
    ) -> Bool {
        activeConversation = conversation
        #if DEBUG
        if uxTestingIsActive {
            refreshActiveContextMetadata()
            return false
        }
        #endif
        if
            trigger == .selectionPoll,
            let selectedMessage,
            let signature = selectionSignature(for: selectedMessage),
            signature == lastResolvedSelectionSignature
        {
            return false
        }
        refreshActiveContextMetadata()
        return decodeSelectedMessage(
            selectedMessage,
            trigger: trigger
        )
    }

    func clearActiveContext() {
        selectedState = nil
        activeSource = nil
        activeContextSource = "-"
        staleContextWarning = "-"
        gameLedgerStore.markActiveGame(nil)
        refreshRecoveredGames()
        resetDisplayedFields()
        lobbyDisplayNameDraft = lobbyDisplayNamePreferenceStore.load() ?? ""
    }

    func prepareNewGame() {
        clearActiveContext()
        selectedTranscriptGameId = nil
        lastResolvedSelectionSignature = nil
        selectionStatus = "Ready for a new game"
        setLastError(nil)
    }

    func beginFreshLobby(conversation: MSConversation) {
        activeConversation = conversation
        prepareNewGame()
    }

    func inviteNewGame() {
        guard !isSendingInvite else { return }
        guard let actor = localParticipantIdentifier() else {
            setLastError("Missing local participant identifier.")
            return
        }

        let preferredDisplayName = normalizedLobbyDisplayNameDraft()
        let state = CoreGameStateV1(
            gameId: UUID().uuidString,
            rev: 0,
            prevHash: nil,
            stateHash: "",
            roster: [actor],
            currentPlayer: actor,
            playerDisplayNamesByPlayer: preferredDisplayName.map { [actor: $0] } ?? [:],
            phase: .lobby,
            seed: nil,
            diceRngState: nil,
            resourcesByPlayer: [actor: .zero],
            boardRules: nil,
            board: nil
        ).rehashed()

        isSendingInvite = true
        do {
            let payload = try jsonString(from: state)
            let envelope = EnvelopeV1(kind: .state, body: .state(payload: payload))
            try sendEnvelope(
                envelope,
                bubbleCopy: TranscriptBubbleCopyBuilder.invite(for: state),
                sessionPolicy: .state(gameId: state.gameId),
                postPublishEffect: .dismissExtension
            )
            persistPreferredLobbyDisplayNameIfPresent(preferredDisplayName)
            setActiveContext(state, source: .lastSentState)
            selectionStatus = "Invite sent: lobby rev0"
            setLastError(nil)
        } catch {
            isSendingInvite = false
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

        let preferredDisplayName = normalizedLobbyDisplayNameDraft()
        guard let joinedState = LobbyMembershipResolver.joinedLobbyState(
            state: state,
            localParticipant: actor,
            displayName: preferredDisplayName
        ) else {
            setLastError("Join is only available from lobby STATE messages.")
            return
        }

        do {
            try validateTransition(from: state, to: joinedState, actor: actor)
            let payload = try jsonString(from: joinedState)
            let envelope = EnvelopeV1(kind: .state, body: .state(payload: payload))
            try sendEnvelope(
                envelope,
                bubbleCopy: TranscriptBubbleCopyBuilder.lobbyJoin(to: joinedState, joiningPlayer: actor),
                sessionPolicy: .state(gameId: joinedState.gameId)
            )
            persistPreferredLobbyDisplayNameIfPresent(preferredDisplayName)
            setActiveContext(joinedState, source: .lastSentState)
            selectionStatus = "Joined lobby rev\(joinedState.rev)"
            setLastError(nil)
        } catch {
            setLastError("Join failed: \(error.localizedDescription)")
        }
    }

    func publishLobbyDisplayName() {
        guard let state = selectedState else {
            setLastError("Select a lobby bubble first.")
            return
        }

        guard state.phase == .lobby else {
            setLastError("Names can only be updated in the lobby.")
            return
        }

        guard let actor = localParticipantIdentifier() else {
            setLastError("Missing local participant identifier.")
            return
        }

        let previousDisplayName = PlayerPseudonymResolver.displayName(for: actor, in: state)
        let preferredDisplayName = normalizedLobbyDisplayNameDraft()
        guard let renamedState = LobbyMembershipResolver.renamedLobbyState(
            state: state,
            localParticipant: actor,
            displayName: preferredDisplayName
        ) else {
            setLastError("Enter a new name before saving.")
            return
        }

        do {
            try validateTransition(from: state, to: renamedState, actor: actor)
            let payload = try jsonString(from: renamedState)
            let envelope = EnvelopeV1(kind: .state, body: .state(payload: payload))
            try sendEnvelope(
                envelope,
                bubbleCopy: TranscriptBubbleCopyBuilder.lobbyRename(
                    from: state,
                    to: renamedState,
                    player: actor,
                    previousDisplayName: previousDisplayName
                ),
                sessionPolicy: .state(gameId: renamedState.gameId)
            )
            persistPreferredLobbyDisplayNameIfPresent(preferredDisplayName)
            setActiveContext(renamedState, source: .lastSentState)
            selectionStatus = "Saved name in lobby rev\(renamedState.rev)"
            setLastError(nil)
        } catch {
            setLastError("Name update failed: \(error.localizedDescription)")
        }
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
            playerDisplayNamesByPlayer: fromState.playerDisplayNamesByPlayer,
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
                bubbleCopy: TranscriptBubbleCopyBuilder.startGame(from: fromState, to: toState),
                sessionPolicy: .state(gameId: toState.gameId)
            )
            gameLedgerStore.clearObservedJoiners(for: toState.gameId)
            refreshRecoveredGames()
            setActiveContext(toState, source: .lastSentState)
            selectionStatus = "Start sent: setup rev\(toState.rev)"
            setLastError(nil)
        } catch {
            setLastError("Start failed: \(error.localizedDescription)")
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
        guard let draft = immediateTurnIntent(for: actionKind) else {
            return false
        }

        do {
            try applyAndPublishTurnIntent(draft, successStatus: successStatus(for: draft.intent))
            return true
        } catch {
            setLastError("Turn action failed: \(error.localizedDescription)")
            return false
        }
    }

    func publishDiceRoll() -> GameDiceRollResult? {
        guard let draft = immediateTurnIntent(for: .roll) else {
            return nil
        }

        do {
            let resultingState = try applyAndPublishTurnIntent(
                draft,
                successStatus: successStatus(for: draft.intent)
            )
            guard let roll = resultingState.turnState?.lastRoll else {
                return nil
            }
            return GameDiceRollResult(first: roll.d1, second: roll.d2)
        } catch {
            setLastError("Turn action failed: \(error.localizedDescription)")
            return nil
        }
    }

    func previewDiceRoll() -> GameDiceRollResult? {
        guard let draft = immediateTurnIntent(for: .roll) else {
            return nil
        }

        do {
            let resolution = actionAuthoringStateResolution(for: draft.anchorGameId)
            guard let fromState = resolution.state ?? selectedState, draft.matches(fromState) else {
                return nil
            }
            let resultingState = try ULS_CoreGame.apply(
                intent: draft.intent,
                to: fromState,
                actor: draft.actor
            )
            guard let roll = resultingState.turnState?.lastRoll else {
                return nil
            }
            return GameDiceRollResult(first: roll.d1, second: roll.d2)
        } catch {
            setLastError("Turn action failed: \(error.localizedDescription)")
            return nil
        }
    }

    @discardableResult
    func publishTurnState(for target: GameBoardTarget, mode: GameMode) -> Bool {
        let resolution = actionAuthoringStateResolution()
        let authoringState = resolution.state
        let draft: TurnActionDraft?
        let failureMessage: String

        switch mode {
        case .buildRoad, .buildSettlement, .buildCity:
            draft = TurnInteractionResolver.draftBuildIntent(
                state: authoringState,
                actingAs: localActorIdentifier(for: authoringState),
                mode: mode,
                target: target
            )
            failureMessage = "Selected build target is not legal."
        case .robberMove:
            draft = TurnInteractionResolver.draftRobberMoveIntent(
                state: authoringState,
                actingAs: localActorIdentifier(for: authoringState),
                target: target
            )
            failureMessage = "Selected robber tile is not legal."
        case .robberVictim:
            draft = TurnInteractionResolver.draftStealVictimIntent(
                state: authoringState,
                actingAs: localActorIdentifier(for: authoringState),
                target: target
            )
            failureMessage = "Selected robber victim is not legal."
        default:
            draft = nil
            failureMessage = "Selected turn target is not legal."
        }

        guard let draft else {
            setLastError(failureMessage)
            return false
        }
        activateAuthoringStateIfNeeded(resolution)

        do {
            try applyAndPublishTurnIntent(draft, successStatus: successStatus(for: draft.intent))
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

        guard let draft = TurnInteractionResolver.draftDiscardIntent(
            state: state,
            actingAs: actor,
            discarded: discarded
        ) else {
            setLastError("No valid discard action is currently available.")
            return false
        }

        do {
            try applyAndPublishTurnIntent(draft, successStatus: successStatus(for: draft.intent))
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
        guard let draft = TradeInteractionResolver.draftTradeOfferIntent(
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
            try applyAndPublishTurnIntent(draft, successStatus: "Published trade offer")
            return true
        } catch {
            setLastError("Trade offer failed: \(error.localizedDescription)")
            return false
        }
    }

    @discardableResult
    func publishMaritimeTrade(give: ResourceHandV1, receive: ResourceHandV1) -> Bool {
        let resolution = actionAuthoringStateResolution()
        guard let draft = TradeInteractionResolver.draftMaritimeTradeIntent(
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
            try applyAndPublishTurnIntent(draft, successStatus: "Published maritime trade")
            return true
        } catch {
            setLastError("Maritime trade failed: \(error.localizedDescription)")
            return false
        }
    }

    @discardableResult
    func sendAcceptTradeResponse() -> Bool {
        let resolution = actionAuthoringStateResolution()
        guard let draft = TradeInteractionResolver.draftAcceptTradeIntent(
            state: resolution.state,
            actingAs: localActorIdentifier(for: resolution.state)
        ) else {
            setLastError("No legal trade accept is available.")
            return false
        }
        activateAuthoringStateIfNeeded(resolution)

        do {
            try publishTradeResponse(draft)
            return true
        } catch {
            setLastError("Accept trade failed: \(error.localizedDescription)")
            return false
        }
    }

    @discardableResult
    func sendDeclineTradeResponse() -> Bool {
        let resolution = actionAuthoringStateResolution()
        guard let draft = TradeInteractionResolver.draftDeclineTradeIntent(
            state: resolution.state,
            actingAs: localActorIdentifier(for: resolution.state)
        ) else {
            setLastError("No legal trade decline is available.")
            return false
        }
        activateAuthoringStateIfNeeded(resolution)

        do {
            try publishTradeResponse(draft)
            return true
        } catch {
            setLastError("Decline trade failed: \(error.localizedDescription)")
            return false
        }
    }

    @discardableResult
    func sendCounterTradeResponse(give: ResourceHandV1, receive: ResourceHandV1) -> Bool {
        let resolution = actionAuthoringStateResolution()
        guard let draft = TradeInteractionResolver.draftCounterTradeIntent(
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
            try publishTradeResponse(draft)
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
            guard let draft = DevCardInteractionResolver.draftBuyDevCardIntent(
                state: resolution.state,
                actingAs: localActorIdentifier(for: resolution.state)
            ) else {
                setLastError("Selected dev-card action is not legal.")
                return false
            }
            activateAuthoringStateIfNeeded(resolution)
            do {
                try applyAndPublishTurnIntent(draft, successStatus: "Published dev-card purchase")
                return true
            } catch {
                setLastError("Dev-card action failed: \(error.localizedDescription)")
                return false
            }
        case .revealVictoryPoint:
            let resolution = actionAuthoringStateResolution()
            guard let draft = DevCardInteractionResolver.draftRevealVictoryPointIntent(
                state: resolution.state,
                actingAs: localActorIdentifier(for: resolution.state)
            ) else {
                setLastError("Selected dev-card action is not legal.")
                return false
            }
            activateAuthoringStateIfNeeded(resolution)
            do {
                try applyAndPublishTurnIntent(draft, successStatus: "Published victory-point reveal")
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
        let draftAction: TurnActionDraft?
        let successStatus: String

        switch draft {
        case let .knight(tileID, victimPlayer):
            guard let tileID else {
                setLastError("Knight play needs a robber tile.")
                return false
            }
            draftAction = DevCardInteractionResolver.draftPlayKnightIntent(
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
            draftAction = DevCardInteractionResolver.draftPlayMonopolyIntent(
                state: authoringState,
                actingAs: authoringActor,
                resource: resource
            )
            successStatus = "Published monopoly play"
        case let .yearOfPlenty(first, second):
            guard let first, let second else {
                setLastError("Year of Plenty needs two resources.")
                return false
            }
            draftAction = DevCardInteractionResolver.draftPlayYearOfPlentyIntent(
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
            draftAction = DevCardInteractionResolver.draftPlayRoadBuildingIntent(
                state: authoringState,
                actingAs: authoringActor,
                firstEdgeID: firstEdgeID,
                secondEdgeID: secondEdgeID
            )
            successStatus = "Published road-building play"
        }

        guard let draftAction else {
            setLastError("Selected dev-card action is not legal.")
            return false
        }
        activateAuthoringStateIfNeeded(resolution)

        do {
            try applyAndPublishTurnIntent(draftAction, successStatus: successStatus)
            return true
        } catch {
            setLastError("Dev-card action failed: \(error.localizedDescription)")
            return false
        }
    }

    @discardableResult
    func publishRobberVictimState(victimPlayer: String) -> Bool {
        let resolution = actionAuthoringStateResolution()
        guard let draft = TurnInteractionResolver.draftStealVictimIntent(
            state: resolution.state,
            actingAs: localActorIdentifier(for: resolution.state),
            victimPlayer: victimPlayer
        ) else {
            setLastError("Selected robber victim is not legal.")
            return false
        }
        activateAuthoringStateIfNeeded(resolution)

        do {
            try applyAndPublishTurnIntent(draft, successStatus: successStatus(for: draft.intent))
            return true
        } catch {
            setLastError("Steal selection failed: \(error.localizedDescription)")
            return false
        }
    }

    private func applyAndPublishSetupIntent(
        _ setupIntent: SetupIntentV1,
        from fromState: CoreGameStateV1,
        actor: String,
        successStatus: String
    ) throws {
        let toState = try ULS_CoreGame.apply(intent: setupIntent, to: fromState, actor: actor)
        try validateTransition(from: fromState, to: toState, actor: actor)

        let payload = try jsonString(from: toState)
        let envelope = EnvelopeV1(kind: .state, body: .state(payload: payload))
        try sendEnvelope(
            envelope,
            bubbleCopy: TranscriptBubbleCopyBuilder.setupIntent(
                setupIntent,
                resultingState: toState,
                actor: actor
            ),
            sessionPolicy: .state(gameId: toState.gameId)
        )
        setActiveContext(toState, source: .lastSentState)
        selectionStatus = "\(successStatus) rev\(toState.rev)"
        setLastError(nil)
    }

    private func decodeSelectedMessage(
        _ message: MSMessage?,
        trigger: TranscriptSelectionTrigger
    ) -> Bool {
        if
            trigger == .selectionPoll,
            let message,
            let signature = selectionSignature(for: message),
            signature == lastResolvedSelectionSignature
        {
            return false
        }

        guard let message else {
            selectedTranscriptGameId = nil
            selectionStatus = "No message selected"
            if selectedState == nil {
                resetDisplayedFields()
            }
            return true
        }

        guard let encodedEnvelope = payloadValue(from: message) else {
            selectedTranscriptGameId = nil
            selectionStatus = "Selected message has no transport payload"
            if selectedState == nil {
                resetDisplayedFields()
            }
            setLastError("Missing message payload.")
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
            setLastError(nil)
            return false
        } catch {
            selectedTranscriptGameId = nil
            selectionStatus = "Failed to decode selected message"
            if selectedState == nil {
                resetDisplayedFields()
            }
            setLastError(playerFacingRecoveryErrorMessage(for: error))
            return false
        }
    }

    private func apply(
        envelope: EnvelopeV1,
        message: MSMessage,
        source: TranscriptPayloadSource,
        trigger: TranscriptSelectionTrigger
    ) throws {
        let payload: String
        switch envelope.body {
        case let .state(value):
            payload = value
        }

        let state = try decodePayload(CoreGameStateV1.self, from: payload)
        try validateCanonicalSnapshot(state)
        selectedTranscriptGameId = state.gameId
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
        if message.session != nil {
            unboundRecoveredGameIds.remove(state.gameId)
        }
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
        case .uxTesting, .tutorial:
            transcriptActiveSource = nil
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
            selectionStatus = "Stored received game rev\(stateSelection.preferredState.rev) for another game"
        } else {
            selectionStatus = stateSelection.selectionStatus
        }

        refreshStaleContextWarning()
    }

    private func setActiveContext(_ state: CoreGameStateV1, source: ActiveContextSource) {
        latestKnownStatesByGameId = TranscriptStateSelection.recording(
            state,
            in: latestKnownStatesByGameId
        )
        selectedState = state
        activeSource = source
        gameLedgerStore.markActiveGame(state.gameId)
        refreshRecoveredGames()
        syncLobbyDisplayNameDraft(with: state)
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
        case .uxTesting:
            payloadSource = .local
        case .tutorial:
            payloadSource = .local
        }
        render(state: state, source: payloadSource)
    }

    private func syncLobbyDisplayNameDraft(with state: CoreGameStateV1?) {
        lobbyDisplayNameDraft = LobbyDisplayNameDraftResolver.resolve(
            state: state,
            localParticipant: localParticipantIdentifier(),
            preferredDisplayName: lobbyDisplayNamePreferenceStore.load() ?? ""
        )
    }

    private func refreshActiveContextMetadata() {
        activeContextSource = activeSource?.label ?? "-"
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

    func requestBoardReload(detail: String = "manual") {
        _ = detail
        boardReloadToken &+= 1
    }

    func resumeRecoveredGame(_ gameId: String) {
        guard let recoveredState = gameLedgerStore.latestState(for: gameId) else {
            refreshRecoveredGames()
            setLastError("Corrupt local recovery record.")
            return
        }

        bindRecoveredSessionIfAvailable(for: gameId)
        setActiveContext(recoveredState, source: .localLedgerState)
        onRequestExpanded?()
        selectionStatus = "Recovered latest game rev\(recoveredState.rev)"
        setLastError(nil)
    }

    func requiresTranscriptReconnect(_ gameId: String) -> Bool {
        if stateSessionsByGameId[gameId] != nil {
            return false
        }
        if
            let selected = activeConversation?.selectedMessage,
            selected.session != nil,
            gameIdEncodedInMessage(selected) == gameId
        {
            return false
        }
        return gameLedgerStore.latestState(for: gameId) != nil
    }

    func canResendRecoveredGame(_ gameId: String) -> Bool {
        guard
            let state = gameLedgerStore.latestState(for: gameId),
            isCompatibleWithActiveConversation(state)
        else {
            return false
        }
        return localActorIdentifier(for: state) != nil
    }

    func resendRecoveredGame(_ gameId: String) {
        guard
            let state = gameLedgerStore.latestState(for: gameId),
            let actor = localActorIdentifier(for: state),
            isCompatibleWithActiveConversation(state)
        else {
            setLastError("Open this game from its original group chat before resending it.")
            return
        }

        do {
            let unchangedState = try RecoveryStatePublicationResolver.resolve(
                state: state,
                actor: actor
            )
            let payload = try jsonString(from: unchangedState)
            let envelope = EnvelopeV1(kind: .state, body: .state(payload: payload))
            try sendEnvelope(
                envelope,
                bubbleCopy: TranscriptBubbleCopyBuilder.recoveryResend(
                    state: unchangedState,
                    actor: actor
                ),
                sessionPolicy: .state(gameId: unchangedState.gameId),
                permitsRecoverySessionStart: true
            )
            setActiveContext(unchangedState, source: .lastSentState)
            selectionStatus = "Resent unchanged game state rev\(unchangedState.rev)"
            setLastError(nil)
        } catch {
            setLastError("Resend failed: \(error.localizedDescription)")
        }
    }

    func canResignRecoveredGame(_ gameId: String) -> Bool {
        guard
            let state = gameLedgerStore.latestState(for: gameId),
            state.phase == .setup || state.phase == .turn,
            state.activePlayers.count > 1,
            let actor = localActorIdentifier(for: state),
            state.isActivePlayer(actor),
            isCompatibleWithActiveConversation(state)
        else {
            return false
        }
        return true
    }

    func resignRecoveredGame(_ gameId: String) {
        guard
            let fromState = gameLedgerStore.latestState(for: gameId),
            let actor = localActorIdentifier(for: fromState),
            isCompatibleWithActiveConversation(fromState)
        else {
            setLastError("Open this game from its original group chat before resigning.")
            return
        }

        do {
            let toState = try ULS_CoreGame.apply(
                intent: GameLifecycleIntentV1.resign(anchoredTo: fromState),
                to: fromState,
                actor: actor
            )
            try validateTransition(from: fromState, to: toState, actor: actor)
            let payload = try jsonString(from: toState)
            let envelope = EnvelopeV1(kind: .state, body: .state(payload: payload))
            try sendEnvelope(
                envelope,
                bubbleCopy: TranscriptBubbleCopyBuilder.resignation(
                    resultingState: toState,
                    actor: actor
                ),
                sessionPolicy: .state(gameId: toState.gameId)
            )
            setActiveContext(toState, source: .lastSentState)
            selectionStatus = "Published resignation rev\(toState.rev)"
            setLastError(nil)
        } catch {
            setLastError("Resign failed: \(error.localizedDescription)")
        }
    }

    func canProposeDraw(for gameId: String) -> Bool {
        guard
            let state = gameLedgerStore.latestState(for: gameId),
            state.phase == .setup || state.phase == .turn,
            state.drawVote == nil,
            let actor = localActorIdentifier(for: state),
            isCompatibleWithActiveConversation(state)
        else {
            return false
        }
        return state.isActivePlayer(actor)
    }

    func proposeDraw(for gameId: String) {
        publishLifecycleChange(
            gameId: gameId,
            intent: { .proposeDraw(anchoredTo: $0) },
            receipt: { state, actor in
                TranscriptBubbleCopyBuilder.drawProposed(
                    resultingState: state,
                    actor: actor
                )
            },
            successStatus: "Published draw proposal"
        )
    }

    func canVoteOnDraw(for gameId: String) -> Bool {
        guard
            let state = gameLedgerStore.latestState(for: gameId),
            let vote = state.drawVote,
            let actor = localActorIdentifier(for: state),
            isCompatibleWithActiveConversation(state)
        else {
            return false
        }
        return state.isActivePlayer(actor) && !vote.approvals.contains(actor)
    }

    func voteOnDraw(for gameId: String, approve: Bool) {
        publishLifecycleChange(
            gameId: gameId,
            intent: { .voteDraw(approve: approve, anchoredTo: $0) },
            receipt: { state, actor in
                TranscriptBubbleCopyBuilder.drawVote(
                    resultingState: state,
                    actor: actor,
                    approved: approve
                )
            },
            successStatus: approve ? "Published draw approval" : "Published draw rejection"
        )
    }

    func canHostEndGame(_ gameId: String) -> Bool {
        guard
            let state = gameLedgerStore.latestState(for: gameId),
            state.phase == .setup || state.phase == .turn,
            let actor = localActorIdentifier(for: state),
            isCompatibleWithActiveConversation(state)
        else {
            return false
        }
        return actor == state.hostPlayer
    }

    func shouldOfferDrawBeforeHostEnd(_ gameId: String) -> Bool {
        guard let state = gameLedgerStore.latestState(for: gameId) else {
            return false
        }
        return !state.hasAttemptedDrawVote && state.drawVote == nil
    }

    func hostEndGame(_ gameId: String) {
        publishLifecycleChange(
            gameId: gameId,
            intent: { .endGame(anchoredTo: $0) },
            receipt: { state, actor in
                TranscriptBubbleCopyBuilder.hostEnded(
                    resultingState: state,
                    actor: actor
                )
            },
            successStatus: "Published host end"
        )
    }

    private func publishLifecycleChange(
        gameId: String,
        intent: (CoreGameStateV1) -> GameLifecycleIntentV1,
        receipt: (CoreGameStateV1, String) -> TranscriptBubbleCopy,
        successStatus: String
    ) {
        guard
            let fromState = gameLedgerStore.latestState(for: gameId),
            let actor = localActorIdentifier(for: fromState),
            isCompatibleWithActiveConversation(fromState)
        else {
            setLastError("Open this game from its original group chat before taking that action.")
            return
        }

        do {
            let toState = try ULS_CoreGame.apply(
                intent: intent(fromState),
                to: fromState,
                actor: actor
            )
            try validateTransition(from: fromState, to: toState, actor: actor)
            let payload = try jsonString(from: toState)
            let envelope = EnvelopeV1(kind: .state, body: .state(payload: payload))
            try sendEnvelope(
                envelope,
                bubbleCopy: receipt(toState, actor),
                sessionPolicy: .state(gameId: toState.gameId)
            )
            setActiveContext(toState, source: .lastSentState)
            selectionStatus = "\(successStatus) rev\(toState.rev)"
            setLastError(nil)
        } catch {
            setLastError("Game action failed: \(error.localizedDescription)")
        }
    }

    func archiveRecoveredGame(_ gameId: String) {
        gameLedgerStore.archive(gameId: gameId)
        latestKnownStatesByGameId.removeValue(forKey: gameId)
        stateSessionsByGameId.removeValue(forKey: gameId)

        if selectedState?.gameId == gameId {
            clearActiveContext()
            selectionStatus = "Archived local game"
        } else {
            refreshRecoveredGames()
        }
        setLastError(nil)
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
        #if DEBUG
        if uxTestingIsActive {
            let fixtureState = selectedState.flatMap { state in
                resolvedGameId == nil || state.gameId == resolvedGameId ? state : nil
            }
            return ActionAuthoringStateResolution(
                state: fixtureState,
                source: fixtureState == nil ? nil : .selectedState,
                prefersRecoveredState: false
            )
        }
        #endif
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
        selectionStatus = "Decoded game rev\(state.rev) via \(source.label)"
        updateGameplayShellProjection(
            GameShellProjectionBuilder.build(
                state: state,
                actingAs: localActorIdentifier(),
                actionAvailability: shellActionAvailability,
                modeAvailability: shellModeAvailability
            )
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

    private func defaultMaritimeTrade(
        for actor: String,
        from state: CoreGameStateV1
    ) -> (give: ResourceHandV1, receive: ResourceHandV1, ratio: Int)? {
        guard let maritime = state.defaultMaritimeTrade(for: actor) else {
            return nil
        }
        return (
            give: maritime.give,
            receive: maritime.receive,
            ratio: maritime.ratio
        )
    }

    private func payloadValue(from message: MSMessage) -> TranscriptDecodedPayload? {
        TranscriptTransportSupport.decodePayload(from: message.url)
    }

    private func sendEnvelope(
        _ envelope: EnvelopeV1,
        bubbleCopy: TranscriptBubbleCopy,
        sessionPolicy: TranscriptSessionPolicy,
        postPublishEffect: PostPublishEffect = .none,
        permitsRecoverySessionStart: Bool = false
    ) throws {
        #if DEBUG
        if uxTestingIsActive {
            try applyUXTestingEnvelope(envelope, bubbleCopy: bubbleCopy)
            return
        }
        #endif

        guard let conversation = activeConversation else {
            throw SendError.noActiveConversation
        }

        let encodedEnvelope = try encode(envelope)
        let bubbleImage = TranscriptBubbleImageRenderer.render(visual: bubbleCopy.visual)
        let builtMessage = try TranscriptTransportSupport.buildMessage(
            encodedEnvelope: encodedEnvelope,
            caption: bubbleCopy.caption,
            summaryLabel: bubbleCopy.summary,
            image: bubbleImage,
            session: try session(
                for: sessionPolicy,
                permitsRecoverySessionStart: permitsRecoverySessionStart
            ),
            sessionPolicy: sessionPolicy
        )
        let localLedgerStateRecord = localLedgerStateRecord(from: envelope)

        publish(
            builtMessage.message,
            into: conversation,
            envelopeKind: envelope.kind,
            sessionPolicy: builtMessage.sessionPolicy,
            localLedgerStateRecord: localLedgerStateRecord,
            postPublishEffect: postPublishEffect
        )
    }

    #if DEBUG
    private func applyUXTestingEnvelope(
        _ envelope: EnvelopeV1,
        bubbleCopy: TranscriptBubbleCopy
    ) throws {
        guard case let .state(payload) = envelope.body else {
            setLastError("UX Lab only applies STATE publishes locally.")
            return
        }

        let state = try decodePayload(CoreGameStateV1.self, from: payload)
        gameLedgerStore.record(state: state, payload: payload)
        if uxTestingFollowsTurnOwner, state.roster.contains(state.currentPlayer) {
            uxTestingActorID = state.currentPlayer
        } else if !state.roster.contains(uxTestingActorID) {
            uxTestingActorID = state.roster.first ?? uxTestingActorID
        }
        setActiveContext(state, source: .uxTesting)
        selectionStatus = "UX Lab applied \(bubbleCopy.caption)"
        setLastError(nil)
        runUXTestingAutoplayIfNeeded()
    }
    #endif

    private func publish(
        _ message: MSMessage,
        into conversation: MSConversation,
        envelopeKind _: EnvelopeV1.Kind,
        sessionPolicy _: TranscriptSessionPolicy,
        localLedgerStateRecord: Data?,
        postPublishEffect: PostPublishEffect
    ) {
        conversation.send(message) { [weak self] error in
            Task { @MainActor in
                guard let self else { return }
                self.isSendingInvite = false
                if let error {
                    self.setLastError("Publish failed: \(error.localizedDescription)")
                } else {
                    if let localLedgerStateRecord {
                        self.cacheLocalLedgerStateRecord(localLedgerStateRecord)
                    }
                    self.apply(postPublishEffect: postPublishEffect)
                }
            }
        }
    }

    func requestExtensionDismissal() {
        dismissRequestToken += 1
        onRequestDismiss?()
    }

    private func apply(postPublishEffect: PostPublishEffect) {
        switch postPublishEffect {
        case .none:
            break
        case .dismissExtension:
            requestExtensionDismissal()
        }
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

    private func normalizedLobbyDisplayNameDraft() -> String? {
        CoreGameStateV1.normalizedPlayerDisplayName(lobbyDisplayNameDraft)
    }

    private func persistPreferredLobbyDisplayNameIfPresent(_ displayName: String?) {
        guard let displayName else {
            return
        }
        lobbyDisplayNamePreferenceStore.save(displayName)
    }

    private func localActorIdentifier() -> String? {
        localActorIdentifier(for: selectedState)
    }

    private func localActorIdentifier(for state: CoreGameStateV1?) -> String? {
        if let tutorialActorID, let state, state.roster.contains(tutorialActorID) {
            return tutorialActorID
        }

        #if DEBUG
        if uxTestingIsActive, let state, state.roster.contains(uxTestingActorID) {
            return uxTestingActorID
        }
        #endif

        return ProductActorResolver.resolve(
            localParticipant: localParticipantIdentifier(),
            state: state
        )
    }

    private func isCompatibleWithActiveConversation(_ state: CoreGameStateV1) -> Bool {
        #if DEBUG
        if uxTestingIsActive {
            return true
        }
        #endif

        guard let activeConversation else {
            return false
        }

        let participantIDs = Set(
            [activeConversation.localParticipantIdentifier.uuidString]
                + activeConversation.remoteParticipantIdentifiers.map(\.uuidString)
        )
        return Set(state.roster).isSubset(of: participantIDs)
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

    private func localParticipantIdentifier() -> String? {
        #if DEBUG
        if uxTestingIsActive {
            return uxTestingActorID
        }
        #endif

        return activeConversation?.localParticipantIdentifier.uuidString
    }

    private func currentGameId() -> String? {
        selectedState?.gameId
    }

    private func rememberObservedJoiner(_ joiner: String, for gameId: String) {
        gameLedgerStore.recordJoin(actor: joiner, gameId: gameId)
        refreshRecoveredGames()
    }

    private func refreshRecoveredGames() {
        recoveredGames = gameLedgerStore.recoveredStates().map { recovered in
            ActiveGameRecoveryModelBuilder.build(
                from: recovered.state,
                updatedAt: recovered.updatedAt,
                isLastActive: recovered.isLastActive,
                isCurrentSelection: recovered.state.gameId == selectedState?.gameId
            )
        }
    }

    @discardableResult
    private func applyAndPublishTurnIntent(
        _ draft: TurnActionDraft,
        successStatus: String
    ) throws -> CoreGameStateV1 {
        let resolution = actionAuthoringStateResolution(for: draft.anchorGameId)
        activateAuthoringStateIfNeeded(resolution)

        guard let fromState = resolution.state ?? selectedState else {
            throw NSError(domain: "LobbyDriverViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "No active context."])
        }
        guard localActorIdentifier(for: fromState) != nil else {
            throw NSError(domain: "LobbyDriverViewModel", code: 2, userInfo: [NSLocalizedDescriptionKey: "This device has not joined the selected game."])
        }
        guard draft.matches(fromState) else {
            throw NSError(domain: "LobbyDriverViewModel", code: 3, userInfo: [NSLocalizedDescriptionKey: "Turn intent anchor does not match Active Context."])
        }

        let toState = try ULS_CoreGame.apply(intent: draft.intent, to: fromState, actor: draft.actor)
        try validateTransition(from: fromState, to: toState, actor: draft.actor)

        let payload = try jsonString(from: toState)
        let envelope = EnvelopeV1(kind: .state, body: .state(payload: payload))
        try sendEnvelope(
            envelope,
            bubbleCopy: TranscriptBubbleCopyBuilder.turnIntent(
                draft.intent,
                actor: draft.actor,
                resultingState: toState
            ),
            sessionPolicy: .state(gameId: toState.gameId)
        )
        setActiveContext(toState, source: .lastSentState)
        selectionStatus = "\(successStatus) rev\(toState.rev)"
        setLastError(nil)
        return toState
    }

    private func publishTradeResponse(_ draft: TurnActionDraft) throws {
        guard TradeResponsePublicationResolver.resolve(draft) != nil else {
            throw SendError.invalidIntentPayload
        }
        try applyAndPublishTurnIntent(
            draft,
            successStatus: successStatus(for: draft.intent)
        )
    }

    private func immediateTurnIntent(for actionKind: GameActionDockItem.Kind) -> TurnActionDraft? {
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
            return TurnActionDraft(
                intent: .rollDice,
                actor: authoringActor,
                state: authoringState
            )
        case .endTurn:
            guard authoringState.turnState?.step == .afterRoll else {
                return nil
            }
            return TurnActionDraft(
                intent: .endTurn,
                actor: authoringActor,
                state: authoringState
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

    private func successStatus(for intent: TurnIntentV1) -> String {
        switch intent {
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
        #if DEBUG
        uxTestingLastRawError = message ?? "-"
        #endif
        guard let message else {
            lastError = "-"
            return
        }

        #if DEBUG
        print("[Unlucky Sevens] \(message)")
        if message.contains("UX Lab") || message.contains("autoplay") {
            lastError = message
            return
        }
        #endif

        lastError = PlayerFacingErrorCopy.message(for: message)
    }

    private func playerFacingRecoveryErrorMessage(for error: Error) -> String {
        if
            let transportError = error as? TransportError,
            case .unsupportedVersion = transportError
        {
            return "Unsupported transport version."
        }
        if
            let coreError = error as? CoreGameError,
            coreError == .invalidStateHash
        {
            return "Invalid canonical state hash."
        }
        return "Malformed game payload."
    }

    private func session(
        for policy: TranscriptSessionPolicy,
        permitsRecoverySessionStart: Bool
    ) throws -> MSSession {
        switch policy {
        case .new:
            return MSSession()
        case let .state(gameId):
            let selected = activeConversation?.selectedMessage
            let selectedGameId = selected.flatMap(gameIdEncodedInMessage)
            let binding = TranscriptRecoverySessionBinding.resolve(
                gameId: gameId,
                selectedMessageGameId: selectedGameId,
                hasSelectedMessageSession: selected?.session != nil,
                hasCachedSession: stateSessionsByGameId[gameId] != nil
            )

            switch binding {
            case .cached:
                guard let cached = stateSessionsByGameId[gameId] else {
                    throw SendError.recoverySessionUnbound
                }
                return cached
            case .selectedMessage:
                guard let selectedSession = selected?.session else {
                    throw SendError.recoverySessionUnbound
                }
                stateSessionsByGameId[gameId] = selectedSession
                unboundRecoveredGameIds.remove(gameId)
                return selectedSession
            case .unbound:
                guard TranscriptRecoverySessionBinding.permitsNewSession(
                    isMarkedRecoveryUnbound: unboundRecoveredGameIds.contains(gameId),
                    isExplicitReconnect: permitsRecoverySessionStart
                ) else {
                    throw SendError.recoverySessionUnbound
                }
                let newSession = MSSession()
                stateSessionsByGameId[gameId] = newSession
                unboundRecoveredGameIds.remove(gameId)
                return newSession
            }
        }
    }

    private func bindRecoveredSessionIfAvailable(for gameId: String) {
        let selected = activeConversation?.selectedMessage
        let selectedGameId = selected.flatMap(gameIdEncodedInMessage)
        let binding = TranscriptRecoverySessionBinding.resolve(
            gameId: gameId,
            selectedMessageGameId: selectedGameId,
            hasSelectedMessageSession: selected?.session != nil,
            hasCachedSession: stateSessionsByGameId[gameId] != nil
        )

        switch binding {
        case .cached:
            unboundRecoveredGameIds.remove(gameId)
        case .selectedMessage:
            if let selectedSession = selected?.session {
                stateSessionsByGameId[gameId] = selectedSession
                unboundRecoveredGameIds.remove(gameId)
            }
        case .unbound:
            unboundRecoveredGameIds.insert(gameId)
        }
    }

    private func gameIdEncodedInMessage(_ message: MSMessage) -> String? {
        guard
            let encoded = payloadValue(from: message),
            let envelope = try? decode(encoded.payload),
            case let .state(payload) = envelope.body,
            let state = try? decodePayload(CoreGameStateV1.self, from: payload)
        else {
            return nil
        }
        return state.gameId
    }

    private enum ActiveContextSource {
        case selectedBubble
        case receivedMessage
        case latestKnownState
        case lastSentState
        case localLedgerState
        case uxTesting
        case tutorial

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
            case .uxTesting:
                return "uxTesting"
            case .tutorial:
                return "tutorial"
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
        case recoverySessionUnbound

        var errorDescription: String? {
            switch self {
            case .noActiveConversation:
                return "No active conversation."
            case .invalidJSONPayload:
                return "Could not create JSON payload string."
            case .invalidIntentPayload:
                return "Intent payload is missing required fields."
            case .recoverySessionUnbound:
                return "Reconnect this game to the chat from Your Games before making a move."
            }
        }
    }
}
