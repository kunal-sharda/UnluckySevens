import ULS_CoreGame
import XCTest

@MainActor
final class GameBoardSnapshotRendererTests: XCTestCase {
    func testSnapshotRendererProducesBubbleSizedImage() throws {
        let renderModel = try XCTUnwrap(makeRenderModel())

        let image = try XCTUnwrap(
            GameBoardSnapshotRenderer.render(
            renderModel: renderModel,
            variant: .bubbleCompact
            )
        )

        XCTAssertEqual(image.size.width, GameBoardSnapshotVariant.bubbleCompact.canvasSize.width, accuracy: 0.5)
        XCTAssertEqual(image.size.height, GameBoardSnapshotVariant.bubbleCompact.canvasSize.height, accuracy: 0.5)
    }

    func testSnapshotRendererProducesTranscriptPreviewImage() throws {
        let renderModel = try XCTUnwrap(makeRenderModel())

        let image = try XCTUnwrap(
            GameBoardSnapshotRenderer.render(
            renderModel: renderModel,
            variant: .transcriptPreview
            )
        )

        XCTAssertEqual(image.size.width, GameBoardSnapshotVariant.transcriptPreview.canvasSize.width, accuracy: 0.5)
        XCTAssertEqual(image.size.height, GameBoardSnapshotVariant.transcriptPreview.canvasSize.height, accuracy: 0.5)

        let attachment = XCTAttachment(image: image)
        attachment.name = "Approved robber on transcript board snapshot"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func makeRenderModel() -> GameBoardRenderModel? {
        let board = BoardSetupV1(
            resourcesByTile: [
                .wood, .brick, .desert, .sheep, .wheat,
                .ore, .wood, .brick, .sheep, .wheat,
                .ore, .wood, .brick, .sheep, .wheat,
                .ore, .wood, .brick, .sheep,
            ],
            numbersByTile: [
                5, 2, nil, 6, 3,
                8, 10, 9, 12, 11,
                4, 8, 10, 9, 4,
                5, 6, 3, 11,
            ],
            portsByIndex: StandardBoardTopologyV1.standard().ports.map(\.kind),
            robberTile: 2,
            generator: .noRedAdjacentV1,
            boardHash: ""
        ).rehashed()

        let state = CoreGameStateV1(
            gameId: "snapshot-renderer",
            rev: 9,
            prevHash: "hash-8",
            stateHash: "",
            roster: ["A", "B", "C"],
            currentPlayer: "A",
            phase: .turn,
            seed: 1,
            diceRngState: 2,
            robberRngState: 3,
            resourcesByPlayer: ["A": .zero, "B": .zero, "C": .zero],
            settlementsByNode: [0: "A"],
            citiesByNode: [9: "B"],
            roadsByEdge: [3: "A"],
            boardRules: BoardRulesV1(strategy: .noRedAdjacentV1),
            board: board,
            turnState: TurnStateV1(step: .afterRoll, lastRoll: DiceRollV1(d1: 4, d2: 2))
        ).rehashed()

        return GameBoardRenderModelBuilder.build(state: state)
    }
}
