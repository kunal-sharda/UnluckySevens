import XCTest
@testable import ULS_CoreGame

final class LobbyReconciliationV1Tests: XCTestCase {
    func testSiblingJoinPermutationsProduceSameCanonicalUnion() throws {
        let root = makeLobby(roster: ["host"])
        let alice = try join("alice", to: root, name: "Alice")
        let ben = try join("ben", to: root, name: "Ben")
        let anchor = [alice, ben].max { $0.stateHash < $1.stateHash }!
        let resolutions = try permutations(of: [root, alice, ben]).map {
            try reconcileLobbyV1(anchor: anchor, observedStates: $0, actor: "host")
        }

        XCTAssertTrue(resolutions.allSatisfy { $0 == resolutions[0] })
        XCTAssertEqual(Set(resolutions[0].state?.roster ?? []), ["host", "alice", "ben"])
        XCTAssertEqual(resolutions[0].state?.playerDisplayNamesByPlayer["ben"], "Ben")
        XCTAssertEqual(resolutions[0].state?.resourcesByPlayer["ben"], .zero)
    }

    func testOnlyOriginalInviterCanReconcile() throws {
        let root = makeLobby(roster: ["host"])
        let alice = try join("alice", to: root)

        XCTAssertThrowsError(
            try reconcileLobbyV1(
                anchor: root,
                observedStates: [root, alice],
                actor: "alice"
            )
        ) { error in
            XCTAssertEqual(error as? CoreGameError, .actorMismatch)
        }
    }

    func testCapacityRetainsCanonicalRosterAndUsesDeterministicClaimPriority() throws {
        let root = makeLobby(roster: ["host", "canonical"])
        let claims = try ["alice", "ben", "casey"].map { try join($0, to: root) }

        let resolutions = try permutations(of: [root] + claims).map {
            try reconcileLobbyV1(anchor: root, observedStates: $0, actor: "host")
        }
        let resolution = resolutions[0]
        let expectedAdmitted = claims
            .sorted { $0.stateHash > $1.stateHash }
            .prefix(2)
            .compactMap(\.roster.last)
        let expectedExcluded = claims
            .sorted { $0.stateHash > $1.stateHash }
            .dropFirst(2)
            .compactMap(\.roster.last)

        XCTAssertEqual(resolution.state?.roster.prefix(2), root.roster.prefix(2))
        XCTAssertEqual(resolution.admittedPlayers, expectedAdmitted)
        XCTAssertEqual(resolution.excludedPlayers, expectedExcluded)
        XCTAssertEqual(resolution.state?.roster.count, 4)
        XCTAssertTrue(resolutions.allSatisfy { $0 == resolution })
    }

    func testUnreachableFabricatedClaimIsIgnored() throws {
        let root = makeLobby(roster: ["host"])
        let alienRoot = makeLobby(gameId: root.gameId, roster: ["host", "alien"])
        let fabricated = try join("intruder", to: alienRoot)

        let resolution = try reconcileLobbyV1(
            anchor: root,
            observedStates: [root, fabricated],
            actor: "host"
        )

        XCTAssertNil(resolution.state)
        XCTAssertTrue(resolution.admittedPlayers.isEmpty)
    }

    func testAlternateValidGenesisCannotInjectAJoinClaim() throws {
        let approvedRoot = makeLobby(roster: ["host"])
        let alice = try join("alice", to: approvedRoot)
        let alternateRoot = makeLobby(
            gameId: approvedRoot.gameId,
            roster: ["host"],
            names: ["host": "Alternate Host"]
        )
        let injected = try join("intruder", to: alternateRoot)

        let resolution = try reconcileLobbyV1(
            anchor: alice,
            observedStates: [approvedRoot, alice, alternateRoot, injected],
            actor: "host"
        )

        XCTAssertNil(resolution.state)
        XCTAssertFalse(resolution.admittedPlayers.contains("intruder"))
    }

    func testAlreadyCanonicalClaimsDoNotRepublish() throws {
        let root = makeLobby(roster: ["host"])
        let alice = try join("alice", to: root)

        let resolution = try reconcileLobbyV1(
            anchor: alice,
            observedStates: [root, alice],
            actor: "host"
        )

        XCTAssertNil(resolution.state)
        XCTAssertTrue(resolution.admittedPlayers.isEmpty)
    }

    private func join(
        _ actor: String,
        to state: CoreGameStateV1,
        name: String? = nil
    ) throws -> CoreGameStateV1 {
        var names = state.playerDisplayNamesByPlayer
        names[actor] = name
        let joined = makeLobby(
            gameId: state.gameId,
            rev: state.rev + 1,
            prevHash: state.stateHash,
            roster: state.roster + [actor],
            names: names
        )
        try validateTransition(from: state, to: joined, actor: actor)
        return joined
    }

    private func makeLobby(
        gameId: String = "lobby-reconciliation-tests",
        rev: Int = 0,
        prevHash: String? = nil,
        roster: [String],
        names: [String: String] = [:]
    ) -> CoreGameStateV1 {
        CoreGameStateV1(
            gameId: gameId,
            rev: rev,
            prevHash: prevHash,
            stateHash: "",
            roster: roster,
            currentPlayer: roster[0],
            playerDisplayNamesByPlayer: names,
            phase: .lobby,
            seed: nil,
            diceRngState: nil,
            resourcesByPlayer: Dictionary(uniqueKeysWithValues: roster.map { ($0, .zero) }),
            devCardsByPlayer: Dictionary(uniqueKeysWithValues: roster.map { ($0, .zero) }),
            newDevCardsByPlayer: Dictionary(uniqueKeysWithValues: roster.map { ($0, .zero) }),
            revealedVictoryPointsByPlayer: Dictionary(uniqueKeysWithValues: roster.map { ($0, 0) }),
            knightsPlayedByPlayer: Dictionary(uniqueKeysWithValues: roster.map { ($0, 0) })
        ).rehashed()
    }

    private func permutations<Element>(of values: [Element]) -> [[Element]] {
        guard values.count > 1 else { return [values] }
        return values.indices.flatMap { index -> [[Element]] in
            var remainder = values
            let value = remainder.remove(at: index)
            return permutations(of: remainder).map { [value] + $0 }
        }
    }
}
