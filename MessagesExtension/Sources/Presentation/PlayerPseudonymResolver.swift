enum PlayerPseudonymResolver {
    private static let aliasPool = [
        "SheepGrazer",
        "BrickLayer",
        "OreMiner",
        "WoodCutter",
        "WheatFarmer",
    ]

    static func displayName(for playerID: String?, gameID: String?, roster: [String]) -> String {
        guard let playerID else {
            return "the host"
        }

        let mapping = displayNames(for: gameID, roster: roster + [playerID])
        return mapping[playerID] ?? fallbackName(for: playerID)
    }

    static func displayNames(for gameID: String?, roster: [String]) -> [String: String] {
        let uniqueRoster = uniquePlayers(in: roster)
        guard !uniqueRoster.isEmpty else {
            return [:]
        }

        let seed = stableHash(gameID ?? uniqueRoster.sorted().joined(separator: "|"))
        let aliasOrder = shuffledAliases(seed: seed)
        let playerOrder = uniqueRoster.sorted {
            playerScore($0, seed: seed) < playerScore($1, seed: seed)
        }

        let assignmentCount = min(playerOrder.count, aliasOrder.count)
        var mapping: [String: String] = [:]
        for index in 0..<assignmentCount {
            mapping[playerOrder[index]] = aliasOrder[index]
        }

        return mapping
    }

    private static func uniquePlayers(in roster: [String]) -> [String] {
        var seen: Set<String> = []
        var result: [String] = []

        for player in roster where seen.insert(player).inserted {
            result.append(player)
        }

        return result
    }

    private static func shuffledAliases(seed: UInt64) -> [String] {
        var aliases = aliasPool
        guard aliases.count > 1 else {
            return aliases
        }

        var generator = SeededGenerator(seed: seed)
        for index in stride(from: aliases.count - 1, through: 1, by: -1) {
            let swapIndex = Int(generator.next() % UInt64(index + 1))
            aliases.swapAt(index, swapIndex)
        }

        return aliases
    }

    private static func playerScore(_ playerID: String, seed: UInt64) -> UInt64 {
        stableHash("\(seed)|\(playerID)")
    }

    private static func fallbackName(for playerID: String) -> String {
        let seed = stableHash(playerID)
        return aliasPool[Int(seed % UInt64(aliasPool.count))]
    }

    private static func stableHash(_ value: String) -> UInt64 {
        var hash: UInt64 = 0xcbf29ce484222325
        for byte in value.utf8 {
            hash ^= UInt64(byte)
            hash &*= 0x100000001b3
        }
        return hash
    }
}

private struct SeededGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 0x9e3779b97f4a7c15 : seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9e3779b97f4a7c15
        var z = state
        z = (z ^ (z >> 30)) &* 0xbf58476d1ce4e5b9
        z = (z ^ (z >> 27)) &* 0x94d049bb133111eb
        return z ^ (z >> 31)
    }
}
