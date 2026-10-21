import ULS_CoreGame

extension ReliabilityDiagnosticBuffer.Action {
    static func dock(_ kind: GameActionDockItem.Kind) -> Self {
        switch kind {
        case .roll: .roll
        case .endTurn: .endTurn
        case .build: .build
        case .trade: .trade
        case .devCards: .developmentCard
        }
    }

    /// Categories only: associated values can contain private cards or participant IDs.
    static func turn(_ intent: TurnIntentV1) -> Self {
        switch intent {
        case .rollDice: .roll
        case .submitDiscard: .discard
        case .moveRobber, .selectStealVictim: .robber
        case .buildRoad, .buildSettlement, .buildCity: .build
        case .proposeTrade, .acceptTrade, .declineTrade, .counterTrade, .maritimeTrade: .trade
        case .buyDevCard, .playKnight, .playMonopoly, .playYearOfPlenty,
             .playRoadBuilding, .revealVictoryPoint: .developmentCard
        case .endTurn: .endTurn
        }
    }
}
