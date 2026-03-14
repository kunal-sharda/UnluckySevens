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
        let frame = CGRect(origin: .zero, size: size)

        let scene = GameBoardScene(size: size)
        scene.scaleMode = .resizeFill
        scene.update(renderModel: renderModel, size: size, overlayModel: overlayModel)

        let view = SKView(frame: frame)
        view.allowsTransparency = true
        view.isOpaque = false
        view.preferredFramesPerSecond = 60
        view.presentScene(scene)
        view.layoutIfNeeded()

        guard let texture = view.texture(from: scene, crop: frame) else {
            return nil
        }

        let cgImage = texture.cgImage()
        let scale = max(
            CGFloat(cgImage.width) / max(size.width, 1),
            CGFloat(cgImage.height) / max(size.height, 1),
            1
        )
        return UIImage(cgImage: cgImage, scale: scale, orientation: .up)
    }
}
