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
        actingAs: String?
    ) -> ULS_Transport.TurnIntentV1? {
        guard
            let state,
            state.phase == .turn,
            state.turnState?.step.allowsDevCardPlay == true,
            let actingAs,
            actingAs == state.currentPlayer,
            !state.devCardActionPlayedThisTurn,
            (state.devCardsByPlayer[actingAs] ?? .zero).knight > 0,
            let tileID = preferredKnightTileID(in: state, actor: actingAs)
        else {
            return nil
        }

        return ULS_Transport.TurnIntentV1(
            playDevCardKind: .knight,
            tileID: tileID,
            victimPlayer: state.defaultKnightVictim(for: tileID, actor: actingAs),
            gameId: state.gameId,
            anchorRev: state.rev,
            anchorHash: state.stateHash,
            actor: actingAs
        )
    }

    static func draftPlayMonopolyIntent(
        state: CoreGameStateV1?,
        actingAs: String?
    ) -> ULS_Transport.TurnIntentV1? {
        guard
            let state,
            state.phase == .turn,
            state.turnState?.step.allowsDevCardPlay == true,
            let actingAs,
            actingAs == state.currentPlayer,
            !state.devCardActionPlayedThisTurn,
            (state.devCardsByPlayer[actingAs] ?? .zero).monopoly > 0,
            let resource = state.defaultMonopolyResource(for: actingAs)
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
        actingAs: String?
    ) -> ULS_Transport.TurnIntentV1? {
        guard
            let state,
            state.phase == .turn,
            state.turnState?.step.allowsDevCardPlay == true,
            let actingAs,
            actingAs == state.currentPlayer,
            !state.devCardActionPlayedThisTurn,
            (state.devCardsByPlayer[actingAs] ?? .zero).yearOfPlenty > 0,
            let selection = state.defaultYearOfPlentyResources()
        else {
            return nil
        }

        return ULS_Transport.TurnIntentV1(
            playDevCardKind: .yearOfPlenty,
            firstResource: transportResource(from: selection.first),
            secondResource: transportResource(from: selection.second),
            gameId: state.gameId,
            anchorRev: state.rev,
            anchorHash: state.stateHash,
            actor: actingAs
        )
    }

    static func draftPlayRoadBuildingIntent(
        state: CoreGameStateV1?,
        actingAs: String?
    ) -> ULS_Transport.TurnIntentV1? {
        guard
            let state,
            state.phase == .turn,
            state.turnState?.step.allowsDevCardPlay == true,
            let actingAs,
            actingAs == state.currentPlayer,
            !state.devCardActionPlayedThisTurn,
            (state.devCardsByPlayer[actingAs] ?? .zero).roadBuilding > 0,
            let edges = state.defaultRoadBuildingEdges(for: actingAs)
        else {
            return nil
        }

        return ULS_Transport.TurnIntentV1(
            playDevCardKind: .roadBuilding,
            firstEdgeID: edges.firstEdgeID,
            secondEdgeID: edges.secondEdgeID,
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
            actingAs == state.currentPlayer
        else {
            return nil
        }

        let playable = state.devCardsByPlayer[actingAs] ?? .zero
        let newCards = state.newDevCardsByPlayer[actingAs] ?? .zero
        guard playable.victoryPoint > 0 || newCards.victoryPoint > 0 else {
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

    private static func preferredKnightTileID(in state: CoreGameStateV1, actor: String) -> TileID? {
        guard let board = state.board else {
            return nil
        }

        let candidateTiles = board.resourcesByTile.indices.filter { $0 != board.robberTile }
        if let victimTile = candidateTiles.first(where: { state.defaultKnightVictim(for: $0, actor: actor) != nil }) {
            return victimTile
        }
        return candidateTiles.first
    }
}
