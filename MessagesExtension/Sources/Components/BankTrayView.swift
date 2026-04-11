import SwiftUI
import ULS_CoreGame

struct BankTrayView: View {
    let model: GameBankTrayModel
    let onSelect: (ResourceV1) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: GameTheme.inlineSpacing) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(model.title)
                    .font(GameTheme.headingFont)
                    .foregroundStyle(GameTheme.ink)

                if let subtitle = model.subtitle {
                    Text(subtitle)
                        .font(GameTheme.metaFont)
                        .foregroundStyle(GameTheme.mutedInk)
                        .lineLimit(2)
                }
            }

            LazyVGrid(
                columns: Array(
                    repeating: GridItem(.flexible(minimum: 0), spacing: GameTheme.chipSpacing),
                    count: max(model.chips.count, 1)
                ),
                spacing: GameTheme.chipSpacing
            ) {
                ForEach(model.chips) { chip in
                    BankChipButton(chip: chip) {
                        onSelect(chip.resource)
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

private struct BankChipButton: View {
    let chip: GameBankChip
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    Text(chip.resource.shortLabel)
                        .font(GameTheme.chipFont)
                        .foregroundStyle(GameTheme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)

                    Spacer(minLength: 0)

                    if let selectionIndex = chip.selectionIndex {
                        Text("\(selectionIndex)")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(GameTheme.accent)
                            .clipShape(Capsule())
                    }
                }

                Text("\(chip.count)")
                    .font(GameTheme.headingFont)
                    .foregroundStyle(GameTheme.mutedInk)

                if let detailText = chip.detailText {
                    Text(detailText)
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(chip.isEnabled ? GameTheme.accent : GameTheme.mutedInk)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                } else {
                    Spacer()
                        .frame(height: 12)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 72, alignment: .top)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(backgroundColor(for: chip.resource, selected: chip.isSelected))
            .overlay(
                RoundedRectangle(cornerRadius: GameTheme.smallRadius)
                    .stroke(borderColor, lineWidth: chip.isSelected ? 2 : 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: GameTheme.smallRadius))
            .opacity(chip.isEnabled ? 1 : 0.72)
        }
        .buttonStyle(.plain)
        .disabled(!chip.isEnabled)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    private var borderColor: Color {
        chip.isSelected ? GameTheme.accent : GameTheme.outline.opacity(0.14)
    }

    private func backgroundColor(for resource: ResourceV1, selected: Bool) -> Color {
        let base: Color = switch resource {
        case .wood:
            GameTheme.wood.opacity(0.20)
        case .brick:
            GameTheme.brick.opacity(0.18)
        case .sheep:
            GameTheme.sheep.opacity(0.18)
        case .wheat:
            GameTheme.wheat.opacity(0.20)
        case .ore:
            GameTheme.ore.opacity(0.18)
        case .desert:
            GameTheme.surfaceRaised.opacity(0.4)
        }
        return selected ? base.opacity(1.2) : base
    }

    private var accessibilityLabel: String {
        var parts = [chip.resource.shortLabel, "\(chip.count) left in bank"]
        if let detailText = chip.detailText {
            parts.append(detailText)
        }
        if let selectionIndex = chip.selectionIndex {
            parts.append("selection \(selectionIndex)")
        }
        return parts.joined(separator: ", ")
    }
}

private extension ResourceV1 {
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
