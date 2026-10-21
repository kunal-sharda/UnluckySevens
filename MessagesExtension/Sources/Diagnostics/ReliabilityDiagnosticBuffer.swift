import CryptoKit
import Foundation

/// Local reliability data only. Not a state source, actor credential, or delivery receipt.
struct ReliabilityDiagnosticBuffer {
    struct GameToken: Codable, Equatable, Sendable {
        let digest: String

        init(gameID: String) {
            digest = SHA256.hash(data: Data(("uls-reliability-game-v1\0" + gameID).utf8))
                .map { String(format: "%02x", $0) }.joined()
        }
    }

    enum Action: String, Codable, Sendable {
        case invite, join, reconcile, setup, roll, build, trade, discard, robber
        case developmentCard, endTurn, lifecycle, reopen, recovery, publication
    }

    enum Boundary: String, Codable, Sendable {
        case eligibility, encoding, localHandoff, stateSelection, recovery
    }

    enum Outcome: String, Codable, Sendable {
        case observed, accepted, rejected, unavailable, failed
    }

    enum ActorMembership: String, Codable, Sendable {
        case joined, notInRoster, unavailable
    }

    enum Trigger: String, Codable, Sendable {
        case viewDidLoad, didSelect, didReceive, selectionPoll, reload
    }

    struct Observation: Codable, Equatable, Sendable {
        let game: GameToken
        let revision: UInt64
        let action: Action
        let boundary: Boundary
        var outcome: Outcome
        let actorMembership: ActorMembership
        var stateDigest: String? = nil
        var trigger: Trigger? = nil
        var sessionPresent: Bool? = nil
    }

    struct Record: Codable {
        let sequence: UInt64
        let timestamp: TimeInterval
        let observation: Observation
    }

    private struct Export: Encodable {
        let schemaVersion = 1
        let records: [Record]
    }

    static let maximumRecords = 128
    static let maximumAge: TimeInterval = 24 * 60 * 60
    static let maximumExportBytes = 64 * 1024
    private(set) var records: [Record] = []
    private var nextSequence: UInt64 = 0

    mutating func append(_ observation: Observation, at date: Date) {
        let timestamp = date.timeIntervalSince1970
        guard timestamp.isFinite else { return }
        prune(at: timestamp)
        if let last = records.last,
           last.observation == observation, timestamp - last.timestamp <= 1 {
            return
        }
        // Saturation cannot wrap and create a misleading sequence identifier.
        guard nextSequence < UInt64.max else { return }
        records.append(Record(sequence: nextSequence, timestamp: timestamp, observation: observation))
        nextSequence += 1
        if records.count > Self.maximumRecords {
            records.removeFirst(records.count - Self.maximumRecords)
        }
    }

    mutating func clear() {
        records.removeAll()
        nextSequence = 0
    }

    /// Same bytes can be previewed and exported later. No I/O or automatic send occurs here.
    mutating func export(game: GameToken, at date: Date) -> Data? {
        let timestamp = date.timeIntervalSince1970
        guard timestamp.isFinite else { return nil }
        prune(at: timestamp)
        var selected = records.filter { $0.observation.game == game }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        while let data = try? encoder.encode(Export(records: selected)) {
            if data.count <= Self.maximumExportBytes { return data }
            guard !selected.isEmpty else { return nil }
            selected.removeFirst()
        }
        return nil
    }

    private struct Snapshot: Codable {
        let schemaVersion: Int
        let provenance: String?
        let records: [Record]
    }

    /// Storage is separate from the single-game export projection.
    mutating func snapshot(at date: Date, provenance: String? = nil) -> Data? {
        guard date.timeIntervalSince1970.isFinite else { return nil }
        prune(at: date.timeIntervalSince1970)
        guard let data = try? JSONEncoder().encode(Snapshot(schemaVersion: 1, provenance: provenance, records: records)),
              data.count <= Self.maximumExportBytes else { return nil }
        return data
    }

    static func restore(_ data: Data, at date: Date, provenance: String? = nil) -> Self? {
        guard data.count <= maximumExportBytes, date.timeIntervalSince1970.isFinite,
              let snapshot = try? JSONDecoder().decode(Snapshot.self, from: data),
              snapshot.schemaVersion == 1, snapshot.provenance == provenance, snapshot.records.count <= maximumRecords else { return nil }
        var previous: Record?
        for record in snapshot.records {
            let digest = record.observation.game.digest
            guard digest.utf8.count == 64,
                  digest.utf8.allSatisfy({ (48...57).contains($0) || (97...102).contains($0) }),
                  record.timestamp.isFinite, record.sequence < UInt64.max else { return nil }
            if let stateDigest = record.observation.stateDigest {
                guard stateDigest.utf8.count == 64,
                      stateDigest.utf8.allSatisfy({ (48...57).contains($0) || (97...102).contains($0) }) else { return nil }
            }
            if let previous {
                guard record.sequence > previous.sequence, record.timestamp >= previous.timestamp else { return nil }
            }
            previous = record
        }
        var buffer = Self()
        buffer.records = snapshot.records
        buffer.nextSequence = snapshot.records.last.map { $0.sequence + 1 } ?? 0
        buffer.prune(at: date.timeIntervalSince1970)
        return buffer
    }

    private mutating func prune(at timestamp: TimeInterval) {
        records.removeAll { $0.timestamp > timestamp || timestamp - $0.timestamp >= Self.maximumAge }
    }
}
