import XCTest
import ULS_CoreGame
@testable import MessagesExtension

final class GameNormalTurnInteractionResolverTests: XCTestCase {
    func testEnteringAndLeavingNormalPostRollContextRequireReset() {
        let inactive = snapshot(
            revision: 5,
            stateHash: "before-roll",
            turnStep: "needsRoll",
            isActive: false
        )
        let active = snapshot(
            revision: 6,
            stateHash: "after-roll",
            isActive: true
        )

        XCTAssertEqual(
            GameNormalTurnInteractionResolver.transition(from: inactive, to: active),
            .entered
        )
        XCTAssertEqual(
            GameNormalTurnInteractionResolver.transition(from: active, to: inactive),
            .left
        )
    }

    func testForwardRevisionInSameTurnPreservesInteractionContext() {
        let beforePurchase = snapshot(revision: 8, stateHash: "before", isActive: true)
        let afterPurchase = snapshot(revision: 9, stateHash: "after", isActive: true)

        XCTAssertEqual(
            GameNormalTurnInteractionResolver.transition(from: beforePurchase, to: afterPurchase),
            .updated
        )
    }

    func testOwnerGameAndCanonicalStateReplacementStartFreshContext() {
        let current = snapshot(revision: 8, stateHash: "current", isActive: true)

        XCTAssertEqual(
            GameNormalTurnInteractionResolver.transition(
                from: current,
                to: snapshot(
                    gameID: "game-2",
                    revision: 1,
                    stateHash: "new-game",
                    isActive: true
                )
            ),
            .replaced
        )
        XCTAssertEqual(
            GameNormalTurnInteractionResolver.transition(
                from: current,
                to: snapshot(
                    revision: 12,
                    stateHash: "same-owner-next-turn",
                    turnRecapMarker: "different-previous-turn",
                    isActive: true
                )
            ),
            .replaced
        )
        XCTAssertEqual(
            GameNormalTurnInteractionResolver.transition(
                from: current,
                to: snapshot(
                    revision: 9,
                    stateHash: "next-owner",
                    turnOwner: "ben",
                    isActive: true
                )
            ),
            .replaced
        )
        XCTAssertEqual(
            GameNormalTurnInteractionResolver.transition(
                from: current,
                to: snapshot(revision: 8, stateHash: "fork", isActive: true)
            ),
            .replaced
        )
        XCTAssertEqual(
            GameNormalTurnInteractionResolver.transition(
                from: current,
                to: snapshot(revision: 7, stateHash: "older", isActive: true)
            ),
            .replaced
        )
    }

    func testUnavailableExecutableRoutesCloseWithoutClosingInformationalRoutes() {
        let unavailable = GameNormalTurnRouteAvailability(
            canBuild: false,
            canTrade: false,
            canPlayDevCard: false,
            canEndTurn: false
        )

        XCTAssertEqual(normalize(.build, availability: unavailable), .none)
        XCTAssertEqual(normalize(.trade(.chooser), availability: unavailable), .none)
        XCTAssertEqual(normalize(.devCards, availability: unavailable), .none)
        XCTAssertEqual(normalize(.endTurnConfirmation, availability: unavailable), .none)
        XCTAssertEqual(normalize(.utility(.bank), availability: unavailable), .utility(.bank))
        XCTAssertEqual(normalize(.gameInfo, availability: unavailable), .gameInfo)
    }

    func testAvailableExecutableRoutesSurviveSameContextUpdates() {
        let available = GameNormalTurnRouteAvailability(
            canBuild: true,
            canTrade: true,
            canPlayDevCard: true,
            canEndTurn: true
        )
        let draft = GameTradeDraft(
            kind: .offer,
            give: .zero,
            receive: .zero,
            recipients: ["ben"]
        )

        XCTAssertEqual(normalize(.build, availability: available), .build)
        XCTAssertEqual(normalize(.devCards, availability: available), .devCards)
        XCTAssertEqual(
            normalize(.trade(.playerDraft(draft)), availability: available),
            .trade(.playerDraft(draft))
        )
        XCTAssertEqual(
            normalize(.endTurnConfirmation, availability: available),
            .endTurnConfirmation
        )
    }

    private func normalize(
        _ route: GameShellRoute,
        availability: GameNormalTurnRouteAvailability
    ) -> GameShellRoute {
        GameNormalTurnInteractionResolver.normalizedRoute(
            route,
            availability: availability
        )
    }

    private func snapshot(
        gameID: String = "game-1",
        revision: Int,
        stateHash: String,
        turnStep: String = "afterRoll",
        turnOwner: String = "alice",
        turnRecapMarker: String = "previous-turn",
        isActive: Bool
    ) -> GameNormalTurnContextSnapshot {
        GameNormalTurnContextSnapshot(
            gameID: gameID,
            revision: revision,
            stateHash: stateHash,
            turnStep: turnStep,
            turnOwner: turnOwner,
            turnRecapMarker: turnRecapMarker,
            isLocalActivePostRoll: isActive
        )
    }
}
