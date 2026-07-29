import SwiftUI

struct GameEndDevelopmentCardSpreadView: View {
    let groups: [GameEndDevelopmentCardGroup]

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(spacing: GameTheme.chipSpacing) {
            Text("Your cards")
                .font(.subheadline)
                .bold()
                .foregroundStyle(GamePhysicalTurnPalette.primaryText)

            if groups.isEmpty {
                Text("No development cards")
                    .font(.caption)
                    .foregroundStyle(GamePhysicalTurnPalette.secondaryText)
                    .frame(maxWidth: .infinity, minHeight: 47)
            } else {
                HStack(alignment: .center, spacing: GameTheme.chipSpacing) {
                    ForEach(Array(groups.enumerated()), id: \.element.id) { index, group in
                        ZStack(alignment: .topTrailing) {
                            GameTabletopPortraitCardView(
                                face: .ownedDevelopment(group.kind),
                                size: GamePhysicalTurnLayout.portraitCardSize
                            )

                            if group.count > 1 {
                                Text("×\(group.count)")
                                    .font(.caption)
                                    .bold()
                                    .foregroundStyle(GamePhysicalTurnPalette.publicPileRevealInk)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 1)
                                    .background(
                                        Capsule()
                                            .fill(GamePhysicalTurnPalette.devCardEdge)
                                    )
                                    .offset(x: 7, y: -4)
                            }
                        }
                        .rotationEffect(.degrees(rotation(at: index)))
                        .offset(y: verticalOffset(at: index))
                        .frame(width: 42)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(maxWidth: .infinity)
        .allowsHitTesting(false)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityIdentifier("uls.endScreen.playedDevelopmentCards")
        .dynamicTypeSize(dynamicTypeSize.isAccessibilitySize ? .large : dynamicTypeSize)
    }

    private func rotation(at index: Int) -> Double {
        guard groups.count > 1 else { return 0 }
        let center = Double(groups.count - 1) / 2
        return (Double(index) - center) * 4
    }

    private func verticalOffset(at index: Int) -> CGFloat {
        guard groups.count > 1 else { return 0 }
        let center = CGFloat(groups.count - 1) / 2
        return abs(CGFloat(index) - center) * 1.5
    }

    private var accessibilityLabel: String {
        guard !groups.isEmpty else {
            return "You had no development cards this game"
        }
        let descriptions = groups.map { "\($0.count) \($0.kind.title)" }
        return "Your development cards: \(descriptions.joined(separator: ", "))"
    }
}
