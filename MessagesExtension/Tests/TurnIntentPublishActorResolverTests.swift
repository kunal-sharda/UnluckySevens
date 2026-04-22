import ULS_Transport
import XCTest
@testable import MessagesExtension

final class TurnIntentPublishActorResolverTests: XCTestCase {
    func testTradeResponseUsesRespondingActorWhenPublishingCanonicalState() {
        let intent = ULS_Transport.TurnIntentV1(
            acceptTradePlayer: "guest",
            offerHash: "offer-1",
            gameId: "game-1",
            anchorRev: 4,
            anchorHash: "hash-4",
            actor: "guest"
        )

        let actor = TurnIntentPublishActorResolver.resolve(intent, localActor: "host")

        XCTAssertEqual(actor, "guest")
    }

    func testDiscardUsesDiscardingActorWhenPublishingCanonicalState() {
        let intent = ULS_Transport.TurnIntentV1(
            submitDiscardFor: "guest",
            discarded: TransportResourceHandV1(wood: 1),
            gameId: "game-1",
            anchorRev: 4,
            anchorHash: "hash-4",
            actor: "guest"
        )

        let actor = TurnIntentPublishActorResolver.resolve(intent, localActor: "host")

        XCTAssertEqual(actor, "guest")
    }

    func testCurrentPlayerActionKeepsLocalActor() {
        let intent = ULS_Transport.TurnIntentV1(
            kind: .endTurn,
            gameId: "game-1",
            anchorRev: 4,
            anchorHash: "hash-4",
            actor: "host"
        )

        let actor = TurnIntentPublishActorResolver.resolve(intent, localActor: "host")

        XCTAssertEqual(actor, "host")
    }
}
