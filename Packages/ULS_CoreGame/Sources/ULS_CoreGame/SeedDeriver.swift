import Foundation

public enum SeedDomain: String, Codable {
    case board
    case dice
    case devDeck
    case robber
}

public struct SeedDeriver {
    public let masterSeed: UInt64

    public init(masterSeed: UInt64) {
        self.masterSeed = masterSeed
    }

    public func seed(for domain: SeedDomain) -> UInt64 {
        let input = masterSeed ^ Self.salt(for: domain)
        var rng = DeterministicRNG(seed: input)
        return rng.nextUInt64()
    }

    private static func salt(for domain: SeedDomain) -> UInt64 {
        switch domain {
        case .board:
            return 0x424F4152445F5631
        case .dice:
            return 0x444943455F56315F
        case .devDeck:
            return 0x4445434B5F56315F
        case .robber:
            return 0x524F42425F56315F
        }
    }
}
