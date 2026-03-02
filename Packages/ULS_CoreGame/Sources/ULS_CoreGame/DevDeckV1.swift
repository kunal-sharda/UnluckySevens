import Foundation

public enum DevCardV1: String, Codable, Equatable {
    case knight
    case monopoly
    case yearOfPlenty
    case roadBuilding
    case victoryPoint
}

public func makeDeterministicDevDeck(masterSeed: UInt64) -> [DevCardV1] {
    let seed = SeedDeriver(masterSeed: masterSeed).seed(for: .devDeck)
    return shuffledDevDeck(seed: seed)
}

internal func drawTopDevCard(from deck: [DevCardV1]) -> (card: DevCardV1, remaining: [DevCardV1])? {
    guard let top = deck.first else {
        return nil
    }
    return (card: top, remaining: Array(deck.dropFirst()))
}

internal func shuffledDevDeck(seed: UInt64) -> [DevCardV1] {
    var deck: [DevCardV1] = []
    deck.append(contentsOf: Array(repeating: .knight, count: 14))
    deck.append(contentsOf: Array(repeating: .monopoly, count: 2))
    deck.append(contentsOf: Array(repeating: .yearOfPlenty, count: 2))
    deck.append(contentsOf: Array(repeating: .roadBuilding, count: 2))
    deck.append(contentsOf: Array(repeating: .victoryPoint, count: 5))

    var rng = DeterministicRNG(seed: seed)
    if deck.count > 1 {
        for i in stride(from: deck.count - 1, through: 1, by: -1) {
            let j = Int(rng.nextUInt64() % UInt64(i + 1))
            if i != j {
                deck.swapAt(i, j)
            }
        }
    }
    return deck
}
