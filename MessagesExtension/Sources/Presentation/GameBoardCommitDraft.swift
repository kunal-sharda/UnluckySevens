import Foundation

struct GameBoardCommitDraft: Equatable {
    let mode: GameMode
    let target: GameBoardTarget

    var title: String {
        switch actionKind {
        case .setupSettlement:
            return "Place Settlement"
        case .setupRoad:
            return "Place Road"
        case .buildRoad:
            return "Build Road"
        case .buildSettlement:
            return "Build Settlement"
        case .buildCity:
            return "Build City"
        }
    }

    var message: String {
        switch actionKind {
        case .setupSettlement, .buildSettlement:
            return "Confirm this settlement location."
        case .setupRoad, .buildRoad:
            return "Confirm this road placement."
        case .buildCity:
            return "Confirm this city upgrade."
        }
    }

    var confirmTitle: String {
        title
    }

    var summaryText: String {
        target.selectionLabel(for: mode)
    }

    var hintText: String {
        "Tap again or confirm"
    }

    private var actionKind: ActionKind {
        switch (mode, target) {
        case (.setup, .node):
            return .setupSettlement
        case (.setup, .edge):
            return .setupRoad
        case (.buildRoad, .edge):
            return .buildRoad
        case (.buildSettlement, .node):
            return .buildSettlement
        case (.buildCity, .node):
            return .buildCity
        default:
            return .buildSettlement
        }
    }

    private enum ActionKind {
        case setupSettlement
        case setupRoad
        case buildRoad
        case buildSettlement
        case buildCity
    }
}
