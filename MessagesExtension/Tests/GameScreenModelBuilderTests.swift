import ULS_CoreGame
import XCTest
@testable import MessagesExtension

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
        XCTAssertEqual(model.header.statusLine.subtitle, "Open a game bubble to continue.")
        XCTAssertEqual(model.header.metaText, "")
        XCTAssertEqual(model.board.title, "Open game")
        XCTAssertEqual(model.board.subtitle, "Open a game bubble to continue.")
        XCTAssertNil(model.boardRenderModel)
        XCTAssertTrue(model.opponents.isEmpty)
        XCTAssertTrue(model.handTray.chips.isEmpty)
        XCTAssertEqual(model.actionDock.primaryItems.map(\.isEnabled), [false, false, false, false])
        XCTAssertTrue(model.actionDock.utilityItems.isEmpty)
        XCTAssertTrue(model.actionDock.buildShelfItems.isEmpty)
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
        XCTAssertEqual(
            model.opponents[0].displayName,
            PlayerPseudonymResolver.displayName(for: "B", gameID: state.gameId, roster: state.roster)
        )
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

    func testBuildKeepsObserverReadOnlyAndSecrecySafe() {
        let state = makeState(
            currentPlayer: "A",
            resourcesByPlayer: [
                "A": ResourceHandV1(wood: 2, brick: 1),
                "B": ResourceHandV1(wood: 1, sheep: 2),
            ]
        )

        let model = GameScreenModelBuilder.build(
            context: GameScreenContext(
                selectedState: state,
                actingAs: nil,
                contextBanner: "banner",
                contextMeta: "meta",
                actionAvailability: .none,
                modeAvailability: .none
            )
        )

        XCTAssertTrue(model.handTray.chips.isEmpty)
        XCTAssertEqual(model.opponents.map(\.handCount), [3, 3])
        XCTAssertEqual(model.actionDock.primaryItems.map(\.isEnabled), [false, false, false, false])
        XCTAssertTrue(model.actionDock.utilityItems.isEmpty)
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
                    canBuyDevCard: false,
                    canPlayDevCards: false,
                    canEndTurn: true
                ),
                modeAvailability: GameModeAvailability(
                    canSetup: false,
                    canBuildRoad: false,
                    canBuildSettlement: false,
                    canBuildCity: false,
                    canRobberMove: false,
                    canRobberVictim: false,
                    canTrade: true,
                    canPlayDevCard: false,
                    canDiscard: false
                )
            )
        )

        XCTAssertEqual(
            model.actionDock.primaryItems,
            [
                GameActionDockItem(kind: .roll, title: "Roll", systemImage: "die.face.5", isEnabled: true),
                GameActionDockItem(kind: .endTurn, title: "End Turn", systemImage: "flag.pattern.checkered", isEnabled: true),
                GameActionDockItem(kind: .build, title: "Build", systemImage: "hammer.fill", isEnabled: false),
                GameActionDockItem(kind: .devCards, title: "Play Dev", systemImage: "sparkles.rectangle.stack.fill", isEnabled: false),
            ]
        )
        XCTAssertTrue(model.actionDock.utilityItems.isEmpty)
        XCTAssertTrue(model.actionDock.buildShelfItems.isEmpty)
    }

    func testBuildUsesBuildShelfForDevCardPurchaseWhenPurchaseIsLegal() {
        let model = GameScreenModelBuilder.build(
            context: GameScreenContext(
                selectedState: makeState(resourcesByPlayer: ["A": .zero, "B": .zero]),
                actingAs: "A",
                contextBanner: "banner",
                contextMeta: "meta",
                actionAvailability: GameActionAvailability(
                    canRoll: false,
                    canBuild: false,
                    canTrade: false,
                    canBuyDevCard: true,
                    canPlayDevCards: false,
                    canEndTurn: false
                ),
                modeAvailability: .none
            )
        )

        XCTAssertEqual(
            model.actionDock.primaryItems[2],
            GameActionDockItem(
                kind: .build,
                title: "Build",
                systemImage: "hammer.fill",
                isEnabled: true
            )
        )
        XCTAssertEqual(
            model.actionDock.buildShelfItems,
            [
                GameBuildShelfItem(
                    kind: .buyDevCard,
                    title: "Buy Dev",
                    systemImage: "plus.rectangle.on.folder.fill",
                    isEnabled: true
                ),
            ]
        )
        XCTAssertFalse(model.actionDock.primaryItems[3].isEnabled)
    }

    func testBuildComposesHeaderWithTurnOwnershipAndDiceRoll() {
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
        XCTAssertEqual(yourTurnModel.header.statusLine.subtitle, "Roll: 3 + 4 = 7")
        XCTAssertEqual(yourTurnModel.header.metaText, "")

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
        XCTAssertEqual(
            waitingModel.header.statusLine.title,
            "Waiting on \(PlayerPseudonymResolver.displayName(for: "A", gameID: "game-screen-builder", roster: ["A", "B"]))"
        )
        XCTAssertEqual(waitingModel.header.statusLine.subtitle, "Roll: 3 + 4 = 7")

        let pendingRollModel = GameScreenModelBuilder.build(
            context: GameScreenContext(
                selectedState: makeState(
                    currentPlayer: "A",
                    resourcesByPlayer: ["A": .zero, "B": .zero],
                    turnState: TurnStateV1(step: .needsRoll, lastRoll: nil)
                ),
                actingAs: "B",
                contextBanner: "banner",
                contextMeta: "meta",
                actionAvailability: .none,
                modeAvailability: .none
            )
        )
        XCTAssertEqual(
            pendingRollModel.header.statusLine.title,
            "Waiting on \(PlayerPseudonymResolver.displayName(for: "A", gameID: "game-screen-builder", roster: ["A", "B"]))"
        )
        XCTAssertEqual(pendingRollModel.header.statusLine.subtitle, "Roll pending")

        let discardModel = GameScreenModelBuilder.build(
            context: GameScreenContext(
                selectedState: makeState(
                    currentPlayer: "B",
                    resourcesByPlayer: ["A": ResourceHandV1(wood: 1, brick: 1), "B": .zero],
                    turnState: TurnStateV1(
                        step: .pendingDiscards,
                        lastRoll: DiceRollV1(d1: 4, d2: 3),
                        discardRequirementsByPlayer: ["A": 2]
                    )
                ),
                actingAs: "A",
                contextBanner: "banner",
                contextMeta: "meta",
                actionAvailability: .none,
                modeAvailability: .none
            )
        )
        XCTAssertEqual(
            discardModel.header.statusLine.title,
            "Waiting on \(PlayerPseudonymResolver.displayName(for: "B", gameID: "game-screen-builder", roster: ["A", "B"]))"
        )
        XCTAssertEqual(discardModel.header.statusLine.subtitle, "Roll: 4 + 3 = 7")

        let robberModel = GameScreenModelBuilder.build(
            context: GameScreenContext(
                selectedState: makeState(
                    currentPlayer: "A",
                    resourcesByPlayer: ["A": .zero, "B": .zero],
                    turnState: TurnStateV1(step: .needsRobberMove, lastRoll: DiceRollV1(d1: 4, d2: 3))
                ),
                actingAs: "A",
                contextBanner: "banner",
                contextMeta: "meta",
                actionAvailability: .none,
                modeAvailability: .none
            )
        )
        XCTAssertEqual(robberModel.header.statusLine.title, "Your turn")
        XCTAssertEqual(robberModel.header.statusLine.subtitle, "Roll: 4 + 3 = 7")
    }

    func testBuildShowsGameOverWinnerFinalScoreAndRecap() {
        let recap = TurnRecapV1(
            actor: "B",
            startRev: 10,
            endRev: 12,
            rollTotal: 8,
            actions: [.rollDice, .buildCity, .endTurn]
        )
        let state = makeState(
            currentPlayer: "B",
            resourcesByPlayer: ["A": .zero, "B": .zero, "C": .zero],
            settlementsByNode: [0: "A", 1: "C", 4: "B", 5: "B"],
            citiesByNode: [2: "B", 3: "B"],
            revealedVictoryPointsByPlayer: ["B": 4],
            phase: .gameOver,
            winnerPlayer: "B",
            winningVictoryPoints: 10,
            lastTurnRecap: recap
        )

        let model = GameScreenModelBuilder.build(
            context: GameScreenContext(
                selectedState: state,
                actingAs: "B",
                contextBanner: "banner",
                contextMeta: "meta",
                actionAvailability: GameActionAvailability(
                    canRoll: true,
                    canBuild: true,
                    canTrade: true,
                    canBuyDevCard: true,
                    canPlayDevCards: true,
                    canEndTurn: true
                ),
                modeAvailability: .none
            )
        )

        XCTAssertEqual(model.header.statusLine.title, "You won")
        XCTAssertTrue(model.header.statusLine.subtitle.contains("Final score:"))
        XCTAssertTrue(
            model.header.statusLine.subtitle.contains(
                PlayerPseudonymResolver.displayName(for: "B", gameID: state.gameId, roster: state.roster)
            )
        )
        XCTAssertTrue(model.header.metaText.contains("Last turn:"))
        XCTAssertTrue(model.actionDock.primaryItems.allSatisfy { !$0.isEnabled })
        XCTAssertTrue(model.actionDock.utilityItems.isEmpty)
        XCTAssertTrue(model.actionDock.buildShelfItems.isEmpty)
    }

    private func makeState(
        currentPlayer: String = "A",
        resourcesByPlayer: [String: ResourceHandV1],
        settlementsByNode: [NodeID: String] = [:],
        citiesByNode: [NodeID: String] = [:],
        revealedVictoryPointsByPlayer: [String: Int] = [:],
        activeTradeOffer: TradeOfferV1? = nil,
        turnState: TurnStateV1 = TurnStateV1(step: .afterRoll, lastRoll: DiceRollV1(d1: 3, d2: 4)),
        phase: PhaseV1 = .turn,
        winnerPlayer: String? = nil,
        winningVictoryPoints: Int = 0,
        lastTurnRecap: TurnRecapV1? = nil
    ) -> CoreGameStateV1 {
        let roster = Array(resourcesByPlayer.keys).sorted()

        return CoreGameStateV1(
            gameId: "game-screen-builder",
            rev: 7,
            prevHash: "hash-6",
            stateHash: "",
            roster: roster,
            currentPlayer: currentPlayer,
            phase: phase,
            seed: 1,
            diceRngState: 2,
            robberRngState: 3,
            resourcesByPlayer: resourcesByPlayer,
            revealedVictoryPointsByPlayer: revealedVictoryPointsByPlayer,
            winnerPlayer: winnerPlayer,
            winningVictoryPoints: winningVictoryPoints,
            lastTurnRecap: lastTurnRecap,
            activeTradeOffer: activeTradeOffer,
            settlementsByNode: settlementsByNode,
            citiesByNode: citiesByNode,
            turnState: turnState
        ).rehashed()
    }
}
