import SpriteKit
import SwiftUI
import UIKit

struct BoardSceneView: View, Equatable {
    let renderModel: GameBoardRenderModel
    let overlayModel: GameBoardOverlayModel
    let interactionMode: GameMode
    let reloadToken: Int
    let onInteractionChanged: ((Bool) -> Void)?
    let onDiagnosticsChanged: ((BoardInteractionDiagnosticsSnapshot) -> Void)?
    let onGestureEvent: ((HostGestureEvent) -> Void)?
    let onResizeFreezeChanged: ((BoardResizeFreezeState) -> Void)?
    let onFreezeRecoveryReloadRequested: ((String) -> Void)?
    let onTargetTap: ((GameBoardTarget) -> Void)?

    @State private var scene = GameBoardScene(size: CGSize(width: 320, height: 240))
    @State private var interactionController = BoardSceneInteractionController()
    @State private var isBoardInteracting: Bool = false
    @State private var stableBoardReferenceSize: CGSize?
    @State private var largestSettledViewportSize: CGSize?
    @State private var lastViewportUpdateSize: CGSize?
    @State private var pendingViewportSize: CGSize?
    @State private var pendingRenderModel: GameBoardRenderModel?
    @State private var pendingOverlayModel: GameBoardOverlayModel?
    @State private var resizeSettleTask: Task<Void, Never>?
    @State private var boardHostReloadGeneration: Int = 0

    private static let referencePromotionThreshold: CGFloat = 24
    private static let resizeSettleDelayNanoseconds: UInt64 = 180_000_000

    static func == (lhs: BoardSceneView, rhs: BoardSceneView) -> Bool {
        lhs.renderModel == rhs.renderModel
            && lhs.overlayModel == rhs.overlayModel
            && lhs.interactionMode == rhs.interactionMode
            && lhs.reloadToken == rhs.reloadToken
    }

    var body: some View {
        GeometryReader { geometry in
            let referenceSize = resolvedReferenceSize(for: geometry.size)
            let layout = GameBoardLayout(size: referenceSize, geometry: renderModel.geometry)

            ZStack {
                BoardSceneHostView(
                    scene: scene,
                    renderModel: renderModel,
                    overlayModel: overlayModel,
                    interactionMode: interactionMode,
                    viewportSize: geometry.size,
                    contentFrame: layout.contentFrame,
                    boardReferenceSize: referenceSize,
                    interactionController: interactionController,
                    isInteractionEnabled: true,
                    onInteractionChanged: { active in
                        isBoardInteracting = active
                        onInteractionChanged?(active)
                        emitDiagnosticsSnapshot(viewportSize: geometry.size)
                    },
                    onGestureEvent: onGestureEvent,
                    onTargetTap: onTargetTap
                )
                .id("board-host-\(reloadToken)-\(boardHostReloadGeneration)")
            }
            .clipped()
            .onAppear {
                if stableBoardReferenceSize == nil {
                    stableBoardReferenceSize = geometry.size
                }
                if largestSettledViewportSize == nil {
                    largestSettledViewportSize = geometry.size
                }
                let referenceSize = resolvedReferenceSize(for: geometry.size)
                applySceneUpdate(
                    renderModel: renderModel,
                    overlayModel: overlayModel,
                    referenceSize: referenceSize,
                    viewportSize: geometry.size
                )
                lastViewportUpdateSize = geometry.size
                emitDiagnosticsSnapshot(viewportSize: geometry.size)
            }
            .onChange(of: renderModel) { _, newValue in
                pendingRenderModel = newValue
                commitViewportState(
                    viewportSize: geometry.size,
                    renderModel: newValue,
                    overlayModel: overlayModel
                )
            }
            .onChange(of: overlayModel) { _, newValue in
                pendingOverlayModel = newValue
                let referenceSize = resolvedReferenceSize(for: geometry.size)
                scene.updateOverlay(
                    renderModel: renderModel,
                    referenceSize: referenceSize,
                    viewportSize: geometry.size,
                    overlayModel: newValue
                )
                emitDiagnosticsSnapshot(viewportSize: geometry.size)
            }
            .onChange(of: geometry.size) { _, newValue in
                handleLiveViewportResize(
                    viewportSize: newValue,
                    renderModel: renderModel,
                    overlayModel: overlayModel
                )
            }
            .onChange(of: reloadToken) { _, _ in
                rebuildBoardSurface(
                    viewportSize: geometry.size,
                    renderModel: renderModel,
                    overlayModel: overlayModel,
                    reason: "manual"
                )
            }
            .onDisappear {
                cancelResizeSettle()
                interactionController.resetInteraction()
            }
        }
    }

    private func handleLiveViewportResize(
        viewportSize: CGSize,
        renderModel: GameBoardRenderModel,
        overlayModel: GameBoardOverlayModel
    ) {
        pendingViewportSize = viewportSize
        pendingRenderModel = renderModel
        pendingOverlayModel = overlayModel

        let referenceSize = resolvedReferenceSize(for: viewportSize)
        let referenceLayout = GameBoardLayout(size: referenceSize, geometry: renderModel.geometry)
        scene.updateViewport(viewportSize: viewportSize)
        interactionController.clampCameraState(
            viewportSize: viewportSize,
            contentFrame: referenceLayout.contentFrame,
            scene: scene
        )
        emitDiagnosticsSnapshot(viewportSize: viewportSize)
        scheduleResizeSettle()
    }

    private func scheduleResizeSettle() {
        resizeSettleTask?.cancel()
        resizeSettleTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: Self.resizeSettleDelayNanoseconds)
            guard !Task.isCancelled else { return }
            settleViewportResize()
        }
    }

    private func settleViewportResize() {
        let viewportSize = pendingViewportSize ?? lastViewportUpdateSize ?? stableBoardReferenceSize ?? CGSize(width: 320, height: 240)
        let renderModel = pendingRenderModel ?? self.renderModel
        let overlayModel = pendingOverlayModel ?? self.overlayModel
        pendingViewportSize = nil
        pendingRenderModel = nil
        pendingOverlayModel = nil
        resizeSettleTask?.cancel()
        resizeSettleTask = nil
        commitViewportState(
            viewportSize: viewportSize,
            renderModel: renderModel,
            overlayModel: overlayModel
        )
    }

    private func cancelResizeSettle() {
        resizeSettleTask?.cancel()
        resizeSettleTask = nil
        pendingViewportSize = nil
        pendingRenderModel = nil
        pendingOverlayModel = nil
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
        interactionController.clampCameraState(
            viewportSize: viewportSize,
            contentFrame: referenceLayout.contentFrame,
            scene: scene
        )
        lastViewportUpdateSize = viewportSize
        largestSettledViewportSize = promotedLargestSettledViewportSize(with: viewportSize)
        emitDiagnosticsSnapshot(viewportSize: viewportSize)
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
        scene.updateCamera(state: interactionController.cameraState, viewportSize: viewportSize)
    }

    private func rebuildBoardSurface(
        viewportSize: CGSize,
        renderModel: GameBoardRenderModel,
        overlayModel: GameBoardOverlayModel,
        reason: String
    ) {
        let preservedCameraState = interactionController.cameraState
        let rebuiltScene = GameBoardScene(size: viewportSize)
        let rebuiltInteractionController = BoardSceneInteractionController(cameraState: preservedCameraState)
        rebuiltInteractionController.onInteractionChanged = onInteractionChanged
        scene = rebuiltScene
        interactionController = rebuiltInteractionController
        boardHostReloadGeneration &+= 1

        let referenceSize = resolvedReferenceSize(for: viewportSize)
        rebuiltScene.updateBase(
            renderModel: renderModel,
            referenceSize: referenceSize,
            viewportSize: viewportSize
        )
        rebuiltScene.updateOverlay(
            renderModel: renderModel,
            referenceSize: referenceSize,
            viewportSize: viewportSize,
            overlayModel: overlayModel
        )
        let referenceLayout = GameBoardLayout(size: referenceSize, geometry: renderModel.geometry)
        rebuiltInteractionController.clampCameraState(
            viewportSize: viewportSize,
            contentFrame: referenceLayout.contentFrame,
            scene: rebuiltScene
        )
        onGestureEvent?(
            HostGestureEvent(
                kind: .boardSurfaceReloaded,
                detail: "\(reason) viewport=\(describe(size: viewportSize))"
            )
        )
    }

    private func emitDiagnosticsSnapshot(viewportSize: CGSize?) {
        onDiagnosticsChanged?(
            BoardInteractionDiagnosticsSnapshot(
                isBoardInteracting: isBoardInteracting,
                isResizeFrozen: false,
                viewportSize: viewportSize ?? lastViewportUpdateSize,
                largestSettledViewportSize: largestSettledViewportSize
            )
        )
    }

    private func diagnosticDetail(
        viewportSize: CGSize?,
        largestSettledViewportSize: CGSize?
    ) -> String {
        "viewport=\(describe(size: viewportSize)) largest=\(describe(size: largestSettledViewportSize))"
    }

    private func describe(size: CGSize?) -> String {
        guard let size else {
            return "-"
        }

        return "\(Int(size.width.rounded()))x\(Int(size.height.rounded()))"
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

    private func promotedLargestSettledViewportSize(with viewportSize: CGSize) -> CGSize {
        guard let largestSettledViewportSize else {
            return viewportSize
        }

        return CGSize(
            width: max(largestSettledViewportSize.width, viewportSize.width),
            height: max(largestSettledViewportSize.height, viewportSize.height)
        )
    }
}
