import SwiftUI

struct GamePhysicalPublicRackView: View {
    let bank: GameBankTrayModel
    let revealsBankCounts: Bool
    let developmentDeckCount: Int
    let canBuyDevelopmentCard: Bool
    let onToggleBankCounts: () -> Void
    let onBuyDevelopmentCard: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: GamePhysicalTurnLayout.publicObjectGap) {
            Button(action: onToggleBankCounts) {
                VStack(spacing: GamePhysicalTurnLayout.publicLabelGap) {
                    HStack(spacing: GamePhysicalTurnLayout.publicBankCardGap) {
                        ForEach(bank.chips) { chip in
                            GameTabletopPortraitCardView(
                                face: .resource(chip.resource),
                                size: GamePhysicalTurnLayout.portraitCardSize,
                                overlayText: revealsBankCounts
                                    ? GamePublicPileLevel.resource(remaining: chip.count).symbol
                                    : nil,
                                isFaded: revealsBankCounts,
                                stackDepth: 2
                            )
                        }
                    }

                    GameTabletopNameTileView(
                        title: "Bank",
                        width: 42,
                        isSelected: revealsBankCounts
                    )
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("uls.tabletop.bankRack")
            .accessibilityLabel("Bank")
            .accessibilityValue(bankAccessibilityValue)
            .accessibilityHint(
                revealsBankCounts
                    ? "Hides remaining resource cards"
                    : "Shows remaining resource cards"
            )
            .accessibilityAddTraits(revealsBankCounts ? .isSelected : [])

            Group {
                if canBuyDevelopmentCard {
                    Button(action: onBuyDevelopmentCard) {
                        developmentDeck
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("Buys one card for one sheep, one wheat, and one ore")
                } else {
                    developmentDeck
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityIdentifier("uls.tabletop.devDeck")
            .accessibilityLabel("Dev Cards")
            .accessibilityValue(devCardsAccessibilityValue)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("uls.turn.publicRail")
    }

    private var developmentDeck: some View {
        VStack(spacing: GamePhysicalTurnLayout.publicLabelGap) {
            GameTabletopPortraitCardView(
                face: .developmentBack,
                size: GamePhysicalTurnLayout.portraitCardSize,
                overlayText: revealsBankCounts
                    ? GamePublicPileLevel.devCards(remaining: developmentDeckCount).symbol
                    : nil,
                isFaded: revealsBankCounts,
                stackDepth: 3
            )

            GameTabletopNameTileView(
                title: "Dev Cards",
                width: 74,
                isSelected: false
            )
        }
        .frame(minWidth: 74, minHeight: 44)
        .contentShape(Rectangle())
    }

    private var bankAccessibilityValue: String {
        guard revealsBankCounts else { return "Counts hidden" }
        return bank.chips
            .map {
                let level = GamePublicPileLevel.resource(remaining: $0.count)
                return "\($0.resource.shortLabel) \(level.accessibilityLabel)"
            }
            .joined(separator: ", ")
    }

    private var devCardsAccessibilityValue: String {
        guard revealsBankCounts else { return "Count hidden" }
        return GamePublicPileLevel
            .devCards(remaining: developmentDeckCount)
            .accessibilityLabel
    }
}
