enum TranscriptDidReceiveDisposition: Equatable {
    case applyToActiveContext
    case storeInLedgerOnly

    var label: String {
        switch self {
        case .applyToActiveContext:
            return "apply"
        case .storeInLedgerOnly:
            return "storeOnly"
        }
    }
}

enum TranscriptDidReceiveContract {
    static func disposition(
        trigger: TranscriptSelectionTrigger,
        incomingGameId: String?,
        currentGameId: String?
    ) -> TranscriptDidReceiveDisposition {
        // didReceive and selectionPoll are implicit host observations. Neither may
        // replace the game established by explicit bubble selection. Bubble
        // selection and initial hydration are the only explicit context switches.
        guard trigger == .didReceive || trigger == .selectionPoll else {
            return .applyToActiveContext
        }

        guard let currentGameId, let incomingGameId else {
            return .applyToActiveContext
        }

        if incomingGameId == currentGameId {
            return .applyToActiveContext
        }

        return .storeInLedgerOnly
    }
}
