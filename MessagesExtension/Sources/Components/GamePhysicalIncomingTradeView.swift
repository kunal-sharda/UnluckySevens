import SwiftUI

struct GamePhysicalIncomingTradeView: View {
    static let minimumHeight: CGFloat = 96

    let offer: GameTradeOfferSummary
    let actions: GameTradeResponderActions
    let assetBundle: Bundle
    let onAccept: () -> Void
    let onDecline: () -> Void
    let onCounter: () -> Void

    init(
        offer: GameTradeOfferSummary,
        actions: GameTradeResponderActions,
        assetBundle: Bundle = .main,
        onAccept: @escaping () -> Void,
        onDecline: @escaping () -> Void,
        onCounter: @escaping () -> Void
    ) {
        self.offer = offer
        self.actions = actions
        self.assetBundle = assetBundle
        self.onAccept = onAccept
        self.onDecline = onDecline
        self.onCounter = onCounter
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(offer.proposerDisplay) offers")
                        .font(.caption)
                        .bold()
                        .foregroundStyle(GamePhysicalTurnPalette.primaryText)

                    Text(offer.recipientsLabel)
                        .font(.footnote)
                        .foregroundStyle(GamePhysicalTurnPalette.secondaryText)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                resourceCards(offer.give)

                Image(systemName: "arrow.right")
                    .font(.footnote)
                    .bold()
                    .foregroundStyle(GamePhysicalTurnPalette.selectedKeyline)
                    .accessibilityHidden(true)

                resourceCards(offer.receive)
            }
            .frame(height: 42)

            GameTradeResponderActionRow(
                actions: actions,
                usesPhysicalProps: true,
                onAccept: onAccept,
                onDecline: onDecline,
                onCounter: onCounter
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(offerAccessibilityLabel)
        .accessibilityIdentifier("uls.notPrimary.incomingTrade")
    }

    private func resourceCards(_ chips: [GameHandChip]) -> some View {
        HStack(spacing: 3) {
            ForEach(chips) { chip in
                GameTabletopPortraitCardView(
                    face: .resource(chip.resource),
                    size: CGSize(width: 27, height: 34),
                    count: chip.count,
                    stackDepth: 1,
                    assetBundle: assetBundle
                )
            }
        }
    }

    private var offerAccessibilityLabel: String {
        let give = offer.give.map { "\($0.count) \($0.shortLabel)" }.joined(separator: ", ")
        let receive = offer.receive.map { "\($0.count) \($0.shortLabel)" }.joined(separator: ", ")
        return "\(offer.proposerDisplay) offers \(give) for \(receive). \(offer.recipientsLabel)."
    }
}
