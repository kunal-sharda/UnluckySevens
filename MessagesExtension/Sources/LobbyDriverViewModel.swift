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
    @Published var pendingJoiners: String = "[]"
    @Published var selectionStatus: String = "No message selected"
    @Published var lastError: String = "-"

    private let summaryPayloadPrefix = "ulsenv:"
    private let userDefaults: UserDefaults

    private weak var activeConversation: MSConversation?
    private var selectedState: CoreGameStateV1?
    private var selectedJoinIntent: JoinIntentV1?

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
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
            seed: nil
        ).rehashed()

        do {
            let payload = try jsonString(from: state)
            let envelope = EnvelopeV1(kind: .state, body: .state(payload: payload))
            try sendEnvelope(envelope, caption: "ULS STATE rev0")
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
            try sendEnvelope(envelope, caption: "ULS INTENT join")
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

        let toState = CoreGameStateV1(
            gameId: fromState.gameId,
            rev: fromState.rev + 1,
            prevHash: fromState.stateHash,
            stateHash: "",
            roster: finalRoster,
            currentPlayer: inviter,
            phase: .setup,
            seed: UInt64.random(in: .min ... .max)
        ).rehashed()

        do {
            try validateTransition(from: fromState, to: toState, actor: inviter)
            let payload = try jsonString(from: toState)
            let envelope = EnvelopeV1(kind: .state, body: .state(payload: payload))
            try sendEnvelope(envelope, caption: "ULS STATE rev1")
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

    private func decodeSelectedMessage(_ message: MSMessage?) {
        selectedState = nil
        selectedJoinIntent = nil

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
            let envelope = try decode(encodedEnvelope)
            try apply(envelope: envelope)
            setLastError(nil)
        } catch {
            selectionStatus = "Failed to decode selected message"
            resetDisplayedFields()
            refreshPendingJoiners(for: nil)
            setLastError("Decode failed: \(error.localizedDescription)")
        }
    }

    private func apply(envelope: EnvelopeV1) throws {
        switch envelope.body {
        case let .state(payload):
            let state = try decodePayload(CoreGameStateV1.self, from: payload)
            selectedState = state
            selectedJoinIntent = nil
            render(state: state)
        case let .intent(payload):
            let intent = try decodePayload(JoinIntentV1.self, from: payload)
            selectedJoinIntent = intent
            selectedState = nil
            render(joinIntent: intent)
        }
    }

    private func render(state: CoreGameStateV1) {
        kind = "STATE"
        gameId = state.gameId
        rev = String(state.rev)
        prevHash = state.prevHash ?? "nil"
        stateHash = state.stateHash
        roster = state.roster.joined(separator: ", ")
        currentPlayer = state.currentPlayer
        phase = state.phase.rawValue
        seed = state.seed.map(String.init) ?? "nil"
        selectionStatus = "Decoded STATE rev\(state.rev)"
        refreshPendingJoiners(for: state.gameId)
    }

    private func render(joinIntent: JoinIntentV1) {
        kind = "INTENT(join)"
        gameId = joinIntent.gameId
        rev = String(joinIntent.anchorRev)
        prevHash = "-"
        stateHash = joinIntent.anchorHash
        roster = "-"
        currentPlayer = joinIntent.actor
        phase = "-"
        seed = "-"
        selectionStatus = "Decoded JOIN intent"
        refreshPendingJoiners(for: joinIntent.gameId)
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
    }

    private func payloadValue(from message: MSMessage) -> String? {
        if let url = message.url,
           let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let payload = components.queryItems?.first(where: { $0.name == "payload" })?.value,
           !payload.isEmpty {
            return payload
        }

        guard let summaryText = message.summaryText,
              summaryText.hasPrefix(summaryPayloadPrefix) else {
            return nil
        }

        let payloadStart = summaryText.index(summaryText.startIndex, offsetBy: summaryPayloadPrefix.count)
        let payload = String(summaryText[payloadStart...])
        return payload.isEmpty ? nil : payload
    }

    private func sendEnvelope(_ envelope: EnvelopeV1, caption: String) throws {
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

        let message = MSMessage(session: MSSession())
        message.url = url

        let layout = MSMessageTemplateLayout()
        layout.caption = caption
        message.layout = layout
        message.summaryText = "\(summaryPayloadPrefix)\(encodedEnvelope)"

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
