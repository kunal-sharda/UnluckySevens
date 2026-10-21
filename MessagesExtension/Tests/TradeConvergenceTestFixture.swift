import ULS_CoreGame

private enum TradeConvergenceTestFixtureError: Error {
    case missingOffer
}

func makeCompetingTradeAcceptBranches() throws -> (
    acceptedByB: CoreGameStateV1,
    acceptedByC: CoreGameStateV1,
    losingDescendant: CoreGameStateV1,
    winner: CoreGameStateV1,
    loser: CoreGameStateV1,
    context: CanonicalStateConvergenceContextV1
) {
    let base = CoreGameStateV1(
        gameId: "message-trade-contention",
        rev: 20,
        prevHash: "hash-19",
        stateHash: "",
        roster: ["A", "B", "C"],
        currentPlayer: "A",
        phase: .turn,
        seed: 1,
        diceRngState: 2,
        robberRngState: 3,
        resourcesByPlayer: [
            "A": ResourceHandV1(wood: 2),
            "B": ResourceHandV1(brick: 2),
            "C": ResourceHandV1(brick: 2),
        ],
        bankResources: .standardBank,
        turnState: TurnStateV1(step: .afterRoll, lastRoll: DiceRollV1(d1: 4, d2: 3))
    ).rehashed()
    let proposed = try apply(
        intent: .proposeTrade(
            give: ResourceHandV1(wood: 1),
            receive: ResourceHandV1(brick: 1),
            recipients: ["B", "C"]
        ),
        to: base,
        actor: "A"
    )
    guard let offerHash = proposed.activeTradeOffer?.offerHash else {
        throw TradeConvergenceTestFixtureError.missingOffer
    }
    let acceptedByB = try apply(
        intent: .acceptTrade(acceptingPlayer: "B", offerHash: offerHash),
        to: proposed,
        actor: "B"
    )
    let acceptedByC = try apply(
        intent: .acceptTrade(acceptingPlayer: "C", offerHash: offerHash),
        to: proposed,
        actor: "C"
    )
    let winner = CanonicalStatePreferenceV1.prefers(acceptedByB, over: acceptedByC)
        ? acceptedByB
        : acceptedByC
    let loser = winner.stateHash == acceptedByB.stateHash ? acceptedByC : acceptedByB
    let losingDescendant = try apply(intent: .endTurn, to: loser, actor: "A")
    var context = CanonicalStateConvergenceContextV1()
    context.observe(acceptedByB)
    context.observe(acceptedByC)
    return (acceptedByB, acceptedByC, losingDescendant, winner, loser, context)
}
