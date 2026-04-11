import SwiftUI

struct BoardContainerView: View {
    let model: GameBoardPlaceholderModel
    let renderModel: GameBoardRenderModel?
    let overlayModel: GameBoardOverlayModel
    let interactionMode: GameMode
    let selectionText: String?
    let onInteractionChanged: ((Bool) -> Void)?
    let onTargetTap: ((GameBoardTarget) -> Void)?

    private var shouldShowBoardHeader: Bool {
        renderModel != nil || !model.subtitle.isEmpty
    }

    private var boardHintText: String? {
        guard renderModel != nil else {
            return nil
        }
        return selectionText
    }

    var body: some View {
        ZStack {
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
                if shouldShowBoardHeader {
                    boardHeader
                }

                Spacer(minLength: 0)

                if renderModel == nil {
                    placeholderCopy
                }
            }
            .padding(GameTheme.shellPadding)
            .allowsHitTesting(false)

            if let boardHintText {
                VStack {
                    Spacer(minLength: 0)

                    Text(boardHintText)
                        .font(GameTheme.metaFont.weight(.semibold))
                        .foregroundStyle(GameTheme.accent)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .frame(maxWidth: 240)
                        .background(GameTheme.surface.opacity(0.92))
                        .overlay(
                            Capsule()
                                .stroke(GameTheme.outline.opacity(0.14), lineWidth: 1)
                        )
                        .clipShape(Capsule())
                        .padding(.bottom, 24)
                }
                .padding(.horizontal, 24)
                .allowsHitTesting(false)
            }
        }
        .frame(
            maxWidth: .infinity,
            minHeight: renderModel == nil ? 260 : nil,
            alignment: .topLeading
        )
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
                .padding(.horizontal, 4)
                .padding(.vertical, 6)
            } else {
                BoardPlaceholderArtView()
                    .padding(.horizontal, 8)
                    .padding(.vertical, 10)
            }
        }
        .padding(4)
    }

    private var boardHeader: some View {
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
            } else if renderModel == nil, !model.subtitle.isEmpty {
                Text(model.subtitle)
                    .font(GameTheme.metaFont)
                    .foregroundStyle(GameTheme.mutedInk)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)
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
