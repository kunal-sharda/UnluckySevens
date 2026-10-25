#if DEBUG
import SwiftUI
import ULS_CoreGame

/// A review-only alternative. The Messages publication dispatcher never selects it.
struct TranscriptSharedResultDesignPreviewView: View {
    let state: CoreGameStateV1
    let visual: TranscriptGameOverVisual
    let boardImage: UIImage

    var body: some View {
        VStack(spacing: 0) {
            Image(uiImage: boardImage)
                .resizable()
                .scaledToFit()
                .frame(height: 168)
                .frame(maxWidth: .infinity)
                .background(Color(uiColor: GameBoardPalette.sceneBackground))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 12) {
                Text(visual.winnerTitle)
                    .font(.headline)
                    .foregroundStyle(GamePhysicalTurnPalette.primaryText)
                    .fixedSize(horizontal: false, vertical: true)

                LazyVGrid(
                    columns: [GridItem(.flexible()), GridItem(.flexible())],
                    alignment: .leading,
                    spacing: 12
                ) {
                    ForEach(state.roster, id: \.self) { player in
                        HStack(alignment: .center, spacing: 6) {
                            GameTabletopPiecePropView(
                                kind: .settlement,
                                color: Color(uiColor: GameBoardPalette.playerColor(
                                    owner: player,
                                    playerOrder: state.roster
                                )),
                                isSelected: false
                            )
                            .frame(width: 24, height: 24)
                            .accessibilityHidden(true)

                            Text(state.playerDisplayNamesByPlayer[player] ?? player)
                                .font(.caption.weight(.medium))
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer(minLength: 2)
                            Text("\(victoryPoints(for: player, in: state))")
                                .font(.subheadline.weight(.semibold))
                                .monospacedDigit()
                        }
                        .foregroundStyle(GamePhysicalTurnPalette.primaryText)
                        .accessibilityElement(children: .combine)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 16)
        }
        .frame(width: TranscriptBubbleImageRenderer.imageSize.width)
        .fixedSize(horizontal: false, vertical: true)
        .background(GameTheme.felt)
        .environment(\.colorScheme, .dark)
        // Like production bubble artwork, scalable reading remains in Messages copy.
        .environment(\.dynamicTypeSize, .large)
    }
}
#endif
