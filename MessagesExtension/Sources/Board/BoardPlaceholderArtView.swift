import SwiftUI

struct BoardPlaceholderArtView: View {
    private let rows: [[Color]] = [
        [GameTheme.sheep, GameTheme.brick, GameTheme.wheat],
        [GameTheme.wood, GameTheme.surfaceRaised, GameTheme.ore, GameTheme.wheat],
        [GameTheme.brick, GameTheme.sheep, GameTheme.wood],
    ]

    var body: some View {
        GeometryReader { geometry in
            let tileWidth = min(geometry.size.width / 4.4, 92)
            let tileHeight = tileWidth * 0.86
            let rowSpacing = tileHeight * -0.22
            let rowOffset = tileWidth * 0.30

            ZStack {
                Circle()
                    .fill(GameTheme.water.opacity(0.18))
                    .frame(width: geometry.size.width * 0.92)
                    .blur(radius: 18)

                VStack(spacing: rowSpacing) {
                    ForEach(rows.indices, id: \.self) { rowIndex in
                        HStack(spacing: tileWidth * -0.08) {
                            ForEach(rows[rowIndex].indices, id: \.self) { colorIndex in
                                HexagonShape()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                rows[rowIndex][colorIndex].opacity(0.92),
                                                GameTheme.surfaceRaised.opacity(0.88),
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .overlay(
                                        HexagonShape()
                                            .stroke(GameTheme.outline.opacity(0.18), lineWidth: 1)
                                    )
                                    .frame(width: tileWidth, height: tileHeight)
                                    .shadow(color: GameTheme.sectionShadow.opacity(0.45), radius: 6, x: 0, y: 4)
                            }
                        }
                        .offset(x: rowIndex == 1 ? 0 : rowOffset)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .allowsHitTesting(false)
    }
}
