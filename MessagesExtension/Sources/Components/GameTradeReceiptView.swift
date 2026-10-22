import SwiftUI

struct GameTradeReceiptView: View {
    let visual: TranscriptTradeVisual
    let assetBundle: Bundle

    init(
        visual: TranscriptTradeVisual,
        assetBundle: Bundle = .main
    ) {
        self.visual = visual
        self.assetBundle = assetBundle
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\(visual.offer.proposerDisplay) offers")
                .font(.headline)
                .foregroundStyle(GamePhysicalTurnPalette.primaryText)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            if max(visual.offer.give.count, visual.offer.receive.count) > 3 {
                VStack(spacing: 8) {
                    denseResourceRow(visual.offer.give, title: "Gives")
                    denseResourceRow(visual.offer.receive, title: "Wants")
                }
            } else {
                HStack(spacing: 12) {
                    resourceGroup(visual.offer.give, title: "Gives")
                    Image(systemName: "arrow.right")
                        .font(.headline.bold())
                        .foregroundStyle(GamePhysicalTurnPalette.selectedKeyline)
                        .accessibilityHidden(true)
                    resourceGroup(visual.offer.receive, title: "Wants")
                }
                .frame(maxWidth: .infinity)
            }

            if !visual.participantStatuses.isEmpty {
                HStack(spacing: 8) {
                    ForEach(visual.participantStatuses) { status in
                        VStack(alignment: .leading, spacing: 3) {
                            Text(status.displayName)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(GamePhysicalTurnPalette.primaryText)
                                .lineLimit(1)
                            Label(status.detailText, systemImage: statusSymbol(for: status.state))
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.caption2)
                        .foregroundStyle(GamePhysicalTurnPalette.secondaryText)
                    }
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    private func resourceGroup(_ chips: [GameHandChip], title: String) -> some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(GamePhysicalTurnPalette.secondaryText)
            GeometryReader { geometry in
                let groupWidth = max(1, (geometry.size.width - CGFloat(max(chips.count - 1, 0)) * 5) / CGFloat(max(chips.count, 1)))
                HStack(alignment: .top, spacing: 5) {
                    ForEach(chips) { chip in
                        VStack(spacing: 5) {
                            TranscriptTradeCardStackView(chip: chip, availableWidth: groupWidth, assetBundle: assetBundle)
                                .frame(height: 68, alignment: .bottom)
                            Text(chips.count > 3 ? "\(chip.count)" : "\(chip.count) \(chip.shortLabel)")
                                .font(.caption2.weight(.semibold))
                                .monospacedDigit()
                                .foregroundStyle(GamePhysicalTurnPalette.primaryText)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(width: groupWidth)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .frame(height: 100)
            let total = chips.reduce(0) { $0 + $1.count }
            Text("\(total) \(total == 1 ? "card" : "cards")")
                .font(.caption.weight(.bold))
                .monospacedDigit()
                .foregroundStyle(GamePhysicalTurnPalette.primaryText)
        }
        .frame(maxWidth: .infinity)
    }

    private func denseResourceRow(_ chips: [GameHandChip], title: String) -> some View {
        let total = chips.reduce(0) { $0 + $1.count }
        return HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.caption.weight(.semibold))
                Text("\(total) \(total == 1 ? "card" : "cards")")
                    .font(.caption2)
                    .monospacedDigit()
            }
            .foregroundStyle(GamePhysicalTurnPalette.secondaryText)
            .frame(width: 45, alignment: .leading)
            GeometryReader { geometry in
                let width = min(42, (geometry.size.width - CGFloat(max(chips.count - 1, 0)) * 5) / CGFloat(max(chips.count, 1)))
                HStack(spacing: 5) {
                    ForEach(chips) { chip in
                        VStack(spacing: 3) {
                            GameTabletopPortraitCardView(face: .resource(chip.resource), size: CGSize(width: width, height: width * 1.27), assetBundle: assetBundle)
                            Text("\(chip.count)")
                                .font(.caption2.weight(.semibold))
                                .monospacedDigit()
                                .foregroundStyle(GamePhysicalTurnPalette.primaryText)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .frame(height: 70)
    }

    private func resourceDescription(_ chips: [GameHandChip]) -> String {
        chips
            .map { "\($0.count) \($0.shortLabel)" }
            .joined(separator: " + ")
    }

    private func statusSymbol(
        for state: GameTradeParticipantResponseState
    ) -> String {
        switch state {
        case .watching, .waiting:
            "clock"
        case .accepted:
            "checkmark.circle.fill"
        case .declined:
            "xmark.circle.fill"
        case .countered:
            "arrow.triangle.2.circlepath"
        }
    }

    private var accessibilityLabel: String {
        let give = resourceDescription(visual.offer.give)
        let receive = resourceDescription(visual.offer.receive)
        return "\(visual.offer.proposerDisplay) offers \(give) for \(receive). \(visual.recipientScopeLabel)."
    }
}
