import SwiftUI
import ULS_CoreGame

struct GamePhysicalDevResourceSpreadView: View {
    let bank: GameBankTrayModel
    let confirmTitle: String?
    let canConfirm: Bool
    let onSelectResource: (ResourceV1) -> Void
    let onConfirm: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            ForEach(bank.chips) { chip in
                resourceButton(chip)
            }

            if let confirmTitle {
                Button(confirmTitle, action: onConfirm)
                    .font(.caption)
                    .bold()
                    .foregroundStyle(GamePhysicalTurnPalette.primaryText)
                    .frame(width: 52, height: 44)
                    .overlay(alignment: .bottom) {
                        Capsule()
                            .fill(GamePhysicalTurnPalette.selectedKeyline)
                            .frame(width: 22, height: 2)
                    }
                    .contentShape(Rectangle())
                    .buttonStyle(.plain)
                    .disabled(!canConfirm)
                    .opacity(canConfirm ? 1 : 0.46)
                    .accessibilityIdentifier("uls.physicalProps.devResourceConfirm")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("uls.physicalProps.devResourceSpread")
        .accessibilityLabel("Development card resource choices")
    }

    private func resourceButton(_ chip: GameBankChip) -> some View {
        Button {
            onSelectResource(chip.resource)
        } label: {
            GameTabletopPortraitCardView(
                face: .resource(chip.resource),
                size: GamePhysicalTurnLayout.portraitCardSize,
                count: chip.count,
                isFaded: true,
                stackDepth: 1
            )
            .overlay(alignment: .topTrailing) {
                if let selectionIndex = chip.selectionIndex {
                    Text(selectionIndex, format: .number)
                        .font(.caption2)
                        .bold()
                        .foregroundStyle(GamePhysicalTurnPalette.cardCountInk)
                        .frame(width: 17, height: 17)
                        .background(GamePhysicalTurnPalette.selectedKeyline)
                        .clipShape(Circle())
                        .offset(x: 5, y: -5)
                }
            }
            .overlay {
                if chip.isSelected {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(GamePhysicalTurnPalette.selectedKeyline, lineWidth: 2)
                }
            }
            .frame(width: 44, height: 52)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!chip.isEnabled)
        .opacity(chip.isEnabled ? 1 : 0.42)
        .accessibilityLabel(accessibilityLabel(for: chip))
        .accessibilityAddTraits(chip.isSelected ? .isSelected : [])
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
