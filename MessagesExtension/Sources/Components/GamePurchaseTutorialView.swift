import SwiftUI
import ULS_CoreGame

/// Explicit purchase confirmation, with optional teaching about the public piles.
struct GamePurchaseTutorialView: View {
    let canBuy: Bool
    let unavailableReason: String?
    let tutorialsEnabled: Bool
    let onBuy: () -> Void
    let onClose: () -> Void
    let onDisable: () -> Void
    let onDisableTip: () -> Void
    let onEnableTip: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                ScrollView { content }.scrollBounceBehavior(.basedOnSize)
            } else {
                ViewThatFits(in: .vertical) {
                    content.fixedSize(horizontal: false, vertical: true)
                    ScrollView { content }.scrollBounceBehavior(.basedOnSize)
                }
            }
        }
        .foregroundStyle(GamePhysicalTurnPalette.primaryText)
        .padding(16).frame(maxWidth: 350)
        .background(GameTheme.felt, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(GamePhysicalTurnPalette.selectedKeyline.opacity(0.7), lineWidth: 1))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("uls.purchase.surface")
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Buy a Dev Card").font(GameTheme.titleFont).accessibilityAddTraits(.isHeader)
                Spacer(minLength: 0)
                Button(action: onClose) {
                    Image(systemName: "chevron.down").frame(width: 44, height: 44).contentShape(Rectangle())
                }.accessibilityLabel("Put away Dev Card")
                    .accessibilityIdentifier("uls.purchase.close")
            }
            HStack(spacing: 16) {
                GameTabletopPortraitCardView(face: .developmentBack, size: CGSize(width: 48, height: 62), stackDepth: 3)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Draw one hidden card").font(.subheadline)
                    GameBuildCostRow(cost: CoreBuildCostsV1.developmentCard)
                }
            }
            if tutorialsEnabled {
                Text("Tap the Dev Cards pile above to buy.")
                    .font(.subheadline).fixedSize(horizontal: false, vertical: true)
                Text("Tap the Bank to check supply. The bars show roughly how many cards remain; an empty bar means none.")
                    .font(.subheadline).fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("uls.tutorial.purchase.bankExplanation")
            }
            if !canBuy, let unavailableReason {
                Text(unavailableReason).font(.subheadline).fixedSize(horizontal: false, vertical: true)
            }
            Button("Buy Dev Card", action: onBuy)
                .buttonStyle(GameTabletopActionButtonStyle(emphasis: .primary, solidBackground: true))
                .frame(minHeight: 44).disabled(!canBuy)
                .accessibilityIdentifier("uls.purchase.confirm")
            if tutorialsEnabled {
                Divider()
                GameTutorialPreferenceControls(onDisableTip: onDisableTip, onDisableAll: onDisable,
                    accessibilityPrefix: "uls.tutorial.purchase", disableAllIdentifier: "uls.tutorial.purchase.disable",
                    onEnableTip: onEnableTip)
            }
        }.buttonStyle(.plain)
    }
}
