import SpriteKit
import SwiftUI

struct BoardSceneView: View {
    let renderModel: GameBoardRenderModel
    let overlayModel: GameBoardOverlayModel
    let interactionMode: GameMode
    let onInteractionChanged: ((Bool) -> Void)?
    let onTargetTap: ((GameBoardTarget) -> Void)?

    @State private var scene = GameBoardScene(size: CGSize(width: 320, height: 240))
    @State private var cameraState = GameBoardCameraState()
    @State private var dragBaseState: GameBoardCameraState?
    @State private var pinchBaseState: GameBoardCameraState?
    @State private var isDragInteracting: Bool = false
    @State private var isPinchInteracting: Bool = false
    @State private var isInteracting: Bool = false

    var body: some View {
        GeometryReader { geometry in
            let layout = GameBoardLayout(size: geometry.size, geometry: renderModel.geometry)

            ZStack {
                SpriteView(
                    scene: scene,
                    options: [.allowsTransparency]
                )
                .allowsHitTesting(false)

                Color.clear
                    .contentShape(Rectangle())
                    .highPriorityGesture(dragGesture(viewportSize: geometry.size, contentFrame: layout.contentFrame))
                    .highPriorityGesture(magnificationGesture(viewportSize: geometry.size, contentFrame: layout.contentFrame))
                    .simultaneousGesture(tapGesture(viewportSize: geometry.size))
            }
            .clipped()
            .onAppear {
                scene.updateBase(renderModel: renderModel, size: geometry.size)
                scene.updateOverlay(renderModel: renderModel, size: geometry.size, overlayModel: overlayModel)
                scene.updateCamera(state: cameraState, size: geometry.size)
            }
            .onChange(of: renderModel) { _, newValue in
                scene.updateBase(renderModel: newValue, size: geometry.size)
                scene.updateOverlay(renderModel: newValue, size: geometry.size, overlayModel: overlayModel)
                cameraState = GameBoardCameraState(
                    zoom: cameraState.zoom,
                    offset: GameBoardCameraController.clampedOffset(
                        cameraState.offset,
                        zoom: cameraState.zoom,
                        viewportSize: geometry.size,
                        contentFrame: layout.contentFrame
                    )
                )
                scene.updateCamera(state: cameraState, size: geometry.size)
            }
            .onChange(of: overlayModel) { _, newValue in
                scene.updateOverlay(renderModel: renderModel, size: geometry.size, overlayModel: newValue)
            }
            .onChange(of: geometry.size) { _, newValue in
                scene.updateBase(renderModel: renderModel, size: newValue)
                scene.updateOverlay(renderModel: renderModel, size: newValue, overlayModel: overlayModel)
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
                scene.updateCamera(state: cameraState, size: newValue)
            }
            .onDisappear {
                setInteractionActive(false)
            }
        }
    }

    private func dragGesture(viewportSize: CGSize, contentFrame: CGRect) -> some Gesture {
        DragGesture(minimumDistance: 4)
            .onChanged { value in
                let base = dragBaseState ?? cameraState
                dragBaseState = base
                isDragInteracting = true
                updateInteractionState()
                cameraState = GameBoardCameraController.applyingDrag(
                    base: base,
                    translation: value.translation,
                    viewportSize: viewportSize,
                    contentFrame: contentFrame
                )
                scene.updateCamera(state: cameraState, size: viewportSize)
            }
            .onEnded { _ in
                dragBaseState = nil
                isDragInteracting = false
                updateInteractionState()
            }
    }

    private func magnificationGesture(viewportSize: CGSize, contentFrame: CGRect) -> some Gesture {
        MagnificationGesture()
            .onChanged { value in
                let base = pinchBaseState ?? cameraState
                pinchBaseState = base
                isPinchInteracting = true
                updateInteractionState()
                cameraState = GameBoardCameraController.applyingMagnification(
                    base: base,
                    magnification: value,
                    viewportSize: viewportSize,
                    contentFrame: contentFrame
                )
                scene.updateCamera(state: cameraState, size: viewportSize)
            }
            .onEnded { _ in
                pinchBaseState = nil
                isPinchInteracting = false
                updateInteractionState()
            }
    }

    private func tapGesture(viewportSize: CGSize) -> some Gesture {
        SpatialTapGesture()
            .onEnded { value in
                guard let target = GameBoardCameraController.hitTarget(
                    at: value.location,
                    state: cameraState,
                    renderModel: renderModel,
                    overlayModel: overlayModel,
                    interactionMode: interactionMode,
                    viewportSize: viewportSize
                ) else {
                    return
                }

                onTargetTap?(target)
            }
    }

    private func updateInteractionState() {
        setInteractionActive(isDragInteracting || isPinchInteracting)
    }

    private func setInteractionActive(_ active: Bool) {
        guard isInteracting != active else {
            return
        }

        isInteracting = active
        onInteractionChanged?(active)
    }
}
