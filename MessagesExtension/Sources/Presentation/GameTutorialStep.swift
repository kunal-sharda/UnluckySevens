import SwiftUI

struct GameTutorialCallout: Identifiable, Equatable {
    enum Placement: Hashable {
        case above
        case below
        case leading
        case trailing
    }

    let number: Int
    let target: GameTutorialTarget
    let targetPoint: UnitPoint
    let placement: Placement
    let text: String

    var id: Int { number }

    init(
        number: Int,
        target: GameTutorialTarget,
        targetPoint: UnitPoint = .center,
        placement: Placement,
        text: String
    ) {
        self.number = number
        self.target = target
        self.targetPoint = targetPoint
        self.placement = placement
        self.text = text
    }
}

struct GameTutorialStep: Identifiable, Equatable {
    enum ID: Int, CaseIterable {
        case setupSettlement = 1
        case setupRoad
        case rollDice
        case readProduction
        case useHand
        case buildCosts
        case legalPlacement
        case playerTrade
        case tradeRecipients
        case bankTrade
        case discard
        case moveRobber
        case chooseVictim
        case developmentCards
        case endTurn
        case strategy
    }

    let id: ID
    let title: String
    let guidance: String
    let previewAccessibilityLabel: String
    let callouts: [GameTutorialCallout]

    static let all: [GameTutorialStep] = [
        .init(
            id: .setupSettlement,
            title: "Place Your First Settlement",
            guidance: "Everyone places twice. Round two reverses the order. Choose a glowing corner when your name is current.",
            previewAccessibilityLabel: "Setup board with the placement order and available settlement corners glowing.",
            callouts: [
                .init(number: 1, target: .setupOrder, placement: .below, text: "You place twice. Round two goes in reverse."),
                .init(number: 2, target: .board, targetPoint: UnitPoint(x: 0.28, y: 0.47), placement: .trailing, text: "Start on a glowing corner."),
            ]
        ),
        .init(
            id: .setupRoad,
            title: "Add a Road",
            guidance: "Add one road beside your settlement. After your second settlement, each neighboring producing tile adds its resource to your hand.",
            previewAccessibilityLabel: "Setup board after a settlement, with connected road edges glowing.",
            callouts: [
                .init(number: 1, target: .board, targetPoint: UnitPoint(x: 0.31, y: 0.43), placement: .trailing, text: "Add a road beside your settlement."),
                .init(number: 2, target: .setupRoadPiece, placement: .above, text: "Your second spot deals starting cards."),
            ]
        ),
        .init(
            id: .rollDice,
            title: "Roll to Begin",
            guidance: "Every normal turn starts with a roll. Development cards available before rolling appear beside the dice.",
            previewAccessibilityLabel: "Start-of-turn surface with the Roll control available.",
            callouts: [
                .init(number: 1, target: .rollButton, placement: .below, text: "Roll to see which tiles produce."),
            ]
        ),
        .init(
            id: .readProduction,
            title: "Follow the Roll",
            guidance: "When the dice total matches a tile, each adjacent settlement gains one matching resource and each city gains two. The robber stops its tile from producing.",
            previewAccessibilityLabel: "Post-roll board with numbered terrain, nearby buildings, and a robber blocking one tile.",
            callouts: [
                .init(number: 1, target: .board, targetPoint: UnitPoint(x: 0.42, y: 0.35), placement: .leading, text: "Matching numbers pay nearby buildings."),
                .init(number: 2, target: .board, targetPoint: UnitPoint(x: 0.25, y: 0.66), placement: .trailing, text: "The robber blocks this tile."),
            ]
        ),
        .init(
            id: .useHand,
            title: "Check Your Hand",
            guidance: "Your hand shows every resource you can spend and separates owned development cards.",
            previewAccessibilityLabel: "Your resource hand and owned development-card stack.",
            callouts: [
                .init(number: 1, target: .handSpread, placement: .above, text: "These are the cards you can spend."),
            ]
        ),
        .init(
            id: .buildCosts,
            title: "Pick a Build",
            guidance: "Roads, settlements, and cities print their resource cost below the piece. A city replaces one of your settlements.",
            previewAccessibilityLabel: "Build choices showing Roads, settlements, cities, and their costs.",
            callouts: [
                .init(number: 1, target: .buildSettlement, placement: .above, text: "Each piece shows its cost. Cities replace settlements."),
            ]
        ),
        .init(
            id: .legalPlacement,
            title: "Choose a Glowing Spot",
            guidance: "After choosing a piece, available board targets glow. Tap a spot again to confirm the build.",
            previewAccessibilityLabel: "Board in settlement-placement mode with available intersections glowing.",
            callouts: [
                .init(number: 1, target: .board, targetPoint: UnitPoint(x: 0.28, y: 0.39), placement: .trailing, text: "Tap a glowing spot twice to build."),
            ]
        ),
        .init(
            id: .playerTrade,
            title: "Make an Offer",
            guidance: "Choose the cards you will give, then the cards you want back. You will select who receives the offer next.",
            previewAccessibilityLabel: "Player-trade composer with Give and Get selections.",
            callouts: [
                .init(
                    number: 1,
                    target: .tradeGive,
                    placement: .above,
                    text: "Pick what you’ll give and what you want."
                ),
            ]
        ),
        .init(
            id: .tradeRecipients,
            title: "Choose Who Gets It",
            guidance: "Send the offer to one or more players. Their accept, decline, or counter response returns through Messages.",
            previewAccessibilityLabel: "Player-trade composer showing the players who can receive the offer.",
            callouts: [
                .init(
                    number: 1,
                    target: .tradeRecipients,
                    placement: .below,
                    text: "Choose the players, then send the offer."
                ),
            ]
        ),
        .init(
            id: .bankTrade,
            title: "Use Your Best Rate",
            guidance: "The trade list automatically uses your best Bank or Port rate.",
            previewAccessibilityLabel: "Bank or Port trade list showing the best available rate.",
            callouts: [
                .init(
                    number: 1,
                    target: .maritimeOptions,
                    placement: .above,
                    text: "Your best Bank or Port rate is shown."
                ),
            ]
        ),
        .init(
            id: .discard,
            title: "Discard on Seven",
            guidance: "If you hold more than seven cards when a seven rolls, choose half your hand, rounded down, before the robber moves.",
            previewAccessibilityLabel: "Forced-discard composer showing the exact required count and your selectable hand.",
            callouts: [
                .init(number: 1, target: .discardSurface, placement: .above, text: "Choose half your hand, then confirm."),
            ]
        ),
        .init(
            id: .moveRobber,
            title: "Move the Robber",
            guidance: "Move the robber to another highlighted terrain tile. That tile stops producing while the robber remains there.",
            previewAccessibilityLabel: "Board with available robber destinations glowing.",
            callouts: [
                .init(number: 1, target: .board, targetPoint: UnitPoint(x: 0.50, y: 0.50), placement: .trailing, text: "Move the robber to a glowing tile."),
            ]
        ),
        .init(
            id: .chooseVictim,
            title: "Choose a Victim",
            guidance: "Maya and Theo both touch the robber tile. Choose one marked opponent to steal one random resource card from.",
            previewAccessibilityLabel: "Board with neighboring players available for a robber steal.",
            callouts: [
                .init(number: 1, target: .board, targetPoint: UnitPoint(x: 0.68, y: 0.41), placement: .leading, text: "Choose a neighboring player."),
            ]
        ),
        .init(
            id: .developmentCards,
            title: "Play a Dev Card",
            guidance: "You may play one non-Victory Point development card per turn. Cards bought this turn wait until your next turn.",
            previewAccessibilityLabel: "Development-card chooser showing which cards are available now.",
            callouts: [
                .init(number: 1, target: .devChooser, placement: .above, text: "Bright cards can be played now."),
            ]
        ),
        .init(
            id: .endTurn,
            title: "Send the Turn",
            guidance: "End Turn confirms your actions and sends the updated game to the next player in Messages.",
            previewAccessibilityLabel: "End Turn confirmation that sends the updated board to the chat.",
            callouts: [
                .init(number: 1, target: .endTurnConfirmation, targetPoint: UnitPoint(x: 0.78, y: 0.72), placement: .above, text: "End Turn sends the new board to the chat."),
            ]
        ),
        .init(
            id: .strategy,
            title: "Strategy",
            guidance: "More dots mean stronger production. Roads and development cards can help earn points. Settlements score 1 point, while cities and awards score 2.",
            previewAccessibilityLabel: "Board dimmed behind a Strategy card with production, investment, and scoring tips.",
            callouts: []
        ),
    ]
}
