import XCTest
import ULS_CoreGame
@testable import MessagesExtensionSupport

final class PlayerRecordModelTests: XCTestCase {
    func testRecoveryPreviewUsesOnlyCanonicalSnapshots() {
        let states = UXTestFixtures.recoveryStates

        XCTAssertEqual(states.count, 8)
        for state in states {
            XCTAssertNoThrow(try validateCanonicalSnapshot(state), state.gameId)
        }
    }

    func testBuildCalculatesOverallResultsAndExactPlayerGroup() {
        let records = [
            recovered(
                finishedState(
                    gameId: "win",
                    roster: ["me", "friend"],
                    winners: ["me"],
                    scores: ["me": 10, "friend": 7]
                ),
                actor: "me",
                updatedAt: 30
            ),
            recovered(
                finishedState(
                    gameId: "draw",
                    roster: ["me", "friend"],
                    reason: .draw,
                    scores: ["me": 8, "friend": 8]
                ),
                actor: "me",
                updatedAt: 20
            ),
            recovered(
                finishedState(
                    gameId: "resigned",
                    roster: ["me", "other"],
                    scores: ["me": 4, "other": 6],
                    resignedPlayers: ["me"]
                ),
                actor: "me",
                updatedAt: 10
            ),
        ]

        let model = PlayerRecordModelBuilder.build(
            from: records,
            currentParticipantIDs: ["me", "friend"]
        )

        XCTAssertEqual(model.overall.stats.completedGames, 3)
        XCTAssertEqual(model.overall.stats.wins, 1)
        XCTAssertEqual(model.overall.stats.losses, 1)
        XCTAssertEqual(model.overall.stats.draws, 1)
        XCTAssertEqual(model.overall.stats.resignations, 1)
        XCTAssertEqual(model.overall.stats.winRateText, "33%")
        XCTAssertEqual(model.overall.stats.currentWinStreak, 1)
        XCTAssertEqual(model.withCurrentGroup.games.map(\.id), ["win", "draw"])
        XCTAssertEqual(model.withCurrentGroup.stats.completedGames, 2)
        XCTAssertEqual(model.withCurrentGroup.stats.wins, 1)
        XCTAssertEqual(model.currentGroupNamesText, "Friend")
        XCTAssertEqual(model.currentGroupStandings.map(\.wins), [1, 0])
        XCTAssertTrue(model.currentGroupStandings.first?.isLocalPlayer == true)
        XCTAssertTrue(model.hasCurrentGroup)
    }

    func testBuildKeepsUnknownIdentityVisibleButOutOfPersonalStats() {
        let state = finishedState(
            gameId: "legacy",
            roster: ["a", "b"],
            winners: ["a"],
            scores: ["a": 10, "b": 6]
        )

        let model = PlayerRecordModelBuilder.build(
            from: [recovered(state, actor: nil, updatedAt: 1)],
            currentParticipantIDs: []
        )

        XCTAssertEqual(model.overall.games.count, 1)
        XCTAssertEqual(model.overall.stats, .empty)
        XCTAssertEqual(model.overall.unidentifiedGameCount, 1)
        XCTAssertEqual(model.overall.games.first?.outcomeText, "Finished · player identity unavailable")
        XCTAssertEqual(model.overall.games.first?.outcomeKind, .unidentified)
        XCTAssertFalse(model.hasCurrentGroup)
    }

    func testInProgressRecordExplainsBubbleContinuationAndDoesNotCountAsCompleted() {
        let state = CoreGameStateV1(
            gameId: "active",
            rev: 2,
            prevHash: nil,
            stateHash: "",
            roster: ["me", "friend"],
            currentPlayer: "friend",
            phase: .turn,
            seed: 1,
            diceRngState: 2
        )

        let model = PlayerRecordModelBuilder.build(
            from: [recovered(state, actor: "me", updatedAt: 1)],
            currentParticipantIDs: ["me", "friend"]
        )

        XCTAssertEqual(model.overall.stats.completedGames, 0)
        XCTAssertEqual(
            model.overall.games.first?.outcomeText,
            "In progress · open its game bubble to continue"
        )
        XCTAssertTrue(
            model.overall.games.first?.accessibilityLabel.contains(
                "open its game bubble to continue"
            ) == true
        )
    }

    func testResignationCountsWhenCanonicalGameContinues() {
        let state = CoreGameStateV1(
            gameId: "resigned-active",
            rev: 4,
            prevHash: nil,
            stateHash: "",
            roster: ["me", "friend", "other"],
            currentPlayer: "friend",
            phase: .turn,
            seed: 1,
            diceRngState: 2,
            resignedPlayers: ["me"]
        )

        let model = PlayerRecordModelBuilder.build(
            from: [recovered(state, actor: "me", updatedAt: 1)],
            currentParticipantIDs: ["me", "friend", "other"]
        )

        XCTAssertEqual(model.overall.stats.completedGames, 1)
        XCTAssertEqual(model.overall.stats.losses, 1)
        XCTAssertEqual(model.overall.stats.resignations, 1)
        XCTAssertEqual(model.overall.games.first?.outcomeText, "Resigned · game continues")
        XCTAssertEqual(model.overall.games.first?.outcomeKind, .resigned)
    }

    func testBuildCalculatesTableHonorsDiceAndFastestWinFromCanonicalHistory() {
        let firstWin = finishedState(
            gameId: "first-win",
            roster: ["me", "friend"],
            winners: ["me"],
            scores: ["me": 10, "friend": 8],
            auditLog: [
                AuditEntryV1(rev: 1, actor: "me", action: .rollDice, rollTotal: 7),
                AuditEntryV1(rev: 2, actor: "me", action: .endTurn),
                AuditEntryV1(rev: 3, actor: "friend", action: .endTurn),
                AuditEntryV1(rev: 4, actor: "me", action: .buildCity),
            ],
            largestArmyOwner: "me",
            largestArmySize: 5,
            longestRoadOwner: "me",
            longestRoadLength: 8
        )
        let secondWin = finishedState(
            gameId: "second-win",
            roster: ["me", "friend"],
            winners: ["me"],
            scores: ["me": 10, "friend": 9],
            auditLog: [
                AuditEntryV1(rev: 1, actor: "me", action: .rollDice, rollTotal: 7),
                AuditEntryV1(rev: 2, actor: "me", action: .rollDice, rollTotal: 7),
                AuditEntryV1(rev: 3, actor: "me", action: .buildSettlement),
            ],
            largestArmyOwner: "friend",
            largestArmySize: 6,
            longestRoadOwner: "me",
            longestRoadLength: 11
        )

        let model = PlayerRecordModelBuilder.build(
            from: [
                recovered(secondWin, actor: "me", updatedAt: 20),
                recovered(firstWin, actor: "me", updatedAt: 10),
            ],
            currentParticipantIDs: ["me", "friend"]
        )

        XCTAssertEqual(model.overall.stats.fastestWinTurns, 1)
        XCTAssertEqual(model.overall.stats.currentWinStreak, 2)
        XCTAssertEqual(model.overall.stats.longestRoadRecord, 11)
        XCTAssertEqual(model.overall.stats.longestRoadTitles, 2)
        XCTAssertEqual(model.overall.stats.largestArmyRecord, 5)
        XCTAssertEqual(model.overall.stats.largestArmyTitles, 1)
        XCTAssertEqual(model.overall.stats.sevenRolls, 3)
    }

    func testMostUsedResourceUsesOnlyLocalPaidPurchaseCosts() {
        let state = finishedState(
            gameId: "resource-leader",
            roster: ["me", "friend"],
            winners: ["me"],
            scores: ["me": 10, "friend": 8],
            auditLog: [
                AuditEntryV1(rev: 1, actor: "me", action: .buildCity),
                AuditEntryV1(rev: 2, actor: "me", action: .buildCity),
                AuditEntryV1(rev: 3, actor: "me", action: .buyDevCard),
                AuditEntryV1(rev: 4, actor: "friend", action: .buildRoad),
            ]
        )

        let model = PlayerRecordModelBuilder.build(
            from: [recovered(state, actor: "me", updatedAt: 1)],
            currentParticipantIDs: ["me", "friend"]
        )

        XCTAssertEqual(model.overall.stats.mostUsedResource, .ore)
        XCTAssertNil(model.overall.games.first?.scoreText)
    }

    func testMostUsedResourceHasNoLeaderForTieOrMissingSpending() {
        let tied = finishedState(
            gameId: "resource-tie",
            roster: ["me", "friend"],
            winners: ["friend"],
            scores: ["me": 8, "friend": 10],
            auditLog: [AuditEntryV1(rev: 1, actor: "me", action: .buildRoad)]
        )
        let noSpending = finishedState(
            gameId: "no-resource-spending",
            roster: ["me", "friend"],
            winners: ["friend"],
            scores: ["me": 7, "friend": 10]
        )

        let tiedModel = PlayerRecordModelBuilder.build(
            from: [recovered(tied, actor: "me", updatedAt: 2)],
            currentParticipantIDs: ["me", "friend"]
        )
        let emptyModel = PlayerRecordModelBuilder.build(
            from: [recovered(noSpending, actor: "me", updatedAt: 1)],
            currentParticipantIDs: ["me", "friend"]
        )

        XCTAssertNil(tiedModel.overall.stats.mostUsedResource)
        XCTAssertNil(emptyModel.overall.stats.mostUsedResource)
        XCTAssertEqual(tiedModel.overall.games.first?.scoreText, "8 VP")
    }

    private func recovered(
        _ state: CoreGameStateV1,
        actor: String?,
        updatedAt: TimeInterval
    ) -> TranscriptGameLedgerRecoveredState {
        TranscriptGameLedgerRecoveredState(
            state: state,
            updatedAt: updatedAt,
            isLastActive: false,
            localActor: actor
        )
    }

    private func finishedState(
        gameId: String,
        roster: [String],
        reason: GameEndReasonV1 = .victory,
        winners: [String] = [],
        scores: [String: Int],
        resignedPlayers: [String] = [],
        auditLog: [AuditEntryV1] = [],
        largestArmyOwner: String? = nil,
        largestArmySize: Int = 0,
        longestRoadOwner: String? = nil,
        longestRoadLength: Int = 0
    ) -> CoreGameStateV1 {
        CoreGameStateV1(
            gameId: gameId,
            rev: 5,
            prevHash: nil,
            stateHash: "",
            roster: roster,
            currentPlayer: roster[0],
            playerDisplayNamesByPlayer: Dictionary(
                uniqueKeysWithValues: roster.map { ($0, $0.capitalized) }
            ),
            phase: .gameOver,
            seed: 1,
            diceRngState: 2,
            largestArmyOwner: largestArmyOwner,
            largestArmySize: largestArmySize,
            longestRoadOwner: longestRoadOwner,
            longestRoadLength: longestRoadLength,
            gameResult: GameResultV1(
                reason: reason,
                winnerPlayers: winners,
                finalScoresByPlayer: scores
            ),
            resignedPlayers: resignedPlayers,
            auditLog: auditLog
        )
    }
}
