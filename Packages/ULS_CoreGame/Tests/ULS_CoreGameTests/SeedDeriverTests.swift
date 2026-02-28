import XCTest
@testable import ULS_CoreGame

final class SeedDeriverTests: XCTestCase {
    func testGoldenSeedsForMasterSeed0123456789ABCDEF() {
        let deriver = SeedDeriver(masterSeed: 0x0123456789ABCDEF)

        XCTAssertEqual(deriver.seed(for: .board), 0x8B65420AA40B150D)
        XCTAssertEqual(deriver.seed(for: .dice), 0x8D45FEEDD1B6D86B)
        XCTAssertEqual(deriver.seed(for: .devDeck), 0x92FA6DE1EB359B0A)
        XCTAssertEqual(deriver.seed(for: .robber), 0xD39F075559A6C094)
    }

    func testDomainDerivationIsOrderIndependent() {
        let deriver = SeedDeriver(masterSeed: 0x0123456789ABCDEF)

        let robber = deriver.seed(for: .robber)
        let board = deriver.seed(for: .board)
        let devDeck = deriver.seed(for: .devDeck)
        let dice = deriver.seed(for: .dice)

        XCTAssertEqual(board, 0x8B65420AA40B150D)
        XCTAssertEqual(dice, 0x8D45FEEDD1B6D86B)
        XCTAssertEqual(devDeck, 0x92FA6DE1EB359B0A)
        XCTAssertEqual(robber, 0xD39F075559A6C094)
    }
}
