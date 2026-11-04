import SwiftUI
import ULS_CoreGame

/// A physical reference card. Core-derived items alone determine legal placement.
struct GameBuildCostReferenceView: View {
    let items: [GameBuildShelfItem]
    let playerColor: Color
    let canBuy: Bool
    let buyUnavailableReason: String?
    let showsTutorialControls: Bool
    let onBuild: (GameBuildShelfItem.Kind) -> Void
    let onDev: () -> Void
    let onClose: () -> Void
    let onDisableTip: () -> Void
    let onEnableTip: () -> Void
    let onDisableAll: () -> Void

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
        .padding(16)
        .frame(maxWidth: 370)
        .foregroundStyle(GameTheme.felt)
        .background(GameTheme.surface, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(GamePhysicalTurnPalette.selectedKeyline.opacity(0.65), lineWidth: 1))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("uls.buildCosts.reference")
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Build Costs").font(GameTheme.titleFont).accessibilityAddTraits(.isHeader)
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "chevron.down").frame(width: 44, height: 44).contentShape(Rectangle())
                }
                .accessibilityLabel("Put away Build Costs")
                .accessibilityIdentifier("uls.purchase.close")
            }
            ForEach(items) { item in
                Button { onBuild(item.kind) } label: {
                    row(title: item.title, points: item.kind == .buildRoad ? "0 VP" : item.kind == .buildSettlement ? "1 VP" : "2 VP · replaces a settlement",
                        cost: item.cost, reason: item.isEnabled ? nil : item.unavailableReason) {
                        GameTabletopPiecePropView(kind: piece(item.kind), color: playerColor, isSelected: item.isEnabled)
                            .frame(width: 46, height: 38)
                    }
                }
                .disabled(!item.isEnabled)
                .accessibilityIdentifier("uls.tutorial.build.\(item.kind.rawValue)")
            }
            Button(action: onDev) {
                row(title: "Dev Card", points: "Action or hidden VP", cost: CoreBuildCostsV1.developmentCard,
                    reason: canBuy ? nil : buyUnavailableReason) {
                    GameTabletopPortraitCardView(face: .developmentBack, size: CGSize(width: 30, height: 38), stackDepth: 2)
                        .frame(width: 46, height: 38)
                }
            }
            .accessibilityHint("Opens purchase confirmation without buying a card")
            .accessibilityIdentifier("uls.buildCosts.dev")
            if showsTutorialControls {
                Divider()
                GameTutorialPreferenceControls(onDisableTip: onDisableTip, onDisableAll: onDisableAll,
                    accessibilityPrefix: "uls.tutorial.purchase", disableAllIdentifier: "uls.tutorial.purchase.disable", onEnableTip: onEnableTip)
            }
        }
        .buttonStyle(.plain)
    }

    private func row<Art: View>(title: String, points: String, cost: ResourceHandV1, reason: String?, @ViewBuilder art: () -> Art) -> some View {
        HStack(alignment: .top, spacing: 10) {
            art().padding(.top, 3).accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 5) {
                Text(title).font(.subheadline.bold())
                Text(points).font(.caption).fixedSize(horizontal: false, vertical: true)
                GameBuildCostRow(cost: cost)
                if let reason { Text(reason).font(.caption).fixedSize(horizontal: false, vertical: true) }
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
        .contentShape(Rectangle())
    }

    private func piece(_ kind: GameBuildShelfItem.Kind) -> GameTabletopPiecePropView.Kind {
        switch kind { case .buildRoad: .road; case .buildSettlement: .settlement; case .buildCity: .city }
    }

    #if DEBUG
    @State private var showsAwardDetail = false

    private var preview: some View {
        GameTableReferencePreview(title: "Build Costs", close: onClose) {
            ForEach(items) { item in
                Button { onBuild(item.kind) } label: {
                    HStack(spacing: 10) {
                        GameTabletopPiecePropView(kind: piece(item.kind), color: playerColor, isSelected: item.isEnabled)
                            .frame(width: 34, height: 28)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(item.title).font(.subheadline.bold())
                            Text(benefit(item.kind)).font(.caption)
                            if !item.isEnabled, let reason = item.unavailableReason { Text(reason).font(.caption) }
                        }
                        Spacer(minLength: 3)
                        GameBuildCostRow(cost: item.cost)
                    }.frame(minHeight: 48).contentShape(Rectangle())
                }.disabled(!item.isEnabled)
                .accessibilityIdentifier("uls.tutorial.build.\(item.kind.rawValue)")
            }
            Button(action: onDev) {
                HStack(spacing: 10) {
                    GameTabletopPortraitCardView(face: .developmentBack, size: CGSize(width: 22, height: 28))
                        .frame(width: 34)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Dev Card").font(.subheadline.bold())
                        Text("Draw one hidden card.").font(.caption)
                    }
                    Spacer()
                    GameBuildCostRow(cost: CoreBuildCostsV1.developmentCard)
                }.frame(minHeight: 48).contentShape(Rectangle())
            }.accessibilityIdentifier("uls.buildCosts.dev")
            Divider()
            GameReferenceAwardPreview(title: "Longest Road", detail: "Connect at least 5 roads in one continuous route. To take Longest Road from another player, build a longer route.", expanded: $showsAwardDetail)
            if showsTutorialControls {
                Divider()
                GameTutorialPreferenceControls(onDisableTip: onDisableTip, onDisableAll: onDisableAll,
                    accessibilityPrefix: "uls.tutorial.purchase", disableAllIdentifier: "uls.tutorial.purchase.disable", onEnableTip: onEnableTip)
            }
        }.accessibilityElement(children: .contain).accessibilityIdentifier("uls.buildCosts.reference")
    }

    private func benefit(_ kind: GameBuildShelfItem.Kind) -> String {
        switch kind {
        case .buildRoad: "Extend your route toward Longest Road."
        case .buildSettlement: "Collect resources from adjacent tiles. 1 VP."
        case .buildCity: "Replace a settlement. Double its production. 2 VP total."
        }
    }
    #endif

}

