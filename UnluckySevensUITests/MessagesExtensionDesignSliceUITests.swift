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

    func testCaptureInstalledMessagesDrawerIcon() throws {
        messages.launch()
        handleFirstRunPrompts()
        openExistingConversation()

        let drawerButton = firstExistingElement(
            [
                messages.buttons["add"].firstMatch,
                messages.buttons["Apps"].firstMatch,
                messages.buttons["More"].firstMatch,
                messages.buttons["App Store"].firstMatch,
            ],
            timeout: 4
        )
        XCTAssertTrue(drawerButton.exists, "Expected the Messages app drawer control.")
        drawerButton.tap()

        let appRow = messages.staticTexts["Unlucky Sevens"].firstMatch
        for _ in 0..<8 where !appRow.exists {
            messages.swipeUp()
        }
        XCTAssertTrue(appRow.waitForExistence(timeout: 4), "Expected the installed Unlucky Sevens drawer row.")
        attachScreenshot(named: "Approved Unlucky Sevens Messages drawer icon")
    }

    func testCaptureProductionLobbyEntryAndUtilities() throws {
        openUnluckySevensExtension()

        openUXLabPanel()
        activateUXLabNestedQuickState(
            title: "Invitation",
            identifier: "uls.uxLab.cleanShot.lobbyInvite"
        )
        XCTAssertTrue(waitForInviteSlice(timeout: 12))
        let games = messages.buttons["uls.lobby.games"].firstMatch
        XCTAssertTrue(games.exists)
        XCTAssertEqual(games.label, "Games")
        XCTAssertTrue(messages.buttons["uls.lobby.gameSettings"].firstMatch.exists)
        XCTAssertFalse(messages.staticTexts["Async turns"].firstMatch.exists)
        attachScreenshot(named: "Production Lobby - Invitation")

        messages.buttons["uls.lobby.gameSettings"].firstMatch.tap()
        XCTAssertTrue(messages.descendants(matching: .any)["uls.settings.surface"].firstMatch.waitForExistence(timeout: 4))
        XCTAssertTrue(messages.switches["uls.settings.skipAnimations"].firstMatch.exists)
        XCTAssertTrue(messages.staticTexts["Board"].firstMatch.exists)
        XCTAssertTrue(messages.staticTexts["Victory"].firstMatch.exists)
        messages.buttons["Done"].firstMatch.tap()

        openLobbyTutorial()
        dismissTutorialNavigationCoach()
        assertTutorialProgress(title: "Place Your First Settlement")
        messages.buttons["uls.tutorial.exit"].firstMatch.tap()
    }

    func testCaptureProductionLobbyLifecycle() throws {
        openUnluckySevensExtension()
        waitForUXLabChrome()
        activateUXLabNestedQuickState(
            title: "Invitation",
            identifier: "uls.uxLab.cleanShot.lobbyInvite"
        )

        XCTAssertTrue(waitForInviteSlice(timeout: 12))
        let inviteRoster = messages.descendants(matching: .any)["uls.lobby.roster"].firstMatch
        XCTAssertTrue(inviteRoster.exists)
        XCTAssertFalse(inviteRoster.staticTexts["1 player at the table"].firstMatch.exists)
        // XCUI reports the glyph bounds for plain SwiftUI text buttons rather than
        // their larger interaction frames. The utility test taps both controls
        // end-to-end; keep this lifecycle check focused on current hittability.
        XCTAssertTrue(messages.buttons["uls.lobby.games"].firstMatch.isHittable)
        XCTAssertTrue(messages.buttons["uls.lobby.gameSettings"].firstMatch.isHittable)
        let productionSendInvite = messages.buttons["uls.lobby.action.Send Invite"].firstMatch
        revealLobbyActionIfNeeded(productionSendInvite)
        assertVisibleLobbyAction(productionSendInvite, title: "Send Invite")
        attachScreenshot(named: "Lobby Lifecycle 01 - Send Invite")

        activateUXLabNestedQuickState(
            title: "Join",
            identifier: "uls.uxLab.cleanShot.lobbyJoin"
        )
        XCTAssertTrue(messages.buttons["uls.lobby.games"].firstMatch.waitForExistence(timeout: 4))
        XCTAssertTrue(messages.staticTexts["Join the Table"].firstMatch.waitForExistence(timeout: 8))
        let joinRoster = messages.descendants(matching: .any)["uls.lobby.roster"].firstMatch
        XCTAssertTrue(joinRoster.exists)
        XCTAssertFalse(joinRoster.staticTexts["1 player at the table"].firstMatch.exists)
        let joinGame = messages.buttons["uls.lobby.action.Join Game"].firstMatch
        revealLobbyActionIfNeeded(joinGame)
        assertVisibleLobbyAction(joinGame, title: "Join Game")
        attachScreenshot(named: "Lobby Lifecycle 02 - Join")

        restoreUXLabChrome()
        activateUXLabNestedQuickState(
            title: "Ready",
            identifier: "uls.uxLab.cleanShot.lobbyReady"
        )
        XCTAssertTrue(messages.buttons["uls.lobby.games"].firstMatch.waitForExistence(timeout: 4))
        XCTAssertTrue(messages.staticTexts["Ready to Start"].firstMatch.waitForExistence(timeout: 8))
        let readyRoster = messages.descendants(matching: .any)["uls.lobby.roster"].firstMatch
        XCTAssertTrue(readyRoster.exists)
        XCTAssertFalse(readyRoster.staticTexts["3 players at the table"].firstMatch.exists)
        let startGame = messages.buttons["uls.lobby.action.Start Game"].firstMatch
        revealLobbyActionIfNeeded(startGame)
        assertVisibleLobbyAction(startGame, title: "Start Game")
        attachScreenshot(named: "Lobby Lifecycle 03 - Ready")
    }

    func testCaptureLobbyJoinSettingsRulesPolish() throws {
        openUnluckySevensExtension()
        waitForUXLabChrome()
        activateUXLabNestedQuickState(
            title: "Invitation",
            identifier: "uls.uxLab.cleanShot.lobbyInvite"
        )

        XCTAssertTrue(waitForInviteSlice(timeout: 12))
        let games = messages.buttons["uls.lobby.games"].firstMatch
        assertMinimumTarget(games, message: "The direct lobby Games control must remain tappable.")
        let tutorial = messages.buttons["uls.lobby.tutorial"].firstMatch
        assertMinimumTarget(tutorial, message: "Tutorial must be a visible, tappable lobby option.")
        XCTAssertTrue(messages.staticTexts["Game Settings"].firstMatch.exists)
        XCTAssertTrue(messages.staticTexts["Playing as"].firstMatch.exists)
        let lobbySurface = messages.descendants(matching: .any)["uls.lobby.tableSurface"].firstMatch
        let sendInvite = messages.buttons["uls.lobby.action.Send Invite"].firstMatch
        assertVisibleLobbyAction(sendInvite, title: "Send Invite")
        XCTAssertLessThanOrEqual(
            lobbySurface.frame.maxY - sendInvite.frame.maxY,
            72,
            "Invite identity and action controls should finish at the bottom of the lobby canvas."
        )
        attachScreenshot(named: "Polish 01 - Lobby")

        games.tap()
        XCTAssertTrue(
            messages.descendants(matching: .any)["uls.games.library"]
                .firstMatch.waitForExistence(timeout: 4)
        )
        messages.buttons["Back"].firstMatch.tap()

        openLobbyTutorial()
        dismissTutorialNavigationCoach()
        assertTutorialProgress(title: "Place Your First Settlement")
        messages.buttons["uls.tutorial.exit"].firstMatch.tap()
        XCTAssertTrue(messages.buttons["uls.lobby.games"].firstMatch.waitForExistence(timeout: 4))

        activateUXLabNestedQuickState(
            title: "Join",
            identifier: "uls.uxLab.cleanShot.lobbyJoin"
        )
        XCTAssertTrue(messages.staticTexts["Playing as"].firstMatch.waitForExistence(timeout: 8))
        let nameField = messages.descendants(matching: .any)["uls.lobby.nameField"].firstMatch
        XCTAssertTrue(nameField.exists)
        let joinGame = messages.buttons["uls.lobby.action.Join Game"].firstMatch
        assertVisibleLobbyAction(joinGame, title: "Join Game")
        XCTAssertLessThanOrEqual(
            lobbySurface.frame.maxY - joinGame.frame.maxY,
            72,
            "Join identity and action controls should finish at the bottom of the lobby canvas."
        )
        attachScreenshot(named: "Polish 02 - Join")

        messages.buttons["uls.lobby.gameSettings"].firstMatch.tap()
        XCTAssertTrue(
            messages.descendants(matching: .any)["uls.settings.surface"]
                .firstMatch.waitForExistence(timeout: 4)
        )
        XCTAssertTrue(messages.buttons["uls.settings.showRules"].firstMatch.exists)
        XCTAssertTrue(messages.staticTexts["Skip animations"].firstMatch.exists)
        XCTAssertFalse(messages.staticTexts["Experience"].firstMatch.exists)
        XCTAssertFalse(messages.staticTexts["Help"].firstMatch.exists)
        XCTAssertFalse(
            messages.staticTexts["Show game changes immediately. Rules and dice results stay the same."]
                .firstMatch.exists
        )
        attachScreenshot(named: "Polish 03 - Settings")

        messages.buttons["uls.settings.showRules"].firstMatch.tap()
        XCTAssertTrue(
            messages.descendants(matching: .any)["uls.rules.surface"]
                .firstMatch.waitForExistence(timeout: 4)
        )
        let scrollCue = messages.buttons["Scroll for more"].firstMatch
        XCTAssertTrue(scrollCue.waitForExistence(timeout: 4))
        attachScreenshot(named: "Polish 04 - Rules")
        messages.descendants(matching: .any)["uls.rules.surface"].firstMatch.swipeUp()
        XCTAssertTrue(messages.staticTexts["Build costs"].firstMatch.exists)
        XCTAssertFalse(scrollCue.exists)
        attachScreenshot(named: "Polish 05 - Rules Scrolled")

        let strategy = messages.buttons["uls.rules.showStrategy"].firstMatch
        for _ in 0..<4 where !strategy.isHittable {
            messages.descendants(matching: .any)["uls.rules.surface"].firstMatch.swipeUp()
        }
        XCTAssertTrue(strategy.waitForExistence(timeout: 4))
        XCTAssertTrue(strategy.isHittable)
        strategy.tap()
        let closeStrategy = messages.buttons["uls.strategy.close"].firstMatch
        XCTAssertTrue(closeStrategy.waitForExistence(timeout: 4))
        XCTAssertTrue(messages.staticTexts["Strategy"].firstMatch.exists)
        XCTAssertFalse(
            messages.buttons["uls.rules.showStrategy"].firstMatch.isHittable,
            "The Rules destination must be inactive behind the focused Strategy card."
        )
        XCTAssertTrue(closeStrategy.isHittable)
        attachScreenshot(named: "Polish 06 - Standalone Strategy Card")
        closeStrategy.tap()
        XCTAssertTrue(
            messages.descendants(matching: .any)["uls.rules.surface"]
                .firstMatch.waitForExistence(timeout: 4)
        )
    }

    func testApprovedProductionJourneyUsesPhysicalPropsOnly() throws {
        openUnluckySevensExtension()
        waitForUXLabChrome()

        activateUXLabNestedQuickState(
            title: "Join",
            identifier: "uls.uxLab.cleanShot.lobbyJoin"
        )
        XCTAssertTrue(
            messages.buttons["uls.lobby.action.Join Game"].firstMatch
                .waitForExistence(timeout: 8)
        )

        restoreUXLabChrome()
        activateUXLabNestedQuickState(
            title: "Ready",
            identifier: "uls.uxLab.cleanShot.lobbyReady"
        )
        XCTAssertTrue(
            messages.buttons["uls.lobby.action.Start Game"].firstMatch
                .waitForExistence(timeout: 8)
        )

        restoreUXLabChrome()
        loadCleanSetupGameplaySlice()
        XCTAssertTrue(
            turnElement(identifier: "uls.setup.pieceRail", labels: [])
                .waitForExistence(timeout: 8)
        )
        assertNoRetiredGameplayShelf()

        restoreUXLabChrome()
        loadStartTurnGameplaySlice()
        XCTAssertTrue(
            turnElement(identifier: "uls.startTurn.surface", labels: ["Start of turn"])
                .waitForExistence(timeout: 8)
        )
        assertNoRetiredGameplayShelf()

        restoreUXLabChrome()
        loadTurnGameplaySlice()
        XCTAssertTrue(
            turnElement(identifier: "uls.physicalProps.hand", labels: ["Hand"])
                .waitForExistence(timeout: 8)
        )
        assertNoRetiredGameplayShelf()

        restoreUXLabChrome()
        loadActionableDiscardSlice()
        XCTAssertTrue(
            turnElement(identifier: "uls.discard.surface", labels: [])
                .waitForExistence(timeout: 8)
        )
        assertNoRetiredGameplayShelf()

        restoreUXLabChrome()
        loadTurnGameplaySlice()
        let settings = turnElement(identifier: "", labels: ["Settings"])
        XCTAssertTrue(settings.waitForExistence(timeout: 8))
        settings.tap()
        XCTAssertTrue(
            messages.descendants(matching: .any)["uls.settings.surface"]
                .firstMatch.waitForExistence(timeout: 4)
        )
        messages.buttons["Done"].firstMatch.tap()

        let gameInformation = turnElement(
            identifier: "",
            labels: ["Players and game information", "Game information"]
        )
        XCTAssertTrue(gameInformation.waitForExistence(timeout: 4))
        gameInformation.tap()
        let playerRecord = messages.buttons["uls.gameInfo.playerRecord"].firstMatch
        XCTAssertTrue(playerRecord.waitForExistence(timeout: 4))
        XCTAssertFalse(
            messages.buttons["uls.game.games"].firstMatch.exists,
            "Player Record must not consume a gameplay top-bar slot."
        )
        playerRecord.tap()
        XCTAssertFalse(
            messages.buttons["Open"].firstMatch.exists,
            "Player Record must not expose saved-game continuation."
        )
        XCTAssertTrue(messages.descendants(matching: .any)["uls.playerRecord"].firstMatch.exists)
        messages.buttons["Back"].firstMatch.tap()

        restoreUXLabChrome()
        loadRecoveryGamesSlice()
        XCTAssertTrue(waitForGamesEntryPoint(), "Expected Games to remain reachable from the current surface.")

        loadEndScreenSlice()
        XCTAssertTrue(
            turnElement(identifier: "uls.endScreen", labels: [])
                .waitForExistence(timeout: 8)
        )
        assertNoRetiredGameplayShelf()
    }

    func testCaptureProductionLobbyAccessibilityLayout() throws {
        openUnluckySevensExtension()
        hideUXLabChromeWithoutChangingFixture()

        XCTAssertTrue(waitForInviteSlice(timeout: 12))
        XCTAssertTrue(
            messages.descendants(matching: .any)["uls.lobby.roster"].firstMatch.exists
        )
        XCTAssertTrue(messages.buttons["uls.lobby.games"].firstMatch.isHittable)
        XCTAssertTrue(messages.buttons["uls.lobby.gameSettings"].firstMatch.isHittable)

        let sendInvite = messages.buttons["uls.lobby.action.Send Invite"].firstMatch
        revealLobbyActionIfNeeded(sendInvite)
        assertVisibleLobbyAction(sendInvite, title: "Send Invite")
        attachScreenshot(named: "Lobby Accessibility - Send Invite")

        openLobbyTutorial()
        dismissTutorialNavigationCoach()
        assertTutorialProgress(title: "Place Your First Settlement")
        let accessibleGuide = messages.descendants(matching: .any)[
            "uls.tutorial.accessibleGuide"
        ].firstMatch
        XCTAssertTrue(
            accessibleGuide.waitForExistence(timeout: 4),
            "An accessibility content-size category must use the ordered tutorial guide."
        )
        XCTAssertFalse(
            messages.descendants(matching: .any)
                .matching(identifier: "uls.tutorial.callout")
                .firstMatch.exists,
            "Accessibility sizes must replace spatial coach cards with the ordered guide."
        )
        XCTAssertTrue(
            messages.staticTexts[
                "Everyone places a settlement and road twice. Round two goes in reverse order."
            ].firstMatch.exists
        )
        XCTAssertTrue(
            messages.staticTexts[
                "First, place a settlement on a glowing corner."
            ].firstMatch.exists
        )
        assertElement(
            accessibleGuide,
            isContainedIn: messages.frame,
            message: "The accessibility tutorial guide must stay inside the Messages host."
        )
        attachScreenshot(named: "Tutorial Accessibility - Ordered Guide")

        messages.buttons["uls.tutorial.exit"].firstMatch.tap()
        XCTAssertTrue(messages.buttons["uls.lobby.games"].firstMatch.waitForExistence(timeout: 4))
        restoreUXLabChrome()
        loadEndScreenSlice()
        let endScreen = turnElement(identifier: "uls.endScreen", labels: [])
        let newGame = messages.buttons["uls.endScreen.newGame"].firstMatch
        XCTAssertTrue(endScreen.waitForExistence(timeout: 8))
        XCTAssertTrue(newGame.waitForExistence(timeout: 4))
        assertElement(
            endScreen,
            isContainedIn: messages.frame,
            message: "The accessibility-size terminal surface must stay inside the Messages host."
        )
        assertMinimumTarget(
            newGame,
            message: "New Game must remain a full-size target at accessibility sizes."
        )
        attachScreenshot(named: "End Screen Accessibility - Final Scores")
    }

    func testCaptureSettingsRulesTutorialCheckpoint() throws {
        openUnluckySevensExtension()
        openUXLabPanel()
        activateUXLabNestedQuickState(
            title: "Invitation",
            identifier: "uls.uxLab.cleanShot.lobbyInvite"
        )
        XCTAssertTrue(waitForInviteSlice(timeout: 12))

        messages.buttons["uls.lobby.gameSettings"].firstMatch.tap()
        XCTAssertTrue(messages.descendants(matching: .any)["uls.settings.surface"].firstMatch.waitForExistence(timeout: 4))
        XCTAssertTrue(messages.switches["uls.settings.skipAnimations"].firstMatch.exists)
        XCTAssertTrue(messages.buttons["uls.settings.showRules"].firstMatch.exists)
        attachScreenshot(named: "Settings Rules Tutorial - Settings")

        messages.buttons["uls.settings.showRules"].firstMatch.tap()
        XCTAssertTrue(messages.descendants(matching: .any)["uls.rules.surface"].firstMatch.waitForExistence(timeout: 4))
        let scrollCue = messages.staticTexts["Scroll for more"].firstMatch
        XCTAssertTrue(scrollCue.waitForExistence(timeout: 4))
        messages.descendants(matching: .any)["uls.rules.surface"].firstMatch.swipeUp()
        XCTAssertTrue(messages.staticTexts["Build costs"].firstMatch.exists)
        attachScreenshot(named: "Settings Rules Tutorial - Rules")
        messages.navigationBars["Rules"].buttons.firstMatch.tap()
        XCTAssertTrue(messages.descendants(matching: .any)["uls.settings.surface"].firstMatch.waitForExistence(timeout: 4))
        messages.buttons["Done"].firstMatch.tap()

        openLobbyTutorial()
        dismissTutorialNavigationCoach()
        assertTutorialProgress(title: "Place Your First Settlement")

        for _ in 0..<7 {
            messages.buttons["uls.tutorial.next"].firstMatch.tap()
        }
        assertTutorialProgress(title: "Trade")
        attachScreenshot(named: "Settings Rules Tutorial - Player Trade")

        for _ in 0..<8 {
            messages.buttons["uls.tutorial.next"].firstMatch.tap()
        }
        assertTutorialProgress(title: "Strategy")
        XCTAssertTrue(messages.buttons["uls.tutorial.done"].firstMatch.exists)
        attachScreenshot(named: "Settings Rules Tutorial - Strategy")
        messages.buttons["uls.tutorial.done"].firstMatch.tap()
        XCTAssertTrue(messages.buttons["uls.lobby.games"].firstMatch.waitForExistence(timeout: 4))
    }

    func testPlaceTutorialTradeCheckpoint() throws {
        openUnluckySevensExtension()

        openLobbyTutorial()

        dismissTutorialNavigationCoach()

        let next = messages.buttons["uls.tutorial.next"].firstMatch
        XCTAssertTrue(next.waitForExistence(timeout: 4))
        for _ in 0..<7 {
            next.tap()
        }
        assertTutorialProgress(title: "Trade")
    }

    func testCapturePhysicalTradeCorrectionTutorialCheckpoint() throws {
        openUnluckySevensExtension()
        let restoreChrome = messages.buttons["uls.uxLab.restoreChrome"].firstMatch
        if restoreChrome.waitForExistence(timeout: 2) {
            restoreChrome.tap()
        }
        openUXLabPanel()
        activateUXLabNestedQuickState(
            title: "Invitation",
            identifier: "uls.uxLab.cleanShot.lobbyInvite"
        )
        XCTAssertTrue(waitForInviteSlice(timeout: 12))

        openLobbyTutorial()
        dismissTutorialNavigationCoach()

        let next = messages.buttons["uls.tutorial.next"].firstMatch
        XCTAssertTrue(next.waitForExistence(timeout: 4))
        for _ in 0..<7 {
            next.tap()
        }

        assertTutorialProgress(title: "Trade")
        assertMinimumTarget(
            messages.buttons["Exit tutorial"].firstMatch,
            message: "The trade tutorial close control must preserve a 44-point target."
        )
        let tutorialBoard = turnElement(identifier: "uls.tabletop.board", labels: [])
        let tutorialBoardHost = turnElement(
            identifier: "uls.tabletop.boardHost",
            labels: ["Live game board host"]
        )
        let tutorialHand = turnElement(identifier: "uls.physicalProps.hand", labels: ["Hand"])
        XCTAssertTrue(tutorialBoard.waitForExistence(timeout: 4))
        XCTAssertTrue(tutorialBoardHost.waitForExistence(timeout: 4))
        XCTAssertTrue(tutorialHand.waitForExistence(timeout: 4))
        // The production shell applies its island-centering correction from a
        // global-frame preference on the next presentation update.
        Thread.sleep(forTimeInterval: 1)
        let tutorialBoardFrame = tutorialBoard.frame
        let tutorialBoardHostFrame = tutorialBoardHost.frame
        let tutorialHandFrame = tutorialHand.frame
        let safeFrame = messages.windows.firstMatch.frame
        assertElement(
            tutorialBoard,
            isContainedIn: safeFrame,
            message: "The tutorial must keep the production board inside the device frame."
        )
        assertElement(
            tutorialHand,
            isContainedIn: safeFrame,
            message: "The tutorial must keep Hand inside the device frame."
        )
        XCTAssertFalse(messages.staticTexts["8 / 17"].exists)
        XCTAssertFalse(messages.staticTexts["Choose Give"].exists)
        let tutorialGiveWood = messages.buttons["Add Wood to Give"].firstMatch
        let tutorialGetBrick = messages.buttons["Add Brick to Get"].firstMatch
        XCTAssertTrue(tutorialGiveWood.waitForExistence(timeout: 4))
        XCTAssertTrue(tutorialGetBrick.waitForExistence(timeout: 4))
        XCTAssertEqual(tutorialGiveWood.value as? String, "2 selected, 5 available")
        XCTAssertEqual(tutorialGetBrick.value as? String, "1 selected, 19 available")
        attachScreenshot(named: "Tutorial Trade - Player Give Get")

        next.tap()
        assertTutorialProgress(title: "Trade")
        assertFrame(
            of: tutorialBoard,
            matches: tutorialBoardFrame,
            message: "Recipient selection must preserve the tutorial board frame."
        )
        assertFrame(
            of: tutorialHand,
            matches: tutorialHandFrame,
            message: "Recipient selection must preserve the tutorial Hand frame."
        )
        XCTAssertFalse(messages.staticTexts["9 / 17"].exists)
        XCTAssertFalse(messages.staticTexts["Choose players"].exists)
        let tutorialMaya = messages.buttons["Maya"].firstMatch
        let tutorialTheo = messages.buttons["Theo"].firstMatch
        let tutorialSendOffer = messages.buttons["Send Offer"].firstMatch
        XCTAssertTrue(tutorialMaya.waitForExistence(timeout: 4))
        XCTAssertTrue(tutorialTheo.waitForExistence(timeout: 4))
        XCTAssertTrue(waitForHittable(tutorialSendOffer, timeout: 4))
        XCTAssertTrue(tutorialMaya.isSelected)
        XCTAssertFalse(tutorialTheo.isSelected)
        attachScreenshot(named: "Tutorial Trade - Recipient Selection")

        next.tap()
        assertTutorialProgress(title: "Trade")
        assertFrame(
            of: tutorialBoard,
            matches: tutorialBoardFrame,
            message: "Maritime trade must preserve the tutorial board frame."
        )
        assertFrame(
            of: tutorialHand,
            matches: tutorialHandFrame,
            message: "Maritime trade must preserve the tutorial Hand frame."
        )
        XCTAssertFalse(messages.staticTexts["10 / 17"].exists)
        XCTAssertFalse(messages.staticTexts["Ports cut cost"].exists)
        XCTAssertFalse(messages.staticTexts["Swipe trades"].exists)
        XCTAssertFalse(messages.staticTexts["Swipe for other legal trades"].exists)
        let tutorialMaritimeHand = turnElement(
            identifier: "uls.physicalTrade.maritimeHandSpread",
            labels: []
        )
        let tutorialMaritimePosition = turnElement(
            identifier: "uls.physicalTrade.maritimePosition",
            labels: []
        )
        XCTAssertTrue(
            tutorialMaritimeHand.waitForExistence(timeout: 4),
            "Maritime trade must retain the normal-turn resource hand."
        )
        XCTAssertTrue(
            tutorialMaritimePosition.waitForExistence(timeout: 4),
            "Multiple maritime exchanges must expose their current position."
        )
        let tutorialFirstExchange = messages.descendants(matching: .any).matching(
            NSPredicate(format: "label BEGINSWITH %@", "Give ")
        ).firstMatch
        let tutorialConfirmMaritime = messages.buttons["Confirm Trade"].firstMatch
        XCTAssertTrue(tutorialFirstExchange.waitForExistence(timeout: 4))
        XCTAssertTrue(tutorialConfirmMaritime.waitForExistence(timeout: 4))
        XCTAssertEqual(
            tutorialFirstExchange.label,
            "Give 3 Wood for 1 Brick, 3 to 1 trade"
        )
        XCTAssertEqual(
            tutorialConfirmMaritime.value as? String,
            tutorialFirstExchange.label
        )
        assertElement(
            tutorialMaritimeHand,
            isContainedIn: safeFrame,
            message: "The maritime resource hand must stay on screen without clipping."
        )
        assertElement(
            tutorialMaritimePosition,
            isContainedIn: safeFrame,
            message: "The maritime exchange position must stay on screen without clipping."
        )
        let tutorialMaritimeHandFrame = tutorialMaritimeHand.frame
        attachScreenshot(named: "Tutorial Trade - Maritime Exchange")

        for _ in 0..<7 {
            guard next.waitForExistence(timeout: 2) else { break }
            next.tap()
        }
        let done = messages.buttons["uls.tutorial.done"].firstMatch
        XCTAssertTrue(done.waitForExistence(timeout: 4))
        done.tap()
        restoreUXLabChrome()
        loadTurnGameplaySlice()
        let productionBoard = turnElement(identifier: "uls.tabletop.board", labels: [])
        let productionBoardHost = turnElement(
            identifier: "uls.tabletop.boardHost",
            labels: ["Live game board host"]
        )
        let productionHand = turnElement(identifier: "uls.physicalProps.hand", labels: ["Hand"])
        let productionHandSpread = turnElement(
            identifier: "uls.physicalProps.actionSpread",
            labels: []
        )
        XCTAssertTrue(productionBoard.waitForExistence(timeout: 4))
        XCTAssertTrue(productionBoardHost.waitForExistence(timeout: 4))
        XCTAssertTrue(productionHand.waitForExistence(timeout: 4))
        if !productionHandSpread.waitForExistence(timeout: 1), !productionHand.isSelected {
            productionHand.tap()
        }
        XCTAssertTrue(productionHandSpread.waitForExistence(timeout: 4))
        Thread.sleep(forTimeInterval: 1)
        XCTAssertFalse(
            messages.descendants(matching: .any)
                .matching(identifier: "uls.tutorial.callout")
                .firstMatch.exists,
            "Tutorial callouts must be removed before production gameplay resumes."
        )
        XCTAssertFalse(
            messages.descendants(matching: .any)["uls.tutorial.progress"]
                .firstMatch.exists,
            "Tutorial progress must be removed before production gameplay resumes."
        )
        assertFrame(
            of: productionBoardHost,
            matches: tutorialBoardHostFrame,
            message: "The tutorial SpriteKit board host must use the production frame."
        )
        assertFrame(
            of: productionBoard,
            matches: tutorialBoardFrame,
            message: "The tutorial board must use the production Physical Props frame."
        )
        assertFrame(
            of: productionHand,
            matches: tutorialHandFrame,
            message: "The tutorial Hand must use the production Physical Props frame."
        )
        assertFrame(
            of: productionHandSpread,
            matches: tutorialMaritimeHandFrame,
            message: "The maritime resource hand must use the normal-turn Physical Props frame."
        )
    }

    func testPhysicalTradeCorrectionProductionGeometry() throws {
        openUnluckySevensExtension()
        loadTurnGameplaySlice()

        let board = turnElement(identifier: "uls.tabletop.board", labels: [])
        let trade = turnElement(identifier: "uls.turnObject.trade", labels: ["Trade"])
        XCTAssertTrue(board.waitForExistence(timeout: 4))
        XCTAssertTrue(trade.waitForExistence(timeout: 4))
        let normalHandSpread = turnElement(
            identifier: "uls.physicalProps.actionSpread",
            labels: []
        )
        if !normalHandSpread.waitForExistence(timeout: 1) {
            let hand = turnElement(identifier: "uls.physicalProps.hand", labels: ["Hand"])
            if !hand.isSelected {
                hand.tap()
            }
        }
        XCTAssertTrue(normalHandSpread.waitForExistence(timeout: 4))
        let fixedBoardFrame = board.frame
        let normalHandSpreadFrame = normalHandSpread.frame
        let safeFrame = messages.windows.firstMatch.frame

        trade.tap()
        let playerTrade = messages.buttons["Player Trade"].firstMatch
        XCTAssertTrue(playerTrade.waitForExistence(timeout: 4))
        playerTrade.tap()

        let giveWood = messages.buttons["Add Wood to Give"].firstMatch
        let getBrick = messages.buttons["Add Brick to Get"].firstMatch
        let composerClose = messages.buttons["Close trade"].firstMatch
        let chooseRecipients = messages.buttons["Choose Players"].firstMatch

        assertMinimumTarget(giveWood, message: "Give resource cards must preserve 44-point targets.")
        assertMinimumTarget(getBrick, message: "Get resource cards must preserve 44-point targets.")
        assertMinimumTarget(composerClose, message: "Composer Close must preserve a 44-point target.")
        assertMinimumTarget(chooseRecipients, message: "Choose Players must preserve a 44-point target.")
        for control in [giveWood, getBrick, composerClose, chooseRecipients] {
            assertElement(control, isContainedIn: safeFrame, message: "Every Give/Get control must stay on screen without clipping.")
        }

        giveWood.tap()
        XCTAssertEqual(giveWood.value as? String, "1 selected, 5 available")
        giveWood.tap()
        XCTAssertEqual(giveWood.value as? String, "2 selected, 5 available")
        getBrick.tap()
        XCTAssertEqual(getBrick.value as? String, "1 selected, 19 available")
        let giveRemove = messages.buttons["uls.physicalTrade.give.wood.remove"].firstMatch
        let getRemove = messages.buttons["uls.physicalTrade.get.brick.remove"].firstMatch
        assertMinimumTarget(giveRemove, message: "Selected Give cards must expose a 44-point decrement target.")
        assertMinimumTarget(getRemove, message: "Selected Get cards must expose a 44-point decrement target.")
        assertElement(giveRemove, isContainedIn: safeFrame, message: "The Give decrement control must stay on screen without clipping.")
        assertElement(getRemove, isContainedIn: safeFrame, message: "The Get decrement control must stay on screen without clipping.")
        XCTAssertEqual(giveWood.value as? String, "2 selected, 5 available")
        XCTAssertEqual(getBrick.value as? String, "1 selected, 19 available")
        XCTAssertEqual(giveRemove.value as? String, "2 selected")
        XCTAssertEqual(getRemove.value as? String, "1 selected")
        giveRemove.tap()
        XCTAssertEqual(giveWood.value as? String, "1 selected, 5 available")
        XCTAssertEqual(giveRemove.value as? String, "1 selected")
        giveWood.tap()
        XCTAssertEqual(giveWood.value as? String, "2 selected, 5 available")
        XCTAssertEqual(giveRemove.value as? String, "2 selected")
        assertFrame(of: board, matches: fixedBoardFrame, message: "Give/Get composition must not move the board.")

        chooseRecipients.tap()
        let maya = messages.buttons["Maya"].firstMatch
        let theo = messages.buttons["Theo"].firstMatch
        let recipientClose = messages.buttons.matching(
            NSPredicate(format: "label == %@", "Close trade")
        ).element(boundBy: 1)
        let recipientCancel = messages.buttons["Cancel"].firstMatch
        let sendOffer = messages.buttons["Send Offer"].firstMatch
        assertMinimumTarget(maya, message: "Recipient rows must preserve 44-point targets.")
        assertMinimumTarget(theo, message: "Recipient rows must preserve 44-point targets.")
        assertMinimumTarget(recipientClose, message: "Recipient Close must preserve a 44-point target.")
        assertMinimumTarget(recipientCancel, message: "Recipient Cancel must preserve a 44-point target.")
        assertMinimumTarget(sendOffer, message: "Send Offer must preserve a 44-point target.")
        maya.tap()
        XCTAssertTrue(maya.isSelected)
        XCTAssertFalse(theo.isSelected)
        for control in [maya, theo, recipientClose, recipientCancel, sendOffer] {
            assertElement(control, isContainedIn: safeFrame, message: "Every recipient overlay control must stay on screen without clipping.")
        }
        assertFrame(of: board, matches: fixedBoardFrame, message: "Recipient selection must not move the board.")

        recipientCancel.tap()
        XCTAssertTrue(trade.waitForExistence(timeout: 4))
        trade.tap()
        let maritime = messages.buttons["Bank or Port"].firstMatch
        XCTAssertTrue(maritime.waitForExistence(timeout: 4))
        maritime.tap()

        let firstExchange = messages.descendants(matching: .any).matching(
            NSPredicate(format: "label BEGINSWITH %@", "Give ")
        ).firstMatch
        let confirmMaritime = messages.buttons["Confirm Trade"].firstMatch
        let maritimeClose = messages.buttons["Close trade"].firstMatch
        let maritimeHandSpread = turnElement(
            identifier: "uls.physicalTrade.maritimeHandSpread",
            labels: []
        )
        let maritimePosition = turnElement(
            identifier: "uls.physicalTrade.maritimePosition",
            labels: []
        )
        let previousMaritime = messages.buttons["Previous exchange"].firstMatch
        let nextMaritime = messages.buttons["Next exchange"].firstMatch
        XCTAssertTrue(firstExchange.waitForExistence(timeout: 4))
        XCTAssertTrue(confirmMaritime.waitForExistence(timeout: 4))
        XCTAssertTrue(maritimeHandSpread.waitForExistence(timeout: 4))
        XCTAssertTrue(maritimePosition.waitForExistence(timeout: 4))
        assertMinimumTarget(maritimeClose, message: "Maritime Close must preserve a 44-point target.")
        assertMinimumTarget(confirmMaritime, message: "Confirm Trade must preserve a 44-point target.")
        assertMinimumTarget(previousMaritime, message: "Previous exchange must preserve a 44-point target.")
        assertMinimumTarget(nextMaritime, message: "Next exchange must preserve a 44-point target.")
        assertElement(maritimeClose, isContainedIn: safeFrame, message: "Maritime Close must stay on screen without clipping.")
        assertElement(firstExchange, isContainedIn: safeFrame, message: "The visible maritime exchange must not clip horizontally or vertically.")
        assertElement(confirmMaritime, isContainedIn: safeFrame, message: "Confirm Trade must stay on screen without clipping.")
        assertElement(maritimeHandSpread, isContainedIn: safeFrame, message: "The normal-turn Hand must remain visible without clipping.")
        assertElement(maritimePosition, isContainedIn: safeFrame, message: "The maritime exchange position must remain visible without clipping.")
        assertElement(previousMaritime, isContainedIn: safeFrame, message: "Previous exchange must remain visible without clipping.")
        assertElement(nextMaritime, isContainedIn: safeFrame, message: "Next exchange must remain visible without clipping.")
        XCTAssertTrue(firstExchange.label.contains("Give"))
        XCTAssertTrue(firstExchange.label.contains("for"))
        XCTAssertEqual(confirmMaritime.value as? String, firstExchange.label)
        XCTAssertFalse(previousMaritime.isEnabled)
        XCTAssertTrue(nextMaritime.isEnabled)
        let firstConfirmedExchange = String(describing: confirmMaritime.value)
        nextMaritime.tap()
        XCTAssertTrue(
            waitForValueChange(
                of: confirmMaritime,
                from: firstConfirmedExchange,
                timeout: 4
            ),
            "Paging forward must update the exchange confirmed by the production action."
        )
        XCTAssertTrue(previousMaritime.isEnabled)
        XCTAssertEqual(maritimePosition.label, "Exchange 2 of 20")
        assertFrame(
            of: maritimeHandSpread,
            matches: normalHandSpreadFrame,
            message: "Maritime trade must preserve the normal-turn Hand frame."
        )
        assertFrame(of: board, matches: fixedBoardFrame, message: "Maritime paging must not move the board.")
    }

    func testPhysicalTradeCorrectionLiveRoutes() throws {
        openUnluckySevensExtension()
        waitForUXLabChrome()
        activateUXLabQuickState(
            title: "Pending",
            identifier: "uls.uxLab.cleanShot.pendingTrade"
        )

        let pendingTrade = turnElement(identifier: "uls.turnObject.trade", labels: ["Trade"])
        XCTAssertTrue(pendingTrade.waitForExistence(timeout: 8))
        pendingTrade.tap()

        let pendingSurface = turnElement(identifier: "uls.turn.tradeSurface", labels: [])
        let replaceOffer = messages.buttons["Replace Offer"].firstMatch
        XCTAssertTrue(pendingSurface.waitForExistence(timeout: 4))
        assertMinimumTarget(
            replaceOffer,
            message: "The production pending route must retain a 44-point Replace Offer target."
        )

        restoreUXLabChrome()
        loadNotPrimaryOfferSlice()
        let incomingTrade = turnElement(identifier: "uls.turnObject.trade", labels: ["Trade"])
        XCTAssertTrue(incomingTrade.waitForExistence(timeout: 8))
        incomingTrade.tap()

        let incomingSurface = turnElement(identifier: "uls.turn.tradeSurface", labels: [])
        let counter = messages.buttons["Counter"].firstMatch
        XCTAssertTrue(incomingSurface.waitForExistence(timeout: 4))
        assertMinimumTarget(
            messages.buttons["Accept"].firstMatch,
            message: "The production incoming route must retain a 44-point Accept target."
        )
        assertMinimumTarget(
            messages.buttons["Decline"].firstMatch,
            message: "The production incoming route must retain a 44-point Decline target."
        )
        assertMinimumTarget(
            counter,
            message: "The production incoming route must retain a 44-point Counter target."
        )

        counter.tap()
        XCTAssertTrue(
            messages.staticTexts["Counter Trade"].firstMatch.waitForExistence(timeout: 4),
            "Counter must enter the same production Give/Get composer."
        )
        assertMinimumTarget(
            messages.buttons["Add Wood to Give"].firstMatch,
            message: "Counter must reuse the production Give card controls."
        )

        messages.buttons["Close trade"].firstMatch.tap()
        restoreUXLabChrome()
    }

    func testPlaceTutorialFirstTapZonesCheckpoint() throws {
        openUnluckySevensExtension()

        openLobbyTutorial()

        let startPrompt = messages.staticTexts["Tap anywhere to begin"].firstMatch
        XCTAssertTrue(startPrompt.waitForExistence(timeout: 4))
        XCTAssertTrue(messages.staticTexts["Tap left"].firstMatch.exists)
        XCTAssertTrue(messages.staticTexts["Tap right"].firstMatch.exists)
        dismissTutorialNavigationCoach()
        XCTAssertTrue(startPrompt.waitForNonExistence(timeout: 4))
        XCTAssertFalse(messages.staticTexts["1 / 16"].firstMatch.exists)
        assertTutorialProgress(title: "Place Your First Settlement")
    }

    func testCaptureEveryTutorialScreen() throws {
        openUnluckySevensExtension()
        waitForUXLabChrome()
        activateUXLabNestedQuickState(
            title: "Invitation",
            identifier: "uls.uxLab.cleanShot.lobbyInvite"
        )

        openLobbyTutorial()

        let startPrompt = messages.staticTexts["Tap anywhere to begin"].firstMatch
        XCTAssertTrue(startPrompt.waitForExistence(timeout: 4))
        attachScreenshot(named: "Tutorial 00 - Navigation")
        messages.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        XCTAssertTrue(startPrompt.waitForNonExistence(timeout: 4))

        let titles = [
            "Place Your First Settlement",
            "Add a Road",
            "Roll to Begin",
            "Follow the Roll",
            "Check Your Hand",
            "Choose What to Build",
            "Choose a Glowing Corner",
            "Make an Offer",
            "Choose Who Gets It",
            "Trade with Bank or Port",
            "Discard on Seven",
            "Move the Robber",
            "Choose a Victim",
            "Play a Dev Card",
            "Send the Turn",
            "Strategy",
        ]

        for (index, title) in titles.enumerated() {
            let progress = messages.descendants(matching: .any)["uls.tutorial.progress"].firstMatch
            let expectedTitle = (7...9).contains(index) ? "Trade" : title
            XCTAssertTrue(
                progress.waitForExistence(timeout: 4),
                "Expected visible tutorial progress for step \(index + 1)."
            )
            XCTAssertEqual(progress.label, expectedTitle)
            let callouts = messages.descendants(matching: .any)
                .matching(identifier: "uls.tutorial.callout")
            let expectedMinimumCalloutCount = index == titles.count - 1 ? 0 : 1
            XCTAssertGreaterThanOrEqual(
                callouts.count,
                expectedMinimumCalloutCount,
                "Expected the tutorial model's callout treatment for step \(index + 1)."
            )
            for calloutIndex in 0..<callouts.count {
                XCTAssertLessThanOrEqual(
                    callouts.element(boundBy: calloutIndex).frame.height,
                    88,
                    "Tutorial callouts must stay compact in a narrow Messages host."
                )
            }
            if title == "Follow the Roll", callouts.count == 2 {
                XCTAssertFalse(
                    callouts.element(boundBy: 0).frame.intersects(
                        callouts.element(boundBy: 1).frame
                    ),
                    "Follow the Roll callouts must not overlap."
                )
            }
            if title == "Place Your First Settlement" {
                let setupOrderCallout = messages.staticTexts[
                    "Everyone places a settlement and road twice. Round two goes in reverse order."
                ].firstMatch
                let boardCallout = messages.staticTexts[
                    "First, place a settlement on a glowing corner."
                ].firstMatch
                XCTAssertTrue(setupOrderCallout.exists)
                XCTAssertTrue(boardCallout.exists)
                XCTAssertGreaterThanOrEqual(
                    boardCallout.frame.minY,
                    setupOrderCallout.frame.maxY,
                    "The first placement instruction must sit below the setup-order card."
                )
            }
            attachScreenshot(named: String(format: "Tutorial %02d - %@", index + 1, title))

            if index < titles.count - 1 {
                let next = messages.buttons["uls.tutorial.next"].firstMatch
                XCTAssertTrue(next.waitForExistence(timeout: 4))
                next.tap()
            }
        }
    }

    func testCaptureNarrowShortTutorialCorrectionCheckpoint() throws {
        openUnluckySevensExtension()
        waitForUXLabChrome()
        activateUXLabNestedQuickState(
            title: "Invitation",
            identifier: "uls.uxLab.cleanShot.lobbyInvite"
        )
        openLobbyTutorial()
        dismissTutorialNavigationCoach()

        assertTutorialProgress(title: "Place Your First Settlement")
        XCTAssertTrue(
            messages.staticTexts[
                "Everyone places a settlement and road twice. Round two goes in reverse order."
            ].firstMatch.waitForExistence(timeout: 4)
        )
        let setupBoard = turnElement(identifier: "uls.tabletop.board", labels: [])
        let setupPieceRail = turnElement(identifier: "uls.setup.pieceRail", labels: [])
        XCTAssertTrue(setupBoard.waitForExistence(timeout: 4))
        XCTAssertTrue(setupPieceRail.waitForExistence(timeout: 4))
        XCTAssertLessThanOrEqual(
            setupBoard.frame.maxY,
            setupPieceRail.frame.minY,
            "The setup ocean frame must end above the fixed piece rail."
        )
        attachScreenshot(named: "Tutorial Correction 01 - Setup")

        let next = messages.buttons["uls.tutorial.next"].firstMatch
        for _ in 0..<5 {
            XCTAssertTrue(next.waitForExistence(timeout: 4))
            next.tap()
        }
        assertTutorialProgress(title: "Choose What to Build")
        XCTAssertTrue(
            messages.staticTexts[
                "Each piece shows its cost. A city upgrades one of your settlements."
            ].firstMatch.waitForExistence(timeout: 4)
        )
        let buildBoard = turnElement(identifier: "uls.tabletop.board", labels: [])
        let turnObjectRail = turnElement(identifier: "uls.turn.objectRail", labels: [])
        XCTAssertTrue(buildBoard.waitForExistence(timeout: 4))
        XCTAssertTrue(turnObjectRail.waitForExistence(timeout: 4))
        XCTAssertLessThanOrEqual(
            buildBoard.frame.maxY,
            turnObjectRail.frame.minY,
            "The turn ocean frame must end above the fixed turn-object rail."
        )
        attachScreenshot(named: "Tutorial Correction 02 - Build")

        for _ in 0..<2 {
            XCTAssertTrue(next.waitForExistence(timeout: 4))
            next.tap()
        }
        assertTutorialProgress(title: "Trade")
        XCTAssertTrue(
            messages.staticTexts[
                "Choose what you’ll offer and what you want back."
            ].firstMatch.waitForExistence(timeout: 4)
        )
        let tradeCallout = messages.descendants(matching: .any)
            .matching(identifier: "uls.tutorial.callout")
            .firstMatch
        let giveHeading = messages.staticTexts["Give"].firstMatch
        XCTAssertTrue(tradeCallout.waitForExistence(timeout: 4))
        XCTAssertTrue(giveHeading.waitForExistence(timeout: 4))
        XCTAssertFalse(
            tradeCallout.frame.intersects(giveHeading.frame),
            "Trade tutorial guidance must not cover the Give heading."
        )
        attachScreenshot(named: "Tutorial Correction 03 - Trade")
    }

    func testCaptureRobberPhysicalFlow() throws {
        openUnluckySevensExtension()
        waitForUXLabChrome()
        activateUXLabQuickState(
            title: "Robber Move",
            identifier: "uls.uxLab.cleanShot.robberMove"
        )

        let topBar = turnElement(identifier: "uls.turn.topBar", labels: [])
        let status = turnElement(identifier: "uls.turn.status", labels: ["Move the Robber"])
        let publicRail = turnElement(identifier: "uls.turn.publicRail", labels: [])
        let boardHost = turnElement(identifier: "uls.tabletop.boardHost", labels: ["Live game board host"])
        let turnObjects = turnElement(identifier: "uls.turn.objectRail", labels: [])
        XCTAssertTrue(topBar.waitForExistence(timeout: 8))
        XCTAssertTrue(status.waitForExistence(timeout: 4))
        XCTAssertTrue(publicRail.exists)
        XCTAssertTrue(boardHost.exists)
        XCTAssertTrue(turnObjects.exists)
        XCTAssertFalse(messages.staticTexts["Tap tile"].exists)
        XCTAssertFalse(messages.descendants(matching: .any)["uls.physicalProps.componentSurface"].firstMatch.exists)
        XCTAssertFalse(messages.descendants(matching: .any)["uls.overlayShelf"].firstMatch.exists)

        let fixedTopBarFrame = topBar.frame
        let fixedPublicRailFrame = publicRail.frame
        let fixedBoardHostFrame = boardHost.frame
        let fixedTurnObjectsFrame = turnObjects.frame
        attachScreenshot(named: "Robber Physical 01 - Move Robber")

        restoreUXLabChrome()
        activateUXLabQuickState(
            title: "Robber Victim",
            identifier: "uls.uxLab.cleanShot.robberVictim"
        )

        let victimStatus = turnElement(
            identifier: "uls.turn.status",
            labels: ["Select a Settlement Beside the Robber"]
        )
        XCTAssertTrue(victimStatus.waitForExistence(timeout: 8))
        XCTAssertEqual(victimStatus.label, "Select a Settlement Beside the Robber")
        XCTAssertFalse(messages.staticTexts["Steal a Card"].exists)
        XCTAssertFalse(messages.staticTexts["Choose a marked player beside the robber."].exists)
        XCTAssertFalse(messages.descendants(matching: .any)["uls.physicalProps.componentSurface"].firstMatch.exists)
        XCTAssertFalse(messages.descendants(matching: .any)["uls.overlayShelf"].firstMatch.exists)
        assertFrame(of: topBar, matches: fixedTopBarFrame, message: "Robber prompts must share one fixed top bar.")
        assertFrame(of: publicRail, matches: fixedPublicRailFrame, message: "Robber prompts must preserve the public rail.")
        assertFrame(of: boardHost, matches: fixedBoardHostFrame, message: "Robber prompts must preserve the mounted board frame.")
        assertFrame(of: turnObjects, matches: fixedTurnObjectsFrame, message: "Robber prompts must preserve the turn-object rail.")
        attachScreenshot(named: "Robber Physical 02 - Select Adjacent Settlement")
    }

    private func assertTutorialProgress(
        title: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let progress = messages.descendants(matching: .any)["uls.tutorial.progress"].firstMatch
        XCTAssertTrue(progress.waitForExistence(timeout: 4), file: file, line: line)
        XCTAssertEqual(progress.label, title, file: file, line: line)
    }

    func testPlaceSettingsOverlayCheckpoint() throws {
        openUnluckySevensExtension()

        let settings = messages.buttons["uls.lobby.gameSettings"].firstMatch
        XCTAssertTrue(settings.waitForExistence(timeout: 4))
        settings.tap()
        XCTAssertTrue(
            messages.descendants(matching: .any)["uls.settings.surface"]
                .firstMatch.waitForExistence(timeout: 4)
        )
    }

    func testSkipAnimationsPersistsWhenSettingsReopens() throws {
        openUnluckySevensExtension()

        let settings = messages.buttons["uls.lobby.gameSettings"].firstMatch
        XCTAssertTrue(settings.waitForExistence(timeout: 4))
        settings.tap()

        let toggle = messages.switches["uls.settings.skipAnimations"].firstMatch
        XCTAssertTrue(toggle.waitForExistence(timeout: 4))
        if (toggle.value as? String) != "0" {
            toggle.tap()
        }
        toggle.tap()
        XCTAssertEqual(toggle.value as? String, "1")

        messages.buttons["Done"].firstMatch.tap()
        XCTAssertTrue(settings.waitForExistence(timeout: 4))
        settings.tap()

        let reopenedToggle = messages.switches["uls.settings.skipAnimations"].firstMatch
        XCTAssertTrue(reopenedToggle.waitForExistence(timeout: 4))
        XCTAssertEqual(reopenedToggle.value as? String, "1")

        reopenedToggle.tap()
        messages.buttons["Done"].firstMatch.tap()
    }

    func testGameplaySettingsOpensOverTheLiveTable() throws {
        openUnluckySevensExtension()
        waitForUXLabChrome()
        loadTurnGameplaySlice()
        collapseUXLabPanelIfExpanded()

        let settings = turnElement(identifier: "", labels: ["Settings"])
        XCTAssertTrue(settings.waitForExistence(timeout: 4))
        settings.tap()

        XCTAssertTrue(
            messages.descendants(matching: .any)["uls.settings.surface"]
                .firstMatch.waitForExistence(timeout: 4)
        )
        XCTAssertTrue(messages.descendants(matching: .any)["uls.tabletop.board"].firstMatch.exists)

        messages.buttons["Done"].firstMatch.tap()
        XCTAssertTrue(turnElement(identifier: "uls.tabletop.board", labels: []).waitForExistence(timeout: 4))
    }

    func testAdvancePreparedMessagesToSettingsOverlay() throws {
        let appRow = messages.staticTexts["Unlucky Sevens"].firstMatch
        XCTAssertTrue(appRow.waitForExistence(timeout: 4))
        appRow.tap()

        let settings = messages.buttons["uls.lobby.gameSettings"].firstMatch
        XCTAssertTrue(settings.waitForExistence(timeout: 4))
        settings.tap()
        XCTAssertTrue(
            messages.descendants(matching: .any)["uls.settings.surface"]
                .firstMatch.waitForExistence(timeout: 4)
        )
    }

    func testAdvanceSettingsOverlayToTradeTutorial() throws {
        let done = messages.buttons["Done"].firstMatch
        XCTAssertTrue(done.waitForExistence(timeout: 4))
        done.tap()

        openLobbyTutorial()

        dismissTutorialNavigationCoach()

        let next = messages.buttons["uls.tutorial.next"].firstMatch
        XCTAssertTrue(next.waitForExistence(timeout: 4))
        for _ in 0..<7 {
            next.tap()
        }
        assertTutorialProgress(title: "Trade")
    }

    func testAdvanceSettingsOverlayToCleanIntroOverlay() throws {
        let done = messages.buttons["Done"].firstMatch
        XCTAssertTrue(done.waitForExistence(timeout: 4))
        done.tap()

        openUXLabPanel()
        activateUXLabNestedQuickState(
            title: "Invitation",
            identifier: "uls.uxLab.cleanShot.lobbyInvite"
        )
        XCTAssertTrue(waitForInviteSlice(timeout: 8))

        messages.buttons["uls.lobby.gameSettings"].firstMatch.tap()
        XCTAssertTrue(
            messages.descendants(matching: .any)["uls.settings.surface"]
                .firstMatch.waitForExistence(timeout: 4)
        )
    }

    func testAdvanceSettingsOverlayToBuildTutorial() throws {
        let done = messages.buttons["Done"].firstMatch
        XCTAssertTrue(done.waitForExistence(timeout: 4))
        done.tap()

        openLobbyTutorial()

        dismissTutorialNavigationCoach()

        for expectedStep in 2...6 {
            let next = messages.buttons["uls.tutorial.next"].firstMatch
            XCTAssertTrue(next.waitForExistence(timeout: 4))
            next.tap()
            XCTAssertTrue(
                messages.staticTexts["\(expectedStep) / 16"].firstMatch.waitForExistence(timeout: 4)
            )
        }
    }

    func testAdvanceOpenTutorialToBuildUsingVisibleControls() throws {
        for expectedStep in 2...6 {
            let next = messages.buttons["uls.tutorial.next"].firstMatch
            XCTAssertTrue(next.waitForExistence(timeout: 4))
            next.tap()
            XCTAssertTrue(
                messages.staticTexts["\(expectedStep) / 17"].firstMatch.waitForExistence(timeout: 4)
            )
        }
    }

    func testPlaceTutorialVictoryCheckpoint() throws {
        openUnluckySevensExtension()
        waitForUXLabChrome()
        loadEndScreenSlice()

        let newGame = messages.buttons["uls.endScreen.newGame"].firstMatch
        XCTAssertTrue(newGame.waitForExistence(timeout: 8))
        newGame.tap()

        openLobbyTutorial()

        dismissTutorialNavigationCoach()

        let next = messages.buttons["uls.tutorial.next"].firstMatch
        XCTAssertTrue(next.waitForExistence(timeout: 4))
        for _ in 0..<15 {
            next.tap()
        }
        assertTutorialProgress(title: "Strategy")
        attachScreenshot(named: "Tutorial - Strategy Player Aid")
    }

    func testAdvanceOpenTutorialToTradeCheckpoint() throws {
        let next = messages.buttons["uls.tutorial.next"].firstMatch
        XCTAssertTrue(next.waitForExistence(timeout: 4))
        for _ in 0..<7 {
            next.tap()
        }
        assertTutorialProgress(title: "Trade")
    }

    func testAdvanceOpenTutorialToVictoryCheckpoint() throws {
        let next = messages.buttons["uls.tutorial.next"].firstMatch
        XCTAssertTrue(next.waitForExistence(timeout: 4))
        for _ in 0..<8 {
            next.tap()
        }
        assertTutorialProgress(title: "Strategy")
    }

    func testAdvanceOpenTutorialThreeStepsToVictoryCheckpoint() throws {
        for expectedStep in 9...16 {
            let next = messages.buttons["uls.tutorial.next"].firstMatch
            XCTAssertTrue(next.waitForExistence(timeout: 4))
            next.tap()
            XCTAssertTrue(
                messages.staticTexts["\(expectedStep) / 16"].firstMatch.waitForExistence(timeout: 4)
            )
        }
        XCTAssertTrue(messages.buttons["uls.tutorial.done"].firstMatch.exists)
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
        tapCurrentFrame(of: button)
        if !button.waitForNonExistence(timeout: 2) {
            let currentButton = firstExistingElement(
                [
                    messages.buttons[identifier].firstMatch,
                    messages.buttons[label].firstMatch,
                    messages.descendants(matching: .any)[identifier].firstMatch,
                    messages.descendants(matching: .any)[label].firstMatch,
                ],
                timeout: 2
            )
            XCTAssertTrue(currentButton.waitForExistence(timeout: 2))
            tapCurrentFrame(of: currentButton)
            XCTAssertTrue(
                currentButton.waitForNonExistence(timeout: 4),
                "The direct UX Lab state control must disappear after activating \(label)."
            )
        }
    }

    private func tapCurrentFrame(of element: XCUIElement) {
        guard element.exists else {
            XCTFail("Cannot coordinate-tap an element that does not exist.")
            return
        }
        let frame = element.frame
        guard !frame.isNull,
              !frame.isInfinite,
              frame.width > 0,
              frame.height > 0,
              frame.intersects(messages.frame)
        else {
            XCTFail("Cannot coordinate-tap an invalid or offscreen frame: \(frame).")
            return
        }
        messages.coordinate(withNormalizedOffset: .zero)
            .withOffset(CGVector(dx: frame.midX, dy: frame.midY))
            .tap()
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
        let setupBoard = turnElement(identifier: "uls.tabletop.board", labels: [])
        let settlement = turnElement(identifier: "uls.setup.piece.settlement", labels: [])
        let road = turnElement(identifier: "uls.setup.piece.road", labels: [])
        _ = assertTabletopLayoutContract(
            board: setupBoard,
            bottomRegion: pieceRail,
            interactiveElements: [settlement, road]
        )
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
    }

    func testCaptureNotPrimaryPlayerOrdinaryWaiting() throws {
        openUnluckySevensExtension()
        waitForUXLabChrome()
        loadNotPrimaryWaitingSlice()

        let board = turnElement(identifier: "uls.tabletop.board", labels: [])
        let publicRail = turnElement(identifier: "uls.turn.publicRail", labels: [])
        let status = turnElement(identifier: "uls.turn.status", labels: ["Maya's Turn"])
        let hand = turnElement(identifier: "uls.physicalProps.hand", labels: ["Hand"])

        XCTAssertTrue(board.waitForExistence(timeout: 8))
        XCTAssertTrue(publicRail.waitForExistence(timeout: 4))
        XCTAssertTrue(status.waitForExistence(timeout: 4))
        XCTAssertTrue(hand.waitForExistence(timeout: 4))
        XCTAssertGreaterThanOrEqual(hand.frame.width, 44)
        XCTAssertGreaterThanOrEqual(hand.frame.height, 44)
        XCTAssertGreaterThanOrEqual(hand.frame.minX, board.frame.minX)
        XCTAssertLessThanOrEqual(hand.frame.maxX, board.frame.maxX)
        XCTAssertFalse(messages.buttons["uls.turnObject.build"].firstMatch.exists)
        XCTAssertFalse(messages.buttons["uls.turnObject.trade"].firstMatch.exists)
        XCTAssertFalse(messages.buttons["uls.turnObject.endTurn"].firstMatch.exists)
        let actionSpread = turnElement(
            identifier: "uls.physicalProps.actionSpread",
            labels: [],
            timeout: 1
        )
        if actionSpread.exists {
            hand.tap()
        }
        XCTAssertTrue(
            actionSpread.waitForNonExistence(timeout: 4),
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
        let hand = turnElement(identifier: "uls.physicalProps.hand", labels: ["Hand"])
        XCTAssertTrue(board.waitForExistence(timeout: 8))
        XCTAssertTrue(boardHost.waitForExistence(timeout: 4))
        XCTAssertTrue(trade.waitForExistence(timeout: 4))
        XCTAssertTrue(hand.waitForExistence(timeout: 4))
        XCTAssertEqual((hand.frame.midX + trade.frame.midX) / 2, board.frame.midX, accuracy: 2)
        let boardFrame = board.frame
        let boardHostValue = String(describing: boardHost.value)

        trade.tap()
        let offerPrompt = turnElement(
            identifier: "",
            labels: ["Review the Offer", "Answer the Trade Offer"]
        )
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
        let hand = turnElement(identifier: "uls.physicalProps.hand", labels: ["Hand"])
        XCTAssertTrue(board.waitForExistence(timeout: 8))
        XCTAssertTrue(boardHost.waitForExistence(timeout: 4))
        XCTAssertTrue(trade.waitForExistence(timeout: 4))
        XCTAssertTrue(hand.waitForExistence(timeout: 4))
        XCTAssertEqual((hand.frame.midX + trade.frame.midX) / 2, board.frame.midX, accuracy: 2)
        let boardFrame = board.frame
        let boardHostValue = String(describing: boardHost.value)

        trade.tap()
        let offerPrompt = turnElement(
            identifier: "",
            labels: ["Review the Offer", "Answer the Trade Offer"]
        )
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
        let prompt = turnElement(identifier: "", labels: ["Waiting for Other Players"])
        let hand = turnElement(identifier: "uls.physicalProps.hand", labels: ["Hand"])
        XCTAssertTrue(board.waitForExistence(timeout: 8))
        XCTAssertTrue(publicRail.waitForExistence(timeout: 4))
        XCTAssertTrue(prompt.waitForExistence(timeout: 4))
        XCTAssertTrue(hand.waitForExistence(timeout: 4))
        XCTAssertGreaterThanOrEqual(hand.frame.minX, board.frame.minX)
        XCTAssertLessThanOrEqual(hand.frame.maxX, board.frame.maxX)
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
        openUXLabPanel()
        activateUXLabQuickState(
            title: "Discard Now",
            identifier: "uls.uxLab.cleanShot.pendingDiscard"
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
        _ = assertTabletopLayoutContract(
            board: board,
            bottomRegion: surface,
            interactiveElements: [wood, brick, wheat, submit]
        )
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
        restoreUXLabChrome()
        activateUXLabQuickState(
            title: "Start Dev",
            identifier: "uls.uxLab.cleanShot.turnNeedsRollDevChooser.menu"
        )
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

    func testGameplayActionRollCommitsCanonicalState() throws {
        openUnluckySevensExtension()
        waitForUXLabChrome()
        loadStartTurnGameplaySlice()

        let before = gameplayActionEvidenceValue()
        XCTAssertTrue(before.contains("rev=8"))
        let roll = turnElement(identifier: "uls.startTurn.roll", labels: ["Roll dice"])
        XCTAssertTrue(roll.waitForExistence(timeout: 8))
        roll.tap()

        let after = waitForGameplayActionEvidenceChange(from: before, timeout: 8)
        XCTAssertTrue(after.contains("rev=9"), after)
        XCTAssertTrue(after.contains("status=Published roll"), after)
        XCTAssertFalse(after.contains("step=needsRoll"), after)
        attachGameplayActionEvidence(name: "Roll", before: before, after: after)
    }

    func testGameplayActionDiscardCommitsCanonicalState() throws {
        openUnluckySevensExtension()
        waitForUXLabChrome()
        loadActionableDiscardSlice()

        let before = gameplayActionEvidenceValue()
        let wood = messages.buttons["uls.discard.hand.wood"].firstMatch
        let brick = messages.buttons["uls.discard.hand.brick"].firstMatch
        let submit = messages.buttons["uls.discard.submit"].firstMatch
        XCTAssertTrue(wood.waitForExistence(timeout: 8))
        XCTAssertTrue(brick.waitForExistence(timeout: 4))
        wood.tap()
        wood.tap()
        wood.tap()
        brick.tap()
        brick.tap()
        XCTAssertTrue(submit.isEnabled)
        submit.tap()

        let after = waitForGameplayActionEvidenceChange(from: before, timeout: 6)
        XCTAssertTrue(after.contains("rev=12"), after)
        XCTAssertTrue(after.contains("status=Published discard"), after)
        XCTAssertTrue(after.contains("submitted=1/1 [host]"), after)
        XCTAssertTrue(after.contains("step=needsRobberMove"), after)
        attachGameplayActionEvidence(name: "Discard", before: before, after: after)
    }

    func testGameplayActionEndTurnCommitsCanonicalState() throws {
        openUnluckySevensExtension()
        waitForUXLabChrome()
        openUXLabPanel()
        activateDirectCleanState(
            identifier: "uls.uxLab.cleanShot.endTurnAction.direct",
            label: "Clean end turn action"
        )

        let before = gameplayActionEvidenceValue()
        let end = turnElement(identifier: "uls.turnObject.endTurn", labels: ["End", "End Turn"])
        XCTAssertTrue(end.waitForExistence(timeout: 8))
        end.tap()
        let confirmation = turnElement(identifier: "uls.turn.endConfirmation", labels: [])
        XCTAssertTrue(confirmation.waitForExistence(timeout: 4))
        let confirm = messages.buttons["uls.turn.endConfirmation.confirm"].firstMatch
        XCTAssertTrue(confirm.waitForExistence(timeout: 4))
        XCTAssertTrue(confirm.isHittable)
        confirm.tap()

        let after = waitForGameplayActionEvidenceChange(from: before, timeout: 6)
        XCTAssertTrue(after.contains("rev=10"), after)
        XCTAssertTrue(after.contains("current=alice"), after)
        XCTAssertTrue(after.contains("status=Published end turn"), after)
        attachGameplayActionEvidence(name: "End Turn", before: before, after: after)
    }

    func testGameplayActionMaritimeTradeCommitsCanonicalState() throws {
        openUnluckySevensExtension()
        waitForUXLabChrome()
        loadTurnGameplaySlice()

        let before = gameplayActionEvidenceValue()
        let trade = turnElement(identifier: "uls.turnObject.trade", labels: ["Trade"])
        XCTAssertTrue(trade.waitForExistence(timeout: 8))
        trade.tap()
        let maritime = messages.buttons["Bank or Port"].firstMatch
        XCTAssertTrue(maritime.waitForExistence(timeout: 4))
        maritime.tap()
        let confirm = messages.buttons["uls.physicalTrade.confirmMaritime"].firstMatch
        XCTAssertTrue(confirm.waitForExistence(timeout: 4))
        confirm.tap()

        let after = waitForGameplayActionEvidenceChange(from: before, timeout: 6)
        XCTAssertTrue(after.contains("rev=10"), after)
        XCTAssertTrue(after.contains("status=Published maritime trade"), after)
        attachGameplayActionEvidence(name: "Maritime Trade", before: before, after: after)
    }

    func testGameplayActionPlayerTradeOfferCommitsCanonicalState() throws {
        openUnluckySevensExtension()
        waitForUXLabChrome()
        loadTurnGameplaySlice()

        let before = gameplayActionEvidenceValue()
        let trade = turnElement(identifier: "uls.turnObject.trade", labels: ["Trade"])
        XCTAssertTrue(trade.waitForExistence(timeout: 8))
        trade.tap()
        messages.buttons["Player Trade"].firstMatch.tap()
        messages.buttons["Add Wood to Give"].firstMatch.tap()
        messages.buttons["Add Brick to Get"].firstMatch.tap()
        messages.buttons["Choose Players"].firstMatch.tap()
        let maya = messages.buttons["Maya"].firstMatch
        XCTAssertTrue(maya.waitForExistence(timeout: 4))
        maya.tap()
        let send = messages.buttons["Send Offer"].firstMatch
        XCTAssertTrue(send.isEnabled)
        send.tap()

        let after = waitForGameplayActionEvidenceChange(from: before, timeout: 6)
        XCTAssertTrue(after.contains("rev=10"), after)
        XCTAssertTrue(after.contains("status=Published trade offer"), after)
        XCTAssertFalse(after.contains("trade=none"), after)
        attachGameplayActionEvidence(name: "Player Trade Offer", before: before, after: after)
    }

    func testGameplayActionTradeAcceptCommitsCanonicalState() throws {
        openUnluckySevensExtension()
        waitForUXLabChrome()
        loadNotPrimaryOfferSlice()

        let before = gameplayActionEvidenceValue()
        let trade = turnElement(identifier: "uls.turnObject.trade", labels: ["Trade"])
        XCTAssertTrue(trade.waitForExistence(timeout: 8))
        trade.tap()
        let accept = messages.buttons["Accept"].firstMatch
        XCTAssertTrue(accept.waitForExistence(timeout: 4))
        XCTAssertTrue(accept.isEnabled)
        accept.tap()

        let after = waitForGameplayActionEvidenceChange(from: before, timeout: 6)
        XCTAssertTrue(after.contains("rev=14"), after)
        XCTAssertTrue(after.contains("status=Applied trade accept"), after)
        XCTAssertFalse(after.contains("responses=none"), after)
        attachGameplayActionEvidence(name: "Trade Accept", before: before, after: after)
    }

    func testGameplayActionBuyDevCardCommitsCanonicalState() throws {
        openUnluckySevensExtension()
        waitForUXLabChrome()
        loadTurnGameplaySlice()

        let before = gameplayActionEvidenceValue()
        let devDeck = turnElement(identifier: "uls.tabletop.devDeck", labels: ["Dev Cards"])
        XCTAssertTrue(devDeck.waitForExistence(timeout: 8))
        XCTAssertTrue(devDeck.isHittable)
        devDeck.tap()

        let after = waitForGameplayActionEvidenceChange(from: before, timeout: 6)
        XCTAssertTrue(after.contains("rev=10"), after)
        XCTAssertTrue(after.contains("status=Published dev-card purchase"), after)
        attachGameplayActionEvidence(name: "Buy Dev Card", before: before, after: after)
    }

    func testGameplayActionSetupSettlementAndRoadCommitCanonicalState() throws {
        openUnluckySevensExtension()
        loadDirectGameplayActionFixture(
            identifier: "uls.uxLab.cleanShot.setupAction.direct",
            label: "Clean setup action"
        )

        let before = gameplayActionEvidenceValue()
        XCTAssertTrue(before.contains("rev=3"), before)
        try tapFirstBoardTarget(kind: "node", requiresConfirmation: true)

        let afterSettlement = waitForGameplayActionEvidenceChange(from: before, timeout: 6)
        XCTAssertTrue(afterSettlement.contains("rev=4"), afterSettlement)
        XCTAssertTrue(afterSettlement.contains("status=Published setup placement"), afterSettlement)
        XCTAssertTrue(afterSettlement.contains("host:R15/S4/C4"), afterSettlement)

        try tapFirstBoardTarget(kind: "edge", requiresConfirmation: true)
        let afterRoad = waitForGameplayActionEvidenceChange(from: afterSettlement, timeout: 6)
        XCTAssertTrue(afterRoad.contains("rev=5"), afterRoad)
        XCTAssertTrue(afterRoad.contains("status=Published setup placement"), afterRoad)
        XCTAssertTrue(afterRoad.contains("host:R14/S4/C4"), afterRoad)
        XCTAssertTrue(afterRoad.contains("current=alice"), afterRoad)
        attachGameplayActionEvidence(name: "Setup Settlement and Road", before: before, after: afterRoad)
    }

    func testGameplayActionBuildRoadCommitsCanonicalState() throws {
        openCanonicalPostRollActionFixture()
        let before = gameplayActionEvidenceValue()
        chooseBuildAction(identifier: "uls.physicalProps.build.buildRoad")
        try tapFirstBoardTarget(kind: "edge", requiresConfirmation: true)

        let after = waitForGameplayActionEvidenceChange(from: before, timeout: 6)
        XCTAssertTrue(after.contains("rev=10"), after)
        XCTAssertTrue(after.contains("status=Published road build"), after)
        XCTAssertTrue(after.contains("rawError=-"), after)
        attachGameplayActionEvidence(name: "Build Road", before: before, after: after)
    }

    func testGameplayActionBuildSettlementCommitsCanonicalState() throws {
        openCanonicalPostRollActionFixture()
        let before = gameplayActionEvidenceValue()
        chooseBuildAction(identifier: "uls.physicalProps.build.buildSettlement")
        try tapFirstBoardTarget(kind: "node", requiresConfirmation: true)

        let after = waitForGameplayActionEvidenceChange(from: before, timeout: 6)
        XCTAssertTrue(after.contains("rev=10"), after)
        XCTAssertTrue(after.contains("status=Published settlement build"), after)
        XCTAssertTrue(after.contains("rawError=-"), after)
        attachGameplayActionEvidence(name: "Build Settlement", before: before, after: after)
    }

    func testGameplayActionBuildCityCommitsCanonicalState() throws {
        openCanonicalPostRollActionFixture()
        let before = gameplayActionEvidenceValue()
        chooseBuildAction(identifier: "uls.physicalProps.build.buildCity")
        try tapFirstBoardTarget(kind: "node", requiresConfirmation: true)

        let after = waitForGameplayActionEvidenceChange(from: before, timeout: 6)
        XCTAssertTrue(after.contains("rev=10"), after)
        XCTAssertTrue(after.contains("status=Published city upgrade"), after)
        XCTAssertTrue(after.contains("rawError=-"), after)
        attachGameplayActionEvidence(name: "Build City", before: before, after: after)
    }

    func testGameplayActionMoveRobberCommitsCanonicalState() throws {
        openUnluckySevensExtension()
        loadDirectGameplayActionFixture(
            identifier: "uls.uxLab.cleanShot.robberAction.direct",
            label: "Clean robber action"
        )

        let before = gameplayActionEvidenceValue()
        XCTAssertTrue(before.contains("rev=12"), before)
        let previousRobber = evidenceField("robber", in: before)
        try tapFirstBoardTarget(kind: "tile", requiresConfirmation: false)

        let after = waitForGameplayActionEvidenceChange(from: before, timeout: 6)
        XCTAssertTrue(after.contains("rev=13"), after)
        XCTAssertTrue(after.contains("status=Published robber move"), after)
        XCTAssertNotEqual(evidenceField("robber", in: after), previousRobber)
        XCTAssertTrue(after.contains("rawError=-"), after)
        attachGameplayActionEvidence(name: "Move Robber", before: before, after: after)
    }

    func testGameplayActionChooseRobberVictimCommitsCanonicalState() throws {
        openUnluckySevensExtension()
        loadDirectGameplayActionFixture(
            identifier: "uls.uxLab.cleanShot.robberVictimAction.direct",
            label: "Clean robber victim action"
        )

        let before = gameplayActionEvidenceValue()
        XCTAssertTrue(before.contains("step=needsRobberSteal"), before)
        XCTAssertFalse(before.contains("victims=none"), before)
        try tapFirstBoardTarget(kind: "node", requiresConfirmation: false)

        let after = waitForGameplayActionEvidenceChange(from: before, timeout: 6)
        XCTAssertTrue(after.contains("status=Published steal selection"), after)
        XCTAssertTrue(after.contains("step=afterRoll"), after)
        XCTAssertTrue(after.contains("rawError=-"), after)
        attachGameplayActionEvidence(name: "Choose Robber Victim", before: before, after: after)
    }

    func testGameplayActionPlayMonopolyCommitsCanonicalState() throws {
        openCanonicalPostRollActionFixture()
        let before = gameplayActionEvidenceValue()
        openPlayableDevCard(identifier: "uls.physicalProps.devCard.monopoly")
        selectDevResource(prefix: "Wood,")
        confirmDevResourceSelection()

        let after = waitForGameplayActionEvidenceChange(from: before, timeout: 6)
        XCTAssertTrue(after.contains("rev=10"), after)
        XCTAssertTrue(after.contains("status=Published monopoly play"), after)
        XCTAssertTrue(after.contains("rawError=-"), after)
        attachGameplayActionEvidence(name: "Play Monopoly", before: before, after: after)
    }

    func testGameplayActionPlayYearOfPlentyCommitsCanonicalState() throws {
        openCanonicalPostRollActionFixture()
        let before = gameplayActionEvidenceValue()
        openPlayableDevCard(identifier: "uls.physicalProps.devCard.yearOfPlenty")
        selectDevResource(prefix: "Wood,")
        selectDevResource(prefix: "Brick,")
        confirmDevResourceSelection()

        let after = waitForGameplayActionEvidenceChange(from: before, timeout: 6)
        XCTAssertTrue(after.contains("rev=10"), after)
        XCTAssertTrue(after.contains("status=Published year-of-plenty play"), after)
        XCTAssertTrue(after.contains("rawError=-"), after)
        attachGameplayActionEvidence(name: "Play Year of Plenty", before: before, after: after)
    }

    func testGameplayActionPlayRoadBuildingCommitsCanonicalState() throws {
        openCanonicalPostRollActionFixture()
        let before = gameplayActionEvidenceValue()
        openPlayableDevCard(identifier: "uls.physicalProps.devCard.roadBuilding")
        try tapFirstBoardTarget(kind: "edge", requiresConfirmation: false)
        try tapFirstBoardTarget(kind: "edge", requiresConfirmation: false)

        let after = waitForGameplayActionEvidenceChange(from: before, timeout: 6)
        XCTAssertTrue(after.contains("rev=10"), after)
        XCTAssertTrue(after.contains("status=Published road-building play"), after)
        XCTAssertTrue(after.contains("rawError=-"), after)
        attachGameplayActionEvidence(name: "Play Road Building", before: before, after: after)
    }

    func testGameplayActionPlayKnightCommitsCanonicalState() throws {
        openCanonicalPostRollActionFixture()
        let before = gameplayActionEvidenceValue()
        openPlayableDevCard(identifier: "uls.physicalProps.devCard.knight")
        try tapFirstBoardTarget(kind: "tile", requiresConfirmation: false)

        if let victim = try boardTargetCoordinate(kind: "node", timeout: 1.5) {
            tapBoardTarget(victim)
        }

        let after = waitForGameplayActionEvidenceChange(from: before, timeout: 6)
        XCTAssertTrue(after.contains("rev=10"), after)
        XCTAssertTrue(after.contains("status=Published knight play"), after)
        XCTAssertTrue(after.contains("rawError=-"), after)
        attachGameplayActionEvidence(name: "Play Knight", before: before, after: after)
    }

    func testGameplayGuardrailCancelTransientActionsPreserveCanonicalState() throws {
        openCanonicalPostRollActionFixture()

        let before = gameplayActionEvidenceValue()
        let board = turnElement(identifier: "uls.tabletop.board", labels: [])
        let boardHost = turnElement(identifier: "uls.tabletop.boardHost", labels: [])
        XCTAssertTrue(board.waitForExistence(timeout: 5))
        XCTAssertTrue(boardHost.waitForExistence(timeout: 4))
        let boardFrame = board.frame
        let boardHostValue = String(describing: boardHost.value)

        chooseBuildAction(identifier: "uls.physicalProps.build.buildRoad")
        XCTAssertNotNil(try boardTargetCoordinate(kind: "edge", timeout: 4))
        let build = turnElement(identifier: "uls.turnObject.build", labels: ["Build"])
        build.tap()
        XCTAssertNil(try boardTargetCoordinate(kind: "edge", timeout: 1))
        XCTAssertEqual(gameplayActionEvidenceValue(), before)

        let trade = turnElement(identifier: "uls.turnObject.trade", labels: ["Trade"])
        XCTAssertTrue(trade.waitForExistence(timeout: 4))
        trade.tap()
        let playerTrade = messages.buttons["Player Trade"].firstMatch
        XCTAssertTrue(playerTrade.waitForExistence(timeout: 4))
        playerTrade.tap()
        let giveWood = messages.buttons["Add Wood to Give"].firstMatch
        let getBrick = messages.buttons["Add Brick to Get"].firstMatch
        XCTAssertTrue(giveWood.waitForExistence(timeout: 4))
        XCTAssertTrue(getBrick.waitForExistence(timeout: 4))
        giveWood.tap()
        getBrick.tap()
        let closeTrade = messages.buttons["uls.physicalTrade.close"].firstMatch
        XCTAssertTrue(closeTrade.waitForExistence(timeout: 4))
        closeTrade.tap()
        XCTAssertTrue(giveWood.waitForNonExistence(timeout: 4))
        XCTAssertEqual(gameplayActionEvidenceValue(), before)

        let end = turnElement(identifier: "uls.turnObject.endTurn", labels: ["End", "End Turn"])
        XCTAssertTrue(end.waitForExistence(timeout: 4))
        end.tap()
        let confirmation = turnElement(identifier: "uls.turn.endConfirmation", labels: [])
        XCTAssertTrue(confirmation.waitForExistence(timeout: 4))
        let keepPlaying = messages.buttons["uls.turn.endConfirmation.cancel"].firstMatch
        XCTAssertTrue(keepPlaying.waitForExistence(timeout: 4))
        keepPlaying.tap()
        XCTAssertTrue(confirmation.waitForNonExistence(timeout: 4))

        let after = gameplayActionEvidenceValue()
        XCTAssertEqual(after, before, "Cancelling transient UI must not publish canonical state.")
        XCTAssertEqual(board.frame, boardFrame)
        XCTAssertEqual(String(describing: boardHost.value), boardHostValue)
        attachGameplayActionEvidence(name: "Cancelled Build Trade and End Turn", before: before, after: after)
        attachScreenshot(named: "Gameplay Guardrails - Cancelled Actions Preserve State")
    }

    func testGameplayGuardrailDeclineTradeCommitsCanonicalState() throws {
        openUnluckySevensExtension()
        waitForUXLabChrome()
        loadNotPrimaryOfferSlice()

        let before = gameplayActionEvidenceValue()
        let trade = turnElement(identifier: "uls.turnObject.trade", labels: ["Trade"])
        XCTAssertTrue(trade.waitForExistence(timeout: 8))
        trade.tap()
        let decline = messages.buttons["Decline"].firstMatch
        XCTAssertTrue(decline.waitForExistence(timeout: 4))
        XCTAssertTrue(decline.isEnabled)
        decline.tap()

        let after = waitForGameplayActionEvidenceChange(from: before, timeout: 6)
        XCTAssertTrue(after.contains("rev=14"), after)
        XCTAssertTrue(after.contains("status=Applied trade decline"), after)
        XCTAssertFalse(after.contains("responses=none"), after)
        XCTAssertTrue(after.contains("rawError=-"), after)
        attachGameplayActionEvidence(name: "Trade Decline", before: before, after: after)
    }

    func testGameplayGuardrailWaitingPlayerCannotAct() throws {
        openUnluckySevensExtension()
        waitForUXLabChrome()
        loadNotPrimaryWaitingSlice()

        let before = gameplayActionEvidenceValue()
        let hand = turnElement(identifier: "uls.physicalProps.hand", labels: ["Hand"])
        XCTAssertTrue(hand.waitForExistence(timeout: 8))
        XCTAssertFalse(messages.buttons["uls.turnObject.build"].firstMatch.exists)
        XCTAssertFalse(messages.buttons["uls.turnObject.trade"].firstMatch.exists)
        XCTAssertFalse(messages.buttons["uls.turnObject.endTurn"].firstMatch.exists)
        hand.tap()
        let actionSpread = turnElement(
            identifier: "uls.physicalProps.actionSpread",
            labels: [],
            timeout: 1
        )
        XCTAssertTrue(actionSpread.waitForExistence(timeout: 3))
        XCTAssertEqual(actionSpread.value as? String, "Hand")
        XCTAssertFalse(
            messages.buttons.matching(
                NSPredicate(format: "identifier BEGINSWITH %@", "uls.physicalProps.devCard.")
            ).allElementsBoundByIndex.contains { $0.isEnabled },
            "A waiting player may inspect their Hand but cannot play a Dev Card."
        )

        let after = gameplayActionEvidenceValue()
        XCTAssertEqual(after, before, "A waiting player must not publish or reveal active-turn actions.")
        attachGameplayActionEvidence(name: "Waiting Player Cannot Act", before: before, after: after)
        attachScreenshot(named: "Gameplay Guardrails - Waiting Player")
    }

    func testGameplayActionVictoryPointReachesGameOverSurface() throws {
        openUnluckySevensExtension()
        loadDirectGameplayActionFixture(
            identifier: "uls.uxLab.cleanShot.victoryAction.direct",
            label: "Clean victory action"
        )
        let before = waitForGameplayActionEvidence(
            containing: "status=UX Lab loaded Victory action",
            timeout: 6
        )
        XCTAssertTrue(before.contains("phase=turn"), before)
        XCTAssertTrue(before.contains("winner=-"), before)

        openPlayableDevCard(identifier: "uls.physicalProps.devCard.victoryPoint")

        let after = waitForGameplayActionEvidenceChange(from: before, timeout: 8)
        XCTAssertTrue(after.contains("rev=18"), after)
        XCTAssertTrue(after.contains("phase=gameOver"), after)
        XCTAssertTrue(after.contains("winner=host"), after)
        XCTAssertTrue(after.contains("winningVP=10"), after)
        XCTAssertTrue(after.contains("status=Published victory-point reveal"), after)
        XCTAssertTrue(after.contains("rawError=-"), after)
        XCTAssertTrue(
            messages.descendants(matching: .any)["uls.endScreen"].firstMatch
                .waitForExistence(timeout: 6)
        )
        attachGameplayActionEvidence(name: "Reveal Winning Victory Point", before: before, after: after)
        attachScreenshot(named: "Complete Match - Winning Action")
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

    func testCaptureNarrowShortResponsiveCheckpoint() throws {
        openUnluckySevensExtension()
        waitForUXLabChrome()
        loadTurnGameplaySlice()
        collapseUXLabPanelIfExpanded()

        let board = turnElement(identifier: "uls.tabletop.board", labels: [])
        let boardHost = turnElement(identifier: "uls.tabletop.boardHost", labels: [])
        let hand = turnElement(identifier: "uls.physicalProps.hand", labels: ["Hand"])
        let build = turnElement(identifier: "uls.turnObject.build", labels: ["Build"])
        let trade = turnElement(identifier: "uls.turnObject.trade", labels: ["Trade"])
        let end = turnElement(identifier: "uls.turnObject.endTurn", labels: ["End", "End Turn"])
        let turnObjects = [hand, build, trade, end]
        XCTAssertTrue(board.waitForExistence(timeout: 8))
        XCTAssertTrue(boardHost.waitForExistence(timeout: 4))
        XCTAssertEqual(
            boardHost.frame.width / boardHost.frame.height,
            430.0 / 520.0,
            accuracy: 0.01,
            "The live board host must preserve the canonical ocean aspect ratio."
        )
        for object in turnObjects {
            XCTAssertTrue(object.waitForExistence(timeout: 4))
            XCTAssertGreaterThanOrEqual(object.frame.width, 44)
            XCTAssertGreaterThanOrEqual(object.frame.height, 44)
        }
        let initialHostDiagnostic = assertTabletopLayoutContract(
            board: board,
            bottomRegion: turnElement(identifier: "uls.turn.objectRail", labels: []),
            interactiveElements: turnObjects
        )
        let hostDiagnosticAttachment = XCTAttachment(string: initialHostDiagnostic)
        hostDiagnosticAttachment.name = "Host Layout Diagnostics"
        hostDiagnosticAttachment.lifetime = .keepAlways
        add(hostDiagnosticAttachment)
        let initialBoardMount = boardMountIdentity(of: boardHost)
        let fixedBoardFrame = board.frame
        let fixedTurnObjectFrames = turnObjects.map(\.frame)
        attachScreenshot(named: "Responsive 01 - Normal Turn")

        let gameInfo = turnElement(
            identifier: "",
            labels: ["Players and game information", "Game information"]
        )
        XCTAssertTrue(gameInfo.waitForExistence(timeout: 4))
        gameInfo.tap()
        let gameInfoSurface = turnElement(identifier: "uls.turn.gameInfo", labels: [])
        XCTAssertTrue(gameInfoSurface.waitForExistence(timeout: 4))
        XCTAssertEqual(gameInfoSurface.frame.midX, fixedBoardFrame.midX, accuracy: 2)
        assertFrame(of: board, matches: fixedBoardFrame, message: "Players must not resize the board.")
        for (object, expectedFrame) in zip(turnObjects, fixedTurnObjectFrames) {
            assertFrame(of: object, matches: expectedFrame, message: "Players must not move the fixed turn rail.")
        }
        XCTAssertEqual(
            currentHostDiagnosticValue(),
            initialHostDiagnostic,
            "Players must not republish the settled Messages host layout."
        )
        attachScreenshot(named: "Responsive 02 - Players")

        let closeGameInfo = messages.buttons["uls.gameInfo.close"].firstMatch
        XCTAssertTrue(closeGameInfo.waitForExistence(timeout: 4))
        closeGameInfo.tap()
        XCTAssertTrue(gameInfoSurface.waitForNonExistence(timeout: 4))

        let currentTrade = turnElement(
            identifier: "uls.turnObject.trade",
            labels: ["Trade"]
        )
        XCTAssertTrue(currentTrade.waitForExistence(timeout: 4))
        let currentTradeFrame = currentTrade.frame
        messages.coordinate(withNormalizedOffset: .zero)
            .withOffset(CGVector(dx: currentTradeFrame.midX, dy: currentTradeFrame.midY))
            .tap()
        let tradeSurface = turnElement(identifier: "uls.turn.tradeSurface", labels: [])
        XCTAssertTrue(
            tradeSurface.waitForExistence(timeout: 4),
            "Trade must finish its route transition before the harness selects a trade kind."
        )
        let playerTrade = exactLabelElement("Player Trade")
        XCTAssertTrue(playerTrade.waitForExistence(timeout: 4))
        playerTrade.tap()
        let tradeComposer = turnElement(
            identifier: "uls.physicalTrade.composerPanel",
            labels: ["Player Trade"]
        )
        XCTAssertTrue(tradeComposer.waitForExistence(timeout: 4))
        assertElement(
            tradeComposer,
            isContainedIn: messages.windows.firstMatch.frame,
            message: "Trade composer must remain fully visible in the Messages host."
        )
        assertFrame(of: board, matches: fixedBoardFrame, message: "Trade must not resize the board.")
        for (object, expectedFrame) in zip(turnObjects, fixedTurnObjectFrames) {
            assertFrame(of: object, matches: expectedFrame, message: "Trade must not move the fixed turn rail.")
        }
        XCTAssertEqual(
            currentHostDiagnosticValue(),
            initialHostDiagnostic,
            "Trade must not republish the settled Messages host layout."
        )
        let currentBoardHost = turnElement(
            identifier: "uls.tabletop.boardHost",
            labels: ["Live game board host"]
        )
        XCTAssertEqual(
            boardMountIdentity(of: currentBoardHost),
            initialBoardMount,
            "Trade must preserve the mounted SpriteKit host."
        )
        _ = assertTabletopLayoutContract(
            board: board,
            bottomRegion: turnElement(identifier: "uls.turn.objectRail", labels: []),
            interactiveElements: turnObjects,
            protectedOverlays: [tradeComposer]
        )
        attachScreenshot(named: "Responsive 03 - Trade Composer")
    }

    func testOpenMessagesExtensionAndCaptureTurnGameplaySlice() throws {
        openUnluckySevensExtension()
        waitForUXLabChrome()
        loadTurnGameplaySlice()

        XCTAssertTrue(
            turnElement(identifier: "uls.physicalProps.hand", labels: ["Hand"])
                .waitForExistence(timeout: 8),
            "Expected the turn gameplay fixture to render."
        )
        for _ in 0..<3 {
            let currentWheatCard = messages.descendants(matching: .any)[
                "uls.physicalProps.handCard.wheat"
            ]
            if currentWheatCard.waitForExistence(timeout: 2),
               currentWheatCard.label.contains("5 owned") {
                break
            }
            restoreUXLabChrome()
            loadTurnGameplaySlice()
            Thread.sleep(forTimeInterval: 0.5)
        }
        let loadedWheatCard = messages.descendants(matching: .any)[
            "uls.physicalProps.handCard.wheat"
        ]
        XCTAssertTrue(loadedWheatCard.waitForExistence(timeout: 4))
        XCTAssertTrue(loadedWheatCard.label.contains("5 owned"))
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
            messages.descendants(matching: .any)["uls.settings.surface"]
                .firstMatch.waitForExistence(timeout: 4),
            "Expected Settings to open over gameplay."
        )
        XCTAssertTrue(
            waitForValueChange(
                of: settingsHookEvidence,
                from: initialSettingsHookValue,
                timeout: 4
            ),
            "Expected Settings to invoke the root navigation hook without requiring a destination in this slice."
        )
        messages.buttons["Done"].firstMatch.tap()
        let handButton = turnElement(identifier: "uls.physicalProps.hand", labels: ["Hand"])
        XCTAssertTrue(handButton.waitForExistence(timeout: 4), "Expected the fixed Hand object.")
        let handAccessibilityState = [
            handButton.label,
            String(describing: handButton.value),
        ]
        .joined(separator: " ")
        XCTAssertTrue(
            handAccessibilityState.contains("resource cards"),
            "Hand must expose its total resource-card count before opening."
        )
        XCTAssertNotNil(
            handAccessibilityState.rangeOfCharacter(from: .decimalDigits),
            "Hand must expose a numeric total resource-card count."
        )
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
        let safeFrame = messages.windows.firstMatch.frame
        expectedTurnActionWellFrame = fixedActionWellFrame
        assertElement(handSurface, isContainedIn: fixedActionWellFrame, message: "Hand must stay inside the reserved action well.")
        let fixedTurnObjectFrames = turnObjects.map(\.frame)
        let fixedTurnRailFrame = unionFrame(of: turnObjects)
        let fixedBoardHostFrame = boardHost.frame
        let fixedBoardHostValue = String(describing: boardHost.value)
        let fixedBoardMount = boardMountIdentity(of: boardHost)
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
        XCTAssertEqual(boardMountIdentity(of: boardHost), fixedBoardMount)
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
        XCTAssertEqual(boardMountIdentity(of: boardHost), fixedBoardMount)
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
        let gamesInGameInfo = messages.buttons["uls.gameInfo.games"].firstMatch
        XCTAssertTrue(gamesInGameInfo.waitForExistence(timeout: 4))
        XCTAssertGreaterThanOrEqual(
            gameInfoSurface.frame.height,
            fixedActionWellFrame.height,
            "Centered Game Information must remain tall enough for complete player rows."
        )
        XCTAssertEqual(
            gameInfoSurface.frame.midX,
            fixedBoardFrame.midX,
            accuracy: 2,
            "Game Information must share the mounted board's host-local horizontal center."
        )
        XCTAssertGreaterThan(
            gameInfoSurface.frame.minY,
            fixedStatusFrame.maxY,
            "Game Information must stay below the fixed top status."
        )
        XCTAssertLessThan(
            gameInfoSurface.frame.maxY,
            fixedTurnRailFrame.minY,
            "Game Information must float above the unchanged turn-object rail."
        )
        let localPlayerSummary = messages.staticTexts["Kunal · You"].firstMatch
        XCTAssertTrue(localPlayerSummary.waitForExistence(timeout: 4))
        assertElement(
            localPlayerSummary,
            isContainedIn: gameInfoSurface.frame,
            message: "Game Information must show at least one complete player summary."
        )
        assertElement(
            messages.staticTexts["Last turn: Maya rolled 6, built road, ended turn"].firstMatch,
            isContainedIn: gameInfoSurface.frame,
            message: "The short public recap must be visible inside Game Information."
        )
        let occludedBoardHost = messages.descendants(matching: .any)[
            "uls.tabletop.boardHost.occluded"
        ].firstMatch
        XCTAssertTrue(
            occludedBoardHost.waitForExistence(timeout: 4),
            "The centered Game Information focus veil must keep the live board mounted."
        )
        assertFrame(of: board, matches: fixedBoardFrame, message: "The board must stay fixed for Game Info.")
        assertFrame(
            of: occludedBoardHost,
            matches: fixedBoardHostFrame,
            message: "The live board host must stay fixed behind centered Game Information."
        )
        let occludedBoardHostValue = String(describing: occludedBoardHost.value)
        XCTAssertEqual(
            boardMountIdentity(of: occludedBoardHost),
            fixedBoardMount,
            "Game Information must preserve the mounted SpriteKit host."
        )
        XCTAssertTrue(
            occludedBoardHostValue.contains("occlusion=1.0"),
            "Game Information must report the board as visually occluded."
        )
        assertPersistentTurnGeometry(
            board: board, boardFrame: fixedBoardFrame,
            boardHost: occludedBoardHost, boardHostValue: occludedBoardHostValue,
            bankRack: bankRack, bankRackFrame: fixedBankRackFrame,
            publicRail: publicRail, publicRailFrame: fixedPublicRailFrame,
            status: status, statusFrame: fixedStatusFrame,
            turnObjects: turnObjects, turnObjectFrames: fixedTurnObjectFrames,
            turnRailFrame: fixedTurnRailFrame, route: "Game Info"
        )
        attachScreenshot(named: "Unlucky Sevens - turn gameplay game info")

        let gameInfoFrame = gameInfoSurface.frame
        gamesInGameInfo.tap()
        let inlineGamesList = messages.buttons["uls.gameInfo.players"].firstMatch
        XCTAssertTrue(
            inlineGamesList.waitForExistence(timeout: 4),
            "Games must replace the player rows inside Game Information."
        )
        XCTAssertFalse(localPlayerSummary.exists)
        XCTAssertFalse(messages.descendants(matching: .any)["uls.games.library"].firstMatch.exists)
        let manageGames = messages.buttons["uls.gameInfo.manageGames"].firstMatch
        XCTAssertTrue(manageGames.waitForExistence(timeout: 4))
        XCTAssertEqual(manageGames.label, "Your Games")
        assertMinimumTarget(
            manageGames,
            message: "The labeled Your Games destination must preserve a 44-point target."
        )
        assertFrame(
            of: gameInfoSurface,
            matches: gameInfoFrame,
            message: "Switching from Players to Games must preserve the Game Information frame."
        )
        assertFrame(of: board, matches: fixedBoardFrame, message: "The board must stay fixed for inline Games.")
        assertFrame(
            of: occludedBoardHost,
            matches: fixedBoardHostFrame,
            message: "Switching to Games must not move the live board host."
        )
        XCTAssertEqual(String(describing: occludedBoardHost.value), occludedBoardHostValue)
        attachScreenshot(named: "Unlucky Sevens - turn gameplay inline games")

        let playersInGameInfo = messages.buttons["uls.gameInfo.players"].firstMatch
        XCTAssertTrue(playersInGameInfo.waitForExistence(timeout: 4))
        playersInGameInfo.tap()
        if !localPlayerSummary.waitForExistence(timeout: 2), playersInGameInfo.exists {
            playersInGameInfo.tap()
        }
        XCTAssertTrue(localPlayerSummary.waitForExistence(timeout: 4))
        assertFrame(
            of: gameInfoSurface,
            matches: gameInfoFrame,
            message: "Returning to Players must preserve the Game Information frame."
        )

        let closeGameInfo = messages.buttons["uls.gameInfo.close"].firstMatch
        XCTAssertTrue(closeGameInfo.waitForExistence(timeout: 4))
        closeGameInfo.tap()
        XCTAssertTrue(gameInfoSurface.waitForNonExistence(timeout: 4))

        XCTAssertTrue(
            waitForHittable(buildButton, timeout: 4),
            "Build must become tappable after Game Information closes."
        )
        buildButton.tap()
        let buildSurface = turnElement(identifier: "uls.physicalProps.actionSpread", labels: [])
        let roadButton = messages.staticTexts["Road"].firstMatch
        let settlementButton = messages.staticTexts["Settlement"].firstMatch
        let cityButton = messages.staticTexts["City"].firstMatch
        if !roadButton.waitForExistence(timeout: 1) {
            XCTAssertTrue(
                waitForHittable(buildButton, timeout: 4),
                "Build must remain tappable if Messages drops the first post-overlay tap."
            )
            buildButton.tap()
        }
        XCTAssertTrue(roadButton.waitForExistence(timeout: 4))
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
        XCTAssertFalse(
            exactLabelElement("Tap road").exists,
            "Physical Props must keep build guidance in the fixed header instead of covering the board."
        )
        XCTAssertTrue(buildSurface.waitForNonExistence(timeout: 4))
        XCTAssertTrue(buildButton.isSelected)
        assertFrame(of: board, matches: fixedBoardFrame, message: "The board must stay fixed for Road targets.")
        XCTAssertEqual(boardMountIdentity(of: boardHost), fixedBoardMount)
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
        for _ in 0..<2 where !settlementButton.exists {
            buildSurface.swipeLeft()
        }
        XCTAssertTrue(settlementButton.waitForExistence(timeout: 4))
        settlementButton.tap()
        let placeSettlementPrompt = exactLabelElement("Place a Settlement")
        XCTAssertTrue(placeSettlementPrompt.waitForExistence(timeout: 4))
        XCTAssertFalse(
            exactLabelElement("Tap node").exists,
            "Physical Props must keep build guidance in the fixed header instead of covering the board."
        )
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
        for _ in 0..<3 where !cityButton.exists {
            buildSurface.swipeLeft()
        }
        if cityButton.waitForExistence(timeout: 4) {
            cityButton.tap()
            let upgradeCityPrompt = exactLabelElement("Upgrade to a City")
            XCTAssertTrue(upgradeCityPrompt.waitForExistence(timeout: 4))
            XCTAssertFalse(
                exactLabelElement("Tap city").exists,
                "Physical Props must keep build guidance in the fixed header instead of covering the board."
            )
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
        } else {
            buildButton.tap()
        }

        XCTAssertTrue(tradeButton.waitForExistence(timeout: 4))
        tradeButton.tap()
        let tradeSurface = turnElement(identifier: "uls.turn.tradeSurface", labels: [])
        let playerTrade = exactLabelElement("Player Trade")
        XCTAssertTrue(playerTrade.waitForExistence(timeout: 4))
        XCTAssertTrue(tradeSurface.waitForExistence(timeout: 4))
        XCTAssertTrue(exactLabelElement("Bank or Port").exists)
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
        let tradeComposerSignal = exactLabelElement("Give")
        let tradeComposer = turnElement(
            identifier: "uls.physicalTrade.composerPanel",
            labels: ["Player Trade"]
        )
        XCTAssertTrue(tradeComposerSignal.waitForExistence(timeout: 4))
        XCTAssertTrue(tradeComposer.waitForExistence(timeout: 4))
        assertElement(
            tradeComposer,
            isContainedIn: safeFrame,
            message: "The expanded Trade composer must remain fully on screen."
        )
        XCTAssertLessThan(
            tradeComposerSignal.frame.minY,
            fixedActionWellFrame.minY,
            "The card-native Trade composer intentionally expands above the shallow action well."
        )
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
        let cancelTradeDraft = messages.buttons["uls.physicalTrade.close"].firstMatch
        XCTAssertTrue(
            waitForHittable(cancelTradeDraft, timeout: 4),
            "Trade composer Close must remain pinned and reachable in the expanded overlay."
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
        XCTAssertFalse(
            exactLabelElement("Tap tile").exists,
            "Physical Props must keep robber guidance in the fixed header instead of covering the board."
        )
        assertFrame(of: board, matches: fixedBoardFrame, message: "The board must stay fixed for Dev board selection.")
        XCTAssertEqual(boardMountIdentity(of: boardHost), fixedBoardMount)
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
        XCTAssertGreaterThanOrEqual(
            gameInfoSurface.frame.height,
            fixedActionWellFrame.height,
            "Centered Game Information must remain tall enough for complete player rows."
        )
        XCTAssertEqual(
            gameInfoSurface.frame.midX,
            fixedBoardFrame.midX,
            accuracy: 2,
            "Cross-object replacement must preserve the host-local centered Game Information frame."
        )
        XCTAssertGreaterThan(
            gameInfoSurface.frame.minY,
            fixedStatusFrame.maxY,
            "Cross-object replacement must keep Game Information below the fixed status."
        )
        XCTAssertLessThan(
            gameInfoSurface.frame.maxY,
            fixedTurnRailFrame.minY,
            "Cross-object replacement must keep Game Information above the turn-object rail."
        )
        assertElement(
            messages.staticTexts["Kunal · You"].firstMatch,
            isContainedIn: gameInfoSurface.frame,
            message: "Cross-object replacement must retain a complete player summary."
        )
        assertFrame(of: board, matches: fixedBoardFrame, message: "The board must remain fixed after every action-well route.")
        XCTAssertEqual(String(describing: occludedBoardHost.value), occludedBoardHostValue)

        closeGameInfo.tap()
        XCTAssertTrue(gameInfoSurface.waitForNonExistence(timeout: 4))
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

    func testCaptureCityTargetAndGameInfoRegression() throws {
        try XCTSkipIf(true, "Game Information proof must be recaptured for Player Record and current-game lifecycle controls.")
        openUnluckySevensExtension()
        waitForUXLabChrome()
        activateUXLabQuickState(
            title: "Turn",
            identifier: "uls.uxLab.cleanShot.turnAfterRoll"
        )
        XCTAssertTrue(
            turnElement(identifier: "uls.physicalProps.hand", labels: ["Hand"])
                .waitForExistence(timeout: 8)
        )
        restoreUXLabChrome()
        waitForUXLabChrome()
        activateDirectCleanState(
            identifier: "uls.uxLab.cleanShot.turnNeedsRollDevChooser",
            label: "City Targets"
        )
        let upgradeCityPrompt = exactLabelElement("Upgrade to a City")
        if !upgradeCityPrompt.waitForExistence(timeout: 2) {
            let buildButton = turnElement(identifier: "uls.turnObject.build", labels: ["Build"])
            XCTAssertTrue(buildButton.waitForExistence(timeout: 8))
            buildButton.tap()
            let roadChoice = messages.staticTexts["Road"].firstMatch
            if !roadChoice.waitForExistence(timeout: 2) {
                buildButton.tap()
            }
            XCTAssertTrue(roadChoice.waitForExistence(timeout: 4))
            let cityChoice = messages.staticTexts["City"].firstMatch
            XCTAssertTrue(cityChoice.waitForExistence(timeout: 4))
            cityChoice.tap()
        }
        XCTAssertTrue(upgradeCityPrompt.waitForExistence(timeout: 8))
        XCTAssertFalse(
            exactLabelElement("Tap city").exists,
            "The fixed Physical Props header must own city guidance without covering the board."
        )
        attachScreenshot(named: "Regression - unobstructed city targets")

        restoreUXLabChrome()
        loadTurnGameplaySlice()
        XCTAssertTrue(
            turnElement(identifier: "uls.physicalProps.hand", labels: ["Hand"])
                .waitForExistence(timeout: 8),
            "Expected the turn gameplay fixture to render."
        )
        collapseUXLabPanelIfExpanded()

        let gameInfo = turnElement(
            identifier: "",
            labels: ["Players and game information", "Game information"]
        )
        XCTAssertTrue(gameInfo.waitForExistence(timeout: 4))
        gameInfo.tap()
        XCTAssertTrue(
            turnElement(identifier: "uls.turn.gameInfo", labels: [])
                .waitForExistence(timeout: 4),
            "Expected compact Game Information to open."
        )
        XCTAssertTrue(messages.buttons["uls.gameInfo.games"].firstMatch.waitForExistence(timeout: 4))
        let gameInfoSurface = turnElement(identifier: "uls.turn.gameInfo", labels: [])
        let localPlayerSummary = messages.staticTexts["Kunal · You"].firstMatch
        XCTAssertTrue(localPlayerSummary.waitForExistence(timeout: 4))
        assertElement(
            localPlayerSummary,
            isContainedIn: gameInfoSurface.frame,
            message: "Compact Game Information must still show a complete player summary."
        )
        let recap = messages.staticTexts["Last turn: Maya rolled 6, built road, ended turn"].firstMatch
        XCTAssertTrue(recap.waitForExistence(timeout: 4))
        assertElement(
            recap,
            isContainedIn: gameInfoSurface.frame,
            message: "Compact Game Information must keep its public recap visible."
        )
        attachScreenshot(named: "Regression - compact game info")

        let fixedGameInfoFrame = gameInfoSurface.frame
        messages.buttons["uls.gameInfo.games"].firstMatch.tap()
        let inlineGames = messages.buttons["uls.gameInfo.players"].firstMatch
        XCTAssertTrue(inlineGames.waitForExistence(timeout: 4))
        XCTAssertFalse(localPlayerSummary.exists)
        XCTAssertFalse(messages.descendants(matching: .any)["uls.games.library"].firstMatch.exists)
        let manageGames = messages.buttons["uls.gameInfo.manageGames"].firstMatch
        XCTAssertTrue(manageGames.waitForExistence(timeout: 4))
        assertMinimumTarget(
            manageGames,
            message: "The centered Your Games destination must preserve a 44-point target."
        )
        assertFrame(
            of: gameInfoSurface,
            matches: fixedGameInfoFrame,
            message: "Inline Games must replace player rows without resizing Game Information."
        )
        attachScreenshot(named: "Regression - compact inline games")

        let players = messages.buttons["uls.gameInfo.players"].firstMatch
        XCTAssertTrue(players.waitForExistence(timeout: 4))
        players.tap()
        if !localPlayerSummary.waitForExistence(timeout: 2), players.exists {
            players.tap()
        }
        XCTAssertTrue(localPlayerSummary.waitForExistence(timeout: 4))
        assertFrame(
            of: gameInfoSurface,
            matches: fixedGameInfoFrame,
            message: "Players must restore the roster without resizing Game Information."
        )

        let closeGameInfo = messages.buttons["uls.gameInfo.close"].firstMatch
        XCTAssertTrue(closeGameInfo.waitForExistence(timeout: 4))
        XCTAssertEqual(closeGameInfo.label, "Close game information")
        closeGameInfo.tap()
        XCTAssertTrue(
            closeGameInfo.waitForNonExistence(timeout: 4),
            "Closing Game Information must remove its interactive surface."
        )
        XCTAssertTrue(
            turnElement(
                identifier: "",
                labels: ["Players and game information", "Game information"]
            ).waitForExistence(timeout: 4),
            "Closing Game Information must restore the gameplay entry point."
        )

    }

    func testOpenMessagesExtensionAndCaptureEndScreenCandidate() throws {
        openUnluckySevensExtension()
        waitForUXLabChrome()
        loadEndScreenSlice()

        let endScreen = turnElement(identifier: "uls.endScreen", labels: [])
        let board = turnElement(identifier: "uls.tabletop.board", labels: [])
        XCTAssertTrue(
            endScreen.waitForExistence(timeout: 8),
            "Expected the Physical Props end-screen candidate to render."
        )
        XCTAssertTrue(
            board.waitForExistence(timeout: 4),
            "Expected the final live board to remain visible."
        )
        XCTAssertFalse(
            messages.buttons["Games"].firstMatch.exists,
            "Games management belongs on the lobby, not over the final board."
        )
        let outcomeHeader = turnElement(
            identifier: "uls.endScreen.title",
            labels: []
        )
        XCTAssertTrue(outcomeHeader.waitForExistence(timeout: 4))
        XCTAssertTrue(
            outcomeHeader.label.contains("Victory!")
                && outcomeHeader.label.contains("10 points"),
            "The terminal header should lead with the local result."
        )
        XCTAssertTrue(
            turnElement(
                identifier: "uls.endScreen.playedDevelopmentCards",
                labels: []
            ).waitForExistence(timeout: 4),
            "Expected the local player's played development cards to remain visible."
        )
        XCTAssertTrue(
            messages.staticTexts["Final scores"].firstMatch.exists,
            "Expected the result aid to use a printed final-score ledger."
        )
        XCTAssertTrue(
            outcomeHeader.label.contains("Your city secured the victory."),
            "Expected the end screen to explain the decisive winning event."
        )
        for playerID in ["host", "alice", "ben"] {
            XCTAssertTrue(
                turnElement(
                    identifier: "uls.endScreen.player.\(playerID)",
                    labels: []
                ).waitForExistence(timeout: 4),
                "Expected every final player score to render."
            )
        }
        XCTAssertLessThan(
            endScreen.frame.minY,
            endScreen.frame.maxY,
            "Expected the result rail to have visible height."
        )
        XCTAssertGreaterThan(
            endScreen.frame.minY,
            board.frame.midY,
            "Expected the result rail to stay in the lower table zone."
        )
        XCTAssertGreaterThanOrEqual(
            endScreen.frame.minY - board.frame.maxY,
            6,
            "Expected a visible gap between the final board and score rail."
        )
        attachScreenshot(named: "End Screen Candidate - Final Board and Scores")
    }

    func testRecoveryGamesArchiveAndRestoreJourney() throws {
        try XCTSkipIf(true, "Superseded: Player Record has no archive or recovery actions.")
        openUnluckySevensExtension()
        loadRecoveryGamesSlice()

        openGamesLibraryFromCurrentSurface()
        XCTAssertTrue(
            messages.descendants(matching: .any)["uls.games.section.active"]
                .firstMatch.waitForExistence(timeout: 4)
        )
        XCTAssertTrue(
            messages.descendants(matching: .any)["uls.games.section.finished"]
                .firstMatch.waitForExistence(timeout: 4)
        )

        let actionMenus = messages.buttons.matching(
            NSPredicate(format: "label BEGINSWITH %@", "Actions for")
        )
        XCTAssertGreaterThanOrEqual(actionMenus.count, 2)
        let finishedActions = messages.buttons.matching(
            NSPredicate(
                format: "label BEGINSWITH %@ AND label CONTAINS %@",
                "Actions for",
                "won"
            )
        ).firstMatch
        XCTAssertTrue(finishedActions.waitForExistence(timeout: 4))
        finishedActions.tap()
        let archive = messages.buttons["Archive"].firstMatch
        XCTAssertTrue(archive.waitForExistence(timeout: 4))
        archive.tap()
        XCTAssertFalse(finishedActions.exists)
        XCTAssertTrue(
            messages.descendants(matching: .any)["uls.games.section.active"]
                .firstMatch.waitForExistence(timeout: 4)
        )

        messages.buttons["Back"].firstMatch.tap()
        loadRecoveryGamesSlice()
        openGamesLibraryFromCurrentSurface()
        XCTAssertGreaterThanOrEqual(
            messages.buttons.matching(
                NSPredicate(format: "label BEGINSWITH %@", "Actions for")
            ).count,
            2,
            "A later valid recovery fixture should restore a locally archived game."
        )
    }

    func testGameplayRecoveryMessagesRelaunchRestoresSavedGames() throws {
        try XCTSkipIf(true, "Superseded: relaunch proof now requires read-only Player Record and real-bubble continuation.")
        openUnluckySevensExtension()
        loadRecoveryGamesSlice()
        let beforeFingerprint = canonicalRecoveryFingerprint(
            from: gameplayActionEvidenceValue()
        )
        let beforeBoardHost = messages.descendants(matching: .any)[
            "uls.tabletop.boardHost"
        ].firstMatch
        XCTAssertTrue(beforeBoardHost.waitForExistence(timeout: 4))
        XCTAssertFalse(
            boardMountIdentity(of: beforeBoardHost).isEmpty,
            "The recovered game must begin with a mounted SpriteKit board."
        )
        let beforeBoardFrame = beforeBoardHost.frame
        openGamesLibraryFromCurrentSurface()

        let beforeRows = messages.buttons.matching(
            NSPredicate(format: "label BEGINSWITH %@", "Actions for")
        )
        XCTAssertGreaterThanOrEqual(beforeRows.count, 2)
        let beforeLabels = (0..<beforeRows.count).map { beforeRows.element(boundBy: $0).label }.sorted()
        XCTAssertTrue(beforeLabels.contains { $0.localizedCaseInsensitiveContains("won") })
        attachScreenshot(named: "Gameplay Recovery - Saved Games Before Messages Relaunch")

        messages.terminate()
        reopenUnluckySevensAfterMessagesTermination()
        hideUXLabChromeWithoutChangingFixture()
        openGamesLibraryFromCurrentSurface()

        let afterRows = messages.buttons.matching(
            NSPredicate(format: "label BEGINSWITH %@", "Actions for")
        )
        XCTAssertGreaterThanOrEqual(afterRows.count, 2)
        let afterLabels = (0..<afterRows.count).map { afterRows.element(boundBy: $0).label }.sorted()
        XCTAssertEqual(afterLabels, beforeLabels, "Messages relaunch must restore the same saved canonical games.")

        openRecoveredGameFromLibrary(
            gameID: "ux-recovery-active",
            visibleSubtitle: "Kunal's turn"
        )
        XCTAssertEqual(
            canonicalRecoveryFingerprint(from: gameplayActionEvidenceValue()),
            beforeFingerprint,
            "Messages relaunch must restore the exact canonical game revision and hash."
        )
        let afterBoardHost = messages.descendants(matching: .any)[
            "uls.tabletop.boardHost"
        ].firstMatch
        XCTAssertTrue(afterBoardHost.waitForExistence(timeout: 4))
        XCTAssertFalse(
            boardMountIdentity(of: afterBoardHost).isEmpty,
            "The restored game must remount its live SpriteKit board."
        )
        assertFrame(
            of: afterBoardHost,
            matches: beforeBoardFrame,
            message: "The restored tabletop must keep the settled board frame."
        )
        XCTAssertFalse(
            messages.descendants(matching: .any)["uls.physicalTrade.composerPanel"].firstMatch.exists,
            "A process relaunch must not restore an interrupted transient Trade composer."
        )
        XCTAssertFalse(
            messages.descendants(matching: .any)["uls.turn.endConfirmation"].firstMatch.exists,
            "A process relaunch must not restore a transient end-turn confirmation."
        )
        attachScreenshot(named: "Gameplay Recovery - Saved Games Restored After Messages Relaunch")
    }

    func testDrawerRelaunchStartsFreshLobbyWithoutDiscardingSavedGames() throws {
        openUnluckySevensExtension()
        loadRecoveryGamesSlice()

        messages.terminate()
        reopenUnluckySevensAfterMessagesTermination(automaticallyOpensCompactLaunch: false)

        let compactLaunch = messages.descendants(matching: .any)[
            "uls.compactLaunch"
        ].firstMatch
        XCTAssertTrue(
            compactLaunch.waitForExistence(timeout: 8),
            "Fresh app-drawer entry must present the compact robber entrance."
        )

        let skip = messages.buttons["uls.compactLaunch.skip"].firstMatch
        if skip.exists {
            skip.tap()
        }

        XCTAssertTrue(
            waitForCompactLaunchPhase("landed", timeout: 4),
            "Skip or the natural animation must leave the robber settled on Open Lobby."
        )
        attachScreenshot(named: "Drawer Relaunch - Compact Robber Entrance")

        let openLobby = messages.buttons["uls.compactLaunch.openLobby"].firstMatch
        XCTAssertTrue(openLobby.waitForExistence(timeout: 4))
        openLobby.tap()

        let inviteTitle = exactLabelElement("Invite Friends to Table", timeout: 8)
        XCTAssertTrue(inviteTitle.exists, "Open Lobby must reveal the fresh invitation lobby.")
        let freshLobbyEvidence = gameplayActionEvidenceValue()
        XCTAssertTrue(
            freshLobbyEvidence.contains("game=-") && freshLobbyEvidence.contains("phase=-"),
            "A locally saved game must not become the active canonical context on drawer entry."
        )
        attachScreenshot(named: "Drawer Relaunch - Fresh Invitation Lobby")

        openGamesLibraryFromCurrentSurface()
        XCTAssertGreaterThanOrEqual(
            messages.buttons.matching(
                NSPredicate(format: "label BEGINSWITH %@", "Actions for")
            ).count,
            2,
            "Fresh drawer entry must not discard games that remain available through Your Games."
        )
        attachScreenshot(named: "Drawer Relaunch - Saved Games Preserved")
    }

    func testRecoveryResendAndResignationContinuesJourney() throws {
        try XCTSkipIf(true, "Superseded: saved records cannot resend or resign; lifecycle actions moved to current Game Information.")
        openUnluckySevensExtension()
        loadRecoveryGamesSlice()

        openGamesLibraryFromCurrentSurface()

        let activeActions = messages.buttons.matching(
            NSPredicate(format: "label BEGINSWITH %@", "Actions for")
        ).firstMatch
        XCTAssertTrue(activeActions.waitForExistence(timeout: 4))
        activeActions.tap()
        let resend = messages.buttons["Resend Latest State"].firstMatch
        XCTAssertTrue(resend.waitForExistence(timeout: 4))
        resend.tap()
        XCTAssertTrue(
            messages.descendants(matching: .any)["uls.games.library"]
                .firstMatch.waitForExistence(timeout: 4),
            "Resending must keep the Games library and unchanged game available."
        )

        XCTAssertTrue(activeActions.waitForExistence(timeout: 4))
        activeActions.tap()
        let resign = messages.buttons["Resign"].firstMatch
        XCTAssertTrue(waitForHittable(resign, timeout: 4))
        resign.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()

        let confirmation = firstExistingElement(
            [
                messages.descendants(matching: .any)["uls.games.lifecycleConfirmation"].firstMatch,
                messages.staticTexts["Resign from this game?"].firstMatch,
            ],
            timeout: 4
        )
        XCTAssertTrue(confirmation.exists)
        XCTAssertTrue(
            messages.staticTexts[
                "You will leave active play. Your pieces stay on the board, and the remaining players continue."
            ].exists
        )
        attachScreenshot(named: "Recovery - Resign Confirmation")
        let confirmResign = messages.buttons["Resign"].firstMatch
        XCTAssertTrue(waitForHittable(confirmResign, timeout: 4))
        tapCurrentFrame(of: confirmResign)
        let activeRow = messages.buttons.matching(
            NSPredicate(format: "label CONTAINS %@", "Kunal resigned")
        ).firstMatch
        XCTAssertTrue(activeRow.waitForExistence(timeout: 8))
        XCTAssertTrue(activeRow.label.contains("Kunal resigned"))
        XCTAssertFalse(
            turnElement(identifier: "uls.endScreen", labels: []).exists,
            "Resignation must not end the game for the remaining players."
        )
    }

    func testRecoveryGamesLibraryUsesDedicatedSurface() throws {
        openUnluckySevensExtension()
        openUXLabPanel()
        activateDirectCleanState(
            identifier: "uls.uxLab.recoveryGames.direct",
            label: "Recovery Games"
        )
        collapseUXLabPanelIfExpanded()

        openGamesLibraryFromCurrentSurface()
        let library = messages.descendants(matching: .any)["uls.playerRecord"].firstMatch
        XCTAssertTrue(library.waitForExistence(timeout: 4))
        let title = messages.staticTexts["Player Record"].firstMatch
        let back = messages.buttons["Back"].firstMatch
        XCTAssertTrue(title.exists)
        XCTAssertTrue(back.exists)
        XCTAssertEqual(title.frame.midX, messages.frame.midX, accuracy: 3)
        XCTAssertEqual(title.frame.midY, back.frame.midY, accuracy: 4)
        XCTAssertTrue(messages.descendants(matching: .any)["uls.playerRecord.stats"].firstMatch.exists)
        XCTAssertFalse(messages.buttons["Open"].firstMatch.exists)
        XCTAssertFalse(messages.buttons["Reconnect to Chat"].firstMatch.exists)
        XCTAssertFalse(messages.buttons["Resend Latest State"].firstMatch.exists)
        attachScreenshot(named: "Player Record - Catan Stats")

        let swipeStart = messages.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.76))
        let swipeEnd = messages.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.30))
        swipeStart.press(forDuration: 0.05, thenDragTo: swipeEnd)
        XCTAssertTrue(
            messages.descendants(matching: .any)["uls.playerRecord.honors"].firstMatch
                .waitForExistence(timeout: 3)
        )
        XCTAssertTrue(
            messages.descendants(matching: .any)["uls.playerRecord.recentGames"].firstMatch
                .waitForExistence(timeout: 3)
        )
        attachScreenshot(named: "Player Record - Honors and Group")
    }

    func testInlineGamesCanOpenRecoveredGame() throws {
        try XCTSkipIf(true, "Superseded: Game Information links to Player Record and records cannot open games.")
        openUnluckySevensExtension()
        openUXLabPanel()
        activateDirectCleanState(
            identifier: "uls.uxLab.recoveryGames.direct",
            label: "Recovery Games"
        )
        collapseUXLabPanelIfExpanded()

        openInlineGamesFromCurrentSurface()

        let nonCurrentGame = messages.buttons.matching(
            NSPredicate(
                format: "identifier BEGINSWITH %@ AND NOT label CONTAINS[c] %@",
                "uls.gameInfo.open.",
                "Current game"
            )
        ).firstMatch
        XCTAssertTrue(nonCurrentGame.waitForExistence(timeout: 4))
        assertMinimumTarget(
            nonCurrentGame,
            message: "Every inline saved-game row must preserve a 44-point target."
        )
        let openedGameIdentifier = nonCurrentGame.identifier
        nonCurrentGame.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()

        let gameInfoSurface = turnElement(identifier: "uls.turn.gameInfo", labels: [])
        XCTAssertTrue(
            gameInfoSurface.waitForNonExistence(timeout: 4),
            "Opening a recovered game must close the inline Game Information panel."
        )

        let recoveredEndScreen = turnElement(identifier: "uls.endScreen", labels: [])
        if recoveredEndScreen.waitForExistence(timeout: 4) {
            XCTAssertTrue(
                messages.staticTexts["Victory!"].firstMatch.exists,
                "Opening a finished recovered game must show its production victory surface."
            )
            return
        }

        openInlineGamesFromCurrentSurface()

        let openedGame = messages.buttons[openedGameIdentifier].firstMatch
        XCTAssertTrue(openedGame.waitForExistence(timeout: 4))
        XCTAssertTrue(
            openedGame.label.localizedCaseInsensitiveContains("Current game"),
            "The opened inline game must become the current selection."
        )
    }

    func testRecoveryResignConfirmationExplainsContinuedPlay() throws {
        try XCTSkipIf(true, "Superseded by current-game Game Information lifecycle proof.")
        openUnluckySevensExtension()
        openUXLabPanel()
        activateDirectCleanState(
            identifier: "uls.uxLab.recoveryGames.direct",
            label: "Recovery Games"
        )
        collapseUXLabPanelIfExpanded()

        openGamesLibraryFromCurrentSurface()
        let activeActions = messages.buttons.matching(
            NSPredicate(format: "label BEGINSWITH %@", "Actions for")
        ).firstMatch
        XCTAssertTrue(activeActions.waitForExistence(timeout: 4))
        activeActions.tap()
        let resign = messages.buttons["Resign"].firstMatch
        XCTAssertTrue(resign.waitForExistence(timeout: 4))
        resign.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()

        let keepPlaying = messages.buttons["uls.games.keepPlaying"].firstMatch
        XCTAssertTrue(keepPlaying.waitForExistence(timeout: 4))
        XCTAssertTrue(messages.buttons["uls.games.confirmResign"].firstMatch.exists)
        XCTAssertTrue(
            messages.staticTexts[
                "You will leave active play. Your pieces stay on the board, and the remaining players continue."
            ].exists
        )
        attachScreenshot(named: "Recovery - Resign Confirmation")
        keepPlaying.tap()
        let activeActionsAfterCancel = messages.buttons.matching(
            NSPredicate(format: "label BEGINSWITH %@", "Actions for")
        ).firstMatch
        XCTAssertTrue(
            activeActionsAfterCancel.waitForExistence(timeout: 4),
            "Keeping play active must leave the recovered game in the library."
        )
    }

    func testHostEndOffersDrawBeforeUnilateralEnd() throws {
        try XCTSkipIf(true, "Superseded by current-game Game Information lifecycle proof.")
        openUnluckySevensExtension()
        openUXLabPanel()
        activateDirectCleanState(
            identifier: "uls.uxLab.recoveryGames.direct",
            label: "Recovery Games"
        )
        collapseUXLabPanelIfExpanded()

        openGamesLibraryFromCurrentSurface()
        let activeActions = messages.buttons.matching(
            NSPredicate(format: "label BEGINSWITH %@", "Actions for")
        ).firstMatch
        XCTAssertTrue(activeActions.waitForExistence(timeout: 4))
        activeActions.tap()
        let endGame = messages.buttons["End Game"].firstMatch
        XCTAssertTrue(waitForHittable(endGame, timeout: 4))
        endGame.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()

        let proposeDraw = messages.buttons["uls.games.proposeDraw"].firstMatch
        XCTAssertTrue(proposeDraw.waitForExistence(timeout: 4))
        XCTAssertTrue(messages.buttons["uls.games.endAnyway"].firstMatch.exists)
        attachScreenshot(named: "Recovery - Host End Decision")

        let endAnyway = messages.buttons["uls.games.endAnyway"].firstMatch
        XCTAssertTrue(waitForHittable(endAnyway, timeout: 4))
        endAnyway.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        let endScreen = messages.descendants(matching: .any)["uls.endScreen"].firstMatch
        let endEvidence = firstExistingElement(
            [
                endScreen,
                messages.staticTexts["Game ended"].firstMatch,
                messages.staticTexts["Game Ended"].firstMatch,
                messages.staticTexts.matching(
                    NSPredicate(format: "label CONTAINS[c] %@", "ended the game")
                ).firstMatch,
            ],
            timeout: 8
        )
        XCTAssertTrue(endEvidence.exists, "Ending anyway must produce the terminal screen or outgoing host-end receipt.")
        if endScreen.exists {
            XCTAssertFalse(
                messages.staticTexts["0 points"].firstMatch.exists,
                "A neutral host end must not invent a winning score."
            )
        }
        attachScreenshot(named: "Recovery - Neutral Host End")
    }

    func testHostEndCanProposeDrawFromNativeConfirmation() throws {
        try XCTSkipIf(true, "Superseded by current-game Game Information lifecycle proof.")
        openUnluckySevensExtension()
        openUXLabPanel()
        activateDirectCleanState(
            identifier: "uls.uxLab.recoveryGames.direct",
            label: "Recovery Games"
        )
        collapseUXLabPanelIfExpanded()

        openGamesLibraryFromCurrentSurface()
        let activeActions = messages.buttons.matching(
            NSPredicate(format: "label BEGINSWITH %@", "Actions for")
        ).firstMatch
        XCTAssertTrue(activeActions.waitForExistence(timeout: 4))
        activeActions.tap()
        let endGame = messages.buttons["End Game"].firstMatch
        XCTAssertTrue(waitForHittable(endGame, timeout: 4))
        endGame.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()

        let confirmation = messages.descendants(matching: .any)[
            "uls.games.lifecycleConfirmation"
        ].firstMatch
        XCTAssertTrue(confirmation.waitForExistence(timeout: 4))
        let proposeDraw = messages.buttons["uls.games.proposeDraw"].firstMatch
        XCTAssertTrue(waitForHittable(proposeDraw, timeout: 4))
        proposeDraw.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        attachScreenshot(named: "Recovery - Draw Proposal Result")

        let drawReceipt = firstExistingElement(
            [
                messages.staticTexts.matching(
                    NSPredicate(format: "label BEGINSWITH %@", "Draw proposed by")
                ).firstMatch,
                messages.staticTexts["Draw Proposed"].firstMatch,
                messages.staticTexts.matching(
                    NSPredicate(format: "label CONTAINS[c] %@", "proposed a draw")
                ).firstMatch,
            ],
            timeout: 8
        )
        XCTAssertTrue(
            drawReceipt.exists,
            "Proposing a draw must produce the updated game summary or outgoing draw receipt."
        )
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
        let replaceOffer = messages.buttons["Replace Offer"].firstMatch
        XCTAssertTrue(
            waitForHittable(replaceOffer, timeout: 4),
            "Pending Trade must keep Replace Offer pinned and reachable."
        )
        XCTAssertTrue(tradeButton.isSelected)
        attachScreenshot(named: "Physical Trade Correction - Pending Offer")
        replaceOffer.tap()
        XCTAssertTrue(
            turnElement(
                identifier: "uls.physicalTrade.composerPanel",
                labels: ["Player Trade"]
            )
            .waitForExistence(timeout: 4)
        )
    }

    func testCapturePendingTradeBannerPolish() throws {
        openUnluckySevensExtension()
        waitForUXLabChrome()
        loadNotPrimaryOfferSlice()
        hideUXLabChromeWithoutChangingFixture()

        let pendingBanner = turnElement(
            identifier: "uls.trade.pendingBanner",
            labels: ["Maya offers 2 sheep for 1 ore · 2 players"]
        )
        XCTAssertTrue(waitForHittable(pendingBanner, timeout: 6))
        attachScreenshot(named: "Physical Trade Correction - Pending Strip")

        pendingBanner.tap()
        XCTAssertTrue(
            waitForHittable(messages.buttons["Accept"].firstMatch, timeout: 4),
            "The integrated pending-trade strip must still open the incoming offer."
        )
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
            turnElement(identifier: "uls.physicalProps.hand", labels: ["Hand"])
                .waitForExistence(timeout: 8),
            "Expected the turn gameplay fixture to render."
        )
        collapseUXLabPanelIfExpanded()
        let handButton = turnElement(identifier: "uls.physicalProps.hand", labels: ["Hand"])
        XCTAssertTrue(handButton.waitForExistence(timeout: 4))
        handButton.tap()

        XCTAssertTrue(
            messages.descendants(matching: .any)
                .matching(identifier: "uls.physicalProps.handContents")
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

    func testOpenMessagesExtensionAndCapturePhysicalPropsRoundFour() throws {
        openUnluckySevensExtension()
        openUXLabPanel()
        loadTabletopComparison(
            identifier: "uls.uxLab.cleanShot.tabletopPhysicalProps",
            label: "Physical props comparison"
        )

        let handButton = turnElement(identifier: "uls.physicalProps.hand", labels: ["Hand"])
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
        if !devChooser.waitForExistence(timeout: 2), ownedDevCards.exists {
            ownedDevCards.tap()
        }
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

        let handButton = turnElement(identifier: "uls.physicalProps.hand", labels: ["Hand"])
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

    private func openUnluckySevensExtension(
        automaticallyOpensCompactLaunch: Bool = true
    ) {
        messages.launch()
        handleFirstRunPrompts()
        openExistingConversation()
        if !waitForUnluckySevensSurface(timeout: 3) {
            openMessagesAppDrawer()
            openUnluckySevensFromDrawer()
        }
        XCTAssertTrue(
            waitForUnluckySevensSurface(timeout: 8),
            "Expected Unlucky Sevens after resolving the current Messages state."
        )

        if automaticallyOpensCompactLaunch {
            let openLobby = messages.buttons["uls.compactLaunch.openLobby"].firstMatch
            if openLobby.waitForExistence(timeout: 1) {
                openLobby.tap()
                XCTAssertTrue(
                    openLobby.waitForNonExistence(timeout: 8),
                    "Open Lobby must dismiss the compact launch gate."
                )
            }
        }
        dismissPersistedUtilitySurfaces()
    }

    private func reopenUnluckySevensAfterMessagesTermination(
        automaticallyOpensCompactLaunch: Bool = true
    ) {
        openUnluckySevensExtension(
            automaticallyOpensCompactLaunch: automaticallyOpensCompactLaunch
        )
    }

    private func gameplayActionEvidenceValue(timeout: TimeInterval = 4) -> String {
        let evidence = messages.descendants(matching: .any)[
            "uls.gameplay.actionEvidence"
        ].firstMatch
        XCTAssertTrue(
            evidence.waitForExistence(timeout: timeout),
            "Expected DEBUG gameplay action evidence."
        )
        return evidence.value as? String ?? ""
    }

    private func canonicalRecoveryFingerprint(from evidence: String) -> String {
        var fields: [String: String] = [:]
        for component in evidence.split(separator: ";") {
            let pair = component.split(separator: "=", maxSplits: 1).map(String.init)
            guard pair.count == 2 else { continue }
            fields[pair[0]] = pair[1]
        }

        let requiredKeys = ["game", "rev", "phase", "hash"]
        for key in requiredKeys {
            XCTAssertNotNil(fields[key], "Recovery evidence is missing \(key): \(evidence)")
        }
        return requiredKeys.map { "\($0)=\(fields[$0] ?? "-")" }.joined(separator: ";")
    }

    private func waitForGameplayActionEvidence(
        containing expectedText: String,
        timeout: TimeInterval
    ) -> String {
        let evidence = messages.descendants(matching: .any)[
            "uls.gameplay.actionEvidence"
        ].firstMatch
        XCTAssertTrue(evidence.waitForExistence(timeout: timeout))
        let predicate = NSPredicate(format: "value CONTAINS %@", expectedText)
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: evidence)
        XCTAssertEqual(
            XCTWaiter.wait(for: [expectation], timeout: timeout),
            .completed,
            "Expected gameplay fixture evidence containing \(expectedText)."
        )
        return evidence.value as? String ?? ""
    }

    private func openCanonicalPostRollActionFixture() {
        openUnluckySevensExtension()
        loadDirectGameplayActionFixture(
            identifier: "uls.uxLab.cleanShot.endTurnAction.direct",
            label: "Clean end turn action"
        )
        _ = waitForGameplayActionEvidence(
            containing: "status=UX Lab loaded End turn action",
            timeout: 6
        )
    }

    private func loadDirectGameplayActionFixture(identifier: String, label: String) {
        waitForUXLabChrome()
        openUXLabPanel()
        activateDirectCleanState(identifier: identifier, label: label)
    }

    private struct BoardTargetCoordinate {
        let boardHost: XCUIElement
        let identifier: Int
        let normalizedOffset: CGVector
    }

    private func boardTargetCoordinate(
        kind: String,
        timeout: TimeInterval
    ) throws -> BoardTargetCoordinate? {
        let boardHost = messages.descendants(matching: .any)["uls.tabletop.boardHost"].firstMatch
        guard boardHost.waitForExistence(timeout: timeout) else {
            return nil
        }

        let deadline = Date().addingTimeInterval(timeout)
        repeat {
            let diagnostic = boardHost.value as? String ?? ""
            let prefix = "target.\(kind)="
            if let field = diagnostic
                .split(separator: ";")
                .map(String.init)
                .first(where: { $0.hasPrefix(prefix) }) {
                let components = field.dropFirst(prefix.count).split(separator: ",")
                if components.count == 3,
                   let identifier = Int(components[0]),
                   let x = Double(components[1]),
                   let y = Double(components[2]) {
                    let normalizedOffset = CGVector(dx: x, dy: y)
                    XCTAssertTrue((0...1).contains(x), "Board target x must be normalized: \(field)")
                    XCTAssertTrue((0...1).contains(y), "Board target y must be normalized: \(field)")
                    return BoardTargetCoordinate(
                        boardHost: boardHost,
                        identifier: identifier,
                        normalizedOffset: normalizedOffset
                    )
                }
                XCTFail("Malformed \(kind) target in board diagnostic: \(field)")
                return nil
            }

            RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        } while Date() < deadline

        return nil
    }

    private func tapBoardTarget(_ target: BoardTargetCoordinate) {
        target.boardHost.coordinate(withNormalizedOffset: target.normalizedOffset).tap()
    }

    private func tapFirstBoardTarget(kind: String, requiresConfirmation: Bool) throws {
        let target = try XCTUnwrap(
            boardTargetCoordinate(kind: kind, timeout: 5),
            "Expected a legal \(kind) board target in the live board diagnostic."
        )
        tapBoardTarget(target)

        guard requiresConfirmation else { return }
        XCTAssertTrue(target.boardHost.waitForExistence(timeout: 4))
        tapBoardTarget(target)
    }

    private func chooseBuildAction(identifier: String) {
        let build = turnElement(identifier: "uls.turnObject.build", labels: ["Build"])
        XCTAssertTrue(build.waitForExistence(timeout: 5))
        build.tap()

        let labelPrefix: String
        switch identifier {
        case "uls.physicalProps.build.buildRoad":
            labelPrefix = "Road,"
        case "uls.physicalProps.build.buildSettlement":
            labelPrefix = "Settlement,"
        case "uls.physicalProps.build.buildCity":
            labelPrefix = "City,"
        default:
            XCTFail("Unknown build choice \(identifier).")
            return
        }

        let choice = messages.buttons
            .matching(identifier: "uls.physicalProps.buildSpread")
            .matching(NSPredicate(format: "label BEGINSWITH %@", labelPrefix))
            .firstMatch
        XCTAssertTrue(choice.waitForExistence(timeout: 4), "Expected build choice \(labelPrefix).")
        XCTAssertTrue(choice.isEnabled)
        choice.tap()
    }

    private func openPlayableDevCard(identifier: String) {
        let hand = turnElement(identifier: "uls.physicalProps.hand", labels: ["Hand"])
        XCTAssertTrue(hand.waitForExistence(timeout: 5))
        let actionSpread = messages.descendants(matching: .any)[
            "uls.physicalProps.actionSpread"
        ].firstMatch
        let handIsAlreadyOpen = actionSpread.exists
            && (actionSpread.value as? String) == "Hand"
        if !handIsAlreadyOpen {
            tapCurrentFrame(of: hand)
        }
        XCTAssertTrue(actionSpread.waitForExistence(timeout: 4))
        XCTAssertEqual(actionSpread.value as? String, "Hand")
        let ownedCards = turnElement(
            identifier: "uls.physicalProps.ownedDevCards",
            labels: ["Owned Dev Cards"]
        )
        XCTAssertTrue(ownedCards.waitForExistence(timeout: 4))
        ownedCards.tap()

        let visibleTitle: String
        switch identifier {
        case "uls.physicalProps.devCard.knight":
            visibleTitle = "Knight"
        case "uls.physicalProps.devCard.monopoly":
            visibleTitle = "Monopoly"
        case "uls.physicalProps.devCard.yearOfPlenty":
            visibleTitle = "Year of"
        case "uls.physicalProps.devCard.roadBuilding":
            visibleTitle = "Road"
        case "uls.physicalProps.devCard.victoryPoint":
            visibleTitle = "Victory"
        default:
            XCTFail("Unknown playable Dev Card \(identifier).")
            return
        }

        let cardTitle = messages.staticTexts[visibleTitle].firstMatch
        XCTAssertTrue(cardTitle.waitForExistence(timeout: 4), "Expected playable Dev Card \(visibleTitle).")
        tapCurrentFrame(of: cardTitle)
    }

    private func selectDevResource(prefix: String) {
        let resource = messages.buttons
            .matching(NSPredicate(format: "label BEGINSWITH %@", prefix))
            .firstMatch
        XCTAssertTrue(resource.waitForExistence(timeout: 4), "Expected Dev Card resource \(prefix).")
        XCTAssertTrue(resource.isEnabled)
        resource.tap()
    }

    private func confirmDevResourceSelection() {
        let confirm = messages.buttons["uls.physicalProps.devResourceConfirm"].firstMatch
        XCTAssertTrue(confirm.waitForExistence(timeout: 4))
        XCTAssertTrue(confirm.isEnabled)
        confirm.tap()
    }

    private func evidenceField(_ field: String, in evidence: String) -> String? {
        evidence.split(separator: ";")
            .map(String.init)
            .first { $0.hasPrefix("\(field)=") }?
            .dropFirst(field.count + 1)
            .description
    }

    private func waitForGameplayActionEvidenceChange(
        from previousValue: String,
        timeout: TimeInterval
    ) -> String {
        let evidence = messages.descendants(matching: .any)[
            "uls.gameplay.actionEvidence"
        ].firstMatch
        let predicate = NSPredicate(format: "value != %@", previousValue)
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: evidence)
        XCTAssertEqual(
            XCTWaiter.wait(for: [expectation], timeout: timeout),
            .completed,
            "Expected the canonical gameplay evidence to change."
        )
        return evidence.value as? String ?? ""
    }

    private func attachGameplayActionEvidence(
        name: String,
        before: String,
        after: String
    ) {
        let attachment = XCTAttachment(
            string: "before:\n\(before)\n\nafter:\n\(after)"
        )
        attachment.name = "Gameplay Action - \(name)"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func dismissPersistedUtilitySurfaces() {
        let lifecycleConfirmation = messages.descendants(matching: .any)[
            "uls.games.lifecycleConfirmation"
        ].firstMatch
        if lifecycleConfirmation.waitForExistence(timeout: 0.2) {
            lifecycleConfirmation.buttons["uls.games.keepPlaying"].firstMatch.tap()
        }

        let library = messages.descendants(matching: .any)["uls.games.library"].firstMatch
        if library.exists {
            messages.buttons["Back"].firstMatch.tap()
        }
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

        focusMessageComposer()
        // Messages can preserve a photo-only `+` state or ignore the first
        // drawer tap while the composer is settling. Re-focus and re-query
        // controls between bounded attempts; never retain a stale XCUIElement.
        for attempt in 0..<4 {
            tapMessagesDrawerButton()
            if waitForFullMessagesAppDrawer(timeout: attempt == 0 ? 3 : 4) {
                return
            }
            focusMessageComposer()
        }

        XCTFail("Expected the complete Messages apps drawer to open.")
    }

    private func focusMessageComposer() {
        let messageField = firstExistingElement(
            [
                messages.textFields["messageBodyField"].firstMatch,
                messages.textFields["Message"].firstMatch,
                messages.textViews["messageBodyField"].firstMatch,
                messages.textViews["Message"].firstMatch,
            ],
            timeout: 2
        )
        if messageField.exists {
            messageField.tap()
        }
    }

    private func tapMessagesDrawerButton() {
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

    private func waitForFullMessagesAppDrawer(timeout: TimeInterval) -> Bool {
        if messages.staticTexts["Unlucky Sevens"].firstMatch.waitForExistence(timeout: timeout) {
            return true
        }

        let knownFullDrawerEntries = [
            "Stickers",
            "Apple Cash",
            "Audio",
            "#images",
            "Digital Touch",
            "Memoji",
        ]
        return knownFullDrawerEntries.contains { label in
            messages.staticTexts[label].firstMatch.exists
                || messages.buttons[label].firstMatch.exists
        }
    }

    private func openUnluckySevensFromDrawer() {
        if waitForUnluckySevensSurface(timeout: 2) {
            return
        }

        for launchAttempt in 0..<3 {
            if waitForUnluckySevensSurface(timeout: 1) {
                return
            }
            let appsDrawer = messages.collectionViews
                .containing(.staticText, identifier: "Stickers")
                .firstMatch
            XCTAssertTrue(
                appsDrawer.waitForExistence(timeout: 3),
                "Expected the complete Messages apps drawer collection."
            )

            for _ in 0..<8 {
                let appRow = firstExistingElement(
                    [
                        messages.staticTexts["Unlucky Sevens"].firstMatch,
                        messages.buttons["Unlucky Sevens"].firstMatch,
                        messages.descendants(matching: .any)["Unlucky Sevens"].firstMatch,
                    ],
                    timeout: 1
                )
                if appRow.exists {
                    tapCurrentFrame(of: appRow)
                    if waitForUnluckySevensSurface(timeout: 10) {
                        return
                    }
                    break
                }

                appsDrawer.swipeUp()
            }

            guard launchAttempt < 2 else { break }
            focusMessageComposer()
            tapMessagesDrawerButton()
            XCTAssertTrue(
                waitForFullMessagesAppDrawer(timeout: 5),
                "Expected the Messages apps drawer to reopen after an extension launch stall."
            )
        }

        XCTFail("Unlucky Sevens did not finish loading from the Messages app drawer.")
    }

    private func waitForUnluckySevensSurface(timeout: TimeInterval) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        repeat {
            if waitForInviteSlice(timeout: 0.2)
                || messages.descendants(matching: .any)["uls.compactLaunch"].firstMatch.exists
                || messages.buttons["uls.uxLab.toggle"].firstMatch.exists
                || messages.buttons["uls.uxLab.restoreChrome"].firstMatch.exists
                || messages.descendants(matching: .any)["uls.gameplay.actionEvidence"].firstMatch.exists
                || messages.descendants(matching: .any)["uls.host.usableCanvas"].firstMatch.exists
                || messages.descendants(matching: .any)["uls.games.library"].firstMatch.exists
            {
                return true
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.2))
        } while Date() < deadline
        return false
    }

    private func waitForCompactLaunchPhase(
        _ expectedPhase: String,
        timeout: TimeInterval
    ) -> Bool {
        let launch = messages.descendants(matching: .any)["uls.compactLaunch"].firstMatch
        let deadline = Date().addingTimeInterval(timeout)
        repeat {
            if launch.exists, launch.value as? String == expectedPhase {
                return true
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        } while Date() < deadline
        return false
    }

    private func openUXLabPanel() {
        let existingPanel = messages.descendants(matching: .any)["uls.uxLab.panel"].firstMatch
        if existingPanel.exists {
            return
        }

        let toggle = waitForUXLabChrome()
        toggle.tap()

        var panelSignal = firstExistingElement(
            [
                messages.staticTexts["Single-device UX Lab"].firstMatch,
                messages.buttons["uls.uxLab.load"].firstMatch,
                messages.buttons["Load"].firstMatch,
            ],
            timeout: 4
        )
        if !panelSignal.exists, toggle.exists {
            toggle.tap()
            panelSignal = firstExistingElement(
                [
                    messages.staticTexts["Single-device UX Lab"].firstMatch,
                    messages.buttons["uls.uxLab.load"].firstMatch,
                    messages.buttons["Load"].firstMatch,
                ],
                timeout: 4
            )
        }
        XCTAssertTrue(panelSignal.exists, "Expected the UX Lab panel to open.")
    }

    @discardableResult
    private func waitForUXLabChrome() -> XCUIElement {
        let restoreChrome = messages.buttons["uls.uxLab.restoreChrome"].firstMatch
        if restoreChrome.waitForExistence(timeout: 1) {
            restoreChrome.tap()
        }

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
        openUXLabPanel()
        activateDirectCleanState(
            identifier: "uls.uxLab.cleanShot.header.turnAfterRoll",
            label: "Clean turn screenshot"
        )
    }

    private func loadEndScreenSlice() {
        openUXLabPanel()
        let endControl = firstExistingElement(
            [
                messages.buttons["uls.uxLab.cleanShot.gameOver.direct"].firstMatch,
                messages.descendants(matching: .any)[
                    "uls.uxLab.cleanShot.gameOver.direct"
                ].firstMatch,
                messages.buttons["Clean end screen"].firstMatch,
                messages.descendants(matching: .any)["Clean end screen"].firstMatch,
            ],
            timeout: 4
        )
        XCTAssertTrue(endControl.exists, "Expected the UX Lab End state to be available.")
        tapCurrentFrame(of: endControl)
    }

    private func loadRecoveryGamesSlice() {
        openUXLabPanel()
        activateDirectCleanState(
            identifier: "uls.uxLab.recoveryGames.direct",
            label: "Recovery Games"
        )
        XCTAssertTrue(
            messages.descendants(matching: .any)["uls.uxLab.panel"]
                .firstMatch.waitForNonExistence(timeout: 4),
            "Recovery navigation must begin after the DEBUG UX Lab stops intercepting production controls."
        )
    }

    private func hideUXLabChromeWithoutChangingFixture() {
        let panel = messages.descendants(matching: .any)["uls.uxLab.panel"].firstMatch
        if !panel.exists {
            return
        }

        let hideChrome = firstExistingElement(
            [
                messages.buttons["uls.uxLab.hideChrome"].firstMatch,
                messages.descendants(matching: .any)["uls.uxLab.hideChrome"].firstMatch,
            ],
            timeout: 4
        )
        XCTAssertTrue(
            hideChrome.exists,
            "Expected a DEBUG-only control that hides UX Lab chrome without reseeding persisted games."
        )
        tapCurrentFrame(of: hideChrome)
        XCTAssertTrue(
            panel.waitForNonExistence(timeout: 4),
            "UX Lab must stop intercepting production controls after Messages relaunch."
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
        if waitForHittable(directButton, timeout: 1) {
            directButton.tap()
            if !directButton.waitForNonExistence(timeout: 2), waitForHittable(directButton, timeout: 1) {
                directButton.tap()
            }
            return
        }

        openUXLabPanel()
        let panelButton = messages.buttons[identifier].firstMatch
        if waitForHittable(panelButton, timeout: 2) {
            panelButton.tap()
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
        if !menuItem.waitForNonExistence(timeout: 2), waitForHittable(menuItem, timeout: 1) {
            menuItem.tap()
        }
    }

    private func activateUXLabNestedQuickState(
        title: String,
        identifier: String
    ) {
        let directControl = messages.buttons[identifier].firstMatch
        if directControl.waitForExistence(timeout: 1) {
            directControl.tap()
            return
        }

        openUXLabPanel()
        let panelControl = messages.buttons[identifier].firstMatch
        if waitForHittable(panelControl, timeout: 2) {
            panelControl.tap()
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
            turnElement(identifier: "uls.physicalProps.hand", labels: ["Hand"])
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

    private func dismissTutorialNavigationCoach() {
        let startPrompt = messages.staticTexts["Tap anywhere to begin"].firstMatch
        XCTAssertTrue(startPrompt.waitForExistence(timeout: 4))
        let coach = messages.buttons["uls.tutorial.navigationCoach"].firstMatch
        XCTAssertTrue(coach.waitForExistence(timeout: 4))
        coach.tap()
        XCTAssertTrue(startPrompt.waitForNonExistence(timeout: 4))
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

    private func assertMinimumTarget(
        _ element: XCUIElement,
        message: String
    ) {
        let floatingPointTolerance: CGFloat = 0.01
        XCTAssertTrue(element.waitForExistence(timeout: 4), message)
        XCTAssertGreaterThanOrEqual(element.frame.width + floatingPointTolerance, 44, message)
        XCTAssertGreaterThanOrEqual(element.frame.height + floatingPointTolerance, 44, message)
    }

    @discardableResult
    private func assertTabletopLayoutContract(
        board: XCUIElement,
        bottomRegion: XCUIElement,
        interactiveElements: [XCUIElement],
        protectedOverlays: [XCUIElement] = []
    ) -> String {
        let hostCanvas = messages.descendants(matching: .any)["uls.host.usableCanvas"].firstMatch
        let tabletopShell = messages.descendants(matching: .any)["uls.tabletop.shell"].firstMatch
        XCTAssertTrue(hostCanvas.waitForExistence(timeout: 4))
        XCTAssertTrue(tabletopShell.waitForExistence(timeout: 4))
        XCTAssertTrue(board.waitForExistence(timeout: 4))
        XCTAssertTrue(bottomRegion.waitForExistence(timeout: 4))
        let boardHost = turnElement(
            identifier: "uls.tabletop.boardHost",
            labels: ["Live game board host"]
        )
        XCTAssertTrue(boardHost.waitForExistence(timeout: 4))

        let hostFrame = hostCanvas.frame
        let shellFrame = tabletopShell.frame
        assertElement(
            hostCanvas,
            isContainedIn: messages.frame,
            message: "The settled Messages usable canvas must remain inside the real host window."
        )
        assertElement(
            tabletopShell,
            isContainedIn: hostFrame,
            message: "The tabletop shell must remain inside the Messages usable canvas."
        )
        assertElement(
            boardHost,
            isContainedIn: shellFrame,
            message: "The mounted canonical board viewport must remain inside the tabletop shell."
        )
        XCTAssertEqual(
            boardHost.frame.width / boardHost.frame.height,
            430.0 / 520.0,
            accuracy: 0.01,
            "The mounted board and ocean must preserve their canonical aspect ratio."
        )
        XCTAssertEqual(
            boardHost.frame.midX,
            shellFrame.midX,
            accuracy: 2,
            "The mounted canonical board viewport must remain horizontally centered."
        )
        XCTAssertLessThanOrEqual(
            boardHost.frame.maxY,
            bottomRegion.frame.minY + 1.5,
            "The mounted board viewport must finish above the fixed lower region."
        )

        let diagnostic = currentHostDiagnosticValue()
        let totalBottomClearance = safeBottomInset(from: diagnostic)
            + (hostFrame.maxY - bottomRegion.frame.maxY)
        XCTAssertGreaterThanOrEqual(
            totalBottomClearance + 0.5,
            12,
            "The lower region must retain at least 12 points of total host-edge clearance."
        )

        for interactiveElement in interactiveElements {
            assertMinimumTarget(
                interactiveElement,
                message: "Every fixed tabletop control must remain at least 44 points."
            )
            assertElement(
                interactiveElement,
                isContainedIn: shellFrame,
                message: "Every fixed tabletop control must remain inside the shell."
            )
        }
        for overlay in protectedOverlays {
            XCTAssertTrue(overlay.waitForExistence(timeout: 4))
            assertElement(
                overlay,
                isContainedIn: shellFrame,
                message: "Temporary tabletop overlays must remain inside the stable shell."
            )
        }
        return diagnostic
    }

    private func currentHostDiagnosticValue() -> String {
        let hostCanvas = messages.descendants(matching: .any)["uls.host.usableCanvas"].firstMatch
        XCTAssertTrue(hostCanvas.waitForExistence(timeout: 4))
        return hostCanvas.value as? String ?? String(describing: hostCanvas.value)
    }

    private func safeBottomInset(from diagnostic: String) -> CGFloat {
        guard let safeComponent = diagnostic.split(separator: ";").first(where: {
            $0.hasPrefix("safe=")
        }) else {
            XCTFail("Host diagnostics must include safe-area insets: \(diagnostic)")
            return 0
        }
        let values = safeComponent.dropFirst("safe=".count).split(separator: ",")
        guard values.count == 4, let bottom = Double(values[2]) else {
            XCTFail("Host safe-area diagnostics are malformed: \(diagnostic)")
            return 0
        }
        return CGFloat(bottom)
    }

    private func boardMountIdentity(of boardHost: XCUIElement) -> String {
        XCTAssertTrue(boardHost.waitForExistence(timeout: 4))
        let diagnostic = boardHost.value as? String ?? String(describing: boardHost.value)
        return boardMountIdentity(from: diagnostic)
    }

    private func boardMountIdentity(from diagnostic: String) -> String {
        guard let mountRange = diagnostic.range(of: "mount=") else {
            XCTFail("Board diagnostics must expose the mounted SKView identity: \(diagnostic)")
            return ""
        }
        return String(
            diagnostic[mountRange.upperBound...]
                .prefix { $0 != ";" && $0 != ")" }
        )
    }

    private func assertNoRetiredGameplayShelf() {
        XCTAssertFalse(
            messages.descendants(matching: .any)
                .matching(identifier: "uls.overlayShelf")
                .firstMatch.exists,
            "The approved production journey must not render the retired gameplay shelf."
        )
    }

    private func waitForGamesEntryPoint() -> Bool {
        let lobbyGames = messages.buttons["uls.lobby.games"].firstMatch
        if lobbyGames.waitForExistence(timeout: 2) {
            return true
        }

        let gameInformation = firstExistingElement(
            [
                messages.buttons["Players and game information"].firstMatch,
                messages.buttons["Game information"].firstMatch,
            ],
            timeout: 2
        )
        guard gameInformation.waitForExistence(timeout: 4) else {
            return false
        }
        gameInformation.tap()
        return messages.buttons["uls.gameInfo.playerRecord"].firstMatch.waitForExistence(timeout: 4)
    }

    private func openGamesLibraryFromCurrentSurface() {
        let hostCanvas = messages.descendants(matching: .any)["uls.host.usableCanvas"].firstMatch
        if hostCanvas.waitForExistence(timeout: 2) {
            let tolerance: CGFloat = 1.5
            let visibleHostBounds = messages.frame.insetBy(dx: -tolerance, dy: -tolerance)
            guard visibleHostBounds.contains(hostCanvas.frame) else {
                XCTFail(
                    "The settled usable canvas is outside the Messages window: \(hostCanvas.frame)."
                )
                return
            }
        }

        for _ in 0..<8 {
            let library = messages.descendants(matching: .any)["uls.playerRecord"].firstMatch
            if library.exists {
                return
            }

            let playerRecord = messages.buttons["uls.gameInfo.playerRecord"].firstMatch
            if playerRecord.exists {
                tapCurrentFrame(of: playerRecord)
                RunLoop.current.run(until: Date().addingTimeInterval(0.4))
                continue
            }

            let gameInformation = firstExistingElement(
                [
                    messages.buttons["Players and game information"].firstMatch,
                    messages.buttons["Game information"].firstMatch,
                ],
                timeout: 1
            )
            if gameInformation.exists {
                tapCurrentFrame(of: gameInformation)
                RunLoop.current.run(until: Date().addingTimeInterval(0.3))
                continue
            }

            let lobbyGames = firstExistingElement(
                [
                    messages.buttons["uls.lobby.games"].firstMatch,
                    messages.buttons["Player Record"].firstMatch,
                ],
                timeout: 1
            )
            if lobbyGames.exists {
                tapCurrentFrame(of: lobbyGames)
                RunLoop.current.run(until: Date().addingTimeInterval(0.4))
                continue
            }

            RunLoop.current.run(until: Date().addingTimeInterval(0.25))
        }

        XCTFail("Expected Player Record from the current recognized surface.")
    }

    private func openRecoveredGameFromLibrary(
        gameID: String,
        visibleSubtitle: String
    ) {
        let library = messages.descendants(matching: .any)["uls.games.library"].firstMatch
        guard library.waitForExistence(timeout: 4) else {
            XCTFail("Recovered-game navigation requires the standalone Games library.")
            return
        }

        for _ in 0..<4 {
            let gameRow = firstExistingElement(
                [
                    messages.buttons["uls.games.open.\(gameID)"].firstMatch,
                    messages.descendants(matching: .any)["uls.games.open.\(gameID)"].firstMatch,
                    library.staticTexts[visibleSubtitle].firstMatch,
                    library.buttons.matching(
                        NSPredicate(format: "label CONTAINS[c] %@", "Current game")
                    ).firstMatch,
                    messages.buttons.matching(
                        NSPredicate(
                            format: "identifier BEGINSWITH %@ AND label CONTAINS[c] %@",
                            "uls.games.open.",
                            "Current game"
                        )
                    ).firstMatch,
                    messages.descendants(matching: .any).matching(
                        NSPredicate(
                            format: "identifier BEGINSWITH %@ AND label CONTAINS[c] %@",
                            "uls.games.open.",
                            "Current game"
                        )
                    ).firstMatch,
                ],
                timeout: 2
            )
            if gameRow.exists {
                tapCurrentFrame(of: gameRow)
                let boardHost = messages.descendants(matching: .any)["uls.tabletop.boardHost"].firstMatch
                if library.waitForNonExistence(timeout: 3) {
                    let inlineClose = messages.buttons["uls.gameInfo.close"].firstMatch
                    if inlineClose.exists {
                        tapCurrentFrame(of: inlineClose)
                        _ = inlineClose.waitForNonExistence(timeout: 3)
                    }
                    if boardHost.waitForExistence(timeout: 4) {
                        return
                    }
                }
            }

            let actionsAnchor = firstExistingElement(
                [
                    messages.buttons["uls.games.actions.\(gameID)"].firstMatch,
                    messages.buttons.matching(
                        NSPredicate(
                            format: "label BEGINSWITH %@ AND label CONTAINS[c] %@",
                            "Actions for",
                            visibleSubtitle
                        )
                    ).firstMatch,
                ],
                timeout: 1
            )
            if actionsAnchor.exists {
                let libraryFrame = library.frame
                let rowPoint = CGVector(
                    dx: libraryFrame.minX + libraryFrame.width * 0.35,
                    dy: actionsAnchor.frame.midY
                )
                messages.coordinate(withNormalizedOffset: .zero)
                    .withOffset(rowPoint)
                    .tap()
                let boardHost = messages.descendants(matching: .any)["uls.tabletop.boardHost"].firstMatch
                if library.waitForNonExistence(timeout: 3) {
                    let inlineClose = messages.buttons["uls.gameInfo.close"].firstMatch
                    if inlineClose.exists {
                        tapCurrentFrame(of: inlineClose)
                        _ = inlineClose.waitForNonExistence(timeout: 3)
                    }
                    if boardHost.waitForExistence(timeout: 4) {
                        return
                    }
                }
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.25))
        }

        XCTFail("Expected recovered game \(gameID) to open its gameplay tabletop.")
    }

    private func openInlineGamesFromCurrentSurface() {
        let gameInformation = firstExistingElement(
            [
                messages.buttons["Players and game information"].firstMatch,
                messages.buttons["Game information"].firstMatch,
            ],
            timeout: 4
        )
        XCTAssertTrue(gameInformation.waitForExistence(timeout: 4))
        tapCurrentFrame(of: gameInformation)

        let games = messages.buttons["uls.gameInfo.games"].firstMatch
        let players = messages.buttons["uls.gameInfo.players"].firstMatch
        let replacementControl = firstExistingElement([games, players], timeout: 4)
        XCTAssertTrue(
            replacementControl.exists,
            "Expected the inline Players/Games overlay after opening game information."
        )
        if games.exists {
            tapCurrentFrame(of: games)
        }
        XCTAssertTrue(players.waitForExistence(timeout: 4))
    }

    private func openLobbyTutorial() {
        let tutorial = messages.buttons["uls.lobby.tutorial"].firstMatch
        XCTAssertTrue(tutorial.waitForExistence(timeout: 4))
        tutorial.tap()
    }

    private func assertVisibleLobbyAction(_ element: XCUIElement, title: String) {
        let message = "\(title) must be fully visible and tappable in the Messages host."
        assertMinimumTarget(element, message: message)
        XCTAssertTrue(element.isHittable, message)
        assertElement(element, isContainedIn: messages.frame, message: message)
    }

    private func revealLobbyActionIfNeeded(_ element: XCUIElement) {
        for _ in 0..<4 where !element.isHittable {
            messages.descendants(matching: .any)["uls.lobby.tableSurface"].firstMatch.swipeUp()
        }
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
            boardMountIdentity(of: boardHost),
            boardMountIdentity(from: boardHostValue),
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
                messages.staticTexts["Invite Friends to Table"].firstMatch,
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
