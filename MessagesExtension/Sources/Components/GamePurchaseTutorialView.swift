import SwiftUI
import ULS_CoreGame

/// Inspection uses canonical eligibility; callbacks alone can enter placement or buy.
struct GamePurchaseTutorialView: View {
    let buildItems: [GameBuildShelfItem]?
    let hand: GameHandTrayModel
    let canBuy: Bool
    let unavailableReason: String?
    let tutorialsEnabled: Bool
    let playerColor: Color
    let onBuild: (GameBuildShelfItem.Kind) -> Void
    let onBuy: () -> Void
    let onClose: () -> Void
    let onDisable: () -> Void
    let onDisableTip: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text(buildItems == nil ? "Dev Cards" : "Build").font(GameTheme.titleFont)
            if let buildItems {
                HStack(alignment: .top, spacing: 12) {
                    ForEach(buildItems) { item in
                        Button { onBuild(item.kind) } label: {
                            VStack(spacing: 10) {
                                GameTabletopPiecePropView(kind: piece(item.kind), color: playerColor, isSelected: item.isEnabled)
                                    .frame(width: 62, height: 48)
                                Text(item.title).font(.caption.bold())
                                costRow(item.cost)
                                Text(item.isEnabled ? "Build \(item.title)" : item.unavailableReason ?? "Unavailable now")
                                    .font(.caption).multilineTextAlignment(.center)
                                    .fixedSize(horizontal: false, vertical: true)
                            }.frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.plain).disabled(!item.isEnabled)
                        .accessibilityIdentifier("uls.tutorial.build.\(item.kind.rawValue)")
                    }
                }
            } else {
                GameTabletopPortraitCardView(face: .developmentBack, size: CGSize(width: 62, height: 78), stackDepth: 3)
                costRow(CoreBuildCostsV1.developmentCard)
                if tutorialsEnabled { Text("Draw one hidden card").font(.subheadline) }
                if !canBuy {
                    Text(unavailableReason ?? "Unavailable now")
                        .font(.subheadline).fixedSize(horizontal: false, vertical: true)
                }
                Button("Buy Dev Card", action: onBuy)
                    .buttonStyle(GameTabletopActionButtonStyle(emphasis: .primary, solidBackground: true))
                    .frame(minHeight: 44).disabled(!canBuy)
                    .accessibilityIdentifier("uls.purchase.confirm")
            }
            Button("Close", action: onClose).frame(minHeight: 44)
                .accessibilityIdentifier("uls.purchase.close")
            if tutorialsEnabled {
                GameTutorialPreferenceControls(
                    onDisableTip: onDisableTip, onDisableAll: onDisable,
                    accessibilityPrefix: "uls.tutorial.purchase",
                    disableAllIdentifier: "uls.tutorial.purchase.disable"
                )
            }
        }
        .foregroundStyle(GamePhysicalTurnPalette.primaryText)
        .padding(20).frame(maxWidth: 350)
        .background(GameTheme.felt, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(GamePhysicalTurnPalette.selectedKeyline.opacity(0.7), lineWidth: 1.5))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("uls.purchase.surface")
    }

    private func piece(_ kind: GameBuildShelfItem.Kind) -> GameTabletopPiecePropView.Kind {
        switch kind { case .buildRoad: .road; case .buildSettlement: .settlement; case .buildCity: .city }
    }
    private func costRow(_ cost: ResourceHandV1) -> some View {
        HStack(spacing: 3) {
            ForEach(ResourceV1.allCases.filter { cost.count(for: $0) > 0 }, id: \.self) { resource in
                VStack(spacing: 2) {
                    GameTabletopPortraitCardView(face: .resource(resource), size: CGSize(width: 17, height: 23))
                    if cost.count(for: resource) > 1 { Text("×\(cost.count(for: resource))").font(.caption2.bold()) }
                }.accessibilityLabel("\(cost.count(for: resource)) \(resource.shortLabel)")
            }
        }.frame(height: 38, alignment: .top)
    }
}
