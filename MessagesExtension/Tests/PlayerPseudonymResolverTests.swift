import XCTest
@testable import MessagesExtension

final class PlayerPseudonymResolverTests: XCTestCase {
    func testDisplayNamesAreDeterministicAndUseAliasPool() {
        let roster = ["host-player", "guest-player", "guest-two", "guest-three"]
        let first = PlayerPseudonymResolver.displayNames(for: "game-1", roster: roster)
        let second = PlayerPseudonymResolver.displayNames(for: "game-1", roster: roster)

        XCTAssertEqual(first, second)
        XCTAssertEqual(first.count, 4)
        XCTAssertEqual(Set(first.values).count, 4)
        XCTAssertTrue(first.values.allSatisfy(Self.aliasPool.contains))
    }

    func testDisplayNamesVaryByGameSeed() {
        let roster = ["host-player", "guest-player", "guest-two", "guest-three"]
        let first = PlayerPseudonymResolver.displayNames(for: "game-1", roster: roster)
        let second = PlayerPseudonymResolver.displayNames(for: "game-2", roster: roster)

        XCTAssertNotEqual(first, second)
    }

    func testDisplayNamesAssignEveryAliasUniquelyWhenRosterMatchesPoolSize() {
        let roster = ["host-player", "guest-player", "guest-two", "guest-three", "guest-four"]
        let mapping = PlayerPseudonymResolver.displayNames(for: "game-1", roster: roster)

        XCTAssertEqual(mapping.count, 5)
        XCTAssertEqual(Set(mapping.values).count, 5)
        XCTAssertEqual(Set(mapping.values), Self.aliasPool)
    }

    func testCustomNamesOverrideAliasFallback() {
        let roster = ["host-player", "guest-player", "guest-two"]
        let mapping = PlayerPseudonymResolver.displayNames(
            for: "game-1",
            roster: roster,
            customNames: ["guest-player": "Kunal"]
        )

        XCTAssertEqual(mapping["guest-player"], "Kunal")
        XCTAssertTrue(mapping["host-player"].map(Self.aliasPool.contains) ?? false)
        XCTAssertTrue(mapping["guest-two"].map(Self.aliasPool.contains) ?? false)
    }

    private static let aliasPool: Set<String> = [
        "SheepGrazer",
        "BrickLayer",
        "OreMiner",
        "WoodCutter",
        "WheatFarmer",
    ]
}
