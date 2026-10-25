#if DEBUG
import SwiftUI

/// A small action rail, leaving the board available for selecting/revising roads.
struct GameRoadBuildingPreviewControls: View {
    let draft: GameRoadBuildingPreviewDraft
    let onUndo: () -> Void
    let onStartOver: () -> Void
    let onCancel: () -> Void
    let onConfirm: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(draft.guidance ?? draft.progress)
                .font(.headline)
                .accessibilityIdentifier("uls.preview.roads.progress")
                .accessibilityHint(draft.isReady
                    ? "Road Building. Both numbered roads are pending. Tap a highlighted edge to change Road 2."
                    : "Road Building places two roads together. Select a highlighted edge.")
            HStack(spacing: 12) {
                Button(action: onCancel) { Text("Cancel").frame(minHeight: 44).contentShape(Rectangle()) }
                    .accessibilityIdentifier("uls.preview.roads.cancel")
                if !draft.pendingEdgeIDs.isEmpty {
                    Button(action: onUndo) { Text("Undo").frame(minHeight: 44).contentShape(Rectangle()) }
                        .accessibilityIdentifier("uls.preview.roads.undo")
                    Button(action: onStartOver) { Text("Start Over").frame(minHeight: 44).contentShape(Rectangle()) }
                        .accessibilityIdentifier("uls.preview.roads.startOver")
                }
            }
            .buttonStyle(.plain)
            .font(.subheadline)
            .frame(minHeight: 44)
            if draft.isReady {
                Button("Play Road Building", action: onConfirm)
                    .buttonStyle(GameTabletopActionButtonStyle(emphasis: .primary, solidBackground: true))
                    .accessibilityHint("Confirm both pending roads together. This preview does not send a move.")
                    .accessibilityIdentifier("uls.preview.roads.confirm")
            }
        }
        .foregroundStyle(GamePhysicalTurnPalette.primaryText)
        .padding(10)
        .frame(maxWidth: 350)
        .background(GameTheme.felt, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(GamePhysicalTurnPalette.selectedKeyline.opacity(0.7), lineWidth: 1))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("uls.preview.roads.controls")
    }
}
#endif
