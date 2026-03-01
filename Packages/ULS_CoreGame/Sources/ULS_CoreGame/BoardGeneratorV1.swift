import Foundation

public protocol BoardGenerationStrategyV1 {
    func generate(
        rng: inout DeterministicRNG,
        topology: BoardGraphV1,
        rules: BoardRulesV1
    ) -> BoardSetupV1
}

public struct RandomBoardStrategyV1: BoardGenerationStrategyV1 {
    public init() {}

    public func generate(
        rng: inout DeterministicRNG,
        topology: BoardGraphV1,
        rules _: BoardRulesV1
    ) -> BoardSetupV1 {
        precondition(topology.tiles.count == 19, "Standard board generator expects 19 tiles.")
        precondition(topology.ports.count == 9, "Standard board generator expects 9 ports.")

        let resources = shuffledResources(rng: &rng)
        let numbers = shuffledNumberTokens(rng: &rng)
        let ports = shuffledPorts(rng: &rng)
        return makeBoardSetup(
            resourcesByTile: resources,
            numberTokens: numbers,
            portsByIndex: ports,
            generator: .randomV1
        )
    }
}

public struct NoRedAdjacentStrategyV1: BoardGenerationStrategyV1 {
    private let maxNumberShuffleAttempts: Int

    public init(maxNumberShuffleAttempts: Int = 256) {
        self.maxNumberShuffleAttempts = maxNumberShuffleAttempts
    }

    public func generate(
        rng: inout DeterministicRNG,
        topology: BoardGraphV1,
        rules _: BoardRulesV1
    ) -> BoardSetupV1 {
        precondition(topology.tiles.count == 19, "Standard board generator expects 19 tiles.")
        precondition(topology.ports.count == 9, "Standard board generator expects 9 ports.")

        let resources = shuffledResources(rng: &rng)
        let ports = shuffledPorts(rng: &rng)
        let adjacentTilePairs = tileAdjacencyPairs(for: topology)

        var chosenNumbers = numberTokens
        var attemptsRemaining = max(maxNumberShuffleAttempts, 1)
        while attemptsRemaining > 0 {
            attemptsRemaining -= 1
            let candidate = shuffledNumberTokens(rng: &rng)
            chosenNumbers = candidate

            let candidateNumbersByTile = assignNumbers(
                for: resources,
                numberTokens: candidate
            )

            if !hasAdjacentRedNumbers(
                numbersByTile: candidateNumbersByTile,
                adjacentPairs: adjacentTilePairs
            ) {
                break
            }
        }

        return makeBoardSetup(
            resourcesByTile: resources,
            numberTokens: chosenNumbers,
            portsByIndex: ports,
            generator: .noRedAdjacentV1
        )
    }
}

public enum StandardBoardGeneratorV1 {
    public static func generate(
        boardSeed: UInt64,
        rules: BoardRulesV1,
        topology: BoardGraphV1 = StandardBoardTopologyV1.standard()
    ) -> BoardSetupV1 {
        var rng = DeterministicRNG(seed: boardSeed)

        let strategy: BoardGenerationStrategyV1
        switch rules.strategy {
        case .randomV1:
            strategy = RandomBoardStrategyV1()
        case .noRedAdjacentV1:
            strategy = NoRedAdjacentStrategyV1()
        }

        return strategy.generate(rng: &rng, topology: topology, rules: rules)
    }
}

private let resourceTiles: [ResourceV1] = [
    .wood, .wood, .wood, .wood,
    .sheep, .sheep, .sheep, .sheep,
    .wheat, .wheat, .wheat, .wheat,
    .brick, .brick, .brick,
    .ore, .ore, .ore,
    .desert,
]

private let numberTokens: [Int] = [
    2, 3, 3, 4, 4, 5, 5, 6, 6,
    8, 8, 9, 9, 10, 10, 11, 11, 12,
]

private let portKinds: [PortKindV1] = [
    .threeToOne, .threeToOne, .threeToOne, .threeToOne,
    .twoToOne(.wood), .twoToOne(.brick), .twoToOne(.sheep), .twoToOne(.wheat), .twoToOne(.ore),
]

private func shuffledResources(rng: inout DeterministicRNG) -> [ResourceV1] {
    var resources = resourceTiles
    fisherYatesShuffle(&resources, rng: &rng)
    return resources
}

private func shuffledNumberTokens(rng: inout DeterministicRNG) -> [Int] {
    var tokens = numberTokens
    fisherYatesShuffle(&tokens, rng: &rng)
    return tokens
}

private func shuffledPorts(rng: inout DeterministicRNG) -> [PortKindV1] {
    var ports = portKinds
    fisherYatesShuffle(&ports, rng: &rng)
    return ports
}

private func makeBoardSetup(
    resourcesByTile: [ResourceV1],
    numberTokens: [Int],
    portsByIndex: [PortKindV1],
    generator: BoardGenStrategyV1
) -> BoardSetupV1 {
    precondition(resourcesByTile.count == 19, "resourcesByTile must have 19 entries.")
    precondition(numberTokens.count == 18, "numberTokens must have 18 entries.")
    precondition(portsByIndex.count == 9, "portsByIndex must have 9 entries.")

    let numbersByTile = assignNumbers(for: resourcesByTile, numberTokens: numberTokens)
    guard let robberTile = resourcesByTile.firstIndex(of: .desert) else {
        preconditionFailure("resourcesByTile must include exactly one desert tile.")
    }

    return BoardSetupV1(
        resourcesByTile: resourcesByTile,
        numbersByTile: numbersByTile,
        portsByIndex: portsByIndex,
        robberTile: robberTile,
        generator: generator,
        boardHash: ""
    ).rehashed()
}

private func assignNumbers(for resourcesByTile: [ResourceV1], numberTokens: [Int]) -> [Int?] {
    var numbersByTile = Array<Int?>(repeating: nil, count: resourcesByTile.count)
    var tokenIndex = 0

    for tileIndex in resourcesByTile.indices {
        if resourcesByTile[tileIndex] == .desert { continue }
        numbersByTile[tileIndex] = numberTokens[tokenIndex]
        tokenIndex += 1
    }

    return numbersByTile
}

private func hasAdjacentRedNumbers(
    numbersByTile: [Int?],
    adjacentPairs: [(TileID, TileID)]
) -> Bool {
    for (a, b) in adjacentPairs {
        guard let left = numbersByTile[a], let right = numbersByTile[b] else { continue }
        if isRedNumber(left) && isRedNumber(right) {
            return true
        }
    }
    return false
}

private func isRedNumber(_ value: Int) -> Bool {
    value == 6 || value == 8
}

private func tileAdjacencyPairs(for topology: BoardGraphV1) -> [(TileID, TileID)] {
    var pairs = Set<TilePair>()
    for edgeID in topology.edges.indices {
        let adjacentTiles = topology.tiles(adjacentToEdge: edgeID)
        if adjacentTiles.count == 2 {
            pairs.insert(TilePair(adjacentTiles[0], adjacentTiles[1]))
        }
    }

    return pairs
        .map { ($0.a, $0.b) }
        .sorted { left, right in
            if left.0 != right.0 { return left.0 < right.0 }
            return left.1 < right.1
        }
}

private struct TilePair: Hashable {
    let a: TileID
    let b: TileID

    init(_ lhs: TileID, _ rhs: TileID) {
        if lhs <= rhs {
            a = lhs
            b = rhs
        } else {
            a = rhs
            b = lhs
        }
    }
}

private func fisherYatesShuffle<T>(_ values: inout [T], rng: inout DeterministicRNG) {
    guard values.count > 1 else { return }

    var index = values.count - 1
    while index > 0 {
        let swapIndex = Int(rng.nextUInt64() % UInt64(index + 1))
        if swapIndex != index {
            values.swapAt(index, swapIndex)
        }
        index -= 1
    }
}
