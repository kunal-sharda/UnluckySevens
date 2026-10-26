import SwiftUI

/// Local pre-roll presentation over the continuously mounted table.
struct GamePreRollInspectionView: View {
    let devCardPanel: GameDevCardPanelModel?
    let canPlayDevCards: Bool
    let canRoll: Bool
    let contentScale: CGFloat

    let isInspectingBoard: Bool
    let isDevChooserOpen: Bool
    let onInspect: () -> Void
    let onReturn: () -> Void
    let onToggleDevCards: () -> Void
    let onSelectDevCard: (GameDevCardActionKind) -> Void
    let onRoll: () -> Void
    var accessibilityPrefix = "uls.preRoll.map"
    @AccessibilityFocusState private var returnControlIsFocused: Bool

    var body: some View {
        ZStack {
            if !isInspectingBoard {
                GamePhysicalTurnPalette.focusVeil.ignoresSafeArea()

                GamePhysicalStartTurnView(
                    devCardPanel: devCardPanel,
                    canPlayDevCards: canPlayDevCards,
                    canRoll: canRoll,
                    isDevChooserOpen: isDevChooserOpen,
                    contentScale: contentScale,
                    onToggleDevCards: onToggleDevCards,
                    onSelectDevCard: onSelectDevCard,
                    onRoll: onRoll,
                    showsFocusVeil: false
                )
                .padding(.bottom, 88)
            }

            VStack {
                Spacer(minLength: 0)

                Button {
                    if isInspectingBoard { onReturn() } else { onInspect() }
                    returnControlIsFocused = true
                } label: {
                    Label(
                        isInspectingBoard ? "Back to Roll" : "Inspect Board",
                        systemImage: isInspectingBoard ? "arrow.uturn.backward" : "map"
                    )
                }
                .buttonStyle(GameTabletopActionButtonStyle(emphasis: .secondary, solidBackground: true))
                .frame(maxWidth: 240)
                .accessibilityIdentifier(
                    isInspectingBoard ? "\(accessibilityPrefix).return" : "\(accessibilityPrefix).inspect"
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
        .accessibilityIdentifier("\(accessibilityPrefix).surface")
        .accessibilityValue(isInspectingBoard ? "Inspecting board" : "Roll choices")
    }
}
