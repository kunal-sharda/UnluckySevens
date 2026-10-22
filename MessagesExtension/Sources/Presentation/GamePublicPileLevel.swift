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

    /// Coarse thirds deliberately conceal exact inventory, including within each band.
    static func resourceFilledSegments(remaining: Int) -> Int {
        guard remaining > 0 else { return 0 }
        return resource(remaining: remaining).filledSegments
    }

    static func devCardFilledSegments(remaining: Int) -> Int {
        guard remaining > 0 else { return 0 }
        return devCards(remaining: remaining).filledSegments
    }

    private var filledSegments: Int {
        switch self {
        case .high: return 3
        case .medium: return 2
        case .low: return 1
        }
    }

    static func devCardSupplyDescription(remaining: Int) -> String {
        guard remaining > 0 else { return "Dev Card supply empty" }
        return "Dev Card supply \(devCards(remaining: remaining).accessibilityLabel)"
    }

    static func resourceSupplyDescription(remaining: Int) -> String {
        guard remaining > 0 else { return "Bank supply empty" }
        return "Bank supply \(resource(remaining: remaining).accessibilityLabel)"
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
