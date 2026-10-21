import XCTest
import ULS_CoreGame
@testable import MessagesExtensionSupport

final class LobbyPublicationReceiptValidatorTests: XCTestCase {
    func testHostReconciliationRequiresExactKnownParentAndClaims() throws {
        let root = makeLobby(roster: ["host"])
        let alice = try join("alice", to: root)
        let ben = try join("ben", to: root)
        let cara = try join("cara", to: root)
        let reconciled = try XCTUnwrap(
            reconcileLobbyV1(
                anchor: alice,
                observedStates: [root, alice, ben, cara],
                actor: "host"
            ).state
        )

        XCTAssertEqual(
            try LobbyPublicationReceiptValidator.validate(
                state: reconciled,
                observedStates: [root, alice, ben, cara]
            ),
            .hostReconciliation
        )
        XCTAssertThrowsError(
            try LobbyPublicationReceiptValidator.validate(
                state: reconciled,
                observedStates: [root, alice, ben]
            )
        ) { error in
            XCTAssertEqual(error as? LobbyPublicationReceiptError, .unauthorizedTransition)
        }
    }

    func testMemberAuthoredJoinValidatesItsStructurallyInferredActor() throws {
        let root = makeLobby(roster: ["host"])
        let alice = try join("alice", to: root)

        XCTAssertEqual(
            try LobbyPublicationReceiptValidator.validate(
                state: alice,
                observedStates: [root]
            ),
            .memberAuthored
        )
    }

    func testGenesisRequiresSoleCurrentHost() throws {
        let root = makeLobby(roster: ["host"])
        XCTAssertEqual(
            try LobbyPublicationReceiptValidator.validate(
                state: root,
                observedStates: []
            ),
            .genesis
        )
    }

    func testFreshDeviceBootstrapsJoinedLobbyAndCanReopenIt() throws {
        let root = makeLobby(roster: ["host"])
        let joined = try join("alice", to: root)
        XCTAssertEqual(try LobbyPublicationReceiptValidator.validate(state: joined, observedStates: []), .snapshotBootstrap)
        XCTAssertEqual(try LobbyPublicationReceiptValidator.validate(state: joined, observedStates: [joined]), .knownSnapshot)
    }

    func testExistingHistoryDoesNotBootstrapMissingParentOrAcceptTampering() throws {
        let root = makeLobby(roster: ["host"])
        let first = try join("alice", to: root)
        let second = try join("ben", to: first)
        XCTAssertThrowsError(try LobbyPublicationReceiptValidator.validate(state: second, observedStates: [root]))
        let invalid = CoreGameStateV1(gameId: "invalid", rev: 1, prevHash: "parent", stateHash: "wrong",
            roster: ["host"], currentPlayer: "host", phase: .lobby, seed: nil, diceRngState: nil,
            resourcesByPlayer: ["host": .zero])
        XCTAssertThrowsError(try LobbyPublicationReceiptValidator.validate(state: invalid, observedStates: []))
    }

    private func join(_ actor: String, to state: CoreGameStateV1) throws -> CoreGameStateV1 {
        let joined = makeLobby(
            rev: state.rev + 1,
            prevHash: state.stateHash,
            roster: state.roster + [actor]
        )
        try validateTransition(from: state, to: joined, actor: actor)
        return joined
    }

    private func makeLobby(
        rev: Int = 0,
        prevHash: String? = nil,
        roster: [String]
    ) -> CoreGameStateV1 {
        CoreGameStateV1(
            gameId: "lobby-receipt-tests",
            rev: rev,
            prevHash: prevHash,
            stateHash: "",
            roster: roster,
            currentPlayer: "host",
            phase: .lobby,
            seed: nil,
            diceRngState: nil,
            resourcesByPlayer: Dictionary(uniqueKeysWithValues: roster.map { ($0, .zero) })
        ).rehashed()
    }
}
