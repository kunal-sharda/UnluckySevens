import SwiftUI
import ULS_CoreGame

enum ResourceChipLayoutMetrics {
    static let minHeight: CGFloat = 52

    static var columns: [GridItem] {
        Array(
            repeating: GridItem(.flexible(minimum: 0), spacing: GameTheme.chipSpacing),
            count: 5
        )
    }
}

struct ResourceChipGridView<Item: Identifiable, Content: View>: View {
    let items: [Item]
    let content: (Item) -> Content

    var body: some View {
        LazyVGrid(
            columns: ResourceChipLayoutMetrics.columns,
            spacing: GameTheme.chipSpacing
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
                    .font(GameTheme.chipFont)
                    .foregroundStyle(GameTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                Text("\(count)")
                    .font(GameTheme.headingFont)
                    .foregroundStyle(GameTheme.mutedInk)
            }
            .frame(maxWidth: .infinity, minHeight: ResourceChipLayoutMetrics.minHeight)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
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
            .font(.system(size: 10, weight: .bold, design: .rounded))
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
