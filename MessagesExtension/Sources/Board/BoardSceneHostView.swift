import SpriteKit
import SwiftUI
import UIKit

struct BoardSceneHostView: UIViewRepresentable {
    let scene: GameBoardScene
    let renderModel: GameBoardRenderModel
    let overlayModel: GameBoardOverlayModel
    let interactionMode: GameMode
    let viewportSize: CGSize
    let contentFrame: CGRect
    let boardReferenceSize: CGSize
    let interactionController: BoardSceneInteractionController
    let isInteractionEnabled: Bool
    let onInteractionChanged: ((Bool) -> Void)?
    let onGestureEvent: ((HostGestureEvent) -> Void)?
    let onTargetTap: ((GameBoardTarget) -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> SKView {
        let view = SKView(frame: .zero)
        configure(view)
        context.coordinator.attachGestures(to: view)
        context.coordinator.update(
            scene: scene,
            renderModel: renderModel,
            overlayModel: overlayModel,
            interactionMode: interactionMode,
            viewportSize: viewportSize,
            contentFrame: contentFrame,
            boardReferenceSize: boardReferenceSize,
            interactionController: interactionController,
            isInteractionEnabled: isInteractionEnabled,
            onInteractionChanged: onInteractionChanged,
            onGestureEvent: onGestureEvent,
            onTargetTap: onTargetTap
        )
        view.presentScene(scene)
        return view
    }

    func updateUIView(_ uiView: SKView, context: Context) {
        configure(uiView)
        if uiView.scene !== scene {
            uiView.presentScene(scene)
        }

        context.coordinator.update(
            scene: scene,
            renderModel: renderModel,
            overlayModel: overlayModel,
            interactionMode: interactionMode,
            viewportSize: viewportSize,
            contentFrame: contentFrame,
            boardReferenceSize: boardReferenceSize,
            interactionController: interactionController,
            isInteractionEnabled: isInteractionEnabled,
            onInteractionChanged: onInteractionChanged,
            onGestureEvent: onGestureEvent,
            onTargetTap: onTargetTap
        )
        uiView.isUserInteractionEnabled = isInteractionEnabled
    }

    private func configure(_ view: SKView) {
        view.allowsTransparency = false
        view.isOpaque = true
        view.backgroundColor = GameBoardPalette.water
        view.preferredFramesPerSecond = 60
        view.showsFPS = false
        view.showsNodeCount = false
        view.showsDrawCount = false
    }

    @MainActor
    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        private weak var view: SKView?
        private var scene: GameBoardScene?
        private var renderModel: GameBoardRenderModel?
        private var overlayModel: GameBoardOverlayModel = .empty
        private var interactionMode: GameMode = .idle
        private var viewportSize: CGSize = .zero
        private var contentFrame: CGRect = .zero
        private var boardReferenceSize: CGSize = CGSize(width: 320, height: 240)
        private var interactionController: BoardSceneInteractionController?
        private var isInteractionEnabled = true
        private var onTargetTap: ((GameBoardTarget) -> Void)?
        private var onInteractionChanged: ((Bool) -> Void)?
        private var onGestureEvent: ((HostGestureEvent) -> Void)?
        private var panGestureRecognizer: UIPanGestureRecognizer?
        private var pinchGestureRecognizer: UIPinchGestureRecognizer?
        private var tapGestureRecognizer: UITapGestureRecognizer?

        func attachGestures(to view: SKView) {
            guard self.view !== view else {
                return
            }

            self.view = view

            let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
            pan.delegate = self

            let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
            pinch.delegate = self

            let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
            tap.numberOfTapsRequired = 1
            tap.delegate = self
            tap.require(toFail: pan)
            tap.require(toFail: pinch)

            view.addGestureRecognizer(pan)
            view.addGestureRecognizer(pinch)
            view.addGestureRecognizer(tap)

            panGestureRecognizer = pan
            pinchGestureRecognizer = pinch
            tapGestureRecognizer = tap
        }

        func update(
            scene: GameBoardScene,
            renderModel: GameBoardRenderModel,
            overlayModel: GameBoardOverlayModel,
            interactionMode: GameMode,
            viewportSize: CGSize,
            contentFrame: CGRect,
            boardReferenceSize: CGSize,
            interactionController: BoardSceneInteractionController,
            isInteractionEnabled: Bool,
            onInteractionChanged: ((Bool) -> Void)?,
            onGestureEvent: ((HostGestureEvent) -> Void)?,
            onTargetTap: ((GameBoardTarget) -> Void)?
        ) {
            self.scene = scene
            self.renderModel = renderModel
            self.overlayModel = overlayModel
            self.interactionMode = interactionMode
            self.viewportSize = viewportSize
            self.contentFrame = contentFrame
            self.boardReferenceSize = boardReferenceSize
            self.interactionController = interactionController
            self.isInteractionEnabled = isInteractionEnabled
            self.onInteractionChanged = onInteractionChanged
            self.onGestureEvent = onGestureEvent
            self.onTargetTap = onTargetTap
            interactionController.onInteractionChanged = onInteractionChanged
            view?.isUserInteractionEnabled = isInteractionEnabled
        }

        @objc
        private func handlePan(_ recognizer: UIPanGestureRecognizer) {
            guard isInteractionEnabled,
                  let scene,
                  let interactionController,
                  let view else {
                return
            }

            switch recognizer.state {
            case .began:
                interactionController.beginDrag()
                onGestureEvent?(HostGestureEvent(kind: .boardPanBegan, detail: "viewport=\(Int(viewportSize.width.rounded()))x\(Int(viewportSize.height.rounded()))"))
                fallthrough
            case .changed:
                interactionController.updateDrag(
                    translation: CGSize(width: recognizer.translation(in: view).x, height: recognizer.translation(in: view).y),
                    viewportSize: viewportSize,
                    contentFrame: contentFrame,
                    scene: scene
                )
            case .ended, .cancelled, .failed:
                interactionController.endDrag()
                onGestureEvent?(HostGestureEvent(kind: .boardPanEnded, detail: ""))
            default:
                break
            }
        }

        @objc
        private func handlePinch(_ recognizer: UIPinchGestureRecognizer) {
            guard isInteractionEnabled,
                  let scene,
                  let interactionController else {
                return
            }

            switch recognizer.state {
            case .began:
                interactionController.beginPinch()
                onGestureEvent?(HostGestureEvent(kind: .boardPinchBegan, detail: "viewport=\(Int(viewportSize.width.rounded()))x\(Int(viewportSize.height.rounded()))"))
                fallthrough
            case .changed:
                interactionController.updatePinch(
                    magnification: recognizer.scale,
                    viewportSize: viewportSize,
                    contentFrame: contentFrame,
                    scene: scene
                )
            case .ended, .cancelled, .failed:
                interactionController.endPinch()
                onGestureEvent?(HostGestureEvent(kind: .boardPinchEnded, detail: ""))
            default:
                break
            }
        }

        @objc
        private func handleTap(_ recognizer: UITapGestureRecognizer) {
            guard recognizer.state == .ended,
                  isInteractionEnabled,
                  let interactionController,
                  let renderModel,
                  let onTargetTap else {
                return
            }

            guard let target = interactionController.hitTarget(
                at: recognizer.location(in: recognizer.view),
                renderModel: renderModel,
                overlayModel: overlayModel,
                interactionMode: interactionMode,
                viewportSize: viewportSize,
                boardReferenceSize: boardReferenceSize
            ) else {
                return
            }

            onGestureEvent?(HostGestureEvent(kind: .boardTap, detail: "\(target)"))
            onTargetTap(target)
        }

        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            (gestureRecognizer is UIPanGestureRecognizer && otherGestureRecognizer is UIPinchGestureRecognizer)
                || (gestureRecognizer is UIPinchGestureRecognizer && otherGestureRecognizer is UIPanGestureRecognizer)
        }
    }
}

@MainActor
final class BoardSceneInteractionController {
    private(set) var cameraState = GameBoardCameraState()
    private var dragBaseState: GameBoardCameraState?
    private var pinchBaseState: GameBoardCameraState?
    private var isDragInteracting = false
    private var isPinchInteracting = false
    private var isInteracting = false

    var onInteractionChanged: ((Bool) -> Void)?

    init(cameraState: GameBoardCameraState = GameBoardCameraState()) {
        self.cameraState = cameraState
    }

    func resetInteraction() {
        dragBaseState = nil
        pinchBaseState = nil
        isDragInteracting = false
        isPinchInteracting = false
        updateInteractionState()
    }

    func beginDrag() {
        dragBaseState = dragBaseState ?? cameraState
        isDragInteracting = true
        updateInteractionState()
    }

    func updateDrag(
        translation: CGSize,
        viewportSize: CGSize,
        contentFrame: CGRect,
        scene: GameBoardScene
    ) {
        let base = dragBaseState ?? cameraState
        dragBaseState = base
        isDragInteracting = true
        updateInteractionState()
        cameraState = GameBoardCameraController.applyingDrag(
            base: base,
            translation: translation,
            viewportSize: viewportSize,
            contentFrame: contentFrame
        )
        scene.updateCamera(state: cameraState, viewportSize: viewportSize)
    }

    func endDrag() {
        dragBaseState = nil
        isDragInteracting = false
        updateInteractionState()
    }

    func beginPinch() {
        pinchBaseState = pinchBaseState ?? cameraState
        isPinchInteracting = true
        updateInteractionState()
    }

    func updatePinch(
        magnification: CGFloat,
        viewportSize: CGSize,
        contentFrame: CGRect,
        scene: GameBoardScene
    ) {
        let base = pinchBaseState ?? cameraState
        pinchBaseState = base
        isPinchInteracting = true
        updateInteractionState()
        cameraState = GameBoardCameraController.applyingMagnification(
            base: base,
            magnification: magnification,
            viewportSize: viewportSize,
            contentFrame: contentFrame
        )
        scene.updateCamera(state: cameraState, viewportSize: viewportSize)
    }

    func endPinch() {
        pinchBaseState = nil
        isPinchInteracting = false
        updateInteractionState()
    }

    func clampCameraState(
        viewportSize: CGSize,
        contentFrame: CGRect,
        scene: GameBoardScene
    ) {
        cameraState = GameBoardCameraState(
            zoom: cameraState.zoom,
            offset: GameBoardCameraController.clampedOffset(
                cameraState.offset,
                zoom: cameraState.zoom,
                viewportSize: viewportSize,
                contentFrame: contentFrame
            )
        )
        scene.updateCamera(state: cameraState, viewportSize: viewportSize)
    }

    func hitTarget(
        at location: CGPoint,
        renderModel: GameBoardRenderModel,
        overlayModel: GameBoardOverlayModel,
        interactionMode: GameMode,
        viewportSize: CGSize,
        boardReferenceSize: CGSize
    ) -> GameBoardTarget? {
        GameBoardCameraController.hitTarget(
            at: location,
            state: cameraState,
            renderModel: renderModel,
            overlayModel: overlayModel,
            interactionMode: interactionMode,
            viewportSize: viewportSize,
            boardReferenceSize: boardReferenceSize
        )
    }

    private func updateInteractionState() {
        let active = isDragInteracting || isPinchInteracting
        guard isInteracting != active else {
            return
        }

        isInteracting = active
        onInteractionChanged?(active)
    }
}
