import SwiftUI
import ULS_CoreGame

struct HandTrayView: View {
    let model: GameHandTrayModel

    var body: some View {
        VStack(alignment: .leading, spacing: GameTheme.inlineSpacing) {
            Text(model.title)
                .font(GameTheme.headingFont)
                .foregroundStyle(GameTheme.ink)

            if model.chips.isEmpty {
                ContentUnavailableView("No visible hand", systemImage: "shippingbox")
                    .frame(maxWidth: .infinity)
            } else {
                LazyVGrid(
                    columns: Array(
                        repeating: GridItem(.flexible(minimum: 0), spacing: GameTheme.chipSpacing),
                        count: model.chips.count
                    ),
                    spacing: GameTheme.chipSpacing
                ) {
                    ForEach(model.chips) { chip in
                        HandChipView(chip: chip)
                    }
                }
            }
        }
        .padding(GameTheme.compactPadding)
        .background(GameTheme.surface.opacity(0.92))
        .overlay(
            RoundedRectangle(cornerRadius: GameTheme.mediumRadius)
                .stroke(GameTheme.outline.opacity(0.16), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: GameTheme.mediumRadius))
    }
}

private struct HandChipView: View {
    let chip: GameHandChip

    var body: some View {
        VStack(spacing: 4) {
            Text(chip.shortLabel)
                .font(GameTheme.chipFont)
                .foregroundStyle(GameTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
            Text("\(chip.count)")
                .font(GameTheme.headingFont)
                .foregroundStyle(GameTheme.mutedInk)
        }
        .frame(maxWidth: .infinity, minHeight: 58)
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(backgroundColor(for: chip.resource))
        .overlay(
            RoundedRectangle(cornerRadius: GameTheme.smallRadius)
                .stroke(GameTheme.outline.opacity(0.14), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: GameTheme.smallRadius))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(chip.shortLabel) \(chip.count)")
    }

    private func backgroundColor(for resource: ResourceV1) -> Color {
        switch resource {
        case .wood:
            return GameTheme.wood.opacity(0.28)
        case .brick:
            return GameTheme.brick.opacity(0.24)
        case .sheep:
            return GameTheme.sheep.opacity(0.24)
        case .wheat:
            return GameTheme.wheat.opacity(0.26)
        case .ore:
            return GameTheme.ore.opacity(0.22)
        case .desert:
            return GameTheme.surfaceRaised.opacity(0.4)
        }
    }
}
