import SwiftUI

struct GamePhysicalPublicRackView: View {
    @ScaledMetric(relativeTo: .caption) private var bankLabelWidth: CGFloat = 42
    let bank: GameBankTrayModel
    let revealsBankCounts: Bool
    var isTradeShowingSupply = false
    var previewDiscoverability = true
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
                                    supplyBar(filledSegments: GamePublicPileLevel.resourceFilledSegments(remaining: chip.count))
                                        .padding(.bottom, 4)
                                }
                            }
                        }
                    }

                    HStack(spacing: 6) {
                        GameTabletopNameTileView(title: "Bank", width: bankLabelWidth, isSelected: false)
                        if revealsBankCounts {
                            Text("Approx. cards left")
                                .font(.caption2)
                                .foregroundStyle(GamePhysicalTurnPalette.primaryText)
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                        } else if previewDiscoverability {
                            Text("Tap for supply")
                                .font(.caption)
                                .foregroundStyle(GamePhysicalTurnPalette.primaryText)
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)
                                .accessibilityHidden(true)
                        }
                    }
                    .frame(maxWidth: 210)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("uls.tabletop.bankRack")
            .gameTutorialTarget(.bankRack)
            .accessibilityLabel("Bank")
            .accessibilityValue(bankAccessibilityValue)
            .accessibilityHint(
                isTradeShowingSupply
                    ? "Approximate cards left: more filled segments means more cards; an empty bar means none. Supply stays visible while Trade is open."
                    : revealsBankCounts
                        ? "Approximate cards left: more filled segments means more cards; an empty bar means none. Tap to hide."
                        : "Shows approximate cards left. More filled segments means more cards; an empty bar means none."
            )
            .accessibilityAddTraits(revealsBankCounts ? .isSelected : [])

            if previewDiscoverability {
                Button(action: onBuyDevelopmentCard) { developmentDeck }
                    .buttonStyle(.plain)
                    .accessibilityElement(children: .ignore)
                    .accessibilityIdentifier("uls.tabletop.devDeck")
                    .accessibilityLabel("Dev Cards")
                    .accessibilityValue(devCardsAccessibilityValue)
                    .accessibilityHint("Opens card information and purchase options. Opening does not buy a card.")
                    .accessibilityAddTraits(.isButton)
                    .accessibilityAction { onBuyDevelopmentCard() }
            } else {
                Group {
                    if canBuyDevelopmentCard {
                        Button(action: onBuyDevelopmentCard) { developmentDeck }
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
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("uls.turn.publicRail")
    }

    private func supplyBar(filledSegments: Int) -> some View {
        HStack(spacing: 1.5) {
            ForEach(0..<3) { segment in
                Rectangle()
                    .fill(segment < filledSegments
                        ? GamePhysicalTurnPalette.primaryText : Color.clear)
                    .frame(width: 5, height: 4)
            }
        }
        .padding(2)
        .background(GamePhysicalTurnPalette.cardCountInk, in: RoundedRectangle(cornerRadius: 3))
        .overlay {
            RoundedRectangle(cornerRadius: 3)
                .stroke(GamePhysicalTurnPalette.primaryText, lineWidth: 1)
        }
        .accessibilityHidden(true)
    }

    private var developmentDeck: some View {
        VStack(spacing: GamePhysicalTurnLayout.publicLabelGap) {
            if previewDiscoverability {
                HStack(spacing: 4) {
                    developmentCard
                    Text("Tap to buy")
                        .font(.caption)
                        .foregroundStyle(GamePhysicalTurnPalette.primaryText)
                        .lineLimit(3)
                        .minimumScaleFactor(0.65)
                        .frame(width: 44, height: GamePhysicalTurnLayout.portraitCardSize.height)
                        .accessibilityHidden(true)
                }
            } else {
                developmentCard
            }

            GameTabletopNameTileView(
                title: "Dev Cards",
                width: 74,
                isSelected: false
            )
        }
        .frame(minWidth: 74, minHeight: 44)
        .contentShape(Rectangle())
    }

    private var developmentCard: some View {
        GameTabletopPortraitCardView(
            face: .developmentBack,
            size: GamePhysicalTurnLayout.portraitCardSize,
            isFaded: false,
            stackDepth: 3
        )
        .overlay(alignment: .bottom) {
            if revealsBankCounts {
                supplyBar(filledSegments: GamePublicPileLevel.devCardFilledSegments(remaining: developmentDeckCount))
                    .padding(.bottom, 4)
            }
        }
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
        guard revealsBankCounts else { return "Supply level hidden" }
        return GamePublicPileLevel.devCardSupplyDescription(remaining: developmentDeckCount)
    }
}
