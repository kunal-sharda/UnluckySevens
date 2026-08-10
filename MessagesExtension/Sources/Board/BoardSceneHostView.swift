import SpriteKit
import SwiftUI
import UIKit

extension Notification.Name {
    static let gameBoardPanelOcclusionChanged = Notification.Name(
        "com.unluckysevens.gameBoardPanelOcclusionChanged"
    )
}

@MainActor
enum GameBoardPanelOcclusionController {
    private final class WeakBoardView {
        weak var value: SKView?

        init(_ value: SKView) {
            self.value = value
        }
    }

    private static var activeViews: [WeakBoardView] = []
    private static let overlayTag = 7_072_024
    private static var height: CGFloat = 0

    static func attach(to view: SKView) {
        activeViews.removeAll { $0.value == nil }
        if !activeViews.contains(where: { $0.value === view }) {
            activeViews.append(WeakBoardView(view))
        }
        apply(to: view)
    }

    static func setHeight(_ newHeight: CGFloat) {
        height = max(newHeight, 0)
        activeViews.removeAll { $0.value == nil }
        for boardView in activeViews {
            guard let view = boardView.value else { continue }
            apply(to: view)
        }
    }

    private static func apply(to view: SKView) {
        view.isUserInteractionEnabled = height <= 0
        let overlay: UIView
        if let existing = view.viewWithTag(overlayTag) {
            overlay = existing
        } else {
            let created = UIView(frame: .zero)
            created.tag = overlayTag
            created.isUserInteractionEnabled = false
            created.backgroundColor = UIColor(GameTheme.feltRaised)
            created.layer.cornerRadius = 12
            created.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
            created.layer.masksToBounds = true
            view.addSubview(created)
            overlay = created
        }

        let resolvedHeight = min(height, view.bounds.height)
        overlay.isHidden = resolvedHeight <= 0
        overlay.frame = CGRect(
            x: 0,
            y: view.bounds.height - resolvedHeight,
            width: view.bounds.width,
            height: resolvedHeight
        )
        view.bringSubviewToFront(overlay)
    }
}

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
    let bottomOcclusionHeight: CGFloat
    let onInteractionChanged: ((Bool) -> Void)?
    let onTargetTap: ((GameBoardTarget) -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> SKView {
        let view = SKView(frame: .zero)
#if DEBUG
        view.isAccessibilityElement = true
        view.accessibilityIdentifier = bottomOcclusionHeight > 0
            ? "uls.tabletop.boardHost.occluded"
            : "uls.tabletop.boardHost"
        view.accessibilityLabel = "Live game board host"
        view.accessibilityValue = String(describing: bottomOcclusionHeight)
#endif
        configure(view)
        GameBoardPanelOcclusionController.attach(to: view)
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
            onTargetTap: onTargetTap
        )
        context.coordinator.layoutPanelOcclusion(in: view)
        view.presentScene(scene)
        scene.updateBottomOcclusion(
            height: bottomOcclusionHeight,
            viewportSize: viewportSize
        )
        return view
    }

    func updateUIView(_ uiView: SKView, context: Context) {
        configure(uiView)
        GameBoardPanelOcclusionController.attach(to: uiView)
#if DEBUG
        uiView.accessibilityIdentifier = bottomOcclusionHeight > 0
            ? "uls.tabletop.boardHost.occluded"
            : "uls.tabletop.boardHost"
        uiView.accessibilityValue = String(describing: bottomOcclusionHeight)
#endif
        if uiView.scene !== scene {
            uiView.presentScene(scene)
        }
        scene.updateBottomOcclusion(
            height: bottomOcclusionHeight,
            viewportSize: viewportSize
        )

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
            onTargetTap: onTargetTap
        )
        context.coordinator.layoutPanelOcclusion(in: uiView)
    }

    private func configure(_ view: SKView) {
        view.allowsTransparency = false
        view.isOpaque = true
        view.clipsToBounds = true
        view.layer.masksToBounds = true
        view.backgroundColor = GameBoardPalette.sceneBackground
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
        private var panGestureRecognizer: UIPanGestureRecognizer?
        private var pinchGestureRecognizer: UIPinchGestureRecognizer?
        private var tapGestureRecognizer: UITapGestureRecognizer?
        private var panelOcclusionHeight: CGFloat = 0
        private let panelOcclusionView: UIView = {
            let view = UIView(frame: .zero)
            view.isUserInteractionEnabled = false
            view.backgroundColor = UIColor(GameTheme.feltRaised)
            view.layer.cornerRadius = 12
            view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
            view.layer.masksToBounds = true
            view.isHidden = true
#if DEBUG
            view.isAccessibilityElement = true
            view.accessibilityIdentifier = "uls.tabletop.gameInfoOcclusion"
            view.accessibilityLabel = "Game Information board cover"
#endif
            return view
        }()

        override init() {
            super.init()
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handlePanelOcclusionChanged(_:)),
                name: .gameBoardPanelOcclusionChanged,
                object: nil
            )
        }

        deinit {
            NotificationCenter.default.removeObserver(self)
        }

        func attachGestures(to view: SKView) {
            guard self.view !== view else {
                return
            }

            self.view = view
            if panelOcclusionView.superview !== view {
                panelOcclusionView.removeFromSuperview()
                view.addSubview(panelOcclusionView)
            }
            layoutPanelOcclusion(in: view)

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

        func layoutPanelOcclusion(in view: SKView) {
            let resolvedHeight = min(max(panelOcclusionHeight, 0), view.bounds.height)
            panelOcclusionView.isHidden = resolvedHeight <= 0
            panelOcclusionView.frame = CGRect(
                x: 0,
                y: view.bounds.height - resolvedHeight,
                width: view.bounds.width,
                height: resolvedHeight
            )
            view.bringSubviewToFront(panelOcclusionView)
#if DEBUG
            view.isAccessibilityElement = resolvedHeight <= 0
            view.accessibilityElements = resolvedHeight > 0 ? [panelOcclusionView] : nil
#endif
        }

        @objc
        private func handlePanelOcclusionChanged(_ notification: Notification) {
            let rawHeight = notification.userInfo?["height"]
            let height: CGFloat
            if let number = rawHeight as? NSNumber {
                height = CGFloat(truncating: number)
            } else if let value = rawHeight as? CGFloat {
                height = value
            } else {
                height = 0
            }
            panelOcclusionHeight = height
            guard let view else { return }
            layoutPanelOcclusion(in: view)
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
