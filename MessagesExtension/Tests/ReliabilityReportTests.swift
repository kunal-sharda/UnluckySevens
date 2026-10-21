import Foundation
import ULS_CoreGame
import XCTest
@testable import MessagesExtensionSupport

@MainActor
final class ReliabilityReportTests: XCTestCase {
    private let date = Date(timeIntervalSince1970: 1000)
    private var metadata: ReliabilityReport.Metadata {
        .init(version: "1.0", build: "9", candidate: String(repeating: "a", count: 40), configuration: "release", osVersion: "26.0")
    }

    private func state(game: String = "private-game", revision: Int = 1) -> CoreGameStateV1 {
        CoreGameStateV1(gameId: game, rev: revision, prevHash: nil, stateHash: "", roster: ["private-host", "private-guest"],
                        currentPlayer: "private-host", phase: .lobby, seed: 1, diceRngState: 1,
                        resourcesByPlayer: ["private-host": ResourceHandV1(wood: 4)]).rehashed()
    }

    private func directory() throws -> URL {
        let value = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: value, withIntermediateDirectories: true)
        addTeardownBlock { try? FileManager.default.removeItem(at: value) }
        return value
    }

    func testImmutablePreviewExportAndExactReportAllowlist() throws {
        let collector = ReliabilityDiagnostics(directory: try directory(), metadata: metadata, at: date)
        let current = state()
        collector.record(state: current, actor: "private-host", action: .reopen, boundary: .stateSelection,
                         outcome: .accepted, trigger: .didSelect, sessionPresent: true, at: date)
        collector.record(state: state(game: "unrelated-game"), actor: nil, action: .publication,
                         boundary: .localHandoff, outcome: .failed, at: date)
        let data = try XCTUnwrap(collector.report(gameID: current.gameId, at: date))
        let report = try JSONDecoder().decode(ReliabilityReport.self, from: data)
        XCTAssertEqual(report.records.count, 1)
        XCTAssertEqual(report.records[0].observation.actorMembership, .joined)
        XCTAssertEqual(report.records[0].observation.trigger, .didSelect)
        XCTAssertEqual(report.records[0].observation.stateDigest?.count, 64)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertEqual(Set(object.keys), ["schemaVersion", "metadata", "game", "records"])
        let text = try XCTUnwrap(String(data: data, encoding: .utf8))
        for secret in ["private-game", "private-host", "private-guest", "unrelated-game", current.stateHash, "resourcesByPlayer"] {
            XCTAssertFalse(text.contains(secret))
        }
        let document = ReliabilityReportDocument(data: data)
        XCTAssertEqual(document.data, data)
        XCTAssertTrue(collector.clear())
        XCTAssertEqual(document.data, data, "Preview bytes must not change after clear or later collection.")
        let empty = try XCTUnwrap(collector.report(gameID: current.gameId, at: date))
        XCTAssertTrue(try JSONDecoder().decode(ReliabilityReport.self, from: empty).records.isEmpty)
    }

    func testStateCorrelationAgreesAcrossActorsButSeparatesGamesAndRevisions() throws {
        let root = try directory()
        let collector = ReliabilityDiagnostics(directory: root, metadata: metadata, at: date)
        collector.record(state: state(), actor: "private-host", action: .reopen, boundary: .stateSelection, outcome: .accepted, at: date)
        collector.record(state: state(), actor: "private-guest", action: .publication, boundary: .localHandoff, outcome: .accepted, at: date)
        let report = try JSONDecoder().decode(ReliabilityReport.self, from: XCTUnwrap(collector.report(gameID: "private-game", at: date)))
        XCTAssertEqual(report.records[0].observation.stateDigest, report.records[1].observation.stateDigest)
        XCTAssertNotEqual(report.records[0].observation.boundary, report.records[1].observation.boundary)
        let other = ReliabilityDiagnostics.observation(state: state(revision: 2), actor: nil, action: .reopen, boundary: .stateSelection, outcome: .observed)
        XCTAssertNotEqual(other?.stateDigest, report.records[0].observation.stateDigest)
        let restored = ReliabilityDiagnostics(directory: root, metadata: metadata, at: date)
        XCTAssertEqual(try restored.report(gameID: "private-game", at: date).map { try JSONDecoder().decode(ReliabilityReport.self, from: $0).records.count }, 2)
    }

    func testNewCandidateCannotRelabelPersistedOldObservations() throws {
        let root = try directory()
        let old = ReliabilityDiagnostics(directory: root, metadata: metadata, at: date)
        old.record(state: state(), actor: "private-host", action: .reopen, boundary: .stateSelection,
                   outcome: .accepted, trigger: .didSelect, sessionPresent: true, at: date)
        let nextMetadata = ReliabilityReport.Metadata(version: "1.0", build: "10", candidate: String(repeating: "b", count: 40),
                                                      configuration: "release", osVersion: "26.0")
        let updated = ReliabilityDiagnostics(directory: root, metadata: nextMetadata, at: date)
        let data = try XCTUnwrap(updated.report(gameID: "private-game", at: date))
        let report = try JSONDecoder().decode(ReliabilityReport.self, from: data)
        XCTAssertEqual(report.metadata, nextMetadata)
        XCTAssertTrue(report.records.isEmpty, "Prior candidate evidence must not acquire current metadata.")
    }

    func testMetadataAndPrettyPrintedRecordsRemainWithinWholeReportLimit() throws {
        let collector = ReliabilityDiagnostics(directory: try directory(), metadata: metadata, at: date)
        for revision in 0..<200 {
            collector.record(state: state(revision: revision), actor: nil, action: .reopen, boundary: .stateSelection, outcome: .observed,
                             trigger: .reload, sessionPresent: true, at: date)
        }
        let data = try XCTUnwrap(collector.report(gameID: "private-game", at: date))
        XCTAssertLessThanOrEqual(data.count, ReliabilityDiagnosticBuffer.maximumExportBytes)
        let report = try JSONDecoder().decode(ReliabilityReport.self, from: data)
        XCTAssertLessThanOrEqual(report.records.count, 128)
        XCTAssertEqual(report.records.last?.observation.revision, 199)
        XCTAssertEqual(report.metadata, metadata)
    }

    func testStorageFailureStillProvidesReportWithoutAlteringState() throws {
        let root = try directory().appendingPathComponent("not-a-directory")
        try Data([1]).write(to: root)
        let collector = ReliabilityDiagnostics(directory: root, metadata: metadata, at: date)
        let original = state()
        collector.record(state: original, actor: nil, action: .publication, boundary: .localHandoff, outcome: .failed, at: date)
        XCTAssertTrue(collector.storageUnavailable)
        XCTAssertNotNil(collector.report(gameID: original.gameId, at: date))
        XCTAssertEqual(original, state())
        XCTAssertFalse(collector.clear())
    }
}
