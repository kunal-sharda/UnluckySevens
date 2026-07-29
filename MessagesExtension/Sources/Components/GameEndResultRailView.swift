import SwiftUI

struct GameEndResultRailView: View {
    let model: GameEndScreenModel
    let onNewGame: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                ScrollView(.vertical) {
                    GameEndResultContentView(
                        model: model,
                        onNewGame: onNewGame
                    )
                }
                .scrollIndicators(.hidden)
                .scrollBounceBehavior(.basedOnSize)
            } else {
                GameEndResultContentView(
                    model: model,
                    onNewGame: onNewGame
                )
            }
        }
        .frame(maxWidth: .infinity)
        .background(GamePhysicalTurnPalette.nameTileFill)
        .clipShape(RoundedRectangle(cornerRadius: GameTheme.smallRadius))
        .overlay {
            RoundedRectangle(cornerRadius: GameTheme.smallRadius)
                .stroke(GamePhysicalTurnPalette.nameTileEdge, lineWidth: 1.5)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("uls.endScreen")
    }
}
