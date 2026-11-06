import CoreGraphics

enum GamePlayerMark: Int, CaseIterable {
    case circle, triangle, square, diamond

    static func resolve(owner: String, playerOrder: [String]) -> Self {
        let index = playerOrder.firstIndex(of: owner) ?? 0
        return allCases[index % allCases.count]
    }

    var name: String {
        switch self {
        case .circle: "Circle"
        case .triangle: "Triangle"
        case .square: "Square"
        case .diamond: "Diamond"
        }
    }

    func path(in rect: CGRect) -> CGPath {
        switch self {
        case .circle:
            return CGPath(ellipseIn: rect, transform: nil)
        case .square:
            return CGPath(rect: rect, transform: nil)
        case .triangle, .diamond:
            let path = CGMutablePath()
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: self == .triangle ? rect.maxY : rect.midY))
            if self == .diamond { path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY)) }
            path.addLine(to: CGPoint(x: rect.minX, y: self == .triangle ? rect.maxY : rect.midY))
            path.closeSubpath()
            return path
        }
    }
}
