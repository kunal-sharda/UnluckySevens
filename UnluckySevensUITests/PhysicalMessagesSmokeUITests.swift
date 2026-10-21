import XCTest

/// Physical-device feasibility lane. Never uses simulator fixtures or arbitrary chats.
final class PhysicalMessagesSmokeUITests: XCTestCase {
    private let messages = XCUIApplication(bundleIdentifier: "com.apple.MobileSMS")
    private var environment: [String: String] { ProcessInfo.processInfo.environment }

    override func setUpWithError() throws {
        continueAfterFailure = false
        #if targetEnvironment(simulator)
        throw XCTSkip("Physical Messages lane requires a real device.")
        #else
        guard environment["ULS_PHYSICAL_ENABLED"] == "1" else {
            throw XCTSkip("Use the explicitly configured physical runner.")
        }
        #endif
    }

    func testProbeDedicatedConversation() throws {
        try openDedicatedConversation()
        try openExtension()
        capture("physical-probe-extension-open")
    }

    func testPublishInvite() throws {
        guard environment["ULS_PHYSICAL_ALLOW_SEND"] == "1" else {
            XCTFail("Sending requires explicit runner authorization.")
            return
        }
        try openDedicatedConversation()
        try openExtension()
        let header = try required("ULS_PHYSICAL_CONVERSATION_HEADER")
        let confirmedHeader = messages.navigationBars.buttons.matching(NSPredicate(
            format: "identifier == %@ AND label == %@", "ConversationTitle", header
        ))
        // iPad presents the extension in a modal popover: the selected header
        // remains readable but cannot receive taps while the extension is open.
        guard confirmedHeader.count == 1, confirmedHeader.element.exists else {
            capture("physical-invite-conversation-mismatch")
            throw NSError(domain: "PhysicalMessagesSmoke", code: 3,
                          userInfo: [NSLocalizedDescriptionKey: "Conversation changed before invite; stopping."])
        }
        let invite = inviteControl
        try tapUnique(invite, timeout: 10)
        // A tap is not delivery proof. The runner keeps recipient agreement pending.
        capture("physical-invite-control-tapped-receipt-unverified")
    }

    func testInspectDedicatedConversation() throws {
        try openDedicatedConversation()
        let links = messages.links.matching(NSPredicate(format: "label BEGINSWITH %@", "Unlucky Sevens:"))
        let labels = links.allElementsBoundByIndex.filter { $0.isHittable }.map { $0.label }
        let attachment = XCTAttachment(data: try JSONSerialization.data(withJSONObject: labels),
                                       uniformTypeIdentifier: "public.json")
        attachment.name = "physical-visible-game-links"
        attachment.lifetime = .keepAlways
        add(attachment)
        capture("physical-conversation-inspected")
    }

    func testReopenJoinedLobby() throws {
        try openDedicatedConversation()
        let label = try required("ULS_PHYSICAL_JOIN_BUBBLE_LABEL")
        let bubble = messages.links.matching(NSPredicate(format: "label == %@", label))
        XCTAssertTrue(bubble.firstMatch.waitForExistence(timeout: 15), "Expected exact joined link.")
        guard let occurrence = Int(try required("ULS_PHYSICAL_JOIN_BUBBLE_OCCURRENCE")),
              let expectedCount = Int(try required("ULS_PHYSICAL_JOIN_BUBBLE_COUNT")),
              occurrence >= 1, occurrence <= expectedCount, expectedCount <= 20 else {
            throw NSError(domain: "PhysicalMessagesSmoke", code: 7,
                          userInfo: [NSLocalizedDescriptionKey: "Invalid explicit bubble occurrence/count."])
        }
        let visible = bubble.allElementsBoundByIndex.filter { $0.isHittable }.sorted { $0.frame.minY < $1.frame.minY }
        guard visible.count == expectedCount,
              zip(visible, visible.dropFirst()).allSatisfy({ $0.frame.maxY <= $1.frame.minY }) else {
            capture("physical-joined-bubble-ambiguous")
            throw NSError(domain: "PhysicalMessagesSmoke", code: 8,
                          userInfo: [NSLocalizedDescriptionKey: "Visible bubble count/order differs from inspected selection."])
        }
        capture("physical-joined-bubble-before-selection")
        visible[occurrence - 1].tap()
        let surface = messages.descendants(matching: .any).matching(identifier: "uls.lobby.tableSurface")
        XCTAssertTrue(surface.firstMatch.waitForExistence(timeout: 15), "Expected joined lobby.")
        try hideDebugChrome()
        capture("physical-reopened-lobby-role")
        let hostTitle = messages.staticTexts.matching(NSPredicate(format: "label == %@", "Waiting for Players"))
        XCTAssertTrue(hostTitle.firstMatch.waitForExistence(timeout: 5), "Original inviter must reopen as the waiting host.")
        XCTAssertFalse(messages.buttons.matching(NSPredicate(format: "label == %@", "Join Game")).firstMatch.exists,
                       "Original inviter must not be offered a guest join action.")
        let evidence = messages.descendants(matching: .any).matching(identifier: "uls.gameplay.actionEvidence")
        guard evidence.firstMatch.waitForExistence(timeout: 5), evidence.count == 1,
              let raw = evidence.element.value as? String else {
            throw NSError(domain: "PhysicalMessagesSmoke", code: 5,
                          userInfo: [NSLocalizedDescriptionKey: "Missing decoded lobby evidence."])
        }
        var fields: [String: String] = [:]
        for part in raw.split(separator: ";") {
            let pair = part.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
            if pair.count == 2, ["game", "rev", "phase", "hash"].contains(String(pair[0])) {
                fields[String(pair[0])] = String(pair[1])
            }
        }
        guard fields["phase"] == "lobby", let revision = Int(fields["rev"] ?? ""), revision >= 1,
              let game = fields["game"], !game.isEmpty, game != "-",
              let hash = fields["hash"], !hash.isEmpty, hash != "-" else {
            capture("physical-reopen-invalid-state")
            throw NSError(domain: "PhysicalMessagesSmoke", code: 6,
                          userInfo: [NSLocalizedDescriptionKey: "Selected bubble did not resolve to a joined lobby."])
        }
        let diagnostic = XCTAttachment(data: try JSONSerialization.data(withJSONObject: fields, options: [.sortedKeys]),
                                       uniformTypeIdentifier: "public.json")
        diagnostic.name = "physical-reopened-lobby-state"
        diagnostic.lifetime = .keepAlways
        add(diagnostic)
        capture("physical-reopened-joined-lobby")
    }

    private func required(_ key: String) throws -> String {
        let value = environment[key]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !value.isEmpty else {
            throw NSError(domain: "PhysicalMessagesSmoke", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Missing explicit configuration: \(key)"])
        }
        return value
    }

    private func openDedicatedConversation() throws {
        let row = try required("ULS_PHYSICAL_CONVERSATION_ROW")
        let header = try required("ULS_PHYSICAL_CONVERSATION_HEADER")
        // Development installation replaces the extension while its host may live on.
        // Start a fresh host process rather than reusing a stale extension panel.
        messages.terminate()
        messages.launch()
        // A prior failed probe may leave the known app-menu popover open.
        // Dismiss it before requiring the conversation header to be hittable.
        if messages.popovers.count == 1 {
            let dismiss = messages.descendants(matching: .any).matching(identifier: "PopoverDismissRegion")
            try tapUnique(dismiss, timeout: 3)
        }
        let headerQuery = messages.navigationBars.buttons.matching(NSPredicate(format: "label == %@", header))
        if !headerQuery.firstMatch.waitForExistence(timeout: 3) {
            // A single exact row is required. Never pick the first chat or tap coordinates.
            let rows = messages.cells.containing(.staticText, identifier: row)
            try tapUnique(rows, timeout: 8)
        }
        guard headerQuery.firstMatch.waitForExistence(timeout: 8), headerQuery.count == 1 else {
            XCTFail("Cannot confirm the configured conversation header; stopping.")
            return
        }
        XCTAssertTrue(headerQuery.element.isHittable, "Conversation header must be visible.")
    }

    private func openExtension() throws {
        let surface = messages.descendants(matching: .any).matching(identifier: "uls.lobby.tableSurface")
        if !surface.firstMatch.waitForExistence(timeout: 2) {
            if messages.popovers.count == 0 {
                try tapUnique(messages.buttons.matching(identifier: "add"), timeout: 5)
            }
            let entry = messages.staticTexts.matching(NSPredicate(format: "label == %@", "Unlucky Sevens"))
            // Physical iPad evidence shows the app menu is a scrollable popover.
            // Never scroll the conversation list or transcript while finding the app.
            for _ in 0..<3 {
                if entry.firstMatch.waitForExistence(timeout: 2), entry.count == 1,
                   entry.element.isHittable { break }
                let menus = messages.popovers
                guard menus.count == 1 else { break }
                let lists = menus.element.collectionViews
                guard lists.count == 1, lists.element.isHittable else { break }
                lists.element.swipeUp()
            }
            try tapUnique(entry, timeout: 3)
        }
        let openLobby = messages.buttons.matching(identifier: "uls.compactLaunch.openLobby")
        if openLobby.firstMatch.waitForExistence(timeout: 3) {
            try tapUnique(openLobby, timeout: 3)
        }
        XCTAssertTrue(surface.firstMatch.waitForExistence(timeout: 10), "Expected the production lobby.")
        try hideDebugChrome()
        let invite = inviteControl
        guard invite.firstMatch.waitForExistence(timeout: 5), invite.count == 1,
              invite.element.isHittable, invite.element.isEnabled else {
            capture("physical-lobby-not-ready")
            throw NSError(domain: "PhysicalMessagesSmoke", code: 4,
                          userInfo: [NSLocalizedDescriptionKey: "Production invite control is not ready; stopping."])
        }
    }

    private func hideDebugChrome() throws {
        let hideChrome = messages.descendants(matching: .any).matching(identifier: "uls.uxLab.hideChrome")
        if hideChrome.firstMatch.waitForExistence(timeout: 2) {
            try tapUnique(hideChrome, timeout: 3)
        }
        XCTAssertTrue(messages.descendants(matching: .any).matching(identifier: "uls.uxLab.panel")
            .firstMatch.waitForNonExistence(timeout: 4), "DEBUG panel must not cover production controls.")
    }

    private var inviteControl: XCUIElementQuery {
        // On the physical host SwiftUI exposes the inherited table identifier.
        messages.buttons.matching(NSPredicate(
            format: "label == %@ AND (identifier == %@ OR identifier == %@)",
            "Send Invite", "uls.lobby.action.Send Invite", "uls.lobby.tableSurface"
        ))
    }

    private func tapUnique(_ query: XCUIElementQuery, timeout: TimeInterval) throws {
        guard query.firstMatch.waitForExistence(timeout: timeout), query.count == 1,
              query.element.isHittable, query.element.isEnabled else {
            throw NSError(domain: "PhysicalMessagesSmoke", code: 2,
                          userInfo: [NSLocalizedDescriptionKey: "Expected one visible, enabled control; stopping without fallback."])
        }
        query.element.tap()
    }

    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: messages.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
