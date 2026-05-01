import UIKit

@MainActor
enum TranscriptBubbleImageRenderer {
    static let imageSize = GameBoardSnapshotVariant.transcriptPreview.canvasSize

    private static let statusBandHeight: CGFloat = 72

    static func render(visual: TranscriptBubbleVisual) -> UIImage? {
        switch visual {
        case .none:
            return nil
        case .lobbyInvite:
            return renderLobbyInvite()
        case let .board(context):
            return renderBoardBubble(context: context)
        }
    }

    private static func renderBoardBubble(context: TranscriptBoardBubbleVisual) -> UIImage? {
        guard let renderModel = GameBoardRenderModelBuilder.build(state: context.state) else {
            return nil
        }

        let boardSize = CGSize(
            width: imageSize.width,
            height: imageSize.height - statusBandHeight
        )
        guard let boardImage = GameBoardSnapshotRenderer.render(
            renderModel: renderModel,
            referenceSize: boardSize,
            viewportSize: boardSize,
            cameraState: .init()
        ) else {
            return nil
        }

        return imageRenderer().image { _ in
            let canvas = CGRect(origin: .zero, size: imageSize)
            let boardRect = CGRect(origin: .zero, size: boardSize)
            UIColor(red: 0.11, green: 0.20, blue: 0.25, alpha: 1.0).setFill()
            UIRectFill(canvas)
            boardImage.draw(in: boardRect)
            drawBoardStatusBand(
                title: context.title,
                detail: context.detail,
                rect: CGRect(
                    x: 0,
                    y: boardRect.maxY,
                    width: imageSize.width,
                    height: statusBandHeight
                )
            )
        }
    }

    private static func renderLobbyInvite() -> UIImage {
        imageRenderer().image { context in
            let canvas = CGRect(origin: .zero, size: imageSize)
            drawInviteBackground(in: canvas, context: context.cgContext)
            drawInviteIsland()
            drawInviteDice()
            drawInviteAccents()
            drawInviteText()
        }
    }

    private static func drawBoardStatusBand(title: String, detail: String, rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        context?.saveGState()
        UIColor(red: 0.08, green: 0.11, blue: 0.13, alpha: 0.94).setFill()
        UIRectFill(rect)
        UIColor(red: 0.87, green: 0.72, blue: 0.36, alpha: 0.75).setFill()
        UIRectFill(CGRect(x: 0, y: rect.minY, width: rect.width, height: 2))
        context?.restoreGState()

        drawText(
            title,
            in: CGRect(x: 18, y: rect.minY + 10, width: rect.width - 36, height: 26),
            font: .systemFont(ofSize: 21, weight: .bold),
            color: .white
        )
        drawText(
            detail,
            in: CGRect(x: 18, y: rect.minY + 38, width: rect.width - 36, height: 24),
            font: .systemFont(ofSize: 15, weight: .semibold),
            color: UIColor(red: 0.87, green: 0.91, blue: 0.89, alpha: 1.0)
        )
    }

    private static func drawInviteBackground(in rect: CGRect, context: CGContext) {
        let colors = [
            UIColor(red: 0.06, green: 0.16, blue: 0.22, alpha: 1.0).cgColor,
            UIColor(red: 0.13, green: 0.39, blue: 0.46, alpha: 1.0).cgColor,
        ] as CFArray
        let gradient = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: colors,
            locations: [0, 1]
        )
        context.drawLinearGradient(
            gradient!,
            start: CGPoint(x: rect.midX, y: rect.minY),
            end: CGPoint(x: rect.midX, y: rect.maxY),
            options: []
        )

        UIColor(red: 0.95, green: 0.82, blue: 0.43, alpha: 0.14).setFill()
        UIBezierPath(ovalIn: CGRect(x: -54, y: 150, width: 220, height: 94)).fill()
        UIColor(red: 0.80, green: 0.95, blue: 0.98, alpha: 0.10).setFill()
        UIBezierPath(ovalIn: CGRect(x: 192, y: 8, width: 210, height: 120)).fill()
    }

    private static func drawInviteIsland() {
        let centers = [
            CGPoint(x: 224, y: 95),
            CGPoint(x: 264, y: 95),
            CGPoint(x: 244, y: 130),
            CGPoint(x: 204, y: 130),
            CGPoint(x: 284, y: 130),
            CGPoint(x: 224, y: 165),
            CGPoint(x: 264, y: 165),
        ]
        let fills: [UIColor] = [
            UIColor(red: 0.40, green: 0.57, blue: 0.28, alpha: 1.0),
            UIColor(red: 0.82, green: 0.36, blue: 0.25, alpha: 1.0),
            UIColor(red: 0.90, green: 0.73, blue: 0.29, alpha: 1.0),
            UIColor(red: 0.57, green: 0.74, blue: 0.39, alpha: 1.0),
            UIColor(red: 0.49, green: 0.53, blue: 0.57, alpha: 1.0),
            UIColor(red: 0.45, green: 0.62, blue: 0.32, alpha: 1.0),
            UIColor(red: 0.79, green: 0.69, blue: 0.50, alpha: 1.0),
        ]

        let context = UIGraphicsGetCurrentContext()
        context?.saveGState()
        context?.setShadow(offset: CGSize(width: 0, height: 6), blur: 14, color: UIColor.black.withAlphaComponent(0.28).cgColor)
        for (index, center) in centers.enumerated() {
            let path = hexPath(center: center, radius: 24)
            fills[index].setFill()
            path.fill()
            UIColor(red: 0.99, green: 0.94, blue: 0.81, alpha: 0.38).setStroke()
            path.lineWidth = 2
            path.stroke()
        }
        context?.restoreGState()
    }

    private static func drawInviteDice() {
        drawDie(in: CGRect(x: 244, y: 190, width: 42, height: 42), value: 3, rotation: -0.10)
        drawDie(in: CGRect(x: 292, y: 184, width: 42, height: 42), value: 4, rotation: 0.12)
    }

    private static func drawInviteAccents() {
        let colors = [
            UIColor(red: 0.79, green: 0.22, blue: 0.19, alpha: 1.0),
            UIColor(red: 0.18, green: 0.39, blue: 0.78, alpha: 1.0),
            UIColor(red: 0.96, green: 0.95, blue: 0.91, alpha: 1.0),
            UIColor(red: 0.90, green: 0.56, blue: 0.14, alpha: 1.0),
        ]
        for index in colors.indices {
            let rect = CGRect(x: 22 + (CGFloat(index) * 18), y: 23, width: 11, height: 11)
            colors[index].setFill()
            UIBezierPath(ovalIn: rect).fill()
            UIColor.black.withAlphaComponent(0.24).setStroke()
            UIBezierPath(ovalIn: rect).stroke()
        }
    }

    private static func drawInviteText() {
        drawText(
            "Unlucky",
            in: CGRect(x: 22, y: 54, width: 172, height: 44),
            font: .systemFont(ofSize: 38, weight: .heavy),
            color: .white
        )
        drawText(
            "Sevens",
            in: CGRect(x: 22, y: 92, width: 172, height: 44),
            font: .systemFont(ofSize: 38, weight: .heavy),
            color: UIColor(red: 0.96, green: 0.78, blue: 0.34, alpha: 1.0)
        )
        drawText(
            "Tap to join the island.",
            in: CGRect(x: 24, y: 147, width: 170, height: 24),
            font: .systemFont(ofSize: 16, weight: .semibold),
            color: UIColor(red: 0.87, green: 0.94, blue: 0.91, alpha: 1.0)
        )
    }

    private static func drawDie(in rect: CGRect, value: Int, rotation: CGFloat) {
        let context = UIGraphicsGetCurrentContext()
        context?.saveGState()
        context?.translateBy(x: rect.midX, y: rect.midY)
        context?.rotate(by: rotation)
        context?.translateBy(x: -rect.midX, y: -rect.midY)
        context?.setShadow(offset: CGSize(width: 0, height: 4), blur: 8, color: UIColor.black.withAlphaComponent(0.30).cgColor)

        let die = UIBezierPath(roundedRect: rect, cornerRadius: 8)
        UIColor(red: 0.98, green: 0.96, blue: 0.90, alpha: 1.0).setFill()
        die.fill()
        UIColor(red: 0.27, green: 0.19, blue: 0.13, alpha: 0.36).setStroke()
        die.lineWidth = 1.5
        die.stroke()
        context?.restoreGState()

        let pipInset = rect.width * 0.27
        let left = rect.minX + pipInset
        let center = rect.midX
        let right = rect.maxX - pipInset
        let top = rect.minY + pipInset
        let middle = rect.midY
        let bottom = rect.maxY - pipInset

        let pips: [CGPoint]
        switch value {
        case 3:
            pips = [
                CGPoint(x: left, y: top),
                CGPoint(x: center, y: middle),
                CGPoint(x: right, y: bottom),
            ]
        case 4:
            pips = [
                CGPoint(x: left, y: top),
                CGPoint(x: right, y: top),
                CGPoint(x: left, y: bottom),
                CGPoint(x: right, y: bottom),
            ]
        default:
            pips = [CGPoint(x: center, y: middle)]
        }

        context?.saveGState()
        context?.translateBy(x: rect.midX, y: rect.midY)
        context?.rotate(by: rotation)
        context?.translateBy(x: -rect.midX, y: -rect.midY)
        UIColor(red: 0.16, green: 0.12, blue: 0.10, alpha: 1.0).setFill()
        for pip in pips {
            UIBezierPath(ovalIn: CGRect(x: pip.x - 3.2, y: pip.y - 3.2, width: 6.4, height: 6.4)).fill()
        }
        context?.restoreGState()
    }

    private static func drawText(_ text: String, in rect: CGRect, font: UIFont, color: UIColor) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = .byTruncatingTail
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: paragraph,
        ]
        (text as NSString).draw(in: rect, withAttributes: attributes)
    }

    private static func hexPath(center: CGPoint, radius: CGFloat) -> UIBezierPath {
        let path = UIBezierPath()
        for index in 0..<6 {
            let angle = (CGFloat.pi / 6) + (CGFloat(index) * CGFloat.pi / 3)
            let point = CGPoint(
                x: center.x + (cos(angle) * radius),
                y: center.y + (sin(angle) * radius)
            )
            if index == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.close()
        return path
    }

    private static func imageRenderer() -> UIGraphicsImageRenderer {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 2
        format.opaque = true
        return UIGraphicsImageRenderer(size: imageSize, format: format)
    }
}
