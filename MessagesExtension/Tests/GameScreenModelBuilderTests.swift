import ULS_CoreGame
import XCTest

final class GameScreenModelBuilderTests: XCTestCase {
    func testBuildWithoutStateReturnsSafeEmptyModel() {
        let model = GameScreenModelBuilder.build(
            context: GameScreenContext(
                selectedState: nil,
                actingAs: nil,
                contextBanner: "Active Context: none",
                contextMeta: "Source: -",
                actionAvailability: .none,
                modeAvailability: .none
            )
        )

        XCTAssertEqual(model.header.statusLine.title, "Open game")
        XCTAssertEqual(model.header.statusLine.subtitle, "Active Context: none")
        XCTAssertEqual(model.header.metaText, "Source: -")
        XCTAssertEqual(model.board.title, "Open game")
        XCTAssertEqual(model.board.subtitle, "Active Context: none")
        XCTAssertNil(model.boardRenderModel)
        XCTAssertTrue(model.opponents.isEmpty)
        XCTAssertTrue(model.handTray.chips.isEmpty)
        XCTAssertEqual(model.actionDock.items.map(\.isEnabled), [false, false, false, false, false])
    }

    func testBuildExcludesLocalActorFromOpponentSummaries() {
        let state = makeState(
            currentPlayer: "A",
            resourcesByPlayer: [
                "A": ResourceHandV1(wood: 2, brick: 1),
                "B": ResourceHandV1(wood: 1, sheep: 2),
                "C": ResourceHandV1(ore: 4),
            ],
            settlementsByNode: [0: "A", 1: "C"],
            citiesByNode: [2: "B"],
            revealedVictoryPointsByPlayer: ["B": 1]
        )

        let model = GameScreenModelBuilder.build(
            context: GameScreenContext(
                selectedState: state,
                actingAs: "A",
                contextBanner: "banner",
                contextMeta: "meta",
                actionAvailability: .none,
                modeAvailability: .none
            )
        )

        XCTAssertEqual(model.opponents.map(\.id), ["B", "C"])
        XCTAssertEqual(model.opponents[0].displayName, "B")
        XCTAssertEqual(model.opponents[0].victoryPoints, 3)
        XCTAssertEqual(model.opponents[0].handCount, 3)
        XCTAssertFalse(model.opponents[0].isCurrentPlayer)
        XCTAssertEqual(model.opponents[1].victoryPoints, 1)
        XCTAssertEqual(model.opponents[1].handCount, 4)
    }

    func testBuildRevealsOnlyLocalHandChips() {
        let state = makeState(
            currentPlayer: "A",
            resourcesByPlayer: [
                "A": ResourceHandV1(wood: 2, brick: 1, sheep: 3, wheat: 1, ore: 4),
                "B": ResourceHandV1(wood: 5),
            ]
        )

        let model = GameScreenModelBuilder.build(
            context: GameScreenContext(
                selectedState: state,
                actingAs: "A",
                contextBanner: "banner",
                contextMeta: "meta",
                actionAvailability: .none,
                modeAvailability: .none
            )
        )

        XCTAssertEqual(
            model.handTray.chips,
            [
                GameHandChip(resource: .wood, count: 2),
                GameHandChip(resource: .brick, count: 1),
                GameHandChip(resource: .sheep, count: 3),
                GameHandChip(resource: .wheat, count: 1),
                GameHandChip(resource: .ore, count: 4),
            ]
        )
    }

    func testBuildMapsActionAvailabilityIntoDockItems() {
        let model = GameScreenModelBuilder.build(
            context: GameScreenContext(
                selectedState: makeState(resourcesByPlayer: ["A": .zero, "B": .zero]),
                actingAs: "A",
                contextBanner: "banner",
                contextMeta: "meta",
                actionAvailability: GameActionAvailability(
                    canRoll: true,
                    canBuild: false,
                    canTrade: true,
                    canUseDevCards: false,
                    canEndTurn: true
                ),
                modeAvailability: .none
            )
        )

        XCTAssertEqual(
            model.actionDock.items,
            [
                GameActionDockItem(kind: .roll, title: "Roll", systemImage: "die.face.5", isEnabled: true),
                GameActionDockItem(kind: .build, title: "Build", systemImage: "hammer.fill", isEnabled: false),
                GameActionDockItem(kind: .trade, title: "Trade", systemImage: "arrow.left.arrow.right", isEnabled: true),
                GameActionDockItem(kind: .devCards, title: "Dev Cards", systemImage: "sparkles.rectangle.stack.fill", isEnabled: false),
                GameActionDockItem(kind: .endTurn, title: "End Turn", systemImage: "flag.pattern.checkered", isEnabled: true),
            ]
        )
    }

    func testBuildComposesHeaderForTurnOwnershipAndTradePending() {
        let yourTurnModel = GameScreenModelBuilder.build(
            context: GameScreenContext(
                selectedState: makeState(currentPlayer: "A", resourcesByPlayer: ["A": .zero, "B": .zero]),
                actingAs: "A",
                contextBanner: "banner",
                contextMeta: "meta",
                actionAvailability: .none,
                modeAvailability: .none
            )
        )
        XCTAssertEqual(yourTurnModel.header.statusLine.title, "Your turn")

        let waitingModel = GameScreenModelBuilder.build(
            context: GameScreenContext(
                selectedState: makeState(currentPlayer: "A", resourcesByPlayer: ["A": .zero, "B": .zero]),
                actingAs: "B",
                contextBanner: "banner",
                contextMeta: "meta",
                actionAvailability: .none,
                modeAvailability: .none
            )
        )
        XCTAssertEqual(waitingModel.header.statusLine.title, "Waiting on A")

        let tradePendingModel = GameScreenModelBuilder.build(
            context: GameScreenContext(
                selectedState: makeState(
                    currentPlayer: "A",
                    resourcesByPlayer: ["A": .zero, "B": .zero],
                    activeTradeOffer: TradeOfferV1(
                        offerHash: "offer-1",
                        proposer: "A",
                        give: ResourceHandV1(wood: 1),
                        receive: ResourceHandV1(brick: 1),
                        createdRev: 7
                    )
                ),
                actingAs: "B",
                contextBanner: "banner",
                contextMeta: "meta",
                actionAvailability: .none,
                modeAvailability: .none
            )
        )
        XCTAssertEqual(tradePendingModel.header.statusLine.title, "Trade pending")
    }

    private func makeState(
        currentPlayer: String = "A",
        resourcesByPlayer: [String: ResourceHandV1],
        settlementsByNode: [NodeID: String] = [:],
        citiesByNode: [NodeID: String] = [:],
        revealedVictoryPointsByPlayer: [String: Int] = [:],
        activeTradeOffer: TradeOfferV1? = nil
    ) -> CoreGameStateV1 {
        let roster = Array(resourcesByPlayer.keys).sorted()

        return CoreGameStateV1(
            gameId: "game-screen-builder",
            rev: 7,
            prevHash: "hash-6",
            stateHash: "",
            roster: roster,
            currentPlayer: currentPlayer,
            phase: .turn,
            seed: 1,
            diceRngState: 2,
            robberRngState: 3,
            resourcesByPlayer: resourcesByPlayer,
            revealedVictoryPointsByPlayer: revealedVictoryPointsByPlayer,
            activeTradeOffer: activeTradeOffer,
            settlementsByNode: settlementsByNode,
            citiesByNode: citiesByNode,
            turnState: TurnStateV1(step: .afterRoll, lastRoll: DiceRollV1(d1: 3, d2: 4))
        ).rehashed()
    }
}
