import SceneKit
import SwiftUI

struct GameDiceBowlSceneView: UIViewRepresentable {
    let result: GameDiceRollResult
    let isActive: Bool
    let isSettled: Bool
    let onAnimationFinished: () -> Void

    func makeCoordinator() -> GameDiceBowlSceneController {
        GameDiceBowlSceneController()
    }

    func makeUIView(context: Context) -> SCNView {
        context.coordinator.makeView(
            result: result,
            onAnimationFinished: onAnimationFinished
        )
    }

    func updateUIView(_ view: SCNView, context: Context) {
        context.coordinator.setActive(
            isActive,
            result: result,
            onAnimationFinished: onAnimationFinished
        )
        if isSettled {
            context.coordinator.settle(result: result)
        }
    }
}
