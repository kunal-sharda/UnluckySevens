import SwiftUI

struct GameTradeReceiptView: View {
    let visual: TranscriptTradeVisual
    let assetBundle: Bundle

    init(visual: TranscriptTradeVisual, assetBundle: Bundle = .main) {
        self.visual = visual
        self.assetBundle = assetBundle
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            (Text(visual.offer.proposerDisplay).fontWeight(.semibold) + Text(" offers"))
                .font(.subheadline)
                .foregroundStyle(GamePhysicalTurnPalette.primaryText)
                .fixedSize(horizontal: false, vertical: true)

            if isDense {
                VStack(alignment: .leading, spacing: 12) {
                    denseResourceRow(visual.offer.give, title: "Gives")
                    denseResourceRow(visual.offer.receive, title: "Wants")
                }
            } else {
                HStack(alignment: .center, spacing: 10) {
                    resourceGroup(visual.offer.give, title: "Gives")
                    Image(systemName: "arrow.right")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(GamePhysicalTurnPalette.secondaryText)
                        .accessibilityHidden(true)
                    resourceGroup(visual.offer.receive, title: "Wants")
                }
                .frame(maxWidth: .infinity)
            }

            recipientRoster
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    private var isDense: Bool {
        max(visual.offer.give.count, visual.offer.receive.count) > 3
    }

    private var isSimple: Bool {
        visual.offer.give.count == 1 && visual.offer.receive.count == 1
    }

    private var cardWidth: CGFloat {
        if isSimple {
            let largestStack = min(3, max(visual.offer.give.first?.count ?? 1, visual.offer.receive.first?.count ?? 1))
            return min(68, 128 / (1 + 0.75 * CGFloat(largestStack - 1)))
        }
        let count = max(1, visual.offer.give.count + visual.offer.receive.count)
        // Reserve the separator and inter-card gaps; both sides share card size.
        return min(48, (296 - CGFloat(max(0, count - 2)) * 8) / CGFloat(count))
    }

    private func resourceGroup(_ chips: [GameHandChip], title: String) -> some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(GamePhysicalTurnPalette.secondaryText)
            HStack(alignment: .top, spacing: 8) {
                ForEach(chips) { chip in
                    VStack(spacing: 6) {
                        TranscriptTradeCardStackView(
                            chip: chip,
                            cardWidth: cardWidth,
                            showsIndividualCards: isSimple,
                            assetBundle: assetBundle
                        )
                        resourceQuantity(chip)
                    }
                }
            }
        }
    }

    private func resourceQuantity(_ chip: GameHandChip) -> some View {
        VStack(spacing: 1) {
            Text("\(chip.count)")
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(GamePhysicalTurnPalette.primaryText)
            Text(chip.shortLabel)
                .font(.caption2)
                .foregroundStyle(GamePhysicalTurnPalette.secondaryText)
        }
        .fixedSize()
    }

    private func denseResourceRow(_ chips: [GameHandChip], title: String) -> some View {
        HStack(spacing: 10) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(GamePhysicalTurnPalette.secondaryText)
                .frame(width: 34, alignment: .leading)
            HStack(alignment: .top, spacing: 8) {
                ForEach(chips) { chip in
                    VStack(spacing: 4) {
                        GameTabletopPortraitCardView(
                            face: .resource(chip.resource),
                            size: CGSize(width: 48, height: 48 * 1.27),
                            assetBundle: assetBundle
                        )
                        resourceQuantity(chip)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var recipientRoster: some View {
        let participants = visual.participantStatuses
        if !participants.isEmpty && participants.allSatisfy({ $0.state == .waiting }) {
            VStack(alignment: .leading, spacing: 3) {
                (Text("To ") + Text(participants.map(\.displayName).joined(separator: " · ")).fontWeight(.medium))
                    .font(.caption)
                    .foregroundStyle(GamePhysicalTurnPalette.primaryText)
                    .fixedSize(horizontal: false, vertical: true)
                Text(participants.count == 1 ? "Awaiting reply" : "Awaiting replies")
                    .font(.caption2)
                    .foregroundStyle(GamePhysicalTurnPalette.secondaryText)
            }
        } else if participants.isEmpty {
            Text(visual.recipientScopeLabel)
                .font(.caption)
                .foregroundStyle(GamePhysicalTurnPalette.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        } else {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(participants) { status in
                    (Text(status.displayName).fontWeight(.medium)
                        .foregroundStyle(GamePhysicalTurnPalette.primaryText)
                     + Text(" · " + status.detailText)
                        .foregroundStyle(GamePhysicalTurnPalette.secondaryText))
                        .font(.caption)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private func resourceDescription(_ chips: [GameHandChip]) -> String {
        chips.map { "\($0.count) \($0.shortLabel)" }.joined(separator: " + ")
    }

    private var accessibilityLabel: String {
        let give = resourceDescription(visual.offer.give)
        let receive = resourceDescription(visual.offer.receive)
        return "\(visual.offer.proposerDisplay) offers \(give) for \(receive). \(visual.recipientScopeLabel)."
    }
}
