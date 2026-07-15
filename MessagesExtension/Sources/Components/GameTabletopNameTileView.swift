import SwiftUI

struct GameTabletopNameTileView: View {
    let title: String
    let width: CGFloat
    let isSelected: Bool

    var body: some View {
        Text(title)
            .font(.caption.bold())
            .foregroundStyle(GamePhysicalTurnPalette.nameTileInk)
            .lineLimit(1)
            .minimumScaleFactor(0.82)
            .frame(width: width, height: 17)
            .background {
                RoundedRectangle(cornerRadius: 3)
                    .fill(GamePhysicalTurnPalette.nameTileFill)
                    .overlay(alignment: .top) {
                        Rectangle()
                            .fill(.white.opacity(0.09))
                            .frame(height: 1)
                            .padding(.horizontal, 3)
                    }
            }
            .overlay {
                RoundedRectangle(cornerRadius: 3)
                    .stroke(
                        isSelected
                            ? GamePhysicalTurnPalette.selectedKeyline
                            : GamePhysicalTurnPalette.nameTileEdge,
                        lineWidth: isSelected ? 1.4 : 1
                    )
            }
            .accessibilityHidden(true)
    }
}
