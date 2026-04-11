struct GameDevCardCount: Identifiable, Equatable {
    let title: String
    let count: Int

    var id: String { title }
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

struct GameDevCardPanelModel: Equatable {
    let message: String
    let playableCounts: [GameDevCardCount]
    let heldCounts: [GameDevCardCount]
    let newCounts: [GameDevCardCount]
    let playActions: [GameDevCardAction]
    let timingNotes: [String]
    let draftSummary: String?
    let confirmTitle: String?
    let canConfirm: Bool
    let showsBackButton: Bool
}
