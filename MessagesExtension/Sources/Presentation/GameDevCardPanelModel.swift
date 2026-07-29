struct GameDevCardCount: Identifiable, Equatable {
    let title: String
    let count: Int

    var id: String { title }
}

enum GameDevCardVisualKind: String, CaseIterable, Identifiable, Equatable, Hashable {
    case knight
    case monopoly
    case yearOfPlenty
    case roadBuilding
    case victoryPoint

    var id: String { rawValue }

    var title: String {
        switch self {
        case .knight:
            return "Knight"
        case .monopoly:
            return "Monopoly"
        case .yearOfPlenty:
            return "Year of Plenty"
        case .roadBuilding:
            return "Road Building"
        case .victoryPoint:
            return "Victory Point"
        }
    }

    var systemImage: String {
        switch self {
        case .knight:
            return "shield.lefthalf.filled"
        case .monopoly:
            return "shippingbox.fill"
        case .yearOfPlenty:
            return "leaf.fill"
        case .roadBuilding:
            return "road.lanes"
        case .victoryPoint:
            return "star.fill"
        }
    }

    var actionKind: GameDevCardActionKind {
        switch self {
        case .knight:
            return .playKnight
        case .monopoly:
            return .playMonopoly
        case .yearOfPlenty:
            return .playYearOfPlenty
        case .roadBuilding:
            return .playRoadBuilding
        case .victoryPoint:
            return .revealVictoryPoint
        }
    }
}

enum GameDevCardActionKind: String, Equatable {
    case buyDevCard
    case playKnight
    case playMonopoly
    case playYearOfPlenty
    case playRoadBuilding
    case revealVictoryPoint
}

struct GameDevCardAction: Identifiable, Equatable {
    let kind: GameDevCardActionKind
    let title: String
    let detail: String
    let systemImage: String

    var id: String { kind.rawValue }
}

struct GameDevCardTileModel: Identifiable, Equatable {
    let kind: GameDevCardVisualKind
    let count: Int
    let statusText: String
    let detailText: String
    let actionKind: GameDevCardActionKind?
    let isEnabled: Bool
    let isSelected: Bool

    var id: GameDevCardVisualKind { kind }
}

struct GameDevCardPanelModel: Equatable {
    let message: String
    let cards: [GameDevCardTileModel]
    let playableCounts: [GameDevCardCount]
    let heldCounts: [GameDevCardCount]
    let newCounts: [GameDevCardCount]
    let playActions: [GameDevCardAction]
    let timingNotes: [String]
    let draftSummary: String?
    let confirmTitle: String?
    let canConfirm: Bool
    let showsBackButton: Bool

    func executableSelectionOnly() -> GameDevCardPanelModel {
        GameDevCardPanelModel(
            message: message,
            cards: cards.filter { $0.isEnabled || $0.isSelected },
            playableCounts: playableCounts,
            heldCounts: heldCounts,
            newCounts: newCounts,
            playActions: playActions,
            timingNotes: timingNotes,
            draftSummary: draftSummary,
            confirmTitle: confirmTitle,
            canConfirm: canConfirm,
            showsBackButton: showsBackButton
        )
    }
}
