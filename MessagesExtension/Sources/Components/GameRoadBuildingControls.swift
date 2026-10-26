import SwiftUI

/// A small action rail, leaving the board available for selecting/revising roads.
struct GameRoadBuildingControls: View {
    let draft: GameRoadBuildingDraft
    let onUndo: () -> Void
    let onStartOver: () -> Void
    let onCancel: () -> Void
    let onConfirm: () -> Void
    var accessibilityPrefix = "uls.roads"
    var isSending = false
    var confirmationHint = "Confirm and send both pending roads together."
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if !dynamicTypeSize.isAccessibilitySize || draft.guidance != nil {
                Text(draft.guidance ?? draft.progress)
                    .font(.headline)
                    .accessibilityIdentifier("\(accessibilityPrefix).progress")
                    .accessibilityHint(progressHint)
            }
            if dynamicTypeSize.isAccessibilitySize {
                HStack(spacing: 6) {
                    cancelButton
                    if !draft.pendingEdgeIDs.isEmpty { undoButton }
                }
                if !draft.pendingEdgeIDs.isEmpty { startOverButton }
            } else {
                HStack(spacing: 6) {
                    cancelButton
                    if !draft.pendingEdgeIDs.isEmpty {
                        undoButton
                        startOverButton
                    }
                }
            }
            if draft.isReady {
                Button("Play Road Building", action: onConfirm)
                    .buttonStyle(GameTabletopActionButtonStyle(emphasis: .primary, solidBackground: true))
                    .accessibilityHint(confirmationHint)
                    .accessibilityIdentifier("\(accessibilityPrefix).confirm")
            }
        }
        .disabled(isSending)
        .foregroundStyle(GamePhysicalTurnPalette.primaryText)
        .padding(10)
        .frame(maxWidth: 350)
        .background(GameTheme.felt, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(GamePhysicalTurnPalette.selectedKeyline.opacity(0.7), lineWidth: 1))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("\(accessibilityPrefix).controls")
        .accessibilityValue(draft.guidance ?? draft.progress)
        .accessibilityHint(progressHint)
    }

    private var progressHint: String {
        draft.isReady
            ? "Road Building. Both numbered roads are pending. Tap a highlighted edge to change Road 2."
            : "Road Building places two roads together. Select a highlighted edge."
    }

    private var cancelButton: some View {
        revisionButton("Cancel", suffix: "cancel", hint: "Discard both pending roads without playing the card.", action: onCancel)
    }

    private var undoButton: some View {
        revisionButton("Undo", suffix: "undo", hint: "Remove the most recently selected road.", action: onUndo)
    }

    private var startOverButton: some View {
        revisionButton("Start Over", suffix: "startOver", hint: "Clear both pending roads and select again.", action: onStartOver)
    }

    private func revisionButton(_ title: String, suffix: String, hint: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 8)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(GameTheme.felt.opacity(0.98), in: RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(GamePhysicalTurnPalette.primaryText.opacity(0.6), lineWidth: 1))
                .contentShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("\(accessibilityPrefix).\(suffix)")
        .accessibilityHint(hint)
    }

}
