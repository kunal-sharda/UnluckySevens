import UIKit

@MainActor
enum TranscriptBubbleImageRenderer {
    static let imageSize = GameBoardSnapshotVariant.transcriptPreview.canvasSize

    static func render(visual: TranscriptBubbleVisual) -> UIImage? {
        switch visual {
        case .none:
            return nil
        case .lobbyInvite:
            return renderLobbyInvite()
        case let .action(visual):
            return renderActionCard(visual)
        }
    }

    private static func renderLobbyInvite() -> UIImage {
        imageRenderer().image { context in
            let canvas = CGRect(origin: .zero, size: imageSize)
            drawGradient(
                in: canvas,
                context: context.cgContext,
                top: Palette.tealNight,
                bottom: Palette.sea
            )
            drawSoftSpotlight()
            drawHexCluster(center: CGPoint(x: 246, y: 128), radius: 25)
            drawDie(in: CGRect(x: 244, y: 186, width: 44, height: 44), value: 3, rotation: -0.10)
            drawDie(in: CGRect(x: 292, y: 180, width: 44, height: 44), value: 4, rotation: 0.12)
            drawPlayerPips(origin: CGPoint(x: 22, y: 22))
            drawText(
                "Unlucky",
                in: CGRect(x: 22, y: 66, width: 172, height: 38),
                font: .systemFont(ofSize: 33, weight: .heavy),
                color: .white
            )
            drawText(
                "Sevens",
                in: CGRect(x: 22, y: 101, width: 172, height: 38),
                font: .systemFont(ofSize: 33, weight: .heavy),
                color: Palette.gold
            )
            drawText(
                "Join",
                in: CGRect(x: 24, y: 148, width: 72, height: 22),
                font: .systemFont(ofSize: 15, weight: .bold),
                color: Palette.paper
            )
        }
    }

    private static func renderActionCard(_ visual: TranscriptActionBubbleVisual) -> UIImage {
        let style = ActionStyle.style(for: visual.kind)
        return imageRenderer().image { context in
            let canvas = CGRect(origin: .zero, size: imageSize)
            drawGradient(in: canvas, context: context.cgContext, top: style.top, bottom: style.bottom)
            drawActionChrome(style: style)
            drawActionSymbol(kind: visual.kind, style: style)
            drawActionLabel(visual.title, style: style)
        }
    }

    private static func drawActionChrome(style: ActionStyle) {
        UIColor.black.withAlphaComponent(0.20).setFill()
        UIBezierPath(roundedRect: CGRect(x: 18, y: 18, width: 324, height: 224), cornerRadius: 14).fill()
        style.surface.setFill()
        UIBezierPath(roundedRect: CGRect(x: 22, y: 22, width: 316, height: 216), cornerRadius: 12).fill()

        style.accent.withAlphaComponent(0.92).setFill()
        UIRectFill(CGRect(x: 22, y: 22, width: 316, height: 5))
        drawSevenBadge(center: CGPoint(x: 306, y: 54), style: style)
    }

    private static func drawActionSymbol(kind: TranscriptActionBubbleKind, style: ActionStyle) {
        switch kind {
        case .gameStarted, .setupComplete:
            drawHexCluster(center: CGPoint(x: 180, y: 126), radius: 30)
            drawPlayerPips(origin: CGPoint(x: 134, y: 184))
        case .setupSettlement, .buildSettlement:
            drawHexCluster(center: CGPoint(x: 178, y: 126), radius: 30, count: 3)
            drawSettlement(center: CGPoint(x: 180, y: 120), size: 76, fill: style.accent)
        case .setupRoad, .buildRoad:
            drawHexCluster(center: CGPoint(x: 180, y: 126), radius: 30, count: 2)
            drawRoad(from: CGPoint(x: 112, y: 144), to: CGPoint(x: 248, y: 104), color: style.accent)
        case let .roll(total):
            let pair = dicePair(total: total)
            drawLargeDice(values: pair, accent: style.accent)
        case .rollSeven:
            drawBurst(center: CGPoint(x: 180, y: 126), color: style.secondary)
            drawLargeDice(values: (3, 4), accent: style.accent)
        case .discard:
            drawResourceChips(center: CGPoint(x: 180, y: 112), style: style)
            drawTray(rect: CGRect(x: 120, y: 150, width: 120, height: 34), color: style.secondary)
        case .robber:
            drawHex(center: CGPoint(x: 180, y: 132), radius: 58, fill: Palette.desert, stroke: style.accent)
            drawRobber(center: CGPoint(x: 180, y: 122), size: 82)
        case .steal:
            drawRobber(center: CGPoint(x: 145, y: 122), size: 70)
            drawResourceChip(center: CGPoint(x: 216, y: 126), radius: 30, color: style.accent)
        case .buildCity:
            drawHexCluster(center: CGPoint(x: 178, y: 126), radius: 30, count: 3)
            drawCity(center: CGPoint(x: 180, y: 118), size: 82, fill: style.accent)
        case .trade:
            drawTradeArrows(style: style)
            drawResourceChip(center: CGPoint(x: 118, y: 118), radius: 25, color: Palette.brick)
            drawResourceChip(center: CGPoint(x: 242, y: 136), radius: 25, color: Palette.wheat)
        case .maritimeTrade:
            drawShip(center: CGPoint(x: 180, y: 132), style: style)
            drawResourceChip(center: CGPoint(x: 112, y: 118), radius: 22, color: Palette.wood)
            drawResourceChip(center: CGPoint(x: 250, y: 116), radius: 22, color: Palette.ore)
        case .devCard:
            drawDevCard(center: CGPoint(x: 180, y: 124), style: style)
        case .endTurn:
            drawTurnArrow(style: style)
            drawPlayerPips(origin: CGPoint(x: 151, y: 118), size: 28, spacing: 34)
        case .gameOver:
            drawTrophy(center: CGPoint(x: 180, y: 126), style: style)
        }
    }

    private static func drawActionLabel(_ title: String, style: ActionStyle) {
        let shortTitle = conciseTitle(title)
        drawText(
            shortTitle.uppercased(),
            in: CGRect(x: 38, y: 202, width: 230, height: 22),
            font: .systemFont(ofSize: 14, weight: .black),
            color: style.label
        )
    }

    private static func drawLargeDice(values: (Int, Int), accent: UIColor) {
        drawDie(in: CGRect(x: 112, y: 86, width: 62, height: 62), value: values.0, rotation: -0.08)
        drawDie(in: CGRect(x: 186, y: 94, width: 62, height: 62), value: values.1, rotation: 0.10)
        accent.withAlphaComponent(0.24).setFill()
        UIBezierPath(ovalIn: CGRect(x: 102, y: 168, width: 156, height: 18)).fill()
    }

    private static func drawTradeArrows(style: ActionStyle) {
        drawArrow(
            from: CGPoint(x: 126, y: 100),
            to: CGPoint(x: 236, y: 100),
            color: style.accent,
            width: 8
        )
        drawArrow(
            from: CGPoint(x: 234, y: 148),
            to: CGPoint(x: 124, y: 148),
            color: style.secondary,
            width: 8
        )
    }

    private static func drawTurnArrow(style: ActionStyle) {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 106, y: 138))
        path.addCurve(
            to: CGPoint(x: 254, y: 134),
            controlPoint1: CGPoint(x: 132, y: 64),
            controlPoint2: CGPoint(x: 228, y: 66)
        )
        style.accent.setStroke()
        path.lineWidth = 11
        path.lineCapStyle = .round
        path.stroke()
        drawArrowHead(at: CGPoint(x: 254, y: 134), angle: 0.68, color: style.accent, size: 18)
    }

    private static func drawShip(center: CGPoint, style: ActionStyle) {
        let hull = UIBezierPath()
        hull.move(to: CGPoint(x: center.x - 62, y: center.y + 24))
        hull.addLine(to: CGPoint(x: center.x + 62, y: center.y + 24))
        hull.addLine(to: CGPoint(x: center.x + 38, y: center.y + 52))
        hull.addLine(to: CGPoint(x: center.x - 42, y: center.y + 52))
        hull.close()
        style.accent.setFill()
        hull.fill()

        style.secondary.setFill()
        let sail = UIBezierPath()
        sail.move(to: CGPoint(x: center.x - 8, y: center.y + 14))
        sail.addLine(to: CGPoint(x: center.x - 8, y: center.y - 56))
        sail.addLine(to: CGPoint(x: center.x + 42, y: center.y + 12))
        sail.close()
        sail.fill()

        UIColor.white.withAlphaComponent(0.18).setStroke()
        drawWave(y: center.y + 62)
    }

    private static func drawDevCard(center: CGPoint, style: ActionStyle) {
        let card = CGRect(x: center.x - 44, y: center.y - 58, width: 88, height: 116)
        UIColor.black.withAlphaComponent(0.25).setFill()
        UIBezierPath(roundedRect: card.offsetBy(dx: 8, dy: 8), cornerRadius: 12).fill()
        style.accent.setFill()
        UIBezierPath(roundedRect: card, cornerRadius: 12).fill()
        style.surface.setFill()
        UIBezierPath(roundedRect: card.insetBy(dx: 10, dy: 10), cornerRadius: 8).fill()
        style.secondary.setFill()
        UIBezierPath(ovalIn: CGRect(x: center.x - 22, y: center.y - 22, width: 44, height: 44)).fill()
        drawText(
            "7",
            in: CGRect(x: center.x - 12, y: center.y - 19, width: 24, height: 34),
            font: .systemFont(ofSize: 30, weight: .black),
            color: .white
        )
    }

    private static func drawTrophy(center: CGPoint, style: ActionStyle) {
        style.accent.setFill()
        let cup = UIBezierPath(roundedRect: CGRect(x: center.x - 38, y: center.y - 42, width: 76, height: 64), cornerRadius: 18)
        cup.fill()
        UIBezierPath(roundedRect: CGRect(x: center.x - 12, y: center.y + 20, width: 24, height: 34), cornerRadius: 4).fill()
        UIBezierPath(roundedRect: CGRect(x: center.x - 42, y: center.y + 52, width: 84, height: 13), cornerRadius: 6).fill()

        style.secondary.setStroke()
        let left = UIBezierPath(arcCenter: CGPoint(x: center.x - 38, y: center.y - 12), radius: 28, startAngle: 1.0, endAngle: 4.9, clockwise: true)
        left.lineWidth = 8
        left.stroke()
        let right = UIBezierPath(arcCenter: CGPoint(x: center.x + 38, y: center.y - 12), radius: 28, startAngle: 4.5, endAngle: 2.1, clockwise: true)
        right.lineWidth = 8
        right.stroke()
    }

    private static func drawRobber(center: CGPoint, size: CGFloat) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        RobberPieceDrawing.draw(center: center, height: size, in: context)
    }

    private static func drawSettlement(center: CGPoint, size: CGFloat, fill: UIColor) {
        fill.setFill()
        let house = UIBezierPath()
        house.move(to: CGPoint(x: center.x, y: center.y - size * 0.48))
        house.addLine(to: CGPoint(x: center.x + size * 0.46, y: center.y - size * 0.08))
        house.addLine(to: CGPoint(x: center.x + size * 0.33, y: center.y + size * 0.42))
        house.addLine(to: CGPoint(x: center.x - size * 0.33, y: center.y + size * 0.42))
        house.addLine(to: CGPoint(x: center.x - size * 0.46, y: center.y - size * 0.08))
        house.close()
        house.fill()
        Palette.ink.withAlphaComponent(0.28).setStroke()
        house.lineWidth = 3
        house.stroke()
    }

    private static func drawCity(center: CGPoint, size: CGFloat, fill: UIColor) {
        fill.setFill()
        let base = CGRect(x: center.x - size * 0.44, y: center.y - size * 0.14, width: size * 0.88, height: size * 0.54)
        UIBezierPath(roundedRect: base, cornerRadius: 7).fill()
        UIBezierPath(roundedRect: CGRect(x: center.x - size * 0.18, y: center.y - size * 0.52, width: size * 0.36, height: size * 0.44), cornerRadius: 7).fill()
        Palette.ink.withAlphaComponent(0.28).setStroke()
        UIBezierPath(roundedRect: base, cornerRadius: 7).stroke()
    }

    private static func drawRoad(from start: CGPoint, to end: CGPoint, color: UIColor) {
        UIColor.black.withAlphaComponent(0.22).setStroke()
        let shadow = UIBezierPath()
        shadow.move(to: start)
        shadow.addLine(to: end)
        shadow.lineWidth = 24
        shadow.lineCapStyle = .round
        shadow.stroke()

        color.setStroke()
        let path = UIBezierPath()
        path.move(to: start)
        path.addLine(to: end)
        path.lineWidth = 16
        path.lineCapStyle = .round
        path.stroke()
    }

    private static func drawResourceChips(center: CGPoint, style: ActionStyle) {
        let chips = [
            (CGPoint(x: center.x - 48, y: center.y + 10), Palette.wood),
            (CGPoint(x: center.x - 18, y: center.y - 16), Palette.brick),
            (CGPoint(x: center.x + 18, y: center.y - 14), Palette.wheat),
            (CGPoint(x: center.x + 50, y: center.y + 10), Palette.ore),
        ]
        for chip in chips {
            drawResourceChip(center: chip.0, radius: 23, color: chip.1)
        }
        drawResourceChip(center: center, radius: 26, color: style.accent)
    }

    private static func drawResourceChip(center: CGPoint, radius: CGFloat, color: UIColor) {
        UIColor.black.withAlphaComponent(0.20).setFill()
        UIBezierPath(ovalIn: CGRect(x: center.x - radius + 4, y: center.y - radius + 5, width: radius * 2, height: radius * 2)).fill()
        color.setFill()
        UIBezierPath(ovalIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)).fill()
        UIColor.white.withAlphaComponent(0.24).setStroke()
        UIBezierPath(ovalIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)).stroke()
    }

    private static func drawTray(rect: CGRect, color: UIColor) {
        color.setFill()
        UIBezierPath(roundedRect: rect, cornerRadius: 10).fill()
        Palette.ink.withAlphaComponent(0.30).setStroke()
        UIBezierPath(roundedRect: rect, cornerRadius: 10).stroke()
    }

    private static func drawHexCluster(center: CGPoint, radius: CGFloat, count: Int = 7) {
        let offsets = [
            CGPoint(x: 0, y: 0),
            CGPoint(x: radius * 1.52, y: 0),
            CGPoint(x: -radius * 1.52, y: 0),
            CGPoint(x: radius * 0.76, y: radius * 1.30),
            CGPoint(x: -radius * 0.76, y: radius * 1.30),
            CGPoint(x: radius * 0.76, y: -radius * 1.30),
            CGPoint(x: -radius * 0.76, y: -radius * 1.30),
        ]
        let fills = [Palette.wood, Palette.brick, Palette.wheat, Palette.sheep, Palette.ore, Palette.desert, Palette.wood]

        let context = UIGraphicsGetCurrentContext()
        context?.saveGState()
        context?.setShadow(offset: CGSize(width: 0, height: 7), blur: 12, color: UIColor.black.withAlphaComponent(0.25).cgColor)
        for index in 0..<min(count, offsets.count) {
            let hexCenter = CGPoint(x: center.x + offsets[index].x, y: center.y + offsets[index].y)
            drawHex(center: hexCenter, radius: radius, fill: fills[index], stroke: Palette.paper.withAlphaComponent(0.34))
        }
        context?.restoreGState()
    }

    private static func drawHex(center: CGPoint, radius: CGFloat, fill: UIColor, stroke: UIColor) {
        let path = hexPath(center: center, radius: radius)
        fill.setFill()
        path.fill()
        stroke.setStroke()
        path.lineWidth = 2
        path.stroke()
    }

    private static func drawPlayerPips(origin: CGPoint, size: CGFloat = 12, spacing: CGFloat = 18) {
        let colors = [Palette.redPlayer, Palette.bluePlayer, Palette.whitePlayer, Palette.orangePlayer]
        for index in colors.indices {
            let rect = CGRect(
                x: origin.x + CGFloat(index) * spacing,
                y: origin.y,
                width: size,
                height: size
            )
            colors[index].setFill()
            UIBezierPath(ovalIn: rect).fill()
            UIColor.black.withAlphaComponent(0.24).setStroke()
            UIBezierPath(ovalIn: rect).stroke()
        }
    }

    private static func drawSevenBadge(center: CGPoint, style: ActionStyle) {
        style.accent.setFill()
        UIBezierPath(ovalIn: CGRect(x: center.x - 23, y: center.y - 23, width: 46, height: 46)).fill()
        drawText(
            "7",
            in: CGRect(x: center.x - 11, y: center.y - 17, width: 22, height: 34),
            font: .systemFont(ofSize: 30, weight: .black),
            color: style.badgeText
        )
    }

    private static func drawSoftSpotlight() {
        Palette.gold.withAlphaComponent(0.10).setFill()
        UIBezierPath(ovalIn: CGRect(x: -56, y: 152, width: 220, height: 92)).fill()
        UIColor.white.withAlphaComponent(0.08).setFill()
        UIBezierPath(ovalIn: CGRect(x: 192, y: 6, width: 208, height: 118)).fill()
    }

    private static func drawBurst(center: CGPoint, color: UIColor) {
        color.withAlphaComponent(0.18).setStroke()
        for index in 0..<10 {
            let angle = CGFloat(index) * (.pi * 2 / 10)
            let start = CGPoint(x: center.x + cos(angle) * 58, y: center.y + sin(angle) * 58)
            let end = CGPoint(x: center.x + cos(angle) * 82, y: center.y + sin(angle) * 82)
            let path = UIBezierPath()
            path.move(to: start)
            path.addLine(to: end)
            path.lineWidth = 5
            path.lineCapStyle = .round
            path.stroke()
        }
    }

    private static func drawArrow(from start: CGPoint, to end: CGPoint, color: UIColor, width: CGFloat) {
        color.setStroke()
        let path = UIBezierPath()
        path.move(to: start)
        path.addLine(to: end)
        path.lineWidth = width
        path.lineCapStyle = .round
        path.stroke()
        let angle = atan2(end.y - start.y, end.x - start.x)
        drawArrowHead(at: end, angle: angle, color: color, size: width * 1.7)
    }

    private static func drawArrowHead(at point: CGPoint, angle: CGFloat, color: UIColor, size: CGFloat) {
        color.setFill()
        let path = UIBezierPath()
        path.move(to: point)
        path.addLine(to: CGPoint(x: point.x - cos(angle - 0.55) * size, y: point.y - sin(angle - 0.55) * size))
        path.addLine(to: CGPoint(x: point.x - cos(angle + 0.55) * size, y: point.y - sin(angle + 0.55) * size))
        path.close()
        path.fill()
    }

    private static func drawWave(y: CGFloat) {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 86, y: y))
        path.addCurve(to: CGPoint(x: 166, y: y), controlPoint1: CGPoint(x: 112, y: y + 14), controlPoint2: CGPoint(x: 140, y: y - 14))
        path.addCurve(to: CGPoint(x: 246, y: y), controlPoint1: CGPoint(x: 192, y: y + 14), controlPoint2: CGPoint(x: 220, y: y - 14))
        path.lineWidth = 4
        path.lineCapStyle = .round
        path.stroke()
    }

    private static func drawDie(in rect: CGRect, value: Int, rotation: CGFloat) {
        let context = UIGraphicsGetCurrentContext()
        context?.saveGState()
        context?.translateBy(x: rect.midX, y: rect.midY)
        context?.rotate(by: rotation)
        context?.translateBy(x: -rect.midX, y: -rect.midY)
        context?.setShadow(
            offset: CGSize(width: 0, height: 5),
            blur: 9,
            color: UIColor.black.withAlphaComponent(0.30).cgColor
        )

        let die = UIBezierPath(roundedRect: rect, cornerRadius: 10)
        Palette.paper.setFill()
        die.fill()
        Palette.ink.withAlphaComponent(0.28).setStroke()
        die.lineWidth = 1.5
        die.stroke()
        context?.restoreGState()

        context?.saveGState()
        context?.translateBy(x: rect.midX, y: rect.midY)
        context?.rotate(by: rotation)
        context?.translateBy(x: -rect.midX, y: -rect.midY)
        Palette.ink.setFill()
        for pip in pipPositions(value: value, rect: rect) {
            UIBezierPath(ovalIn: CGRect(x: pip.x - 3.6, y: pip.y - 3.6, width: 7.2, height: 7.2)).fill()
        }
        context?.restoreGState()
    }

    private static func pipPositions(value: Int, rect: CGRect) -> [CGPoint] {
        let inset = rect.width * 0.27
        let left = rect.minX + inset
        let center = rect.midX
        let right = rect.maxX - inset
        let top = rect.minY + inset
        let middle = rect.midY
        let bottom = rect.maxY - inset

        switch value {
        case 1:
            return [CGPoint(x: center, y: middle)]
        case 2:
            return [CGPoint(x: left, y: top), CGPoint(x: right, y: bottom)]
        case 3:
            return [CGPoint(x: left, y: top), CGPoint(x: center, y: middle), CGPoint(x: right, y: bottom)]
        case 4:
            return [
                CGPoint(x: left, y: top),
                CGPoint(x: right, y: top),
                CGPoint(x: left, y: bottom),
                CGPoint(x: right, y: bottom),
            ]
        case 5:
            return [
                CGPoint(x: left, y: top),
                CGPoint(x: right, y: top),
                CGPoint(x: center, y: middle),
                CGPoint(x: left, y: bottom),
                CGPoint(x: right, y: bottom),
            ]
        default:
            return [
                CGPoint(x: left, y: top),
                CGPoint(x: right, y: top),
                CGPoint(x: left, y: middle),
                CGPoint(x: right, y: middle),
                CGPoint(x: left, y: bottom),
                CGPoint(x: right, y: bottom),
            ]
        }
    }

    private static func dicePair(total: Int?) -> (Int, Int) {
        guard let total else {
            return (2, 5)
        }
        let first = min(max(total / 2, 1), 6)
        let second = min(max(total - first, 1), 6)
        return (first, second)
    }

    private static func conciseTitle(_ title: String) -> String {
        switch title {
        case "Game Started":
            return "Start"
        case "Setup Complete":
            return "Setup Done"
        case "Settlement Placed", "Settlement Built":
            return "Settlement"
        case "Road Placed", "Road Built":
            return "Road"
        case "City Built":
            return "City"
        case "Discard Submitted":
            return "Discard"
        case "Robber Moved":
            return "Robber"
        case "Card Stolen":
            return "Steal"
        case "Trade Offered", "Trade Accepted", "Trade Declined", "Counteroffer Sent":
            return "Trade"
        case "Maritime Trade":
            return "Port Trade"
        case "Dev Card Bought":
            return "Dev Card"
        case "Turn Ended":
            return "End Turn"
        default:
            return title
        }
    }

    private static func drawGradient(
        in rect: CGRect,
        context: CGContext,
        top: UIColor,
        bottom: UIColor
    ) {
        let colors = [top.cgColor, bottom.cgColor] as CFArray
        guard let gradient = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: colors,
            locations: [0, 1]
        ) else {
            top.setFill()
            UIRectFill(rect)
            return
        }

        context.drawLinearGradient(
            gradient,
            start: CGPoint(x: rect.midX, y: rect.minY),
            end: CGPoint(x: rect.midX, y: rect.maxY),
            options: []
        )
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
                x: center.x + cos(angle) * radius,
                y: center.y + sin(angle) * radius
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

private struct ActionStyle {
    let top: UIColor
    let bottom: UIColor
    let surface: UIColor
    let accent: UIColor
    let secondary: UIColor
    let label: UIColor
    let badgeText: UIColor

    static func style(for kind: TranscriptActionBubbleKind) -> ActionStyle {
        switch kind {
        case .gameStarted, .setupComplete:
            return base(top: Palette.tealNight, bottom: Palette.sea, accent: Palette.gold)
        case .setupSettlement, .setupRoad, .buildRoad, .buildSettlement, .buildCity:
            return base(top: Palette.forest, bottom: Palette.table, accent: Palette.gold)
        case let .roll(total):
            let accent = total == 7 ? Palette.hotRed : Palette.gold
            return base(top: Palette.ink, bottom: Palette.sea, accent: accent, secondary: Palette.bluePlayer)
        case .rollSeven:
            return base(top: Palette.ink, bottom: Palette.hotRed, accent: Palette.gold, secondary: Palette.hotRed)
        case .discard:
            return base(top: Palette.table, bottom: Palette.ink, accent: Palette.wheat, secondary: Palette.brick)
        case .robber, .steal:
            return base(top: Palette.ink, bottom: Palette.table, accent: Palette.desert, secondary: Palette.hotRed)
        case .trade, .maritimeTrade:
            return base(top: Palette.sea, bottom: Palette.tealNight, accent: Palette.gold, secondary: Palette.sheep)
        case .devCard:
            return base(top: Palette.plum, bottom: Palette.ink, accent: Palette.gold, secondary: Palette.hotRed)
        case .endTurn:
            return base(top: Palette.bluePlayer, bottom: Palette.tealNight, accent: Palette.orangePlayer)
        case .gameOver:
            return base(top: Palette.ink, bottom: Palette.table, accent: Palette.gold, secondary: Palette.paper)
        }
    }

    private static func base(
        top: UIColor,
        bottom: UIColor,
        accent: UIColor,
        secondary: UIColor = Palette.paper
    ) -> ActionStyle {
        ActionStyle(
            top: top,
            bottom: bottom,
            surface: UIColor(red: 0.06, green: 0.09, blue: 0.10, alpha: 0.78),
            accent: accent,
            secondary: secondary,
            label: Palette.paper,
            badgeText: Palette.ink
        )
    }
}

private enum Palette {
    static let ink = UIColor(red: 0.08, green: 0.10, blue: 0.10, alpha: 1.0)
    static let tealNight = UIColor(red: 0.06, green: 0.16, blue: 0.20, alpha: 1.0)
    static let sea = UIColor(red: 0.12, green: 0.40, blue: 0.46, alpha: 1.0)
    static let table = UIColor(red: 0.35, green: 0.22, blue: 0.13, alpha: 1.0)
    static let forest = UIColor(red: 0.18, green: 0.33, blue: 0.20, alpha: 1.0)
    static let plum = UIColor(red: 0.28, green: 0.13, blue: 0.22, alpha: 1.0)
    static let gold = UIColor(red: 0.96, green: 0.76, blue: 0.31, alpha: 1.0)
    static let paper = UIColor(red: 0.96, green: 0.93, blue: 0.84, alpha: 1.0)
    static let hotRed = UIColor(red: 0.72, green: 0.19, blue: 0.17, alpha: 1.0)
    static let wood = UIColor(red: 0.40, green: 0.57, blue: 0.28, alpha: 1.0)
    static let brick = UIColor(red: 0.78, green: 0.34, blue: 0.24, alpha: 1.0)
    static let wheat = UIColor(red: 0.88, green: 0.70, blue: 0.28, alpha: 1.0)
    static let sheep = UIColor(red: 0.56, green: 0.74, blue: 0.40, alpha: 1.0)
    static let ore = UIColor(red: 0.47, green: 0.52, blue: 0.56, alpha: 1.0)
    static let desert = UIColor(red: 0.78, green: 0.66, blue: 0.46, alpha: 1.0)
    static let redPlayer = UIColor(red: 0.79, green: 0.22, blue: 0.19, alpha: 1.0)
    static let bluePlayer = UIColor(red: 0.18, green: 0.39, blue: 0.78, alpha: 1.0)
    static let whitePlayer = UIColor(red: 0.96, green: 0.95, blue: 0.91, alpha: 1.0)
    static let orangePlayer = UIColor(red: 0.90, green: 0.56, blue: 0.14, alpha: 1.0)
}
