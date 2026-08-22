import ULS_CoreGame
import XCTest
@testable import MessagesExtensionSupport

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
        XCTAssertEqual(
            model.opponents[0].playerTint,
            GamePlayerTint(red: 0.18, green: 0.42, blue: 0.70)
        )
        XCTAssertEqual(model.opponents[0].victoryPoints, 3)
        XCTAssertEqual(model.opponents[0].handCount, 3)
        XCTAssertFalse(model.opponents[0].isCurrentPlayer)
        XCTAssertEqual(
            model.opponents[1].playerTint,
            GamePlayerTint(red: 0.91, green: 0.88, blue: 0.78)
        )
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
        XCTAssertEqual(model.handTray.totalCount, 11)
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
                GameActionDockItem(kind: .endTurn, title: "End Turn", systemImage: "flag.fill", isEnabled: true),
                GameActionDockItem(kind: .build, title: "Build", systemImage: "hammer.fill", isEnabled: false),
                GameActionDockItem(kind: .devCards, title: "Dev Cards", systemImage: "sparkles.rectangle.stack.fill", isEnabled: false),
            ]
        )
        XCTAssertTrue(model.actionDock.utilityItems.isEmpty)
        XCTAssertTrue(model.actionDock.buildShelfItems.isEmpty)
    }

    func testBuildShelfIncludesOnlyExecutablePiecesWithCoreOwnedCosts() {
        let model = GameScreenModelBuilder.build(
            context: GameScreenContext(
                selectedState: makeState(resourcesByPlayer: ["A": .zero, "B": .zero]),
                actingAs: "A",
                contextBanner: "banner",
                contextMeta: "meta",
                actionAvailability: GameActionAvailability(
                    canRoll: false,
                    canBuild: true,
                    canTrade: false,
                    canBuyDevCard: false,
                    canPlayDevCards: false,
                    canEndTurn: true
                ),
                modeAvailability: GameModeAvailability(
                    canSetup: false,
                    canBuildRoad: true,
                    canBuildSettlement: false,
                    canBuildCity: true,
                    canRobberMove: false,
                    canRobberVictim: false,
                    canTrade: false,
                    canPlayDevCard: false,
                    canDiscard: false
                )
            )
        )

        XCTAssertEqual(model.actionDock.buildShelfItems.map(\.kind), [.buildRoad, .buildCity])
        XCTAssertEqual(model.actionDock.buildShelfItems.map(\.cost), [CoreBuildCostsV1.road, CoreBuildCostsV1.city])
        XCTAssertEqual(
            model.actionDock.buildShelfItems.map(\.placementInstruction),
            [
                "Tap a highlighted edge, then tap it again to build.",
                "Tap one of your highlighted settlements, then tap it again to upgrade.",
            ]
        )
    }

    func testTurnObjectRailKeepsFixedSlotsWhileUnavailableActionsStayAbsent() {
        let dock = GameActionDockModel(
            primaryItems: [
                GameActionDockItem(kind: .trade, title: "Trade", systemImage: "arrow.left.arrow.right", isEnabled: false),
                GameActionDockItem(kind: .endTurn, title: "End Turn", systemImage: "flag.fill", isEnabled: true),
                GameActionDockItem(kind: .build, title: "Build", systemImage: "hammer.fill", isEnabled: true),
                GameActionDockItem(kind: .devCards, title: "Dev Cards", systemImage: "sparkles.rectangle.stack.fill", isEnabled: false),
            ],
            utilityItems: [],
            buildShelfItems: []
        )

        let rail = GameTurnObjectRailModel.build(actionDock: dock)

        XCTAssertEqual(rail.slots.map(\.kind), [.hand, .build, .trade, .devCards, .endTurn])
        XCTAssertEqual(rail.slots.map(\.isAvailable), [true, true, false, false, true])
        XCTAssertNil(rail.slots[2].actionItem)
        XCTAssertNil(rail.slots[3].actionItem)
    }

    func testBuildKeepsDevCardPurchaseOwnedByPublicDeck() {
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

        XCTAssertFalse(model.actionDock.primaryItems[2].isEnabled)
        XCTAssertTrue(model.actionDock.buildShelfItems.isEmpty)
        XCTAssertTrue(model.canBuyDevCard)
        XCTAssertFalse(model.actionDock.primaryItems[3].isEnabled)
    }

    func testBuildCreatesLocalOwnedDevInventoryAndPublicGameInfo() throws {
        let state = makeState(
            currentPlayer: "A",
            resourcesByPlayer: [
                "A": ResourceHandV1(wood: 2),
                "B": ResourceHandV1(brick: 3),
            ],
            devCardsByPlayer: [
                "A": DevCardInventoryV1(knight: 1),
                "B": DevCardInventoryV1(monopoly: 2),
            ],
            newDevCardsByPlayer: [
                "A": DevCardInventoryV1(yearOfPlenty: 1),
            ],
            largestArmyOwner: "A",
            longestRoadOwner: "B"
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
            model.ownedDevCards,
            [
                GameOwnedDevCardSummary(kind: .knight, playableCount: 1, newCount: 0),
                GameOwnedDevCardSummary(kind: .yearOfPlenty, playableCount: 0, newCount: 1),
            ]
        )
        XCTAssertEqual(model.gameInfo.players.map(\.developmentCardCount), [2, 2])
        XCTAssertEqual(model.gameInfo.players[0].awardLabels, ["Largest Army"])
        XCTAssertEqual(model.gameInfo.players[1].awardLabels, ["Longest Road"])
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
            "\(PlayerPseudonymResolver.displayName(for: "A", gameID: "game-screen-builder", roster: ["A", "B"]))'s Turn"
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
            "\(PlayerPseudonymResolver.displayName(for: "A", gameID: "game-screen-builder", roster: ["A", "B"]))'s Turn"
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
            "\(PlayerPseudonymResolver.displayName(for: "B", gameID: "game-screen-builder", roster: ["A", "B"]))'s Turn"
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

    func testBuildShowsGameOverWinnerFinalScoreAndRecap() throws {
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
            auditLog: [
                AuditEntryV1(rev: 7, actor: "B", action: .playKnight),
                AuditEntryV1(rev: 8, actor: "B", action: .playMonopoly),
                AuditEntryV1(rev: 9, actor: "B", action: .playYearOfPlenty),
                AuditEntryV1(rev: 10, actor: "B", action: .playRoadBuilding),
                AuditEntryV1(rev: 11, actor: "B", action: .revealVictoryPoint),
            ],
            knightsPlayedByPlayer: ["B": 2],
            turnState: nil,
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

        XCTAssertEqual(model.header.statusLine.title, "Victory!")
        XCTAssertTrue(model.header.statusLine.subtitle.contains("Final score:"))
        XCTAssertTrue(
            model.header.statusLine.subtitle.contains(
                PlayerPseudonymResolver.displayName(for: "B", gameID: state.gameId, roster: state.roster)
            )
        )
        XCTAssertTrue(model.header.metaText.contains("Last turn:"))
        let endScreen = try XCTUnwrap(model.endScreen)
        XCTAssertEqual(endScreen.winnerTitle, "Victory!")
        XCTAssertEqual(endScreen.winningScoreText, "10 points")
        XCTAssertEqual(endScreen.players.map(\.id), ["B", "A", "C"])
        XCTAssertEqual(endScreen.players.map(\.victoryPoints), [10, 1, 1])
        XCTAssertEqual(endScreen.players.map(\.isWinner), [true, false, false])
        XCTAssertEqual(endScreen.players.map(\.isLocalPlayer), [true, false, false])
        XCTAssertEqual(
            endScreen.localDevelopmentCardGroups.map(\.kind),
            [
                .knight,
                .monopoly,
                .yearOfPlenty,
                .roadBuilding,
                .victoryPoint,
            ]
        )
        XCTAssertEqual(
            endScreen.localDevelopmentCardGroups.map(\.count),
            [2, 1, 1, 1, 4]
        )
        XCTAssertEqual(
            endScreen.players[0].scoreBreakdown,
            GameEndScoreBreakdown(
                buildingPoints: 6,
                developmentCardPoints: 4,
                largestArmyPoints: 0,
                longestRoadPoints: 0
            )
        )
        XCTAssertEqual(
            endScreen.recapText,
            "Your city secured the victory."
        )
        XCTAssertTrue(model.actionDock.primaryItems.allSatisfy { !$0.isEnabled })
        XCTAssertTrue(model.actionDock.utilityItems.isEmpty)
        XCTAssertTrue(model.actionDock.buildShelfItems.isEmpty)
    }

    func testBuildExplainsAwardWinningActionsWithCanonicalNames() throws {
        let cases: [(AuditActionV1, String, String?, String?)] = [
            (.buildRoad, "Gaining Longest Road secured the victory.", nil, "B"),
            (.playKnight, "Gaining Largest Army secured the victory.", "B", nil),
        ]

        for (action, expected, largestArmyOwner, longestRoadOwner) in cases {
            let state = makeState(
                currentPlayer: "B",
                resourcesByPlayer: ["A": .zero, "B": .zero, "C": .zero],
                largestArmyOwner: largestArmyOwner,
                longestRoadOwner: longestRoadOwner,
                turnState: nil,
                phase: .gameOver,
                winnerPlayer: "B",
                winningVictoryPoints: 10,
                lastTurnRecap: TurnRecapV1(
                    actor: "B",
                    startRev: 6,
                    endRev: 7,
                    rollTotal: 8,
                    actions: [action]
                )
            )

            let model = GameScreenModelBuilder.build(
                context: GameScreenContext(
                    selectedState: state,
                    actingAs: "B",
                    contextBanner: "banner",
                    contextMeta: "meta",
                    actionAvailability: .none,
                    modeAvailability: .none
                )
            )

            XCTAssertEqual(try XCTUnwrap(model.endScreen).recapText, expected)
        }
    }

    func testBuildNeutralHostEndHasNoWinningScore() throws {
        let active = makeState(
            currentPlayer: "A",
            resourcesByPlayer: ["A": .zero, "B": .zero, "C": .zero]
        )
        let ended = try apply(
            intent: .endGame(anchoredTo: active),
            to: active,
            actor: "A"
        )

        let model = GameScreenModelBuilder.build(
            context: GameScreenContext(
                selectedState: ended,
                actingAs: "A",
                contextBanner: "banner",
                contextMeta: "meta",
                actionAvailability: .none,
                modeAvailability: .none
            )
        )

        let endScreen = try XCTUnwrap(model.endScreen)
        XCTAssertEqual(endScreen.winnerTitle, "Game ended")
        XCTAssertNil(endScreen.winningScoreText)
        XCTAssertEqual(
            endScreen.resultDetail,
            "Ended by \(PlayerPseudonymResolver.displayName(for: "A", in: ended))"
        )
        XCTAssertFalse(endScreen.players.contains(where: \.isWinner))
    }

    func testBuildShowsResignedPlayerAsSpectatorWhileGameContinues() throws {
        let active = makeState(
            currentPlayer: "A",
            resourcesByPlayer: ["A": .zero, "B": .zero, "C": .zero],
            citiesByNode: [0: "A", 1: "C"]
        )
        let continued = try apply(
            intent: .resign(anchoredTo: active),
            to: active,
            actor: "B"
        )

        let resignerModel = GameScreenModelBuilder.build(
            context: GameScreenContext(
                selectedState: continued,
                actingAs: "B",
                contextBanner: "banner",
                contextMeta: "meta",
                actionAvailability: .none,
                modeAvailability: .none
            )
        )
        let observerModel = GameScreenModelBuilder.build(
            context: GameScreenContext(
                selectedState: continued,
                actingAs: nil,
                contextBanner: "banner",
                contextMeta: "meta",
                actionAvailability: .none,
                modeAvailability: .none
            )
        )

        XCTAssertEqual(
            resignerModel.header.statusLine.title,
            "Spectating \(PlayerPseudonymResolver.displayName(for: "A", in: continued))'s Turn"
        )
        XCTAssertNil(resignerModel.endScreen)
        XCTAssertNil(observerModel.endScreen)
        XCTAssertTrue(observerModel.header.statusLine.title.hasSuffix("'s Turn"))
        XCTAssertEqual(continued.resignedPlayers, ["B"])
        XCTAssertEqual(continued.phase, .turn)
    }

    private func makeState(
        currentPlayer: String = "A",
        resourcesByPlayer: [String: ResourceHandV1],
        settlementsByNode: [NodeID: String] = [:],
        citiesByNode: [NodeID: String] = [:],
        revealedVictoryPointsByPlayer: [String: Int] = [:],
        devCardsByPlayer: [String: DevCardInventoryV1] = [:],
        newDevCardsByPlayer: [String: DevCardInventoryV1] = [:],
        auditLog: [AuditEntryV1] = [],
        knightsPlayedByPlayer: [String: Int] = [:],
        largestArmyOwner: String? = nil,
        longestRoadOwner: String? = nil,
        activeTradeOffer: TradeOfferV1? = nil,
        turnState: TurnStateV1? = TurnStateV1(step: .afterRoll, lastRoll: DiceRollV1(d1: 3, d2: 4)),
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
            devCardsByPlayer: devCardsByPlayer,
            newDevCardsByPlayer: newDevCardsByPlayer,
            revealedVictoryPointsByPlayer: revealedVictoryPointsByPlayer,
            knightsPlayedByPlayer: knightsPlayedByPlayer,
            largestArmyOwner: largestArmyOwner,
            longestRoadOwner: longestRoadOwner,
            winnerPlayer: winnerPlayer,
            winningVictoryPoints: winningVictoryPoints,
            auditLog: auditLog,
            lastTurnRecap: lastTurnRecap,
            activeTradeOffer: activeTradeOffer,
            settlementsByNode: settlementsByNode,
            citiesByNode: citiesByNode,
            turnState: turnState
        ).rehashed()
    }
}
