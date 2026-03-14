import SpriteKit
import SwiftUI

struct BoardSceneView: View {
    let renderModel: GameBoardRenderModel
    @State private var scene = GameBoardScene(size: CGSize(width: 320, height: 240))

    var body: some View {
        GeometryReader { geometry in
            SpriteView(
                scene: scene,
                options: [.allowsTransparency]
            )
            .onAppear {
                scene.update(renderModel: renderModel, size: geometry.size)
            }
            .onChange(of: renderModel) { _, newValue in
                scene.update(renderModel: newValue, size: geometry.size)
            }
            .onChange(of: geometry.size) { _, newValue in
                scene.update(renderModel: renderModel, size: newValue)
            }
        }
        .allowsHitTesting(false)
    }
}
