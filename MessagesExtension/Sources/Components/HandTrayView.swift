import SwiftUI
import ULS_CoreGame

struct HandTrayView: View {
    let model: GameHandTrayModel
    let density: ResourceChipDensity
    let selectedCountsByResource: [ResourceV1: Int]
    let onSelectResource: ((ResourceV1) -> Void)?

    init(
        model: GameHandTrayModel,
        density: ResourceChipDensity,
        selectedCountsByResource: [ResourceV1: Int] = [:],
        onSelectResource: ((ResourceV1) -> Void)? = nil
    ) {
        self.model = model
        self.density = density
        self.selectedCountsByResource = selectedCountsByResource
        self.onSelectResource = onSelectResource
    }

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
                        isEnabled: isSelectable(chip),
                        isSelected: selectedCount(for: chip.resource) > 0,
                        selectionBadge: selectionBadge(for: chip.resource),
                        detailBadge: nil,
                        density: density,
                        action: selectionAction(for: chip),
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

    private func selectedCount(for resource: ResourceV1) -> Int {
        selectedCountsByResource[resource] ?? 0
    }

    private func selectionBadge(for resource: ResourceV1) -> String? {
        let count = selectedCount(for: resource)
        return count > 0 ? String(count) : nil
    }

    private func isSelectable(_ chip: GameHandChip) -> Bool {
        onSelectResource == nil || selectedCount(for: chip.resource) < chip.count
    }

    private func selectionAction(for chip: GameHandChip) -> (() -> Void)? {
        guard let onSelectResource else {
            return nil
        }

        return {
            guard selectedCount(for: chip.resource) < chip.count else { return }
            onSelectResource(chip.resource)
        }
    }
}
