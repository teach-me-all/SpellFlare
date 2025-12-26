//
//  spelling_bee_iOS_AppUITests.swift
//  spelling-bee iOS AppUITests
//
//  Created by MADHURI on 12/25/25.
//
//  Comprehensive UI tests for the Spelling Bee iOS app.
//

import XCTest

final class spelling_bee_iOS_AppUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UI_TESTING"]
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - App Launch Tests

    @MainActor
    func testAppLaunches() throws {
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 5))
    }

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}

// MARK: - Onboarding UI Tests
final class iOS_OnboardingUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UI_TESTING", "RESET_STATE"]
    }

    override func tearDownWithError() throws {
        app = nil
    }

    @MainActor
    func testOnboardingWelcomeScreenExists() throws {
        app.launch()

        let beeEmoji = app.staticTexts["🐝"]
        XCTAssertTrue(beeEmoji.waitForExistence(timeout: 5), "Bee emoji should be visible")

        let appTitle = app.staticTexts["Spelling Bee"]
        XCTAssertTrue(appTitle.exists, "App title should be visible")
    }

    @MainActor
    func testOnboardingWelcomeToNameTransition() throws {
        app.launch()

        let startButton = app.buttons["Let's Start!"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 5))
        startButton.tap()

        let namePrompt = app.staticTexts["What's your name?"]
        XCTAssertTrue(namePrompt.waitForExistence(timeout: 3), "Name input screen should appear")
    }

    @MainActor
    func testOnboardingCompleteFlow() throws {
        app.launch()

        // Welcome screen
        let startButton = app.buttons["Let's Start!"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 5))
        startButton.tap()

        // Name screen
        let nameTextField = app.textFields["Enter your name"]
        XCTAssertTrue(nameTextField.waitForExistence(timeout: 3))
        nameTextField.tap()
        nameTextField.typeText("TestSpeller")

        let continueButton = app.buttons["Continue"]
        continueButton.tap()

        // Grade selection - tap grade 3
        let grade3Button = app.buttons.matching(NSPredicate(format: "label CONTAINS '3'")).firstMatch
        if grade3Button.waitForExistence(timeout: 3) {
            grade3Button.tap()
        }

        let startLearningButton = app.buttons["Start Learning!"]
        XCTAssertTrue(startLearningButton.waitForExistence(timeout: 3))
        startLearningButton.tap()

        // Should navigate to home screen
        let levelsText = app.staticTexts["Levels"]
        XCTAssertTrue(levelsText.waitForExistence(timeout: 5), "Should navigate to home screen")
    }
}

// MARK: - Home Screen UI Tests
final class iOS_HomeScreenUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UI_TESTING", "EXISTING_PROFILE"]
    }

    override func tearDownWithError() throws {
        app = nil
    }

    @MainActor
    func testHomeScreenDisplays() throws {
        app.launch()

        let levelsText = app.staticTexts["Levels"]
        XCTAssertTrue(levelsText.waitForExistence(timeout: 5), "Home screen should show Levels text")
    }

    @MainActor
    func testHomeScreenShowsUserGreeting() throws {
        app.launch()

        let greeting = app.staticTexts.element(matching: NSPredicate(format: "label BEGINSWITH 'Hi,'"))
        let beeEmoji = app.staticTexts["🐝"]

        let hasGreeting = greeting.waitForExistence(timeout: 5) || beeEmoji.exists
        XCTAssertTrue(hasGreeting, "Should show greeting or bee emoji")
    }

    @MainActor
    func testSettingsButtonExists() throws {
        app.launch()

        let settingsButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'gear' OR identifier CONTAINS 'settings'")).firstMatch
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 5), "Settings button should exist")
    }

    @MainActor
    func testTappingLevelStartsGame() throws {
        app.launch()

        let level1 = app.buttons.element(matching: NSPredicate(format: "label CONTAINS 'Level 1'"))
        XCTAssertTrue(level1.waitForExistence(timeout: 5))
        level1.tap()

        let speakerEmoji = app.staticTexts["🔊"]
        let hearWord = app.staticTexts.element(matching: NSPredicate(format: "label CONTAINS 'Hear'"))

        let inGameView = speakerEmoji.waitForExistence(timeout: 5) || hearWord.waitForExistence(timeout: 2)
        XCTAssertTrue(inGameView, "Should navigate to game view")
    }
}

// MARK: - Game Flow UI Tests
final class iOS_GameFlowUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UI_TESTING", "EXISTING_PROFILE"]
    }

    override func tearDownWithError() throws {
        app = nil
    }

    private func navigateToGame() {
        let level1 = app.buttons.element(matching: NSPredicate(format: "label CONTAINS 'Level 1'"))
        XCTAssertTrue(level1.waitForExistence(timeout: 5))
        level1.tap()
    }

    @MainActor
    func testGameShowsWordPresentation() throws {
        app.launch()
        navigateToGame()

        let speakerEmoji = app.staticTexts["🔊"]
        XCTAssertTrue(speakerEmoji.waitForExistence(timeout: 5), "Should show speaker emoji")
    }

    @MainActor
    func testGameHasSpellItButton() throws {
        app.launch()
        navigateToGame()

        let spellButton = app.buttons["Spell It!"]
        XCTAssertTrue(spellButton.waitForExistence(timeout: 5), "Spell It button should be visible")
    }

    @MainActor
    func testSpellItTransitionsToInput() throws {
        app.launch()
        navigateToGame()

        let spellButton = app.buttons["Spell It!"]
        XCTAssertTrue(spellButton.waitForExistence(timeout: 5))
        spellButton.tap()

        let textField = app.textFields.firstMatch
        let submitButton = app.buttons["Submit"]

        let inSpellingView = textField.waitForExistence(timeout: 5) || submitButton.waitForExistence(timeout: 2)
        XCTAssertTrue(inSpellingView, "Should transition to spelling input")
    }
}

// MARK: - Settings UI Tests
final class iOS_SettingsUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UI_TESTING", "EXISTING_PROFILE"]
    }

    override func tearDownWithError() throws {
        app = nil
    }

    private func openSettings() {
        let settingsButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'gear'")).firstMatch
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 5))
        settingsButton.tap()
    }

    @MainActor
    func testSettingsShowsProfile() throws {
        app.launch()
        openSettings()

        let beeEmoji = app.staticTexts["🐝"]
        XCTAssertTrue(beeEmoji.waitForExistence(timeout: 5), "Profile section should show bee emoji")
    }

    @MainActor
    func testSettingsShowsGradeLevel() throws {
        app.launch()
        openSettings()

        let gradeSection = app.staticTexts["Grade Level"]
        XCTAssertTrue(gradeSection.waitForExistence(timeout: 5), "Grade Level section should exist")
    }

    @MainActor
    func testSettingsShowsPurchases() throws {
        app.launch()
        openSettings()

        app.swipeUp()

        let purchasesSection = app.staticTexts["Purchases"]
        XCTAssertTrue(purchasesSection.waitForExistence(timeout: 5), "Purchases section should exist")
    }

    @MainActor
    func testResetProgressButton() throws {
        app.launch()
        openSettings()

        app.swipeUp()

        let resetButton = app.buttons["Reset All Progress"]
        XCTAssertTrue(resetButton.waitForExistence(timeout: 5), "Reset All Progress button should exist")
    }

    @MainActor
    func testDoneButtonDismissesSettings() throws {
        app.launch()
        openSettings()

        let doneButton = app.buttons["Done"]
        XCTAssertTrue(doneButton.waitForExistence(timeout: 5))
        doneButton.tap()

        let levelsText = app.staticTexts["Levels"]
        XCTAssertTrue(levelsText.waitForExistence(timeout: 5), "Should return to home screen")
    }
}

// MARK: - Parent Gate UI Tests
final class iOS_ParentGateUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UI_TESTING", "EXISTING_PROFILE"]
    }

    override func tearDownWithError() throws {
        app = nil
    }

    private func navigateToRemoveAds() {
        let settingsButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'gear'")).firstMatch
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 5))
        settingsButton.tap()

        app.swipeUp()

        let removeAdsButton = app.buttons.element(matching: NSPredicate(format: "label CONTAINS 'Remove Ads'"))
        if removeAdsButton.waitForExistence(timeout: 3) {
            removeAdsButton.tap()
        }
    }

    @MainActor
    func testParentGateAppears() throws {
        app.launch()
        navigateToRemoveAds()

        let verificationText = app.staticTexts["Parent Verification"]
        XCTAssertTrue(verificationText.waitForExistence(timeout: 5), "Parent Verification should appear")
    }

    @MainActor
    func testParentGateShowsMathProblem() throws {
        app.launch()
        navigateToRemoveAds()

        let mathProblem = app.staticTexts.element(matching: NSPredicate(format: "label CONTAINS '×'"))
        XCTAssertTrue(mathProblem.waitForExistence(timeout: 5), "Math problem should be visible")
    }

    @MainActor
    func testParentGateHasCancelButton() throws {
        app.launch()
        navigateToRemoveAds()

        let cancelButton = app.buttons["Cancel"]
        XCTAssertTrue(cancelButton.waitForExistence(timeout: 5), "Cancel button should exist")
    }
}

// MARK: - Accessibility Tests
final class iOS_AccessibilityUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UI_TESTING", "EXISTING_PROFILE"]
    }

    override func tearDownWithError() throws {
        app = nil
    }

    @MainActor
    func testHomeScreenAccessibility() throws {
        app.launch()

        let buttons = app.buttons.allElementsBoundByIndex
        XCTAssertGreaterThan(buttons.count, 0, "Should have accessible buttons")
    }

    @MainActor
    func testTextElementsAccessible() throws {
        app.launch()

        let texts = app.staticTexts.allElementsBoundByIndex
        XCTAssertGreaterThan(texts.count, 0, "Should have accessible text elements")
    }
}
