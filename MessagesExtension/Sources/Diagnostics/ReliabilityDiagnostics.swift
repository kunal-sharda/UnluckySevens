import CryptoKit
import Foundation
import ULS_CoreGame

/// Main-actor owner; diagnostic failures remain separate from gameplay and publication.
@MainActor
final class ReliabilityDiagnostics {
    private var store: ReliabilityDiagnosticStore
    let metadata: ReliabilityReport.Metadata

    init(directory: URL, metadata: ReliabilityReport.Metadata, at date: Date = Date()) {
        let identity = [metadata.version, metadata.build, metadata.candidate, metadata.configuration].joined(separator: "\0")
        let provenance = SHA256.hash(data: Data(identity.utf8)).map { String(format: "%02x", $0) }.joined()
        store = ReliabilityDiagnosticStore(directory: directory, at: date, provenance: provenance)
        self.metadata = metadata
    }

    static func production() -> ReliabilityDiagnostics {
        let bundle = Bundle.main
        #if DEBUG
        let configuration = "debug"
        #else
        let configuration = "release"
        #endif
        let root = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return ReliabilityDiagnostics(
            directory: root.appendingPathComponent("Reliability", isDirectory: true),
            metadata: .init(
                version: bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown",
                build: bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "unknown",
                candidate: bundle.object(forInfoDictionaryKey: "ULSReliabilityCandidate") as? String ?? "unfrozen",
                configuration: configuration,
                osVersion: ProcessInfo.processInfo.operatingSystemVersionString
            )
        )
    }

    func record(
        state: CoreGameStateV1,
        actor: String?,
        action: ReliabilityDiagnosticBuffer.Action,
        boundary: ReliabilityDiagnosticBuffer.Boundary,
        outcome: ReliabilityDiagnosticBuffer.Outcome,
        trigger: ReliabilityDiagnosticBuffer.Trigger? = nil,
        sessionPresent: Bool? = nil,
        at date: Date = Date()
    ) {
        guard let observation = Self.observation(state: state, actor: actor, action: action, boundary: boundary,
                                                 outcome: outcome, trigger: trigger, sessionPresent: sessionPresent) else { return }
        record(observation, at: date)
    }

    func record(_ observation: ReliabilityDiagnosticBuffer.Observation, at date: Date = Date()) {
        store.append(observation, at: date)
    }

    static func observation(
        state: CoreGameStateV1, actor: String?, action: ReliabilityDiagnosticBuffer.Action,
        boundary: ReliabilityDiagnosticBuffer.Boundary, outcome: ReliabilityDiagnosticBuffer.Outcome,
        trigger: ReliabilityDiagnosticBuffer.Trigger? = nil, sessionPresent: Bool? = nil
    ) -> ReliabilityDiagnosticBuffer.Observation? {
        guard state.rev >= 0 else { return nil }
        let membership: ReliabilityDiagnosticBuffer.ActorMembership = actor.map {
            state.roster.contains($0) ? .joined : .notInRoster
        } ?? .unavailable
        // Correlate state only within a game; do not export its canonical hash or raw payload.
        let digest = SHA256.hash(data: Data(("uls-reliability-state-v1\0" + state.gameId + "\0" + state.stateHash).utf8))
            .map { String(format: "%02x", $0) }.joined()
        return .init(
            game: .init(gameID: state.gameId), revision: UInt64(state.rev),
            action: action, boundary: boundary, outcome: outcome, actorMembership: membership,
            stateDigest: digest, trigger: trigger, sessionPresent: sessionPresent
        )
    }

    func report(gameID: String, at date: Date = Date()) -> Data? {
        let game = ReliabilityDiagnosticBuffer.GameToken(gameID: gameID)
        guard store.export(game: game, at: date) != nil else { return nil }
        return ReliabilityReport.make(metadata: metadata, game: game, records: store.buffer.records)
    }

    var storageUnavailable: Bool { store.status == .unavailable }

    @discardableResult
    func clear() -> Bool {
        store.clear()
        return store.status != .unavailable
    }
}
