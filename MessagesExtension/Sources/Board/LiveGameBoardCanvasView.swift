import SwiftUI
import UIKit

struct LiveGameBoardCanvasView: View {
    let renderModel: GameBoardRenderModel
    let overlayModel: GameBoardOverlayModel
    let interactionMode: GameMode
    let bankTray: GameBankTrayModel
    let showsTabletopRack: Bool
    let showsBankCounts: Bool
    let isBankOpen: Bool
    let devDeckCount: Int
    let isDevDeckEnabled: Bool
    let showsIntegratedFrame: Bool
    let contentVerticalOffset: CGFloat
    let frozenBoardImage: UIImage?
    let bottomOcclusionHeight: CGFloat
    let reloadToken: Int
    let onInteractionChanged: ((Bool) -> Void)?
    let onResizeFreezeChanged: ((BoardResizeFreezeState) -> Void)?
    let onFreezeRecoveryReloadRequested: ((String) -> Void)?
    let onTargetTap: ((GameBoardTarget) -> Void)?
    let onOpenBank: () -> Void
    let onOpenDevCards: () -> Void

    var body: some View {
        GeometryReader { geometry in
            let rackHeight = showsTabletopRack ? Self.tabletopRackHeight(for: geometry.size) : 0
            let boardHeight = max(geometry.size.height - rackHeight, 0)

            VStack(spacing: 0) {
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
                .frame(height: boardHeight)
                .background(Color(uiColor: GameBoardPalette.sceneBackground))
                .clipped()

                if showsTabletopRack {
                    GameTabletopBankRackView(
                        model: bankTray,
                        showsBankCounts: showsBankCounts,
                        isBankOpen: isBankOpen,
                        devDeckCount: devDeckCount,
                        isDevDeckEnabled: isDevDeckEnabled,
                        onOpenBank: onOpenBank,
                        onOpenDevCards: onOpenDevCards
                    )
                    .frame(height: rackHeight, alignment: .center)
                    .frame(maxWidth: .infinity)
                    .background(showsIntegratedFrame ? GameTheme.felt : Color.clear)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                showsIntegratedFrame
                    ? Color(uiColor: GameBoardPalette.sceneBackground)
                    : Color.clear
            )
        }
    }

    static func tabletopRackHeight(for size: CGSize) -> CGFloat {
        min(max(size.height * 0.16, 88), 100)
    }
}
