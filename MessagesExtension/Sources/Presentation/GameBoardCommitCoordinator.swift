enum GameBoardCommitCoordinator {
    enum Decision: Equatable {
        case invalid(String?)
        case selected(GameBoardCommitDraft)
        case confirm(GameBoardCommitDraft)
    }

    static func handles(mode: GameMode) -> Bool {
        switch mode {
        case .setup, .buildRoad, .buildSettlement, .buildCity:
            return true
        case .idle,
             .robberMove,
             .robberVictim,
             .trade,
             .playDevCard,
             .devCardKnightMove,
             .devCardKnightVictim,
             .devCardMonopoly,
             .devCardYearOfPlenty,
             .devCardRoadBuildingFirst,
             .devCardRoadBuildingSecond,
             .discard:
            return false
        }
    }

    static func decision(
        existingDraft: GameBoardCommitDraft?,
        normalizedTarget: GameBoardTarget?,
        mode: GameMode
    ) -> Decision? {
        guard handles(mode: mode) else {
            return nil
        }

        guard let normalizedTarget else {
            return .invalid(failureHint(for: mode))
        }

        let draft = GameBoardCommitDraft(mode: mode, target: normalizedTarget)
        if existingDraft == draft {
            return .confirm(draft)
        }

        return .selected(draft)
    }

    private static func failureHint(for mode: GameMode) -> String? {
        switch mode {
        case .setup, .buildSettlement:
            return "Tap node"
        case .buildRoad:
            return "Tap road"
        case .buildCity:
            return "Tap city"
        case .idle,
             .robberMove,
             .robberVictim,
             .trade,
             .playDevCard,
             .devCardKnightMove,
             .devCardKnightVictim,
             .devCardMonopoly,
             .devCardYearOfPlenty,
             .devCardRoadBuildingFirst,
             .devCardRoadBuildingSecond,
             .discard:
            return nil
        }
    }
}
