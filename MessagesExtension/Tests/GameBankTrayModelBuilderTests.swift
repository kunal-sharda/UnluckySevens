import ULS_CoreGame
import XCTest
@testable import MessagesExtension

final class GameBankTrayModelBuilderTests: XCTestCase {
    func testMonopolyModeShowsPersistentCountsAndClaimPreviews() {
        let state = makeState(
            resourcesByPlayer: [
                "A": .zero,
                "B": ResourceHandV1(wood: 1, ore: 2),
                "C": ResourceHandV1(ore: 1),
            ]
        )

        let model = GameBankTrayModelBuilder.build(
            state: state,
            actingAs: "A",
            mode: .devCardMonopoly,
            draft: .monopoly(resource: .ore)
        )

        XCTAssertEqual(model.title, "Bank")
        XCTAssertEqual(model.subtitle, "Choose the resource to claim from every opponent.")
        XCTAssertEqual(model.chips.count, 5)

        let oreChip = model.chips.first(where: { $0.resource == ResourceV1.ore })
        XCTAssertEqual(oreChip?.count, 19)
        XCTAssertEqual(oreChip?.detailText, "Claim 3")
        XCTAssertEqual(oreChip?.isSelected, true)
        XCTAssertEqual(oreChip?.selectionIndex, 1)
        XCTAssertEqual(oreChip?.isEnabled, true)
    }

    func testYearOfPlentyModeAllowsSameResourceTwiceOnlyWhenBankHasEnough() {
        let state = makeState(
            resourcesByPlayer: ["A": .zero, "B": .zero],
            bankResources: ResourceHandV1(wood: 1, brick: 0, sheep: 3, wheat: 2, ore: 2)
        )

        let initialModel = GameBankTrayModelBuilder.build(
            state: state,
            actingAs: "A",
            mode: .devCardYearOfPlenty,
            draft: .yearOfPlenty(first: nil, second: nil)
        )
        XCTAssertEqual(initialModel.subtitle, "Choose the first resource.")
        XCTAssertEqual(initialModel.chips.first(where: { $0.resource == .wood })?.isEnabled, true)
        XCTAssertEqual(initialModel.chips.first(where: { $0.resource == .brick })?.isEnabled, false)

        let selectedModel = GameBankTrayModelBuilder.build(
            state: state,
            actingAs: "A",
            mode: .devCardYearOfPlenty,
            draft: .yearOfPlenty(first: .wood, second: nil)
        )
        XCTAssertEqual(selectedModel.subtitle, "Choose the second resource.")
        XCTAssertEqual(selectedModel.chips.first(where: { $0.resource == .wood })?.isEnabled, false)
        XCTAssertEqual(selectedModel.chips.first(where: { $0.resource == .wood })?.selectionIndex, 1)
        XCTAssertEqual(selectedModel.chips.first(where: { $0.resource == .sheep })?.isEnabled, true)
    }

    private func makeState(
        resourcesByPlayer: [String: ResourceHandV1],
        bankResources: ResourceHandV1 = ResourceHandV1(wood: 19, brick: 19, sheep: 19, wheat: 19, ore: 19)
    ) -> CoreGameStateV1 {
        let topology = StandardBoardTopologyV1.standard()
        let board = BoardSetupV1(
            resourcesByTile: Array(repeating: .wood, count: topology.tiles.count),
            numbersByTile: Array(repeating: 5, count: topology.tiles.count),
            portsByIndex: topology.ports.map(\.kind),
            robberTile: 0,
            generator: .randomV1,
            boardHash: ""
        ).rehashed()

        return CoreGameStateV1(
            gameId: "bank-tray",
            rev: 4,
            prevHash: "hash-3",
            stateHash: "",
            roster: Array(resourcesByPlayer.keys).sorted(),
            currentPlayer: "A",
            phase: .turn,
            seed: 1,
            diceRngState: 2,
            robberRngState: 3,
            resourcesByPlayer: resourcesByPlayer,
            bankResources: bankResources,
            devCardsByPlayer: ["A": DevCardInventoryV1(monopoly: 1, yearOfPlenty: 1)],
            boardRules: BoardRulesV1(strategy: .randomV1),
            board: board,
            turnState: TurnStateV1(step: .afterRoll, lastRoll: DiceRollV1(d1: 3, d2: 4))
        ).rehashed()
    }
}
