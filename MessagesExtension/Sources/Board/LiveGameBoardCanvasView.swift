import SwiftUI
import UIKit

struct LiveGameBoardCanvasView: View {
    let renderModel: GameBoardRenderModel
    let overlayModel: GameBoardOverlayModel
    let interactionMode: GameMode
    let showsIntegratedFrame: Bool
    let contentVerticalOffset: CGFloat
    let frozenBoardImage: UIImage?
    let bottomOcclusionHeight: CGFloat
    let reloadToken: Int
    let onInteractionChanged: ((Bool) -> Void)?
    let onResizeFreezeChanged: ((BoardResizeFreezeState) -> Void)?
    let onFreezeRecoveryReloadRequested: ((String) -> Void)?
    let onTargetTap: ((GameBoardTarget) -> Void)?

    var body: some View {
        GeometryReader { geometry in
            Group {
                    if let frozenBoardImage {
                        Image(uiImage: frozenBoardImage)
                            .resizable()
                            .scaledToFill()
                    } else {
                        BoardSceneView(
                            renderModel: renderModel,
                            overlayModel: overlayModel,
                            interactionMode: interactionMode,
                            bottomOcclusionHeight: bottomOcclusionHeight,
                            reloadToken: reloadToken,
                            onInteractionChanged: onInteractionChanged,
                            onResizeFreezeChanged: onResizeFreezeChanged,
                            onFreezeRecoveryReloadRequested: onFreezeRecoveryReloadRequested,
                            onTargetTap: onTargetTap
                        )
                    }
                }
                .offset(y: contentVerticalOffset)
                .frame(maxWidth: .infinity)
                .frame(height: geometry.size.height)
                .background(Color(uiColor: GameBoardPalette.sceneBackground))
                .clipped()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                showsIntegratedFrame
                    ? Color(uiColor: GameBoardPalette.sceneBackground)
                    : Color.clear
            )
        }
    }

}
