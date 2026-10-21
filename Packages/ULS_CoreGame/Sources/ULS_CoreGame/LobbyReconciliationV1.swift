import CryptoKit
import Foundation

public struct LobbyReconciliationResolutionV1: Equatable {
    public let state: CoreGameStateV1?
    public let frontierDigest: String
    public let admittedPlayers: [String]
    public let excludedPlayers: [String]

    public init(
        state: CoreGameStateV1?,
        frontierDigest: String,
        admittedPlayers: [String],
        excludedPlayers: [String]
    ) {
        self.state = state
        self.frontierDigest = frontierDigest
        self.admittedPlayers = admittedPlayers
        self.excludedPlayers = excludedPlayers
    }
}

/// Produces the only host-authorized canonical union of independently valid lobby joins.
///
/// `observedStates` is evidence, not roster truth. A player is eligible only when a
/// self-authored join transition can be validated from another reachable state in
/// the evidence graph. Existing canonical members are retained and remaining seats
/// are filled by descending state-hash priority so delivery order cannot affect the
/// result.
public func reconcileLobbyV1(
    anchor: CoreGameStateV1,
    observedStates: [CoreGameStateV1],
    actor: String,
    maximumPlayers: Int = 4
) throws -> LobbyReconciliationResolutionV1 {
    guard
        anchor.phase == .lobby,
        let originalInviter = anchor.roster.first,
        actor == originalInviter
    else {
        throw CoreGameError.actorMismatch
    }
    guard maximumPlayers == 4, (1 ... maximumPlayers).contains(anchor.roster.count) else {
        throw CoreGameError.lobbyPlayerLimitInvalid
    }
    try validateCanonicalSnapshot(anchor)

    let evidence = try canonicalLobbyEvidence(
        anchor: anchor,
        observedStates: observedStates
    )
    let claims = validatedJoinClaims(
        anchor: anchor,
        evidenceByHash: evidence,
        originalInviter: originalInviter
    )

    let bestClaimByPlayer = claims.reduce(into: [String: CoreGameStateV1]()) { result, claim in
        let player = claim.roster.last!
        if result[player].map({ claim.stateHash > $0.stateHash }) ?? true {
            result[player] = claim
        }
    }
    let orderedCandidates = bestClaimByPlayer
        .filter { !anchor.roster.contains($0.key) }
        .sorted { lhs, rhs in
            if lhs.value.stateHash != rhs.value.stateHash {
                return lhs.value.stateHash > rhs.value.stateHash
            }
            return lhs.key < rhs.key
        }

    let openSeats = maximumPlayers - anchor.roster.count
    let admittedClaims = Array(orderedCandidates.prefix(openSeats))
    let excludedPlayers = orderedCandidates.dropFirst(openSeats).map(\.key)
    let admittedPlayers = admittedClaims.map(\.key)
    let frontierDigest = lobbyFrontierDigest(
        anchorHash: anchor.stateHash,
        claimHashes: claims.map(\.stateHash)
    )

    guard !admittedPlayers.isEmpty else {
        return LobbyReconciliationResolutionV1(
            state: nil,
            frontierDigest: frontierDigest,
            admittedPlayers: [],
            excludedPlayers: excludedPlayers
        )
    }

    var displayNames = anchor.playerDisplayNamesByPlayer
    var resources = anchor.resourcesByPlayer
    var devCards = anchor.devCardsByPlayer
    var newDevCards = anchor.newDevCardsByPlayer
    var revealedVictoryPoints = anchor.revealedVictoryPointsByPlayer
    var knightsPlayed = anchor.knightsPlayedByPlayer
    for (player, claim) in admittedClaims {
        if let displayName = claim.playerDisplayNamesByPlayer[player] {
            displayNames[player] = displayName
        }
        resources[player] = .zero
        devCards[player] = .zero
        newDevCards[player] = .zero
        revealedVictoryPoints[player] = 0
        knightsPlayed[player] = 0
    }

    let reconciled = CoreGameStateV1(
        gameId: anchor.gameId,
        rev: anchor.rev + 1,
        prevHash: anchor.stateHash,
        stateHash: "",
        roster: anchor.roster + admittedPlayers,
        currentPlayer: anchor.currentPlayer,
        playerDisplayNamesByPlayer: displayNames,
        phase: .lobby,
        seed: anchor.seed,
        diceRngState: anchor.diceRngState,
        robberRngState: anchor.robberRngState,
        resourcesByPlayer: resources,
        bankResources: anchor.bankResources,
        devDeck: anchor.devDeck,
        devCardsByPlayer: devCards,
        newDevCardsByPlayer: newDevCards,
        revealedVictoryPointsByPlayer: revealedVictoryPoints,
        devCardActionPlayedThisTurn: anchor.devCardActionPlayedThisTurn,
        knightsPlayedByPlayer: knightsPlayed,
        largestArmyOwner: anchor.largestArmyOwner,
        largestArmySize: anchor.largestArmySize,
        longestRoadOwner: anchor.longestRoadOwner,
        longestRoadLength: anchor.longestRoadLength,
        winnerPlayer: anchor.winnerPlayer,
        winningVictoryPoints: anchor.winningVictoryPoints,
        gameResult: anchor.gameResult,
        resignedPlayers: anchor.resignedPlayers,
        drawVote: anchor.drawVote,
        hasAttemptedDrawVote: anchor.hasAttemptedDrawVote,
        auditLog: anchor.auditLog,
        lastTurnRecap: anchor.lastTurnRecap,
        activeTradeOffer: anchor.activeTradeOffer,
        tradeResponses: anchor.tradeResponses,
        settlementsByNode: anchor.settlementsByNode,
        citiesByNode: anchor.citiesByNode,
        roadsByEdge: anchor.roadsByEdge,
        boardRules: anchor.boardRules,
        board: anchor.board,
        setupState: nil,
        turnState: nil
    ).rehashed()
    try validateCanonicalSnapshot(reconciled)

    return LobbyReconciliationResolutionV1(
        state: reconciled,
        frontierDigest: frontierDigest,
        admittedPlayers: admittedPlayers,
        excludedPlayers: excludedPlayers
    )
}

private func canonicalLobbyEvidence(
    anchor: CoreGameStateV1,
    observedStates: [CoreGameStateV1]
) throws -> [String: CoreGameStateV1] {
    var evidenceByHash = [anchor.stateHash: anchor]
    for state in observedStates where state.gameId == anchor.gameId && state.phase == .lobby {
        try validateCanonicalSnapshot(state)
        evidenceByHash[state.stateHash] = state
    }
    return evidenceByHash
}

private func validatedJoinClaims(
    anchor: CoreGameStateV1,
    evidenceByHash: [String: CoreGameStateV1],
    originalInviter: String
) -> [CoreGameStateV1] {
    var reachableHashes: Set<String> = [anchor.stateHash]
    if let genesisHash = approvedLobbyGenesisHash(
        anchor: anchor,
        evidenceByHash: evidenceByHash,
        originalInviter: originalInviter
    ) {
        reachableHashes.insert(genesisHash)
    }

    var claimsByHash: [String: CoreGameStateV1] = [:]
    var madeProgress = true
    while madeProgress {
        madeProgress = false
        for state in evidenceByHash.values where !reachableHashes.contains(state.stateHash) {
            guard
                let parentHash = state.prevHash,
                reachableHashes.contains(parentHash),
                let parent = evidenceByHash[parentHash],
                let transitionActor = lobbyTransitionActor(from: parent, to: state),
                (try? validateTransition(from: parent, to: state, actor: transitionActor)) != nil
            else {
                continue
            }
            reachableHashes.insert(state.stateHash)
            madeProgress = true
            if state.roster == parent.roster + [transitionActor] {
                claimsByHash[state.stateHash] = state
            }
        }
    }
    return claimsByHash.values.sorted { $0.stateHash > $1.stateHash }
}

private func approvedLobbyGenesisHash(
    anchor: CoreGameStateV1,
    evidenceByHash: [String: CoreGameStateV1],
    originalInviter: String
) -> String? {
    var cursor = anchor
    var visited: Set<String> = []
    while let parentHash = cursor.prevHash {
        guard
            visited.insert(cursor.stateHash).inserted,
            let parent = evidenceByHash[parentHash],
            parent.gameId == anchor.gameId,
            parent.phase == .lobby,
            parent.rev == cursor.rev - 1,
            parent.roster.first == originalInviter
        else {
            return nil
        }
        cursor = parent
    }
    guard
        cursor.rev == 0,
        cursor.roster == [originalInviter],
        cursor.currentPlayer == originalInviter
    else {
        return nil
    }
    return cursor.stateHash
}

private func lobbyTransitionActor(
    from parent: CoreGameStateV1,
    to state: CoreGameStateV1
) -> String? {
    let addedPlayers = state.roster.filter { !parent.roster.contains($0) }
    if addedPlayers.count == 1, let player = addedPlayers.first {
        return player
    }
    guard state.roster == parent.roster else {
        return nil
    }
    let changedNames = parent.roster.filter {
        parent.playerDisplayNamesByPlayer[$0] != state.playerDisplayNamesByPlayer[$0]
    }
    return changedNames.count == 1 ? changedNames.first : nil
}

private func lobbyFrontierDigest(anchorHash: String, claimHashes: [String]) -> String {
    let canonical = ([anchorHash] + claimHashes.sorted()).joined(separator: "|")
    return SHA256.hash(data: Data(canonical.utf8))
        .map { String(format: "%02x", $0) }
        .joined()
}
