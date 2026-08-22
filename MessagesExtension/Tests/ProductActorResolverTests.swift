import ULS_CoreGame
import XCTest
@testable import MessagesExtensionSupport

final class ProductActorResolverTests: XCTestCase {
    func testResolveReturnsJoinedLocalParticipant() {
        let state = makeState(roster: ["host", "guest"])

        XCTAssertEqual(
            ProductActorResolver.resolve(localParticipant: "guest", state: state),
            "guest"
        )
    }

    func testResolveRejectsObserverOrMissingIdentity() {
        let state = makeState(roster: ["host", "guest"])

        XCTAssertNil(ProductActorResolver.resolve(localParticipant: "observer", state: state))
        XCTAssertNil(ProductActorResolver.resolve(localParticipant: nil, state: state))
        XCTAssertNil(ProductActorResolver.resolve(localParticipant: "guest", state: nil))
    }

    private func makeState(roster: [String]) -> CoreGameStateV1 {
        CoreGameStateV1(
            gameId: "game-1",
            rev: 2,
            prevHash: "hash-1",
            stateHash: "",
            roster: roster,
            currentPlayer: roster.first ?? "host",
            phase: .turn,
            seed: 1,
            diceRngState: 2,
            robberRngState: 3,
            resourcesByPlayer: Dictionary(uniqueKeysWithValues: roster.map { ($0, .zero) }),
            boardRules: nil,
            board: nil
        ).rehashed()
    }
}
