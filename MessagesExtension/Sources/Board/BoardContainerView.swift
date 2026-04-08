import SwiftUI

struct BoardContainerView: View {
    let model: GameBoardPlaceholderModel
    let renderModel: GameBoardRenderModel?
    let overlayModel: GameBoardOverlayModel
    let interactionMode: GameMode
    let selectionText: String?
    let onInteractionChanged: ((Bool) -> Void)?
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
                BoardSceneView(
                    renderModel: renderModel,
                    overlayModel: overlayModel,
                    interactionMode: interactionMode,
                    onInteractionChanged: onInteractionChanged,
                    onTargetTap: onTargetTap
                )
                    .padding(.horizontal, 12)
                    .padding(.vertical, 14)
            } else {
                BoardPlaceholderArtView()
                    .padding(.horizontal, 12)
                    .padding(.vertical, 16)
            }

            VStack(alignment: .leading, spacing: 6) {
                boardHUD

                Spacer(minLength: 0)

                if renderModel == nil {
                    placeholderCopy
                }
            }
            .padding(GameTheme.shellPadding)
        }
        .frame(maxWidth: .infinity, minHeight: renderModel == nil ? 260 : 312, alignment: .topLeading)
        .overlay(
            RoundedRectangle(cornerRadius: GameTheme.largeRadius)
                .stroke(GameTheme.outline.opacity(0.18), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: GameTheme.largeRadius))
        .shadow(color: GameTheme.sectionShadow.opacity(0.75), radius: 10, x: 0, y: 4)
    }

    private var boardHUD: some View {
        HStack(spacing: 8) {
            Label("Board", systemImage: "hexagon")
                .font(GameTheme.headingFont)
                .foregroundStyle(GameTheme.ink)

            if model.title != "Board" {
                Text(model.title)
                    .font(GameTheme.metaFont.weight(.semibold))
                    .foregroundStyle(GameTheme.accent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(GameTheme.surface.opacity(0.88))
                    .clipShape(Capsule())
            }

            if let selectionText {
                Label(selectionText, systemImage: "scope")
                    .font(.system(.footnote, design: .rounded).bold())
                    .foregroundStyle(GameTheme.accent)
                    .lineLimit(1)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(GameTheme.surface.opacity(0.88))
                    .clipShape(Capsule())
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(GameTheme.surface.opacity(0.70))
        .overlay(
            RoundedRectangle(cornerRadius: GameTheme.mediumRadius)
                .stroke(GameTheme.outline.opacity(0.10), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: GameTheme.mediumRadius))
    }

    private var placeholderCopy: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(model.title)
                .font(GameTheme.titleFont)
                .foregroundStyle(GameTheme.ink)
                .lineLimit(2)

            Text(model.subtitle)
                .font(GameTheme.metaFont)
                .foregroundStyle(GameTheme.mutedInk)
                .lineLimit(3)
        }
        .padding(GameTheme.compactPadding)
        .background(GameTheme.surface.opacity(0.90))
        .overlay(
            RoundedRectangle(cornerRadius: GameTheme.mediumRadius)
                .stroke(GameTheme.outline.opacity(0.16), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: GameTheme.mediumRadius))
    }
}
