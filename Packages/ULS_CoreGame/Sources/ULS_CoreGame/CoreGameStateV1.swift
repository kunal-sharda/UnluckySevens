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
    public let playerDisplayNamesByPlayer: [String: String]
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
    public let gameResult: GameResultV1?
    public let resignedPlayers: [String]
    public let drawVote: DrawVoteV1?
    public let hasAttemptedDrawVote: Bool
    public let auditLog: [AuditEntryV1]
    public let lastTurnRecap: TurnRecapV1?
    public let activeTradeOffer: TradeOfferV1?
    public let tradeResponses: [TradeResponseV1]
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
        playerDisplayNamesByPlayer: [String: String] = [:],
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
        gameResult: GameResultV1? = nil,
        resignedPlayers: [String] = [],
        drawVote: DrawVoteV1? = nil,
        hasAttemptedDrawVote: Bool = false,
        auditLog: [AuditEntryV1] = [],
        lastTurnRecap: TurnRecapV1? = nil,
        activeTradeOffer: TradeOfferV1? = nil,
        tradeResponses: [TradeResponseV1] = [],
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
        self.playerDisplayNamesByPlayer = Self.normalizedDisplayNamesMap(
            playerDisplayNamesByPlayer,
            roster: roster
        )
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
        let normalizedWinner = Self.normalizedAwardOwner(winnerPlayer, roster: roster)
        self.winnerPlayer = normalizedWinner
        self.winningVictoryPoints = max(0, winningVictoryPoints)
        let finalScores = Self.finalScoresByPlayer(
            roster: roster,
            revealedVictoryPointsByPlayer: self.revealedVictoryPointsByPlayer,
            largestArmyOwner: self.largestArmyOwner,
            longestRoadOwner: self.longestRoadOwner,
            settlementsByNode: settlementsByNode,
            citiesByNode: citiesByNode
        )
        if let gameResult {
            self.gameResult = Self.normalizedGameResult(gameResult, roster: roster)
        } else if phase == .gameOver, let normalizedWinner {
            self.gameResult = GameResultV1(
                reason: .victory,
                winnerPlayers: [normalizedWinner],
                finalScoresByPlayer: finalScores
            )
        } else {
            self.gameResult = nil
        }
        let rosterSet = Set(roster)
        let resignedSet = Set(resignedPlayers.filter(rosterSet.contains))
        self.resignedPlayers = roster.filter(resignedSet.contains)
        self.drawVote = Self.normalizedDrawVote(
            drawVote,
            roster: roster,
            resignedPlayers: self.resignedPlayers
        )
        self.hasAttemptedDrawVote = hasAttemptedDrawVote
        self.auditLog = auditLog
        self.lastTurnRecap = lastTurnRecap
        self.activeTradeOffer = activeTradeOffer
        self.tradeResponses = tradeResponses.sorted { lhs, rhs in
            lhs.respondingPlayer < rhs.respondingPlayer
        }
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
            playerDisplayNamesByPlayer: playerDisplayNamesByPlayer,
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
            gameResult: gameResult,
            resignedPlayers: resignedPlayers,
            drawVote: drawVote,
            hasAttemptedDrawVote: hasAttemptedDrawVote,
            auditLog: auditLog,
            lastTurnRecap: lastTurnRecap,
            activeTradeOffer: activeTradeOffer,
            tradeResponses: tradeResponses,
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
            "playerDisplayNamesByPlayer": playerDisplayNamesByPlayer,
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
            "gameResult": gameResult?.canonicalJSONValue() ?? NSNull(),
            "resignedPlayers": resignedPlayers,
            "drawVote": drawVote?.canonicalJSONValue() ?? NSNull(),
            "hasAttemptedDrawVote": hasAttemptedDrawVote,
            "auditLog": auditLog.map { $0.canonicalJSONValue() },
            "lastTurnRecap": lastTurnRecap?.canonicalJSONValue() ?? NSNull(),
            "activeTradeOffer": activeTradeOffer?.canonicalJSONValue() ?? NSNull(),
            "tradeResponses": tradeResponses.map { $0.canonicalJSONValue() },
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

    private static func normalizedGameResult(
        _ result: GameResultV1,
        roster: [String]
    ) -> GameResultV1 {
        let rosterSet = Set(roster)
        var seen = Set<String>()
        let winners = result.winnerPlayers.filter {
            rosterSet.contains($0) && seen.insert($0).inserted
        }
        let endedByPlayer = result.endedByPlayer.flatMap {
            rosterSet.contains($0) ? $0 : nil
        }
        return GameResultV1(
            reason: result.reason,
            winnerPlayers: winners,
            endedByPlayer: endedByPlayer,
            finalScoresByPlayer: normalizedIntMap(
                result.finalScoresByPlayer,
                roster: roster
            )
        )
    }

    private static func normalizedDrawVote(
        _ vote: DrawVoteV1?,
        roster: [String],
        resignedPlayers: [String]
    ) -> DrawVoteV1? {
        guard let vote else {
            return nil
        }
        let activePlayers = roster.filter { !resignedPlayers.contains($0) }
        guard activePlayers.contains(vote.proposedBy) else {
            return nil
        }
        let approvalSet = Set(vote.approvals.filter(activePlayers.contains))
        return DrawVoteV1(
            proposedBy: vote.proposedBy,
            approvals: activePlayers.filter(approvalSet.contains)
        )
    }

    private static func finalScoresByPlayer(
        roster: [String],
        revealedVictoryPointsByPlayer: [String: Int],
        largestArmyOwner: String?,
        longestRoadOwner: String?,
        settlementsByNode: [NodeID: String],
        citiesByNode: [NodeID: String]
    ) -> [String: Int] {
        Dictionary(uniqueKeysWithValues: roster.map { player in
            let settlements = settlementsByNode.values.filter { $0 == player }.count
            let cities = citiesByNode.values.filter { $0 == player }.count
            let revealed = revealedVictoryPointsByPlayer[player] ?? 0
            let awardPoints = (largestArmyOwner == player ? 2 : 0)
                + (longestRoadOwner == player ? 2 : 0)
            return (player, settlements + (cities * 2) + revealed + awardPoints)
        })
    }

    private static func normalizedAwardOwner(_ value: String?, roster: [String]) -> String? {
        guard let value else {
            return nil
        }
        return roster.contains(value) ? value : nil
    }

    public var activePlayers: [String] {
        roster.filter { !resignedPlayers.contains($0) }
    }

    public var hostPlayer: String? {
        roster.first
    }

    public func isActivePlayer(_ player: String) -> Bool {
        activePlayers.contains(player)
    }

    public static func normalizedPlayerDisplayName(_ value: String?) -> String? {
        guard let value else {
            return nil
        }

        let collapsedWhitespace = value
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        let trimmed = collapsedWhitespace.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return nil
        }

        return String(trimmed.prefix(24))
    }

    private static func normalizedDisplayNamesMap(
        _ value: [String: String],
        roster: [String]
    ) -> [String: String] {
        var result: [String: String] = [:]
        for player in roster {
            guard let normalized = normalizedPlayerDisplayName(value[player]) else {
                continue
            }
            result[player] = normalized
        }
        return result
    }
}
