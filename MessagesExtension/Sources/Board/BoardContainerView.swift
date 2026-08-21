import SwiftUI
import UIKit

struct BoardContainerView: View {
    let model: GameBoardPlaceholderModel
    let renderModel: GameBoardRenderModel?
    let overlayModel: GameBoardOverlayModel
    let interactionMode: GameMode
    let selectionText: String?
    let hintBottomInset: CGFloat
    let showsCreamFrame: Bool
    let boardContentVerticalOffset: CGFloat
    var bottomOcclusionHeight: CGFloat = 0
    let reloadToken: Int
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
            GameTheme.felt.opacity(0.001)

            boardCanvas

            if renderModel == nil {
                placeholderCopy
                    .padding(GameTheme.shellPadding)
                    .allowsHitTesting(false)
            }

            if let boardHintText, shouldShowBoardHint {
                VStack {
                    Spacer(minLength: 0)

                    Text(boardHintText)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(GameTheme.accent)
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .frame(maxWidth: 180)
                        .background(GameTheme.surface.opacity(0.92))
                        .overlay(
                            Capsule()
                                .stroke(GameTheme.outline.opacity(0.14), lineWidth: 1)
                        )
                        .clipShape(Capsule())
                        .padding(.bottom, hintBottomInset)
                }
                .padding(.horizontal, 20)
                .allowsHitTesting(false)
            }
        }
        .frame(
            maxWidth: .infinity,
            minHeight: renderModel == nil ? 260 : nil,
            alignment: .topLeading
        )
        .background(outerBackground)
        .overlay(outerOverlay)
        .clipShape(RoundedRectangle(cornerRadius: GameTheme.largeRadius + 8))
        .shadow(
            color: showsCreamFrame ? .black.opacity(0.28) : .clear,
            radius: showsCreamFrame ? 11 : 0,
            x: 0,
            y: showsCreamFrame ? 4 : 0
        )
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("uls.tabletop.board")
    }

    @ViewBuilder
    private var boardCanvas: some View {
        ZStack {
            if let renderModel {
                LiveGameBoardCanvasView(
                    renderModel: renderModel,
                    overlayModel: overlayModel,
                    interactionMode: interactionMode,
                    showsIntegratedFrame: showsCreamFrame,
                    contentVerticalOffset: boardContentVerticalOffset,
                    bottomOcclusionHeight: bottomOcclusionHeight,
                    reloadToken: reloadToken,
                    onInteractionChanged: onInteractionChanged,
                    onTargetTap: onTargetTap
                )
            } else {
                BoardPlaceholderArtView()
                    .padding(.horizontal, 8)
                    .padding(.vertical, 10)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: boardCanvasCornerRadius))
        .padding(boardCanvasPadding)
        .background(
            RoundedRectangle(cornerRadius: GameTheme.largeRadius + 8)
                .fill(boardFrameColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: GameTheme.largeRadius + 8)
                .stroke(boardFrameStrokeColor, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: GameTheme.largeRadius + 8))
    }

    private var boardCanvasCornerRadius: CGFloat {
        showsCreamFrame ? GameTheme.largeRadius : GameTheme.largeRadius + 8
    }

    private var boardCanvasPadding: CGFloat {
        renderModel != nil && showsCreamFrame ? 7 : 0
    }

    private var boardFrameColor: Color {
        guard renderModel != nil, showsCreamFrame else {
            return .clear
        }
        return GameTheme.boardFrame
    }

    private var boardFrameStrokeColor: Color {
        guard renderModel != nil, showsCreamFrame else {
            return .clear
        }
        return GameTheme.outline.opacity(0.56)
    }

    @ViewBuilder
    private var outerBackground: some View {
        if showsCreamFrame {
            RoundedRectangle(cornerRadius: GameTheme.largeRadius + 8)
                .fill(GameTheme.feltRaised.opacity(0.78))
        } else {
            Color.clear
        }
    }

    @ViewBuilder
    private var outerOverlay: some View {
        if showsCreamFrame {
            RoundedRectangle(cornerRadius: GameTheme.largeRadius + 8)
                .stroke(GameTheme.surface.opacity(0.18), lineWidth: 1)
        } else {
            Color.clear
        }
    }

    private var shouldShowBoardHint: Bool {
        switch interactionMode {
        case .setup:
            return false
        default:
            return true
        }
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
