import XCTest
import ULS_CoreGame
@testable import MessagesExtensionSupport

final class LobbyMembershipResolverTests: XCTestCase {
    func testJoinedLobbyStateCarriesSubmittedDisplayName() throws {
        let host = "host"
        let guest = "guest"
        let state = makeLobbyState(roster: [host], customNames: [host: "Hosty"])

        let joined = try XCTUnwrap(
            LobbyMembershipResolver.joinedLobbyState(
                state: state,
                localParticipant: guest,
                displayName: "Kunal"
            )
        )

        XCTAssertEqual(joined.playerDisplayNamesByPlayer[host], "Hosty")
        XCTAssertEqual(joined.playerDisplayNamesByPlayer[guest], "Kunal")
        XCTAssertEqual(joined.resourcesByPlayer[guest], .zero)
        XCTAssertEqual(joined.devCardsByPlayer[guest], .zero)
        XCTAssertEqual(joined.newDevCardsByPlayer[guest], .zero)
        XCTAssertEqual(joined.revealedVictoryPointsByPlayer[guest], 0)
        XCTAssertEqual(joined.knightsPlayedByPlayer[guest], 0)
        XCTAssertNoThrow(try validateTransition(from: state, to: joined, actor: guest))
    }

    func testRenamedLobbyStateUpdatesOnlyJoinedPlayerName() throws {
        let host = "host"
        let guest = "guest"
        let state = makeLobbyState(
            roster: [host, guest],
            customNames: [host: "Hosty", guest: "Guesty"]
        )

        let renamed = try XCTUnwrap(
            LobbyMembershipResolver.renamedLobbyState(
                state: state,
                localParticipant: guest,
                displayName: "Kunal"
            )
        )

        XCTAssertEqual(renamed.playerDisplayNamesByPlayer[host], "Hosty")
        XCTAssertEqual(renamed.playerDisplayNamesByPlayer[guest], "Kunal")
        XCTAssertEqual(renamed.rev, state.rev + 1)
        XCTAssertNoThrow(try validateTransition(from: state, to: renamed, actor: guest))
    }

    func testLobbyJoinValidationRejectsWrongActor() throws {
        let host = "host"
        let guest = "guest"
        let state = makeLobbyState(roster: [host], customNames: [host: "Hosty"])
        let joined = try XCTUnwrap(
            LobbyMembershipResolver.joinedLobbyState(
                state: state,
                localParticipant: guest,
                displayName: "Guesty"
            )
        )

        XCTAssertThrowsError(try validateTransition(from: state, to: joined, actor: host)) { error in
            XCTAssertEqual(error as? CoreGameError, .actorMismatch)
        }
    }

    func testLobbyValidationRejectsRosterReorder() {
        let host = "host"
        let guest = "guest"
        let state = makeLobbyState(
            roster: [host, guest],
            customNames: [host: "Hosty", guest: "Guesty"]
        )
        let reordered = makeLobbyTransition(
            from: state,
            roster: [guest, host],
            customNames: state.playerDisplayNamesByPlayer
        )

        XCTAssertThrowsError(try validateTransition(from: state, to: reordered, actor: guest)) { error in
            XCTAssertEqual(error as? CoreGameError, .rosterChanged)
        }
    }

    func testLobbyValidationRejectsRosterRemoval() {
        let host = "host"
        let guest = "guest"
        let state = makeLobbyState(
            roster: [host, guest],
            customNames: [host: "Hosty", guest: "Guesty"]
        )
        let removed = makeLobbyTransition(
            from: state,
            roster: [host],
            customNames: state.playerDisplayNamesByPlayer
        )

        XCTAssertThrowsError(try validateTransition(from: state, to: removed, actor: guest)) { error in
            XCTAssertEqual(error as? CoreGameError, .rosterChanged)
        }
    }

    func testLobbyRenameValidationRejectsChangingAnotherPlayerName() {
        let host = "host"
        let guest = "guest"
        let state = makeLobbyState(
            roster: [host, guest],
            customNames: [host: "Hosty", guest: "Guesty"]
        )
        var tamperedNames = state.playerDisplayNamesByPlayer
        tamperedNames[host] = "Other Host"
        let tampered = makeLobbyTransition(
            from: state,
            customNames: tamperedNames
        )

        XCTAssertThrowsError(try validateTransition(from: state, to: tampered, actor: guest)) { error in
            XCTAssertEqual(error as? CoreGameError, .playerDisplayNamesChanged)
        }
    }

    private func makeLobbyState(
        roster: [String],
        customNames: [String: String]
    ) -> CoreGameStateV1 {
        CoreGameStateV1(
            gameId: "lobby-membership-tests",
            rev: 0,
            prevHash: nil,
            stateHash: "",
            roster: roster,
            currentPlayer: roster[0],
            playerDisplayNamesByPlayer: customNames,
            phase: .lobby,
            seed: nil,
            diceRngState: nil,
            resourcesByPlayer: Dictionary(uniqueKeysWithValues: roster.map { ($0, .zero) }),
            boardRules: nil,
            board: nil
        ).rehashed()
    }

    private func makeLobbyTransition(
        from state: CoreGameStateV1,
        roster: [String]? = nil,
        customNames: [String: String]? = nil
    ) -> CoreGameStateV1 {
        let nextRoster = roster ?? state.roster
        return CoreGameStateV1(
            gameId: state.gameId,
            rev: state.rev + 1,
            prevHash: state.stateHash,
            stateHash: "",
            roster: nextRoster,
            currentPlayer: state.currentPlayer,
            playerDisplayNamesByPlayer: customNames ?? state.playerDisplayNamesByPlayer,
            phase: .lobby,
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
}
