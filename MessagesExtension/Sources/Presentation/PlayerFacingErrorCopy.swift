enum PlayerFacingErrorCopy {
    static func message(for rawMessage: String) -> String {
        let message = rawMessage.lowercased()

        if message.contains("at least two players") {
            return "At least two players need to join before you can start."
        }
        if message.contains("enter a new name") {
            return "Enter a different display name before saving."
        }
        if message.contains("only the inviter") {
            return "Only the host can start the game."
        }
        if message.contains("only current player") {
            return "It's not your turn yet."
        }
        if message.contains("missing local participant")
            || message.contains("local player identity")
            || message.contains("device has not joined") {
            return "Open the latest invite, join the table, and try again."
        }
        if message.contains("select")
            && (message.contains("bubble")
                || message.contains("state")
                || message.contains("active context")) {
            return "Reopen the latest game message and try again."
        }
        if message.contains("invite failed") {
            return "Couldn't send the invite. Check your connection and try again."
        }
        if message.contains("join failed") {
            return "Couldn't join the table. Reopen the latest invite and try again."
        }
        if message.contains("name update failed") {
            return "Couldn't save your display name. Try again."
        }
        if message.contains("start failed") || message.contains("initialize setup") {
            return "Couldn't start the game. Reopen the latest invite and try again."
        }
        if message.contains("publish failed") || message.contains("publication failed") {
            return "Couldn't send the game update. Check your connection and try again."
        }
        if message.contains("decode")
            || message.contains("payload")
            || message.contains("missing required fields") {
            return "Couldn't open this game message. Ask the sender to resend it."
        }
        if message.contains("discard") {
            return "Couldn't send your discard. Reopen the latest game message and try again."
        }
        if message.contains("trade") {
            if message.contains("not legal") || message.contains("no legal") {
                return "That trade is no longer available. Reopen the latest game message."
            }
            return "Couldn't send the trade. Reopen the latest game message and try again."
        }
        if message.contains("dev-card")
            || message.contains("development card")
            || message.contains("knight play")
            || message.contains("monopoly needs")
            || message.contains("year of plenty")
            || message.contains("road building") {
            return "That development card isn't available now."
        }
        if message.contains("turn action")
            || message.contains("setup placement")
            || message.contains("build target")
            || message.contains("robber")
            || message.contains("steal selection")
            || message.contains("not legal in current") {
            return "That move is no longer available. Reopen the latest game message."
        }
        return "Something went wrong. Reopen the latest game message and try again."
    }
}
