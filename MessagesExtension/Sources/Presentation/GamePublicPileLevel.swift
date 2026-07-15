enum GamePublicPileLevel: String, Equatable {
    case high
    case medium
    case low

    var symbol: String {
        switch self {
        case .high: return "H"
        case .medium: return "M"
        case .low: return "L"
        }
    }

    var accessibilityLabel: String {
        rawValue.capitalized
    }

    static func resource(remaining: Int) -> GamePublicPileLevel {
        resolve(remaining: remaining, capacity: 19)
    }

    static func devCards(remaining: Int) -> GamePublicPileLevel {
        resolve(remaining: remaining, capacity: 25)
    }

    private static func resolve(
        remaining: Int,
        capacity: Int
    ) -> GamePublicPileLevel {
        let clampedRemaining = min(max(remaining, 0), capacity)
        if clampedRemaining * 3 >= capacity * 2 {
            return .high
        }
        if clampedRemaining * 3 >= capacity {
            return .medium
        }
        return .low
    }
}
