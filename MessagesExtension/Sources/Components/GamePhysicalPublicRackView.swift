import SwiftUI

struct GamePhysicalPublicRackView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
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
                                isFaded: false,
                                stackDepth: 2
                            )
                            .overlay(alignment: .bottom) {
                                if revealsBankCounts {
                                    supplyBar(remaining: chip.count)
                                        .padding(.bottom, 3)
                                }
                            }
                        }
                    }

                    if revealsBankCounts {
                        Text(dynamicTypeSize.isAccessibilitySize ? "Bank supply" : "Bank · Approx. cards left")
                            .font(.caption)
                            .foregroundStyle(GamePhysicalTurnPalette.primaryText)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: 210)
                    } else {
                        GameTabletopNameTileView(title: "Bank", width: 42, isSelected: false)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("uls.tabletop.bankRack")
            .gameTutorialTarget(.bankRack)
            .accessibilityLabel("Bank")
            .accessibilityValue(bankAccessibilityValue)
            .accessibilityHint(
                revealsBankCounts
                    ? "Approximate cards left: more filled segments means more cards; an empty bar means none. Tap to hide."
                    : "Shows approximate cards left. More filled segments means more cards; an empty bar means none."
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

    private func supplyBar(remaining: Int) -> some View {
        HStack(spacing: 2) {
            ForEach(0..<3) { segment in
                Rectangle()
                    .fill(segment < GamePublicPileLevel.resourceFilledSegments(remaining: remaining)
                        ? GamePhysicalTurnPalette.primaryText : Color.clear)
                    .frame(width: 6, height: 5)
            }
        }
        .padding(3)
        .background(GamePhysicalTurnPalette.cardCountInk, in: RoundedRectangle(cornerRadius: 3))
        .overlay {
            RoundedRectangle(cornerRadius: 3)
                .stroke(GamePhysicalTurnPalette.primaryText, lineWidth: 1)
        }
        .accessibilityHidden(true)
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
        guard revealsBankCounts else { return "Supply levels hidden" }
        return bank.chips
            .map {
                return "\($0.resource.shortLabel): \(GamePublicPileLevel.resourceSupplyDescription(remaining: $0.count))"
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
