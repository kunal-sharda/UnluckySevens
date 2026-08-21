enum MessagesLaunchRoute: Equatable {
    case freshLobby
    case selectedMessage

    static func resolve(hasSelectedMessage: Bool) -> Self {
        hasSelectedMessage ? .selectedMessage : .freshLobby
    }
}
