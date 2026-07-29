import SwiftUI

struct GameEndTopTableauView: View {
    let model: GameEndScreenModel

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(spacing: GameTheme.inlineSpacing) {
                    GameEndOutcomeHeaderView(model: model)
                    GameEndDevelopmentCardSpreadView(
                        groups: model.localDevelopmentCardGroups
                    )
                }
            } else {
                HStack(spacing: GameTheme.blockSpacing) {
                    GameEndOutcomeHeaderView(model: model)
                        .frame(maxWidth: GamePhysicalTurnLayout.endOutcomeColumnMaxWidth)

                    GameEndDevelopmentCardSpreadView(
                        groups: model.localDevelopmentCardGroups
                    )
                }
            }
        }
        .padding(.horizontal, GameTheme.shellPadding)
        .frame(maxWidth: .infinity)
    }
}
