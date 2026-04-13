import SpriteKit
import SwiftUI
import UIKit

struct BoardSceneView: View, Equatable {
    let renderModel: GameBoardRenderModel
    let overlayModel: GameBoardOverlayModel
    let interactionMode: GameMode
    let onInteractionChanged: ((Bool) -> Void)?
    let onResizeFreezeChanged: ((Bool) -> Void)?
    let onTargetTap: ((GameBoardTarget) -> Void)?

    @State private var scene = GameBoardScene(size: CGSize(width: 320, height: 240))
    @State private var cameraState = GameBoardCameraState()
    @State private var dragBaseState: GameBoardCameraState?
    @State private var pinchBaseState: GameBoardCameraState?
    @State private var isDragInteracting: Bool = false
    @State private var isPinchInteracting: Bool = false
    @State private var isInteracting: Bool = false
    @State private var stableBoardReferenceSize: CGSize?
    @State private var lastViewportUpdateSize: CGSize?
    @State private var isResizeFrozen: Bool = false
    @State private var frozenSnapshot: UIImage?
    @State private var pendingViewportSize: CGSize?
    @State private var pendingRenderModel: GameBoardRenderModel?
    @State private var pendingOverlayModel: GameBoardOverlayModel?
    @State private var resizeFreezeTask: Task<Void, Never>?

    private static let referencePromotionThreshold: CGFloat = 24
    private static let resizeFreezeThreshold: CGFloat = 10
    private static let resizeFreezeDelayNanoseconds: UInt64 = 220_000_000

    static func == (lhs: BoardSceneView, rhs: BoardSceneView) -> Bool {
        lhs.renderModel == rhs.renderModel
            && lhs.overlayModel == rhs.overlayModel
            && lhs.interactionMode == rhs.interactionMode
    }

    var body: some View {
        GeometryReader { geometry in
            let referenceSize = resolvedReferenceSize(for: geometry.size)
            let layout = GameBoardLayout(size: referenceSize, geometry: renderModel.geometry)

            ZStack {
                SpriteView(
                    scene: scene,
                    options: [.allowsTransparency]
                )
                .allowsHitTesting(false)

                if let frozenSnapshot {
                    Image(uiImage: frozenSnapshot)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipped()
                        .transition(.opacity)
                }

                Color.clear
                    .contentShape(Rectangle())
                    .allowsHitTesting(!isResizeFrozen)
                    .gesture(
                        dragGesture(viewportSize: geometry.size, contentFrame: layout.contentFrame)
                            .simultaneously(with: magnificationGesture(viewportSize: geometry.size, contentFrame: layout.contentFrame))
                    )
                    .simultaneousGesture(tapGesture(viewportSize: geometry.size))
            }
            .clipped()
            .onAppear {
                if stableBoardReferenceSize == nil {
                    stableBoardReferenceSize = geometry.size
                }
                let referenceSize = resolvedReferenceSize(for: geometry.size)
                applySceneUpdate(
                    renderModel: renderModel,
                    overlayModel: overlayModel,
                    referenceSize: referenceSize,
                    viewportSize: geometry.size
                )
                lastViewportUpdateSize = geometry.size
            }
            .onChange(of: renderModel) { _, newValue in
                pendingRenderModel = newValue
                if isResizeFrozen {
                    scheduleResizeFreezeSettle()
                    return
                }

                commitViewportState(
                    viewportSize: geometry.size,
                    renderModel: newValue,
                    overlayModel: overlayModel
                )
            }
            .onChange(of: overlayModel) { _, newValue in
                pendingOverlayModel = newValue
                if isResizeFrozen {
                    scheduleResizeFreezeSettle()
                    return
                }

                let referenceSize = resolvedReferenceSize(for: geometry.size)
                scene.updateOverlay(
                    renderModel: renderModel,
                    referenceSize: referenceSize,
                    viewportSize: geometry.size,
                    overlayModel: newValue
                )
            }
            .onChange(of: geometry.size) { _, newValue in
                guard isResizeFrozen || shouldFreezeForResize(to: newValue) else {
                    return
                }

                beginResizeFreeze(
                    viewportSize: newValue,
                    renderModel: renderModel,
                    overlayModel: overlayModel
                )
            }
            .onDisappear {
                cancelResizeFreeze()
                setInteractionActive(false)
            }
        }
    }

    private func beginResizeFreeze(
        viewportSize: CGSize,
        renderModel: GameBoardRenderModel,
        overlayModel: GameBoardOverlayModel
    ) {
        pendingViewportSize = viewportSize
        pendingRenderModel = renderModel
        pendingOverlayModel = overlayModel

        if !isResizeFrozen {
            isResizeFrozen = true
            setInteractionActive(false)
            onResizeFreezeChanged?(true)
            frozenSnapshot = GameBoardSnapshotRenderer.render(
                renderModel: renderModel,
                overlayModel: overlayModel,
                referenceSize: resolvedReferenceSize(for: lastViewportUpdateSize ?? viewportSize),
                viewportSize: lastViewportUpdateSize ?? viewportSize,
                cameraState: cameraState
            )
        }

        scheduleResizeFreezeSettle()
    }

    private func scheduleResizeFreezeSettle() {
        resizeFreezeTask?.cancel()
        resizeFreezeTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: Self.resizeFreezeDelayNanoseconds)
            guard !Task.isCancelled else { return }
            settleFrozenResize()
        }
    }

    private func cancelResizeFreeze() {
        resizeFreezeTask?.cancel()
        resizeFreezeTask = nil
        isResizeFrozen = false
        frozenSnapshot = nil
        pendingViewportSize = nil
        pendingRenderModel = nil
        pendingOverlayModel = nil
    }

    private func shouldFreezeForResize(to size: CGSize) -> Bool {
        guard let lastViewportUpdateSize else {
            return false
        }

        return max(
            abs(size.width - lastViewportUpdateSize.width),
            abs(size.height - lastViewportUpdateSize.height)
        ) >= Self.resizeFreezeThreshold
    }

    private func settleFrozenResize() {
        let viewportSize = pendingViewportSize ?? lastViewportUpdateSize ?? stableBoardReferenceSize ?? CGSize(width: 320, height: 240)
        let renderModel = pendingRenderModel ?? self.renderModel
        let overlayModel = pendingOverlayModel ?? self.overlayModel

        commitViewportState(
            viewportSize: viewportSize,
            renderModel: renderModel,
            overlayModel: overlayModel
        )

        isResizeFrozen = false
        frozenSnapshot = nil
        pendingViewportSize = nil
        pendingRenderModel = nil
        pendingOverlayModel = nil
        resizeFreezeTask = nil
        onResizeFreezeChanged?(false)
    }

    private func commitViewportState(
        viewportSize: CGSize,
        renderModel: GameBoardRenderModel,
        overlayModel: GameBoardOverlayModel
    ) {
        let referenceSize = shouldPromoteReferenceSize(to: viewportSize)
            ? promotedReferenceSize(for: viewportSize)
            : resolvedReferenceSize(for: viewportSize)
        stableBoardReferenceSize = referenceSize
        applySceneUpdate(
            renderModel: renderModel,
            overlayModel: overlayModel,
            referenceSize: referenceSize,
            viewportSize: viewportSize
        )
        let referenceLayout = GameBoardLayout(
            size: referenceSize,
            geometry: renderModel.geometry
        )
        cameraState = GameBoardCameraState(
            zoom: cameraState.zoom,
            offset: GameBoardCameraController.clampedOffset(
                cameraState.offset,
                zoom: cameraState.zoom,
                viewportSize: viewportSize,
                contentFrame: referenceLayout.contentFrame
            )
        )
        scene.updateCamera(state: cameraState, viewportSize: viewportSize)
        lastViewportUpdateSize = viewportSize
    }

    private func applySceneUpdate(
        renderModel: GameBoardRenderModel,
        overlayModel: GameBoardOverlayModel,
        referenceSize: CGSize,
        viewportSize: CGSize
    ) {
        scene.updateBase(
            renderModel: renderModel,
            referenceSize: referenceSize,
            viewportSize: viewportSize
        )
        scene.updateOverlay(
            renderModel: renderModel,
            referenceSize: referenceSize,
            viewportSize: viewportSize,
            overlayModel: overlayModel
        )
        scene.updateCamera(state: cameraState, viewportSize: viewportSize)
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
                scene.updateCamera(state: cameraState, viewportSize: viewportSize)
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
                scene.updateCamera(state: cameraState, viewportSize: viewportSize)
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
                guard !isResizeFrozen else {
                    return
                }
                guard let target = GameBoardCameraController.hitTarget(
                    at: value.location,
                    state: cameraState,
                    renderModel: renderModel,
                    overlayModel: overlayModel,
                    interactionMode: interactionMode,
                    viewportSize: viewportSize,
                    boardReferenceSize: resolvedReferenceSize(for: viewportSize)
                ) else {
                    return
                }

                onTargetTap?(target)
            }
    }

    private func updateInteractionState() {
        setInteractionActive((isDragInteracting || isPinchInteracting) && !isResizeFrozen)
    }

    private func setInteractionActive(_ active: Bool) {
        guard isInteracting != active else {
            return
        }

        isInteracting = active
        onInteractionChanged?(active)
    }

    private func resolvedReferenceSize(for viewportSize: CGSize) -> CGSize {
        stableBoardReferenceSize ?? viewportSize
    }

    private func shouldPromoteReferenceSize(to viewportSize: CGSize) -> Bool {
        guard let stableBoardReferenceSize else {
            return true
        }

        return viewportSize.width > (stableBoardReferenceSize.width + Self.referencePromotionThreshold)
            || viewportSize.height > (stableBoardReferenceSize.height + Self.referencePromotionThreshold)
    }

    private func promotedReferenceSize(for viewportSize: CGSize) -> CGSize {
        guard let stableBoardReferenceSize else {
            return viewportSize
        }

        return CGSize(
            width: max(stableBoardReferenceSize.width, viewportSize.width),
            height: max(stableBoardReferenceSize.height, viewportSize.height)
        )
    }
}
