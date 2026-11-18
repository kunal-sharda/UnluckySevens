import Foundation
import ULS_CoreGame

/// Device-local private receipts follow observed hash links, never revision numbers alone.
struct GameRollReceiptRecord: Codable, Equatable {
    let gameID: String
    let viewer: String
    var latestStateHash: String
    let receipt: ProductionReceiptV1
}

final class GameRollReceiptStore {
    private let defaults: UserDefaults
    private let key = "uls.privateRollReceipts.v1"

    init(defaults: UserDefaults) { self.defaults = defaults }

    func observe(_ state: CoreGameStateV1, previous: CoreGameStateV1?, viewer: String?) -> ProductionReceiptV1? {
        guard let viewer, state.roster.contains(viewer) else { return nil }
        var records = (defaults.data(forKey: key).flatMap {
            try? JSONDecoder().decode([GameRollReceiptRecord].self, from: $0)
        }) ?? []
        let index = records.firstIndex { $0.gameID == state.gameId && $0.viewer == viewer }
        var record = index.map { records[$0] }
        if let previous, let receipt = state.productionReceipt(from: previous, for: viewer) {
            record = GameRollReceiptRecord(gameID: state.gameId, viewer: viewer,
                                          latestStateHash: state.stateHash, receipt: receipt)
        } else if var prior = record, state.prevHash == prior.latestStateHash,
                  state.auditLog.last?.action != .rollDice {
            prior.latestStateHash = state.stateHash
            record = prior
        }
        guard let record, record.latestStateHash == state.stateHash else { return nil }
        if let index { records.remove(at: index) }
        records.append(record)
        defaults.set(try? JSONEncoder().encode(Array(records.suffix(100))), forKey: key)
        return record.receipt
    }
}
