#if DEBUG
import SwiftUI

/// Accepted fixture remains inert while sharing the production composition.
struct GameMapInspectionPreviewView: View {
    let devCardPanel: GameDevCardPanelModel?
    let canPlayDevCards: Bool
    let canRoll: Bool
    let contentScale: CGFloat
    @State private var inspecting = false
    @State private var chooser = false

    var body: some View {
        GamePreRollInspectionView(
            devCardPanel: devCardPanel, canPlayDevCards: canPlayDevCards,
            canRoll: canRoll, contentScale: contentScale,
            isInspectingBoard: inspecting, isDevChooserOpen: chooser,
            onInspect: { inspecting = true }, onReturn: { inspecting = false },
            onToggleDevCards: { chooser.toggle() }, onSelectDevCard: { _ in }, onRoll: {},
            accessibilityPrefix: "uls.preview.map"
        )
    }
}
#endif
