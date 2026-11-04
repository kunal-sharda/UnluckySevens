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
        #if DEBUG
        if UserDefaults.standard.bool(forKey: "uls.debug.referenceCopyPreview") {
            preview
        } else {
            shippingCard
        }
        #else
        shippingCard
        #endif
    }

    private var shippingCard: some View {
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

    #if DEBUG
    @State private var showsAwardDetail = false

    private var preview: some View {
        GameTableReferencePreview(title: "Dev Cards", close: onClose) {
            HStack(spacing: 12) {
                GameTabletopPortraitCardView(face: .developmentBack, size: CGSize(width: 32, height: 40), stackDepth: 2)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Draw one hidden card.").font(.subheadline.bold())
                    Text("Buy from the Dev Cards pile above the board.").font(.caption)
                }
                Spacer(minLength: 3)
                GameBuildCostRow(cost: CoreBuildCostsV1.developmentCard)
            }.padding(.vertical, 4)
            if tutorialsEnabled {
                Divider()
                ForEach([GameDevCardVisualKind.knight, .roadBuilding, .yearOfPlenty, .monopoly, .victoryPoint]) { kind in
                    HStack(spacing: 10) {
                        GameTabletopPortraitCardView(face: .ownedDevelopment(kind), size: CGSize(width: 21, height: 27))
                        VStack(alignment: .leading, spacing: 1) {
                            Text(kind.title).font(.subheadline.bold())
                            Text(effect(kind)).font(.caption)
                        }
                    }
                }
                Divider()
                GameReferenceAwardPreview(title: "Largest Army", detail: "Play at least 3 Knights. To take Largest Army from another player, play more Knights than they have.", expanded: $showsAwardDetail)
            }
            if !canBuy, let unavailableReason { Text(unavailableReason).font(.caption) }
            Button("Buy Dev Card", action: onBuy)
                .buttonStyle(GameTabletopActionButtonStyle(emphasis: .primary, solidBackground: true))
                .frame(minHeight: 44).disabled(!canBuy).accessibilityIdentifier("uls.purchase.confirm")
            if tutorialsEnabled {
                Divider()
                GameTutorialPreferenceControls(onDisableTip: onDisableTip, onDisableAll: onDisable,
                    accessibilityPrefix: "uls.tutorial.purchase", disableAllIdentifier: "uls.tutorial.purchase.disable", onEnableTip: onEnableTip)
            }
        }.accessibilityElement(children: .contain).accessibilityIdentifier("uls.purchase.surface")
    }

    private func effect(_ kind: GameDevCardVisualKind) -> String {
        switch kind {
        case .knight: "Move the robber and steal a resource. Counts toward Largest Army."
        case .roadBuilding: "Place up to 2 roads for free."
        case .yearOfPlenty: "Take 2 resources of your choice from the Bank."
        case .monopoly: "Choose a resource. Take all of it from the other players."
        case .victoryPoint: "Gain 1 hidden VP. Your card is revealed automatically at 10 VP on your turn."
        }
    }
    #endif

}
