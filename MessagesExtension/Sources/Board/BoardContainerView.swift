import SwiftUI

struct BoardContainerView: View {
    let model: GameBoardPlaceholderModel
    let renderModel: GameBoardRenderModel?
    let overlayModel: GameBoardOverlayModel
    let interactionMode: GameMode
    let selectionText: String?
    let onInteractionChanged: ((Bool) -> Void)?
    let onTargetTap: ((GameBoardTarget) -> Void)?

    private var shouldShowBoardHUD: Bool {
        renderModel == nil || interactionMode != .idle || selectionText != nil
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            LinearGradient(
                colors: [
                    GameTheme.water.opacity(0.18),
                    GameTheme.surfaceRaised.opacity(0.90),
                    GameTheme.surface.opacity(0.94),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            boardCanvas

            VStack(alignment: .leading, spacing: 6) {
                if shouldShowBoardHUD {
                    boardHUD
                }

                Spacer(minLength: 0)

                if renderModel == nil {
                    placeholderCopy
                }
            }
            .padding(GameTheme.shellPadding)
            .allowsHitTesting(false)
        }
        .frame(maxWidth: .infinity, minHeight: renderModel == nil ? 260 : 312, alignment: .topLeading)
        .overlay(
            RoundedRectangle(cornerRadius: GameTheme.largeRadius)
                .stroke(GameTheme.outline.opacity(0.18), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: GameTheme.largeRadius))
        .shadow(color: GameTheme.sectionShadow.opacity(0.75), radius: 10, x: 0, y: 4)
    }

    @ViewBuilder
    private var boardCanvas: some View {
        ZStack {
            RoundedRectangle(cornerRadius: GameTheme.largeRadius - 4)
                .fill(GameTheme.water.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: GameTheme.largeRadius - 4)
                        .stroke(GameTheme.outline.opacity(0.10), lineWidth: 1)
                )

            if let renderModel {
                BoardSceneView(
                    renderModel: renderModel,
                    overlayModel: overlayModel,
                    interactionMode: interactionMode,
                    onInteractionChanged: onInteractionChanged,
                    onTargetTap: onTargetTap
                )
                .padding(.horizontal, 10)
                .padding(.vertical, 12)
            } else {
                BoardPlaceholderArtView()
                    .padding(.horizontal, 12)
                    .padding(.vertical, 16)
            }
        }
        .padding(8)
    }

    private var boardHUD: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Label("Board", systemImage: "hexagon")
                    .font(GameTheme.headingFont)
                    .foregroundStyle(GameTheme.ink)

                if interactionMode != .idle && model.title != "Board" {
                    Text(model.title)
                        .font(GameTheme.metaFont.weight(.semibold))
                        .foregroundStyle(GameTheme.accent)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(GameTheme.surface.opacity(0.88))
                        .clipShape(Capsule())
                }

                Spacer(minLength: 0)
            }

            if let selectionText {
                Text(selectionText)
                    .font(GameTheme.metaFont.weight(.semibold))
                    .foregroundStyle(GameTheme.accent)
                    .fixedSize(horizontal: false, vertical: true)
            } else if renderModel == nil, !model.subtitle.isEmpty {
                Text(model.subtitle)
                    .font(GameTheme.metaFont)
                    .foregroundStyle(GameTheme.mutedInk)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, renderModel == nil ? 10 : 8)
        .background(GameTheme.surface.opacity(renderModel == nil ? 0.70 : 0.82))
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
