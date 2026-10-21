import SwiftUI

struct GameTabletopActionButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    enum Emphasis: Equatable {
        case primary
        case secondary
        case destructive
    }

    let emphasis: Emphasis
    var solidBackground = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption)
            .bold()
            .foregroundStyle(
                emphasis == .destructive
                    ? Color.red
                    : GamePhysicalTurnPalette.primaryText
            )
            .opacity(solidBackground && !isEnabled ? 0.56 : 1)
            .frame(maxWidth: .infinity, minHeight: 44)
            .contentShape(Rectangle())
            .background {
                RoundedRectangle(cornerRadius: 7)
                    .fill(GamePhysicalTurnPalette.nameTileFill.opacity(solidBackground ? 1 : 0.28))
                    .overlay {
                        if solidBackground && configuration.isPressed {
                            RoundedRectangle(cornerRadius: 7)
                                .fill(.black.opacity(0.20))
                        }
                    }
            }
            .overlay {
                RoundedRectangle(cornerRadius: 7)
                    .stroke(borderColor, lineWidth: emphasis == .primary ? 1.5 : 1)
            }
            .opacity(!solidBackground && configuration.isPressed ? 0.72 : 1)
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
