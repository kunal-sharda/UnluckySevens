import SwiftUI

struct GamePhysicalStartTurnDevChooserView: View {
    let panel: GameDevCardPanelModel?
    let onSelect: (GameDevCardActionKind) -> Void

    var body: some View {
        HStack(spacing: 10) {
            ForEach(panel?.cards ?? []) { card in
                GamePhysicalDevCardPropView(
                    card: card,
                    action: card.isEnabled ? card.actionKind : nil,
                    onSelect: onSelect
                )
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("uls.startTurn.devChooser")
        .accessibilityLabel("Playable pre-roll Dev Cards")
    }
}
