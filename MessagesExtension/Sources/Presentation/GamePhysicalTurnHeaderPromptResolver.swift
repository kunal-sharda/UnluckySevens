enum GamePhysicalTurnHeaderPromptResolver {
    static func prompt(
        route: GameShellRoute,
        mode: GameMode,
        hasBoardCommitDraft: Bool,
        devCardDraft: GameDevCardDraft?
    ) -> GamePhysicalTurnHeaderPrompt? {
        switch route {
        case .trade(.chooser):
            return .chooseTrade
        case .trade(.playerDraft):
            return .makeOffer
        case .trade(.maritime):
            return .tradeWithBank
        case .trade(.liveOffer):
            return .waitingForPlayers
        case .build where mode == .idle:
            return .choosePiece
        case .devCards where mode == .playDevCard:
            return .chooseDevCard
        case .none, .utility, .build, .devCards, .endTurnConfirmation, .gameInfo:
            break
        }

        switch mode {
        case .buildRoad:
            return hasBoardCommitDraft ? .tapAgainToPlace : .placeRoad
        case .buildSettlement:
            return hasBoardCommitDraft ? .tapAgainToPlace : .placeSettlement
        case .buildCity:
            return hasBoardCommitDraft ? .tapAgainToUpgrade : .upgradeCity
        case .devCardKnightMove:
            return .moveRobber
        case .devCardKnightVictim:
            return .choosePlayer
        case .devCardMonopoly:
            return .chooseResource
        case .devCardYearOfPlenty:
            return yearOfPlentyPrompt(for: devCardDraft)
        case .devCardRoadBuildingFirst:
            return .placeFirstRoad
        case .devCardRoadBuildingSecond:
            return .placeSecondRoad
        case .idle,
             .setup,
             .robberMove,
             .robberVictim,
             .trade,
             .playDevCard,
             .discard:
            return nil
        }
    }

    private static func yearOfPlentyPrompt(
        for draft: GameDevCardDraft?
    ) -> GamePhysicalTurnHeaderPrompt? {
        guard case let .yearOfPlenty(first, second) = draft else {
            return .chooseTwoResources
        }
        if first == nil {
            return .chooseTwoResources
        }
        if second == nil {
            return .chooseOneMore
        }
        return nil
    }
}
