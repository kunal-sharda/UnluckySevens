import CryptoKit
import Foundation

public struct TradeAcceptanceBranchClaimV1: Codable, Equatable {
    public let gameId: String
    public let acceptedAtRev: Int
    public let parentStateHash: String
    public let offerHash: String
    public let responderActorID: String
    public let acceptedStateHash: String
    public let auditPrefixCount: Int
    public let auditPrefixDigest: String

    init(
        gameId: String,
        acceptedAtRev: Int,
        parentStateHash: String,
        offerHash: String,
        responderActorID: String,
        acceptedStateHash: String,
        auditPrefixCount: Int,
        auditPrefixDigest: String
    ) {
        self.gameId = gameId
        self.acceptedAtRev = acceptedAtRev
        self.parentStateHash = parentStateHash
        self.offerHash = offerHash
        self.responderActorID = responderActorID
        self.acceptedStateHash = acceptedStateHash
        self.auditPrefixCount = auditPrefixCount
        self.auditPrefixDigest = auditPrefixDigest
    }

    private enum CodingKeys: String, CodingKey {
        case gameId, acceptedAtRev, parentStateHash, offerHash, responderActorID
        case acceptedStateHash, auditPrefixCount, auditPrefixDigest
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        gameId = try values.decode(String.self, forKey: .gameId)
        acceptedAtRev = try values.decode(Int.self, forKey: .acceptedAtRev)
        parentStateHash = try values.decode(String.self, forKey: .parentStateHash)
        offerHash = try values.decode(String.self, forKey: .offerHash)
        responderActorID = try values.decode(String.self, forKey: .responderActorID)
        acceptedStateHash = try values.decodeIfPresent(String.self, forKey: .acceptedStateHash) ?? ""
        auditPrefixCount = try values.decode(Int.self, forKey: .auditPrefixCount)
        auditPrefixDigest = try values.decode(String.self, forKey: .auditPrefixDigest)
    }
}

/// Device-local evidence used to remember proven competing Accept branches.
/// It is deliberately absent from canonical game state and transport payloads.
public struct CanonicalStateConvergenceContextV1: Codable, Equatable {
    public private(set) var tradeAcceptanceClaims: [TradeAcceptanceBranchClaimV1]
    public private(set) var lineageStateHashesByAcceptedStateHash: [String: [String]]

    public init(
        tradeAcceptanceClaims: [TradeAcceptanceBranchClaimV1] = [],
        lineageStateHashesByAcceptedStateHash: [String: [String]] = [:]
    ) {
        self.tradeAcceptanceClaims = tradeAcceptanceClaims
        self.lineageStateHashesByAcceptedStateHash = lineageStateHashesByAcceptedStateHash
    }

    private enum CodingKeys: String, CodingKey {
        case tradeAcceptanceClaims
        case lineageStateHashesByAcceptedStateHash
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        tradeAcceptanceClaims = try values.decodeIfPresent(
            [TradeAcceptanceBranchClaimV1].self,
            forKey: .tradeAcceptanceClaims
        ) ?? []
        lineageStateHashesByAcceptedStateHash = try values.decodeIfPresent(
            [String: [String]].self,
            forKey: .lineageStateHashesByAcceptedStateHash
        ) ?? [:]
        for claim in tradeAcceptanceClaims {
            appendLineageHash(claim.acceptedStateHash, for: claim.acceptedStateHash)
        }
    }

    public mutating func observe(_ state: CoreGameStateV1) {
        guard (try? validateCanonicalSnapshot(state)) != nil else {
            return
        }
        if let claim = CanonicalStatePreferenceV1.directTradeAcceptanceClaim(from: state) {
            if !tradeAcceptanceClaims.contains(claim) {
                tradeAcceptanceClaims.append(claim)
            }
            appendLineageHash(claim.acceptedStateHash, for: claim.acceptedStateHash)
        }

        guard let parentHash = state.prevHash else { return }
        let claims = tradeAcceptanceClaims
        for claim in claims {
            let knownHashes = lineageStateHashesByAcceptedStateHash[claim.acceptedStateHash] ?? []
            guard
                knownHashes.contains(parentHash),
                CanonicalStatePreferenceV1.hasAuditLineage(state, matching: claim)
            else {
                continue
            }
            appendLineageHash(state.stateHash, for: claim.acceptedStateHash)
        }
    }

    private mutating func appendLineageHash(_ stateHash: String, for acceptedStateHash: String) {
        guard !stateHash.isEmpty, !acceptedStateHash.isEmpty else { return }
        var hashes = lineageStateHashesByAcceptedStateHash[acceptedStateHash] ?? []
        if !hashes.contains(stateHash) {
            hashes.append(stateHash)
            lineageStateHashesByAcceptedStateHash[acceptedStateHash] = hashes
        }
    }
}

/// Defines deterministic preference among canonical snapshots. Ordinary states
/// use revision then state hash ordering. A trade-accept lineage override is
/// allowed only after local evidence contains two direct Accept snapshots with
/// the same parent, offer, revision, and audit prefix.
public enum CanonicalStatePreferenceV1 {
    public static func prefers(
        _ candidate: CoreGameStateV1,
        over existing: CoreGameStateV1,
        context: CanonicalStateConvergenceContextV1 = .init()
    ) -> Bool {
        guard candidate.gameId == existing.gameId else {
            return fallbackPrefers(candidate, over: existing)
        }
        guard candidate.stateHash != existing.stateHash else {
            return false
        }

        var observedContext = context
        observedContext.observe(candidate)
        observedContext.observe(existing)
        if let preference = provenTradeAcceptancePreference(
            candidate,
            existing,
            context: observedContext
        ) {
            return preference
        }
        return fallbackPrefers(candidate, over: existing)
    }

    static func tradeAcceptanceContentionKey(
        gameId: String,
        acceptedAtRev: Int,
        responderActorID: String
    ) -> String {
        let material = [
            lengthPrefixed(gameId),
            String(acceptedAtRev),
            lengthPrefixed(responderActorID),
        ].joined(separator: "|")
        let digest = SHA256.hash(data: Data(material.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    static func directTradeAcceptanceClaim(
        from state: CoreGameStateV1
    ) -> TradeAcceptanceBranchClaimV1? {
        guard
            let parentStateHash = state.prevHash,
            let entry = state.auditLog.last,
            entry.action == .acceptTrade,
            entry.rev == state.rev,
            let response = state.tradeResponses.last(where: {
                $0.kind == .accept
                    && $0.respondingPlayer == entry.actor
                    && $0.respondedAtRev == entry.rev
            })
        else {
            return nil
        }
        let auditPrefix = Array(state.auditLog.dropLast())
        guard let auditPrefixDigest = auditDigest(auditPrefix) else {
            return nil
        }
        return TradeAcceptanceBranchClaimV1(
            gameId: state.gameId,
            acceptedAtRev: entry.rev,
            parentStateHash: parentStateHash,
            offerHash: response.offerHash,
            responderActorID: entry.actor,
            acceptedStateHash: state.stateHash,
            auditPrefixCount: auditPrefix.count,
            auditPrefixDigest: auditPrefixDigest
        )
    }

    private static func provenTradeAcceptancePreference(
        _ candidate: CoreGameStateV1,
        _ existing: CoreGameStateV1,
        context: CanonicalStateConvergenceContextV1
    ) -> Bool? {
        for first in context.tradeAcceptanceClaims {
            guard first.gameId == candidate.gameId else { continue }
            for second in context.tradeAcceptanceClaims where areCompetingClaims(first, second) {
                let firstWins = contentionKey(for: first) > contentionKey(for: second)
                let winner = firstWins ? first : second
                let loser = firstWins ? second : first
                if matchesLineage(candidate, claim: winner, context: context),
                   matchesLineage(existing, claim: loser, context: context) {
                    return true
                }
                if matchesLineage(candidate, claim: loser, context: context),
                   matchesLineage(existing, claim: winner, context: context) {
                    return false
                }
            }
        }
        return nil
    }

    private static func areCompetingClaims(
        _ lhs: TradeAcceptanceBranchClaimV1,
        _ rhs: TradeAcceptanceBranchClaimV1
    ) -> Bool {
        lhs.gameId == rhs.gameId
            && lhs.acceptedAtRev == rhs.acceptedAtRev
            && lhs.parentStateHash == rhs.parentStateHash
            && lhs.offerHash == rhs.offerHash
            && lhs.auditPrefixCount == rhs.auditPrefixCount
            && lhs.auditPrefixDigest == rhs.auditPrefixDigest
            && lhs.responderActorID != rhs.responderActorID
    }

    private static func matchesLineage(
        _ state: CoreGameStateV1,
        claim: TradeAcceptanceBranchClaimV1,
        context: CanonicalStateConvergenceContextV1
    ) -> Bool {
        guard state.gameId == claim.gameId, hasAuditLineage(state, matching: claim) else {
            return false
        }
        if let directClaim = directTradeAcceptanceClaim(from: state), directClaim == claim {
            return true
        }
        return context.lineageStateHashesByAcceptedStateHash[claim.acceptedStateHash]?
            .contains(state.stateHash) == true
    }

    static func hasAuditLineage(
        _ state: CoreGameStateV1,
        matching claim: TradeAcceptanceBranchClaimV1
    ) -> Bool {
        guard state.gameId == claim.gameId else { return false }
        let index = claim.auditPrefixCount
        guard state.auditLog.indices.contains(index) else { return false }
        guard auditDigest(Array(state.auditLog.prefix(index))) == claim.auditPrefixDigest else {
            return false
        }
        let entry = state.auditLog[index]
        return entry.rev == claim.acceptedAtRev
            && entry.action == .acceptTrade
            && entry.actor == claim.responderActorID
    }

    private static func contentionKey(for claim: TradeAcceptanceBranchClaimV1) -> String {
        tradeAcceptanceContentionKey(
            gameId: claim.gameId,
            acceptedAtRev: claim.acceptedAtRev,
            responderActorID: claim.responderActorID
        )
    }

    private static func auditDigest(_ entries: [AuditEntryV1]) -> String? {
        guard let data = try? JSONSerialization.data(
            withJSONObject: entries.map { $0.canonicalJSONValue() },
            options: [.sortedKeys]
        ) else {
            return nil
        }
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    private static func fallbackPrefers(
        _ candidate: CoreGameStateV1,
        over existing: CoreGameStateV1
    ) -> Bool {
        if candidate.rev != existing.rev {
            return candidate.rev > existing.rev
        }
        return candidate.stateHash > existing.stateHash
    }

    private static func lengthPrefixed(_ value: String) -> String {
        "\(value.utf8.count):\(value)"
    }
}
