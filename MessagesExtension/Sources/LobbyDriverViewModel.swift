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
    @Published var pendingJoiners: String = "[]"
    @Published var selectionStatus: String = "No message selected"
    @Published var lastError: String = "-"
    @Published var boardStrategy: BoardGenStrategyV1
    @Published var boardHash: String = "-"
    @Published var boardGenerator: String = "-"
    @Published var boardRobberTile: String = "-"
    @Published var boardResourcesByTile: String = "-"
    @Published var boardNumbersByTile: String = "-"
    @Published var boardPortsByIndex: String = "-"
    @Published var visibleHands: String = "-"
    @Published var bankResources: String = "-"
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

    var canJoin: Bool {
        selectedState?.phase == .lobby
    }

    var canRecordJoin: Bool {
        selectedJoinIntent != nil
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

    var hasBoardDebug: Bool {
        selectedState?.board != nil
    }

    func setBoardStrategy(_ strategy: BoardGenStrategyV1) {
        boardStrategy = strategy
        userDefaults.set(strategy.rawValue, forKey: boardStrategyKey)
    }

    func updateContext(conversation: MSConversation?, selectedMessage: MSMessage?) {
        activeConversation = conversation
        decodeSelectedMessage(selectedMessage)
    }

    func inviteNewGame() {
        guard let actor = localActorIdentifier() else {
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
        let boardSeed = seedDeriver.seed(for: .board)
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
            resourcesByPlayer: Dictionary(uniqueKeysWithValues: finalRoster.map { ($0, .zero) }),
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

    private func decodeSelectedMessage(_ message: MSMessage?) {
        selectedState = nil
        selectedJoinIntent = nil
        selectedSetupIntent = nil
        selectedTurnIntent = nil

        guard let message else {
            selectionStatus = "No message selected"
            resetDisplayedFields()
            refreshPendingJoiners(for: nil)
            return
        }

        guard let encodedEnvelope = payloadValue(from: message) else {
            selectionStatus = "Selected message has no transport payload"
            resetDisplayedFields()
            refreshPendingJoiners(for: nil)
            return
        }

        do {
            let envelope = try decode(encodedEnvelope.payload)
            try apply(envelope: envelope, message: message, source: encodedEnvelope.source)
            setLastError(nil)
        } catch {
            selectionStatus = "Failed to decode selected message"
            resetDisplayedFields()
            refreshPendingJoiners(for: nil)
            setLastError("Decode failed: \(error.localizedDescription)")
        }
    }

    private func apply(envelope: EnvelopeV1, message: MSMessage, source: PayloadSource) throws {
        switch envelope.body {
        case let .state(payload):
            let state = try decodePayload(CoreGameStateV1.self, from: payload)
            selectedState = state
            selectedJoinIntent = nil
            selectedSetupIntent = nil
            selectedTurnIntent = nil
            stateSessionsByGameId[state.gameId] = message.session
            render(state: state, source: source)
        case let .intent(payload):
            if let setupIntent = try? decodePayload(SetupPlacementIntentV1.self, from: payload) {
                selectedSetupIntent = setupIntent
                selectedJoinIntent = nil
                selectedState = nil
                selectedTurnIntent = nil
                render(setupIntent: setupIntent, source: source)
                return
            }

            if let turnIntent = try? decodePayload(ULS_Transport.TurnIntentV1.self, from: payload) {
                selectedTurnIntent = turnIntent
                selectedSetupIntent = nil
                selectedJoinIntent = nil
                selectedState = nil
                render(turnIntent: turnIntent, source: source)
                return
            }

            let intent = try decodePayload(JoinIntentV1.self, from: payload)
            selectedJoinIntent = intent
            selectedSetupIntent = nil
            selectedTurnIntent = nil
            selectedState = nil
            render(joinIntent: intent, source: source)
        }
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
        setupPlacement = "-"
        turnIntent = "-"
        visibleHands = visibleHandsSummary(for: state)
        bankResources = resourceHandDescription(state.bankResources)
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
        setupPlacement = "-"
        turnIntent = "-"
        visibleHands = "-"
        bankResources = "-"
        resetBoardDebugFields()
        selectionStatus = "Decoded JOIN intent via \(source.label)"
        refreshPendingJoiners(for: joinIntent.gameId)
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
        turnIntent = "-"
        visibleHands = "-"
        bankResources = "-"
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
        setupPlacement = "-"
        turnIntent = "kind: \(decodedTurnIntent.kind.rawValue)"
        visibleHands = "-"
        bankResources = "-"
        resetBoardDebugFields()
        selectionStatus = "Decoded \(decodedTurnIntent.kind.rawValue) intent via \(source.label)"
        refreshPendingJoiners(for: decodedTurnIntent.gameId)
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
        setupPlacement = "-"
        turnIntent = "-"
        visibleHands = "-"
        bankResources = "-"
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
        let localActor = localActorIdentifier()
        return state.roster.map { player in
            let hand = state.resourcesByPlayer[player] ?? .zero
            if localActor == player {
                return "\(player): \(resourceHandDescription(hand))"
            }
            return "\(player): \(hand.totalCount)"
        }.joined(separator: " | ")
    }

    private func resourceHandDescription(_ hand: ResourceHandV1) -> String {
        "w:\(hand.wood), b:\(hand.brick), s:\(hand.sheep), wh:\(hand.wheat), o:\(hand.ore)"
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

        var components = URLComponents()
        components.scheme = "unluckysevens"
        components.host = "msg"
        components.queryItems = [URLQueryItem(name: "payload", value: encodedEnvelope)]

        guard let url = components.url else {
            throw SendError.invalidURL
        }

        let message = MSMessage(session: session(for: sessionPolicy))
        message.url = url

        let layout = MSMessageTemplateLayout()
        layout.caption = caption
        message.layout = layout
        #if DEBUG && targetEnvironment(simulator)
        message.summaryText = "\(summaryPayloadPrefix)\(encodedEnvelope)"
        #endif

        conversation.insert(message) { [weak self] error in
            Task { @MainActor in
                guard let self else { return }
                if let error {
                    self.setLastError("Send failed: \(error.localizedDescription)")
                }
            }
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

    private struct DecodedPayloadSource {
        let payload: String
        let source: PayloadSource
    }

    private enum PayloadSource {
        case url
        case summaryFallback

        var label: String {
            switch self {
            case .url:
                return "URL"
            case .summaryFallback:
                return "summary fallback"
            }
        }
    }

    private enum SendError: LocalizedError {
        case noActiveConversation
        case invalidURL
        case invalidJSONPayload

        var errorDescription: String? {
            switch self {
            case .noActiveConversation:
                return "No active conversation."
            case .invalidURL:
                return "Could not build iMessage payload URL."
            case .invalidJSONPayload:
                return "Could not create JSON payload string."
            }
        }
    }
}
