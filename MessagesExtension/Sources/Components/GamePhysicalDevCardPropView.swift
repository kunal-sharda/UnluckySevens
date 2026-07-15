import SwiftUI

struct GamePhysicalDevCardPropView: View {
    let card: GameDevCardTileModel
    let action: GameDevCardActionKind
    let onSelect: (GameDevCardActionKind) -> Void

    var body: some View {
        Button {
            onSelect(action)
        } label: {
            VStack(spacing: 3) {
                GameTabletopPortraitCardView(
                    face: .ownedDevelopment(card.kind),
                    size: CGSize(width: 42, height: 55),
                    count: card.count,
                    isFaded: false,
                    stackDepth: min(card.count, 2)
                )

                Text(displayTitle)
                    .font(.caption)
                    .bold()
                    .foregroundStyle(GamePhysicalTurnPalette.primaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(width: 78, height: 30, alignment: .top)
            }
            .frame(width: 78)
            .frame(minHeight: 88)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(card.kind.title), \(card.count) owned")
        .accessibilityHint("Selects this Dev Card")
    }

    private var displayTitle: String {
        switch card.kind {
        case .yearOfPlenty:
            return "Plenty"
        case .roadBuilding:
            return "Roads"
        default:
            return card.kind.title
        }
    }
}
