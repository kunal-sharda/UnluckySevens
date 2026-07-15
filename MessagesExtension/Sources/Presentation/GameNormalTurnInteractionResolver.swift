struct GameNormalTurnContextSnapshot: Equatable {
    let gameID: String
    let revision: Int?
    let revisionText: String
    let stateHash: String
    let phase: String
    let turnStep: String
    let turnOwner: String
    let turnRecapMarker: String
    let isLocalActivePostRoll: Bool

    init(
        projection: GameShellProjection,
        isLocalActivePostRoll: Bool
    ) {
        gameID = projection.gameId
        revision = Int(projection.rev)
        revisionText = projection.rev
        stateHash = projection.stateHash
        phase = projection.phase
        turnStep = projection.turnStep
        turnOwner = projection.currentPlayer
        turnRecapMarker = projection.lastTurnRecapSummary
        self.isLocalActivePostRoll = isLocalActivePostRoll
    }

    init(
        gameID: String,
        revision: Int,
        stateHash: String,
        phase: String = "turn",
        turnStep: String = "afterRoll",
        turnOwner: String,
        turnRecapMarker: String = "previous-turn",
        isLocalActivePostRoll: Bool
    ) {
        self.gameID = gameID
        self.revision = revision
        revisionText = String(revision)
        self.stateHash = stateHash
        self.phase = phase
        self.turnStep = turnStep
        self.turnOwner = turnOwner
        self.turnRecapMarker = turnRecapMarker
        self.isLocalActivePostRoll = isLocalActivePostRoll
    }
}

enum GameNormalTurnContextTransition: Equatable {
    case inactive
    case entered
    case updated
    case left
    case replaced
}

struct GameNormalTurnRouteAvailability: Equatable {
    let canBuild: Bool
    let canTrade: Bool
    let canPlayDevCard: Bool
    let canEndTurn: Bool

    init(
        screenModel: GameScreenModel,
        hasTradePanel: Bool
    ) {
        canBuild = !screenModel.actionDock.buildShelfItems.isEmpty
        canTrade = screenModel.modeAvailability.canTrade && hasTradePanel
        canPlayDevCard = screenModel.modeAvailability.canPlayDevCard
        canEndTurn = screenModel.actionDock.primaryItems.contains {
            $0.kind == .endTurn && $0.isEnabled
        }
    }

    init(
        canBuild: Bool,
        canTrade: Bool,
        canPlayDevCard: Bool,
        canEndTurn: Bool
    ) {
        self.canBuild = canBuild
        self.canTrade = canTrade
        self.canPlayDevCard = canPlayDevCard
        self.canEndTurn = canEndTurn
    }
}

enum GameNormalTurnInteractionResolver {
    static func transition(
        from previous: GameNormalTurnContextSnapshot,
        to next: GameNormalTurnContextSnapshot
    ) -> GameNormalTurnContextTransition {
        switch (previous.isLocalActivePostRoll, next.isLocalActivePostRoll) {
        case (false, false):
            return .inactive
        case (false, true):
            return .entered
        case (true, false):
            return .left
        case (true, true):
            break
        }

        guard hasSameCanonicalContext(previous, next) else {
            return .replaced
        }

        // A forward revision is an in-place update to the same turn. Buying a
        // card, building, revealing Bank counts, and trade responses must not
        // bounce the player back to Hand. A regression, or a different state
        // at the same revision, means the selected canonical context changed.
        switch (previous.revision, next.revision) {
        case let (oldRevision?, newRevision?) where newRevision < oldRevision:
            return .replaced
        case let (oldRevision?, newRevision?) where newRevision == oldRevision:
            return previous.stateHash == next.stateHash ? .updated : .replaced
        case (nil, nil) where previous.revisionText != next.revisionText:
            return .replaced
        default:
            return .updated
        }
    }

    static func normalizedRoute(
        _ route: GameShellRoute,
        availability: GameNormalTurnRouteAvailability
    ) -> GameShellRoute {
        switch route {
        case .build where !availability.canBuild:
            return .none
        case .trade where !availability.canTrade:
            return .none
        case .devCards where !availability.canPlayDevCard:
            return .none
        case .endTurnConfirmation where !availability.canEndTurn:
            return .none
        case .none,
             .utility,
             .build,
             .devCards,
             .trade,
             .endTurnConfirmation,
             .gameInfo:
            return route
        }
    }

    private static func hasSameCanonicalContext(
        _ lhs: GameNormalTurnContextSnapshot,
        _ rhs: GameNormalTurnContextSnapshot
    ) -> Bool {
        lhs.gameID == rhs.gameID
            && lhs.phase == rhs.phase
            && lhs.turnStep == rhs.turnStep
            && lhs.turnOwner == rhs.turnOwner
            && lhs.turnRecapMarker == rhs.turnRecapMarker
    }
}
