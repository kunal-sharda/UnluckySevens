#if DEBUG
import SwiftUI

/// UX Lab-only composition checkpoint. Roll and Dev execution remain inert;
/// inspection and chooser presentation are local state, never game actions.
struct GameMapInspectionPreviewView: View {
    let devCardPanel: GameDevCardPanelModel?
    let canPlayDevCards: Bool
    let canRoll: Bool
    let contentScale: CGFloat

    @State private var isInspectingBoard = false
    @State private var isDevChooserOpen = false
    @AccessibilityFocusState private var returnControlIsFocused: Bool

    var body: some View {
        ZStack {
            if !isInspectingBoard {
                GamePhysicalStartTurnView(
                    devCardPanel: devCardPanel,
                    canPlayDevCards: canPlayDevCards,
                    canRoll: canRoll,
                    isDevChooserOpen: isDevChooserOpen,
                    contentScale: contentScale,
                    onToggleDevCards: { isDevChooserOpen.toggle() },
                    onSelectDevCard: { _ in },
                    onRoll: {}
                )
            }

            VStack {
                Spacer(minLength: 0)

                Button {
                    isInspectingBoard.toggle()
                    returnControlIsFocused = true
                } label: {
                    Label(
                        isInspectingBoard ? "Back to Roll" : "Inspect Board",
                        systemImage: isInspectingBoard ? "arrow.uturn.backward" : "map"
                    )
                }
                .buttonStyle(GameTabletopActionButtonStyle(emphasis: .secondary, solidBackground: true))
                .frame(maxWidth: 190)
                .accessibilityIdentifier(
                    isInspectingBoard ? "uls.preview.map.return" : "uls.preview.map.inspect"
                )
                .accessibilityHint(
                    isInspectingBoard
                        ? "Returns to the roll and Development Card choices without rolling"
                        : "Shows the board without rolling or changing the game"
                )
                .accessibilityFocused($returnControlIsFocused)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 28)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("uls.preview.map.surface")
        .accessibilityValue(isInspectingBoard ? "Inspecting board" : "Roll choices")
    }
}
#endif
