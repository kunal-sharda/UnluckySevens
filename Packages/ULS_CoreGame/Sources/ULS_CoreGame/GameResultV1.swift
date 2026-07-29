import Foundation

public enum GameEndReasonV1: String, Codable, Equatable {
    case victory
    case draw
    case hostEnded
}

public struct GameResultV1: Codable, Equatable {
    public let reason: GameEndReasonV1
    public let winnerPlayers: [String]
    public let endedByPlayer: String?
    public let finalScoresByPlayer: [String: Int]

    public init(
        reason: GameEndReasonV1,
        winnerPlayers: [String],
        endedByPlayer: String? = nil,
        finalScoresByPlayer: [String: Int]
    ) {
        self.reason = reason
        self.winnerPlayers = winnerPlayers
        self.endedByPlayer = endedByPlayer
        self.finalScoresByPlayer = finalScoresByPlayer
    }

    internal func canonicalJSONValue() -> [String: Any] {
        [
            "reason": reason.rawValue,
            "winnerPlayers": winnerPlayers,
            "endedByPlayer": endedByPlayer ?? NSNull(),
            "finalScoresByPlayer": finalScoresByPlayer,
        ]
    }
}
