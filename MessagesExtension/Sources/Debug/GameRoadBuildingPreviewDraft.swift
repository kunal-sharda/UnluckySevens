#if DEBUG
import ULS_CoreGame

/// Local-only interaction checkpoint. Core remains the sole legality authority.
struct GameRoadBuildingPreviewDraft: Equatable {
    private(set) var firstEdgeID: EdgeID?
    private(set) var secondEdgeID: EdgeID?
    private(set) var guidance: String?

    var pendingEdgeIDs: [EdgeID] { [firstEdgeID, secondEdgeID].compactMap { $0 } }
    var isReady: Bool { firstEdgeID != nil && secondEdgeID != nil }
    var mode: GameMode { firstEdgeID == nil ? .devCardRoadBuildingFirst : .devCardRoadBuildingSecond }
    var progress: String {
        isReady ? "Review 2 roads" : "Select Road \(firstEdgeID == nil ? 1 : 2) of 2"
    }

    func legalEdges(in state: CoreGameStateV1, actor: String) -> [EdgeID] {
        if let firstEdgeID {
            return state.legalRoadBuildingSecondEdges(for: actor, firstEdgeID: firstEdgeID)
        }
        return state.legalRoadBuildingFirstEdges(for: actor)
    }

    mutating func select(_ edgeID: EdgeID, in state: CoreGameStateV1, actor: String) {
        revalidate(in: state, actor: actor)
        guard legalEdges(in: state, actor: actor).contains(edgeID) else {
            guidance = "Choose a highlighted road."
            return
        }
        if firstEdgeID == nil { firstEdgeID = edgeID } else { secondEdgeID = edgeID }
        guidance = nil
    }

    mutating func undo() {
        if secondEdgeID != nil { secondEdgeID = nil } else { firstEdgeID = nil }
        guidance = nil
    }

    mutating func reset() { self = Self() }

    mutating func revalidate(in state: CoreGameStateV1, actor: String) {
        guard let firstEdgeID else { return }
        guard state.legalRoadBuildingFirstEdges(for: actor).contains(firstEdgeID) else {
            reset()
            guidance = "The board changed. Choose your first road again."
            return
        }
        if let secondEdgeID,
           !state.legalRoadBuildingSecondEdges(for: actor, firstEdgeID: firstEdgeID).contains(secondEdgeID) {
            self.secondEdgeID = nil
            guidance = "The board changed. Choose your second road again."
        }
    }

    /// Produces only a local value for review; this type cannot publish an action.
    mutating func reviewedDraft(in state: CoreGameStateV1, actor: String) -> GameDevCardDraft? {
        revalidate(in: state, actor: actor)
        guard let firstEdgeID, let secondEdgeID else { return nil }
        return .roadBuilding(firstEdgeID: firstEdgeID, secondEdgeID: secondEdgeID)
    }
}
#endif
