import Foundation

enum GameControlInteraction: String, Codable, CaseIterable {
    case bank, publicDev, hand, boardConfirmed, trade, ownedDev, players, endTurn
}

struct GameControlsTourProgress: Codable, Equatable {
    var index = 0
    var completed: Set<GameControlInteraction> = []

    var isComplete: Bool { completed.count == GameControlInteraction.allCases.count }

    mutating func record(_ interaction: GameControlInteraction) {
        guard index < GameControlInteraction.allCases.count,
              GameControlInteraction.allCases[index] == interaction else { return }
        completed.insert(interaction)
    }

    mutating func advance() {
        index = min(index + 1, GameControlInteraction.allCases.count)
    }

    mutating func back() {
        index = max(0, index - 1)
    }
}
