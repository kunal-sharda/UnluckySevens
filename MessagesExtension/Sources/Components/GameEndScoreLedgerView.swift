import SwiftUI

struct GameEndScoreLedgerView: View {
    let players: [GameEndScorePlayer]

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(spacing: GameTheme.chipSpacing) {
                    ForEach(players) { player in
                        GameEndScoreLedgerRowView(player: player)
                    }
                }
            } else {
                HStack(spacing: GameTheme.blockSpacing) {
                    ForEach(players) { player in
                        GameEndCompactScoreView(player: player)
                    }
                }
            }
        }
    }
}
