import Foundation
import XCTest
@testable import MessagesExtensionSupport

final class ReliabilityDiagnosticBufferTests: XCTestCase {
    private typealias Buffer = ReliabilityDiagnosticBuffer

    private func observation(game: String = "game-private-input", revision: UInt64 = 1) -> Buffer.Observation {
        .init(game: .init(gameID: game), revision: revision, action: .trade,
              boundary: .eligibility, outcome: .unavailable, actorMembership: .notInRoster)
    }

    func testSingleGameExportHasExactAllowlistAndNoRawIdentifier() throws {
        var buffer = Buffer()
        buffer.append(observation(), at: Date(timeIntervalSince1970: 100))
        buffer.append(observation(game: "unrelated-game"), at: Date(timeIntervalSince1970: 101))
        let data = try XCTUnwrap(buffer.export(game: .init(gameID: "game-private-input"), at: Date(timeIntervalSince1970: 102)))
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertEqual(Set(json.keys), ["schemaVersion", "records"])
        let records = try XCTUnwrap(json["records"] as? [[String: Any]])
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(Set(records[0].keys), ["sequence", "timestamp", "observation"])
        let value = try XCTUnwrap(records[0]["observation"] as? [String: Any])
        XCTAssertEqual(Set(value.keys), ["game", "revision", "action", "boundary", "outcome", "actorMembership"])
        let game = try XCTUnwrap(value["game"] as? [String: String])
        XCTAssertEqual(Set(game.keys), ["digest"])
        XCTAssertEqual(game["digest"]?.count, 64)
        let text = try XCTUnwrap(String(data: data, encoding: .utf8))
        XCTAssertFalse(text.contains("game-private-input"))
        XCTAssertFalse(text.contains(Buffer.GameToken(gameID: "unrelated-game").digest))
        XCTAssertLessThanOrEqual(data.count, Buffer.maximumExportBytes)
    }

    func testRetentionKeepsOnlyNewest128Records() {
        var buffer = Buffer()
        for n in 0..<200 { buffer.append(observation(revision: UInt64(n)), at: Date(timeIntervalSince1970: Double(n))) }
        XCTAssertEqual(buffer.records.count, 128)
        XCTAssertEqual(buffer.records.first?.sequence, 72)
        XCTAssertEqual(buffer.records.last?.sequence, 199)
    }

    func testExpiryAndClockRollbackDiscardUntrustworthyEntries() {
        var buffer = Buffer()
        buffer.append(observation(), at: Date(timeIntervalSince1970: 100))
        _ = buffer.export(game: .init(gameID: "game-private-input"), at: Date(timeIntervalSince1970: 100 + Buffer.maximumAge))
        XCTAssertTrue(buffer.records.isEmpty)
        buffer.append(observation(), at: Date(timeIntervalSince1970: 200))
        _ = buffer.export(game: .init(gameID: "game-private-input"), at: Date(timeIntervalSince1970: 199))
        XCTAssertTrue(buffer.records.isEmpty)
    }

    func testOnlyConsecutiveIdenticalObservationsCoalesceWithinOneSecond() {
        var buffer = Buffer()
        buffer.append(observation(), at: Date(timeIntervalSince1970: 100))
        buffer.append(observation(), at: Date(timeIntervalSince1970: 101))
        XCTAssertEqual(buffer.records.count, 1)
        buffer.append(observation(revision: 2), at: Date(timeIntervalSince1970: 101))
        buffer.append(observation(), at: Date(timeIntervalSince1970: 102))
        XCTAssertEqual(buffer.records.count, 3)
    }

    func testClearAndInvalidClock() {
        var buffer = Buffer()
        buffer.append(observation(), at: Date(timeIntervalSince1970: .infinity))
        XCTAssertTrue(buffer.records.isEmpty)
        buffer.append(observation(), at: Date(timeIntervalSince1970: 10))
        XCTAssertNil(buffer.export(game: .init(gameID: "game-private-input"), at: Date(timeIntervalSince1970: .nan)))
        buffer.clear()
        XCTAssertTrue(buffer.records.isEmpty)
        buffer.append(observation(), at: Date(timeIntervalSince1970: 10))
        XCTAssertEqual(buffer.records.first?.sequence, 0)
    }

    func testCorrelationIsStablePerGameAndDifferentAcrossGames() {
        XCTAssertEqual(Buffer.GameToken(gameID: "a"), Buffer.GameToken(gameID: "a"))
        XCTAssertNotEqual(Buffer.GameToken(gameID: "a"), Buffer.GameToken(gameID: "b"))
    }

    func testFullBufferExportIsBoundedAndEmptyExportIsValid() throws {
        var buffer = Buffer()
        for n in 0..<128 { buffer.append(observation(revision: UInt64(n)), at: Date(timeIntervalSince1970: Double(n))) }
        let data = try XCTUnwrap(buffer.export(game: .init(gameID: "game-private-input"), at: Date(timeIntervalSince1970: 128)))
        XCTAssertLessThanOrEqual(data.count, Buffer.maximumExportBytes)
        let empty = try XCTUnwrap(buffer.export(game: .init(gameID: "absent"), at: Date(timeIntervalSince1970: 128)))
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: empty) as? [String: Any])
        XCTAssertEqual((json["records"] as? [Any])?.count, 0)
    }
}
