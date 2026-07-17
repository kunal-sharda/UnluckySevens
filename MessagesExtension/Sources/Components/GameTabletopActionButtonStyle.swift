import SwiftUI

struct GameTabletopActionButtonStyle: ButtonStyle {
    enum Emphasis: Equatable {
        case primary
        case secondary
    }

    let emphasis: Emphasis

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption)
            .bold()
            .foregroundStyle(GamePhysicalTurnPalette.primaryText)
            .frame(maxWidth: .infinity, minHeight: 44)
            .contentShape(Rectangle())
            .background {
                RoundedRectangle(cornerRadius: 7)
                    .fill(GamePhysicalTurnPalette.nameTileFill.opacity(0.28))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 7)
                    .stroke(
                        emphasis == .primary
                            ? GamePhysicalTurnPalette.selectedKeyline
                            : GamePhysicalTurnPalette.nameTileEdge,
                        lineWidth: emphasis == .primary ? 1.5 : 1
                    )
            }
            .opacity(configuration.isPressed ? 0.72 : 1)
    }
}
