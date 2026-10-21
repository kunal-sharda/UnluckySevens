import Foundation
import XCTest
import ULS_CoreGame
@testable import MessagesExtensionSupport

@MainActor
final class ReliabilityActionIntegrationTests: XCTestCase {
    func testRejectedTradeAndUnavailableRecoveryAreExportedWithoutPrivateValues() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let diagnostics = ReliabilityDiagnostics(directory: directory, metadata: .init(version: "1", build: "9",
            candidate: "test", configuration: "debug", osVersion: "26"))
        let defaults = try XCTUnwrap(UserDefaults(suiteName: UUID().uuidString))
        let state = CoreGameStateV1(gameId: "private-game", rev: 0, prevHash: nil, stateHash: "",
            roster: ["private-host"], currentPlayer: "private-host", phase: .lobby,
            seed: nil, diceRngState: nil, resourcesByPlayer: ["private-host": .zero]).rehashed()
        let model = LobbyDriverViewModel(userDefaults: defaults, tutorialState: state, reliabilityDiagnostics: diagnostics)
        model.localParticipantForTesting = "private-host"
        XCTAssertFalse(model.sendAcceptTradeResponse())
        model.resendCurrentGameUpdate()
        XCTAssertNil(model.publishDiceRoll())
        model.publishLobbyJoinState()
        model.startGame()
        let data = try XCTUnwrap(diagnostics.report(gameID: state.gameId))
        let report = try JSONDecoder().decode(ReliabilityReport.self, from: data)
        XCTAssertTrue(report.records.contains { $0.observation.action == .trade && $0.observation.outcome == .rejected })
        XCTAssertTrue(report.records.contains { $0.observation.action == .recovery && $0.observation.outcome == .unavailable })
        let categories: [ReliabilityDiagnosticBuffer.Action] = [.roll, .join, .setup]
        for category in categories {
            XCTAssertTrue(report.records.contains { $0.observation.action == category && $0.observation.outcome == .rejected })
        }
        XCTAssertEqual(model.gameplayShellProjection.stateHash, state.stateHash)
        let text = String(decoding: data, as: UTF8.self)
        for secret in ["private-game", "private-host", "resourcesByPlayer"] { XCTAssertFalse(text.contains(secret)) }
    }

    func testIntentCategoryDropsPrivateAssociatedValues() {
        XCTAssertEqual(ReliabilityDiagnosticBuffer.Action.turn(.acceptTrade(acceptingPlayer: "private", offerHash: "secret")), .trade)
        XCTAssertEqual(ReliabilityDiagnosticBuffer.Action.turn(.submitDiscard(player: "private", discarded: .init(wood: 4))), .discard)
        XCTAssertEqual(ReliabilityDiagnosticBuffer.Action.turn(.buildRoad(edgeID: 7)), .build)
        XCTAssertEqual(ReliabilityDiagnosticBuffer.Action.turn(.rollDice), .roll)
        XCTAssertEqual(ReliabilityDiagnosticBuffer.Action.turn(.endTurn), .endTurn)
        XCTAssertEqual(ReliabilityDiagnosticBuffer.Action.turn(.revealVictoryPoint), .developmentCard)
        XCTAssertEqual(ReliabilityDiagnosticBuffer.Action.turn(.selectStealVictim(victimPlayer: "private")), .robber)
    }
}
