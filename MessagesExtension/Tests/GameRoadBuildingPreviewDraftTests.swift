#if DEBUG
@testable import MessagesExtensionSupport
import ULS_CoreGame
import XCTest

final class GameRoadBuildingPreviewDraftTests: XCTestCase {
    private func fixture() throws -> UXTestFixture {
        try XCTUnwrap(UXTestFixtures.all.first { $0.id == "preview-road-building" })
    }

    func testSelectionsStayLocalAndUseDependentCoreLegality() throws {
        let fixture = try fixture()
        let state = fixture.state
        let actor = fixture.defaultActorID
        let originalHash = state.stateHash
        var draft = GameRoadBuildingPreviewDraft()
        XCTAssertEqual(draft.legalEdges(in: state, actor: actor), state.legalRoadBuildingFirstEdges(for: actor))
        let first = try XCTUnwrap(draft.legalEdges(in: state, actor: actor).first)
        draft.select(first, in: state, actor: actor)
        XCTAssertEqual(draft.pendingEdgeIDs, [first])
        XCTAssertFalse(draft.isReady)
        XCTAssertNil(draft.reviewedDraft(in: state, actor: actor))
        XCTAssertEqual(draft.legalEdges(in: state, actor: actor), state.legalRoadBuildingSecondEdges(for: actor, firstEdgeID: first))
        let second = try XCTUnwrap(draft.legalEdges(in: state, actor: actor).first)
        draft.select(second, in: state, actor: actor)
        XCTAssertEqual(draft.pendingEdgeIDs, [first, second])
        XCTAssertTrue(draft.isReady)
        XCTAssertEqual(draft.reviewedDraft(in: state, actor: actor), .roadBuilding(firstEdgeID: first, secondEdgeID: second))
        XCTAssertEqual(state.stateHash, originalHash)
        XCTAssertNil(state.roadsByEdge[first])
        XCTAssertNil(state.roadsByEdge[second])
    }

    func testReplaceUndoAndCancelDoNotConsumeCard() throws {
        let fixture = try fixture()
        let state = fixture.state
        let actor = fixture.defaultActorID
        var draft = GameRoadBuildingPreviewDraft()
        let first = try XCTUnwrap(draft.legalEdges(in: state, actor: actor).first)
        draft.select(first, in: state, actor: actor)
        let seconds = draft.legalEdges(in: state, actor: actor)
        XCTAssertGreaterThan(seconds.count, 1)
        draft.select(seconds[0], in: state, actor: actor)
        draft.select(seconds[1], in: state, actor: actor)
        XCTAssertEqual(draft.secondEdgeID, seconds[1])
        draft.undo()
        XCTAssertEqual(draft.pendingEdgeIDs, [first])
        draft.undo()
        XCTAssertTrue(draft.pendingEdgeIDs.isEmpty)
        draft.select(first, in: state, actor: actor)
        draft.reset()
        XCTAssertEqual(draft, GameRoadBuildingPreviewDraft())
        XCTAssertEqual(state.devCardsByPlayer[actor]?.roadBuilding, 1)
    }

    func testStalePairCannotBeConfirmedAfterCanonicalStateChanges() throws {
        let fixture = try fixture()
        let state = fixture.state
        let actor = fixture.defaultActorID
        var draft = GameRoadBuildingPreviewDraft()
        let first = try XCTUnwrap(draft.legalEdges(in: state, actor: actor).first)
        draft.select(first, in: state, actor: actor)
        let second = try XCTUnwrap(draft.legalEdges(in: state, actor: actor).first)
        draft.select(second, in: state, actor: actor)
        let changed = try apply(intent: .playRoadBuilding(firstEdgeID: first, secondEdgeID: second), to: state, actor: actor)
        XCTAssertNil(draft.reviewedDraft(in: changed, actor: actor))
        XCTAssertTrue(draft.pendingEdgeIDs.isEmpty)
        XCTAssertEqual(draft.guidance, "The board changed. Choose your first road again.")
        XCTAssertEqual(changed.auditLog.count, state.auditLog.count + 1)
        XCTAssertEqual(changed.devCardsByPlayer[actor]?.roadBuilding, 0)
    }

    func testIllegalSelectionLeavesDraftUnchanged() throws {
        let fixture = try fixture()
        var draft = GameRoadBuildingPreviewDraft()
        draft.select(-1, in: fixture.state, actor: fixture.defaultActorID)
        XCTAssertTrue(draft.pendingEdgeIDs.isEmpty)
        XCTAssertEqual(draft.guidance, "Choose a highlighted road.")
    }
}
#endif
