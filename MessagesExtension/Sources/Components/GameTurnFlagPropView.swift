import SwiftUI

struct GameTurnFlagPropView: View {
    let color: Color
    let isSelected: Bool

    var body: some View {
        Canvas { context, size in
            let poleX = size.width * 0.32
            let pole = Path { path in
                path.move(to: CGPoint(x: poleX, y: size.height * 0.14))
                path.addLine(to: CGPoint(x: poleX, y: size.height * 0.82))
            }
            let flag = Path { path in
                path.move(to: CGPoint(x: poleX, y: size.height * 0.18))
                path.addCurve(
                    to: CGPoint(x: size.width * 0.84, y: size.height * 0.32),
                    control1: CGPoint(x: size.width * 0.52, y: size.height * 0.10),
                    control2: CGPoint(x: size.width * 0.68, y: size.height * 0.36)
                )
                path.addLine(to: CGPoint(x: poleX, y: size.height * 0.50))
                path.closeSubpath()
            }
            let base = Path(
                roundedRect: CGRect(
                    x: size.width * 0.24,
                    y: size.height * 0.78,
                    width: size.width * 0.38,
                    height: size.height * 0.12
                ),
                cornerRadius: 2
            )

            if isSelected {
                context.stroke(flag, with: .color(GameTheme.surface.opacity(0.9)), lineWidth: 4)
            }
            context.stroke(pole, with: .color(Color(red: 0.34, green: 0.23, blue: 0.12)), lineWidth: 3)
            context.fill(flag, with: .color(color))
            context.stroke(flag, with: .color(.black.opacity(0.36)), lineWidth: 1)
            context.fill(base, with: .color(Color(red: 0.45, green: 0.31, blue: 0.16)))
        }
        .shadow(color: .black.opacity(isSelected ? 0.30 : 0.20), radius: 1.5, x: 0, y: 1)
        .accessibilityHidden(true)
    }
}
