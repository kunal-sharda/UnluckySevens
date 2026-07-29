import SwiftUI

struct LobbyRobberIdentityMark: View {
    var body: some View {
        Canvas { context, size in
            let height = min(size.height * 0.86, size.width * 1.72)
            let paths = RobberPieceGeometry.paths(
                center: CGPoint(x: size.width / 2, y: size.height / 2),
                height: height
            )
            let pieceColor = Color(uiColor: RobberPieceGeometry.pieceColor)

            [paths.base, paths.body, paths.head].forEach {
                context.fill(Path($0), with: .color(pieceColor))
            }

            context.fill(
                Path(paths.mask),
                with: .color(Color(uiColor: RobberPieceGeometry.maskColor))
            )
            context.stroke(
                Path(paths.maskContour),
                with: .color(Color(uiColor: RobberPieceGeometry.maskContourColor)),
                style: StrokeStyle(
                    lineWidth: max(height * 0.006, 0.8),
                    lineCap: .round,
                    lineJoin: .round
                )
            )
            context.fill(Path(paths.eyes), with: .color(pieceColor))
            context.stroke(
                Path(paths.seven),
                with: .color(Color(uiColor: RobberPieceGeometry.sevenColor)),
                style: StrokeStyle(
                    lineWidth: paths.sevenLineWidth,
                    lineCap: .square,
                    lineJoin: .miter
                )
            )
        }
        .accessibilityHidden(true)
    }
}
