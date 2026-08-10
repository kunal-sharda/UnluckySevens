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
      guidance:
        "Each player places one settlement with a connected road. After everyone places once, the order reverses for the second settlement and road.",
      previewAccessibilityLabel:
        "Setup board showing the placement order and glowing settlement locations.",
      callouts: [
        .init(
          number: 1, target: .setupOrder, placement: .below,
          text: "Everyone places a settlement and road twice. Round two goes in reverse order."
        ),
        .init(
          number: 2, target: .board, targetPoint: UnitPoint(x: 0.28, y: 0.47), placement: .trailing,
          text: "First, place a settlement on a glowing corner."),
      ]
    ),
    .init(
      id: .setupRoad,
      title: "Add a Road",
      guidance:
        "Place a road on a glowing edge connected to your settlement. After your second settlement, collect one resource from every neighboring producing tile.",
      previewAccessibilityLabel:
        "Setup board showing glowing road locations beside the new settlement.",
      callouts: [
        .init(
          number: 1, target: .board, targetPoint: UnitPoint(x: 0.31, y: 0.43), placement: .trailing,
          text: "Next, place a road connected to your settlement."),
        .init(
          number: 2, target: .setupRoadPiece, placement: .above,
          text: "Your second settlement gives you starting resources from the tiles it touches."
        ),
      ]
    ),
    .init(
      id: .rollDice,
      title: "Roll to Begin",
      guidance:
        "Every normal turn begins with a roll. If you have a playable Dev Card, you may play it before rolling.",
      previewAccessibilityLabel: "Start-of-turn table with Roll and a playable Dev Card available.",
      callouts: [
        .init(
          number: 1, target: .rollButton, placement: .below,
          text: "Roll to see which numbered tiles produce. You may play a Dev Card first."
        )
      ]
    ),
    .init(
      id: .readProduction,
      title: "Follow the Roll",
      guidance:
        "When the rolled number matches a tile, each neighboring settlement collects one matching resource and each neighboring city collects two. The robber prevents its tile from producing.",
      previewAccessibilityLabel:
        "Post-roll board showing a matching numbered tile, neighboring buildings, and a robber blocking another tile.",
      callouts: [
        .init(
          number: 1, target: .board, targetPoint: UnitPoint(x: 0.42, y: 0.35), placement: .leading,
          text: "Matching tiles give one resource per settlement and two per city."
        ),
        .init(
          number: 2, target: .board, targetPoint: UnitPoint(x: 0.25, y: 0.66), placement: .trailing,
          text: "The robber stops its tile from producing resources."),
      ]
    ),
    .init(
      id: .useHand,
      title: "Check Your Hand",
      guidance: "Open your Hand to see the resource cards you can spend and the Dev Cards you own.",
      previewAccessibilityLabel: "Open Hand showing owned resource cards and Dev Cards.",
      callouts: [
        .init(
          number: 1, target: .handSpread, placement: .above,
          text: "Open your Hand to see your resources and Dev Cards.")
      ]
    ),
    .init(
      id: .buildCosts,
      title: "Choose What to Build",
      guidance:
        "Each road, settlement, and city shows its resource cost. Building a city upgrades one of your settlements.",
      previewAccessibilityLabel:
        "Build choices showing roads, settlements, cities, and their resource costs.",
      callouts: [
        .init(
          number: 1, target: .buildSettlement, placement: .above,
          text: "Each piece shows its cost. A city upgrades one of your settlements.")
      ]
    ),
    .init(
      id: .legalPlacement,
      title: "Choose a Glowing Corner",
      guidance:
        "Available settlement locations glow. Tap one twice to confirm the build. Settlements must be at least two road lengths apart.",
      previewAccessibilityLabel:
        "Board showing the glowing corners where a settlement can be built.",
      callouts: [
        .init(
          number: 1, target: .board, targetPoint: UnitPoint(x: 0.28, y: 0.39), placement: .trailing,
          text: "Tap a glowing corner twice. Settlements must be two road lengths apart."
        )
      ]
    ),
    .init(
      id: .playerTrade,
      title: "Make an Offer",
      guidance: "Choose the cards you will offer, then choose the cards you want in return.",
      previewAccessibilityLabel: "Player-trade offer showing Give and Get card selections.",
      callouts: [
        .init(
          number: 1,
          target: .tradeGive,
          placement: .above,
          text: "Choose what you’ll offer and what you want back."
        )
      ]
    ),
    .init(
      id: .tradeRecipients,
      title: "Choose Who Gets It",
      guidance:
        "Choose one or more players and send the offer. Their accept, decline, or counter response returns through Messages.",
      previewAccessibilityLabel:
        "Player-trade offer showing the players available to receive it.",
      callouts: [
        .init(
          number: 1,
          target: .tradeRecipients,
          placement: .below,
          text: "Choose the players, then send your offer."
        )
      ]
    ),
    .init(
      id: .bankTrade,
      title: "Trade with Bank or Port",
      guidance: "Choose a Bank or Port trade. The list automatically shows the best rate you can use.",
      previewAccessibilityLabel: "Bank or Port trade list showing the best available exchange rate.",
      callouts: [
        .init(
          number: 1,
          target: .maritimeOptions,
          placement: .above,
          text: "Your best Bank or Port rate is already shown."
        )
      ]
    ),
    .init(
      id: .discard,
      title: "Discard on Seven",
      guidance:
        "When a seven is rolled, players holding more than seven cards discard half their hand, rounded down, before the robber moves.",
      previewAccessibilityLabel:
        "Discard screen showing the required number and the resource cards available to discard.",
      callouts: [
        .init(
          number: 1, target: .discardSurface, placement: .above,
          text: "Holding 8+ cards when a seven rolls? Discard half, rounded down.")
      ]
    ),
    .init(
      id: .moveRobber,
      title: "Move the Robber",
      guidance:
        "After a seven or Knight, move the robber to a different glowing terrain tile. That tile cannot produce while the robber remains there.",
      previewAccessibilityLabel: "Board showing the glowing tiles where the robber can move.",
      callouts: [
        .init(
          number: 1, target: .board, targetPoint: UnitPoint(x: 0.50, y: 0.50), placement: .trailing,
          text: "Move the robber to a different glowing tile. That tile stops producing.")
      ]
    ),
    .init(
      id: .chooseVictim,
      title: "Choose a Victim",
      guidance:
        "Select a glowing settlement beside the robber to choose that player. You steal one random resource card from them.",
      previewAccessibilityLabel: "Board showing the neighboring players available for the robber steal.",
      callouts: [
        .init(
          number: 1, target: .board, targetPoint: UnitPoint(x: 0.68, y: 0.41), placement: .leading,
          text: "Choose a neighboring player to steal one random resource from.")
      ]
    ),
    .init(
      id: .developmentCards,
      title: "Play a Dev Card",
      guidance:
        "You may play one non-Victory Point Dev Card per turn. A card bought this turn cannot be played until your next turn.",
      previewAccessibilityLabel: "Dev Card chooser showing which owned cards can be played now.",
      callouts: [
        .init(
          number: 1, target: .devChooser, placement: .above,
          text: "Playable cards glow. Play one per turn. Bought cards wait until next turn."
        )
      ]
    ),
    .init(
      id: .endTurn,
      title: "Send the Turn",
      guidance:
        "End Turn confirms your actions and sends the updated game to the next player through Messages.",
      previewAccessibilityLabel: "End Turn confirmation ready to send the updated game.",
      callouts: [
        .init(
          number: 1, target: .endTurnConfirmation, targetPoint: UnitPoint(x: 0.78, y: 0.72),
          placement: .above,
          text: "End Turn sends the updated game to the next player in Messages.")
      ]
    ),
    .init(
      id: .strategy,
      title: "Strategy",
      guidance:
        "Numbers with more dots roll more often. Five connected roads can earn Longest Road, and three played Knights can earn Largest Army. Each award is worth 2 points. Settlements are worth 1 point, and cities are worth 2. The first player to 10 points wins.",
      previewAccessibilityLabel:
        "Board dimmed behind a Strategy card with production, building, and scoring tips.",
      callouts: []
    ),
  ]
}
