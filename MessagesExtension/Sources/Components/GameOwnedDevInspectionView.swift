import SwiftUI

/// The private inventory is an inspection surface; only explicit actions play cards.
struct GameOwnedDevInspectionView: View {
    let panel: GameDevCardPanelModel?
    var allowsPlaying = true
    let onPlay: (GameDevCardActionKind) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Text("Your Dev Cards").font(.headline)
                if let panel {
                    Text(panel.message).font(.caption)
                    ForEach(panel.cards) { card in
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: card.kind.systemImage)
                                .frame(width: 24).accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 3) {
                                Text("\(card.kind.title) ×\(card.count)").font(.subheadline.bold())
                                Text(card.kind == .victoryPoint ? "\(card.count) hidden" : card.statusText).font(.caption.bold())
                                Text(card.kind == .victoryPoint ? "Counts immediately. Reveals automatically at 10 points on your turn." : card.detailText).font(.caption)
                            }
                            Spacer(minLength: 0)
                            if allowsPlaying, let action = card.actionKind, card.isEnabled, action != .revealVictoryPoint {
                                Button { onPlay(action) } label: { Text("Play").frame(minWidth: 44, minHeight: 44).contentShape(Rectangle()) }
                                    .buttonStyle(.bordered)
                                    .accessibilityLabel("Play \(card.kind.title)")
                                    .accessibilityIdentifier("uls.physicalProps.devCard.\(card.kind.rawValue)")
                            }
                        }
                        Divider()
                    }
                    ForEach(panel.timingNotes, id: \.self) { Text($0).font(.caption) }
                } else {
                    Text("Dev Cards are unavailable in this game phase.").font(.caption)
                }
            }
            .padding(12)
        }
        .foregroundStyle(GameTheme.felt)
        .background(GameTheme.surface, in: RoundedRectangle(cornerRadius: 12))
        .accessibilityIdentifier("uls.devCards.inventory")
    }
}
