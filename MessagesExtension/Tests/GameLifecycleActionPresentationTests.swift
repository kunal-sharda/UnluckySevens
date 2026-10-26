import XCTest
@testable import MessagesExtensionSupport

final class GameLifecycleActionPresentationTests: XCTestCase {
    func testResignRequiresConfirmationAndCancelPublishesNothing() {
        var presentation = GameLifecycleActionPresentation()
        let available = GameLifecycleActionPresentation.Availability(resign: true)
        XCTAssertNil(presentation.select(.resign, availability: available))
        XCTAssertEqual(presentation.screen, .resign)
        presentation.cancel()
        XCTAssertEqual(presentation.screen, .actions)
        XCTAssertNil(presentation.confirm(availability: available))
    }

    func testConfirmEmitsOneResignationAndCannotRepeat() {
        var presentation = GameLifecycleActionPresentation()
        let available = GameLifecycleActionPresentation.Availability(resign: true)
        XCTAssertNil(presentation.select(.resign, availability: available))
        XCTAssertEqual(presentation.confirm(availability: available), .resign)
        XCTAssertNil(presentation.confirm(availability: available))
    }

    func testEligibilityChangeBeforeConfirmDoesNotEmitAction() {
        for action: GameLifecycleActionPresentation.Action in [.resign, .hostEnd, .proposeDraw] {
            var presentation = GameLifecycleActionPresentation()
            let available = GameLifecycleActionPresentation.Availability(proposeDraw: true, resign: true, hostEnd: true)
            XCTAssertNil(presentation.select(action, availability: available))
            XCTAssertNil(presentation.confirm(availability: .init()))
            XCTAssertEqual(presentation.screen, .actions)
        }
    }

    func testDrawProposalConfirmationAndVoteAreDifferentActions() {
        var presentation = GameLifecycleActionPresentation()
        XCTAssertNil(presentation.select(.proposeDraw, availability: .init(proposeDraw: true)))
        XCTAssertEqual(presentation.confirm(availability: .init(proposeDraw: true)), .proposeDraw)
        let vote = GameLifecycleActionPresentation.Availability(proposeDraw: true, voteOnDraw: true)
        XCTAssertNil(presentation.select(.proposeDraw, availability: vote))
        XCTAssertEqual(presentation.select(.agreeDraw, availability: vote), .agreeDraw)
        XCTAssertEqual(presentation.select(.declineDraw, availability: vote), .declineDraw)
    }

    func testHostOnlyActionAndVictoryPriorityStayGated() {
        var presentation = GameLifecycleActionPresentation()
        XCTAssertNil(presentation.select(.hostEnd, availability: .init(resign: true)))
        XCTAssertEqual(presentation.screen, .actions)
        let victory = GameLifecycleActionPresentation.Availability(claimVictory: true, resendUpdate: true, proposeDraw: true, resign: true, hostEnd: true)
        XCTAssertNil(presentation.select(.resign, availability: victory))
        XCTAssertNil(presentation.select(.hostEnd, availability: victory))
        XCTAssertEqual(presentation.select(.claimVictory, availability: victory), .claimVictory)
        XCTAssertEqual(presentation.select(.resendUpdate, availability: victory), .resendUpdate)
    }
}
