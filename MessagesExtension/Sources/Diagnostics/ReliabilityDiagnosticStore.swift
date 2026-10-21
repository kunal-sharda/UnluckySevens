import Foundation

/// A single-owner local store. Call from one serial context; never a canonical state source.
/// Collection wiring chooses its private directory. No automatic upload or gameplay callbacks.
struct ReliabilityDiagnosticStore {
    enum StorageStatus: Equatable {
        case ready, recoveredCorruption, unavailable
    }

    private(set) var buffer = ReliabilityDiagnosticBuffer()
    private(set) var status: StorageStatus = .ready
    private let fileURL: URL
    private let provenance: String?

    init(directory: URL, at date: Date, provenance: String? = nil) {
        self.provenance = provenance
        fileURL = directory.appendingPathComponent("reliability-v1.json", isDirectory: false)
        do {
            let handle = try FileHandle(forReadingFrom: fileURL)
            defer { try? handle.close() }
            // Bound the read itself, not just decoding, including oversized or corrupt input.
            let data = try handle.read(upToCount: ReliabilityDiagnosticBuffer.maximumExportBytes + 1) ?? Data()
            if let restored = ReliabilityDiagnosticBuffer.restore(data, at: date, provenance: provenance) {
                buffer = restored
                persist(at: date) // Remove expired/future records from disk on reopen.
            } else {
                try FileManager.default.removeItem(at: fileURL)
                status = .recoveredCorruption
            }
        } catch {
            status = Self.isMissingFile(error) ? .ready : .unavailable
        }
    }

    mutating func append(_ observation: ReliabilityDiagnosticBuffer.Observation, at date: Date) {
        buffer.append(observation, at: date)
        persist(at: date)
    }

    mutating func export(game: ReliabilityDiagnosticBuffer.GameToken, at date: Date) -> Data? {
        let data = buffer.export(game: game, at: date)
        persist(at: date)
        return data
    }

    /// Failure means deletion was not confirmed; callers must not promise durable erasure.
    mutating func clear() {
        buffer.clear()
        do {
            try FileManager.default.removeItem(at: fileURL)
            status = .ready
        } catch {
            status = Self.isMissingFile(error) ? .ready : .unavailable
        }
    }

    private static func isMissingFile(_ error: Error) -> Bool {
        let error = error as NSError
        return error.domain == NSCocoaErrorDomain
            && (error.code == NSFileNoSuchFileError || error.code == NSFileReadNoSuchFileError)
    }

    private mutating func persist(at date: Date) {
        guard let data = buffer.snapshot(at: date, provenance: provenance) else {
            status = .unavailable
            return
        }
        do {
            let directory = fileURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            var excludedDirectory = directory
            var values = URLResourceValues()
            values.isExcludedFromBackup = true
            try excludedDirectory.setResourceValues(values)
            try data.write(to: fileURL, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
            status = .ready
        } catch {
            status = .unavailable
        }
    }
}
