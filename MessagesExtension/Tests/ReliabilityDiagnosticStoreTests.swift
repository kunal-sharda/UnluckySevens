import Foundation
import XCTest
@testable import MessagesExtensionSupport

final class ReliabilityDiagnosticStoreTests: XCTestCase {
    private typealias Buffer = ReliabilityDiagnosticBuffer
    private var directory: URL!
    private let now = Date(timeIntervalSince1970: 1_000_000)
    private var fileURL: URL { directory.appendingPathComponent("reliability-v1.json") }

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try FileManager.default.removeItem(at: directory)
    }

    private func observation(game: String = "private-game", revision: UInt64 = 1) -> Buffer.Observation {
        .init(game: .init(gameID: game), revision: revision, action: .trade,
              boundary: .localHandoff, outcome: .accepted, actorMembership: .joined)
    }

    func testReopenPreservesRecordsSequenceAndSingleGameExport() throws {
        var store = ReliabilityDiagnosticStore(directory: directory, at: now)
        store.append(observation(), at: now)
        store.append(observation(game: "other"), at: now)
        XCTAssertEqual(store.status, .ready)
        var reopened = ReliabilityDiagnosticStore(directory: directory, at: now)
        XCTAssertEqual(reopened.buffer.records.count, 2)
        reopened.append(observation(revision: 2), at: now)
        XCTAssertEqual(reopened.buffer.records.last?.sequence, 2)
        let data = try XCTUnwrap(reopened.export(game: .init(gameID: "private-game"), at: now))
        let text = String(decoding: data, as: UTF8.self)
        XCTAssertFalse(text.contains("private-game"))
        XCTAssertFalse(text.contains(Buffer.GameToken(gameID: "other").digest))
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertEqual((json["records"] as? [Any])?.count, 2)
        XCTAssertEqual(try directory.resourceValues(forKeys: [.isExcludedFromBackupKey]).isExcludedFromBackup, true)
    }

    func testReopenPrunesExpiredAndFutureRecordsOnDisk() throws {
        for reopenDate in [now.addingTimeInterval(Buffer.maximumAge), now.addingTimeInterval(-1)] {
            var store = ReliabilityDiagnosticStore(directory: directory, at: now)
            store.append(observation(), at: now)
            let reopened = ReliabilityDiagnosticStore(directory: directory, at: reopenDate)
            XCTAssertEqual(reopened.status, .ready)
            XCTAssertTrue(reopened.buffer.records.isEmpty)
            let restored = try XCTUnwrap(Buffer.restore(Data(contentsOf: fileURL), at: now))
            XCTAssertTrue(restored.records.isEmpty)
        }
    }

    func testCorruptAndOversizedFilesRecoverWithoutExportingInput() throws {
        for data in [Data("private corrupt text".utf8), Data(repeating: 65, count: Buffer.maximumExportBytes + 1)] {
            try data.write(to: fileURL)
            var store = ReliabilityDiagnosticStore(directory: directory, at: now)
            XCTAssertEqual(store.status, .recoveredCorruption)
            XCTAssertTrue(store.buffer.records.isEmpty)
            XCTAssertFalse(FileManager.default.fileExists(atPath: fileURL.path))
            store.append(observation(), at: now)
            XCTAssertEqual(store.status, .ready)
            XCTAssertEqual(ReliabilityDiagnosticStore(directory: directory, at: now).buffer.records.count, 1)
        }
    }

    func testMalformedSnapshotsAreRejected() throws {
        var buffer = Buffer()
        buffer.append(observation(), at: now)
        let data = try XCTUnwrap(buffer.snapshot(at: now))
        let original = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let originalRecords = try XCTUnwrap(original["records"] as? [[String: Any]])
        var candidates: [[String: Any]] = []
        var changed = original
        changed["schemaVersion"] = 2
        candidates.append(changed)
        changed = original
        changed["records"] = Array(repeating: originalRecords[0], count: 129)
        candidates.append(changed)
        changed = original
        changed["records"] = [originalRecords[0], originalRecords[0]]
        candidates.append(changed)
        for field in ["game", "action", "boundary", "outcome", "actorMembership"] {
            var record = originalRecords[0]
            var observation = try XCTUnwrap(record["observation"] as? [String: Any])
            observation[field] = field == "game" ? ["digest": "raw-private-id"] : "unknown-private-value"
            record["observation"] = observation
            changed = original
            changed["records"] = [record]
            candidates.append(changed)
        }
        for candidate in candidates {
            try JSONSerialization.data(withJSONObject: candidate).write(to: fileURL)
            let store = ReliabilityDiagnosticStore(directory: directory, at: now)
            XCTAssertEqual(store.status, .recoveredCorruption)
            XCTAssertTrue(store.buffer.records.isEmpty)
        }
    }

    func testCountAndDiskSizeStayBoundedAcrossReopen() throws {
        var store = ReliabilityDiagnosticStore(directory: directory, at: now)
        for n in 0..<150 { store.append(observation(revision: UInt64(n)), at: now) }
        XCTAssertLessThanOrEqual(try Data(contentsOf: fileURL).count, Buffer.maximumExportBytes)
        let reopened = ReliabilityDiagnosticStore(directory: directory, at: now)
        XCTAssertEqual(reopened.buffer.records.count, 128)
        XCTAssertEqual(reopened.buffer.records.first?.sequence, 22)
    }

    func testClearRemovesDiskAndMemoryAndAllowsReuse() {
        var store = ReliabilityDiagnosticStore(directory: directory, at: now)
        store.append(observation(), at: now)
        store.clear()
        XCTAssertEqual(store.status, .ready)
        XCTAssertTrue(store.buffer.records.isEmpty)
        XCTAssertFalse(FileManager.default.fileExists(atPath: fileURL.path))
        XCTAssertTrue(ReliabilityDiagnosticStore(directory: directory, at: now).buffer.records.isEmpty)
        store.clear()
        store.append(observation(), at: now)
        XCTAssertEqual(store.buffer.records.first?.sequence, 0)
    }

    func testUnreadableStorageAndFailedClearReportUnavailable() throws {
        var store = ReliabilityDiagnosticStore(directory: directory, at: now)
        store.append(observation(), at: now)
        try FileManager.default.setAttributes([.posixPermissions: 0o000], ofItemAtPath: fileURL.path)
        defer { try? FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: fileURL.path) }
        XCTAssertEqual(ReliabilityDiagnosticStore(directory: directory, at: now).status, .unavailable)
        try FileManager.default.setAttributes([.posixPermissions: 0o500], ofItemAtPath: directory.path)
        defer { try? FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: directory.path) }
        store.clear()
        XCTAssertEqual(store.status, .unavailable)
        XCTAssertTrue(store.buffer.records.isEmpty)
        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))
    }

    func testWriteFailureKeepsMemoryAndReturnsTypedFailure() throws {
        let blockedDirectory = directory.appendingPathComponent("regular-file")
        try Data("block".utf8).write(to: blockedDirectory)
        var store = ReliabilityDiagnosticStore(directory: blockedDirectory, at: now)
        store.append(observation(), at: now)
        XCTAssertEqual(store.status, .unavailable)
        XCTAssertEqual(store.buffer.records.count, 1)
        XCTAssertNotNil(store.export(game: .init(gameID: "private-game"), at: now))
        XCTAssertEqual(store.status, .unavailable)
    }
}
