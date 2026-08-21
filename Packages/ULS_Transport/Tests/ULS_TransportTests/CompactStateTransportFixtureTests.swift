import XCTest
@testable import ULS_CoreGame
@testable import ULS_Transport

final class CompactStateTransportFixtureTests: XCTestCase {
    func testCompactStateV4FixtureRemainsSchemaIdentical() throws {
        let encodedPayload = try CompactStateTransport.encode(fixtureState)
        XCTAssertEqual(
            try canonicalJSONBytes(encodedPayload),
            try canonicalJSONBytes(legacyCompactStateV4Payload)
        )
    }

    func testCompactStateV4FixtureDecodesAndRawLegacyPayloadRemainsSupported() throws {
        XCTAssertEqual(try CompactStateTransport.decode(legacyCompactStateV4Payload), fixtureState)
        XCTAssertEqual(try CompactStateTransport.decode(legacyRawPayload), fixtureState)
    }

    private var fixtureState: CoreGameStateV1 {
        CoreGameStateV1(
            gameId: "compact-state-v4-fixture",
            rev: 7,
            prevHash: "legacy-prev-hash",
            stateHash: "fixture-state-hash",
            roster: ["A", "B"],
            currentPlayer: "B",
            playerDisplayNamesByPlayer: ["A": "Alpha", "B": "Beta"],
            phase: .lobby,
            seed: 42,
            diceRngState: 24,
            robberRngState: 12,
            resourcesByPlayer: ["A": ResourceHandV1(wood: 1), "B": ResourceHandV1(brick: 2)],
            bankResources: ResourceHandV1(wood: 18, brick: 17, sheep: 19, wheat: 19, ore: 19),
            devDeck: [.knight, .victoryPoint],
            devCardsByPlayer: ["A": DevCardInventoryV1(knight: 1)],
            newDevCardsByPlayer: ["B": DevCardInventoryV1(victoryPoint: 1)],
            revealedVictoryPointsByPlayer: ["B": 1],
            knightsPlayedByPlayer: ["A": 1],
            auditLog: [AuditEntryV1(rev: 7, actor: "B", action: .buildRoad)],
            settlementsByNode: [3: "A"],
            roadsByEdge: [4: "B"]
        )
    }

    // Captured from the pre-migration MessagesExtension implementation.
    private let legacyCompactStateV4Payload = "{\"T\":[],\"d\":24,\"a\":[[7,1,4,null]],\"I\":[],\"r\":7,\"f\":\"compactStateV4\",\"s\":42,\"h\":\"fixture-state-hash\",\"F\":false,\"k\":[0,4],\"n\":[[0,0,0,0,0],[0,0,0,0,1]],\"W\":0,\"m\":0,\"v\":[[1,0,0,0,0],[0,0,0,0,0]],\"g\":\"compact-state-v4-fixture\",\"N\":[\"Alpha\",\"Beta\"],\"C\":[],\"p\":\"legacy-prev-hash\",\"j\":[1,0],\"u\":[[1,0,0,0,0],[0,2,0,0,0]],\"E\":[[4,1]],\"S\":[[3,0]],\"b\":[18,17,19,19,19],\"y\":false,\"q\":[0,1],\"x\":0,\"c\":1,\"t\":0,\"z\":12,\"o\":[\"A\",\"B\"]}"
    private let legacyRawPayload = "{\"settlementsByNode\":{\"3\":\"A\"},\"bankResources\":{\"wood\":18,\"sheep\":19,\"wheat\":19,\"ore\":19,\"brick\":17},\"playerDisplayNamesByPlayer\":{\"B\":\"Beta\",\"A\":\"Alpha\"},\"resignedPlayers\":[],\"roster\":[\"A\",\"B\"],\"devCardsByPlayer\":{\"B\":{\"monopoly\":0,\"roadBuilding\":0,\"knight\":0,\"yearOfPlenty\":0,\"victoryPoint\":0},\"A\":{\"monopoly\":0,\"roadBuilding\":0,\"knight\":1,\"yearOfPlenty\":0,\"victoryPoint\":0}},\"newDevCardsByPlayer\":{\"B\":{\"monopoly\":0,\"roadBuilding\":0,\"knight\":0,\"yearOfPlenty\":0,\"victoryPoint\":1},\"A\":{\"monopoly\":0,\"roadBuilding\":0,\"knight\":0,\"yearOfPlenty\":0,\"victoryPoint\":0}},\"seed\":42,\"devDeck\":[\"knight\",\"victoryPoint\"],\"phase\":\"lobby\",\"currentPlayer\":\"B\",\"prevHash\":\"legacy-prev-hash\",\"revealedVictoryPointsByPlayer\":{\"B\":1,\"A\":0},\"longestRoadLength\":0,\"hasAttemptedDrawVote\":false,\"knightsPlayedByPlayer\":{\"B\":0,\"A\":1},\"winningVictoryPoints\":0,\"stateHash\":\"fixture-state-hash\",\"citiesByNode\":{},\"robberRngState\":12,\"resourcesByPlayer\":{\"B\":{\"wheat\":0,\"wood\":0,\"brick\":2,\"ore\":0,\"sheep\":0},\"A\":{\"ore\":0,\"wood\":1,\"brick\":0,\"sheep\":0,\"wheat\":0}},\"roadsByEdge\":{\"4\":\"B\"},\"gameId\":\"compact-state-v4-fixture\",\"devCardActionPlayedThisTurn\":false,\"diceRngState\":24,\"rev\":7,\"auditLog\":[{\"rev\":7,\"action\":\"buildRoad\",\"actor\":\"B\"}],\"largestArmySize\":0,\"tradeResponses\":[]}"

    private func canonicalJSONBytes(_ payload: String) throws -> Data {
        let object = try JSONSerialization.jsonObject(with: Data(payload.utf8))
        return try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])
    }
}
