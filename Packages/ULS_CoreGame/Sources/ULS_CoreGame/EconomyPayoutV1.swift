import Foundation

private let economyTopology = StandardBoardTopologyV1.standard()

internal struct EconomyUpdateV1 {
    let resourcesByPlayer: [String: ResourceHandV1]
    let bankResources: ResourceHandV1
}

internal func applyStartingSettlementPayout(
    player: String,
    settlementNode: NodeID?,
    board: BoardSetupV1?,
    resourcesByPlayer: [String: ResourceHandV1],
    bankResources: ResourceHandV1
) -> EconomyUpdateV1 {
    guard let settlementNode, let board else {
        return EconomyUpdateV1(resourcesByPlayer: resourcesByPlayer, bankResources: bankResources)
    }

    var updatedResources = resourcesByPlayer
    var bank = bankResources
    var hand = updatedResources[player] ?? .zero

    for tileID in economyTopology.tiles(adjacentToNode: settlementNode) {
        guard tileID >= 0, tileID < board.resourcesByTile.count else {
            continue
        }

        if tileID == board.robberTile {
            continue
        }

        let resource = board.resourcesByTile[tileID]
        if resource == .desert {
            continue
        }

        if bank.count(for: resource) <= 0 {
            continue
        }

        hand = hand.addingOne(for: resource)
        bank = bank.subtracting(1, for: resource)
    }

    updatedResources[player] = hand
    return EconomyUpdateV1(resourcesByPlayer: updatedResources, bankResources: bank)
}

internal func applyProductionPayout(
    rollTotal: Int,
    board: BoardSetupV1?,
    settlementsByNode: [NodeID: String],
    citiesByNode: [NodeID: String],
    resourcesByPlayer: [String: ResourceHandV1],
    bankResources: ResourceHandV1
) -> EconomyUpdateV1 {
    guard rollTotal != 7, let board else {
        return EconomyUpdateV1(resourcesByPlayer: resourcesByPlayer, bankResources: bankResources)
    }

    var owedByPlayer: [String: ResourceHandV1] = [:]

    for tileID in board.numbersByTile.indices {
        guard board.numbersByTile[tileID] == rollTotal else {
            continue
        }

        if tileID == board.robberTile {
            continue
        }

        let resource = board.resourcesByTile[tileID]
        if resource == .desert {
            continue
        }

        for node in economyTopology.tiles[tileID].nodes {
            if let owner = citiesByNode[node], resourcesByPlayer[owner] != nil {
                let current = owedByPlayer[owner] ?? .zero
                owedByPlayer[owner] = current.adding(2, for: resource)
                continue
            }

            if let owner = settlementsByNode[node], resourcesByPlayer[owner] != nil {
                let current = owedByPlayer[owner] ?? .zero
                owedByPlayer[owner] = current.addingOne(for: resource)
            }
        }
    }

    var updatedResources = resourcesByPlayer
    var bank = bankResources

    for resource in [ResourceV1.wood, .brick, .sheep, .wheat, .ore] {
        let totalOwed = owedByPlayer.values.reduce(0) { partial, hand in
            partial + hand.count(for: resource)
        }

        if totalOwed == 0 {
            continue
        }

        if bank.count(for: resource) < totalOwed {
            continue
        }

        for (player, owed) in owedByPlayer {
            let amount = owed.count(for: resource)
            if amount == 0 {
                continue
            }

            let current = updatedResources[player] ?? .zero
            updatedResources[player] = current.adding(amount, for: resource)
        }

        bank = bank.subtracting(totalOwed, for: resource)
    }

    return EconomyUpdateV1(resourcesByPlayer: updatedResources, bankResources: bank)
}
