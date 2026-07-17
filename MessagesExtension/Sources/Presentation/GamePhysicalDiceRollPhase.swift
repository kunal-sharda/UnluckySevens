import Foundation

enum GamePhysicalDiceRollPhase: Equatable {
    case rolling
    case settled

    var instruction: String {
        switch self {
        case .rolling:
            "Tap to skip"
        case .settled:
            "Tap to continue"
        }
    }

    var accessibilityHint: String {
        switch self {
        case .rolling:
            "Skips the remaining dice animation"
        case .settled:
            "Continues to your turn"
        }
    }
}
