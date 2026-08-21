import ULS_CoreGame

enum DevCardInteractionResolver {
    static func draftBuyDevCardIntent(
        state: CoreGameStateV1?,
        actingAs: String?
    ) -> TurnActionDraft? {
        guard
            let state,
            state.phase == .turn,
            state.turnState?.step == .afterRoll,
            let actingAs,
            actingAs == state.currentPlayer,
            !state.devDeck.isEmpty
        else {
            return nil
        }

        let hand = state.resourcesByPlayer[actingAs] ?? .zero
        guard canAfford(hand: hand, cost: CoreBuildCostsV1.developmentCard) else {
            return nil
        }

        return TurnActionDraft(
            intent: .buyDevCard,
            actor: actingAs,
            state: state
        )
    }

    private static func canAfford(hand: ResourceHandV1, cost: ResourceHandV1) -> Bool {
        hand.wood >= cost.wood &&
            hand.brick >= cost.brick &&
            hand.sheep >= cost.sheep &&
            hand.wheat >= cost.wheat &&
            hand.ore >= cost.ore
    }

    static func draftPlayKnightIntent(
        state: CoreGameStateV1?,
        actingAs: String?,
        tileID: TileID,
        victimPlayer: String?
    ) -> TurnActionDraft? {
        guard
            let state,
            state.phase == .turn,
            state.turnState?.step.allowsDevCardPlay == true,
            let actingAs,
            actingAs == state.currentPlayer,
            !state.devCardActionPlayedThisTurn,
            (state.devCardsByPlayer[actingAs] ?? .zero).knight > 0,
            state.legalKnightMoveTilesForDevCard(for: actingAs).contains(tileID)
        else {
            return nil
        }

        let legalVictims = state.legalKnightVictims(for: tileID, actor: actingAs)
        guard victimPlayer == nil || legalVictims.contains(victimPlayer!) else {
            return nil
        }

        return TurnActionDraft(
            intent: .playKnight(tileID: tileID, victimPlayer: victimPlayer),
            actor: actingAs,
            state: state
        )
    }

    static func draftPlayMonopolyIntent(
        state: CoreGameStateV1?,
        actingAs: String?,
        resource: ResourceV1
    ) -> TurnActionDraft? {
        guard
            let state,
            state.phase == .turn,
            state.turnState?.step.allowsDevCardPlay == true,
            let actingAs,
            actingAs == state.currentPlayer,
            !state.devCardActionPlayedThisTurn,
            (state.devCardsByPlayer[actingAs] ?? .zero).monopoly > 0,
            resource != .desert
        else {
            return nil
        }

        return TurnActionDraft(
            intent: .playMonopoly(resource: resource),
            actor: actingAs,
            state: state
        )
    }

    static func draftPlayYearOfPlentyIntent(
        state: CoreGameStateV1?,
        actingAs: String?,
        firstResource: ResourceV1,
        secondResource: ResourceV1
    ) -> TurnActionDraft? {
        guard
            let state,
            state.phase == .turn,
            state.turnState?.step.allowsDevCardPlay == true,
            let actingAs,
            actingAs == state.currentPlayer,
            !state.devCardActionPlayedThisTurn,
            (state.devCardsByPlayer[actingAs] ?? .zero).yearOfPlenty > 0
        else {
            return nil
        }
        guard firstResource != .desert, secondResource != .desert else {
            return nil
        }
        let options = Dictionary(
            uniqueKeysWithValues: state.yearOfPlentyBankOptions(for: actingAs).map { ($0.resource, $0.remainingCount) }
        )
        guard options[firstResource] != nil else {
            return nil
        }
        if firstResource == secondResource {
            guard (options[firstResource] ?? 0) >= 2 else {
                return nil
            }
        } else {
            guard options[secondResource] != nil else {
                return nil
            }
        }

        return TurnActionDraft(
            intent: .playYearOfPlenty(first: firstResource, second: secondResource),
            actor: actingAs,
            state: state
        )
    }

    static func draftPlayRoadBuildingIntent(
        state: CoreGameStateV1?,
        actingAs: String?,
        firstEdgeID: EdgeID,
        secondEdgeID: EdgeID
    ) -> TurnActionDraft? {
        guard
            let state,
            state.phase == .turn,
            state.turnState?.step.allowsDevCardPlay == true,
            let actingAs,
            actingAs == state.currentPlayer,
            !state.devCardActionPlayedThisTurn,
            (state.devCardsByPlayer[actingAs] ?? .zero).roadBuilding > 0,
            state.legalRoadBuildingFirstEdges(for: actingAs).contains(firstEdgeID),
            state.legalRoadBuildingSecondEdges(for: actingAs, firstEdgeID: firstEdgeID).contains(secondEdgeID)
        else {
            return nil
        }

        return TurnActionDraft(
            intent: .playRoadBuilding(firstEdgeID: firstEdgeID, secondEdgeID: secondEdgeID),
            actor: actingAs,
            state: state
        )
    }

    static func draftRevealVictoryPointIntent(
        state: CoreGameStateV1?,
        actingAs: String?
    ) -> TurnActionDraft? {
        guard
            let state,
            state.phase == .turn,
            state.turnState?.step.allowsDevCardPlay == true,
            let actingAs,
            actingAs == state.currentPlayer,
            state.canRevealVictoryPoint(for: actingAs)
        else {
            return nil
        }

        return TurnActionDraft(
            intent: .revealVictoryPoint,
            actor: actingAs,
            state: state
        )
    }
}
