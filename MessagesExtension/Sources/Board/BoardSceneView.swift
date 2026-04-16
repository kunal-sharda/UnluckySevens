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
    let onTargetTap: ((GameBoardTarget) -> Void)?

    @State private var scene = GameBoardScene(size: CGSize(width: 320, height: 240))
    @State private var interactionController = BoardSceneInteractionController()
    @State private var isBoardInteracting: Bool = false
    @State private var stableBoardReferenceSize: CGSize?
    @State private var largestSettledViewportSize: CGSize?
    @State private var lastViewportUpdateSize: CGSize?
    @State private var isResizeFrozen: Bool = false
    @State private var frozenSnapshot: UIImage?
    @State private var pendingViewportSize: CGSize?
    @State private var pendingRenderModel: GameBoardRenderModel?
    @State private var pendingOverlayModel: GameBoardOverlayModel?
    @State private var resizeFreezeTask: Task<Void, Never>?
    @State private var resizeFreezeWatchdogTask: Task<Void, Never>?
    @State private var resizeFreezeEpoch: Int = 0
    @State private var boardHostReloadGeneration: Int = 0

    private static let referencePromotionThreshold: CGFloat = 24
    private static let resizeFreezeThreshold: CGFloat = 10
    private static let resizeFreezeDelayNanoseconds: UInt64 = 220_000_000
    private static let resizeFreezeWatchdogNanoseconds: UInt64 = 1_200_000_000
    private static let fullExtentFreezeEntryHeightLoss: CGFloat = 88
    private static let fullExtentFreezeExitHeightBand: CGFloat = 40

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
                if !isResizeFrozen {
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

                if let frozenSnapshot {
                    Image(uiImage: frozenSnapshot)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipped()
                        .allowsHitTesting(false)
                        .transition(.opacity)
                }
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
                if isResizeFrozen {
                    scheduleResizeFreezeSettle(epoch: resizeFreezeEpoch)
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
                    scheduleResizeFreezeSettle(epoch: resizeFreezeEpoch)
                    return
                }

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
                if shouldKeepLiveBoard(for: newValue) {
                    if isResizeFrozen {
                        finishResizeFreeze(
                            viewportSize: newValue,
                            renderModel: renderModel,
                            overlayModel: overlayModel,
                            source: "full-extent"
                        )
                    } else {
                        commitViewportState(
                            viewportSize: newValue,
                            renderModel: renderModel,
                            overlayModel: overlayModel
                        )
                    }
                    return
                }

                guard isResizeFrozen || shouldFreezeForResize(to: newValue) else {
                    commitViewportState(
                        viewportSize: newValue,
                        renderModel: renderModel,
                        overlayModel: overlayModel
                    )
                    return
                }

                beginResizeFreeze(
                    viewportSize: newValue,
                    renderModel: renderModel,
                    overlayModel: overlayModel
                )
            }
            .onChange(of: reloadToken) { _, _ in
                guard !isResizeFrozen else {
                    return
                }
                rebuildBoardSurface(
                    viewportSize: geometry.size,
                    renderModel: renderModel,
                    overlayModel: overlayModel,
                    reason: "manual"
                )
            }
            .onDisappear {
                cancelResizeFreeze()
                interactionController.resetInteraction()
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
            resizeFreezeEpoch &+= 1
            interactionController.resetInteraction()
            frozenSnapshot = GameBoardSnapshotRenderer.render(
                renderModel: renderModel,
                overlayModel: overlayModel,
                referenceSize: resolvedReferenceSize(for: lastViewportUpdateSize ?? viewportSize),
                viewportSize: lastViewportUpdateSize ?? viewportSize,
                cameraState: interactionController.cameraState
            )
            onResizeFreezeChanged?(BoardResizeFreezeState(
                isFrozen: true,
                snapshot: frozenSnapshot
            ))
            let detail = diagnosticDetail(
                viewportSize: viewportSize,
                largestSettledViewportSize: largestSettledViewportSize
            )
            onGestureEvent?(HostGestureEvent(kind: .resizeFreezeBegan, detail: detail))
            emitDiagnosticsSnapshot(viewportSize: viewportSize)
            startResizeFreezeWatchdog(epoch: resizeFreezeEpoch)
        }

        scheduleResizeFreezeSettle(epoch: resizeFreezeEpoch)
    }

    private func scheduleResizeFreezeSettle(epoch: Int) {
        resizeFreezeTask?.cancel()
        resizeFreezeTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: Self.resizeFreezeDelayNanoseconds)
            guard !Task.isCancelled, isResizeFrozen, epoch == resizeFreezeEpoch else { return }
            settleFrozenResize()
        }
    }

    private func startResizeFreezeWatchdog(epoch: Int) {
        resizeFreezeWatchdogTask?.cancel()
        resizeFreezeWatchdogTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: Self.resizeFreezeWatchdogNanoseconds)
            guard !Task.isCancelled, isResizeFrozen, epoch == resizeFreezeEpoch else { return }
            settleFrozenResize(source: "watchdog")
        }
    }

    private func cancelResizeFreeze() {
        resizeFreezeTask?.cancel()
        resizeFreezeWatchdogTask?.cancel()
        resizeFreezeTask = nil
        resizeFreezeWatchdogTask = nil
        let wasFrozen = isResizeFrozen
        isResizeFrozen = false
        frozenSnapshot = nil
        pendingViewportSize = nil
        pendingRenderModel = nil
        pendingOverlayModel = nil
        interactionController.resetInteraction()
        if wasFrozen {
            onResizeFreezeChanged?(BoardResizeFreezeState(
                isFrozen: false,
                snapshot: nil
            ))
            let detail = diagnosticDetail(
                viewportSize: lastViewportUpdateSize,
                largestSettledViewportSize: largestSettledViewportSize
            )
            onGestureEvent?(HostGestureEvent(kind: .resizeFreezeEnded, detail: detail))
        }
        emitDiagnosticsSnapshot(viewportSize: lastViewportUpdateSize)
    }

    private func shouldFreezeForResize(to size: CGSize) -> Bool {
        guard !isBoardInteracting else {
            return false
        }

        guard let lastViewportUpdateSize else {
            return false
        }

        let delta = max(
            abs(size.width - lastViewportUpdateSize.width),
            abs(size.height - lastViewportUpdateSize.height)
        )
        guard delta >= Self.resizeFreezeThreshold else {
            return false
        }

        guard let largestSettledViewportSize else {
            return false
        }

        return size.height < (largestSettledViewportSize.height - Self.fullExtentFreezeEntryHeightLoss)
    }

    private func shouldKeepLiveBoard(for viewportSize: CGSize) -> Bool {
        guard !isBoardInteracting else {
            return true
        }

        guard let largestSettledViewportSize else {
            return true
        }

        return viewportSize.height >= (largestSettledViewportSize.height - Self.fullExtentFreezeExitHeightBand)
    }

    private func settleFrozenResize() {
        settleFrozenResize(source: "settle")
    }

    private func settleFrozenResize(source: String) {
        let viewportSize = pendingViewportSize ?? lastViewportUpdateSize ?? stableBoardReferenceSize ?? CGSize(width: 320, height: 240)
        let renderModel = pendingRenderModel ?? self.renderModel
        let overlayModel = pendingOverlayModel ?? self.overlayModel

        finishResizeFreeze(
            viewportSize: viewportSize,
            renderModel: renderModel,
            overlayModel: overlayModel,
            source: source
        )
    }

    private func finishResizeFreeze(
        viewportSize: CGSize,
        renderModel: GameBoardRenderModel,
        overlayModel: GameBoardOverlayModel,
        source: String
    ) {
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
        resizeFreezeTask?.cancel()
        resizeFreezeWatchdogTask?.cancel()
        resizeFreezeTask = nil
        resizeFreezeWatchdogTask = nil
        onResizeFreezeChanged?(BoardResizeFreezeState(
            isFrozen: false,
            snapshot: nil
        ))
        let detail = diagnosticDetail(
            viewportSize: viewportSize,
            largestSettledViewportSize: largestSettledViewportSize
        )
        onGestureEvent?(HostGestureEvent(kind: .resizeFreezeEnded, detail: "\(detail) source=\(source)"))
        rebuildBoardSurface(
            viewportSize: viewportSize,
            renderModel: renderModel,
            overlayModel: overlayModel,
            reason: "freeze-recovery:\(source)"
        )
        emitDiagnosticsSnapshot(viewportSize: viewportSize)
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
                isResizeFrozen: isResizeFrozen,
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
