#if DEBUG
import ULS_CoreGame

/// Game-agnostic metadata for a DEBUG UX fixture.
///
/// A fixture's state and actions stay owned by its game. This descriptor only
/// describes how the lab presents and selects that fixture.
struct UXTestingFixtureDescriptor: Equatable, Identifiable {
    let id: String
    let title: String
    let detail: String
    let defaultActorID: String
}

/// Ordered fixture lookup with an explicit fallback for UI-driven selection.
///
/// This is intentionally agnostic about game state, rules, and action types so
/// another game can adopt the same DEBUG harness shape without sharing a rules
/// implementation or package boundary prematurely.
struct UXTestingFixtureRegistry<Fixture> {
    private let fixturesByID: [String: Fixture]
    let all: [Fixture]

    init(_ fixtures: [Fixture], id: (Fixture) -> String) {
        var fixturesByID: [String: Fixture] = [:]
        for fixture in fixtures {
            let fixtureID = id(fixture)
            precondition(
                fixturesByID[fixtureID] == nil,
                "DEBUG UX fixtures must have unique identifiers."
            )
            fixturesByID[fixtureID] = fixture
        }
        self.fixturesByID = fixturesByID
        self.all = fixtures
    }

    func fixture(id: String, fallingBackTo fallbackID: String) -> Fixture {
        guard let fallback = fixturesByID[fallbackID] else {
            preconditionFailure("DEBUG UX fixture fallback must be registered.")
        }
        return fixturesByID[id] ?? fallback
    }
}

struct UXTestFixture: Equatable, Identifiable {
    let descriptor: UXTestingFixtureDescriptor
    let state: CoreGameStateV1
    let extraActorIDs: [String]

    init(
        id: String,
        title: String,
        detail: String,
        defaultActorID: String,
        state: CoreGameStateV1,
        extraActorIDs: [String] = []
    ) {
        self.descriptor = UXTestingFixtureDescriptor(
            id: id,
            title: title,
            detail: detail,
            defaultActorID: defaultActorID
        )
        self.state = state
        self.extraActorIDs = extraActorIDs
    }

    var id: String { descriptor.id }
    var title: String { descriptor.title }
    var detail: String { descriptor.detail }
    var defaultActorID: String { descriptor.defaultActorID }

    var actorIDs: [String] {
        var ids = state.roster
        for actorID in extraActorIDs where !ids.contains(actorID) {
            ids.append(actorID)
        }
        return ids
    }
}

enum UXTestFixtures {
    static let host = "host"
    static let alice = "alice"
    static let ben = "ben"

    static let all: [UXTestFixture] = [
        lobbyInvite,
        lobbyReady,
        setupPlacement,
        setupRoadPlacement,
        setupHandoff,
        turnNeedsRoll,
        turnAfterRoll,
        endTurnAction,
        waitingOnAlice,
        waitingOnDiscard,
        pendingDiscard,
        robberMove,
        robberMoveAction,
        robberVictim,
        robberVictimAction,
        tradeOffer,
        multiTypeTradeOffer,
        victoryAction,
        gameOver,
        tutorialVictory,
    ]

    static let defaultFixtureID = turnAfterRoll.id
    static let defaultActorID = host
    static let lobbyInviteID = "lobby-invite"
    static let lobbyReadyID = "lobby-ready"
    static let setupPlacementID = "setup-placement"
    static let setupRoadPlacementID = "setup-road-placement"
    static let setupHandoffID = "setup-handoff"
    static let turnNeedsRollID = "turn-needs-roll"
    static let endTurnActionID = "end-turn-action"
    static let tradeOfferID = "trade-offer"
    static let multiTypeTradeOfferID = "multi-type-trade-offer"
    static let waitingOnAliceID = "waiting-on-alice"
    static let waitingOnDiscardID = "waiting-on-discard"
    static let robberVictimID = "robber-victim"
    static let robberMoveActionID = "robber-move-action"
    static let robberVictimActionID = "robber-victim-action"
    static let victoryActionID = "victory-action"
    static let tutorialVictoryID = "tutorial-victory"

    private static let registry = UXTestingFixtureRegistry(all) { $0.id }

    static func fixture(id: String) -> UXTestFixture {
        registry.fixture(id: id, fallingBackTo: defaultFixtureID)
    }

    static func displayName(for actorID: String) -> String? {
        displayNames[actorID]
    }

    static var recoveryStates: [CoreGameStateV1] {
        [
            reidentified(recoveryCoWinnerTurnState, gameId: "ux-recovery-active"),
            recoveryFinishedState(
                gameId: "ux-record-win-1",
                auditLog: recoveryAudit(turns: 9, sevenRolls: 2)
            ),
            recoveryFinishedState(
                gameId: "ux-record-loss-1",
                auditLog: recoveryAudit(turns: 11, sevenRolls: 1)
            ),
            recoveryFinishedState(
                gameId: "ux-record-draw",
                auditLog: recoveryAudit(turns: 12, sevenRolls: 2)
            ),
            recoveryFinishedState(
                gameId: "ux-record-win-2",
                auditLog: recoveryAudit(turns: 8, sevenRolls: 3)
            ),
            recoveryFinishedState(
                gameId: "ux-record-loss-2",
                auditLog: recoveryAudit(turns: 10, sevenRolls: 1)
            ),
            recoveryFinishedState(
                gameId: "ux-record-win-3",
                auditLog: recoveryAudit(turns: 7, sevenRolls: 4)
            ),
            recoveryFinishedState(
                gameId: "ux-record-win-4",
                auditLog: recoveryAudit(turns: 6, sevenRolls: 5)
            ),
        ]
    }

    private static func recoveryFinishedState(
        gameId: String,
        auditLog: [AuditEntryV1]
    ) -> CoreGameStateV1 {
        let base = gameOver.state
        return CoreGameStateV1(
            gameId: gameId,
            rev: base.rev,
            prevHash: base.prevHash,
            stateHash: "",
            roster: base.roster,
            currentPlayer: base.currentPlayer,
            playerDisplayNamesByPlayer: base.playerDisplayNamesByPlayer,
            phase: .gameOver,
            seed: base.seed,
            diceRngState: base.diceRngState,
            robberRngState: base.robberRngState,
            resourcesByPlayer: base.resourcesByPlayer,
            bankResources: base.bankResources,
            devDeck: base.devDeck,
            devCardsByPlayer: base.devCardsByPlayer,
            newDevCardsByPlayer: base.newDevCardsByPlayer,
            revealedVictoryPointsByPlayer: base.revealedVictoryPointsByPlayer,
            knightsPlayedByPlayer: base.knightsPlayedByPlayer,
            largestArmyOwner: base.largestArmyOwner,
            largestArmySize: base.largestArmySize,
            longestRoadOwner: base.longestRoadOwner,
            longestRoadLength: base.longestRoadLength,
            winnerPlayer: base.winnerPlayer,
            winningVictoryPoints: base.winningVictoryPoints,
            gameResult: base.gameResult,
            auditLog: auditLog,
            settlementsByNode: base.settlementsByNode,
            citiesByNode: base.citiesByNode,
            roadsByEdge: base.roadsByEdge,
            boardRules: base.boardRules,
            board: base.board
        ).rehashed()
    }

    private static func recoveryAudit(turns: Int, sevenRolls: Int) -> [AuditEntryV1] {
        var entries: [AuditEntryV1] = []
        var rev = 1
        var remainingSevens = sevenRolls
        for turn in 0..<turns {
            let actor = roster[turn % roster.count]
            if actor == host, remainingSevens > 0 {
                entries.append(AuditEntryV1(rev: rev, actor: actor, action: .rollDice, rollTotal: 7))
                rev += 1
                remainingSevens -= 1
            }
            entries.append(AuditEntryV1(rev: rev, actor: actor, action: .endTurn))
            rev += 1
        }
        while remainingSevens > 0 {
            entries.append(AuditEntryV1(rev: rev, actor: host, action: .rollDice, rollTotal: 7))
            rev += 1
            remainingSevens -= 1
        }
        entries.append(AuditEntryV1(rev: rev, actor: host, action: .buildCity))
        return entries
    }

    private static var recoveryCoWinnerTurnState: CoreGameStateV1 {
        makeState(
            rev: 9,
            currentPlayer: host,
            phase: .turn,
            settlementsByNode: defaultSettlements,
            citiesByNode: defaultCities,
            roadsByEdge: defaultRoads,
            largestArmyOwner: nil,
            largestArmySize: 0,
            longestRoadOwner: nil,
            longestRoadLength: 0,
            lastTurnRecap: TurnRecapV1(
                actor: alice,
                startRev: 5,
                endRev: 8,
                rollTotal: 6,
                actions: [.buildRoad, .endTurn]
            ),
            turnState: TurnStateV1(
                step: .afterRoll,
                lastRoll: DiceRollV1(d1: 3, d2: 5)
            )
        )
    }

    private static let roster = [host, alice, ben]
    private static let displayNames = [
        host: "Kunal",
        alice: "Maya",
        ben: "Theo",
    ]
    private static let boardRules = BoardRulesV1(strategy: .noRedAdjacentV1)
    private static let board = StandardBoardGeneratorV1.generate(
        boardSeed: SeedDeriver(masterSeed: 9_001).seed(for: .board),
        rules: boardRules
    )
    private static let fullBank = ResourceHandV1.standardBank
    private static let devDeck = Array(
        repeating: DevCardV1.knight,
        count: 8
    ) + [.roadBuilding, .yearOfPlenty, .monopoly, .victoryPoint]

    private static let lobbyInvite = UXTestFixture(
        id: "lobby-invite",
        title: "Lobby invite",
        detail: "Start here to drive the full table: switch to Maya or Theo, join, then return to Kunal to start.",
        defaultActorID: host,
        state: makeState(
            rev: 0,
            roster: [host],
            currentPlayer: host,
            phase: .lobby,
            seed: nil,
            diceRngState: nil,
            robberRngState: nil,
            resourcesByPlayer: [host: .zero],
            boardRules: nil,
            board: nil
        ),
        extraActorIDs: [alice, ben]
    )

    private static let lobbyReady = UXTestFixture(
        id: "lobby-ready",
        title: "Lobby ready",
        detail: "Three-player lobby with host able to start.",
        defaultActorID: host,
        state: makeState(
            rev: 2,
            phase: .lobby,
            seed: nil,
            diceRngState: nil,
            robberRngState: nil,
            boardRules: nil,
            board: nil
        )
    )

    private static let setupPlacement = UXTestFixture(
        id: setupPlacementID,
        title: "Setup placement",
        detail: "First setup settlement prompt.",
        defaultActorID: host,
        state: makeInitialSetupState()
    )

    private static let setupRoadPlacement = UXTestFixture(
        id: setupRoadPlacementID,
        title: "Setup road placement",
        detail: "Connected-road prompt after the first settlement.",
        defaultActorID: host,
        state: makeSetupRoadPlacementState()
    )

    private static let setupHandoff = UXTestFixture(
        id: setupHandoffID,
        title: "Setup handoff",
        detail: "Authoritative first-turn state after all setup placements.",
        defaultActorID: host,
        state: makeSetupHandoffState()
    )

    private static let turnNeedsRoll = UXTestFixture(
        id: turnNeedsRollID,
        title: "Turn needs roll",
        detail: "Current player before rolling.",
        defaultActorID: host,
        state: makeTurnFixture(
            rev: 8,
            currentPlayer: host,
            turnState: TurnStateV1(step: .needsRoll, lastRoll: nil)
        )
    )

    private static let turnAfterRoll = UXTestFixture(
        id: "turn-after-roll",
        title: "Turn after roll",
        detail: "Main gameplay surface with hand, actions, opponents, and board.",
        defaultActorID: host,
        state: makeTurnFixture(
            rev: 9,
            currentPlayer: host,
            lastTurnRecap: TurnRecapV1(
                actor: alice,
                startRev: 5,
                endRev: 8,
                rollTotal: 6,
                actions: [.buildRoad, .endTurn]
            ),
            turnState: TurnStateV1(
                step: .afterRoll,
                lastRoll: DiceRollV1(d1: 3, d2: 5)
            )
        )
    )

    private static let endTurnAction = UXTestFixture(
        id: endTurnActionID,
        title: "End turn action",
        detail: "Canonical post-roll state with award fields matching the placed pieces.",
        defaultActorID: host,
        state: makeTurnFixture(
            rev: 9,
            currentPlayer: host,
            largestArmyOwner: nil,
            largestArmySize: 0,
            longestRoadOwner: nil,
            longestRoadLength: 0,
            turnState: TurnStateV1(
                step: .afterRoll,
                lastRoll: DiceRollV1(d1: 3, d2: 5)
            )
        )
    )

    private static let waitingOnAlice = UXTestFixture(
        id: waitingOnAliceID,
        title: "Waiting on another player",
        detail: "Read-only local view while another player owns the turn.",
        defaultActorID: host,
        state: makeTurnFixture(
            rev: 10,
            currentPlayer: alice,
            turnState: TurnStateV1(step: .needsRoll, lastRoll: nil)
        )
    )

    private static let waitingOnDiscard = UXTestFixture(
        id: waitingOnDiscardID,
        title: "Waiting on discard",
        detail: "Seven was rolled; Theo is the next ordered discarder while the local player waits.",
        defaultActorID: host,
        state: makeTurnFixture(
            rev: 11,
            currentPlayer: alice,
            resourcesByPlayer: [
                host: ResourceHandV1(wood: 2, brick: 1, sheep: 1, wheat: 1, ore: 1),
                alice: ResourceHandV1(wood: 2, brick: 1, sheep: 1, wheat: 1, ore: 1),
                ben: ResourceHandV1(wood: 3, brick: 2, sheep: 2, wheat: 1, ore: 1),
            ],
            turnState: TurnStateV1(
                step: .pendingDiscards,
                lastRoll: DiceRollV1(d1: 4, d2: 3),
                discardRequirementsByPlayer: [ben: 4]
            )
        )
    )

    private static let pendingDiscard = UXTestFixture(
        id: "pending-discard",
        title: "Pending discard",
        detail: "Seven was rolled; local player must discard.",
        defaultActorID: host,
        state: makeTurnFixture(
            rev: 11,
            currentPlayer: alice,
            resourcesByPlayer: [
                host: ResourceHandV1(wood: 3, brick: 2, sheep: 2, wheat: 2, ore: 1),
                alice: ResourceHandV1(wood: 2, brick: 1, sheep: 1, wheat: 1, ore: 1),
                ben: ResourceHandV1(wood: 1, brick: 1, sheep: 1),
            ],
            turnState: TurnStateV1(
                step: .pendingDiscards,
                lastRoll: DiceRollV1(d1: 4, d2: 3),
                discardRequirementsByPlayer: [host: 5]
            )
        )
    )

    private static let robberMove = UXTestFixture(
        id: "robber-move",
        title: "Robber move",
        detail: "Current player must move the robber after a seven.",
        defaultActorID: host,
        state: makeTurnFixture(
            rev: 12,
            currentPlayer: host,
            turnState: TurnStateV1(
                step: .needsRobberMove,
                lastRoll: DiceRollV1(d1: 4, d2: 3)
            )
        )
    )

    private static let robberMoveAction = UXTestFixture(
        id: robberMoveActionID,
        title: "Robber move action",
        detail: "Canonical robber action state with award fields matching the placed pieces.",
        defaultActorID: host,
        state: makeTurnFixture(
            rev: 12,
            currentPlayer: host,
            largestArmyOwner: nil,
            largestArmySize: 0,
            longestRoadOwner: nil,
            longestRoadLength: 0,
            turnState: TurnStateV1(
                step: .needsRobberMove,
                lastRoll: DiceRollV1(d1: 4, d2: 3)
            )
        )
    )

    private static let robberVictim = UXTestFixture(
        id: robberVictimID,
        title: "Robber victim",
        detail: "The robber moved beside an opponent; the active player must choose a victim.",
        defaultActorID: host,
        state: {
            let state = robberMove.state
            for tileID in state.legalRobberMoveTiles(for: host) {
                guard let moved = try? apply(
                    intent: .moveRobber(tileID: tileID),
                    to: state,
                    actor: host
                ) else { continue }
                if moved.turnState?.step == .needsRobberSteal {
                    return moved
                }
            }
            preconditionFailure("Robber victim fixture requires a destination beside an opponent.")
        }()
    )

    private static let robberVictimAction = UXTestFixture(
        id: robberVictimActionID,
        title: "Robber victim action",
        detail: "Canonical adjacent-victim action state derived through the rules engine.",
        defaultActorID: host,
        state: {
            let state = robberMoveAction.state
            for tileID in state.legalRobberMoveTiles(for: host) {
                guard let moved = try? apply(
                    intent: .moveRobber(tileID: tileID),
                    to: state,
                    actor: host
                ) else { continue }
                if moved.turnState?.step == .needsRobberSteal {
                    return moved
                }
            }
            preconditionFailure("Robber victim action fixture requires a destination beside an opponent.")
        }()
    )

    private static let tradeOffer = UXTestFixture(
        id: "trade-offer",
        title: "Trade offer received",
        detail: "Local player can review another player's offer.",
        defaultActorID: host,
        state: {
            let offer = TradeOfferV1(
                offerHash: "ux-trade-offer-1",
                proposer: alice,
                give: ResourceHandV1(sheep: 2),
                receive: ResourceHandV1(ore: 1),
                recipients: [host, ben],
                createdRev: 13
            )
            return makeTurnFixture(
                rev: 13,
                currentPlayer: alice,
                activeTradeOffer: offer,
                tradeResponses: [
                    TradeResponseV1(
                        respondingPlayer: ben,
                        offerHash: offer.offerHash,
                        kind: .counter,
                        respondedAtRev: 14,
                        counterGive: ResourceHandV1(wheat: 1),
                        counterReceive: ResourceHandV1(brick: 1)
                    )
                ],
                turnState: TurnStateV1(
                    step: .afterRoll,
                    lastRoll: DiceRollV1(d1: 2, d2: 4)
                )
            )
        }()
    )

    private static let multiTypeTradeOffer = UXTestFixture(
        id: multiTypeTradeOfferID,
        title: "Multi-type trade offer received",
        detail: "Local player can review an offer containing several resource types on both sides.",
        defaultActorID: host,
        state: {
            let offer = TradeOfferV1(
                offerHash: "ux-trade-offer-multi-1",
                proposer: alice,
                give: ResourceHandV1(wood: 1, sheep: 2, wheat: 1),
                receive: ResourceHandV1(brick: 2, ore: 1),
                recipients: [host, ben],
                createdRev: 15
            )
            return makeTurnFixture(
                rev: 15,
                currentPlayer: alice,
                activeTradeOffer: offer,
                turnState: TurnStateV1(
                    step: .afterRoll,
                    lastRoll: DiceRollV1(d1: 3, d2: 3)
                )
            )
        }()
    )

    private static let victoryAction = UXTestFixture(
        id: victoryActionID,
        title: "Victory action",
        detail: "Reveal the final Victory Point through the live Hand control to end the game.",
        defaultActorID: host,
        state: makeTurnFixture(
            rev: 17,
            currentPlayer: host,
            devCardsByPlayer: [
                host: DevCardInventoryV1(victoryPoint: 1),
                alice: .zero,
                ben: .zero,
            ],
            newDevCardsByPlayer: [:],
            revealedVictoryPointsByPlayer: [host: 4],
            settlementsByNode: defaultSettlements,
            citiesByNode: defaultCities,
            roadsByEdge: defaultRoads,
            knightsPlayedByPlayer: [host: 3, alice: 1],
            largestArmyOwner: host,
            largestArmySize: 3,
            longestRoadOwner: nil,
            longestRoadLength: 0,
            turnState: TurnStateV1(
                step: .afterRoll,
                lastRoll: DiceRollV1(d1: 5, d2: 3)
            )
        )
    )

    private static let gameOver = UXTestFixture(
        id: "game-over",
        title: "Game over",
        detail: "Winner, final score, and recap surface.",
        defaultActorID: host,
        state: makeTurnFixture(
            rev: 18,
            currentPlayer: host,
            phase: .gameOver,
            devCardsByPlayer: [
                host: DevCardInventoryV1(knight: 1, monopoly: 1, yearOfPlenty: 1, roadBuilding: 1),
                alice: DevCardInventoryV1(knight: 1),
            ],
            newDevCardsByPlayer: [:],
            revealedVictoryPointsByPlayer: [host: 5],
            auditLog: [
                AuditEntryV1(rev: 7, actor: host, action: .playKnight),
                AuditEntryV1(rev: 15, actor: host, action: .playRoadBuilding),
                AuditEntryV1(rev: 18, actor: host, action: .revealVictoryPoint),
            ],
            settlementsByNode: defaultSettlements,
            citiesByNode: defaultCities,
            roadsByEdge: defaultRoads,
            knightsPlayedByPlayer: [host: 3, alice: 1],
            largestArmyOwner: host,
            largestArmySize: 3,
            longestRoadOwner: nil,
            longestRoadLength: 0,
            winnerPlayer: host,
            winningVictoryPoints: 10,
            lastTurnRecap: TurnRecapV1(
                actor: host,
                startRev: 15,
                endRev: 18,
                rollTotal: 8,
                actions: [.rollDice, .buildCity, .endTurn]
            ),
            turnState: nil
        )
    )

    private static let tutorialVictory = UXTestFixture(
        id: tutorialVictoryID,
        title: "Tutorial victory table",
        detail: "A live table whose game information shows ten points and both awards.",
        defaultActorID: host,
        state: makeTurnFixture(
            rev: 17,
            currentPlayer: host,
            revealedVictoryPointsByPlayer: [host: 5],
            turnState: TurnStateV1(
                step: .afterRoll,
                lastRoll: DiceRollV1(d1: 5, d2: 3)
            )
        )
    )

    private static func makeTurnFixture(
        rev: Int,
        currentPlayer: String,
        phase: PhaseV1 = .turn,
        resourcesByPlayer: [String: ResourceHandV1] = defaultResources,
        devCardsByPlayer: [String: DevCardInventoryV1] = defaultDevCardsByPlayer,
        newDevCardsByPlayer: [String: DevCardInventoryV1] = defaultNewDevCardsByPlayer,
        revealedVictoryPointsByPlayer: [String: Int] = [:],
        auditLog: [AuditEntryV1] = [],
        activeTradeOffer: TradeOfferV1? = nil,
        tradeResponses: [TradeResponseV1] = [],
        settlementsByNode: [NodeID: String] = defaultSettlements,
        citiesByNode: [NodeID: String] = defaultCities,
        roadsByEdge: [EdgeID: String] = defaultRoads,
        knightsPlayedByPlayer: [String: Int] = [host: 2, alice: 1],
        largestArmyOwner: String? = host,
        largestArmySize: Int = 2,
        longestRoadOwner: String? = alice,
        longestRoadLength: Int = 5,
        winnerPlayer: String? = nil,
        winningVictoryPoints: Int = 0,
        lastTurnRecap: TurnRecapV1? = nil,
        turnState: TurnStateV1?
    ) -> CoreGameStateV1 {
        makeState(
            rev: rev,
            currentPlayer: currentPlayer,
            phase: phase,
            resourcesByPlayer: resourcesByPlayer,
            devCardsByPlayer: devCardsByPlayer,
            newDevCardsByPlayer: newDevCardsByPlayer,
            revealedVictoryPointsByPlayer: revealedVictoryPointsByPlayer,
            auditLog: auditLog,
            activeTradeOffer: activeTradeOffer,
            tradeResponses: tradeResponses,
            settlementsByNode: settlementsByNode,
            citiesByNode: citiesByNode,
            roadsByEdge: roadsByEdge,
            knightsPlayedByPlayer: knightsPlayedByPlayer,
            largestArmyOwner: largestArmyOwner,
            largestArmySize: largestArmySize,
            longestRoadOwner: longestRoadOwner,
            longestRoadLength: longestRoadLength,
            winnerPlayer: winnerPlayer,
            winningVictoryPoints: winningVictoryPoints,
            lastTurnRecap: lastTurnRecap,
            turnState: turnState
        )
    }

    private static func makeState(
        rev: Int,
        roster: [String] = roster,
        currentPlayer: String = host,
        phase: PhaseV1,
        seed: UInt64? = 9_001,
        diceRngState: UInt64? = 9_002,
        robberRngState: UInt64? = 9_003,
        resourcesByPlayer: [String: ResourceHandV1] = defaultResources,
        devCardsByPlayer: [String: DevCardInventoryV1] = defaultDevCardsByPlayer,
        newDevCardsByPlayer: [String: DevCardInventoryV1] = defaultNewDevCardsByPlayer,
        revealedVictoryPointsByPlayer: [String: Int] = [:],
        auditLog: [AuditEntryV1] = [],
        activeTradeOffer: TradeOfferV1? = nil,
        tradeResponses: [TradeResponseV1] = [],
        settlementsByNode: [NodeID: String] = defaultSettlements,
        citiesByNode: [NodeID: String] = defaultCities,
        roadsByEdge: [EdgeID: String] = defaultRoads,
        boardRules: BoardRulesV1? = boardRules,
        board: BoardSetupV1? = board,
        setupState: SetupStateV1? = nil,
        knightsPlayedByPlayer: [String: Int] = [host: 2, alice: 1],
        largestArmyOwner: String? = host,
        largestArmySize: Int = 2,
        longestRoadOwner: String? = alice,
        longestRoadLength: Int = 5,
        winnerPlayer: String? = nil,
        winningVictoryPoints: Int = 0,
        lastTurnRecap: TurnRecapV1? = nil,
        turnState: TurnStateV1? = nil
    ) -> CoreGameStateV1 {
        CoreGameStateV1(
            gameId: "ux-single-device-game",
            rev: rev,
            prevHash: rev > 0 ? "ux-prev-\(rev - 1)" : nil,
            stateHash: "",
            roster: roster,
            currentPlayer: currentPlayer,
            playerDisplayNamesByPlayer: displayNames,
            phase: phase,
            seed: seed,
            diceRngState: diceRngState,
            robberRngState: robberRngState,
            resourcesByPlayer: resourcesByPlayer,
            bankResources: fullBank,
            devDeck: devDeck,
            devCardsByPlayer: devCardsByPlayer,
            newDevCardsByPlayer: newDevCardsByPlayer,
            revealedVictoryPointsByPlayer: revealedVictoryPointsByPlayer,
            knightsPlayedByPlayer: knightsPlayedByPlayer,
            largestArmyOwner: largestArmyOwner,
            largestArmySize: largestArmySize,
            longestRoadOwner: longestRoadOwner,
            longestRoadLength: longestRoadLength,
            winnerPlayer: winnerPlayer,
            winningVictoryPoints: winningVictoryPoints,
            auditLog: auditLog,
            lastTurnRecap: lastTurnRecap,
            activeTradeOffer: activeTradeOffer,
            tradeResponses: tradeResponses,
            settlementsByNode: settlementsByNode,
            citiesByNode: citiesByNode,
            roadsByEdge: roadsByEdge,
            boardRules: boardRules,
            board: board,
            setupState: setupState,
            turnState: turnState
        ).rehashed()
    }

    private static func makeInitialSetupState() -> CoreGameStateV1 {
        makeState(
            rev: 3,
            currentPlayer: host,
            phase: .setup,
            resourcesByPlayer: Dictionary(
                uniqueKeysWithValues: roster.map { ($0, ResourceHandV1.zero) }
            ),
            devCardsByPlayer: [:],
            newDevCardsByPlayer: [:],
            settlementsByNode: [:],
            citiesByNode: [:],
            roadsByEdge: [:],
            setupState: initializeSetupState(roster: roster)
        )
    }

    private static func reidentified(
        _ state: CoreGameStateV1,
        gameId: String
    ) -> CoreGameStateV1 {
        CoreGameStateV1(
            gameId: gameId,
            rev: state.rev,
            prevHash: state.prevHash,
            stateHash: "",
            roster: state.roster,
            currentPlayer: state.currentPlayer,
            playerDisplayNamesByPlayer: state.playerDisplayNamesByPlayer,
            phase: state.phase,
            seed: state.seed,
            diceRngState: state.diceRngState,
            robberRngState: state.robberRngState,
            resourcesByPlayer: state.resourcesByPlayer,
            bankResources: state.bankResources,
            devDeck: state.devDeck,
            devCardsByPlayer: state.devCardsByPlayer,
            newDevCardsByPlayer: state.newDevCardsByPlayer,
            revealedVictoryPointsByPlayer: state.revealedVictoryPointsByPlayer,
            devCardActionPlayedThisTurn: state.devCardActionPlayedThisTurn,
            knightsPlayedByPlayer: state.knightsPlayedByPlayer,
            largestArmyOwner: state.largestArmyOwner,
            largestArmySize: state.largestArmySize,
            longestRoadOwner: state.longestRoadOwner,
            longestRoadLength: state.longestRoadLength,
            winnerPlayer: state.winnerPlayer,
            winningVictoryPoints: state.winningVictoryPoints,
            gameResult: state.gameResult,
            auditLog: state.auditLog,
            lastTurnRecap: state.lastTurnRecap,
            activeTradeOffer: state.activeTradeOffer,
            tradeResponses: state.tradeResponses,
            settlementsByNode: state.settlementsByNode,
            citiesByNode: state.citiesByNode,
            roadsByEdge: state.roadsByEdge,
            boardRules: state.boardRules,
            board: state.board,
            setupState: state.setupState,
            turnState: state.turnState
        ).rehashed()
    }

    private static func makeSetupRoadPlacementState() -> CoreGameStateV1 {
        let state = makeInitialSetupState()
        guard let node = state.legalSetupSettlementNodes(for: host).first else {
            preconditionFailure("Setup fixture requires a legal first settlement.")
        }
        do {
            return try apply(intent: .placeSetupSettlement(node: node), to: state, actor: host)
        } catch {
            preconditionFailure("Unable to build setup road fixture: \(error)")
        }
    }

    private static func makeSetupHandoffState() -> CoreGameStateV1 {
        var state = makeInitialSetupState()

        do {
            while state.phase == .setup {
                guard let setupState = state.setupState else {
                    preconditionFailure("Setup fixture lost setup state before handoff.")
                }
                let actor = state.currentPlayer
                switch setupState.step {
                case .placeSettlement:
                    guard let node = state.legalSetupSettlementNodes(for: actor).first else {
                        preconditionFailure("Setup fixture requires a legal settlement for \(actor).")
                    }
                    state = try apply(intent: .placeSetupSettlement(node: node), to: state, actor: actor)
                case .placeRoad:
                    guard let edge = state.legalSetupRoadEdges(for: actor).first else {
                        preconditionFailure("Setup fixture requires a legal road for \(actor).")
                    }
                    state = try apply(intent: .placeSetupRoad(edge: edge), to: state, actor: actor)
                case .done:
                    preconditionFailure("Setup fixture reached an unpublishable done step.")
                }
            }
        } catch {
            preconditionFailure("Unable to build setup handoff fixture: \(error)")
        }

        return state
    }

    private static let defaultResources = [
        host: ResourceHandV1(wood: 5, brick: 5, sheep: 5, wheat: 5, ore: 5),
        alice: ResourceHandV1(wood: 1, brick: 2, sheep: 3, wheat: 1, ore: 1),
        ben: ResourceHandV1(wood: 2, brick: 1, sheep: 1, wheat: 3),
    ]

    private static let defaultDevCardsByPlayer = [
        host: DevCardInventoryV1(
            knight: 1,
            monopoly: 1,
            yearOfPlenty: 1,
            roadBuilding: 1,
            victoryPoint: 1
        ),
        alice: DevCardInventoryV1(knight: 1),
    ]

    private static let defaultNewDevCardsByPlayer = [
        host: DevCardInventoryV1(victoryPoint: 1),
    ]

    /// The shared DEBUG table is intentionally produced through the Core reducer.
    /// This prevents visual fixtures from inventing disconnected roads or buildings
    /// that could never occur in a real game.
    private static let defaultPositionState: CoreGameStateV1 = {
        let completedSetup = makeSetupHandoffState()
        let buildReady = makeState(
            rev: completedSetup.rev,
            currentPlayer: host,
            phase: .turn,
            settlementsByNode: completedSetup.settlementsByNode,
            citiesByNode: completedSetup.citiesByNode,
            roadsByEdge: completedSetup.roadsByEdge,
            largestArmyOwner: nil,
            largestArmySize: 0,
            longestRoadOwner: nil,
            longestRoadLength: 0,
            turnState: TurnStateV1(
                step: .afterRoll,
                lastRoll: DiceRollV1(d1: 3, d2: 5)
            )
        )

        for edgeID in buildReady.legalBuildRoadEdges(for: host) {
            guard let withRoad = try? apply(
                intent: .buildRoad(edgeID: edgeID),
                to: buildReady,
                actor: host
            ),
            !withRoad.legalBuildSettlementNodes(for: host).isEmpty,
            let cityNode = withRoad.legalBuildCityNodes(for: host).first,
            let withCity = try? apply(
                intent: .buildCity(nodeID: cityNode),
                to: withRoad,
                actor: host
            )
            else { continue }

            return withCity
        }

        preconditionFailure("UX fixture requires a reducer-derived road and city position.")
    }()

    private static let defaultSettlements = defaultPositionState.settlementsByNode
    private static let defaultCities = defaultPositionState.citiesByNode
    private static let defaultRoads = defaultPositionState.roadsByEdge

}
#endif
