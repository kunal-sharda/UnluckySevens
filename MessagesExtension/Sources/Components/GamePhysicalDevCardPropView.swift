import SwiftUI

struct GamePhysicalDevCardPropView: View {
    let card: GameDevCardTileModel
    let action: GameDevCardActionKind?
    let onSelect: (GameDevCardActionKind) -> Void

    var body: some View {
        Button {
            guard let action else { return }
            onSelect(action)
        } label: {
            VStack(spacing: 1) {
                ZStack(alignment: .bottom) {
                    GameTabletopPortraitCardView(
                        face: .ownedDevelopment(card.kind),
                        size: GamePhysicalTurnLayout.portraitCardSize,
                        count: card.count,
                        isFaded: action == nil,
                        stackDepth: min(card.count, 2)
                    )

                    if card.statusText.contains("new") {
                        Text("New")
                            .font(.caption2)
                            .bold()
                            .foregroundStyle(GamePhysicalTurnPalette.publicPileRevealInk)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(
                                Capsule()
                                    .fill(GamePhysicalTurnPalette.devCardEdge.opacity(0.94))
                            )
                            .offset(y: 4)
                    }
                }
                .overlay {
                    if action != nil {
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(GamePhysicalTurnPalette.selectedKeyline, lineWidth: 1.25)
                    }
                }

                VStack(spacing: 0) {
                    ForEach(Array(displayTitleLines.enumerated()), id: \.offset) { _, line in
                        Text(verbatim: line)
                    }
                }
                    .font(.caption2)
                    .bold()
                    .foregroundStyle(GamePhysicalTurnPalette.primaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .frame(width: 66, height: 20, alignment: .top)
            }
            .frame(width: 66)
            .frame(minHeight: 68)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(action == nil)
        .accessibilityIdentifier("uls.physicalProps.devCard.\(card.kind.rawValue)")
        .accessibilityLabel("\(card.kind.title), \(card.count) owned")
        .accessibilityValue(card.statusText)
        .accessibilityHint(action == nil ? card.detailText : "Selects this Dev Card")
    }

    private var displayTitleLines: [String] {
        switch card.kind {
        case .yearOfPlenty:
            return ["Year of", "Plenty"]
        case .roadBuilding:
            return ["Road", "Builder"]
        case .victoryPoint:
            return ["Victory", "Point"]
        default:
            return [card.kind.title]
        }
    }
}
