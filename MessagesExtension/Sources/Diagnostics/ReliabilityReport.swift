import Foundation

/// Immutable preview/export bytes. Metadata describes the binary, never its delivery channel.
struct ReliabilityReport: Codable {
    struct Metadata: Codable, Equatable {
        let version: String
        let build: String
        let candidate: String
        let configuration: String
        let osVersion: String
    }

    let schemaVersion: Int
    let metadata: Metadata
    let game: ReliabilityDiagnosticBuffer.GameToken
    let records: [ReliabilityDiagnosticBuffer.Record]

    static func make(
        metadata: Metadata,
        game: ReliabilityDiagnosticBuffer.GameToken,
        records: [ReliabilityDiagnosticBuffer.Record]
    ) -> Data? {
        var selected = Array(records.filter { $0.observation.game == game }.suffix(ReliabilityDiagnosticBuffer.maximumRecords))
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
        while let data = try? encoder.encode(Self(schemaVersion: 2, metadata: metadata, game: game, records: selected)) {
            if data.count <= ReliabilityDiagnosticBuffer.maximumExportBytes { return data }
            guard !selected.isEmpty else { return nil }
            selected.removeFirst()
        }
        return nil
    }
}
