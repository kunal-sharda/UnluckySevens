import SwiftUI

struct GamePhysicalDieView: View {
    let value: Int
    let size: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.18)
                .fill(GamePhysicalTurnPalette.primaryText)

            ForEach(
                GameDiePipLayout.positions(for: min(max(value, 1), 6)).enumerated(),
                id: \.offset
            ) { _, position in
                Circle()
                    .fill(GamePhysicalTurnPalette.cardCountInk)
                    .frame(width: size * 0.13, height: size * 0.13)
                    .position(x: position.x * size, y: position.y * size)
            }
        }
        .frame(width: size, height: size)
        .overlay(alignment: .top) {
            Capsule()
                .fill(.white.opacity(0.32))
                .frame(width: size * 0.58, height: 1.4)
                .padding(.top, 2)
        }
        .overlay {
            RoundedRectangle(cornerRadius: size * 0.18)
                .stroke(.black.opacity(0.42), lineWidth: 1.4)
        }
        .shadow(color: .black.opacity(0.34), radius: 2, x: 0, y: 2)
        .accessibilityHidden(true)
    }
}
