import SwiftUI
import ULS_CoreGame

enum ResourceChipLayoutMetrics {
    static func columns(for density: ResourceChipDensity) -> [GridItem] {
        Array(
            repeating: GridItem(.flexible(minimum: 0), spacing: density.gridSpacing),
            count: 5
        )
    }
}

enum ResourceChipDensity {
    case regular
    case compact
    case tight

    static func resolve(
        availableWidth: CGFloat,
        availableHeight: CGFloat
    ) -> ResourceChipDensity {
        if availableWidth < 340 || availableHeight < 74 {
            return .tight
        }
        if availableWidth < 400 || availableHeight < 96 {
            return .compact
        }
        return .regular
    }

    var containerPadding: CGFloat {
        switch self {
        case .regular:
            12
        case .compact:
            10
        case .tight:
            8
        }
    }

    var gridSpacing: CGFloat {
        switch self {
        case .regular:
            GameTheme.chipSpacing
        case .compact:
            5
        case .tight:
            4
        }
    }

    var contentSpacing: CGFloat {
        switch self {
        case .regular:
            4
        case .compact:
            3
        case .tight:
            2
        }
    }

    var chipMinHeight: CGFloat {
        switch self {
        case .regular:
            52
        case .compact:
            42
        case .tight:
            34
        }
    }

    var chipHorizontalPadding: CGFloat {
        switch self {
        case .regular:
            8
        case .compact:
            6
        case .tight:
            5
        }
    }

    var chipVerticalPadding: CGFloat {
        switch self {
        case .regular:
            6
        case .compact:
            5
        case .tight:
            4
        }
    }

    var labelFont: Font {
        switch self {
        case .regular:
            return GameTheme.chipFont
        case .compact:
            return .system(size: 12, weight: .bold, design: .rounded)
        case .tight:
            return .system(size: 11, weight: .bold, design: .rounded)
        }
    }

    var countFont: Font {
        switch self {
        case .regular:
            return GameTheme.headingFont
        case .compact:
            return .system(size: 15, weight: .bold, design: .rounded)
        case .tight:
            return .system(size: 14, weight: .bold, design: .rounded)
        }
    }

    var badgeFont: Font {
        switch self {
        case .regular:
            return .system(size: 10, weight: .bold, design: .rounded)
        case .compact, .tight:
            return .system(size: 9, weight: .bold, design: .rounded)
        }
    }

    var tradeRowHeight: CGFloat {
        switch self {
        case .regular:
            44
        case .compact:
            40
        case .tight:
            34
        }
    }

    var stackSpacing: CGFloat {
        switch self {
        case .regular:
            GameTheme.inlineSpacing
        case .compact:
            6
        case .tight:
            5
        }
    }
}

struct ResourceChipGridView<Item: Identifiable, Content: View>: View {
    let items: [Item]
    let density: ResourceChipDensity
    let content: (Item) -> Content

    var body: some View {
        LazyVGrid(
            columns: ResourceChipLayoutMetrics.columns(for: density),
            spacing: density.gridSpacing
        ) {
            ForEach(items) { item in
                content(item)
            }
        }
    }
}

struct ResourceCountChipView: View {
    let resource: ResourceV1
    let label: String
    let count: Int
    let isEnabled: Bool
    let isSelected: Bool
    let selectionBadge: String?
    let detailBadge: String?
    let density: ResourceChipDensity
    let action: (() -> Void)?
    let accessibilityLabel: String

    var body: some View {
        Group {
            if let action {
                Button(action: action) {
                    chipBody
                }
                .buttonStyle(.plain)
                .disabled(!isEnabled)
            } else {
                chipBody
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    private var chipBody: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 4) {
                Text(label)
                    .font(density.labelFont)
                    .foregroundStyle(GameTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                Text("\(count)")
                    .font(density.countFont)
                    .foregroundStyle(GameTheme.mutedInk)
            }
            .frame(maxWidth: .infinity, minHeight: density.chipMinHeight)
            .padding(.horizontal, density.chipHorizontalPadding)
            .padding(.vertical, density.chipVerticalPadding)
            .background(backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: GameTheme.smallRadius)
                    .stroke(borderColor, lineWidth: isSelected ? 2 : 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: GameTheme.smallRadius))
            .opacity(isEnabled ? 1 : 0.72)

            if let selectionBadge {
                badge(text: selectionBadge, tint: GameTheme.accent)
                    .padding(6)
            }

            if let detailBadge {
                VStack {
                    Spacer(minLength: 0)

                    HStack {
                        Spacer(minLength: 0)
                        badge(
                            text: detailBadge,
                            tint: isEnabled ? GameTheme.accent : GameTheme.mutedInk
                        )
                    }
                }
                .padding(6)
            }
        }
    }

    private var backgroundColor: Color {
        let base: Color = switch resource {
        case .wood:
            GameTheme.wood.opacity(0.28)
        case .brick:
            GameTheme.brick.opacity(0.24)
        case .sheep:
            GameTheme.sheep.opacity(0.24)
        case .wheat:
            GameTheme.wheat.opacity(0.26)
        case .ore:
            GameTheme.ore.opacity(0.22)
        case .desert:
            GameTheme.surfaceRaised.opacity(0.40)
        }

        return isSelected ? base.opacity(1.15) : base
    }

    private var borderColor: Color {
        isSelected ? GameTheme.accent : GameTheme.outline.opacity(0.14)
    }

    private func badge(text: String, tint: Color) -> some View {
        Text(text)
            .font(density.badgeFont)
            .foregroundStyle(.white)
            .lineLimit(1)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(tint)
            .clipShape(Capsule())
    }
}

extension ResourceV1 {
    var shortLabel: String {
        switch self {
        case .wood:
            return "Wood"
        case .brick:
            return "Brick"
        case .sheep:
            return "Sheep"
        case .wheat:
            return "Wheat"
        case .ore:
            return "Ore"
        case .desert:
            return "Desert"
        }
    }
}
