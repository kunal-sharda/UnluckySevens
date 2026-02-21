import CryptoKit
import Foundation

public enum PhaseV1: String, Codable, Equatable {
    case lobby
    case setup
    case turn
    case gameOver
}

public struct CoreGameStateV1: Codable, Equatable {
    public let gameId: String
    public let rev: Int
    public let prevHash: String?
    public let stateHash: String
    public let roster: [String]
    public let currentPlayer: String
    public let phase: PhaseV1

    public init(
        gameId: String,
        rev: Int,
        prevHash: String?,
        stateHash: String,
        roster: [String],
        currentPlayer: String,
        phase: PhaseV1
    ) {
        self.gameId = gameId
        self.rev = rev
        self.prevHash = prevHash
        self.stateHash = stateHash
        self.roster = roster
        self.currentPlayer = currentPlayer
        self.phase = phase
    }

    public func rehashed() -> CoreGameStateV1 {
        CoreGameStateV1(
            gameId: gameId,
            rev: rev,
            prevHash: prevHash,
            stateHash: canonicalStateHash(),
            roster: roster,
            currentPlayer: currentPlayer,
            phase: phase
        )
    }

    public func canonicalStateHash() -> String {
        let payload = canonicalHashPayload()
        guard JSONSerialization.isValidJSONObject(payload),
              let canonicalData = try? JSONSerialization.data(withJSONObject: payload, options: [.sortedKeys]) else {
            preconditionFailure("CoreGameStateV1 canonical payload must be JSON-serializable.")
        }

        let digest = SHA256.hash(data: canonicalData)
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    private func canonicalHashPayload() -> [String: Any] {
        [
            "gameId": gameId,
            "rev": rev,
            "prevHash": prevHash ?? NSNull(),
            "roster": roster,
            "currentPlayer": currentPlayer,
            "phase": phase.rawValue,
        ]
    }
}
