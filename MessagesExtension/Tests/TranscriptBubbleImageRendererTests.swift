import UIKit
import ULS_CoreGame
import XCTest
@testable import MessagesExtension

@MainActor
final class TranscriptBubbleImageRendererTests: XCTestCase {
    func testLobbyInviteRendererReturnsExpectedSize() throws {
        let image = try XCTUnwrap(TranscriptBubbleImageRenderer.render(visual: .lobbyInvite))

        assertSnapshotImage(image)
    }

    func testBoardRendererReturnsNonEmptySetupImage() throws {
        let state = makeBoardState(phase: .setup, setupState: initializeSetupState(roster: roster))

        let image = try XCTUnwrap(
            TranscriptBubbleImageRenderer.render(
                visual: .board(
                    TranscriptBoardBubbleVisual(
                        state: state,
                        title: "Settlement Placed",
                        detail: "A placed a setup settlement."
                    )
                )
            )
        )

        assertSnapshotImage(image)
    }

    func testBoardRendererReturnsNonEmptyTurnImage() throws {
        let state = makeBoardState(
            phase: .turn,
            turnState: TurnStateV1(step: .afterRoll, lastRoll: DiceRollV1(d1: 3, d2: 4))
        )

        let image = try XCTUnwrap(
            TranscriptBubbleImageRenderer.render(
                visual: .board(
                    TranscriptBoardBubbleVisual(
                        state: state,
                        title: "Rolled 7",
                        detail: "Discards and robber movement are next."
                    )
                )
            )
        )

        assertSnapshotImage(image)
    }

    private var roster: [String] {
        ["A", "B", "C"]
    }

    private func makeBoardState(
        phase: PhaseV1,
        setupState: SetupStateV1? = nil,
        turnState: TurnStateV1? = nil
    ) -> CoreGameStateV1 {
        CoreGameStateV1(
            gameId: "bubble-image-renderer",
            rev: 3,
            prevHash: "hash-2",
            stateHash: "",
            roster: roster,
            currentPlayer: "A",
            playerDisplayNamesByPlayer: [:],
            phase: phase,
            seed: 1,
            diceRngState: 2,
            robberRngState: 3,
            resourcesByPlayer: Dictionary(uniqueKeysWithValues: roster.map { ($0, .zero) }),
            settlementsByNode: [0: "A", 9: "B"],
            roadsByEdge: [3: "A", 7: "B"],
            boardRules: BoardRulesV1(strategy: .noRedAdjacentV1),
            board: BoardSetupV1(
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
            ).rehashed(),
            setupState: setupState,
            turnState: turnState
        ).rehashed()
    }

    private func assertSnapshotImage(_ image: UIImage) {
        XCTAssertEqual(image.size.width, TranscriptBubbleImageRenderer.imageSize.width, accuracy: 0.5)
        XCTAssertEqual(image.size.height, TranscriptBubbleImageRenderer.imageSize.height, accuracy: 0.5)
        XCTAssertGreaterThan(image.pngData()?.count ?? 0, 1_000)
    }
}
