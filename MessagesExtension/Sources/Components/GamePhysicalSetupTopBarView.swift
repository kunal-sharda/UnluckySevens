import SwiftUI

struct GamePhysicalSetupTopBarView: View {
    let model: GameSetupPlacementModel
    let onSettingsTap: () -> Void
    let onGameInfoTap: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Button("Settings", systemImage: "gearshape.fill", action: onSettingsTap)
                .labelStyle(.iconOnly)
                .font(.system(size: 20, weight: .semibold))
                .frame(width: 44, height: 44)

            VStack(spacing: 2) {
                Text(model.title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(GamePhysicalTurnPalette.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.76)

                if !model.instruction.isEmpty {
                    Text(model.instruction)
                        .font(.caption)
                        .foregroundStyle(GamePhysicalTurnPalette.secondaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .multilineTextAlignment(.center)
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("uls.setup.status")

            Button("Players and game information", systemImage: "person.2.fill", action: onGameInfoTap)
                .labelStyle(.iconOnly)
                .font(.system(size: 20, weight: .semibold))
                .frame(width: 44, height: 44)
        }
        .foregroundStyle(GamePhysicalTurnPalette.primaryText)
        .padding(.horizontal, 4)
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("uls.setup.topBar")
    }
}
