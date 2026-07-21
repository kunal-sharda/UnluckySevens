import CoreGraphics
import UIKit

enum RobberPieceGeometry {
    struct Paths {
        let head: CGPath
        let body: CGPath
        let base: CGPath
        let mask: CGPath
        let eyes: CGPath
        let maskContour: CGPath
        let seven: CGPath
        let sevenLineWidth: CGFloat
    }

    static let pieceColor = UIColor(red: CGFloat(0xA9) / 255, green: CGFloat(0xB5) / 255, blue: CGFloat(0xB6) / 255, alpha: 1)
    static let maskColor = UIColor(red: CGFloat(0x29) / 255, green: CGFloat(0x23) / 255, blue: CGFloat(0x1F) / 255, alpha: 1)
    static let maskContourColor = UIColor(red: CGFloat(0x5A) / 255, green: CGFloat(0x4C) / 255, blue: CGFloat(0x42) / 255, alpha: 0.72)
    static let sevenColor = UIColor(red: CGFloat(0x9E) / 255, green: CGFloat(0x35) / 255, blue: CGFloat(0x42) / 255, alpha: 1)

    static func paths(center: CGPoint, height: CGFloat) -> Paths {
        let scale = height / 392
        var transform = CGAffineTransform.identity
            .translatedBy(x: center.x, y: center.y)
            .scaledBy(x: scale, y: scale)
            .translatedBy(x: -260, y: -253)

        return Paths(
            head: sourceHead.copy(using: &transform) ?? sourceHead,
            body: sourceBody.copy(using: &transform) ?? sourceBody,
            base: sourceBase.copy(using: &transform) ?? sourceBase,
            mask: sourceMask.copy(using: &transform) ?? sourceMask,
            eyes: sourceEyes.copy(using: &transform) ?? sourceEyes,
            maskContour: sourceMaskContour.copy(using: &transform) ?? sourceMaskContour,
            seven: sourceSeven.copy(using: &transform) ?? sourceSeven,
            sevenLineWidth: 21.6 * scale
        )
    }

    private static let sourceHead: CGPath = {
        let path = CGMutablePath()
        path.addEllipse(in: CGRect(x: 200, y: 57, width: 120, height: 120))
        return path
    }()

    private static let sourceBody: CGPath = {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 226, y: 169))
        path.addCurve(to: CGPoint(x: 178, y: 287), control1: CGPoint(x: 196, y: 189), control2: CGPoint(x: 178, y: 235))
        path.addCurve(to: CGPoint(x: 217, y: 378), control1: CGPoint(x: 178, y: 334), control2: CGPoint(x: 195, y: 364))
        path.addCurve(to: CGPoint(x: 303, y: 378), control1: CGPoint(x: 239, y: 389), control2: CGPoint(x: 281, y: 389))
        path.addCurve(to: CGPoint(x: 342, y: 287), control1: CGPoint(x: 325, y: 364), control2: CGPoint(x: 342, y: 334))
        path.addCurve(to: CGPoint(x: 294, y: 169), control1: CGPoint(x: 342, y: 235), control2: CGPoint(x: 324, y: 189))
        path.addCurve(to: CGPoint(x: 226, y: 169), control1: CGPoint(x: 276, y: 178), control2: CGPoint(x: 244, y: 178))
        path.closeSubpath()
        return path
    }()

    private static let sourceBase: CGPath = {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 196, y: 357))
        path.addLine(to: CGPoint(x: 324, y: 357))
        path.addCurve(to: CGPoint(x: 340, y: 373), control1: CGPoint(x: 333, y: 357), control2: CGPoint(x: 340, y: 364))
        path.addLine(to: CGPoint(x: 340, y: 420))
        path.addCurve(to: CGPoint(x: 260, y: 449), control1: CGPoint(x: 340, y: 439), control2: CGPoint(x: 315, y: 449))
        path.addCurve(to: CGPoint(x: 180, y: 420), control1: CGPoint(x: 205, y: 449), control2: CGPoint(x: 180, y: 439))
        path.addLine(to: CGPoint(x: 180, y: 373))
        path.addCurve(to: CGPoint(x: 196, y: 357), control1: CGPoint(x: 180, y: 364), control2: CGPoint(x: 187, y: 357))
        path.closeSubpath()
        return path
    }()

    private static let sourceMask: CGPath = {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 199, y: 103))
        path.addCurve(to: CGPoint(x: 260, y: 97), control1: CGPoint(x: 217, y: 92), control2: CGPoint(x: 238, y: 89))
        path.addCurve(to: CGPoint(x: 321, y: 103), control1: CGPoint(x: 282, y: 89), control2: CGPoint(x: 303, y: 92))
        path.addLine(to: CGPoint(x: 318, y: 129))
        path.addCurve(to: CGPoint(x: 269, y: 134), control1: CGPoint(x: 306, y: 139), control2: CGPoint(x: 288, y: 142))
        path.addLine(to: CGPoint(x: 260, y: 129))
        path.addLine(to: CGPoint(x: 251, y: 134))
        path.addCurve(to: CGPoint(x: 202, y: 129), control1: CGPoint(x: 232, y: 142), control2: CGPoint(x: 214, y: 139))
        path.closeSubpath()
        return path
    }()

    private static let sourceEyes: CGPath = {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 214, y: 112))
        path.addCurve(to: CGPoint(x: 254, y: 108), control1: CGPoint(x: 226, y: 104), control2: CGPoint(x: 240, y: 102))
        path.addCurve(to: CGPoint(x: 216, y: 121), control1: CGPoint(x: 246, y: 120), control2: CGPoint(x: 234, y: 125))
        path.closeSubpath()
        path.move(to: CGPoint(x: 306, y: 112))
        path.addCurve(to: CGPoint(x: 266, y: 108), control1: CGPoint(x: 294, y: 104), control2: CGPoint(x: 280, y: 102))
        path.addCurve(to: CGPoint(x: 304, y: 121), control1: CGPoint(x: 274, y: 120), control2: CGPoint(x: 286, y: 125))
        path.closeSubpath()
        return path
    }()

    private static let sourceMaskContour: CGPath = {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 204, y: 105))
        path.addCurve(to: CGPoint(x: 260, y: 102), control1: CGPoint(x: 220, y: 97), control2: CGPoint(x: 239, y: 95))
        path.addCurve(to: CGPoint(x: 316, y: 105), control1: CGPoint(x: 281, y: 95), control2: CGPoint(x: 300, y: 97))
        path.move(to: CGPoint(x: 204, y: 127))
        path.addCurve(to: CGPoint(x: 250, y: 130), control1: CGPoint(x: 216, y: 135), control2: CGPoint(x: 233, y: 136))
        path.addLine(to: CGPoint(x: 260, y: 125))
        path.addLine(to: CGPoint(x: 270, y: 130))
        path.addCurve(to: CGPoint(x: 316, y: 127), control1: CGPoint(x: 287, y: 136), control2: CGPoint(x: 304, y: 135))
        path.move(to: CGPoint(x: 203, y: 106))
        path.addCurve(to: CGPoint(x: 203, y: 127), control1: CGPoint(x: 200, y: 113), control2: CGPoint(x: 200, y: 120))
        path.move(to: CGPoint(x: 317, y: 106))
        path.addCurve(to: CGPoint(x: 317, y: 127), control1: CGPoint(x: 320, y: 113), control2: CGPoint(x: 320, y: 120))
        return path
    }()

    private static let sourceSeven: CGPath = {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 230, y: 257.2))
        path.addLine(to: CGPoint(x: 292.4, y: 257.2))
        path.addLine(to: CGPoint(x: 242, y: 341.2))
        return path
    }()
}

enum RobberPieceDrawing {
    static func draw(center: CGPoint, height: CGFloat, in context: CGContext) {
        let paths = RobberPieceGeometry.paths(center: center, height: height)

        context.saveGState()
        context.setFillColor(RobberPieceGeometry.pieceColor.cgColor)
        [paths.base, paths.body, paths.head].forEach {
            context.addPath($0)
            context.fillPath()
        }

        context.setFillColor(RobberPieceGeometry.maskColor.cgColor)
        context.addPath(paths.mask)
        context.fillPath()

        context.setStrokeColor(RobberPieceGeometry.maskContourColor.cgColor)
        context.setLineWidth(max(height * 0.006, 0.8))
        context.setLineCap(.round)
        context.addPath(paths.maskContour)
        context.strokePath()

        context.setFillColor(RobberPieceGeometry.pieceColor.cgColor)
        context.addPath(paths.eyes)
        context.fillPath()

        context.setStrokeColor(RobberPieceGeometry.sevenColor.cgColor)
        context.setLineWidth(paths.sevenLineWidth)
        context.setLineCap(.square)
        context.setLineJoin(.miter)
        context.addPath(paths.seven)
        context.strokePath()
        context.restoreGState()
    }
}
