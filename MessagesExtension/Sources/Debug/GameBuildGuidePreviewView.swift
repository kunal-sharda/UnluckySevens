#if DEBUG
import SwiftUI
import ULS_CoreGame

/// Local visual checkpoint: selection never executes or publishes a game action.
struct GameBuildGuidePreviewView: View {
    let onClose: () -> Void
    @State private var hidesTip = false
    @State private var selected: String?

    var body: some View {
        ZStack {
            GameTheme.felt.opacity(0.48).ignoresSafeArea()
            VStack(spacing: 14) {
                HStack {
                    Text("Build & Buy").font(GameTheme.titleFont)
                    Spacer()
                    Button("Close", systemImage: "xmark", action: onClose)
                        .labelStyle(.iconOnly)
                        .frame(width: 44, height: 44)
                        .accessibilityIdentifier("uls.preview.guide.close")
                }
                Text("Here’s what you can build or buy.")
                    .font(.subheadline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Grid(horizontalSpacing: 18, verticalSpacing: 18) {
                    GridRow {
                        choice("Road", points: "0 VP", note: nil, cost: CoreBuildCostsV1.road, kind: .road)
                        choice("Settlement", points: "1 VP", note: nil, cost: CoreBuildCostsV1.settlement, kind: .settlement)
                    }
                    GridRow {
                        choice("City", points: "2 VP", note: "Replaces a settlement", cost: CoreBuildCostsV1.city, kind: .city)
                        choice("Dev Card", points: nil, note: "Action or hidden VP", cost: CoreBuildCostsV1.developmentCard, kind: nil)
                    }
                }
                Rectangle().fill(GamePhysicalTurnPalette.primaryText.opacity(0.18)).frame(height: 1)
                HStack(spacing: 8) {
                    Button {
                        hidesTip.toggle()
                    } label: {
                        Label("Hide this tip", systemImage: hidesTip ? "checkmark.square.fill" : "square")
                            .font(.caption)
                            .frame(minHeight: 44)
                    }
                    .accessibilityValue(hidesTip ? "Checked" : "Unchecked")
                    .accessibilityIdentifier("uls.preview.guide.hideTip")
                    Spacer(minLength: 0)
                    Button("Turn off all tips", action: onClose)
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .frame(minHeight: 44)
                        .overlay(RoundedRectangle(cornerRadius: 7).stroke(GamePhysicalTurnPalette.primaryText.opacity(0.45)))
                        .accessibilityIdentifier("uls.preview.purchase.disableTutorials")
                }
            }
            .buttonStyle(.plain)
            .foregroundStyle(GamePhysicalTurnPalette.primaryText)
            .padding(16)
            .frame(maxWidth: 350)
            .background(GameTheme.felt, in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(GamePhysicalTurnPalette.selectedKeyline.opacity(0.7), lineWidth: 1.5))
            .padding(.horizontal, 12)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("uls.preview.guide.surface")
    }

    private func choice(_ title: String, points: String?, note: String?, cost: ResourceHandV1, kind: GameTabletopPiecePropView.Kind?) -> some View {
        Button { selected = title } label: {
            VStack(spacing: 5) {
                Group {
                    if let kind {
                        GameTabletopPiecePropView(kind: kind, color: .red, isSelected: selected == title)
                            .frame(width: 64, height: 46)
                    } else {
                        GameTabletopPortraitCardView(face: .developmentBack, size: CGSize(width: 34, height: 44), stackDepth: 3)
                    }
                }.frame(height: 48)
                HStack(spacing: 5) {
                    Text(title).font(.caption.bold())
                    if let points { Text(points).font(.caption).foregroundStyle(GamePhysicalTurnPalette.selectedKeyline) }
                }
                if let note { Text(note).font(.caption2).multilineTextAlignment(.center) }
                HStack(alignment: .top, spacing: 4) {
                    ForEach(ResourceV1.allCases.filter { cost.count(for: $0) > 0 }, id: \.self) { resource in
                        VStack(spacing: 2) {
                            GameTabletopPortraitCardView(face: .resource(resource), size: CGSize(width: 17, height: 23))
                            if cost.count(for: resource) > 1 { Text("×\(cost.count(for: resource))").font(.caption2.bold()) }
                        }
                    }
                }.frame(height: 38, alignment: .top)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .accessibilityIdentifier("uls.preview.guide.\(title)")
        .accessibilityValue(selected == title ? "Selected" : "")
    }
}
#endif
