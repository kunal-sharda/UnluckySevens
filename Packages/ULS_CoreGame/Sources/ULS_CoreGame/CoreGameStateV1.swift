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
    public let robberRngState: UInt64?
    public let resourcesByPlayer: [String: ResourceHandV1]
    public let bankResources: ResourceHandV1
    public let devDeck: [DevCardV1]
    public let devCardsByPlayer: [String: DevCardInventoryV1]
    public let newDevCardsByPlayer: [String: DevCardInventoryV1]
    public let revealedVictoryPointsByPlayer: [String: Int]
    public let devCardActionPlayedThisTurn: Bool
    public let knightsPlayedByPlayer: [String: Int]
    public let largestArmyOwner: String?
    public let largestArmySize: Int
    public let longestRoadOwner: String?
    public let longestRoadLength: Int
    public let winnerPlayer: String?
    public let winningVictoryPoints: Int
    public let auditLog: [AuditEntryV1]
    public let lastTurnRecap: TurnRecapV1?
    public let activeTradeOffer: TradeOfferV1?
    public let pendingTradeAccepts: [TradeAcceptV1]
    public let settlementsByNode: [NodeID: String]
    public let citiesByNode: [NodeID: String]
    public let roadsByEdge: [EdgeID: String]
    public let boardRules: BoardRulesV1?
    public let board: BoardSetupV1?
    public let setupState: SetupStateV1?
    public let turnState: TurnStateV1?

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
        robberRngState: UInt64? = nil,
        resourcesByPlayer: [String: ResourceHandV1] = [:],
        bankResources: ResourceHandV1 = .standardBank,
        devDeck: [DevCardV1] = [],
        devCardsByPlayer: [String: DevCardInventoryV1] = [:],
        newDevCardsByPlayer: [String: DevCardInventoryV1] = [:],
        revealedVictoryPointsByPlayer: [String: Int] = [:],
        devCardActionPlayedThisTurn: Bool = false,
        knightsPlayedByPlayer: [String: Int] = [:],
        largestArmyOwner: String? = nil,
        largestArmySize: Int = 0,
        longestRoadOwner: String? = nil,
        longestRoadLength: Int = 0,
        winnerPlayer: String? = nil,
        winningVictoryPoints: Int = 0,
        auditLog: [AuditEntryV1] = [],
        lastTurnRecap: TurnRecapV1? = nil,
        activeTradeOffer: TradeOfferV1? = nil,
        pendingTradeAccepts: [TradeAcceptV1] = [],
        settlementsByNode: [NodeID: String] = [:],
        citiesByNode: [NodeID: String] = [:],
        roadsByEdge: [EdgeID: String] = [:],
        boardRules: BoardRulesV1? = nil,
        board: BoardSetupV1? = nil,
        setupState: SetupStateV1? = nil,
        turnState: TurnStateV1? = nil
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
        self.robberRngState = robberRngState
        var normalizedResourcesByPlayer: [String: ResourceHandV1] = [:]
        for player in roster {
            normalizedResourcesByPlayer[player] = resourcesByPlayer[player] ?? .zero
        }
        self.resourcesByPlayer = normalizedResourcesByPlayer
        self.bankResources = bankResources
        self.devDeck = devDeck
        self.devCardsByPlayer = Self.normalizedDevCardsMap(devCardsByPlayer, roster: roster)
        self.newDevCardsByPlayer = Self.normalizedDevCardsMap(newDevCardsByPlayer, roster: roster)
        self.revealedVictoryPointsByPlayer = Self.normalizedIntMap(revealedVictoryPointsByPlayer, roster: roster)
        self.devCardActionPlayedThisTurn = devCardActionPlayedThisTurn
        self.knightsPlayedByPlayer = Self.normalizedIntMap(knightsPlayedByPlayer, roster: roster)
        self.largestArmyOwner = Self.normalizedAwardOwner(largestArmyOwner, roster: roster)
        self.largestArmySize = max(0, largestArmySize)
        self.longestRoadOwner = Self.normalizedAwardOwner(longestRoadOwner, roster: roster)
        self.longestRoadLength = max(0, longestRoadLength)
        self.winnerPlayer = Self.normalizedAwardOwner(winnerPlayer, roster: roster)
        self.winningVictoryPoints = max(0, winningVictoryPoints)
        self.auditLog = auditLog
        self.lastTurnRecap = lastTurnRecap
        self.activeTradeOffer = activeTradeOffer
        self.pendingTradeAccepts = pendingTradeAccepts
        self.settlementsByNode = settlementsByNode
        self.citiesByNode = citiesByNode
        self.roadsByEdge = roadsByEdge
        self.boardRules = boardRules
        self.board = board
        self.setupState = setupState
        self.turnState = turnState
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
            robberRngState: robberRngState,
            resourcesByPlayer: resourcesByPlayer,
            bankResources: bankResources,
            devDeck: devDeck,
            devCardsByPlayer: devCardsByPlayer,
            newDevCardsByPlayer: newDevCardsByPlayer,
            revealedVictoryPointsByPlayer: revealedVictoryPointsByPlayer,
            devCardActionPlayedThisTurn: devCardActionPlayedThisTurn,
            knightsPlayedByPlayer: knightsPlayedByPlayer,
            largestArmyOwner: largestArmyOwner,
            largestArmySize: largestArmySize,
            longestRoadOwner: longestRoadOwner,
            longestRoadLength: longestRoadLength,
            winnerPlayer: winnerPlayer,
            winningVictoryPoints: winningVictoryPoints,
            auditLog: auditLog,
            lastTurnRecap: lastTurnRecap,
            activeTradeOffer: activeTradeOffer,
            pendingTradeAccepts: pendingTradeAccepts,
            settlementsByNode: settlementsByNode,
            citiesByNode: citiesByNode,
            roadsByEdge: roadsByEdge,
            boardRules: boardRules,
            board: board,
            setupState: setupState,
            turnState: turnState
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
            "robberRngState": robberRngState ?? NSNull(),
            "resourcesByPlayer": resourcesByPlayer.mapValues { $0.canonicalJSONValue() },
            "bankResources": bankResources.canonicalJSONValue(),
            "devDeck": devDeck.map(\.rawValue),
            "devCardsByPlayer": devCardsByPlayer.mapValues { $0.canonicalJSONValue() },
            "newDevCardsByPlayer": newDevCardsByPlayer.mapValues { $0.canonicalJSONValue() },
            "revealedVictoryPointsByPlayer": revealedVictoryPointsByPlayer,
            "devCardActionPlayedThisTurn": devCardActionPlayedThisTurn,
            "knightsPlayedByPlayer": knightsPlayedByPlayer,
            "largestArmyOwner": largestArmyOwner ?? NSNull(),
            "largestArmySize": largestArmySize,
            "longestRoadOwner": longestRoadOwner ?? NSNull(),
            "longestRoadLength": longestRoadLength,
            "winnerPlayer": winnerPlayer ?? NSNull(),
            "winningVictoryPoints": winningVictoryPoints,
            "auditLog": auditLog.map { $0.canonicalJSONValue() },
            "lastTurnRecap": lastTurnRecap?.canonicalJSONValue() ?? NSNull(),
            "activeTradeOffer": activeTradeOffer?.canonicalJSONValue() ?? NSNull(),
            "pendingTradeAccepts": pendingTradeAccepts.map { $0.canonicalJSONValue() },
            "settlementsByNode": canonicalOwnershipMap(settlementsByNode),
            "citiesByNode": canonicalOwnershipMap(citiesByNode),
            "roadsByEdge": canonicalOwnershipMap(roadsByEdge),
            "boardRules": boardRules?.canonicalJSONValue() ?? NSNull(),
            "board": board?.canonicalJSONIncludingHash() ?? NSNull(),
            "setupState": setupState?.canonicalJSONValue() ?? NSNull(),
            "turnState": turnState?.canonicalJSONValue() ?? NSNull(),
        ]
    }

    private func canonicalOwnershipMap(_ ownership: [Int: String]) -> [String: Any] {
        var result: [String: Any] = [:]
        for (key, owner) in ownership {
            result[String(key)] = owner
        }
        return result
    }

    private static func normalizedDevCardsMap(
        _ value: [String: DevCardInventoryV1],
        roster: [String]
    ) -> [String: DevCardInventoryV1] {
        var result: [String: DevCardInventoryV1] = [:]
        for player in roster {
            result[player] = value[player] ?? .zero
        }
        return result
    }

    private static func normalizedIntMap(_ value: [String: Int], roster: [String]) -> [String: Int] {
        var result: [String: Int] = [:]
        for player in roster {
            result[player] = value[player] ?? 0
        }
        return result
    }

    private static func normalizedAwardOwner(_ value: String?, roster: [String]) -> String? {
        guard let value else {
            return nil
        }
        return roster.contains(value) ? value : nil
    }
}
