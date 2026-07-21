import UIKit
import XCTest
@testable import MessagesExtension

@MainActor
final class TranscriptBubbleImageRendererTests: XCTestCase {
    func testLobbyInviteRendererReturnsExpectedSize() throws {
        let image = try XCTUnwrap(TranscriptBubbleImageRenderer.render(visual: .lobbyInvite))

        assertBubbleImage(image)
    }

    func testActionRendererReturnsNonEmptyRollImage() throws {
        let image = try XCTUnwrap(
            TranscriptBubbleImageRenderer.render(
                visual: .action(
                    TranscriptActionBubbleVisual(
                        kind: .rollSeven,
                        title: "Rolled 7"
                    )
                )
            )
        )

        assertBubbleImage(image)
    }

    func testActionRendererReturnsNonEmptyBuildImage() throws {
        let image = try XCTUnwrap(
            TranscriptBubbleImageRenderer.render(
                visual: .action(
                    TranscriptActionBubbleVisual(
                        kind: .buildSettlement,
                        title: "Settlement Built"
                    )
                )
            )
        )

        assertBubbleImage(image)
    }

    func testRobberRendererUsesApprovedCompactIdentity() throws {
        let image = try XCTUnwrap(
            TranscriptBubbleImageRenderer.render(
                visual: .action(
                    TranscriptActionBubbleVisual(
                        kind: .robber,
                        title: "Move the Robber"
                    )
                )
            )
        )

        assertBubbleImage(image)
        let attachment = XCTAttachment(image: image)
        attachment.name = "Approved robber transcript artwork"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func assertBubbleImage(_ image: UIImage) {
        XCTAssertEqual(image.size.width, TranscriptBubbleImageRenderer.imageSize.width, accuracy: 0.5)
        XCTAssertEqual(image.size.height, TranscriptBubbleImageRenderer.imageSize.height, accuracy: 0.5)
        XCTAssertGreaterThan(image.pngData()?.count ?? 0, 1_000)
    }
}
