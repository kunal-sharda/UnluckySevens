import SwiftUI

struct HexagonShape: Shape {
    func path(in rect: CGRect) -> Path {
        let width = rect.width
        let height = rect.height
        let horizontalInset = width * 0.25

        var path = Path()
        path.move(to: CGPoint(x: width * 0.5, y: 0))
        path.addLine(to: CGPoint(x: width - horizontalInset, y: 0))
        path.addLine(to: CGPoint(x: width, y: height * 0.5))
        path.addLine(to: CGPoint(x: width - horizontalInset, y: height))
        path.addLine(to: CGPoint(x: horizontalInset, y: height))
        path.addLine(to: CGPoint(x: 0, y: height * 0.5))
        path.closeSubpath()
        return path
    }
}
