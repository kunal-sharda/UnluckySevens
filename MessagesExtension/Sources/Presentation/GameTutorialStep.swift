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
        case victoryAwards
    }

    let id: ID
    let title: String
    let guidance: String
    let previewAccessibilityLabel: String
    let callouts: [GameTutorialCallout]

    static let all: [GameTutorialStep] = [
        .init(
            id: .setupSettlement,
            title: "Place a Settlement",
            guidance: "Everyone places twice. The order reverses for round two, so choose one of the marked legal intersections when your name is current.",
            previewAccessibilityLabel: "The real setup board with legal settlement intersections and the setup order visible.",
            callouts: [
                .init(number: 1, target: .setupOrder, placement: .below, text: "Round two reverses the order"),
                .init(number: 2, target: .board, targetPoint: UnitPoint(x: 0.28, y: 0.47), placement: .trailing, text: "Tap a marked legal intersection"),
            ]
        ),
        .init(
            id: .setupRoad,
            title: "Connect the Road",
            guidance: "Place one road on a marked edge touching the settlement. After your second settlement, each adjacent producing tile adds its resource to your hand.",
            previewAccessibilityLabel: "The real setup board after a settlement, with connected legal road edges highlighted.",
            callouts: [
                .init(number: 1, target: .board, targetPoint: UnitPoint(x: 0.31, y: 0.43), placement: .trailing, text: "Choose a connected marked edge"),
                .init(number: 2, target: .setupRoadPiece, placement: .above, text: "Settlement, then road"),
            ]
        ),
        .init(
            id: .rollDice,
            title: "Roll the Dice",
            guidance: "Every normal turn starts with a roll. Development cards that are eligible before rolling remain available beside it.",
            previewAccessibilityLabel: "The real start-of-turn surface with the Roll control visible.",
            callouts: [
                .init(number: 1, target: .rollButton, placement: .below, text: "Roll first to produce resources"),
            ]
        ),
        .init(
            id: .readProduction,
            title: "Read Production",
            guidance: "When the dice total matches a tile, each adjacent settlement gains one matching resource and each city gains two. The robber stops its tile from producing.",
            previewAccessibilityLabel: "The real post-roll board, numbered terrain, bank, structures, and robber.",
            callouts: [
                .init(number: 1, target: .board, targetPoint: UnitPoint(x: 0.42, y: 0.35), placement: .leading, text: "The rolled number pays adjacent buildings"),
                .init(number: 2, target: .board, targetPoint: UnitPoint(x: 0.25, y: 0.66), placement: .trailing, text: "The robber stops this tile"),
            ]
        ),
        .init(
            id: .useHand,
            title: "Use Your Hand",
            guidance: "Your hand shows every resource you can spend and separates owned development cards.",
            previewAccessibilityLabel: "The real resource hand and owned development-card stack.",
            callouts: [
                .init(number: 1, target: .handSpread, placement: .above, text: "These are your spendable cards"),
            ]
        ),
        .init(
            id: .buildCosts,
            title: "Choose What to Build",
            guidance: "Roads, settlements, and cities print their resource cost below the piece. A city replaces one of your settlements.",
            previewAccessibilityLabel: "The real build spread showing roads, settlements, cities, and their printed costs.",
            callouts: [
                .init(number: 1, target: .buildSettlement, placement: .above, text: "Compare costs; cities replace settlements"),
            ]
        ),
        .init(
            id: .legalPlacement,
            title: "Place on a Highlight",
            guidance: "After choosing a piece, only legal board targets highlight. Cities replace one of your settlements.",
            previewAccessibilityLabel: "The real board in settlement-placement mode with legal intersections highlighted.",
            callouts: [
                .init(number: 1, target: .board, targetPoint: UnitPoint(x: 0.28, y: 0.39), placement: .trailing, text: "Only highlighted targets are legal"),
            ]
        ),
        .init(
            id: .playerTrade,
            title: "Offer a Player Trade",
            guidance: "Choose the cards you will give, then the cards you want back. You will select who receives the offer next.",
            previewAccessibilityLabel: "The real player-trade composer with give, want, and recipient sections.",
            callouts: []
        ),
        .init(
            id: .tradeRecipients,
            title: "Choose Trade Partners",
            guidance: "Send the offer to one or more players. Their accept, decline, or counter response returns through Messages.",
            previewAccessibilityLabel: "The real player-trade composer scrolled to its recipient choices.",
            callouts: []
        ),
        .init(
            id: .bankTrade,
            title: "Use the Bank or a Port",
            guidance: "The legal trade list automatically uses the best ratio from the bank and any ports you control.",
            previewAccessibilityLabel: "The real maritime and bank trade list showing legal ratios.",
            callouts: []
        ),
        .init(
            id: .discard,
            title: "Discard After a Seven",
            guidance: "If you hold more than seven cards when a seven rolls, choose half your hand, rounded down, before the robber moves.",
            previewAccessibilityLabel: "The real forced-discard composer showing the required count and selectable hand.",
            callouts: [
                .init(number: 1, target: .discardSurface, placement: .above, text: "Choose exactly half your hand"),
            ]
        ),
        .init(
            id: .moveRobber,
            title: "Move the Robber",
            guidance: "Move the robber to another highlighted terrain tile. That tile stops producing while the robber remains there.",
            previewAccessibilityLabel: "The real board in robber-movement mode with legal destination tiles highlighted.",
            callouts: [
                .init(number: 1, target: .board, targetPoint: UnitPoint(x: 0.50, y: 0.50), placement: .trailing, text: "Move it to a highlighted tile"),
            ]
        ),
        .init(
            id: .chooseVictim,
            title: "Choose a Victim",
            guidance: "Maya and Theo both touch the robber tile. Choose one marked opponent to steal one random resource card from.",
            previewAccessibilityLabel: "The real board in robber-victim mode with eligible opposing structures highlighted.",
            callouts: [
                .init(number: 1, target: .board, targetPoint: UnitPoint(x: 0.68, y: 0.41), placement: .leading, text: "Tap Maya’s marked building"),
            ]
        ),
        .init(
            id: .developmentCards,
            title: "Play a Development Card",
            guidance: "You may play one non-VP development card per turn. A card bought during this turn becomes playable on a later turn.",
            previewAccessibilityLabel: "The real development-card chooser showing playable and unavailable cards.",
            callouts: [
                .init(number: 1, target: .devChooser, placement: .above, text: "Bright cards are playable now"),
            ]
        ),
        .init(
            id: .endTurn,
            title: "End and Send the Turn",
            guidance: "End Turn confirms your actions and sends the updated game to the next player in Messages.",
            previewAccessibilityLabel: "The real End Turn confirmation controls.",
            callouts: [
                .init(number: 1, target: .endTurnConfirmation, targetPoint: UnitPoint(x: 0.78, y: 0.72), placement: .above, text: "Confirm to send the updated game"),
            ]
        ),
        .init(
            id: .strategy,
            title: "Build a Strong Position",
            guidance: "Spread across useful numbers and resource types. Turn surpluses into what you need through trades and ports, and watch opponents nearing either award.",
            previewAccessibilityLabel: "The real public board showing varied numbers, resources, ports, roads, and opposing positions.",
            callouts: [
                .init(number: 1, target: .handSpread, placement: .above, text: "Trade surpluses; watch both awards"),
            ]
        ),
        .init(
            id: .victoryAwards,
            title: "Win at Ten Points",
            guidance: "Settlements score 1 VP, cities score 2, and VP cards score 1. Longest Road and Largest Army add 2 VP each. Be the first player to reach 10 points on your turn.",
            previewAccessibilityLabel: "The real game information panel showing victory points and both two-point awards over the public board.",
            callouts: [
                .init(number: 1, target: .gameInfo, placement: .above, text: "First to 10 · Settlement/VP card 1 · City/award 2"),
            ]
        ),
    ]
}
