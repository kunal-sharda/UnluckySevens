import SwiftUI

struct GameTabletopPiecePropView: View {
    enum Kind {
        case road
        case settlement
        case city
    }

    let kind: Kind
    let color: Color
    let isSelected: Bool

    var body: some View {
        Canvas { context, size in
            switch kind {
            case .road:
                drawRoad(in: &context, size: size)
            case .settlement:
                drawStructure(.settlement, in: &context, size: size)
            case .city:
                drawStructure(.city, in: &context, size: size)
            }
        }
        .shadow(
            color: .black.opacity(isSelected ? 0.30 : 0.20),
            radius: isSelected ? 2 : 1.5,
            x: 0,
            y: 1
        )
        .accessibilityHidden(true)
    }

    private func drawRoad(
        in context: inout GraphicsContext,
        size: CGSize
    ) {
        let path = centeredPath(
            GamePieceGeometry.roadPath(length: size.width * 0.76),
            in: size
        )
        let width = max(size.height * 0.185, 5.4)

        if isSelected {
            context.stroke(
                path,
                with: .color(GameTheme.surface.opacity(0.86)),
                style: StrokeStyle(lineWidth: width + 5, lineCap: .round)
            )
        }
        context.stroke(
            path,
            with: .color(.black.opacity(0.38)),
            style: StrokeStyle(lineWidth: width + 2.2, lineCap: .round)
        )
        context.stroke(
            path,
            with: .color(color),
            style: StrokeStyle(lineWidth: width, lineCap: .round)
        )
        context.stroke(
            path,
            with: .color(.white.opacity(0.18)),
            style: StrokeStyle(lineWidth: max(width * 0.22, 1.5), lineCap: .round)
        )
    }

    private func drawStructure(
        _ structure: GamePieceGeometry.StructureKind,
        in context: inout GraphicsContext,
        size: CGSize
    ) {
        let radius = min(size.width, size.height) * 0.59
        let body = centeredPath(
            GamePieceGeometry.structurePath(kind: structure, radius: radius),
            in: size,
            flipsVertically: true
        )
        if isSelected {
            context.stroke(
                body,
                with: .color(GameTheme.surface.opacity(0.90)),
                lineWidth: 4
            )
        }
        context.fill(body, with: .color(color))
        context.stroke(body, with: .color(.black.opacity(0.40)), lineWidth: 1.4)
    }

    private func centeredPath(
        _ path: CGPath,
        in size: CGSize,
        flipsVertically: Bool = false
    ) -> Path {
        var transform = CGAffineTransform(
            translationX: size.width / 2,
            y: size.height / 2
        )
        if flipsVertically {
            transform = transform.scaledBy(x: 1, y: -1)
        }
        return Path(path.copy(using: &transform) ?? path)
    }
}
