import SwiftUI

struct GameDevCardChimneyMarkView: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        path.move(to: point(0.10, 0.82, in: rect))
        path.addLine(to: point(0.10, 0.48, in: rect))
        path.addLine(to: point(0.50, 0.22, in: rect))
        path.addLine(to: point(0.90, 0.48, in: rect))
        path.addLine(to: point(0.90, 0.82, in: rect))
        path.closeSubpath()

        path.move(to: point(0.62, 0.30, in: rect))
        path.addLine(to: point(0.62, 0.12, in: rect))
        path.addLine(to: point(0.76, 0.12, in: rect))
        path.addLine(to: point(0.76, 0.39, in: rect))

        path.move(to: point(0.73, 0.05, in: rect))
        path.addCurve(
            to: point(0.88, -0.10, in: rect),
            control1: point(0.67, -0.02, in: rect),
            control2: point(0.91, -0.02, in: rect)
        )

        return path
    }

    private func point(_ x: CGFloat, _ y: CGFloat, in rect: CGRect) -> CGPoint {
        CGPoint(x: rect.minX + rect.width * x, y: rect.minY + rect.height * y)
    }
}
