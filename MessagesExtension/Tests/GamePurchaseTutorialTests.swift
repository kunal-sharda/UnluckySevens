import ULS_CoreGame
@_spi(CompactState) import ULS_Transport
import XCTest
@testable import MessagesExtensionSupport

@MainActor
final class GamePurchaseTutorialTests: XCTestCase {
    private var defaults: UserDefaults!
    private var suiteName: String!

    override func setUp() {
        super.setUp()
        suiteName = "GamePurchaseTutorialTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        suiteName = nil
        super.tearDown()
    }

    func testDetectsEachPrivateNewKindAndRejectsAbsentOrUnchangedPanels() throws {
        let before = try panel(newCards: .zero)
        XCTAssertNil(GameDevPurchaseTutorial.newKind(before: nil, after: before))
        XCTAssertNil(GameDevPurchaseTutorial.newKind(before: before, after: nil))
        XCTAssertNil(GameDevPurchaseTutorial.newKind(before: before, after: before))
        for (card, kind) in cardKinds {
            let after = try panel(newCards: DevCardInventoryV1.zero.addingOne(card: card))
            XCTAssertEqual(GameDevPurchaseTutorial.newKind(before: before, after: after), kind)
            XCTAssertNil(GameDevPurchaseTutorial.newKind(before: after, after: before))
            let otherViewer = try panel(newCards: DevCardInventoryV1.zero.addingOne(card: card), actor: "B")
            XCTAssertNil(GameDevPurchaseTutorial.newKind(before: before, after: otherViewer))
        }
    }

    func testRejectsBatchedOrMixedInventoryChanges() throws {
        let empty = try panel(newCards: .zero)
        XCTAssertNil(GameDevPurchaseTutorial.newKind(before: empty, after: try panel(newCards: .init(knight: 2))))
        XCTAssertNil(GameDevPurchaseTutorial.newKind(before: empty, after: try panel(newCards: .init(knight: 1, monopoly: 1))))
        XCTAssertNil(GameDevPurchaseTutorial.newKind(before: empty, after: try panel(newCards: .init(knight: 1, monopoly: 2))))
        XCTAssertNil(GameDevPurchaseTutorial.newKind(
            before: try panel(newCards: .init(monopoly: 1)),
            after: try panel(newCards: .init(knight: 1))
        ))
    }

    func testAcceptedPurchaseDetectsPrivateCardOnlyAfterHandoffAndPublishesOnce() throws {
        for (card, kind) in cardKinds {
            let state = makeState(deck: [card])
            XCTAssertEqual(try CompactStateTransport.decode(CompactStateTransport.encode(state)), state, "Purchase fixture must survive the real publication transport")
            let model = LobbyDriverViewModel(userDefaults: defaults, tutorialState: state, tutorialActorID: "A")
            let before = try XCTUnwrap(model.makeDevCardPanelModel(mode: .playDevCard, draft: nil))
            var handoffs = 0
            var completion: ((Result<Void, Error>) -> Void)?
            model.stateHandoffForTesting = { handoffs += 1; completion = $0 }

            XCTAssertTrue(model.handleDevCardAction(.buyDevCard))
            XCTAssertTrue(model.isSendingGameUpdate)
            XCTAssertEqual(model.devPurchaseTutorialToken, 0)
            XCTAssertNil(model.devPurchaseTutorialKind)
            XCTAssertNil(model.devPurchaseTutorialPanel)
            XCTAssertEqual(handoffs, 1)
            XCTAssertEqual(model.gameplayShellProjection.stateHash, state.stateHash)
            XCTAssertNil(GameDevPurchaseTutorial.newKind(before: before, after: model.makeDevCardPanelModel(mode: .playDevCard, draft: nil)))
            XCTAssertFalse(model.handleDevCardAction(.buyDevCard), "Repeated confirmation while pending must not publish twice")
            XCTAssertEqual(handoffs, 1)

            let callback = try XCTUnwrap(completion)
            callback(.success(()))
            let accepted = try XCTUnwrap(TranscriptGameLedgerStore(userDefaults: defaults).latestState(for: state.gameId))
            XCTAssertEqual(accepted.rev, state.rev + 1)
            XCTAssertEqual(accepted.auditLog.count, state.auditLog.count + 1)
            XCTAssertEqual(accepted.auditLog.last?.action, .buyDevCard)
            XCTAssertEqual(accepted.newDevCardsByPlayer["A"]?.count(for: card), 1)
            XCTAssertEqual(accepted.resourcesByPlayer["A"], ResourceHandV1(sheep: 1, wheat: 1, ore: 1))
            XCTAssertEqual(GameDevPurchaseTutorial.newKind(before: before, after: model.makeDevCardPanelModel(mode: .playDevCard, draft: nil)), kind)
            let privatePanel = try XCTUnwrap(model.makeDevCardPanelModel(mode: .playDevCard, draft: nil))
            XCTAssertEqual(model.devPurchaseTutorialToken, 1)
            XCTAssertEqual(model.devPurchaseTutorialKind, kind)
            XCTAssertEqual(model.devPurchaseTutorialPanel, privatePanel)
            let tile = try XCTUnwrap(privatePanel.cards.first { $0.kind == kind })
            XCTAssertFalse(tile.isEnabled)
            XCTAssertNil(tile.actionKind, "New action cards must wait; VP must never acquire a manual Play/Reveal control")
            let otherViewer = try XCTUnwrap(GameDevCardPanelModelBuilder.build(state: accepted, actingAs: "B"))
            XCTAssertTrue(otherViewer.newCounts.isEmpty)
            XCTAssertTrue(otherViewer.cards.isEmpty)
            callback(.success(()))
            XCTAssertEqual(model.devPurchaseTutorialToken, 1, "Duplicate acceptance cannot re-present the tutorial")
            XCTAssertEqual(model.devPurchaseTutorialKind, kind)
            XCTAssertEqual(model.devPurchaseTutorialPanel, privatePanel)
            XCTAssertEqual(TranscriptGameLedgerStore(userDefaults: defaults).latestState(for: state.gameId)?.rev, accepted.rev)
        }
    }

    func testFailedPurchaseDoesNotProduceTimingDeltaAndExplicitRetryCanSucceed() throws {
        let state = makeState(deck: [.knight])
        let model = LobbyDriverViewModel(userDefaults: defaults, tutorialState: state, tutorialActorID: "A")
        let before = model.makeDevCardPanelModel(mode: .playDevCard, draft: nil)
        var callbacks: [(Result<Void, Error>) -> Void] = []
        model.stateHandoffForTesting = { callbacks.append($0) }
        XCTAssertTrue(model.handleDevCardAction(.buyDevCard))
        callbacks[0](.failure(NSError(domain: "PurchaseTests", code: 1)))
        XCTAssertFalse(model.isSendingGameUpdate)
        XCTAssertEqual(model.devPurchaseTutorialToken, 0)
        XCTAssertNil(model.devPurchaseTutorialKind)
        XCTAssertNil(model.devPurchaseTutorialPanel)
        XCTAssertEqual(model.gameplayShellProjection.stateHash, state.stateHash)
        XCTAssertNil(GameDevPurchaseTutorial.newKind(before: before, after: model.makeDevCardPanelModel(mode: .playDevCard, draft: nil)))
        XCTAssertTrue(model.handleDevCardAction(.buyDevCard))
        XCTAssertEqual(callbacks.count, 2)
        callbacks[0](.success(()))
        XCTAssertEqual(model.devPurchaseTutorialToken, 0, "A stale callback cannot emit a purchase tutorial")
        XCTAssertNil(model.devPurchaseTutorialPanel)
        XCTAssertEqual(model.gameplayShellProjection.stateHash, state.stateHash, "An old failed callback cannot make a retry look accepted")
        callbacks[1](.success(()))
        XCTAssertEqual(model.devPurchaseTutorialToken, 1)
        XCTAssertEqual(model.devPurchaseTutorialKind, .knight)
        XCTAssertEqual(model.devPurchaseTutorialPanel, model.makeDevCardPanelModel(mode: .playDevCard, draft: nil))
        XCTAssertEqual(GameDevPurchaseTutorial.newKind(before: before, after: model.makeDevCardPanelModel(mode: .playDevCard, draft: nil)), .knight)
    }

    func testSecondAcceptedPurchaseProducesAnotherOccurrenceOfTheSameKind() throws {
        let state = makeState(deck: [.knight, .knight])
        let model = LobbyDriverViewModel(userDefaults: defaults, tutorialState: state, tutorialActorID: "A")
        var completion: ((Result<Void, Error>) -> Void)?
        model.stateHandoffForTesting = { completion = $0 }
        for occurrence in 1...2 {
            let before = model.makeDevCardPanelModel(mode: .playDevCard, draft: nil)
            XCTAssertTrue(model.handleDevCardAction(.buyDevCard))
            XCTAssertEqual(model.devPurchaseTutorialToken, occurrence - 1)
            try XCTUnwrap(completion)(.success(()))
            XCTAssertEqual(model.devPurchaseTutorialToken, occurrence)
            XCTAssertEqual(model.devPurchaseTutorialKind, .knight)
            XCTAssertEqual(model.devPurchaseTutorialPanel, model.makeDevCardPanelModel(mode: .playDevCard, draft: nil))
            XCTAssertEqual(GameDevPurchaseTutorial.newKind(before: before, after: model.makeDevCardPanelModel(mode: .playDevCard, draft: nil)), .knight)
        }
        let accepted = try XCTUnwrap(TranscriptGameLedgerStore(userDefaults: defaults).latestState(for: state.gameId))
        XCTAssertEqual(accepted.rev, state.rev + 2)
        XCTAssertEqual(accepted.newDevCardsByPlayer["A"]?.knight, 2)
    }

    private var cardKinds: [(DevCardV1, GameDevCardVisualKind)] {
        [(.knight, .knight), (.monopoly, .monopoly), (.yearOfPlenty, .yearOfPlenty),
         (.roadBuilding, .roadBuilding), (.victoryPoint, .victoryPoint)]
    }

    private func panel(newCards: DevCardInventoryV1, actor: String = "A") throws -> GameDevCardPanelModel {
        try XCTUnwrap(GameDevCardPanelModelBuilder.build(state: makeState(newCards: newCards), actingAs: actor))
    }

    private func makeState(deck: [DevCardV1] = [.knight], newCards: DevCardInventoryV1 = .zero) -> CoreGameStateV1 {
        let rules = BoardRulesV1(strategy: .noRedAdjacentV1)
        let board = StandardBoardGeneratorV1.generate(
            boardSeed: SeedDeriver(masterSeed: 17).seed(for: .board), rules: rules
        )
        return CoreGameStateV1(
            gameId: UUID().uuidString, rev: 11, prevHash: "previous", stateHash: "",
            roster: ["A", "B"], currentPlayer: "A", phase: .turn,
            seed: 17, diceRngState: 23, robberRngState: 29,
            resourcesByPlayer: ["A": ResourceHandV1(sheep: 2, wheat: 2, ore: 2), "B": .zero],
            bankResources: ResourceHandV1(wood: 19, brick: 19, sheep: 17, wheat: 17, ore: 17),
            devDeck: deck, newDevCardsByPlayer: ["A": newCards],
            boardRules: rules, board: board,
            turnState: TurnStateV1(step: .afterRoll, lastRoll: DiceRollV1(d1: 4, d2: 2))
        ).rehashed()
    }
}
