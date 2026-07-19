import ULS_CoreGame

struct GameSetupPlacementModel: Equatable {
    enum Piece: Equatable {
        case settlement
        case road
        case done

        var label: String {
            switch self {
            case .settlement: return "Settlement"
            case .road: return "Road"
            case .done: return "Setup complete"
            }
        }
    }

    struct OrderEntry: Identifiable, Equatable {
        let id: Int
        let displayName: String
        let playerTint: GamePlayerTint
        let isCurrent: Bool
        let isComplete: Bool
    }

    let piece: Piece
    let isLocalPlayerActive: Bool
    let activePlayerDisplayName: String
    let placementNumber: Int
    let placementCount: Int
    let pairNumber: Int
    let order: [OrderEntry]

    var title: String {
        if isLocalPlayerActive {
            switch piece {
            case .settlement:
                return "Place Your " + pairOrdinal + " Settlement"
            case .road:
                return "Connect Your " + pairOrdinal + " Road"
            case .done:
                return "Setup Complete"
            }
        }

        return activePlayerDisplayName + " Is Placing"
    }

    var instruction: String {
        guard isLocalPlayerActive else {
            return "Waiting for settlement and road placement."
        }

        switch piece {
        case .settlement:
            return ""
        case .road:
            return "Choose a glowing road beside your new settlement."
        case .done:
            return "The first turn is ready."
        }
    }

    var progressLabel: String {
        "Placement " + String(placementNumber) + " of " + String(placementCount)
    }

    var visibleOrder: [OrderEntry] {
        guard let currentIndex = order.firstIndex(where: \.isCurrent) else {
            return []
        }

        return Array(order.dropFirst(currentIndex).prefix(3))
    }

    private var pairOrdinal: String {
        pairNumber == 1 ? "First" : "Second"
    }
}

enum GameSetupPlacementModelBuilder {
    static func build(
        state: CoreGameStateV1?,
        actingAs: String?,
        players: [GameInfoPlayerSummary]
    ) -> GameSetupPlacementModel? {
        guard
            let state,
            state.phase == .setup,
            let setup = state.setupState,
            !setup.order.isEmpty,
            setup.order.indices.contains(setup.turnIndex)
        else {
            return nil
        }

        let playersByID = Dictionary(uniqueKeysWithValues: players.map { ($0.id, $0) })
        let activeID = setup.order[setup.turnIndex]
        let rosterCount = max(state.roster.count, 1)

        return GameSetupPlacementModel(
            piece: piece(for: setup.step),
            isLocalPlayerActive: actingAs == activeID,
            activePlayerDisplayName: playersByID[activeID]?.displayName
                ?? PlayerPseudonymResolver.displayName(for: activeID, in: state),
            placementNumber: setup.turnIndex + 1,
            placementCount: setup.order.count,
            pairNumber: min((setup.turnIndex / rosterCount) + 1, 2),
            order: setup.order.enumerated().map { index, playerID in
                let player = playersByID[playerID]
                return GameSetupPlacementModel.OrderEntry(
                    id: index,
                    displayName: player?.displayName
                        ?? PlayerPseudonymResolver.displayName(for: playerID, in: state),
                    playerTint: player?.playerTint ?? GamePlayerTint(red: 0.58, green: 0.54, blue: 0.46),
                    isCurrent: index == setup.turnIndex,
                    isComplete: index < setup.turnIndex
                )
            }
        )
    }

    private static func piece(for step: SetupStepV1) -> GameSetupPlacementModel.Piece {
        switch step {
        case .placeSettlement: return .settlement
        case .placeRoad: return .road
        case .done: return .done
        }
    }
}
