#if DEBUG
import SwiftUI

struct GameRoadBuildingPreviewControls: View {
    let draft: GameRoadBuildingPreviewDraft
    let onUndo: () -> Void
    let onStartOver: () -> Void
    let onCancel: () -> Void
    let onConfirm: () -> Void

    var body: some View {
        GameRoadBuildingControls(draft: draft, onUndo: onUndo, onStartOver: onStartOver,
                                 onCancel: onCancel, onConfirm: onConfirm,
                                 accessibilityPrefix: "uls.preview.roads",
                                 confirmationHint: "Confirm both pending roads together. This preview does not send a move.")
    }
}
#endif
