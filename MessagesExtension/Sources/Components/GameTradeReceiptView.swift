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
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(visual.offer.proposerDisplay) offers")
                    .font(.headline)
                    .foregroundStyle(GamePhysicalTurnPalette.primaryText)

                Spacer(minLength: 8)

                Text(visual.recipientScopeLabel)
                    .font(.caption)
                    .foregroundStyle(GamePhysicalTurnPalette.secondaryText)
                    .lineLimit(1)
            }

            HStack(spacing: 12) {
                resourceGroup(visual.offer.give)

                Image(systemName: "arrow.right")
                    .font(.headline)
                    .bold()
                    .foregroundStyle(GamePhysicalTurnPalette.selectedKeyline)
                    .accessibilityHidden(true)

                resourceGroup(visual.offer.receive)
            }
            .frame(maxWidth: .infinity)

            if !visual.participantStatuses.isEmpty {
                HStack(spacing: 8) {
                    ForEach(visual.participantStatuses) { status in
                        HStack(spacing: 5) {
                            Image(systemName: statusSymbol(for: status.state))
                                .font(.caption2)
                                .accessibilityHidden(true)

                            Text("\(status.displayName) \(status.detailText)")
                                .lineLimit(1)
                        }
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

    private func resourceGroup(_ chips: [GameHandChip]) -> some View {
        VStack(spacing: 5) {
            HStack(spacing: 4) {
                ForEach(chips) { chip in
                    GameTabletopPortraitCardView(
                        face: .resource(chip.resource),
                        size: CGSize(width: 34, height: 43),
                        count: chip.count,
                        stackDepth: 1,
                        assetBundle: assetBundle
                    )
                }
            }

            Text(resourceDescription(chips))
                .font(.caption2)
                .foregroundStyle(GamePhysicalTurnPalette.secondaryText)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
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
