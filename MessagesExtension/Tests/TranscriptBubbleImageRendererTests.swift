import UIKit
import ULS_CoreGame
import XCTest
@testable import MessagesExtension

@MainActor
final class TranscriptBubbleImageRendererTests: XCTestCase {
    func testLobbySnapshotsUseCurrentRoster() throws {
        let waiting = makeLobbyState(roster: ["host"])
        let joined = makeLobbyState(roster: ["host", "guest-a", "guest-b"])

        let waitingImage = try render(copy: TranscriptBubbleCopyBuilder.invite(for: waiting))
        let joinedImage = try render(
            copy: TranscriptBubbleCopyBuilder.lobbyJoin(
                to: joined,
                joiningPlayer: "guest-b"
            )
        )

        attach(waitingImage, name: "Transcript - Lobby waiting for players")
        attach(joinedImage, name: "Transcript - Lobby with three players")
    }

    func testSetupSnapshotUsesActualBoardWithoutNumberTokens() throws {
        let state = makeBoardState(phase: .setup)
        let copy = TranscriptBubbleCopyBuilder.startGame(
            from: makeLobbyState(roster: state.roster),
            to: state
        )

        let image = try render(copy: copy)

        guard case let .board(visual) = copy.visual else {
            return XCTFail("Expected a board visual.")
        }
        XCTAssertFalse(visual.showsNumberTokens)
        attach(image, name: "Transcript - Setup board without number tokens")
    }

    func testTurnSnapshotUsesActualBoardWithNumberTokens() throws {
        let state = makeBoardState(phase: .turn)
        let copy = TranscriptBubbleCopyBuilder.turnIntent(
            .endTurn,
            actor: "A",
            resultingState: state
        )

        let image = try render(copy: copy)

        guard case let .board(visual) = copy.visual else {
            return XCTFail("Expected a board visual.")
        }
        XCTAssertTrue(visual.showsNumberTokens)
        assertBubbleImage(image)
    }

    func testGameOverSnapshotUsesActualBoardWithNumberTokens() throws {
        let state = makeBoardState(phase: .gameOver)
        let copy = TranscriptBubbleCopyBuilder.turnIntent(
            .endTurn,
            actor: "A",
            resultingState: state
        )

        let image = try render(copy: copy)

        guard case let .gameOver(visual) = copy.visual else {
            return XCTFail("Expected a game-over visual.")
        }
        XCTAssertEqual(visual.winnerTitle, "Avery won")
        attach(image, name: "Transcript - Game over board with number tokens")
    }

    func testFiveFamilyCheckpointGalleryUsesProductionComponents() throws {
        let lobbyState = makeLobbyState(roster: ["A", "B", "C"])
        let setupState = makeBoardState(phase: .setup)
        let turnState = makeBoardState(phase: .turn)
        let tradeState = makeTradeState()
        let gameOverState = makeBoardState(phase: .gameOver)

        let lobby = try render(
            copy: TranscriptBubbleCopyBuilder.lobbyJoin(
                to: lobbyState,
                joiningPlayer: "C"
            )
        )
        let setup = try render(
            copy: TranscriptBubbleCopyBuilder.startGame(
                from: lobbyState,
                to: setupState
            )
        )
        let gameplay = try render(
            copy: TranscriptBubbleCopyBuilder.turnIntent(
                .endTurn,
                actor: "A",
                resultingState: turnState
            )
        )
        let trade = try render(
            copy: TranscriptBubbleCopyBuilder.turnIntent(
                .proposeTrade(
                    give: ResourceHandV1(wheat: 2),
                    receive: ResourceHandV1(ore: 1),
                    recipients: ["B", "C"]
                ),
                actor: "A",
                resultingState: tradeState
            )
        )
        let gameOver = try render(
            copy: TranscriptBubbleCopyBuilder.turnIntent(
                .endTurn,
                actor: "A",
                resultingState: gameOverState
            )
        )

        attach(lobby, name: "Preview family 1 - Lobby")
        attach(setup, name: "Preview family 2 - Setup")
        attach(gameplay, name: "Preview family 3 - Gameplay")
        attach(trade, name: "Preview family 4 - Trade")
        attach(gameOver, name: "Preview family 5 - Game over")
    }

    private func render(copy: TranscriptBubbleCopy) throws -> UIImage {
        let image = try XCTUnwrap(
            TranscriptBubbleImageRenderer.render(
                visual: copy.visual,
                assetBundle: Bundle(for: TranscriptBubbleImageRendererTests.self)
            )
        )
        assertBubbleImage(image)
        return image
    }

    private func attach(_ image: UIImage, name: String) {
        let attachment = XCTAttachment(image: image)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func assertBubbleImage(_ image: UIImage) {
        XCTAssertEqual(
            image.size.width,
            TranscriptBubbleImageRenderer.imageSize.width,
            accuracy: 0.5
        )
        XCTAssertEqual(
            image.size.height,
            TranscriptBubbleImageRenderer.imageSize.height,
            accuracy: 0.5
        )
        XCTAssertGreaterThan(image.pngData()?.count ?? 0, 1_000)
    }

    private func makeLobbyState(roster: [String]) -> CoreGameStateV1 {
        CoreGameStateV1(
            gameId: "transcript-lobby",
            rev: roster.count,
            prevHash: "prev",
            stateHash: "",
            roster: roster,
            currentPlayer: roster[0],
            playerDisplayNamesByPlayer: Dictionary(
                uniqueKeysWithValues: roster.enumerated().map {
                    ($0.element, ["Avery", "Maya", "Theo", "June"][$0.offset])
                }
            ),
            phase: .lobby,
            seed: nil,
            diceRngState: nil,
            resourcesByPlayer: Dictionary(uniqueKeysWithValues: roster.map { ($0, .zero) }),
            boardRules: nil,
            board: nil
        ).rehashed()
    }

    private func makeBoardState(phase: PhaseV1) -> CoreGameStateV1 {
        let roster = ["A", "B", "C"]
        let boardRules = BoardRulesV1(strategy: .noRedAdjacentV1)
        let board = StandardBoardGeneratorV1.generate(
            boardSeed: SeedDeriver(masterSeed: 17).seed(for: .board),
            rules: boardRules
        )

        return CoreGameStateV1(
            gameId: "transcript-board",
            rev: phase == .setup ? 2 : 9,
            prevHash: "prev",
            stateHash: "",
            roster: roster,
            currentPlayer: "A",
            playerDisplayNamesByPlayer: [
                "A": "Avery",
                "B": "Maya",
                "C": "Theo",
            ],
            phase: phase,
            seed: 17,
            diceRngState: 23,
            robberRngState: 29,
            resourcesByPlayer: Dictionary(uniqueKeysWithValues: roster.map { ($0, .zero) }),
            revealedVictoryPointsByPlayer: phase == .gameOver ? ["A": 9] : [:],
            winnerPlayer: phase == .gameOver ? "A" : nil,
            winningVictoryPoints: phase == .gameOver ? 10 : 0,
            settlementsByNode: phase == .setup ? [:] : [0: "A", 9: "B"],
            roadsByEdge: phase == .setup ? [:] : [3: "A"],
            boardRules: boardRules,
            board: board,
            setupState: phase == .setup ? initializeSetupState(roster: roster) : nil,
            turnState: phase == .turn
                ? TurnStateV1(step: .afterRoll, lastRoll: DiceRollV1(d1: 4, d2: 2))
                : nil
        ).rehashed()
    }

    private func makeTradeState() -> CoreGameStateV1 {
        let base = makeBoardState(phase: .turn)
        let offer = TradeOfferV1(
            offerHash: "checkpoint-offer",
            proposer: "A",
            give: ResourceHandV1(wheat: 2),
            receive: ResourceHandV1(ore: 1),
            recipients: ["B", "C"],
            createdRev: base.rev
        )

        return CoreGameStateV1(
            gameId: base.gameId,
            rev: base.rev,
            prevHash: base.prevHash,
            stateHash: "",
            roster: base.roster,
            currentPlayer: base.currentPlayer,
            playerDisplayNamesByPlayer: base.playerDisplayNamesByPlayer,
            phase: base.phase,
            seed: base.seed,
            diceRngState: base.diceRngState,
            robberRngState: base.robberRngState,
            resourcesByPlayer: base.resourcesByPlayer,
            activeTradeOffer: offer,
            tradeResponses: [],
            settlementsByNode: base.settlementsByNode,
            citiesByNode: base.citiesByNode,
            roadsByEdge: base.roadsByEdge,
            boardRules: base.boardRules,
            board: base.board,
            turnState: base.turnState
        ).rehashed()
    }
}
