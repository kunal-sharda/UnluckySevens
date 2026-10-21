enum GameLifecycleMenuGuidance {
    static func message(
        hasCurrentGame: Bool,
        hasLocalActor: Bool,
        hasCompatibleActiveConversation: Bool,
        hasAvailableAction: Bool
    ) -> String? {
        if hasAvailableAction {
            return nil
        }
        guard hasCurrentGame else {
            return "Open an active game to view game actions."
        }
        guard hasLocalActor else {
            return "Game actions are read-only because this device cannot identify you as a player."
        }
        guard hasCompatibleActiveConversation else {
            return "Open this game from its Messages bubble to use game actions."
        }
        return "No current game actions are available."
    }
}
