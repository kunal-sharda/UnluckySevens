import SpriteKit
import SwiftUI

struct BoardSceneView: View {
    let renderModel: GameBoardRenderModel
    let overlayModel: GameBoardOverlayModel
    let onTargetTap: ((GameBoardTarget) -> Void)?

    @State private var scene = GameBoardScene(size: CGSize(width: 320, height: 240))
    @State private var cameraState = GameBoardCameraState()
    @State private var dragBaseState: GameBoardCameraState?
    @State private var pinchBaseState: GameBoardCameraState?

    var body: some View {
        GeometryReader { geometry in
            let layout = GameBoardLayout(size: geometry.size, geometry: renderModel.geometry)

            ZStack {
                SpriteView(
                    scene: scene,
                    options: [.allowsTransparency]
                )
                .scaleEffect(cameraState.zoom)
                .offset(cameraState.offset)
                .allowsHitTesting(false)

                Color.clear
                    .contentShape(Rectangle())
                    .simultaneousGesture(dragGesture(viewportSize: geometry.size, contentFrame: layout.contentFrame))
                    .simultaneousGesture(magnificationGesture(viewportSize: geometry.size, contentFrame: layout.contentFrame))
                    .simultaneousGesture(tapGesture(viewportSize: geometry.size))
            }
            .clipped()
            .onAppear {
                scene.update(renderModel: renderModel, size: geometry.size, overlayModel: overlayModel)
            }
            .onChange(of: renderModel) { _, newValue in
                scene.update(renderModel: newValue, size: geometry.size, overlayModel: overlayModel)
                cameraState = GameBoardCameraState(
                    zoom: cameraState.zoom,
                    offset: GameBoardCameraController.clampedOffset(
                        cameraState.offset,
                        zoom: cameraState.zoom,
                        viewportSize: geometry.size,
                        contentFrame: layout.contentFrame
                    )
                )
            }
            .onChange(of: overlayModel) { _, newValue in
                scene.update(renderModel: renderModel, size: geometry.size, overlayModel: newValue)
            }
            .onChange(of: geometry.size) { _, newValue in
                scene.update(renderModel: renderModel, size: newValue, overlayModel: overlayModel)
                let resizedLayout = GameBoardLayout(size: newValue, geometry: renderModel.geometry)
                cameraState = GameBoardCameraState(
                    zoom: cameraState.zoom,
                    offset: GameBoardCameraController.clampedOffset(
                        cameraState.offset,
                        zoom: cameraState.zoom,
                        viewportSize: newValue,
                        contentFrame: resizedLayout.contentFrame
                    )
                )
            }
        }
    }

    private func dragGesture(viewportSize: CGSize, contentFrame: CGRect) -> some Gesture {
        DragGesture(minimumDistance: 4)
            .onChanged { value in
                let base = dragBaseState ?? cameraState
                dragBaseState = base
                cameraState = GameBoardCameraController.applyingDrag(
                    base: base,
                    translation: value.translation,
                    viewportSize: viewportSize,
                    contentFrame: contentFrame
                )
            }
            .onEnded { _ in
                dragBaseState = nil
            }
    }

    private func magnificationGesture(viewportSize: CGSize, contentFrame: CGRect) -> some Gesture {
        MagnificationGesture()
            .onChanged { value in
                let base = pinchBaseState ?? cameraState
                pinchBaseState = base
                cameraState = GameBoardCameraController.applyingMagnification(
                    base: base,
                    magnification: value,
                    viewportSize: viewportSize,
                    contentFrame: contentFrame
                )
            }
            .onEnded { _ in
                pinchBaseState = nil
            }
    }

    private func tapGesture(viewportSize: CGSize) -> some Gesture {
        SpatialTapGesture()
            .onEnded { value in
                guard let target = GameBoardCameraController.hitTarget(
                    at: value.location,
                    state: cameraState,
                    renderModel: renderModel,
                    viewportSize: viewportSize
                ) else {
                    return
                }

                onTargetTap?(target)
            }
    }
}
