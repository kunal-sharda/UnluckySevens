enum MessagesLaunchRoute: Equatable {
    case freshLobby
    case selectedMessage

    var requestsExpandedPresentation: Bool {
        self == .selectedMessage
    }

    static func resolve(hasSelectedMessage: Bool) -> Self {
        hasSelectedMessage ? .selectedMessage : .freshLobby
    }
}
