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
                    GameTabletopPortraitCardView(
                        face: .resource(chip.resource),
                        size: GamePhysicalTurnLayout.handCardSize,
                        count: chip.count,
                        isFaded: true,
                        stackDepth: 1
                    )
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(chip.shortLabel), \(chip.count) owned")
                }
            }

            if !ownedDevelopmentCards.isEmpty {
                Button(action: onOpenDevCards) {
                    ownedDevStack
                        .frame(width: 48, height: 54)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(!canOpenDevCards)
                .accessibilityIdentifier("uls.physicalProps.ownedDevCards")
                .accessibilityLabel("Owned Dev Cards")
                .accessibilityHint("Opens your playable Dev Cards")
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
    }

    private var ownedDevStack: some View {
        ZStack {
            ForEach(Array(ownedDevelopmentCards.prefix(2).enumerated()), id: \.offset) { index, card in
                GameTabletopPortraitCardView(
                    face: .ownedDevelopment(card.kind),
                    size: CGSize(width: 35, height: 46),
                    count: card.totalCount,
                    isFaded: false,
                    stackDepth: 1
                )
                .rotationEffect(.degrees(index == 0 ? -7 : 7))
                .offset(x: index == 0 ? -7 : 7, y: index == 0 ? 1 : 0)
            }
        }
    }

    private var devCardSpread: some View {
        HStack(spacing: 8) {
            ForEach(devCardPanel?.cards ?? []) { card in
                if let action = card.actionKind, card.isEnabled {
                    GamePhysicalDevCardPropView(
                        card: card,
                        action: action,
                        onSelect: onSelectDevCard
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .accessibilityIdentifier("uls.physicalProps.devChooser")
        .accessibilityLabel("Playable Dev Cards")
    }

    private var accessibilityValue: String {
        switch content {
        case .hand: return "Hand"
        case .build: return "Build"
        case .devCards: return "Dev Cards"
        }
    }

    private var buildSpread: some View {
        HStack(alignment: .center, spacing: 10) {
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
                    .frame(width: 104)
                    .frame(minHeight: 74)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(buildAccessibilityLabel(item))
                .accessibilityHint("Shows placement targets for \(item.title)")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .accessibilityIdentifier("uls.physicalProps.buildSpread")
    }

    private func costRow(_ cost: ResourceHandV1) -> some View {
        HStack(spacing: 4) {
            ForEach(Self.resources.filter { cost.count(for: $0) > 0 }, id: \.self) { resource in
                HStack(spacing: 1) {
                    Image(resource.tabletopStampAssetName)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 12, height: 12)
                        .foregroundStyle(GamePhysicalTurnPalette.secondaryText)
                        .accessibilityHidden(true)

                    Text("\(cost.count(for: resource))")
                        .font(.caption)
                        .bold()
                        .monospacedDigit()
                        .foregroundStyle(GamePhysicalTurnPalette.secondaryText)
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
}
