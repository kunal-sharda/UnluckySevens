enum TranscriptDidReceiveDisposition: Equatable {
    case applyToActiveContext
    case storeForRecoveryOnly

    var label: String {
        switch self {
        case .applyToActiveContext:
            return "apply"
        case .storeForRecoveryOnly:
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
        guard trigger == .didReceive else {
            return .applyToActiveContext
        }

        guard let currentGameId, let incomingGameId else {
            return .applyToActiveContext
        }

        if incomingGameId == currentGameId {
            return .applyToActiveContext
        }

        return .storeForRecoveryOnly
    }
}
