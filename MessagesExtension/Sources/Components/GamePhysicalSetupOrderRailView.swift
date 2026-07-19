import SwiftUI

struct GamePhysicalSetupOrderRailView: View {
    let model: GameSetupPlacementModel

    var body: some View {
        HStack(spacing: 8) {
            Text("SETUP\nORDER")
                .font(.caption2.bold())
                .tracking(0.6)
                .foregroundStyle(GamePhysicalTurnPalette.tertiaryText)
                .frame(width: 64, alignment: .leading)

            HStack(spacing: 4) {
                ForEach(Array(model.visibleOrder.enumerated()), id: \.element.id) { index, entry in
                    VStack(spacing: 6) {
                        ZStack {
                            Circle()
                                .fill(color(for: entry))

                            Text(initials(for: entry.displayName))
                                .font(.caption2.bold())
                                .foregroundStyle(.white)
                        }
                        .frame(width: 26, height: 26)
                        .overlay {
                            if entry.isCurrent {
                                Circle()
                                    .stroke(GamePhysicalTurnPalette.selectedKeyline, lineWidth: 3)
                                    .padding(-3)
                            }
                        }

                        ViewThatFits(in: .horizontal) {
                            Text(slotLabel(for: entry, at: index))
                            Text(entry.displayName)
                        }
                        .font(.caption)
                        .foregroundStyle(GamePhysicalTurnPalette.secondaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    }
                    .frame(width: 70)
                    .opacity(slotOpacity(at: index))
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(entry.displayName)
                    .accessibilityValue(accessibilityValue(for: entry))
                    .accessibilityIdentifier("uls.setup.orderEntry.\(entry.id)")
                }

                ForEach(0..<max(3 - model.visibleOrder.count, 0), id: \.self) { placeholderIndex in
                    let slotIndex = model.visibleOrder.count + placeholderIndex

                    VStack(spacing: 6) {
                        ZStack {
                            Circle()
                                .fill(GamePhysicalTurnPalette.tertiaryText.opacity(0.28))

                            Image(systemName: "person.fill")
                                .font(.caption2.bold())
                                .foregroundStyle(GamePhysicalTurnPalette.secondaryText)
                        }
                        .frame(width: 26, height: 26)

                        Text(slotIndex == 1 ? "Next turn" : "Waiting")
                            .font(.caption)
                            .foregroundStyle(GamePhysicalTurnPalette.secondaryText)
                            .lineLimit(1)
                    }
                    .frame(width: 70)
                    .opacity(slotOpacity(at: slotIndex))
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("No queued placement")
                }
            }

            Text("\(model.placementNumber) / \(model.placementCount)")
                .font(.caption.monospacedDigit())
                .foregroundStyle(GamePhysicalTurnPalette.secondaryText)
                .frame(width: 64, alignment: .trailing)
        }
        .padding(.horizontal, 8)
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("uls.setup.orderRail")
        .accessibilityValue("3 placement slots shown")
    }

    private func color(for entry: GameSetupPlacementModel.OrderEntry) -> Color {
        Color(
            red: entry.playerTint.red,
            green: entry.playerTint.green,
            blue: entry.playerTint.blue
        )
    }

    private func initials(for name: String) -> String {
        name.split(separator: " ")
            .prefix(2)
            .compactMap(\.first)
            .map(String.init)
            .joined()
            .uppercased()
    }

    private func slotLabel(for entry: GameSetupPlacementModel.OrderEntry, at index: Int) -> String {
        index == 1 ? "\(entry.displayName) · Next" : entry.displayName
    }

    private func slotOpacity(at index: Int) -> Double {
        switch index {
        case 0: return 1
        case 1: return 0.58
        default: return 0.34
        }
    }

    private func accessibilityValue(for entry: GameSetupPlacementModel.OrderEntry) -> String {
        if entry.isCurrent { return "Placing now" }
        if entry.isComplete { return "Placement complete" }
        return "Waiting"
    }
}
