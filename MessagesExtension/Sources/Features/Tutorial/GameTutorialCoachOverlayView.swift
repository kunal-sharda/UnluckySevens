import SwiftUI

struct GameTutorialCoachOverlayView: View {
    private struct ResolvedCallout: Identifiable {
        let callout: GameTutorialCallout
        let targetPoint: CGPoint
        let bubbleCenter: CGPoint

        var id: Int { callout.id }
    }

    private let standardBubbleWidth: CGFloat = 178
    private let compactBubbleWidth: CGFloat = 204
    private let tradeBubbleWidth: CGFloat = 196
    private let maritimeBubbleWidth: CGFloat = 252
    private let minimumBubbleHeight: CGFloat = 52
    private let maximumCompactBubbleHeight: CGFloat = 84
    private let edgeInset: CGFloat = 10
    private let topExclusionHeight: CGFloat = 72
    private let shortHostBottomExclusionHeight: CGFloat = 78

    let callouts: [GameTutorialCallout]
    let anchors: [GameTutorialTarget: Anchor<CGRect>]

    var body: some View {
        GeometryReader { proxy in
            let resolvedCallouts = resolveCallouts(in: proxy)

            ZStack {
                ForEach(resolvedCallouts) { resolved in
                    if !isTradeCallout(resolved.callout) {
                        leader(
                            from: resolved.targetPoint,
                            to: leaderEndpoint(
                                from: resolved.targetPoint,
                                bubbleCenter: resolved.bubbleCenter,
                                callout: resolved.callout,
                                availableSize: proxy.size
                            )
                        )
                        targetPin(number: resolved.callout.number)
                            .position(resolved.targetPoint)
                    }
                    calloutBubble(resolved.callout, availableSize: proxy.size)
                        .position(resolved.bubbleCenter)
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func point(in frame: CGRect, at unitPoint: UnitPoint) -> CGPoint {
        CGPoint(
            x: frame.minX + (frame.width * unitPoint.x),
            y: frame.minY + (frame.height * unitPoint.y)
        )
    }

    private func resolveCallouts(in proxy: GeometryProxy) -> [ResolvedCallout] {
        var occupied = [
            CGRect(
                x: 0,
                y: 0,
                width: proxy.size.width,
                height: topExclusionHeight
            ),
        ]
        var resolved: [ResolvedCallout] = []

        for (calloutIndex, callout) in callouts.enumerated() {
            guard let anchor = anchors[callout.target] else { continue }
            let targetFrame = proxy[anchor]
            let targetPoint = point(in: targetFrame, at: callout.targetPoint)
            let placements = orderedPlacements(preferred: callout.placement)
            let baseCandidates = placements.map {
                bubbleCenter(
                    placement: $0,
                    targetFrame: targetFrame,
                    targetPoint: targetPoint,
                    availableSize: proxy.size,
                    callout: callout
                )
            }
            let verticalStep = bubbleSize(for: callout, availableSize: proxy.size).height + 12
            let candidates = baseCandidates.flatMap { center in
                [
                    center,
                    clampedCenter(
                        CGPoint(x: center.x, y: center.y - verticalStep),
                        availableSize: proxy.size,
                        callout: callout
                    ),
                    clampedCenter(
                        CGPoint(x: center.x, y: center.y + verticalStep),
                        availableSize: proxy.size,
                        callout: callout
                    ),
                ]
            }

            let scoredSelection = candidates.enumerated().min { lhs, rhs in
                placementScore(
                    center: lhs.element,
                    preferenceIndex: lhs.offset,
                    targetFrame: targetFrame,
                    occupied: occupied,
                    callout: callout,
                    availableSize: proxy.size
                ) < placementScore(
                    center: rhs.element,
                    preferenceIndex: rhs.offset,
                    targetFrame: targetFrame,
                    occupied: occupied,
                    callout: callout,
                    availableSize: proxy.size
                )
            }?.element ?? candidates[0]
            let selected = compactBoardPairCenter(
                calloutIndex: calloutIndex,
                callout: callout,
                availableSize: proxy.size
            ) ?? scoredSelection

            occupied.append(
                bubbleRect(
                    centeredAt: selected,
                    callout: callout,
                    availableSize: proxy.size
                )
                    .insetBy(dx: -6, dy: -6)
            )
            resolved.append(
                ResolvedCallout(
                    callout: callout,
                    targetPoint: targetPoint,
                    bubbleCenter: selected
                )
            )
        }

        return resolved
    }

    private func orderedPlacements(
        preferred: GameTutorialCallout.Placement
    ) -> [GameTutorialCallout.Placement] {
        let all: [GameTutorialCallout.Placement] = [.above, .below, .leading, .trailing]
        return [preferred] + all.filter { $0 != preferred }
    }

    private func compactBoardPairCenter(
        calloutIndex: Int,
        callout: GameTutorialCallout,
        availableSize: CGSize
    ) -> CGPoint? {
        guard usesCompactBoardPairLayout(availableSize: availableSize) else {
            return nil
        }

        let size = bubbleSize(for: callout, availableSize: availableSize)
        let halfWidth = size.width / 2
        let halfHeight = size.height / 2
        let orderedCallouts = callouts.sorted { lhs, rhs in
            lhs.targetPoint.x < rhs.targetPoint.x
        }
        let slotIndex = orderedCallouts.firstIndex { $0.id == callout.id } ?? calloutIndex
        let x = slotIndex == 0
            ? edgeInset + halfWidth
            : availableSize.width - edgeInset - halfWidth

        return clampedCenter(
            CGPoint(
                x: x,
                y: availableSize.height - shortHostBottomExclusionHeight - halfHeight
            ),
            availableSize: availableSize,
            callout: callout
        )
    }

    private func bubbleCenter(
        placement: GameTutorialCallout.Placement,
        targetFrame: CGRect,
        targetPoint: CGPoint,
        availableSize: CGSize,
        callout: GameTutorialCallout
    ) -> CGPoint {
        let size = bubbleSize(for: callout, availableSize: availableSize)
        let halfWidth = min(size.width, availableSize.width - 28) / 2
        let halfHeight = size.height / 2
        let gap = isTradeCallout(callout) ? 10.0 : 18.0
        let proposed: CGPoint

        switch placement {
        case .above:
            proposed = CGPoint(x: targetPoint.x, y: targetFrame.minY - halfHeight - gap)
        case .below:
            proposed = CGPoint(x: targetPoint.x, y: targetFrame.maxY + halfHeight + gap)
        case .leading:
            proposed = CGPoint(x: targetFrame.minX - halfWidth - gap, y: targetPoint.y)
        case .trailing:
            proposed = CGPoint(x: targetFrame.maxX + halfWidth + gap, y: targetPoint.y)
        }

        return clampedCenter(proposed, availableSize: availableSize, callout: callout)
    }

    private func clampedCenter(
        _ proposed: CGPoint,
        availableSize: CGSize,
        callout: GameTutorialCallout
    ) -> CGPoint {
        let size = bubbleSize(for: callout, availableSize: availableSize)
        let halfWidth = min(size.width, availableSize.width - 28) / 2
        let halfHeight = size.height / 2
        return CGPoint(
            x: min(
                max(proposed.x, halfWidth + edgeInset),
                availableSize.width - halfWidth - edgeInset
            ),
            y: min(
                max(proposed.y, topExclusionHeight + halfHeight + 4),
                availableSize.height - halfHeight - 14
            )
        )
    }

    private func placementScore(
        center: CGPoint,
        preferenceIndex: Int,
        targetFrame: CGRect,
        occupied: [CGRect],
        callout: GameTutorialCallout,
        availableSize: CGSize
    ) -> CGFloat {
        let rect = bubbleRect(
            centeredAt: center,
            callout: callout,
            availableSize: availableSize
        )
        let occupiedOverlap = occupied.reduce(CGFloat.zero) {
            $0 + overlapArea(rect, $1)
        }
        let targetOverlap = overlapArea(rect, targetFrame.insetBy(dx: -6, dy: -6))
        return (occupiedOverlap * 10_000)
            + (targetOverlap * 1_000)
            + CGFloat(preferenceIndex * 10)
    }

    private func overlapArea(_ lhs: CGRect, _ rhs: CGRect) -> CGFloat {
        let intersection = lhs.intersection(rhs)
        guard !intersection.isNull else { return 0 }
        return intersection.width * intersection.height
    }

    private func bubbleRect(
        centeredAt center: CGPoint,
        callout: GameTutorialCallout,
        availableSize: CGSize
    ) -> CGRect {
        let size = bubbleSize(for: callout, availableSize: availableSize)
        return CGRect(
            x: center.x - (size.width / 2),
            y: center.y - (size.height / 2),
            width: size.width,
            height: size.height
        )
    }

    private func leaderEndpoint(
        from start: CGPoint,
        bubbleCenter: CGPoint,
        callout: GameTutorialCallout,
        availableSize: CGSize
    ) -> CGPoint {
        let rect = bubbleRect(
            centeredAt: bubbleCenter,
            callout: callout,
            availableSize: availableSize
        )
            .insetBy(dx: 5, dy: 5)
        let deltaX = start.x - bubbleCenter.x
        let deltaY = start.y - bubbleCenter.y

        if abs(deltaX) > abs(deltaY) {
            return CGPoint(
                x: deltaX < 0 ? rect.minX : rect.maxX,
                y: min(max(start.y, rect.minY), rect.maxY)
            )
        }

        return CGPoint(
            x: min(max(start.x, rect.minX), rect.maxX),
            y: deltaY < 0 ? rect.minY : rect.maxY
        )
    }

    private func leader(from start: CGPoint, to end: CGPoint) -> some View {
        Path { path in
            path.move(to: start)
            path.addLine(to: end)
        }
        .stroke(
            GameTheme.accent,
            style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
        )
        .shadow(color: .black.opacity(0.28), radius: 2, y: 1)
    }

    private func targetPin(number: Int) -> some View {
        Text("\(number)")
            .font(.caption.bold())
            .foregroundStyle(GameTheme.ink)
            .frame(width: 30, height: 30)
            .background(GameTheme.surface, in: Circle())
            .overlay {
                Circle().stroke(GameTheme.accent, lineWidth: 3)
            }
            .shadow(color: .black.opacity(0.25), radius: 3, y: 2)
    }

    @ViewBuilder
    private func calloutBubble(
        _ callout: GameTutorialCallout,
        availableSize: CGSize
    ) -> some View {
        let size = bubbleSize(for: callout, availableSize: availableSize)
        let usesCompactHost = availableSize.width < 560
        Text(callout.text)
            .font(usesCompactHost ? .caption.weight(.semibold) : GameTheme.chipFont)
            .foregroundStyle(GameTheme.ink)
            .multilineTextAlignment(.leading)
            .lineLimit(4)
            .minimumScaleFactor(0.82)
            .frame(width: size.width - 24, alignment: .leading)
            .frame(height: size.height - 14, alignment: .leading)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(GameTheme.surface, in: RoundedRectangle(cornerRadius: 10))
            .overlay {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(GameTheme.accent, lineWidth: 2)
            }
            .shadow(color: .black.opacity(0.22), radius: 5, y: 2)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(callout.text)
            .accessibilityIdentifier("uls.tutorial.callout")
    }

    private func bubbleSize(
        for callout: GameTutorialCallout,
        availableSize: CGSize
    ) -> CGSize {
        let usesTradeLayout = isTradeCallout(callout)
        let usesCompactHost = availableSize.width < 560
        let width: CGFloat
        if usesCompactBoardPairLayout(availableSize: availableSize) {
            width = min(
                compactBubbleWidth,
                (availableSize.width - (edgeInset * 3)) / 2
            )
        } else if callout.target == .maritimeOptions {
            width = maritimeBubbleWidth
        } else {
            width = usesTradeLayout
                ? tradeBubbleWidth
                : (usesCompactHost ? compactBubbleWidth : standardBubbleWidth)
        }
        let estimatedLineCount = wrappedLineCount(
            for: callout.text,
            charactersPerLine: callout.target == .maritimeOptions
                ? 38
                : (usesCompactHost ? 28 : 20)
        )
        let lineHeight = usesCompactHost ? 16.0 : 18.0
        let estimatedTextHeight = CGFloat(estimatedLineCount) * lineHeight
        let estimatedHeight = max(minimumBubbleHeight, estimatedTextHeight + 20)
        return CGSize(
            width: min(width, availableSize.width - 40),
            height: usesCompactHost
                ? min(maximumCompactBubbleHeight, estimatedHeight)
                : estimatedHeight
        )
    }

    private func wrappedLineCount(for text: String, charactersPerLine: Int) -> Int {
        text.split(separator: " ").reduce(into: [0]) { lines, word in
            let requiredCount = word.count + (lines[lines.count - 1] == 0 ? 0 : 1)
            if lines[lines.count - 1] + requiredCount > charactersPerLine {
                lines.append(word.count)
            } else {
                lines[lines.count - 1] += requiredCount
            }
        }.count
    }

    private func isTradeCallout(_ callout: GameTutorialCallout) -> Bool {
        switch callout.target {
        case .tradeGive, .tradeWant, .tradeRecipients, .maritimeOptions:
            return true
        default:
            return false
        }
    }

    private func usesCompactBoardPairLayout(availableSize: CGSize) -> Bool {
        availableSize.width < 560
            && availableSize.height < 760
            && callouts.count == 2
            && callouts.allSatisfy { $0.target == .board }
    }
}
