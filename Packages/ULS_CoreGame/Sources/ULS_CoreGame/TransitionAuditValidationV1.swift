import Foundation

/// Audit reconstruction is deliberately independent from reducer orchestration.
/// It classifies a committed transition after the domain validators have checked it.
func validateAuditTransition(from: CoreGameStateV1, to: CoreGameStateV1, actor: String) throws {
    let isTurnLikeTransition = from.phase == .turn && (to.phase == .turn || to.phase == .gameOver)
    if !isTurnLikeTransition {
        guard to.auditLog == from.auditLog, to.lastTurnRecap == from.lastTurnRecap,
              to.lastTurnRecap == computeLastTurnRecap(from: to.auditLog) else { throw CoreGameError.auditLogInvalid }
        return
    }
    guard to.auditLog.count == from.auditLog.count + 1,
          Array(to.auditLog.dropLast()) == from.auditLog,
          let appended = to.auditLog.last,
          appended.rev == to.rev,
          appended.actor == actor else { throw CoreGameError.auditLogInvalid }
    let expectedAction = try expectedAuditActionForTransition(from: from, to: to)
    guard appended.action == expectedAction else { throw CoreGameError.auditLogInvalid }
    let expectedRollTotal = expectedAction == .rollDice ? to.turnState?.lastRoll.map { $0.d1 + $0.d2 } : nil
    guard appended.rollTotal == expectedRollTotal,
          to.lastTurnRecap == computeLastTurnRecap(from: to.auditLog) else { throw CoreGameError.auditLogInvalid }
}

func expectedAuditActionForTransition(from: CoreGameStateV1, to: CoreGameStateV1) throws -> AuditActionV1 {
    if from.currentPlayer != to.currentPlayer { return .endTurn }
    if from.turnState?.step == .needsRoll, let toStep = to.turnState?.step,
       toStep == .afterRoll || toStep == .pendingDiscards || toStep == .needsRobberMove { return .rollDice }
    if from.turnState?.step == .pendingDiscards,
       let fromSubmitted = from.turnState?.submittedDiscardsByPlayer,
       let toSubmitted = to.turnState?.submittedDiscardsByPlayer,
       toSubmitted.count == fromSubmitted.count + 1 { return .submitDiscard }
    if from.turnState?.step == .needsRobberMove, let fromBoard = from.board, let toBoard = to.board,
       fromBoard.robberTile != toBoard.robberTile { return .moveRobber }
    if from.turnState?.step == .needsRobberSteal { return .selectStealVictim }
    if from.activeTradeOffer == nil, to.activeTradeOffer != nil { return .proposeTrade }
    if let fromOffer = from.activeTradeOffer, let toOffer = to.activeTradeOffer, fromOffer != toOffer { return .proposeTrade }
    if let fromOffer = from.activeTradeOffer {
        let priorPlayers = Set(from.tradeResponses.map(\.respondingPlayer))
        let newResponses = to.tradeResponses.filter { !priorPlayers.contains($0.respondingPlayer) && $0.offerHash == fromOffer.offerHash }
        if let addedResponse = newResponses.first, newResponses.count == 1 {
            switch addedResponse.kind { case .accept: return .acceptTrade; case .decline: return .declineTrade; case .counter: return .counterTrade }
        }
    }
    if to.devDeck.count == from.devDeck.count - 1, Array(from.devDeck.dropFirst()) == to.devDeck { return .buyDevCard }
    if isKnightDevCardTransition(from: from, to: to, actor: from.currentPlayer) { return .playKnight }
    if isMonopolyDevCardTransitionForAudit(from: from, to: to) { return .playMonopoly }
    if isYearOfPlentyDevCardTransitionForAudit(from: from, to: to) { return .playYearOfPlenty }
    if isRoadBuildingDevCardTransitionForAudit(from: from, to: to) { return .playRoadBuilding }
    if isRevealVictoryPointTransitionForAudit(from: from, to: to) { return .revealVictoryPoint }
    if isBuildRoadTransitionForAudit(from: from, to: to) { return .buildRoad }
    if isBuildSettlementTransitionForAudit(from: from, to: to) { return .buildSettlement }
    if isBuildCityTransitionForAudit(from: from, to: to) { return .buildCity }
    if isMaritimeTradeTransitionForAudit(from: from, to: to) { return .maritimeTrade }
    throw CoreGameError.auditLogInvalid
}
