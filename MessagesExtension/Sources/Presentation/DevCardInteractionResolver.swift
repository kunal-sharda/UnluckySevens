import ULS_CoreGame
import ULS_Transport

enum DevCardInteractionResolver {
    static func draftBuyDevCardIntent(
        state: CoreGameStateV1?,
        actingAs: String?
    ) -> ULS_Transport.TurnIntentV1? {
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
        guard hand.sheep >= 1, hand.wheat >= 1, hand.ore >= 1 else {
            return nil
        }

        return ULS_Transport.TurnIntentV1(
            kind: .buyDevCard,
            gameId: state.gameId,
            anchorRev: state.rev,
            anchorHash: state.stateHash,
            actor: actingAs
        )
    }

    static func draftPlayKnightIntent(
        state: CoreGameStateV1?,
        actingAs: String?,
        tileID: TileID,
        victimPlayer: String?
    ) -> ULS_Transport.TurnIntentV1? {
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

        return ULS_Transport.TurnIntentV1(
            playDevCardKind: .knight,
            tileID: tileID,
            victimPlayer: victimPlayer,
            gameId: state.gameId,
            anchorRev: state.rev,
            anchorHash: state.stateHash,
            actor: actingAs
        )
    }

    static func draftPlayMonopolyIntent(
        state: CoreGameStateV1?,
        actingAs: String?,
        resource: ResourceV1
    ) -> ULS_Transport.TurnIntentV1? {
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

        return ULS_Transport.TurnIntentV1(
            playDevCardKind: .monopoly,
            resource: transportResource(from: resource),
            gameId: state.gameId,
            anchorRev: state.rev,
            anchorHash: state.stateHash,
            actor: actingAs
        )
    }

    static func draftPlayYearOfPlentyIntent(
        state: CoreGameStateV1?,
        actingAs: String?,
        firstResource: ResourceV1,
        secondResource: ResourceV1
    ) -> ULS_Transport.TurnIntentV1? {
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

        return ULS_Transport.TurnIntentV1(
            playDevCardKind: .yearOfPlenty,
            firstResource: transportResource(from: firstResource),
            secondResource: transportResource(from: secondResource),
            gameId: state.gameId,
            anchorRev: state.rev,
            anchorHash: state.stateHash,
            actor: actingAs
        )
    }

    static func draftPlayRoadBuildingIntent(
        state: CoreGameStateV1?,
        actingAs: String?,
        firstEdgeID: EdgeID,
        secondEdgeID: EdgeID
    ) -> ULS_Transport.TurnIntentV1? {
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

        return ULS_Transport.TurnIntentV1(
            playDevCardKind: .roadBuilding,
            firstEdgeID: firstEdgeID,
            secondEdgeID: secondEdgeID,
            gameId: state.gameId,
            anchorRev: state.rev,
            anchorHash: state.stateHash,
            actor: actingAs
        )
    }

    static func draftRevealVictoryPointIntent(
        state: CoreGameStateV1?,
        actingAs: String?
    ) -> ULS_Transport.TurnIntentV1? {
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

        return ULS_Transport.TurnIntentV1(
            playDevCardKind: .revealVictoryPoint,
            gameId: state.gameId,
            anchorRev: state.rev,
            anchorHash: state.stateHash,
            actor: actingAs
        )
    }

    private static func transportResource(from resource: ResourceV1) -> TransportResourceV1 {
        switch resource {
        case .wood:
            return .wood
        case .brick:
            return .brick
        case .sheep:
            return .sheep
        case .wheat:
            return .wheat
        case .ore:
            return .ore
        case .desert:
            return .wood
        }
    }
}
