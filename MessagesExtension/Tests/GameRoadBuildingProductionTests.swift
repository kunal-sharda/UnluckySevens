#if DEBUG
import XCTest
import ULS_CoreGame
@testable import MessagesExtensionSupport

@MainActor
final class GameRoadBuildingProductionTests: XCTestCase {
    func testConfirmationPublishesOneAtomicPairAndRejectsDuplicate() throws {
        let (state, actor, model, defaults) = try makeModel()
        var handoffs = 0
        var complete: ((Result<Void, Error>) -> Void)?
        model.stateHandoffForTesting = { callback in
            handoffs += 1
            complete = callback
        }
        var draft = try readyDraft(state: state, actor: actor)
        XCTAssertEqual(handoffs, 0)
        XCTAssertEqual(model.gameplayShellProjection.stateHash, state.stateHash)
        let reviewed = try XCTUnwrap(draft.reviewedDraft(in: state, actor: actor))
        XCTAssertTrue(model.publishDevCardDraft(reviewed))
        XCTAssertTrue(model.isSendingGameUpdate)
        XCTAssertEqual(handoffs, 1)
        XCTAssertEqual(model.gameplayShellProjection.stateHash, state.stateHash)
        XCTAssertFalse(model.publishDevCardDraft(reviewed), "Double confirmation must not enqueue another receipt")
        XCTAssertEqual(handoffs, 1)
        try XCTUnwrap(complete)(.success(()))
        let accepted = try XCTUnwrap(TranscriptGameLedgerStore(userDefaults: defaults).latestState(for: state.gameId))
        XCTAssertEqual(accepted.rev, state.rev + 1)
        XCTAssertEqual(accepted.auditLog.count, state.auditLog.count + 1)
        XCTAssertEqual(accepted.auditLog.last?.action, .playRoadBuilding)
        XCTAssertEqual(accepted.devCardsByPlayer[actor]?.roadBuilding, 0)
        XCTAssertEqual(accepted.resourcesByPlayer, state.resourcesByPlayer)
        for edge in draft.pendingEdgeIDs { XCTAssertEqual(accepted.roadsByEdge[edge], actor) }
        XCTAssertEqual(model.gameplayShellProjection.stateHash, accepted.stateHash)
        XCTAssertFalse(model.publishDevCardDraft(reviewed), "An already accepted pair must not publish twice")
        XCTAssertEqual(handoffs, 1)
    }

    func testFailedConfirmationPreservesCanonicalStateAndAllowsExplicitRetry() throws {
        let (state, actor, model, _) = try makeModel()
        var handoffs = 0
        var complete: ((Result<Void, Error>) -> Void)?
        model.stateHandoffForTesting = { callback in handoffs += 1; complete = callback }
        var draft = try readyDraft(state: state, actor: actor)
        let reviewed = try XCTUnwrap(draft.reviewedDraft(in: state, actor: actor))
        XCTAssertTrue(model.publishDevCardDraft(reviewed))
        try XCTUnwrap(complete)(.failure(NSError(domain: "RoadBuildingTests", code: 1)))
        XCTAssertFalse(model.isSendingGameUpdate)
        XCTAssertEqual(model.gameplayShellProjection.stateHash, state.stateHash)
        XCTAssertTrue(draft.isReady)
        XCTAssertTrue(model.publishDevCardDraft(reviewed))
        XCTAssertEqual(handoffs, 2)
        try XCTUnwrap(complete)(.success(()))
        XCTAssertNotEqual(model.gameplayShellProjection.stateHash, state.stateHash)
    }

    func testPendingProjectionOnlyShowsValidRoadDraftDuringRoadFlow() throws {
        let (state, actor, _, _) = try makeModel()
        let draft = try readyDraft(state: state, actor: actor)
        let active = GameBoardOverlayModelBuilder.build(state: state, actingAs: actor,
            mode: .devCardRoadBuildingSecond, devCardDraft: draft.devCardDraft, selectedTarget: nil)
        XCTAssertEqual(active.pendingEdgeIDs, draft.pendingEdgeIDs)
        let idle = GameBoardOverlayModelBuilder.build(state: state, actingAs: actor,
            mode: .idle, devCardDraft: draft.devCardDraft, selectedTarget: nil)
        XCTAssertTrue(idle.pendingEdgeIDs.isEmpty)
        let invalid = GameBoardOverlayModelBuilder.build(state: state, actingAs: actor,
            mode: .devCardRoadBuildingSecond, devCardDraft: .roadBuilding(firstEdgeID: -1, secondEdgeID: -2), selectedTarget: nil)
        XCTAssertTrue(invalid.pendingEdgeIDs.isEmpty)
    }

    private func readyDraft(state: CoreGameStateV1, actor: String) throws -> GameRoadBuildingDraft {
        var draft = GameRoadBuildingDraft()
        draft.select(try XCTUnwrap(draft.legalEdges(in: state, actor: actor).first), in: state, actor: actor)
        draft.select(try XCTUnwrap(draft.legalEdges(in: state, actor: actor).first), in: state, actor: actor)
        return draft
    }

    private func makeModel() throws -> (CoreGameStateV1, String, LobbyDriverViewModel, UserDefaults) {
        let fixture = try XCTUnwrap(UXTestFixtures.all.first { $0.id == "preview-road-building" })
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "RoadBuildingTests.\(UUID().uuidString)"))
        let model = LobbyDriverViewModel(userDefaults: defaults, tutorialState: fixture.state,
                                        tutorialActorID: fixture.defaultActorID)
        return (fixture.state, fixture.defaultActorID, model, defaults)
    }
}
#endif
