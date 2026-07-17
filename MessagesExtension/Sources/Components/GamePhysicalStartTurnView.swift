import SwiftUI

struct GamePhysicalStartTurnView: View {
    let devCardPanel: GameDevCardPanelModel?
    let canPlayDevCards: Bool
    let canRoll: Bool
    let isDevChooserOpen: Bool
    let contentScale: CGFloat
    let onToggleDevCards: () -> Void
    let onSelectDevCard: (GameDevCardActionKind) -> Void
    let onRoll: () -> Void

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                GamePhysicalTurnPalette.focusVeil
                    .ignoresSafeArea()

                VStack(spacing: isDevChooserOpen ? 22 : 32) {
                    Spacer(minLength: 24)

                    VStack(spacing: 9) {
                        Text(isDevChooserOpen ? "Choose a Dev Card" : "Your Turn")
                            .font(GameTheme.displayFont)
                            .foregroundStyle(GamePhysicalTurnPalette.primaryText)
                            .multilineTextAlignment(.center)

                        Capsule()
                            .fill(GamePhysicalTurnPalette.selectedKeyline)
                            .frame(width: 38, height: 3)
                    }

                    if isDevChooserOpen {
                        GamePhysicalStartTurnDevChooserView(
                            panel: devCardPanel,
                            onSelect: onSelectDevCard
                        )

                        GamePhysicalStartTurnChoiceView(
                            canPlayDevCards: canPlayDevCards,
                            canRoll: canRoll,
                            isDevChooserOpen: true,
                            onToggleDevCards: onToggleDevCards,
                            onRoll: onRoll
                        )
                    } else {
                        GamePhysicalStartTurnChoiceView(
                            canPlayDevCards: canPlayDevCards,
                            canRoll: canRoll,
                            isDevChooserOpen: false,
                            onToggleDevCards: onToggleDevCards,
                            onRoll: onRoll
                        )
                    }

                    Spacer(minLength: 24)
                }
                .padding(.horizontal, 28)
                .scaleEffect(contentScale)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("uls.startTurn.surface")
        .accessibilityLabel("Start of turn")
    }
}
