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
                .font(.caption)
                .foregroundStyle(GamePhysicalTurnPalette.primaryText)
                .fixedSize(horizontal: false, vertical: true)

            if isDense {
                VStack(alignment: .leading, spacing: 12) {
                    denseResourceRow(visual.offer.give, title: "Gives")
                    denseResourceRow(visual.offer.receive, title: "Wants")
                }
            } else {
                HStack(alignment: .center, spacing: 10) {
                    resourceGroup(visual.offer.give)
                    Image(systemName: "arrow.right")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(GamePhysicalTurnPalette.secondaryText)
                        .accessibilityHidden(true)
                    resourceGroup(visual.offer.receive)
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
        return min(56, (296 + CGFloat(max(0, count - 2)) * 6) / CGFloat(count))
    }

    private func resourceGroup(_ chips: [GameHandChip]) -> some View {
        HStack(alignment: .top, spacing: isSimple ? 8 : -6) {
            ForEach(Array(chips.enumerated()), id: \.element.id) { index, chip in
                VStack(spacing: 4) {
                    TranscriptTradeCardStackView(
                        chip: chip,
                        cardWidth: cardWidth,
                        showsIndividualCards: isSimple,
                        assetBundle: assetBundle
                    )
                    .rotationEffect(.degrees(isSimple ? 0 : (Double(index) - Double(chips.count - 1) / 2) * 7))
                    .padding(.vertical, isSimple ? 0 : 5)
                    resourceQuantity(chip)
                }
            }
        }
    }

    private func resourceQuantity(_ chip: GameHandChip) -> some View {
        (Text("\(chip.count)").fontWeight(.semibold) + Text(" " + chip.shortLabel))
            .font(.caption2)
            .monospacedDigit()
            .foregroundStyle(GamePhysicalTurnPalette.primaryText)
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
        if participants.isEmpty {
            Text(visual.recipientScopeLabel)
                .font(.caption)
                .foregroundStyle(GamePhysicalTurnPalette.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        } else {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(responseGroups) { group in
                    let names = participants.filter {
                        $0.state == group.state && $0.detailText == group.detailText
                    }.map(\.displayName).joined(separator: ", ")
                    (Text(group.detailText + " · ")
                        .foregroundStyle(GamePhysicalTurnPalette.secondaryText)
                     + Text(names).fontWeight(.medium)
                        .foregroundStyle(GamePhysicalTurnPalette.primaryText))
                        .font(.caption)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    // Preserve distinct response meanings, even if two states share a label.
    // First appearance keeps the existing participant ordering stable.
    private var responseGroups: [GameTradeParticipantStatus] {
        visual.participantStatuses.enumerated().compactMap { index, participant in
            let alreadyShown = visual.participantStatuses.prefix(index).contains {
                $0.state == participant.state && $0.detailText == participant.detailText
            }
            return alreadyShown ? nil : participant
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
