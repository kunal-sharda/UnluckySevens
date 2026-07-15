import CoreGraphics

enum GamePieceGeometry {
    enum StructureKind {
        case settlement
        case city
    }

    static func roadPath(length: CGFloat) -> CGPath {
        let halfLength = max(length, 1) / 2
        let path = CGMutablePath()
        path.move(to: CGPoint(x: -halfLength, y: 0))
        path.addLine(to: CGPoint(x: halfLength, y: 0))
        return path
    }

    static func structurePath(
        kind: StructureKind,
        radius: CGFloat
    ) -> CGPath {
        let adjustedRadius = max(radius, 8) * structureScale(for: kind)
        let path = CGMutablePath()

        switch kind {
        case .settlement:
            path.move(to: CGPoint(x: -adjustedRadius * 0.70, y: -adjustedRadius * 0.58))
            path.addLine(to: CGPoint(x: -adjustedRadius * 0.70, y: adjustedRadius * 0.10))
            path.addLine(to: CGPoint(x: 0, y: adjustedRadius * 0.78))
            path.addLine(to: CGPoint(x: adjustedRadius * 0.70, y: adjustedRadius * 0.10))
            path.addLine(to: CGPoint(x: adjustedRadius * 0.70, y: -adjustedRadius * 0.58))
            path.closeSubpath()
        case .city:
            path.move(to: CGPoint(x: -adjustedRadius * 0.90, y: -adjustedRadius * 0.62))
            path.addLine(to: CGPoint(x: -adjustedRadius * 0.90, y: adjustedRadius * 0.31))
            path.addLine(to: CGPoint(x: -adjustedRadius * 0.45, y: adjustedRadius * 0.62))
            path.addLine(to: CGPoint(x: 0, y: adjustedRadius * 0.31))
            path.addLine(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: adjustedRadius * 0.90, y: 0))
            path.addLine(to: CGPoint(x: adjustedRadius * 0.90, y: -adjustedRadius * 0.62))
            path.closeSubpath()
        }

        return path
    }

    static func structureCapPath(
        kind: StructureKind,
        radius: CGFloat
    ) -> CGPath {
        let adjustedRadius = max(radius, 8) * structureScale(for: kind)
        let path = CGMutablePath()

        switch kind {
        case .settlement:
            path.move(to: CGPoint(x: -adjustedRadius * 0.52, y: adjustedRadius * 0.04))
            path.addLine(to: CGPoint(x: 0, y: adjustedRadius * 0.54))
            path.addLine(to: CGPoint(x: adjustedRadius * 0.52, y: adjustedRadius * 0.04))
            path.closeSubpath()
        case .city:
            path.move(to: CGPoint(x: -adjustedRadius * 0.78, y: adjustedRadius * 0.31))
            path.addLine(to: CGPoint(x: -adjustedRadius * 0.45, y: adjustedRadius * 0.54))
            path.addLine(to: CGPoint(x: -adjustedRadius * 0.12, y: adjustedRadius * 0.31))
            path.closeSubpath()
        }

        return path
    }

    static func structureScale(for kind: StructureKind) -> CGFloat {
        switch kind {
        case .settlement: return 1
        case .city: return 1.22
        }
    }
}
