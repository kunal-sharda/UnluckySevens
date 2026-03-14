import SwiftUI

struct BoardContainerView: View {
    let model: GameBoardPlaceholderModel
    let renderModel: GameBoardRenderModel?
    let selectionText: String?
    let onTargetTap: ((GameBoardTarget) -> Void)?

    var body: some View {
        ZStack(alignment: .topLeading) {
            LinearGradient(
                colors: [
                    GameTheme.water.opacity(0.24),
                    GameTheme.surfaceRaised.opacity(0.94),
                    GameTheme.surface.opacity(0.92),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            if let renderModel {
                BoardSceneView(renderModel: renderModel, onTargetTap: onTargetTap)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 12)
            } else {
                BoardPlaceholderArtView()
                    .padding(.horizontal, 12)
                    .padding(.vertical, 16)
            }

            VStack(alignment: .leading, spacing: GameTheme.inlineSpacing) {
                Label("Board", systemImage: "hexagon")
                    .font(GameTheme.headingFont)
                    .foregroundStyle(GameTheme.ink)

                Spacer(minLength: 0)

                VStack(alignment: .leading, spacing: 4) {
                    Text(model.title)
                        .font(GameTheme.titleFont)
                        .foregroundStyle(GameTheme.ink)
                        .lineLimit(2)

                    Text(model.subtitle)
                        .font(GameTheme.metaFont)
                        .foregroundStyle(GameTheme.mutedInk)
                        .lineLimit(3)

                    if let selectionText {
                        Label(selectionText, systemImage: "scope")
                            .font(.system(.footnote, design: .rounded).bold())
                            .foregroundStyle(GameTheme.accent)
                            .lineLimit(1)
                    }
                }
                .padding(GameTheme.compactPadding)
                .background(GameTheme.surface.opacity(0.90))
                .overlay(
                    RoundedRectangle(cornerRadius: GameTheme.mediumRadius)
                        .stroke(GameTheme.outline.opacity(0.16), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: GameTheme.mediumRadius))
            }
            .padding(GameTheme.shellPadding)
        }
        .frame(maxWidth: .infinity, minHeight: 260, alignment: .topLeading)
        .overlay(
            RoundedRectangle(cornerRadius: GameTheme.largeRadius)
                .stroke(GameTheme.outline.opacity(0.18), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: GameTheme.largeRadius))
        .shadow(color: GameTheme.sectionShadow.opacity(0.75), radius: 10, x: 0, y: 4)
    }
}
