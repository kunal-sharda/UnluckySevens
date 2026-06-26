import SpriteKit
import UIKit

@MainActor
enum GameBoardSnapshotRenderer {
    static func render(
        renderModel: GameBoardRenderModel,
        overlayModel: GameBoardOverlayModel = .empty,
        variant: GameBoardSnapshotVariant
    ) -> UIImage? {
        let size = variant.canvasSize
        return render(
            renderModel: renderModel,
            overlayModel: overlayModel,
            referenceSize: size,
            viewportSize: size,
            cameraState: .init()
        )
    }

    static func render(
        renderModel: GameBoardRenderModel,
        overlayModel: GameBoardOverlayModel = .empty,
        referenceSize: CGSize,
        viewportSize: CGSize,
        cameraState: GameBoardCameraState
    ) -> UIImage? {
        let frame = CGRect(origin: .zero, size: viewportSize)
        let scene = GameBoardScene(size: viewportSize)
        scene.scaleMode = .resizeFill
        scene.update(
            renderModel: renderModel,
            referenceSize: referenceSize,
            viewportSize: viewportSize,
            overlayModel: overlayModel
        )
        scene.updateCamera(state: cameraState, viewportSize: viewportSize)

        let view = SKView(frame: frame)
        view.allowsTransparency = false
        view.isOpaque = true
        view.backgroundColor = GameBoardPalette.sceneBackground
        view.preferredFramesPerSecond = 60
        view.presentScene(scene)
        view.layoutIfNeeded()

        guard let texture = view.texture(from: scene, crop: frame) else {
            return nil
        }

        let cgImage = texture.cgImage()
        let scale = max(
            CGFloat(cgImage.width) / max(viewportSize.width, 1),
            CGFloat(cgImage.height) / max(viewportSize.height, 1),
            1
        )
        return UIImage(cgImage: cgImage, scale: scale, orientation: .up)
    }
}
