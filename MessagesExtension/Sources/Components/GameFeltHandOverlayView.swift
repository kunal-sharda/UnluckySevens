import SwiftUI

struct GameFeltHandOverlayView: View {
    let handTray: GameHandTrayModel
    let ownedDevCards: [GameOwnedDevCardSummary]

    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion

    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 8) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Hand")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(GameTheme.surface)

                    HStack(spacing: 4) {
                        ForEach(handTray.chips) { chip in
                            TabletopResourceCardView(chip: chip)
                        }
                    }
                }

                Rectangle()
                    .fill(GameTheme.surface.opacity(0.16))
                    .frame(height: 1)

                VStack(alignment: .leading, spacing: 5) {
                    Text("Your Dev")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(GameTheme.surface)

                    GameOwnedDevCardStripView(cards: ownedDevCards)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .scrollBounceBehavior(.basedOnSize)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .clipped()
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("uls.feltTools.handContents")
        .transition(
            accessibilityReduceMotion
                ? .opacity
                : .move(edge: .bottom).combined(with: .opacity)
        )
    }
}
