enum GameModeResolver {
    static func normalized(
        currentMode: GameMode,
        availability: GameModeAvailability
    ) -> GameMode {
        if let forcedMode = forcedMode(for: availability) {
            return forcedMode
        }

        if isAvailable(currentMode, in: availability) {
            return currentMode
        }

        return .idle
    }

    static func nextMode(
        for actionKind: GameActionDockItem.Kind,
        currentMode: GameMode,
        availability: GameModeAvailability
    ) -> GameMode {
        if let forcedMode = forcedMode(for: availability) {
            return forcedMode
        }

        switch actionKind {
        case .build:
            return nextBuildMode(currentMode: currentMode, availability: availability)
        case .trade:
            return toggle(mode: .trade, currentMode: currentMode, isAvailable: availability.canTrade)
        case .devCards:
            return toggle(mode: .playDevCard, currentMode: currentMode, isAvailable: availability.canPlayDevCard)
        case .roll, .endTurn:
            return .idle
        }
    }

    private static func forcedMode(for availability: GameModeAvailability) -> GameMode? {
        if availability.canSetup {
            return .setup
        }
        if availability.canDiscard {
            return .discard
        }
        if availability.canRobberMove {
            return .robberMove
        }
        if availability.canRobberVictim {
            return .robberVictim
        }
        return nil
    }

    private static func isAvailable(_ mode: GameMode, in availability: GameModeAvailability) -> Bool {
        switch mode {
        case .idle:
            return true
        case .setup:
            return availability.canSetup
        case .buildRoad:
            return availability.canBuildRoad
        case .buildSettlement:
            return availability.canBuildSettlement
        case .buildCity:
            return availability.canBuildCity
        case .robberMove:
            return availability.canRobberMove
        case .robberVictim:
            return availability.canRobberVictim
        case .trade:
            return availability.canTrade
        case .playDevCard:
            return availability.canPlayDevCard
        case .discard:
            return availability.canDiscard
        }
    }

    private static func nextBuildMode(
        currentMode: GameMode,
        availability: GameModeAvailability
    ) -> GameMode {
        let buildModes = availableBuildModes(in: availability)
        guard !buildModes.isEmpty else {
            return .idle
        }

        guard let index = buildModes.firstIndex(of: currentMode) else {
            return buildModes[0]
        }

        let nextIndex = buildModes.index(after: index)
        if nextIndex == buildModes.endIndex {
            return .idle
        }

        return buildModes[nextIndex]
    }

    private static func availableBuildModes(in availability: GameModeAvailability) -> [GameMode] {
        var modes: [GameMode] = []
        if availability.canBuildRoad {
            modes.append(.buildRoad)
        }
        if availability.canBuildSettlement {
            modes.append(.buildSettlement)
        }
        if availability.canBuildCity {
            modes.append(.buildCity)
        }
        return modes
    }

    private static func toggle(
        mode: GameMode,
        currentMode: GameMode,
        isAvailable: Bool
    ) -> GameMode {
        guard isAvailable else {
            return .idle
        }
        return currentMode == mode ? .idle : mode
    }
}
