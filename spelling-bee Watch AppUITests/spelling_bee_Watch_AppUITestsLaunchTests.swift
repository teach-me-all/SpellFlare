//
//  spelling_bee_Watch_AppUITestsLaunchTests.swift
//  spelling-bee Watch AppUITests
//
//  Launch screenshot tests for the Spelling Bee watchOS app.
//  Captures screenshots of key screens for visual verification.
//

import XCTest

final class spelling_bee_Watch_AppUITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // MARK: - Launch Screenshot

    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    // MARK: - Onboarding Screenshots

    func testOnboardingWelcomeScreenshot() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UI_TESTING", "RESET_STATE"]
        app.launch()

        // Wait for welcome screen
        let beeEmoji = app.staticTexts["🐝"]
        XCTAssertTrue(beeEmoji.waitForExistence(timeout: 5))

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Onboarding - Welcome"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testOnboardingNameScreenshot() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UI_TESTING", "RESET_STATE"]
        app.launch()

        // Navigate to name screen
        let startButton = app.buttons["Start"]
        if startButton.waitForExistence(timeout: 5) {
            startButton.tap()

            let namePrompt = app.staticTexts["What's your name?"]
            XCTAssertTrue(namePrompt.waitForExistence(timeout: 3))

            let attachment = XCTAttachment(screenshot: app.screenshot())
            attachment.name = "Onboarding - Name Input"
            attachment.lifetime = .keepAlways
            add(attachment)
        }
    }

    func testOnboardingGradeScreenshot() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UI_TESTING", "RESET_STATE"]
        app.launch()

        // Navigate to grade screen
        let startButton = app.buttons["Start"]
        if startButton.waitForExistence(timeout: 5) {
            startButton.tap()

            let nameTextField = app.textFields["Name"]
            if nameTextField.waitForExistence(timeout: 3) {
                nameTextField.tap()
                nameTextField.typeText("Test")

                let nextButton = app.buttons["Next"]
                nextButton.tap()

                let gradePrompt = app.staticTexts["Pick your grade"]
                XCTAssertTrue(gradePrompt.waitForExistence(timeout: 3))

                let attachment = XCTAttachment(screenshot: app.screenshot())
                attachment.name = "Onboarding - Grade Selection"
                attachment.lifetime = .keepAlways
                add(attachment)
            }
        }
    }

    // MARK: - Home Screen Screenshots

    func testHomeScreenScreenshot() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UI_TESTING", "EXISTING_PROFILE"]
        app.launch()

        // Wait for home screen
        let levelsNav = app.navigationBars["Levels"]
        XCTAssertTrue(levelsNav.waitForExistence(timeout: 5))

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Home Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testSettingsScreenshot() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UI_TESTING", "EXISTING_PROFILE"]
        app.launch()

        let settingsButton = app.buttons["gearshape.fill"]
        if settingsButton.waitForExistence(timeout: 5) {
            settingsButton.tap()

            // Wait for settings sheet
            Thread.sleep(forTimeInterval: 0.5)

            let attachment = XCTAttachment(screenshot: app.screenshot())
            attachment.name = "Settings"
            attachment.lifetime = .keepAlways
            add(attachment)
        }
    }

    // MARK: - Game Screenshots

    func testGameWordPresentationScreenshot() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UI_TESTING", "EXISTING_PROFILE"]
        app.launch()

        let level1Button = app.buttons["1"]
        if level1Button.waitForExistence(timeout: 5) {
            level1Button.tap()

            let listenText = app.staticTexts["Listen carefully!"]
            XCTAssertTrue(listenText.waitForExistence(timeout: 5))

            let attachment = XCTAttachment(screenshot: app.screenshot())
            attachment.name = "Game - Word Presentation"
            attachment.lifetime = .keepAlways
            add(attachment)
        }
    }

    func testGameSpellingInputScreenshot() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UI_TESTING", "EXISTING_PROFILE"]
        app.launch()

        let level1Button = app.buttons["1"]
        if level1Button.waitForExistence(timeout: 5) {
            level1Button.tap()

            let spellButton = app.buttons["Spell It!"]
            if spellButton.waitForExistence(timeout: 5) {
                spellButton.tap()

                // Wait for spelling input view
                Thread.sleep(forTimeInterval: 0.5)

                let attachment = XCTAttachment(screenshot: app.screenshot())
                attachment.name = "Game - Spelling Input"
                attachment.lifetime = .keepAlways
                add(attachment)
            }
        }
    }

    // MARK: - Different Watch Sizes

    func testLaunchOnAllWatchSizes() throws {
        // This test captures launch screen across different watch configurations
        // The runsForEachTargetApplicationUIConfiguration flag handles this

        let app = XCUIApplication()
        app.launch()

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch - Watch Simulator"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
