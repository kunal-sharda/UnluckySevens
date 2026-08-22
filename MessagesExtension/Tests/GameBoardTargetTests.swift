import XCTest
@testable import MessagesExtensionSupport

final class GameBoardTargetTests: XCTestCase {
    func testSelectionLabelsAreHumanReadableForBoardModes() {
        XCTAssertEqual(GameBoardTarget.node(3).selectionLabel(for: .setup), "Settlement selected")
        XCTAssertEqual(GameBoardTarget.node(7).selectionLabel(for: .buildSettlement), "Settlement selected")
        XCTAssertEqual(GameBoardTarget.node(9).selectionLabel(for: .buildCity), "City target selected")
        XCTAssertEqual(GameBoardTarget.node(11).selectionLabel(for: .robberVictim), "Victim selected")
        XCTAssertEqual(GameBoardTarget.edge(4).selectionLabel(for: .buildRoad), "Road selected")
        XCTAssertEqual(GameBoardTarget.edge(5).selectionLabel(for: .setup), "Road selected")
        XCTAssertEqual(GameBoardTarget.tile(2).selectionLabel(for: .robberMove), "Robber tile selected")
    }

    func testSelectionLabelsFallBackToIdentifierLabelsOutsideBoardFlows() {
        XCTAssertEqual(GameBoardTarget.node(3).selectionLabel(for: .trade), "Node 3")
        XCTAssertEqual(GameBoardTarget.edge(4).selectionLabel(for: .idle), "Edge 4")
        XCTAssertEqual(GameBoardTarget.tile(2).selectionLabel(for: .idle), "Tile 2")
    }
}
