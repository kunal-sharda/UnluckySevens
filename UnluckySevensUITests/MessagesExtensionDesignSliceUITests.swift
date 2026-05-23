import XCTest

final class MessagesExtensionDesignSliceUITests: XCTestCase {
    private var messages: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        messages = XCUIApplication(bundleIdentifier: "com.apple.MobileSMS")
    }

    func testOpenMessagesExtensionAndCaptureDesignSlices() throws {
        messages.launch()
        handleFirstRunPrompts()
        openExistingConversation()
        openMessagesAppDrawer()
        openUnluckySevensFromDrawer()

        XCTAssertTrue(waitForInviteSlice(timeout: 12), "Expected the Unlucky Sevens invite slice to render.")
        attachScreenshot(named: "Unlucky Sevens - invite slice")

        openUXLabPanel()
        attachScreenshot(named: "Unlucky Sevens - UX Lab panel")
    }

    private func handleFirstRunPrompts() {
        let promptButtons = ["Continue", "OK", "Not Now", "Skip"]

        for _ in 0..<4 {
            var handledPrompt = false

            for label in promptButtons {
                let button = messages.buttons[label].firstMatch
                if button.waitForExistence(timeout: 1) {
                    button.tap()
                    handledPrompt = true
                    break
                }
            }

            if !handledPrompt {
                return
            }
        }
    }

    private func openExistingConversation() {
        if waitForInviteSlice(timeout: 1) || messages.buttons["add"].firstMatch.waitForExistence(timeout: 2) {
            return
        }

        let cancelButton = messages.buttons["Cancel"].firstMatch
        if cancelButton.exists {
            cancelButton.tap()
        }

        let knownConversationLabels = [
            "+1 (888) 555-1212",
            "+1 (555) 564-8583",
        ]

        for label in knownConversationLabels {
            let text = messages.staticTexts[label].firstMatch
            if text.waitForExistence(timeout: 2) {
                text.tap()
                return
            }

            let button = messages.buttons[label].firstMatch
            if button.waitForExistence(timeout: 1) {
                button.tap()
                return
            }
        }

        let firstCell = messages.cells.firstMatch
        if firstCell.waitForExistence(timeout: 2) {
            firstCell.tap()
            return
        }

        messages.coordinate(withNormalizedOffset: CGVector(dx: 0.50, dy: 0.30)).tap()
    }

    private func openMessagesAppDrawer() {
        if waitForInviteSlice(timeout: 1) || messages.staticTexts["Unlucky Sevens"].firstMatch.exists {
            return
        }

        let addButton = messages.buttons["add"].firstMatch
        XCTAssertTrue(addButton.waitForExistence(timeout: 6), "Expected the Messages app drawer add button.")
        addButton.tap()
    }

    private func openUnluckySevensFromDrawer() {
        if waitForInviteSlice(timeout: 2) {
            return
        }

        let appRow = messages.staticTexts["Unlucky Sevens"].firstMatch

        for _ in 0..<8 {
            if appRow.exists {
                appRow.tap()
                return
            }

            messages.swipeUp()
        }

        XCTFail("Could not find Unlucky Sevens in the Messages app drawer.")
    }

    private func openUXLabPanel() {
        let toggle = firstExistingElement(
            [
                messages.buttons["uls.uxLab.toggle"].firstMatch,
                messages.buttons["Preview"].firstMatch,
                messages.buttons["UX Lab"].firstMatch,
            ],
            timeout: 8
        )
        XCTAssertTrue(toggle.waitForExistence(timeout: 8), "Expected the UX Lab toggle to be visible.")
        toggle.tap()

        let panelSignal = firstExistingElement(
            [
                messages.staticTexts["Single-device UX Lab"].firstMatch,
                messages.buttons["uls.uxLab.load"].firstMatch,
                messages.buttons["Load"].firstMatch,
            ],
            timeout: 4
        )
        XCTAssertTrue(panelSignal.exists, "Expected the UX Lab panel to open.")
    }

    private func attachScreenshot(named name: String) {
        let attachment = XCTAttachment(screenshot: messages.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func waitForInviteSlice(timeout: TimeInterval) -> Bool {
        firstExistingElement(
            [
                messages.staticTexts["uls.lobby.inviteTitle"].firstMatch,
                messages.staticTexts["Invite friends to play"].firstMatch,
            ],
            timeout: timeout
        )
        .exists
    }

    private func firstExistingElement(_ candidates: [XCUIElement], timeout: TimeInterval) -> XCUIElement {
        let deadline = Date().addingTimeInterval(timeout)

        repeat {
            if let element = candidates.first(where: { $0.exists }) {
                return element
            }

            RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        } while Date() < deadline

        return candidates[0]
    }
}
