import SwiftUI

struct GameTabletopActionButtonStyle: ButtonStyle {
    enum Emphasis: Equatable {
        case primary
        case secondary
        case destructive
    }

    let emphasis: Emphasis

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption)
            .bold()
            .foregroundStyle(
                emphasis == .destructive
                    ? Color.red
                    : GamePhysicalTurnPalette.primaryText
            )
            .frame(maxWidth: .infinity, minHeight: 44)
            .contentShape(Rectangle())
            .background {
                RoundedRectangle(cornerRadius: 7)
                    .fill(GamePhysicalTurnPalette.nameTileFill.opacity(0.28))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 7)
                    .stroke(borderColor, lineWidth: emphasis == .primary ? 1.5 : 1)
            }
            .opacity(configuration.isPressed ? 0.72 : 1)
    }

    private var borderColor: Color {
        switch emphasis {
        case .primary:
            GamePhysicalTurnPalette.selectedKeyline
        case .secondary:
            GamePhysicalTurnPalette.nameTileEdge
        case .destructive:
            .red.opacity(0.72)
        }
    }
}
