import Foundation

public enum AuditActionV1: String, Codable, Equatable {
    case rollDice
    case submitDiscard
    case moveRobber
    case selectStealVictim
    case buildRoad
    case buildSettlement
    case buildCity
    case proposeTrade
    case acceptTrade
    case executeTrade
    case maritimeTrade
    case buyDevCard
    case playKnight
    case playMonopoly
    case playYearOfPlenty
    case playRoadBuilding
    case revealVictoryPoint
    case endTurn
}

public struct AuditEntryV1: Codable, Equatable {
    public let rev: Int
    public let actor: String
    public let action: AuditActionV1
    public let rollTotal: Int?

    public init(rev: Int, actor: String, action: AuditActionV1, rollTotal: Int? = nil) {
        self.rev = rev
        self.actor = actor
        self.action = action
        self.rollTotal = rollTotal
    }

    internal func canonicalJSONValue() -> [String: Any] {
        [
            "rev": rev,
            "actor": actor,
            "action": action.rawValue,
            "rollTotal": rollTotal ?? NSNull(),
        ]
    }
}

public struct TurnRecapV1: Codable, Equatable {
    public let actor: String
    public let startRev: Int
    public let endRev: Int
    public let rollTotal: Int?
    public let actions: [AuditActionV1]

    public init(
        actor: String,
        startRev: Int,
        endRev: Int,
        rollTotal: Int?,
        actions: [AuditActionV1]
    ) {
        self.actor = actor
        self.startRev = startRev
        self.endRev = endRev
        self.rollTotal = rollTotal
        self.actions = actions
    }

    internal func canonicalJSONValue() -> [String: Any] {
        [
            "actor": actor,
            "startRev": startRev,
            "endRev": endRev,
            "rollTotal": rollTotal ?? NSNull(),
            "actions": actions.map(\.rawValue),
        ]
    }
}

internal func computeLastTurnRecap(from auditLog: [AuditEntryV1]) -> TurnRecapV1? {
    guard !auditLog.isEmpty else {
        return nil
    }

    let startIndex: Int
    let endIndex: Int
    if let lastEndTurnIndex = auditLog.lastIndex(where: { $0.action == .endTurn }) {
        endIndex = lastEndTurnIndex
        if let previousEndTurnIndex = auditLog[..<lastEndTurnIndex].lastIndex(where: { $0.action == .endTurn }) {
            startIndex = previousEndTurnIndex + 1
        } else {
            startIndex = 0
        }
    } else {
        endIndex = auditLog.count - 1
        if let previousEndTurnIndex = auditLog.lastIndex(where: { $0.action == .endTurn }) {
            startIndex = previousEndTurnIndex + 1
        } else {
            startIndex = 0
        }
    }

    guard startIndex <= endIndex else {
        return nil
    }

    let entries = Array(auditLog[startIndex ... endIndex])
    guard let first = entries.first, let last = entries.last else {
        return nil
    }
    let rollTotal = entries.first(where: { $0.action == .rollDice })?.rollTotal
    return TurnRecapV1(
        actor: first.actor,
        startRev: first.rev,
        endRev: last.rev,
        rollTotal: rollTotal,
        actions: entries.map(\.action)
    )
}
