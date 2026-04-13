import SwiftUI
import ULS_CoreGame

struct BankTrayView: View {
    let model: GameBankTrayModel
    let density: ResourceChipDensity
    let onSelect: (ResourceV1) -> Void

    var body: some View {
        let isInteractive = model.chips.contains(where: { $0.detailText != nil || $0.selectionIndex != nil || $0.isEnabled })

        ResourceChipGridView(items: model.chips, density: density) { chip in
            ResourceCountChipView(
                resource: chip.resource,
                label: chip.resource.shortLabel,
                count: chip.count,
                isEnabled: isInteractive ? chip.isEnabled : true,
                isSelected: isInteractive && chip.isSelected,
                selectionBadge: isInteractive ? chip.selectionIndex.map(String.init) : nil,
                detailBadge: isInteractive ? chip.detailText : nil,
                density: density,
                action: isInteractive ? { onSelect(chip.resource) } : nil,
                accessibilityLabel: accessibilityLabel(for: chip)
            )
        }
        .padding(density.containerPadding)
        .background(GameTheme.surface.opacity(0.90))
        .overlay(
            RoundedRectangle(cornerRadius: GameTheme.mediumRadius)
                .stroke(GameTheme.outline.opacity(0.16), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: GameTheme.mediumRadius))
    }

    private func accessibilityLabel(for chip: GameBankChip) -> String {
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
