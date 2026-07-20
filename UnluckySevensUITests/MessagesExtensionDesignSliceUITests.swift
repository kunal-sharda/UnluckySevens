import XCTest

final class MessagesExtensionDesignSliceUITests: XCTestCase {
    private var messages: XCUIApplication!
    private var expectedTurnActionWellFrame: CGRect?

    override func setUpWithError() throws {
        continueAfterFailure = false
        messages = XCUIApplication(bundleIdentifier: "com.apple.MobileSMS")
        expectedTurnActionWellFrame = nil
    }

    func testOpenMessagesExtensionAndCaptureDesignSlices() throws {
        openUnluckySevensExtension()

        XCTAssertTrue(waitForInviteSlice(timeout: 12), "Expected the Unlucky Sevens invite slice to render.")
        attachScreenshot(named: "Unlucky Sevens - invite slice")

        openUXLabPanel()
        attachScreenshot(named: "Unlucky Sevens - UX Lab panel")
    }

    func testOpenMessagesExtensionAndCaptureLobbyInviteDirections() throws {
        openUnluckySevensExtension()

        openUXLabPanel()
        activateUXLabNestedQuickState(
            title: "Setup Card",
            identifier: "uls.uxLab.cleanShot.lobbyInviteSetupCard"
        )
        XCTAssertTrue(waitForInviteSlice(timeout: 12))
        XCTAssertTrue(
            messages.descendants(matching: .any)["uls.lobby.inviteDirection.setupCard"]
                .firstMatch.waitForExistence(timeout: 4)
        )
        attachScreenshot(named: "Lobby Invite Direction - Setup Card")

        restoreUXLabChrome()
        activateUXLabNestedQuickState(
            title: "Invitation Card",
            identifier: "uls.uxLab.cleanShot.lobbyInviteInvitationCard"
        )
        XCTAssertTrue(waitForInviteSlice(timeout: 12))
        XCTAssertTrue(
            messages.descendants(matching: .any)["uls.lobby.inviteDirection.invitationCard"]
                .firstMatch.waitForExistence(timeout: 4)
        )
        let tutorial = messages.buttons["uls.lobby.tutorial"].firstMatch
        XCTAssertTrue(tutorial.exists)
        XCTAssertEqual(tutorial.label, "Tutorial")
        XCTAssertTrue(messages.buttons["uls.lobby.gameSettings"].firstMatch.exists)
        XCTAssertFalse(messages.staticTexts["Async turns"].firstMatch.exists)
        attachScreenshot(named: "Lobby Invite Direction - Invitation Card")

        messages.buttons["uls.lobby.gameSettings"].firstMatch.tap()
        XCTAssertTrue(messages.navigationBars["Game settings"].firstMatch.waitForExistence(timeout: 4))
        XCTAssertTrue(messages.staticTexts["Board"].firstMatch.exists)
        XCTAssertTrue(messages.staticTexts["Victory"].firstMatch.exists)
        messages.buttons["Done"].firstMatch.tap()

        tutorial.tap()
        XCTAssertTrue(messages.navigationBars["Game rules"].firstMatch.waitForExistence(timeout: 4))
        messages.buttons["Done"].firstMatch.tap()
    }

    private func restoreUXLabChrome() {
        let restore = messages.buttons["uls.uxLab.restoreChrome"].firstMatch
        XCTAssertTrue(restore.waitForExistence(timeout: 4))
        restore.tap()
    }

    private func activateDirectCleanState(identifier: String, label: String) {
        let button = firstExistingElement(
            [
                messages.buttons[identifier].firstMatch,
                messages.buttons[label].firstMatch,
                messages.descendants(matching: .any)[identifier].firstMatch,
                messages.descendants(matching: .any)[label].firstMatch,
            ],
            timeout: 4
        )
        XCTAssertTrue(button.waitForExistence(timeout: 4))
        button.tap()
    }

    func testOpenMessagesExtensionAndCaptureCleanSetupGameplaySlice() throws {
        openUnluckySevensExtension()
        waitForUXLabChrome()
        loadCleanSetupGameplaySlice()

        XCTAssertTrue(
            turnElement(
                identifier: "uls.setup.status",
                labels: ["Place Your First Settlement"]
            ).waitForExistence(timeout: 8),
            "Expected the setup gameplay fixture to render."
        )
        let orderRail = turnElement(identifier: "uls.setup.orderRail", labels: [])
        XCTAssertTrue(
            orderRail.waitForExistence(timeout: 4),
            "Expected setup snake order to render."
        )
        XCTAssertEqual(
            orderRail.value as? String,
            "3 placement slots shown",
            "Expected setup order to show the current player and the next two slots."
        )
        let pieceRail = turnElement(identifier: "uls.setup.pieceRail", labels: [])
        XCTAssertTrue(
            pieceRail.waitForExistence(timeout: 4),
            "Expected settlement and road setup steps to render."
        )
        XCTAssertEqual(pieceRail.value as? String, "1 settlement and 1 road")
        XCTAssertFalse(
            messages.buttons["uls.uxLab.toggle"].firstMatch.exists,
            "Expected UX Lab chrome to be hidden for the clean gameplay screenshot."
        )
        attachScreenshot(named: "Setup Flow 1 - Place Settlement")

        restoreUXLabChrome()
        activateUXLabQuickState(
            title: "Setup Road",
            identifier: "uls.uxLab.cleanShot.setupRoadPlacement"
        )
        XCTAssertTrue(
            turnElement(
                identifier: "uls.setup.status",
                labels: ["Connect Your First Road"]
            ).waitForExistence(timeout: 8),
            "Expected the connected-road setup state to render."
        )
        XCTAssertEqual(
            turnElement(identifier: "uls.setup.piece.road", labels: []).value as? String,
            "Place now"
        )
        attachScreenshot(named: "Setup Flow 2 - Connect Road")

        restoreUXLabChrome()
        activateUXLabQuickState(
            title: "Setup Handoff",
            identifier: "uls.uxLab.cleanShot.setupHandoff"
        )
        XCTAssertTrue(
            turnElement(
                identifier: "uls.startTurn.surface",
                labels: ["Start of turn"]
            ).waitForExistence(timeout: 8),
            "Expected authoritative setup completion to hand off to the first turn."
        )
        attachScreenshot(named: "Setup Flow 3 - First Turn")
    }

    func testOpenMessagesExtensionAndCaptureStartOfTurnComparison() throws {
        openUnluckySevensExtension()
        waitForUXLabChrome()
        loadStartTurnGameplaySlice()

        let startSurface = turnElement(
            identifier: "uls.startTurn.surface",
            labels: ["Start of turn"]
        )
        let devCards = turnElement(
            identifier: "uls.startTurn.devCards",
            labels: ["Dev Cards"]
        )
        let roll = turnElement(
            identifier: "uls.startTurn.roll",
            labels: ["Roll dice"]
        )
        let board = turnElement(identifier: "uls.tabletop.board", labels: [])
        let boardHost = turnElement(
            identifier: "uls.tabletop.boardHost",
            labels: ["Live game board host"]
        )

        XCTAssertTrue(startSurface.waitForExistence(timeout: 8))
        XCTAssertTrue(devCards.waitForExistence(timeout: 4))
        XCTAssertTrue(roll.waitForExistence(timeout: 4))
        XCTAssertTrue(board.waitForExistence(timeout: 4))
        XCTAssertTrue(boardHost.waitForExistence(timeout: 4))
        XCTAssertGreaterThanOrEqual(devCards.frame.width, 44)
        XCTAssertGreaterThanOrEqual(devCards.frame.height, 44)
        XCTAssertGreaterThanOrEqual(roll.frame.width, 44)
        XCTAssertGreaterThanOrEqual(roll.frame.height, 44)

        let boardFrame = board.frame
        let boardHostValue = String(describing: boardHost.value)
        attachScreenshot(named: "Start of Turn - Dev or Roll")

        devCards.tap()
        let chooser = turnElement(
            identifier: "uls.startTurn.devChooser",
            labels: ["Playable pre-roll Dev Cards"]
        )
        XCTAssertTrue(chooser.waitForExistence(timeout: 4))
        XCTAssertEqual(board.frame, boardFrame)
        XCTAssertEqual(String(describing: boardHost.value), boardHostValue)
        attachScreenshot(named: "Start of Turn - Dev Chooser")

        devCards.tap()
        XCTAssertTrue(waitForDisappearance(of: chooser, timeout: 4))
        roll.doubleTap()
        XCTAssertTrue(waitForDisappearance(of: startSurface, timeout: 8))
        XCTAssertTrue(boardHost.exists)
        XCTAssertEqual(String(describing: boardHost.value), boardHostValue)
    }

    func testCaptureNotPrimaryPlayerOrdinaryWaiting() throws {
        openUnluckySevensExtension()
        waitForUXLabChrome()
        loadNotPrimaryWaitingSlice()

        let board = turnElement(identifier: "uls.tabletop.board", labels: [])
        let publicRail = turnElement(identifier: "uls.turn.publicRail", labels: [])
        let status = turnElement(identifier: "uls.turn.status", labels: ["Maya's Turn"])
        let hand = turnElement(identifier: "uls.feltTools.hand", labels: ["Hand"])

        XCTAssertTrue(board.waitForExistence(timeout: 8))
        XCTAssertTrue(publicRail.waitForExistence(timeout: 4))
        XCTAssertTrue(status.waitForExistence(timeout: 4))
        XCTAssertTrue(hand.waitForExistence(timeout: 4))
        XCTAssertGreaterThanOrEqual(hand.frame.width, 44)
        XCTAssertGreaterThanOrEqual(hand.frame.height, 44)
        XCTAssertEqual(hand.frame.midX, board.frame.midX, accuracy: 2)
        XCTAssertFalse(messages.buttons["uls.turnObject.build"].firstMatch.exists)
        XCTAssertFalse(messages.buttons["uls.turnObject.trade"].firstMatch.exists)
        XCTAssertFalse(messages.buttons["uls.turnObject.endTurn"].firstMatch.exists)
        XCTAssertFalse(
            turnElement(identifier: "uls.physicalProps.actionSpread", labels: [], timeout: 1).exists,
            "Ordinary waiting should begin with an empty action well."
        )
        attachScreenshot(named: "Not Primary Player - Ordinary Waiting")
    }

    func testCaptureNotPrimaryPlayerIncomingTrade() throws {
        openUnluckySevensExtension()
        waitForUXLabChrome()
        loadNotPrimaryOfferSlice()

        let board = turnElement(identifier: "uls.tabletop.board", labels: [])
        let boardHost = turnElement(
            identifier: "uls.tabletop.boardHost",
            labels: ["Live game board host"]
        )
        let trade = turnElement(identifier: "uls.turnObject.trade", labels: ["Trade"])
        let hand = turnElement(identifier: "uls.feltTools.hand", labels: ["Hand"])
        XCTAssertTrue(board.waitForExistence(timeout: 8))
        XCTAssertTrue(boardHost.waitForExistence(timeout: 4))
        XCTAssertTrue(trade.waitForExistence(timeout: 4))
        XCTAssertTrue(hand.waitForExistence(timeout: 4))
        XCTAssertEqual((hand.frame.midX + trade.frame.midX) / 2, board.frame.midX, accuracy: 2)
        let boardFrame = board.frame
        let boardHostValue = String(describing: boardHost.value)

        trade.tap()
        let offerPrompt = turnElement(identifier: "", labels: ["Answer the Trade Offer"])
        let offer = turnElement(identifier: "uls.turn.tradeSurface", labels: [])
        let accept = messages.buttons["Accept"].firstMatch
        let decline = messages.buttons["Decline"].firstMatch
        let counter = messages.buttons["Counter"].firstMatch
        XCTAssertTrue(offerPrompt.waitForExistence(timeout: 4))
        XCTAssertTrue(offer.waitForExistence(timeout: 4))
        XCTAssertTrue(accept.waitForExistence(timeout: 4))
        XCTAssertTrue(decline.waitForExistence(timeout: 4))
        XCTAssertTrue(counter.waitForExistence(timeout: 4))
        for action in [accept, decline, counter] {
            XCTAssertGreaterThanOrEqual(action.frame.width, 44)
            XCTAssertGreaterThanOrEqual(action.frame.height, 44)
            XCTAssertLessThanOrEqual(
                action.frame.maxY,
                trade.frame.minY,
                "Trade response must remain above the physical prop rail."
            )
        }
        assertFrame(of: board, matches: boardFrame, message: "Board moved for incoming trade.")
        XCTAssertEqual(String(describing: boardHost.value), boardHostValue)
        attachScreenshot(named: "Not Primary Player - Incoming Trade")
    }

    func testCaptureNotPrimaryPlayerMultiTypeIncomingTrade() throws {
        openUnluckySevensExtension()
        waitForUXLabChrome()
        loadNotPrimaryMultiTypeOfferSlice()

        let board = turnElement(identifier: "uls.tabletop.board", labels: [])
        let boardHost = turnElement(
            identifier: "uls.tabletop.boardHost",
            labels: ["Live game board host"]
        )
        let trade = turnElement(identifier: "uls.turnObject.trade", labels: ["Trade"])
        let hand = turnElement(identifier: "uls.feltTools.hand", labels: ["Hand"])
        XCTAssertTrue(board.waitForExistence(timeout: 8))
        XCTAssertTrue(boardHost.waitForExistence(timeout: 4))
        XCTAssertTrue(trade.waitForExistence(timeout: 4))
        XCTAssertTrue(hand.waitForExistence(timeout: 4))
        XCTAssertEqual((hand.frame.midX + trade.frame.midX) / 2, board.frame.midX, accuracy: 2)
        let boardFrame = board.frame
        let boardHostValue = String(describing: boardHost.value)

        trade.tap()
        let offerPrompt = turnElement(identifier: "", labels: ["Answer the Trade Offer"])
        let offer = turnElement(identifier: "uls.turn.tradeSurface", labels: [])
        XCTAssertTrue(offerPrompt.waitForExistence(timeout: 4))
        XCTAssertTrue(offer.waitForExistence(timeout: 4))
        XCTAssertTrue(offer.label.contains("1 Wood"))
        XCTAssertTrue(offer.label.contains("2 Sheep"))
        XCTAssertTrue(offer.label.contains("1 Wheat"))
        XCTAssertTrue(offer.label.contains("2 Brick"))
        XCTAssertTrue(offer.label.contains("1 Ore"))

        for action in [
            messages.buttons["Accept"].firstMatch,
            messages.buttons["Decline"].firstMatch,
            messages.buttons["Counter"].firstMatch,
        ] {
            XCTAssertTrue(action.waitForExistence(timeout: 4))
            XCTAssertGreaterThanOrEqual(action.frame.width, 44)
            XCTAssertGreaterThanOrEqual(action.frame.height, 44)
            XCTAssertLessThanOrEqual(action.frame.maxY, trade.frame.minY)
        }
        assertFrame(of: board, matches: boardFrame, message: "Board moved for multi-type trade.")
        XCTAssertEqual(String(describing: boardHost.value), boardHostValue)
        attachScreenshot(named: "Not Primary Player - Multi-Type Incoming Trade")
    }

    func testCaptureNotPrimaryPlayerWaitingOnDiscard() throws {
        openUnluckySevensExtension()
        waitForUXLabChrome()
        loadNotPrimaryDiscardWaitingSlice()

        let board = turnElement(identifier: "uls.tabletop.board", labels: [])
        let publicRail = turnElement(identifier: "uls.turn.publicRail", labels: [])
        let prompt = turnElement(identifier: "", labels: ["Waiting for Theo to discard"])
        let hand = messages.descendants(matching: .any)
            .matching(
                NSPredicate(
                    format: "label == %@ AND value == %@",
                    "Hand",
                    "Available after the discard"
                )
            )
            .firstMatch
        XCTAssertTrue(board.waitForExistence(timeout: 8))
        XCTAssertTrue(publicRail.waitForExistence(timeout: 4))
        XCTAssertTrue(prompt.waitForExistence(timeout: 4))
        XCTAssertTrue(hand.waitForExistence(timeout: 4))
        XCTAssertEqual(hand.frame.midX, board.frame.midX, accuracy: 2)
        XCTAssertFalse(messages.buttons["Publish Discard"].firstMatch.exists)
        XCTAssertFalse(
            turnElement(identifier: "uls.physicalProps.actionSpread", labels: [], timeout: 1).exists,
            "Discard waiting should begin with the inspection hand closed."
        )
        attachScreenshot(named: "Not Primary Player - Waiting on Discard")
    }

    func testCaptureActionableDiscardComposer() throws {
        openUnluckySevensExtension()
        waitForUXLabChrome()

        openUXLabPanel()
        let flatOcean = turnElement(
            identifier: "uls.uxLab.oceanStyle.flat",
            labels: ["Flat"]
        )
        XCTAssertTrue(flatOcean.waitForExistence(timeout: 4))
        flatOcean.tap()

        loadTurnGameplaySlice()
        let normalTurnBoard = turnElement(identifier: "uls.tabletop.board", labels: [])
        XCTAssertTrue(normalTurnBoard.waitForExistence(timeout: 8))
        let normalTurnBoardFrame = normalTurnBoard.frame
        attachScreenshot(named: "Normal Turn - Board Reference")

        restoreUXLabChrome()
        activateDirectCleanState(
            identifier: "uls.uxLab.cleanShot.pendingDiscard.direct",
            label: "Clean actionable discard"
        )

        let surface = turnElement(identifier: "uls.discard.surface", labels: [])
        let progress = turnElement(identifier: "uls.discard.progress", labels: [])
        let submit = messages.buttons["uls.discard.submit"].firstMatch
        let board = turnElement(identifier: "uls.tabletop.board", labels: [])
        let physicalTopBar = turnElement(identifier: "uls.turn.topBar", labels: [])
        let legacyShelf = messages.descendants(matching: .any)
            .matching(identifier: "uls.overlayShelf")
            .firstMatch
        let wood = messages.buttons["uls.discard.hand.wood"].firstMatch
        let brick = messages.buttons["uls.discard.hand.brick"].firstMatch
        let wheat = messages.buttons["uls.discard.hand.wheat"].firstMatch
        let selectedWood = messages.buttons["uls.discard.selection.wood"].firstMatch

        XCTAssertTrue(surface.waitForExistence(timeout: 8))
        XCTAssertTrue(progress.waitForExistence(timeout: 4))
        XCTAssertTrue(submit.waitForExistence(timeout: 4))
        XCTAssertEqual(submit.label, "Confirm")
        XCTAssertTrue(board.waitForExistence(timeout: 4))
        XCTAssertTrue(physicalTopBar.waitForExistence(timeout: 4))
        XCTAssertEqual(
            board.frame,
            normalTurnBoardFrame,
            "Forced discard must preserve the normal-turn board frame."
        )
        XCTAssertFalse(
            turnElement(identifier: "uls.turn.objectRail", labels: [], timeout: 1).exists,
            "The visible discard hand replaces the redundant standalone Hand prop."
        )
        XCTAssertFalse(legacyShelf.exists)
        XCTAssertTrue(wood.waitForExistence(timeout: 4))
        XCTAssertTrue(brick.waitForExistence(timeout: 4))
        XCTAssertTrue(wheat.waitForExistence(timeout: 4))
        XCTAssertEqual(progress.value as? String, "0 of 5 selected")
        XCTAssertFalse(submit.isEnabled)
        XCTAssertGreaterThanOrEqual(wood.frame.width, 44)
        XCTAssertGreaterThanOrEqual(wood.frame.height, 44)
        XCTAssertGreaterThanOrEqual(submit.frame.height, 44)
        XCTAssertEqual(submit.frame.midY, wood.frame.midY, accuracy: 2)

        let boardFrame = board.frame
        wood.tap()
        wood.tap()
        wood.tap()
        brick.tap()
        brick.tap()

        XCTAssertEqual(progress.value as? String, "5 of 5 selected")
        XCTAssertTrue(submit.isEnabled)
        XCTAssertTrue(selectedWood.waitForExistence(timeout: 2))
        XCTAssertGreaterThanOrEqual(selectedWood.frame.width, 44)
        XCTAssertGreaterThanOrEqual(selectedWood.frame.height, 44)
        XCTAssertEqual(selectedWood.value as? String, "3 selected")
        XCTAssertLessThanOrEqual(
            wood.frame.maxY,
            selectedWood.frame.minY,
            "Discard controls must reserve their own row instead of clipping across the hand cards."
        )
        XCTAssertLessThanOrEqual(selectedWood.frame.maxY, surface.frame.maxY)
        XCTAssertEqual(board.frame, boardFrame)

        selectedWood.tap()
        XCTAssertEqual(progress.value as? String, "4 of 5 selected")
        XCTAssertEqual(selectedWood.value as? String, "2 selected")
        XCTAssertFalse(submit.isEnabled)

        wheat.tap()
        XCTAssertEqual(progress.value as? String, "5 of 5 selected")
        XCTAssertTrue(submit.isEnabled)
        XCTAssertEqual(board.frame, boardFrame)
        attachScreenshot(named: "Discard - Ready to Submit")
    }

    func testSettleStartOfTurnChoiceForDirectStill() throws {
        openUnluckySevensExtension()
        waitForUXLabChrome()
        loadStartTurnGameplaySlice()
        XCTAssertTrue(
            turnElement(identifier: "uls.startTurn.surface", labels: ["Start of turn"])
                .waitForExistence(timeout: 8)
        )
    }

    func testSettleStartOfTurnDevChooserForDirectStill() throws {
        openUnluckySevensExtension()
        waitForUXLabChrome()
        loadStartTurnGameplaySlice()
        let devCards = turnElement(
            identifier: "uls.startTurn.devCards",
            labels: ["Dev Cards"]
        )
        XCTAssertTrue(devCards.waitForExistence(timeout: 8))
        devCards.tap()
        XCTAssertTrue(
            turnElement(
                identifier: "uls.startTurn.devChooser",
                labels: ["Playable pre-roll Dev Cards"]
            )
            .waitForExistence(timeout: 4)
        )
    }

    func testExerciseStartOfTurnRollForDirectVideo() throws {
        openUnluckySevensExtension()
        waitForUXLabChrome()
        loadStartTurnGameplaySlice()
        let roll = turnElement(
            identifier: "uls.startTurn.roll",
            labels: ["Roll dice"]
        )
        XCTAssertTrue(roll.waitForExistence(timeout: 8))
        roll.tap()
        Thread.sleep(forTimeInterval: 1.2)
    }

    func testSettleStartOfTurnDiceBowlForDirectStill() throws {
        openUnluckySevensExtension()
        waitForUXLabChrome()
        loadStartTurnGameplaySlice()
        let roll = turnElement(
            identifier: "uls.startTurn.roll",
            labels: ["Roll dice"]
        )
        XCTAssertTrue(roll.waitForExistence(timeout: 8))
        roll.tap()
        Thread.sleep(forTimeInterval: 1.50)
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = "Start of Turn - 3D Dice Bowl"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testRecordStartOfTurnDiceRollForDirectVideo() throws {
        openUnluckySevensExtension()
        waitForUXLabChrome()
        loadStartTurnGameplaySlice()
        let roll = turnElement(
            identifier: "uls.startTurn.roll",
            labels: ["Roll dice"]
        )
        XCTAssertTrue(roll.waitForExistence(timeout: 8))
        XCTContext.runActivity(named: "External recording arm window") { _ in
            Thread.sleep(forTimeInterval: 5)
        }
        roll.tap()
        Thread.sleep(forTimeInterval: 3.4)
    }

    func testCaptureStartOfTurnDiceRollFrames() throws {
        openUnluckySevensExtension()
        waitForUXLabChrome()
        loadStartTurnGameplaySlice()
        let roll = turnElement(
            identifier: "uls.startTurn.roll",
            labels: ["Roll dice"]
        )
        XCTAssertTrue(roll.waitForExistence(timeout: 8))

        attachDiceRollFrame(index: 0)
        roll.tap()
        for index in 1...14 {
            Thread.sleep(forTimeInterval: 0.12)
            attachDiceRollFrame(index: index)
        }
        Thread.sleep(forTimeInterval: 0.45)
        attachDiceRollFrame(index: 15)
    }

    func testOpenMessagesExtensionAndCaptureTurnGameplaySlice() throws {
        openUnluckySevensExtension()
        waitForUXLabChrome()
        loadTurnGameplaySlice()

        XCTAssertTrue(
            firstExistingElement(
                [
                    messages.staticTexts["Your turn"].firstMatch,
                    messages.staticTexts["Hand"].firstMatch,
                    messages.staticTexts["Dev"].firstMatch,
                    messages.buttons["End Turn"].firstMatch,
                ],
                timeout: 8
            )
            .exists,
            "Expected the turn gameplay fixture to render."
        )
        collapseUXLabPanelIfExpanded()
        let settingsHookEvidence = turnElement(
            identifier: "uls.settings.hookEvidence",
            labels: ["Settings hook invocations"]
        )
        let settingsButton = turnElement(identifier: "", labels: ["Settings"])
        XCTAssertTrue(settingsHookEvidence.waitForExistence(timeout: 4))
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 4))
        let initialSettingsHookValue = String(describing: settingsHookEvidence.value)
        settingsButton.tap()
        XCTAssertTrue(
            waitForValueChange(
                of: settingsHookEvidence,
                from: initialSettingsHookValue,
                timeout: 4
            ),
            "Expected Settings to invoke the root navigation hook without requiring a destination in this slice."
        )
        let handButton = turnElement(identifier: "uls.feltTools.hand", labels: ["Hand"])
        XCTAssertTrue(handButton.waitForExistence(timeout: 4), "Expected the fixed Hand object.")
        let buildButton = turnElement(identifier: "uls.turnObject.build", labels: ["Build"])
        let tradeButton = turnElement(identifier: "uls.turnObject.trade", labels: ["Trade"])
        let endButton = turnElement(identifier: "uls.turnObject.endTurn", labels: ["End", "End Turn"])
        let turnObjects = [handButton, buildButton, tradeButton, endButton]
        let board = turnElement(identifier: "uls.tabletop.board", labels: [])
        let boardHost = turnElement(identifier: "uls.tabletop.boardHost", labels: ["Live game board host"])
        let bankRack = turnElement(identifier: "uls.tabletop.bankRack", labels: ["Bank"])
        let publicRail = turnElement(identifier: "uls.turn.publicRail", labels: [])
        let status = turnElement(identifier: "uls.turn.topBar", labels: [])
        let actionWell = turnElement(identifier: "uls.turn.actionWell", labels: ["Reserved turn action well"])
        let handSurface = turnElement(identifier: "uls.physicalProps.actionSpread", labels: [])
        XCTAssertTrue(board.waitForExistence(timeout: 4), "Expected the live board container to be measurable.")
        XCTAssertTrue(boardHost.waitForExistence(timeout: 4), "Expected the live board host identity marker.")
        XCTAssertTrue(bankRack.waitForExistence(timeout: 4), "Expected the bank rack to be measurable.")
        XCTAssertTrue(publicRail.waitForExistence(timeout: 4), "Expected the public table rail.")
        XCTAssertTrue(status.waitForExistence(timeout: 4), "Expected the fixed turn status.")
        XCTAssertTrue(actionWell.waitForExistence(timeout: 4), "Expected the fixed reserved action well.")
        XCTAssertTrue(handSurface.waitForExistence(timeout: 4), "Expected Hand to own the default action well.")
        let fixedBoardFrame = board.frame
        let fixedBankRackFrame = bankRack.frame
        let fixedPublicRailFrame = publicRail.frame
        let fixedStatusFrame = status.frame
        let fixedActionWellFrame = actionWell.frame
        expectedTurnActionWellFrame = fixedActionWellFrame
        assertElement(handSurface, isContainedIn: fixedActionWellFrame, message: "Hand must stay inside the reserved action well.")
        let fixedTurnObjectFrames = turnObjects.map(\.frame)
        let fixedTurnRailFrame = unionFrame(of: turnObjects)
        let fixedBoardHostValue = String(describing: boardHost.value)
        XCTAssertFalse(fixedBoardHostValue.isEmpty)
        for object in turnObjects {
            XCTAssertTrue(object.exists, "Expected every executable turn object at its fixed anchor.")
            XCTAssertGreaterThanOrEqual(object.frame.width, 44)
            XCTAssertGreaterThanOrEqual(object.frame.height, 44)
        }
        let collapsedBankAccessibility = [bankRack.label, bankRack.value as? String ?? ""].joined(separator: " ")
        XCTAssertEqual(bankRack.label, "Bank")
        XCTAssertNil(
            collapsedBankAccessibility.rangeOfCharacter(from: .decimalDigits),
            "Collapsed Bank accessibility must not disclose exact counts."
        )
        XCTAssertFalse(messages.staticTexts["19"].firstMatch.exists)
        XCTAssertFalse(
            messages.descendants(matching: .any)
                .matching(NSPredicate(format: "label CONTAINS[c] %@", "left in bank"))
                .firstMatch
                .exists,
            "Collapsed Bank must not expose exact count labels before it is tapped."
        )
        assertPersistentTurnGeometry(
            board: board, boardFrame: fixedBoardFrame,
            boardHost: boardHost, boardHostValue: fixedBoardHostValue,
            bankRack: bankRack, bankRackFrame: fixedBankRackFrame,
            publicRail: publicRail, publicRailFrame: fixedPublicRailFrame,
            status: status, statusFrame: fixedStatusFrame,
            turnObjects: turnObjects, turnObjectFrames: fixedTurnObjectFrames,
            turnRailFrame: fixedTurnRailFrame, route: "Hand"
        )
        attachScreenshot(named: "Unlucky Sevens - turn gameplay open hand")

        let concealedBankValue = String(describing: bankRack.value)
        bankRack.tap()
        XCTAssertTrue(
            waitForValueChange(of: bankRack, from: concealedBankValue, timeout: 4),
            "Expected qualitative Bank levels after tapping the public Bank object."
        )
        XCTAssertNil(
            String(describing: bankRack.value).rangeOfCharacter(from: .decimalDigits),
            "Revealed Bank accessibility must expose only H/M/L levels."
        )
        XCTAssertTrue(handSurface.exists, "Bank reveal must not replace the selected Hand spread.")
        assertFrame(
            of: board,
            matches: fixedBoardFrame,
            message: "The board frame must stay fixed when Bank opens."
        )
        assertFrame(
            of: bankRack,
            matches: fixedBankRackFrame,
            message: "The Bank object must stay fixed when its counts open."
        )
        assertFrame(
            of: publicRail,
            matches: fixedPublicRailFrame,
            message: "The public rail must stay fixed when Bank opens."
        )
        assertFrame(
            of: status,
            matches: fixedStatusFrame,
            message: "The top status must stay fixed when Bank opens."
        )
        XCTAssertEqual(String(describing: boardHost.value), fixedBoardHostValue)
        assertPersistentTurnGeometry(
            board: board, boardFrame: fixedBoardFrame,
            boardHost: boardHost, boardHostValue: fixedBoardHostValue,
            bankRack: bankRack, bankRackFrame: fixedBankRackFrame,
            publicRail: publicRail, publicRailFrame: fixedPublicRailFrame,
            status: status, statusFrame: fixedStatusFrame,
            turnObjects: turnObjects, turnObjectFrames: fixedTurnObjectFrames,
            turnRailFrame: fixedTurnRailFrame, route: "Bank"
        )
        attachScreenshot(named: "Unlucky Sevens - turn gameplay bank open")

        let revealedBankValue = String(describing: bankRack.value)
        bankRack.tap()
        XCTAssertTrue(
            waitForValueChange(
                of: bankRack,
                from: revealedBankValue,
                timeout: 4
            ),
            "Expected tapping Bank again to conceal its levels."
        )
        XCTAssertTrue(
            handSurface.exists,
            "Expected Hand to remain open while public Bank information toggles."
        )
        assertElement(handSurface, isContainedIn: fixedActionWellFrame, message: "Hand must reuse the reserved action well.")

        XCTAssertTrue(endButton.waitForExistence(timeout: 4))
        endButton.tap()
        let endConfirmation = turnElement(identifier: "uls.turn.endConfirmation", labels: [])
        XCTAssertTrue(
            endConfirmation.waitForExistence(timeout: 4),
            "Expected inline End Turn confirmation."
        )
        assertElement(endConfirmation, isContainedIn: fixedActionWellFrame, message: "End confirmation must reuse the reserved action well.")
        XCTAssertEqual(String(describing: boardHost.value), fixedBoardHostValue)
        assertPersistentTurnGeometry(
            board: board, boardFrame: fixedBoardFrame,
            boardHost: boardHost, boardHostValue: fixedBoardHostValue,
            bankRack: bankRack, bankRackFrame: fixedBankRackFrame,
            publicRail: publicRail, publicRailFrame: fixedPublicRailFrame,
            status: status, statusFrame: fixedStatusFrame,
            turnObjects: turnObjects, turnObjectFrames: fixedTurnObjectFrames,
            turnRailFrame: fixedTurnRailFrame, route: "End confirmation"
        )

        endButton.tap()
        XCTAssertTrue(
            endConfirmation.waitForNonExistence(timeout: 4),
            "Selecting End again must close its inline confirmation."
        )
        XCTAssertFalse(endButton.isSelected)

        let gameInfo = turnElement(
            identifier: "",
            labels: ["Players and game information", "Game information"]
        )
        XCTAssertTrue(gameInfo.waitForExistence(timeout: 4))
        gameInfo.tap()
        let gameInfoSurface = turnElement(identifier: "uls.turn.gameInfo", labels: [])
        XCTAssertTrue(
            gameInfoSurface.waitForExistence(timeout: 4),
            "Expected Game Info to replace End Turn confirmation."
        )
        XCTAssertTrue(
            messages.staticTexts["Last turn: Maya rolled 6, built road, ended turn"]
                .firstMatch
                .waitForExistence(timeout: 4),
            "Expected Game Info to expose one public recent-turn recap."
        )
        assertElement(gameInfoSurface, isContainedIn: fixedActionWellFrame, message: "Game Info must reuse the reserved action well.")
        assertFrame(of: board, matches: fixedBoardFrame, message: "The board must stay fixed for Game Info.")
        XCTAssertEqual(String(describing: boardHost.value), fixedBoardHostValue)
        assertPersistentTurnGeometry(
            board: board, boardFrame: fixedBoardFrame,
            boardHost: boardHost, boardHostValue: fixedBoardHostValue,
            bankRack: bankRack, bankRackFrame: fixedBankRackFrame,
            publicRail: publicRail, publicRailFrame: fixedPublicRailFrame,
            status: status, statusFrame: fixedStatusFrame,
            turnObjects: turnObjects, turnObjectFrames: fixedTurnObjectFrames,
            turnRailFrame: fixedTurnRailFrame, route: "Game Info"
        )
        attachScreenshot(named: "Unlucky Sevens - turn gameplay game info")

        gameInfo.tap()
        XCTAssertTrue(gameInfoSurface.waitForNonExistence(timeout: 4))

        XCTAssertTrue(buildButton.waitForExistence(timeout: 4))
        buildButton.tap()
        let buildSurface = turnElement(identifier: "uls.physicalProps.actionSpread", labels: [])
        let roadButton = exactLabelElement("Road")
        XCTAssertTrue(roadButton.waitForExistence(timeout: 4))
        XCTAssertTrue(exactLabelElement("Settlement").exists)
        XCTAssertTrue(exactLabelElement("City").exists)
        XCTAssertFalse(messages.buttons["Buy Dev"].firstMatch.exists)
        XCTAssertTrue(buildButton.isSelected)
        assertElement(buildSurface, isContainedIn: fixedActionWellFrame, message: "Build must stay inside the reserved action well.")
        assertFrame(of: board, matches: fixedBoardFrame, message: "The board must stay fixed when Build opens.")
        XCTAssertEqual(String(describing: boardHost.value), fixedBoardHostValue)
        assertPersistentTurnGeometry(
            board: board, boardFrame: fixedBoardFrame,
            boardHost: boardHost, boardHostValue: fixedBoardHostValue,
            bankRack: bankRack, bankRackFrame: fixedBankRackFrame,
            publicRail: publicRail, publicRailFrame: fixedPublicRailFrame,
            status: status, statusFrame: fixedStatusFrame,
            turnObjects: turnObjects, turnObjectFrames: fixedTurnObjectFrames,
            turnRailFrame: fixedTurnRailFrame, route: "Build choices"
        )
        attachScreenshot(named: "Unlucky Sevens - turn gameplay build choices")

        roadButton.tap()
        let placeRoadPrompt = exactLabelElement("Place a Road")
        XCTAssertTrue(placeRoadPrompt.waitForExistence(timeout: 4))
        XCTAssertTrue(buildSurface.waitForNonExistence(timeout: 4))
        XCTAssertTrue(buildButton.isSelected)
        assertFrame(of: board, matches: fixedBoardFrame, message: "The board must stay fixed for Road targets.")
        XCTAssertEqual(String(describing: boardHost.value), fixedBoardHostValue)
        assertPersistentTurnGeometry(
            board: board, boardFrame: fixedBoardFrame,
            boardHost: boardHost, boardHostValue: fixedBoardHostValue,
            bankRack: bankRack, bankRackFrame: fixedBankRackFrame,
            publicRail: publicRail, publicRailFrame: fixedPublicRailFrame,
            status: status, statusFrame: fixedStatusFrame,
            turnObjects: turnObjects, turnObjectFrames: fixedTurnObjectFrames,
            turnRailFrame: fixedTurnRailFrame, route: "Road targets"
        )
        attachScreenshot(named: "Unlucky Sevens - turn gameplay road targets")
        buildButton.tap()
        XCTAssertTrue(placeRoadPrompt.waitForNonExistence(timeout: 4))

        buildButton.tap()
        let settlementButton = exactLabelElement("Settlement")
        XCTAssertTrue(settlementButton.waitForExistence(timeout: 4))
        settlementButton.tap()
        let placeSettlementPrompt = exactLabelElement("Place a Settlement")
        XCTAssertTrue(placeSettlementPrompt.waitForExistence(timeout: 4))
        assertPersistentTurnGeometry(
            board: board, boardFrame: fixedBoardFrame,
            boardHost: boardHost, boardHostValue: fixedBoardHostValue,
            bankRack: bankRack, bankRackFrame: fixedBankRackFrame,
            publicRail: publicRail, publicRailFrame: fixedPublicRailFrame,
            status: status, statusFrame: fixedStatusFrame,
            turnObjects: turnObjects, turnObjectFrames: fixedTurnObjectFrames,
            turnRailFrame: fixedTurnRailFrame, route: "Settlement targets"
        )
        attachScreenshot(named: "Unlucky Sevens - turn gameplay settlement targets")
        buildButton.tap()
        XCTAssertTrue(placeSettlementPrompt.waitForNonExistence(timeout: 4))

        buildButton.tap()
        let cityButton = exactLabelElement("City")
        XCTAssertTrue(cityButton.waitForExistence(timeout: 4))
        cityButton.tap()
        let upgradeCityPrompt = exactLabelElement("Upgrade to a City")
        XCTAssertTrue(upgradeCityPrompt.waitForExistence(timeout: 4))
        assertPersistentTurnGeometry(
            board: board, boardFrame: fixedBoardFrame,
            boardHost: boardHost, boardHostValue: fixedBoardHostValue,
            bankRack: bankRack, bankRackFrame: fixedBankRackFrame,
            publicRail: publicRail, publicRailFrame: fixedPublicRailFrame,
            status: status, statusFrame: fixedStatusFrame,
            turnObjects: turnObjects, turnObjectFrames: fixedTurnObjectFrames,
            turnRailFrame: fixedTurnRailFrame, route: "City targets"
        )
        attachScreenshot(named: "Unlucky Sevens - turn gameplay city targets")
        buildButton.tap()
        XCTAssertTrue(upgradeCityPrompt.waitForNonExistence(timeout: 4))

        XCTAssertTrue(tradeButton.waitForExistence(timeout: 4))
        tradeButton.tap()
        let tradeSurface = turnElement(identifier: "uls.turn.tradeSurface", labels: [])
        let playerTrade = exactLabelElement("Player Trade")
        XCTAssertTrue(playerTrade.waitForExistence(timeout: 4))
        XCTAssertTrue(tradeSurface.waitForExistence(timeout: 4))
        XCTAssertTrue(messages.staticTexts["Maritime / Bank"].firstMatch.exists)
        XCTAssertTrue(tradeButton.isSelected)
        assertElement(tradeSurface, isContainedIn: fixedActionWellFrame, message: "Trade chooser must stay inside the reserved action well.")
        assertElement(playerTrade, isContainedIn: fixedActionWellFrame, message: "Trade chooser must stay inside the reserved action well.")
        assertPersistentTurnGeometry(
            board: board, boardFrame: fixedBoardFrame,
            boardHost: boardHost, boardHostValue: fixedBoardHostValue,
            bankRack: bankRack, bankRackFrame: fixedBankRackFrame,
            publicRail: publicRail, publicRailFrame: fixedPublicRailFrame,
            status: status, statusFrame: fixedStatusFrame,
            turnObjects: turnObjects, turnObjectFrames: fixedTurnObjectFrames,
            turnRailFrame: fixedTurnRailFrame, route: "Trade chooser"
        )
        attachScreenshot(named: "Unlucky Sevens - turn gameplay trade routes")
        playerTrade.tap()
        let tradeComposerSignal = messages.staticTexts["You Give"].firstMatch
        XCTAssertTrue(tradeComposerSignal.waitForExistence(timeout: 4))
        assertElement(tradeSurface, isContainedIn: fixedActionWellFrame, message: "Trade composer must stay inside the action well.")
        assertElement(tradeComposerSignal, isContainedIn: fixedActionWellFrame, message: "Trade composer must stay inside the reserved action well.")
        assertFrame(of: board, matches: fixedBoardFrame, message: "The board must stay fixed for the trade composer.")
        XCTAssertEqual(String(describing: boardHost.value), fixedBoardHostValue)
        assertPersistentTurnGeometry(
            board: board, boardFrame: fixedBoardFrame,
            boardHost: boardHost, boardHostValue: fixedBoardHostValue,
            bankRack: bankRack, bankRackFrame: fixedBankRackFrame,
            publicRail: publicRail, publicRailFrame: fixedPublicRailFrame,
            status: status, statusFrame: fixedStatusFrame,
            turnObjects: turnObjects, turnObjectFrames: fixedTurnObjectFrames,
            turnRailFrame: fixedTurnRailFrame, route: "Trade composer"
        )
        attachScreenshot(named: "Unlucky Sevens - turn gameplay trade composer")
        let cancelTradeDraft = messages.buttons["Cancel"].firstMatch
        XCTAssertTrue(
            waitForHittable(cancelTradeDraft, timeout: 4),
            "Trade composer Cancel must remain pinned and reachable in the fixed action well."
        )
        cancelTradeDraft.tap()
        XCTAssertTrue(tradeComposerSignal.waitForNonExistence(timeout: 4))
        XCTAssertFalse(tradeButton.isSelected)

        handButton.tap()
        let ownedDevCards = turnElement(
            identifier: "uls.physicalProps.ownedDevCards",
            labels: ["Owned Dev Cards"]
        )
        XCTAssertTrue(ownedDevCards.waitForExistence(timeout: 4))
        let ownedDevInventory = String(describing: ownedDevCards.value)
        for expectedKind in ["Knight", "Monopoly", "Year of Plenty", "Road Building", "Victory Point"] {
            XCTAssertTrue(
                ownedDevInventory.contains(expectedKind),
                "Hand must expose every owned Dev Card kind, including \(expectedKind)."
            )
        }
        XCTAssertTrue(ownedDevInventory.contains("1 new"))
        XCTAssertTrue(ownedDevInventory.contains("playable"))
        ownedDevCards.tap()
        let devSurface = turnElement(identifier: "uls.physicalProps.actionSpread", labels: [])
        let monopolyCard = exactLabelElement("Monopoly")
        XCTAssertTrue(monopolyCard.waitForExistence(timeout: 4))
        XCTAssertTrue(messages.staticTexts["Knight"].firstMatch.exists)
        XCTAssertTrue(messages.staticTexts["Year of"].firstMatch.exists)
        XCTAssertTrue(messages.staticTexts["Plenty"].firstMatch.exists)
        XCTAssertTrue(messages.staticTexts["Road"].firstMatch.exists)
        XCTAssertTrue(messages.staticTexts["Builder"].firstMatch.exists)
        let victoryPointLabel = exactLabelElement("Victory")
        XCTAssertTrue(victoryPointLabel.waitForExistence(timeout: 4))
        XCTAssertTrue(exactLabelElement("Point").exists)
        XCTAssertTrue(exactLabelElement("Knight").exists)
        assertElement(devSurface, isContainedIn: fixedActionWellFrame, message: "Dev selection must stay inside the reserved action well.")
        assertPersistentTurnGeometry(
            board: board, boardFrame: fixedBoardFrame,
            boardHost: boardHost, boardHostValue: fixedBoardHostValue,
            bankRack: bankRack, bankRackFrame: fixedBankRackFrame,
            publicRail: publicRail, publicRailFrame: fixedPublicRailFrame,
            status: status, statusFrame: fixedStatusFrame,
            turnObjects: turnObjects, turnObjectFrames: fixedTurnObjectFrames,
            turnRailFrame: fixedTurnRailFrame, route: "Dev choices"
        )
        attachScreenshot(named: "Unlucky Sevens - turn gameplay dev choices")

        monopolyCard.tap()
        let devResourceSpread = turnElement(
            identifier: "uls.physicalProps.devResourceSpread",
            labels: ["Development card resource choices"]
        )
        let monopolyWoodChoice = messages.buttons
            .matching(NSPredicate(format: "label BEGINSWITH %@", "Wood, 19 left in bank"))
            .firstMatch
        XCTAssertTrue(
            monopolyWoodChoice.waitForExistence(timeout: 4),
            "Expected Monopoly resource selection inside the reserved well."
        )
        XCTAssertTrue(devResourceSpread.waitForExistence(timeout: 4))
        assertElement(devResourceSpread, isContainedIn: fixedActionWellFrame, message: "Dev resource selection must stay inside the action well.")
        assertFrame(of: board, matches: fixedBoardFrame, message: "The board must stay fixed for Dev resource selection.")
        XCTAssertEqual(String(describing: boardHost.value), fixedBoardHostValue)
        assertPersistentTurnGeometry(
            board: board, boardFrame: fixedBoardFrame,
            boardHost: boardHost, boardHostValue: fixedBoardHostValue,
            bankRack: bankRack, bankRackFrame: fixedBankRackFrame,
            publicRail: publicRail, publicRailFrame: fixedPublicRailFrame,
            status: status, statusFrame: fixedStatusFrame,
            turnObjects: turnObjects, turnObjectFrames: fixedTurnObjectFrames,
            turnRailFrame: fixedTurnRailFrame, route: "Dev resource selection"
        )
        attachScreenshot(named: "Unlucky Sevens - turn gameplay dev resource selection")

        handButton.tap()
        XCTAssertTrue(ownedDevCards.waitForExistence(timeout: 4))
        ownedDevCards.tap()
        let knightCard = exactLabelElement("Knight")
        XCTAssertTrue(knightCard.waitForExistence(timeout: 4))
        knightCard.tap()
        XCTAssertTrue(exactLabelElement("Move the Robber").waitForExistence(timeout: 4))
        assertFrame(of: board, matches: fixedBoardFrame, message: "The board must stay fixed for Dev board selection.")
        XCTAssertEqual(String(describing: boardHost.value), fixedBoardHostValue)
        assertPersistentTurnGeometry(
            board: board, boardFrame: fixedBoardFrame,
            boardHost: boardHost, boardHostValue: fixedBoardHostValue,
            bankRack: bankRack, bankRackFrame: fixedBankRackFrame,
            publicRail: publicRail, publicRailFrame: fixedPublicRailFrame,
            status: status, statusFrame: fixedStatusFrame,
            turnObjects: turnObjects, turnObjectFrames: fixedTurnObjectFrames,
            turnRailFrame: fixedTurnRailFrame, route: "Dev board selection"
        )
        attachScreenshot(named: "Unlucky Sevens - turn gameplay dev board selection")
        handButton.tap()

        endButton.tap()
        XCTAssertTrue(endConfirmation.waitForExistence(timeout: 4))
        assertElement(endConfirmation, isContainedIn: fixedActionWellFrame, message: "End confirmation must stay inside the action well.")
        let keepPlayingButton = messages.buttons["Keep Playing"].firstMatch
        let confirmEndButton = messages.buttons["End Turn"].firstMatch
        XCTAssertGreaterThanOrEqual(keepPlayingButton.frame.height, 44)
        XCTAssertGreaterThanOrEqual(confirmEndButton.frame.height, 44)
        attachScreenshot(named: "Unlucky Sevens - turn gameplay end confirmation")

        gameInfo.tap()
        XCTAssertTrue(gameInfoSurface.waitForExistence(timeout: 4))
        assertElement(gameInfoSurface, isContainedIn: fixedActionWellFrame, message: "Cross-object replacement must stay inside the action well.")
        assertFrame(of: board, matches: fixedBoardFrame, message: "The board must remain fixed after every action-well route.")
        XCTAssertEqual(String(describing: boardHost.value), fixedBoardHostValue)

        gameInfo.tap()
        let devDeck = turnElement(
            identifier: "uls.tabletop.devDeck",
            labels: ["Buy development card, 12 cards remaining"]
        )
        XCTAssertTrue(devDeck.waitForExistence(timeout: 4))
        devDeck.tap()
        XCTAssertTrue(
            handSurface.waitForExistence(timeout: 4),
            "Expected the public draw pile to own Buy Dev and return to Hand after purchase."
        )
        assertElement(handSurface, isContainedIn: fixedActionWellFrame, message: "A draw-pile purchase must return inside the fixed Hand well.")
        assertFrame(of: board, matches: fixedBoardFrame, message: "Buying from the public draw pile must not move the board.")
        XCTAssertEqual(String(describing: boardHost.value), fixedBoardHostValue)
        assertPersistentTurnGeometry(
            board: board, boardFrame: fixedBoardFrame,
            boardHost: boardHost, boardHostValue: fixedBoardHostValue,
            bankRack: bankRack, bankRackFrame: fixedBankRackFrame,
            publicRail: publicRail, publicRailFrame: fixedPublicRailFrame,
            status: status, statusFrame: fixedStatusFrame,
            turnObjects: turnObjects, turnObjectFrames: fixedTurnObjectFrames,
            turnRailFrame: fixedTurnRailFrame, route: "Buy Dev"
        )
        let updatedConcealedBankValue = String(describing: bankRack.value)
        bankRack.tap()
        XCTAssertTrue(waitForValueChange(of: bankRack, from: updatedConcealedBankValue, timeout: 4))
        XCTAssertNil(String(describing: bankRack.value).rangeOfCharacter(from: .decimalDigits))
        XCTAssertTrue(handSurface.exists, "Updated Bank levels must not replace Hand.")
        assertPersistentTurnGeometry(
            board: board, boardFrame: fixedBoardFrame,
            boardHost: boardHost, boardHostValue: fixedBoardHostValue,
            bankRack: bankRack, bankRackFrame: fixedBankRackFrame,
            publicRail: publicRail, publicRailFrame: fixedPublicRailFrame,
            status: status, statusFrame: fixedStatusFrame,
            turnObjects: turnObjects, turnObjectFrames: fixedTurnObjectFrames,
            turnRailFrame: fixedTurnRailFrame, route: "Updated Bank"
        )
        attachScreenshot(named: "Unlucky Sevens - public draw pile purchase")
    }

    func testOpenMessagesExtensionAndCapturePendingActivePlayerTradeSlice() throws {
        openUnluckySevensExtension()
        activateUXLabQuickState(
            title: "Pending",
            identifier: "uls.uxLab.cleanShot.pendingTrade"
        )

        let tradeButton = turnElement(identifier: "uls.turnObject.trade", labels: ["Trade"])
        XCTAssertTrue(tradeButton.waitForExistence(timeout: 8))
        XCTAssertEqual(
            tradeButton.value as? String,
            "Pending offer",
            "VoiceOver must announce the pending offer while preserving the stable Trade label."
        )
        tradeButton.tap()
        XCTAssertTrue(messages.staticTexts["Your Offer"].firstMatch.waitForExistence(timeout: 4))
        let replaceOffer = messages.buttons["Replace Offer"].firstMatch
        XCTAssertTrue(
            waitForHittable(replaceOffer, timeout: 4),
            "Pending Trade must keep Replace Offer pinned and reachable."
        )
        XCTAssertTrue(messages.staticTexts["Responses"].firstMatch.exists)
        XCTAssertTrue(tradeButton.isSelected)
        attachScreenshot(named: "Unlucky Sevens - pending active player trade")
        replaceOffer.tap()
        XCTAssertTrue(messages.staticTexts["You Give"].firstMatch.waitForExistence(timeout: 4))
    }

    func testSettleTurnBankForDirectStill() throws {
        openSettledTurnGameplaySlice()

        let bankRack = turnElement(identifier: "uls.tabletop.bankRack", labels: ["Bank"])
        XCTAssertTrue(bankRack.waitForExistence(timeout: 4))
        let concealedValue = String(describing: bankRack.value)
        bankRack.tap()
        XCTAssertTrue(waitForValueChange(of: bankRack, from: concealedValue, timeout: 4))
        XCTAssertNil(String(describing: bankRack.value).rangeOfCharacter(from: .decimalDigits))
        Thread.sleep(forTimeInterval: 1)
    }

    func testSettleTurnPendingTradeForDirectStill() throws {
        openUnluckySevensExtension()
        activateUXLabQuickState(
            title: "Pending",
            identifier: "uls.uxLab.cleanShot.pendingTrade"
        )

        let tradeButton = turnElement(identifier: "uls.turnObject.trade", labels: ["Trade"])
        XCTAssertTrue(tradeButton.waitForExistence(timeout: 8))
        XCTAssertEqual(tradeButton.value as? String, "Pending offer")
        tradeButton.tap()
        XCTAssertTrue(messages.staticTexts["Your Offer"].firstMatch.waitForExistence(timeout: 4))
        XCTAssertTrue(waitForHittable(messages.buttons["Replace Offer"].firstMatch, timeout: 4))
        Thread.sleep(forTimeInterval: 1)
    }

    func testSettleTurnBuildTargetForDirectStill() throws {
        openSettledTurnGameplaySlice()

        let buildButton = turnElement(identifier: "uls.turnObject.build", labels: ["Build"])
        XCTAssertTrue(buildButton.waitForExistence(timeout: 4))
        buildButton.tap()
        let roadButton = exactLabelElement("Road")
        XCTAssertTrue(roadButton.waitForExistence(timeout: 4))
        roadButton.tap()
        XCTAssertTrue(exactLabelElement("Place a Road").waitForExistence(timeout: 4))
        Thread.sleep(forTimeInterval: 1)
    }

    func testSettleTurnDevResourceForDirectStill() throws {
        openSettledTurnGameplaySlice()

        let ownedDevCards = turnElement(
            identifier: "uls.physicalProps.ownedDevCards",
            labels: ["Owned Dev Cards"]
        )
        XCTAssertTrue(ownedDevCards.waitForExistence(timeout: 4))
        ownedDevCards.tap()
        let monopolyCard = exactLabelElement("Monopoly")
        XCTAssertTrue(monopolyCard.waitForExistence(timeout: 4))
        monopolyCard.tap()
        XCTAssertTrue(
            messages.buttons
                .matching(NSPredicate(format: "label BEGINSWITH %@", "Wood, 19 left in bank"))
                .firstMatch
                .waitForExistence(timeout: 4)
        )
        Thread.sleep(forTimeInterval: 1)
    }

    func testSettleTurnEndConfirmationForDirectStill() throws {
        openSettledTurnGameplaySlice()

        let endButton = turnElement(identifier: "uls.turnObject.endTurn", labels: ["End", "End Turn"])
        XCTAssertTrue(endButton.waitForExistence(timeout: 4))
        endButton.tap()
        XCTAssertTrue(
            turnElement(identifier: "uls.turn.endConfirmation", labels: ["End turn confirmation"])
                .waitForExistence(timeout: 4)
        )
        Thread.sleep(forTimeInterval: 1)
    }

    func testOpenMessagesExtensionAndCaptureCollapsedHandTraySlice() throws {
        openUnluckySevensExtension()
        waitForUXLabChrome()
        loadTurnGameplaySlice()

        XCTAssertTrue(
            firstExistingElement(
                [
                    messages.staticTexts["Your turn"].firstMatch,
                    messages.staticTexts["Hand"].firstMatch,
                    messages.staticTexts["Dev"].firstMatch,
                ],
                timeout: 8
            )
            .exists,
            "Expected the turn gameplay fixture to render."
        )
        collapseUXLabPanelIfExpanded()
        let handButton = turnElement(identifier: "uls.feltTools.hand", labels: ["Hand"])
        XCTAssertTrue(handButton.waitForExistence(timeout: 4))
        handButton.tap()

        XCTAssertTrue(
            messages.descendants(matching: .any)
                .matching(identifier: "uls.feltTools.handContents")
                .firstMatch
                .waitForNonExistence(timeout: 4),
            "Expected the Hand object to close the action well."
        )
        XCTAssertFalse(
            messages.buttons["Close shelf"].firstMatch.exists,
            "The collapsed hand tray should not render the legacy hand shelf."
        )
        attachScreenshot(named: "Unlucky Sevens - empty turn action well")
    }

    func testOpenMessagesExtensionAndCaptureFramelessShelfComparison() throws {
        openUnluckySevensExtension()
        openUXLabPanel()
        loadTabletopComparison(
            identifier: "uls.uxLab.cleanShot.tabletopFramelessShelf",
            label: "Frameless shelf comparison"
        )

        XCTAssertTrue(
            messages.buttons["Collapse hand"].firstMatch.waitForExistence(timeout: 6),
            "Expected the frameless comparison to keep the existing open hand shelf."
        )
        XCTAssertFalse(
            messages.descendants(matching: .any)
                .matching(identifier: "uls.feltTools.hand")
                .firstMatch
                .exists,
            "The frameless shelf comparison should not render the felt tool dock."
        )
        attachScreenshot(named: "Unlucky Sevens - frameless board with shelf")
    }

    func testOpenMessagesExtensionAndCaptureFeltToolsComparison() throws {
        openUnluckySevensExtension()
        openUXLabPanel()
        loadTabletopComparison(
            identifier: "uls.uxLab.cleanShot.tabletopFeltTools",
            label: "Felt tools comparison"
        )

        let handButton = turnElement(identifier: "uls.feltTools.hand", labels: ["Hand"])
        let handContents = turnElement(identifier: "uls.feltTools.handContents", labels: [])
        let bankRack = turnElement(identifier: "uls.tabletop.bankRack", labels: ["Bank"])
        let board = turnElement(identifier: "uls.tabletop.board", labels: [])
        XCTAssertTrue(
            handButton.waitForExistence(timeout: 6),
            "Expected the felt tools comparison to render a hand button."
        )
        XCTAssertTrue(
            handContents.waitForExistence(timeout: 4),
            "Expected the hand button to reveal hand components on the felt."
        )
        XCTAssertTrue(
            bankRack.waitForExistence(timeout: 4),
            "The bank rack should remain visible above the felt tool stage."
        )
        XCTAssertTrue(board.waitForExistence(timeout: 4), "Expected the felt-tools board frame to be measurable.")
        XCTAssertFalse(
            messages.buttons["Collapse hand"].firstMatch.exists,
            "The felt tools comparison should not render the cream shelf handle."
        )
        let stationaryHandButtonFrame = handButton.frame
        let stationaryBankRackFrame = bankRack.frame
        let stationaryBoardFrame = board.frame
        XCTAssertGreaterThanOrEqual(
            handContents.frame.minY,
            stationaryBankRackFrame.maxY,
            "Hand contents must open below the persistent bank rack."
        )

        handButton.tap()
        XCTAssertTrue(
            handContents.waitForNonExistence(timeout: 4),
            "Expected the hand button to hide the felt components."
        )
        assertFrame(
            of: handButton,
            matches: stationaryHandButtonFrame,
            message: "The felt toolbar must stay fixed when Hand closes."
        )
        assertFrame(
            of: bankRack,
            matches: stationaryBankRackFrame,
            message: "The bank rack must stay fixed when Hand closes."
        )
        assertFrame(of: board, matches: stationaryBoardFrame, message: "The board must stay fixed when Hand closes.")
        attachScreenshot(named: "Unlucky Sevens - felt tools compact dock")

        let buildButton = messages.buttons["Build"].firstMatch
        XCTAssertTrue(buildButton.waitForExistence(timeout: 4), "Expected the Build tool to be available.")
        buildButton.tap()
        let closeToolsButton = messages.buttons["Close tools"].firstMatch
        XCTAssertTrue(
            closeToolsButton.waitForExistence(timeout: 4),
            "Expected Build to bring a closable component surface into the felt area."
        )
        let roadButton = messages.buttons["Road"].firstMatch
        XCTAssertTrue(
            roadButton.waitForExistence(timeout: 4),
            "Expected the Build overlay to expose the Road component."
        )
        assertFrame(
            of: bankRack,
            matches: stationaryBankRackFrame,
            message: "The bank rack must stay fixed when Build opens."
        )
        assertFrame(of: board, matches: stationaryBoardFrame, message: "The board must stay fixed when Build opens.")
        XCTAssertGreaterThanOrEqual(
            roadButton.frame.minY,
            stationaryBankRackFrame.maxY,
            "Build controls must open below the persistent bank rack."
        )
        XCTAssertLessThanOrEqual(
            roadButton.frame.maxY,
            stationaryHandButtonFrame.minY + 4,
            "Build controls must open above the stationary toolbar."
        )
        assertFrame(
            of: handButton,
            matches: stationaryHandButtonFrame,
            message: "The felt toolbar must stay fixed when Build opens."
        )
        attachScreenshot(named: "Unlucky Sevens - felt build tools overlay")
        closeToolsButton.tap()
        handButton.tap()
        XCTAssertTrue(
            handContents.waitForExistence(timeout: 4),
            "Expected the hand components to be restored for the comparison capture."
        )
        assertFrame(
            of: bankRack,
            matches: stationaryBankRackFrame,
            message: "The bank rack must stay fixed when Hand reopens."
        )
        assertFrame(of: board, matches: stationaryBoardFrame, message: "The board must stay fixed when Hand reopens.")
        XCTAssertGreaterThanOrEqual(
            handContents.frame.minY,
            stationaryBankRackFrame.maxY,
            "Reopened Hand contents must remain below the bank rack."
        )
        assertFrame(
            of: handButton,
            matches: stationaryHandButtonFrame,
            message: "The felt toolbar must stay fixed when Hand reopens."
        )

        attachScreenshot(named: "Unlucky Sevens - frameless board with felt tools")

        handButton.tap()
        XCTAssertTrue(
            handContents.waitForNonExistence(timeout: 4),
            "Expected the felt tools test to finish in the compact state for direct simulator evidence capture."
        )
        assertFrame(of: board, matches: stationaryBoardFrame, message: "The board must stay fixed in compact mode.")
        assertFrame(
            of: bankRack,
            matches: stationaryBankRackFrame,
            message: "The bank rack must stay fixed in compact mode."
        )

        buildButton.tap()
        XCTAssertTrue(
            roadButton.waitForExistence(timeout: 4),
            "Expected the felt tools test to finish in Build-open mode for direct simulator evidence capture."
        )
        assertFrame(of: board, matches: stationaryBoardFrame, message: "The board must stay fixed in Build-open mode.")
        assertFrame(
            of: bankRack,
            matches: stationaryBankRackFrame,
            message: "The bank rack must stay fixed in Build-open mode."
        )
    }

    func testOpenMessagesExtensionAndCapturePhysicalPropsRoundFour() throws {
        openUnluckySevensExtension()
        openUXLabPanel()
        loadTabletopComparison(
            identifier: "uls.uxLab.cleanShot.tabletopPhysicalProps",
            label: "Physical props comparison"
        )

        let handButton = turnElement(identifier: "uls.feltTools.hand", labels: ["Hand"])
        let buildButton = turnElement(identifier: "uls.turnObject.build", labels: ["Build"])
        let actionSpread = turnElement(identifier: "uls.physicalProps.actionSpread", labels: [])
        let bankRack = turnElement(identifier: "uls.tabletop.bankRack", labels: ["Bank"])
        let developmentDeck = turnElement(
            identifier: "uls.tabletop.devDeck",
            labels: ["Dev Cards"]
        )
        let ownedDevCards = turnElement(
            identifier: "uls.physicalProps.ownedDevCards",
            labels: ["Owned Dev Cards"]
        )
        let board = turnElement(identifier: "uls.tabletop.board", labels: [])
        let boardHost = turnElement(identifier: "uls.tabletop.boardHost", labels: ["Live game board host"])
        let publicRail = turnElement(identifier: "uls.turn.publicRail", labels: [])
        let actionWell = turnElement(identifier: "uls.turn.actionWell", labels: ["Reserved turn action well"])

        XCTAssertTrue(handButton.waitForExistence(timeout: 8))
        XCTAssertTrue(buildButton.waitForExistence(timeout: 4))
        XCTAssertTrue(actionSpread.waitForExistence(timeout: 4))
        XCTAssertTrue(bankRack.waitForExistence(timeout: 4))
        XCTAssertTrue(developmentDeck.waitForExistence(timeout: 4))
        XCTAssertTrue(ownedDevCards.waitForExistence(timeout: 4))
        XCTAssertTrue(board.waitForExistence(timeout: 4))
        XCTAssertTrue(boardHost.waitForExistence(timeout: 4))
        XCTAssertTrue(publicRail.waitForExistence(timeout: 4))
        XCTAssertTrue(actionWell.waitForExistence(timeout: 4))
        XCTAssertGreaterThanOrEqual(handButton.frame.width, 44)
        XCTAssertGreaterThanOrEqual(handButton.frame.height, 44)
        XCTAssertGreaterThanOrEqual(buildButton.frame.width, 44)
        XCTAssertGreaterThanOrEqual(buildButton.frame.height, 44)

        let fixedBoardFrame = board.frame
        let fixedBoardHostValue = String(describing: boardHost.value)
        let fixedPublicRailFrame = publicRail.frame
        let fixedActionWellFrame = actionWell.frame
        let fixedHandFrame = handButton.frame
        let fixedBuildFrame = buildButton.frame
        assertElement(
            actionSpread,
            isContainedIn: fixedActionWellFrame,
            message: "The physical Hand spread must remain on the reserved felt."
        )
        XCTAssertFalse(
            turnElement(identifier: "uls.turnObject.devCards", labels: ["Dev"]).exists,
            "Owned Dev Cards must be nested inside Hand rather than occupying a rail anchor."
        )
        attachScreenshot(named: "Physical Props Round 4 - Default Hand")

        ownedDevCards.tap()
        let devChooser = turnElement(
            identifier: "uls.physicalProps.devChooser",
            labels: ["Playable Dev Cards"]
        )
        XCTAssertTrue(devChooser.waitForExistence(timeout: 4))
        assertFrame(of: board, matches: fixedBoardFrame, message: "Dev chooser must not resize the board.")
        assertFrame(of: publicRail, matches: fixedPublicRailFrame, message: "Dev chooser must not move the public rail.")
        XCTAssertEqual(String(describing: boardHost.value), fixedBoardHostValue)
        attachScreenshot(named: "Physical Props Round 4 - Dev Chooser")

        handButton.tap()
        XCTAssertTrue(ownedDevCards.waitForExistence(timeout: 4))

        buildButton.tap()
        XCTAssertTrue(buildButton.isSelected)
        assertElement(
            actionSpread,
            isContainedIn: fixedActionWellFrame,
            message: "The build props must remain on the reserved felt."
        )
        assertFrame(of: board, matches: fixedBoardFrame, message: "Build must not resize the board.")
        assertFrame(of: publicRail, matches: fixedPublicRailFrame, message: "Build must not move the public rail.")
        assertFrame(of: handButton, matches: fixedHandFrame, message: "Build must not rearrange Hand.")
        assertFrame(of: buildButton, matches: fixedBuildFrame, message: "Build must stay at its anchor.")
        XCTAssertEqual(String(describing: boardHost.value), fixedBoardHostValue)
        attachScreenshot(named: "Physical Props Round 4 - Build Spread")

        buildButton.tap()
        handButton.tap()
        XCTAssertTrue(actionSpread.waitForExistence(timeout: 4))
        let concealedBankValue = String(describing: bankRack.value)
        let concealedDevValue = String(describing: developmentDeck.value)
        bankRack.tap()
        XCTAssertTrue(
            waitForValueChange(of: bankRack, from: concealedBankValue, timeout: 4),
            "Expected tapping Bank to reveal exact counts in place."
        )
        XCTAssertTrue(
            waitForValueChange(of: developmentDeck, from: concealedDevValue, timeout: 4),
            "Expected tapping Bank to reveal the Dev Cards count in place."
        )
        XCTAssertNil(
            String(describing: bankRack.value).rangeOfCharacter(from: .decimalDigits),
            "Bank reveal must expose only qualitative H/M/L levels."
        )
        XCTAssertNil(
            String(describing: developmentDeck.value).rangeOfCharacter(from: .decimalDigits),
            "Dev Cards reveal must expose only a qualitative H/M/L level."
        )
        XCTAssertTrue(actionSpread.exists, "Bank reveal must leave Hand selected and visible.")
        XCTAssertTrue(handButton.isSelected, "Bank reveal must leave Hand selected.")
        assertFrame(of: board, matches: fixedBoardFrame, message: "Bank reveal must not resize the board.")
        assertFrame(of: publicRail, matches: fixedPublicRailFrame, message: "Bank reveal must not move the public rail.")
        assertFrame(of: handButton, matches: fixedHandFrame, message: "Bank reveal must not rearrange Hand.")
        assertFrame(of: buildButton, matches: fixedBuildFrame, message: "Bank reveal must not rearrange Build.")
        XCTAssertEqual(String(describing: boardHost.value), fixedBoardHostValue)
        attachScreenshot(named: "Physical Props Round 4 - Revealed Bank")
    }

    func testSettlePhysicalPropsDefaultHandForDirectStill() throws {
        openUnluckySevensExtension()
        openUXLabPanel()
        loadTabletopComparison(
            identifier: "uls.uxLab.cleanShot.tabletopPhysicalProps",
            label: "Physical props comparison"
        )

        let handButton = turnElement(identifier: "uls.feltTools.hand", labels: ["Hand"])
        XCTAssertTrue(handButton.waitForExistence(timeout: 8))
        XCTAssertTrue(handButton.isSelected)
        XCTAssertTrue(
            turnElement(identifier: "uls.physicalProps.actionSpread", labels: [])
                .waitForExistence(timeout: 4)
        )
    }

    func testSettlePhysicalPropsDevChooserForDirectStill() throws {
        openUnluckySevensExtension()
        openUXLabPanel()
        loadTabletopComparison(
            identifier: "uls.uxLab.cleanShot.tabletopPhysicalProps",
            label: "Physical props comparison"
        )

        let ownedDevCards = turnElement(
            identifier: "uls.physicalProps.ownedDevCards",
            labels: ["Owned Dev Cards"]
        )
        XCTAssertTrue(ownedDevCards.waitForExistence(timeout: 8))
        ownedDevCards.tap()
        XCTAssertTrue(
            turnElement(
                identifier: "uls.physicalProps.devChooser",
                labels: ["Playable Dev Cards"]
            ).waitForExistence(timeout: 4)
        )
        Thread.sleep(forTimeInterval: 2)
    }

    func testSettlePhysicalPropsBuildForDirectStill() throws {
        openUnluckySevensExtension()
        openUXLabPanel()
        loadTabletopComparison(
            identifier: "uls.uxLab.cleanShot.tabletopPhysicalProps",
            label: "Physical props comparison"
        )

        let buildButton = turnElement(identifier: "uls.turnObject.build", labels: ["Build"])
        XCTAssertTrue(buildButton.waitForExistence(timeout: 8))
        buildButton.tap()
        XCTAssertTrue(buildButton.isSelected)
        Thread.sleep(forTimeInterval: 10)
        attachScreenshot(named: "Physical Props Round 13 - Tall Build")
    }

    func testSettlePhysicalPropsOceanGlowForDirectStill() throws {
        settlePhysicalPropsOceanStyle(
            identifier: "uls.uxLab.oceanStyle.shallowGlow",
            label: "Glow",
            screenshotName: "Physical Props Ocean - Shallow Glow"
        )
    }

    func testSettlePhysicalPropsOceanDepthForDirectStill() throws {
        settlePhysicalPropsOceanStyle(
            identifier: "uls.uxLab.oceanStyle.verticalDepth",
            label: "Depth",
            screenshotName: "Physical Props Ocean - Vertical Depth"
        )
    }

    func testSettlePhysicalPropsOceanHaloForDirectStill() throws {
        settlePhysicalPropsOceanStyle(
            identifier: "uls.uxLab.oceanStyle.edgeVignette",
            labels: ["Halo", "Edge"],
            screenshotName: "Physical Props Ocean - Shoreline Halo"
        )
    }

    func testSettlePhysicalPropsBankForDirectStill() throws {
        openUnluckySevensExtension()
        openUXLabPanel()
        loadTabletopComparison(
            identifier: "uls.uxLab.cleanShot.tabletopPhysicalProps",
            label: "Physical props comparison"
        )

        let bankRack = turnElement(identifier: "uls.tabletop.bankRack", labels: ["Bank"])
        XCTAssertTrue(bankRack.waitForExistence(timeout: 8))
        let concealedValue = String(describing: bankRack.value)
        bankRack.tap()
        XCTAssertTrue(waitForValueChange(of: bankRack, from: concealedValue, timeout: 4))
    }

    private func settlePhysicalPropsOceanStyle(
        identifier: String,
        label: String? = nil,
        labels: [String]? = nil,
        screenshotName: String
    ) {
        openUnluckySevensExtension()
        openUXLabPanel()

        let styleButton = turnElement(
            identifier: identifier,
            labels: labels ?? label.map { [$0] } ?? []
        )
        XCTAssertTrue(styleButton.waitForExistence(timeout: 4))
        styleButton.tap()

        loadTabletopComparison(
            identifier: "uls.uxLab.cleanShot.tabletopPhysicalProps",
            label: "Physical props comparison"
        )

        let buildButton = turnElement(identifier: "uls.turnObject.build", labels: ["Build"])
        XCTAssertTrue(buildButton.waitForExistence(timeout: 8))
        buildButton.tap()
        XCTAssertTrue(buildButton.isSelected)
        Thread.sleep(forTimeInterval: 10)
        attachScreenshot(named: screenshotName)
    }

    private func openUnluckySevensExtension() {
        messages.launch()
        handleFirstRunPrompts()
        openExistingConversation()
        openMessagesAppDrawer()
        openUnluckySevensFromDrawer()
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

        let drawerButtons = [
            messages.buttons["add"].firstMatch,
            messages.buttons["Apps"].firstMatch,
            messages.buttons["More"].firstMatch,
            messages.buttons["App Store"].firstMatch,
        ]

        if let drawerButton = drawerButtons.first(where: { $0.waitForExistence(timeout: 1) }) {
            drawerButton.tap()
            return
        }

        messages.coordinate(withNormalizedOffset: CGVector(dx: 0.07, dy: 0.94)).tap()
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
        let toggle = waitForUXLabChrome()
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

    @discardableResult
    private func waitForUXLabChrome() -> XCUIElement {
        let toggle = firstExistingElement(
            [
                messages.buttons["uls.uxLab.toggle"].firstMatch,
                messages.buttons["Preview"].firstMatch,
                messages.buttons["UX Lab"].firstMatch,
            ],
            timeout: 8
        )
        XCTAssertTrue(toggle.exists, "Expected the UX Lab toggle to be visible.")
        return toggle
    }

    private func loadCleanSetupGameplaySlice() {
        activateUXLabQuickState(
            title: "Setup",
            identifier: "uls.uxLab.cleanShot.setupPlacement"
        )
    }

    private func loadStartTurnGameplaySlice() {
        activateUXLabQuickState(
            title: "Start",
            identifier: "uls.uxLab.cleanShot.turnNeedsRoll"
        )
    }

    private func loadTurnGameplaySlice() {
        activateUXLabQuickState(
            title: "Turn",
            identifier: "uls.uxLab.cleanShot.turnAfterRoll"
        )
    }

    private func loadNotPrimaryWaitingSlice() {
        activateUXLabQuickState(
            title: "Wait",
            identifier: "uls.uxLab.cleanShot.notPrimary.waiting"
        )
    }

    private func loadNotPrimaryOfferSlice() {
        activateUXLabQuickState(
            title: "Offer",
            identifier: "uls.uxLab.cleanShot.notPrimary.offer"
        )
    }

    private func loadNotPrimaryMultiTypeOfferSlice() {
        activateUXLabQuickState(
            title: "Multi Offer",
            identifier: "uls.uxLab.cleanShot.notPrimary.multiOffer"
        )
    }

    private func loadNotPrimaryDiscardWaitingSlice() {
        activateUXLabQuickState(
            title: "Discard Wait",
            identifier: "uls.uxLab.cleanShot.notPrimary.discard"
        )
    }

    private func loadActionableDiscardSlice() {
        openUXLabPanel()
        activateDirectCleanState(
            identifier: "uls.uxLab.cleanShot.pendingDiscard.direct",
            label: "Clean actionable discard"
        )
    }

    private func activateUXLabQuickState(title: String, identifier: String) {
        let directButton = messages.buttons[identifier].firstMatch
        if directButton.waitForExistence(timeout: 1) {
            directButton.tap()
            return
        }

        let menu = firstExistingElement(
            [
                messages.buttons["uls.uxLab.quickStates"].firstMatch,
                messages.buttons["States"].firstMatch,
            ],
            timeout: 4
        )
        XCTAssertTrue(menu.exists, "Expected the UX Lab state menu to be visible.")
        menu.tap()

        let menuItem = firstExistingElement(
            [
                messages.buttons[identifier].firstMatch,
                messages.buttons[title].firstMatch,
            ],
            timeout: 4
        )
        XCTAssertTrue(menuItem.exists, "Expected the UX Lab \(title) state to be available.")
        menuItem.tap()
    }

    private func activateUXLabNestedQuickState(title: String, identifier: String) {
        let menu = firstExistingElement(
            [
                messages.buttons["uls.uxLab.quickStates"].firstMatch,
                messages.buttons["States"].firstMatch,
            ],
            timeout: 4
        )
        XCTAssertTrue(menu.exists, "Expected the UX Lab state menu to be visible.")
        menu.tap()

        let lobbyMenu = firstExistingElement(
            [
                messages.buttons["uls.uxLab.lobbyStates"].firstMatch,
                messages.buttons["Lobby"].firstMatch,
                messages.descendants(matching: .any)["uls.uxLab.lobbyStates"].firstMatch,
                messages.descendants(matching: .any)["Lobby"].firstMatch,
            ],
            timeout: 4
        )
        XCTAssertTrue(lobbyMenu.exists, "Expected the UX Lab Lobby state group to be available.")
        lobbyMenu.tap()

        let menuItem = firstExistingElement(
            [
                messages.buttons[identifier].firstMatch,
                messages.buttons[title].firstMatch,
                messages.descendants(matching: .any)[identifier].firstMatch,
                messages.descendants(matching: .any)[title].firstMatch,
            ],
            timeout: 4
        )
        XCTAssertTrue(menuItem.exists, "Expected the UX Lab \(title) state to be available.")
        menuItem.tap()
    }

    private func openSettledTurnGameplaySlice() {
        openUnluckySevensExtension()
        waitForUXLabChrome()
        loadTurnGameplaySlice()
        XCTAssertTrue(
            turnElement(identifier: "uls.feltTools.hand", labels: ["Hand"])
                .waitForExistence(timeout: 8),
            "Expected the normal post-roll Turn Screen to settle."
        )
        collapseUXLabPanelIfExpanded()
    }

    private func loadTabletopComparison(identifier: String, label: String) {
        let button = firstExistingElement(
            [
                messages.buttons[identifier].firstMatch,
                messages.buttons[label].firstMatch,
            ],
            timeout: 4
        )

        XCTAssertTrue(button.exists, "Expected the UX Lab tabletop comparison button to be visible.")
        button.tap()
    }

    private func collapseUXLabPanelIfExpanded() {
        let toggle = firstExistingElement(
            [
                messages.buttons["uls.uxLab.toggle"].firstMatch,
                messages.buttons["UX Lab"].firstMatch,
                messages.buttons["Preview"].firstMatch,
            ],
            timeout: 2
        )

        if toggle.exists {
            toggle.tap()
        }
    }

    private func collapseHandTray() {
        let handle = firstExistingElement(
            [
                messages.buttons["uls.lowerRail.handle"].firstMatch,
                messages.buttons["Collapse hand"].firstMatch,
            ],
            timeout: 4
        )

        XCTAssertTrue(handle.exists, "Expected the hand tray collapse handle to be visible.")
        handle.tap()
    }

    private func attachScreenshot(named name: String) {
        // Messages embeds the extension through multiple compositing surfaces. A
        // screenshot taken in the first idle turn after a tray transition can
        // preserve frames while capturing those surfaces as black rectangles.
        // Give Core Animation one settled presentation interval before evidence.
        Thread.sleep(forTimeInterval: 1.0)
        let attachment = XCTAttachment(screenshot: messages.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func assertFrame(
        of element: XCUIElement,
        matches expectedFrame: CGRect,
        message: String
    ) {
        let actualFrame = element.frame
        XCTAssertEqual(actualFrame.midX, expectedFrame.midX, accuracy: 1, message)
        XCTAssertEqual(actualFrame.midY, expectedFrame.midY, accuracy: 1, message)
        XCTAssertEqual(actualFrame.width, expectedFrame.width, accuracy: 1, message)
        XCTAssertEqual(actualFrame.height, expectedFrame.height, accuracy: 1, message)
    }

    private func turnElement(
        identifier: String,
        labels: [String],
        timeout: TimeInterval = 4
    ) -> XCUIElement {
        var candidates: [XCUIElement] = []
        if !identifier.isEmpty {
            candidates.append(
                messages.descendants(matching: .any)
                    .matching(identifier: identifier)
                    .firstMatch
            )
        }

        for label in labels {
            candidates.append(messages.buttons[label].firstMatch)
            candidates.append(messages.otherElements[label].firstMatch)
            candidates.append(messages.staticTexts[label].firstMatch)
            candidates.append(
                messages.descendants(matching: .any)
                    .matching(NSPredicate(format: "label == %@", label))
                    .firstMatch
            )
        }

        precondition(!candidates.isEmpty)
        return firstExistingElement(candidates, timeout: timeout)
    }

    private func exactLabelElement(
        _ label: String,
        timeout: TimeInterval = 4
    ) -> XCUIElement {
        firstExistingElement(
            [
                messages.buttons[label].firstMatch,
                messages.otherElements[label].firstMatch,
                messages.staticTexts[label].firstMatch,
                messages.descendants(matching: .any)
                    .matching(NSPredicate(format: "label == %@", label))
                    .firstMatch,
            ],
            timeout: timeout
        )
    }

    private func unionFrame(of elements: [XCUIElement]) -> CGRect {
        elements.map(\.frame).reduce(CGRect.null) { result, frame in
            result.isNull ? frame : result.union(frame)
        }
    }

    private func assertElement(
        _ element: XCUIElement,
        isContainedIn container: CGRect,
        message: String
    ) {
        let compositorTolerance: CGFloat = 1.5
        let frame = element.frame
        XCTAssertGreaterThanOrEqual(frame.minX, container.minX - compositorTolerance, message)
        XCTAssertGreaterThanOrEqual(frame.minY, container.minY - compositorTolerance, message)
        XCTAssertLessThanOrEqual(frame.maxX, container.maxX + compositorTolerance, message)
        XCTAssertLessThanOrEqual(frame.maxY, container.maxY + compositorTolerance, message)
    }

    private func assertPersistentTurnGeometry(
        board: XCUIElement,
        boardFrame: CGRect,
        boardHost: XCUIElement,
        boardHostValue: String,
        bankRack: XCUIElement,
        bankRackFrame: CGRect,
        publicRail: XCUIElement,
        publicRailFrame: CGRect,
        status: XCUIElement,
        statusFrame: CGRect,
        turnObjects: [XCUIElement],
        turnObjectFrames: [CGRect],
        turnRailFrame: CGRect,
        route: String
    ) {
        assertFrame(of: board, matches: boardFrame, message: "Board moved on \(route).")
        XCTAssertEqual(
            String(describing: boardHost.value),
            boardHostValue,
            "The SpriteKit SKView remounted on \(route)."
        )
        assertFrame(of: bankRack, matches: bankRackFrame, message: "Bank moved on \(route).")
        assertFrame(of: publicRail, matches: publicRailFrame, message: "Public rail moved on \(route).")
        assertFrame(of: status, matches: statusFrame, message: "Top status moved on \(route).")
        if let expectedTurnActionWellFrame {
            let actionWell = turnElement(
                identifier: "uls.turn.actionWell",
                labels: ["Reserved turn action well"]
            )
            XCTAssertTrue(actionWell.exists, "Reserved action well disappeared on \(route).")
            assertFrame(
                of: actionWell,
                matches: expectedTurnActionWellFrame,
                message: "Reserved action well moved or resized on \(route)."
            )
        }
        XCTAssertEqual(turnObjects.count, turnObjectFrames.count)
        for (object, expectedFrame) in zip(turnObjects, turnObjectFrames) {
            assertFrame(of: object, matches: expectedFrame, message: "A turn-object anchor moved on \(route).")
        }
        assertFrame(
            of: turnObjects[0],
            matches: turnObjectFrames[0],
            message: "Turn rail was not measurable on \(route)."
        )
        let actualRailFrame = unionFrame(of: turnObjects)
        XCTAssertEqual(actualRailFrame.midX, turnRailFrame.midX, accuracy: 1, "Turn rail moved on \(route).")
        XCTAssertEqual(actualRailFrame.midY, turnRailFrame.midY, accuracy: 1, "Turn rail moved on \(route).")
        XCTAssertEqual(actualRailFrame.width, turnRailFrame.width, accuracy: 1, "Turn rail resized on \(route).")
        XCTAssertEqual(actualRailFrame.height, turnRailFrame.height, accuracy: 1, "Turn rail resized on \(route).")
    }

    private func waitForInviteSlice(timeout: TimeInterval) -> Bool {
        firstExistingElement(
            [
                messages.staticTexts["uls.lobby.inviteTitle"].firstMatch,
                messages.staticTexts["A table is open"].firstMatch,
            ],
            timeout: timeout
        )
        .exists
    }

    private func attachDiceRollFrame(index: Int) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = String(format: "Dice Roll Frame %02d", index)
        attachment.lifetime = .keepAlways
        add(attachment)
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

    private func waitForValueChange(
        of element: XCUIElement,
        from initialValue: String,
        timeout: TimeInterval
    ) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        repeat {
            if String(describing: element.value) != initialValue {
                return true
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        } while Date() < deadline
        return false
    }

    private func waitForDisappearance(
        of element: XCUIElement,
        timeout: TimeInterval
    ) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        repeat {
            if !element.exists {
                return true
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.05))
        } while Date() < deadline
        return !element.exists
    }

    private func waitForHittable(
        _ element: XCUIElement,
        timeout: TimeInterval
    ) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        repeat {
            if element.exists, element.isHittable {
                return true
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        } while Date() < deadline
        return element.exists && element.isHittable
    }
}
