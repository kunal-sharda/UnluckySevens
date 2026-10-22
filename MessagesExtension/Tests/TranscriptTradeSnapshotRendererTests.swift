@testable import MessagesExtensionSupport
import UIKit
import ULS_CoreGame
import XCTest

@MainActor
final class TranscriptTradeSnapshotRendererTests: XCTestCase {
    func testTwoSheepForOneWood() throws {
        try capture("Trade — two sheep for one wood", give: [.init(resource: .sheep, count: 2)], receive: [.init(resource: .wood, count: 1)], names: ["Maya"])
    }

    func testMultiResourceLargeOffer() throws {
        try capture("Trade — mixed large offer", give: [.init(resource: .sheep, count: 8), .init(resource: .wheat, count: 2), .init(resource: .ore, count: 1)], receive: [.init(resource: .wood, count: 2), .init(resource: .brick, count: 3)], names: ["Maya", "Theo", "Sam"], mixedResponses: true)
    }

    func testFiveResourcesAndLongPlayerNames() throws {
        let chips = [ResourceV1.wood, .brick, .sheep, .wheat, .ore].map { GameHandChip(resource: $0, count: 2) }
        try capture("Trade — five resources and long names", give: chips, receive: chips, names: ["Alexandra-Margaret", "Christopher", "Maximilian"], proposer: "Kunal Sharda")
    }

    private func capture(_ title: String, give: [GameHandChip], receive: [GameHandChip], names: [String], proposer: String = "Kunal", mixedResponses: Bool = false) throws {
        let bundle = Bundle(for: Self.self)
        for chip in give + receive {
            XCTAssertNotNil(UIImage(named: chip.resource.tabletopStampAssetName, in: bundle, compatibleWith: nil), "Production resource illustration must be available")
        }
        let visual = TranscriptTradeVisual(
            offer: GameTradeOfferSummary(proposerPlayerID: "host", proposerDisplay: proposer, giveLabel: "Gives", give: give, receiveLabel: "Wants", receive: receive, recipientPlayerIDs: names, recipientsLabel: names.joined(separator: ", ")),
            participantStatuses: names.enumerated().map { index, name in
                GameTradeParticipantStatus(playerID: name, displayName: name, state: mixedResponses && index == 0 ? .declined : .waiting, detailText: mixedResponses && index == 0 ? "Declined" : "Waiting", isTargeted: true, counterGive: [], counterReceive: [])
            },
            recipientScopeLabel: names.joined(separator: ", ")
        )
        let image = try XCTUnwrap(TranscriptTradeSnapshotRenderer.render(visual: visual, assetBundle: bundle))
        XCTAssertEqual(image.size.width, TranscriptBubbleImageRenderer.imageSize.width)
        XCTAssertGreaterThan(image.size.height, 150)
        XCTAssertLessThan(image.size.height, 360)
        let attachment = XCTAttachment(image: image)
        attachment.name = title
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
