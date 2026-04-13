import SwiftUI
import ULS_CoreGame

struct HandTrayView: View {
    let model: GameHandTrayModel
    let density: ResourceChipDensity

    var body: some View {
        Group {
            if model.chips.isEmpty {
                ContentUnavailableView("No visible hand", systemImage: "shippingbox")
                    .frame(maxWidth: .infinity)
            } else {
                ResourceChipGridView(items: model.chips, density: density) { chip in
                    ResourceCountChipView(
                        resource: chip.resource,
                        label: chip.shortLabel,
                        count: chip.count,
                        isEnabled: true,
                        isSelected: false,
                        selectionBadge: nil,
                        detailBadge: nil,
                        density: density,
                        action: nil,
                        accessibilityLabel: "\(chip.shortLabel) \(chip.count)"
                    )
                }
            }
        }
        .padding(density.containerPadding)
        .background(GameTheme.surface.opacity(0.90))
        .overlay(
            RoundedRectangle(cornerRadius: GameTheme.mediumRadius)
                .stroke(GameTheme.outline.opacity(0.16), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: GameTheme.mediumRadius))
    }
}
