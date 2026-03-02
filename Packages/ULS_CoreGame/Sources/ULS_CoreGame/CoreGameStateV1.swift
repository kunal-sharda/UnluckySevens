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
    public let seed: UInt64?
    public let diceRngState: UInt64?
    public let resourcesByPlayer: [String: ResourceHandV1]
    public let boardRules: BoardRulesV1?
    public let board: BoardSetupV1?
    public let setupState: SetupStateV1?

    public init(
        gameId: String,
        rev: Int,
        prevHash: String?,
        stateHash: String,
        roster: [String],
        currentPlayer: String,
        phase: PhaseV1,
        seed: UInt64?,
        diceRngState: UInt64?,
        resourcesByPlayer: [String: ResourceHandV1] = [:],
        boardRules: BoardRulesV1? = nil,
        board: BoardSetupV1? = nil,
        setupState: SetupStateV1? = nil
    ) {
        self.gameId = gameId
        self.rev = rev
        self.prevHash = prevHash
        self.stateHash = stateHash
        self.roster = roster
        self.currentPlayer = currentPlayer
        self.phase = phase
        self.seed = seed
        self.diceRngState = diceRngState
        self.resourcesByPlayer = resourcesByPlayer
        self.boardRules = boardRules
        self.board = board
        self.setupState = setupState
    }

    public func rehashed() -> CoreGameStateV1 {
        CoreGameStateV1(
            gameId: gameId,
            rev: rev,
            prevHash: prevHash,
            stateHash: canonicalStateHash(),
            roster: roster,
            currentPlayer: currentPlayer,
            phase: phase,
            seed: seed,
            diceRngState: diceRngState,
            resourcesByPlayer: resourcesByPlayer,
            boardRules: boardRules,
            board: board,
            setupState: setupState
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
            "seed": seed ?? NSNull(),
            "diceRngState": diceRngState ?? NSNull(),
            "resourcesByPlayer": resourcesByPlayer.mapValues { $0.canonicalJSONValue() },
            "boardRules": boardRules?.canonicalJSONValue() ?? NSNull(),
            "board": board?.canonicalJSONIncludingHash() ?? NSNull(),
            "setupState": setupState?.canonicalJSONValue() ?? NSNull(),
        ]
    }
}
