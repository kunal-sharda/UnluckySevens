import SwiftUI
import ULS_CoreGame

struct GamePhysicalTurnActionSpreadView: View {
    enum Content {
        case hand
        case build
        case devCards
    }

    private static let resources: [ResourceV1] = [.wood, .brick, .sheep, .wheat, .ore]

    let content: Content
    let hand: GameHandTrayModel
    let ownedDevelopmentCards: [GameOwnedDevCardSummary]
    let buildItems: [GameBuildShelfItem]
    let devCardPanel: GameDevCardPanelModel?
    let canOpenDevCards: Bool
    let playerColor: Color
    let onSelectBuild: (GameBuildShelfItem.Kind) -> Void
    let onOpenDevCards: () -> Void
    let onSelectDevCard: (GameDevCardActionKind) -> Void

    var body: some View {
        Group {
            switch content {
            case .hand:
                handSpread
            case .build:
                buildSpread
            case .devCards:
                devCardSpread
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("uls.physicalProps.actionSpread")
        .accessibilityLabel("Turn action spread")
        .accessibilityValue(accessibilityValue)
    }

    private var handSpread: some View {
        HStack(spacing: 12) {
            HStack(spacing: 6) {
                ForEach(hand.chips) { chip in
                    ZStack {
                        GamePhysicalResourceHandCardView(chip: chip, isFaded: true)
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(chip.shortLabel), \(chip.count) owned")
                    .accessibilityIdentifier(
                        "uls.physicalProps.handCard.\(chip.resource.rawValue)"
                    )
                }
            }

            if !ownedDevelopmentCards.isEmpty {
                Button(action: onOpenDevCards) {
                    ownedDevStack
                        .frame(width: 58, height: 54)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(!canOpenDevCards)
                .accessibilityIdentifier("uls.physicalProps.ownedDevCards")
                .accessibilityLabel("Owned Dev Cards")
                .accessibilityValue(ownedDevAccessibilityValue)
                .accessibilityHint(
                    canOpenDevCards
                        ? "Opens your playable Dev Cards"
                        : "No owned Dev Cards are playable now"
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, 8)
        .offset(y: GamePhysicalTurnLayout.centeredHandOffset)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(
            ownedDevelopmentCards.isEmpty
                ? "Resource hand"
                : "Resource hand with owned Dev Cards."
        )
        .accessibilityIdentifier("uls.physicalProps.handSpread")
        .gameTutorialTarget(.handSpread)
    }

    private var ownedDevStack: some View {
        ZStack {
            if let first = ownedDevelopmentCards.first {
                GameTabletopPortraitCardView(
                    face: .ownedDevelopment(first.kind),
                    size: CGSize(width: 35, height: 46),
                    isFaded: false,
                    stackDepth: 1
                )
                .rotationEffect(.degrees(-8))
                .offset(x: -7, y: 1)
            }

            if let second = ownedDevelopmentCards.dropFirst().first ?? ownedDevelopmentCards.first {
                GameTabletopPortraitCardView(
                    face: .ownedDevelopment(second.kind),
                    size: CGSize(width: 35, height: 46),
                    count: ownedDevelopmentCards.reduce(0) { $0 + $1.totalCount },
                    isFaded: false,
                    stackDepth: 1
                )
                .rotationEffect(.degrees(8))
                .offset(x: 7)
            }

            if ownedNewCount > 0 {
                Text("New")
                    .font(.caption2)
                    .bold()
                    .foregroundStyle(GamePhysicalTurnPalette.publicPileRevealInk)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(
                        Capsule()
                            .fill(GamePhysicalTurnPalette.devCardEdge.opacity(0.94))
                    )
                    .offset(x: 16, y: 20)
            }
        }
    }

    private var ownedNewCount: Int {
        ownedDevelopmentCards.reduce(0) { $0 + $1.newCount }
    }

    private var ownedDevAccessibilityValue: String {
        ownedDevelopmentCards.map { card in
            var parts = ["\(card.kind.title): \(card.totalCount) owned"]
            if card.playableCount > 0 {
                parts.append("\(card.playableCount) playable")
            }
            if card.newCount > 0 {
                parts.append("\(card.newCount) new")
            }
            return parts.joined(separator: ", ")
        }
        .joined(separator: ". ")
    }

    private var devCardSpread: some View {
        HStack(spacing: 4) {
            ForEach(devCardPanel?.cards ?? []) { card in
                GamePhysicalDevCardPropView(
                    card: card,
                    action: card.isEnabled ? card.actionKind : nil,
                    onSelect: onSelectDevCard
                )
            }
        }
        .padding(.vertical, 2)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .accessibilityIdentifier("uls.physicalProps.devChooser")
        .accessibilityLabel("Playable Dev Cards")
        .gameTutorialTarget(.devChooser)
    }

    private var accessibilityValue: String {
        switch content {
        case .hand: return "Hand"
        case .build: return "Build"
        case .devCards: return "Dev Cards"
        }
    }

    private var buildSpread: some View {
        HStack(alignment: .center, spacing: 6) {
            ForEach(buildItems) { item in
                Button {
                    onSelectBuild(item.kind)
                } label: {
                    VStack(spacing: 2) {
                        GameTabletopPiecePropView(
                            kind: pieceKind(for: item.kind),
                            color: playerColor,
                            isSelected: false
                        )
                        .frame(width: pieceWidth(for: item.kind), height: 38)
                        .offset(y: pieceVerticalOffset(for: item.kind))
                        .frame(height: 40, alignment: .center)

                        Text(item.title)
                            .font(.caption)
                            .bold()
                            .foregroundStyle(GamePhysicalTurnPalette.primaryText)
                            .lineLimit(1)
                            .frame(height: 16)

                        costRow(item.cost)
                            .frame(height: 16)
                    }
                    .frame(width: 76)
                    .frame(minHeight: 74)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("uls.physicalProps.build.\(item.kind.rawValue)")
                .accessibilityLabel(buildAccessibilityLabel(item))
                .accessibilityHint("Shows placement targets for \(item.title)")
                .gameTutorialTarget(tutorialTarget(for: item.kind))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .accessibilityIdentifier("uls.physicalProps.buildSpread")
    }

    private func costRow(_ cost: ResourceHandV1) -> some View {
        let visibleResources = Self.resources.filter { cost.count(for: $0) > 0 }
        let usesCompactPips = visibleResources.count == 4

        return HStack(spacing: 2) {
            ForEach(visibleResources, id: \.self) { resource in
                HStack(spacing: usesCompactPips ? 1 : 1.5) {
                    ZStack {
                        Circle()
                            .fill(resource.tabletopCardFill.opacity(0.92))

                        Circle()
                            .stroke(resource.tabletopEdge.opacity(0.90), lineWidth: 0.8)

                        GameTabletopResourceStampView(
                            resource: resource,
                            size: CGSize(
                                width: usesCompactPips ? 9 : 10,
                                height: usesCompactPips ? 9 : 10
                            ),
                            usesMiniatureAsset: true
                        )
                    }
                    .frame(
                        width: usesCompactPips ? 14 : 16,
                        height: usesCompactPips ? 14 : 16
                    )
                    .accessibilityHidden(true)

                    Text("\(cost.count(for: resource))")
                        .font(.caption.weight(.heavy))
                        .monospacedDigit()
                        .foregroundStyle(GamePhysicalTurnPalette.primaryText)
                }
            }
        }
    }

    private func pieceKind(
        for kind: GameBuildShelfItem.Kind
    ) -> GameTabletopPiecePropView.Kind {
        switch kind {
        case .buildRoad: return .road
        case .buildSettlement: return .settlement
        case .buildCity: return .city
        }
    }

    private func pieceWidth(for kind: GameBuildShelfItem.Kind) -> CGFloat {
        switch kind {
        case .buildRoad: return 50
        case .buildSettlement: return 46
        case .buildCity: return 54
        }
    }

    private func pieceVerticalOffset(for kind: GameBuildShelfItem.Kind) -> CGFloat {
        kind == .buildCity ? -3 : 0
    }

    private func buildAccessibilityLabel(_ item: GameBuildShelfItem) -> String {
        let cost = Self.resources
            .filter { item.cost.count(for: $0) > 0 }
            .map { "\($0.shortLabel) \(item.cost.count(for: $0))" }
            .joined(separator: ", ")
        return "\(item.title), costs \(cost)"
    }

    private func tutorialTarget(
        for kind: GameBuildShelfItem.Kind
    ) -> GameTutorialTarget {
        switch kind {
        case .buildRoad: .buildRoad
        case .buildSettlement: .buildSettlement
        case .buildCity: .buildCity
        }
    }
}
