#if DEBUG
import SwiftUI
import ULS_CoreGame

/// Visual checkpoint only. Availability examples are synthetic; no purchase is sent.
struct GamePurchaseCostPreviewView: View {
    enum Screen { case build, devAvailable, devUnavailable }
    let screen: Screen
    let onDisableTutorialPopups: () -> Void
    private let resources: [ResourceV1] = [.wood, .brick, .sheep, .wheat, .ore]

    var body: some View {
        if screen == .build {
            GameBuildGuidePreviewView(onClose: onDisableTutorialPopups)
        } else {
            legacyPreview
        }
    }

    private var legacyPreview: some View {
        ZStack {
            GameTheme.felt.opacity(0.48).ignoresSafeArea()
            VStack(spacing: 20) {
                Text(screen == .build ? "Build" : "Dev Cards")
                    .font(GameTheme.titleFont)
                if screen == .build {
                    HStack(alignment: .top, spacing: 12) {
                        buildChoice("Road", kind: .road, cost: CoreBuildCostsV1.road, detail: "Build Road", enabled: true)
                        buildChoice("Settlement", kind: .settlement, cost: CoreBuildCostsV1.settlement, detail: "Need 1 sheep", enabled: false)
                        buildChoice("City", kind: .city, cost: CoreBuildCostsV1.city, detail: "No settlement to upgrade", enabled: false)
                    }
                } else {
                    GameTabletopPortraitCardView(face: .developmentBack, size: CGSize(width: 62, height: 78), stackDepth: 3)
                    costRow(CoreBuildCostsV1.developmentCard)
                    Text("Draw one hidden card")
                        .font(.subheadline)
                    if screen == .devUnavailable {
                        Text("Need 1 ore").font(.subheadline.weight(.semibold))
                    }
                    Text("Buy Dev Card")
                        .font(.headline)
                        .padding(.horizontal, 20).padding(.vertical, 12)
                        .background(GamePhysicalTurnPalette.nameTileFill, in: RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(screen == .devAvailable ? GamePhysicalTurnPalette.selectedKeyline : GamePhysicalTurnPalette.nameTileEdge, lineWidth: 1.5))
                        .opacity(screen == .devAvailable ? 1 : 0.55)
                }
                Button(action: onDisableTutorialPopups) {
                    Text("Disable tutorial pop-ups")
                        .font(.footnote)
                        .underline()
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("uls.preview.purchase.disableTutorials")
            }
            .foregroundStyle(GamePhysicalTurnPalette.primaryText)
            .padding(20)
            .frame(maxWidth: 350)
            .background(GameTheme.felt, in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(GamePhysicalTurnPalette.selectedKeyline.opacity(0.7), lineWidth: 1.5))
            .padding(.horizontal, 12)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("uls.preview.purchase.surface")
    }

    private func buildChoice(_ title: String, kind: GameTabletopPiecePropView.Kind, cost: ResourceHandV1, detail: String, enabled: Bool) -> some View {
        VStack(spacing: 10) {
            GameTabletopPiecePropView(kind: kind, color: .red, isSelected: enabled)
                .frame(width: 62, height: 48)
            Text(title).font(.caption.bold())
            costRow(cost)
            Text(detail)
                .font(.caption)
                .multilineTextAlignment(.center)
                .frame(minHeight: 40, alignment: .top)
                .foregroundStyle(enabled ? GamePhysicalTurnPalette.selectedKeyline : GamePhysicalTurnPalette.primaryText)
        }
        .frame(maxWidth: .infinity)
    }

    private func costRow(_ cost: ResourceHandV1) -> some View {
        HStack(spacing: 3) {
            ForEach(resources.filter { cost.count(for: $0) > 0 }, id: \.self) { resource in
                VStack(spacing: 2) {
                    GameTabletopPortraitCardView(face: .resource(resource), size: CGSize(width: 17, height: 23))
                    if cost.count(for: resource) > 1 {
                        Text("×\(cost.count(for: resource))").font(.caption2.bold())
                    }
                }
                .accessibilityLabel("\(cost.count(for: resource)) \(resource.shortLabel)")
            }
        }
        .frame(height: 38, alignment: .top)
    }
}
#endif
