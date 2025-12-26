//
//  spelling_bee_iOS_AppTests.swift
//  spelling-bee iOS AppTests
//
//  Created by MADHURI on 12/25/25.
//
//  Comprehensive unit tests for the Spelling Bee iOS app.
//

import XCTest
@testable import spelling_bee_iOS_App

// MARK: - UserProfile Tests
final class iOS_UserProfileTests: XCTestCase {

    func testUserProfileInitialization() {
        let profile = UserProfile(name: "TestUser", grade: 3)

        XCTAssertEqual(profile.name, "TestUser")
        XCTAssertEqual(profile.grade, 3)
        XCTAssertEqual(profile.currentLevel, 1)
        XCTAssertTrue(profile.completedLevels.isEmpty)
    }

    func testGradeClampedToMinimum() {
        let profile = UserProfile(name: "Test", grade: 0)
        XCTAssertEqual(profile.grade, 1, "Grade should be clamped to minimum of 1")
    }

    func testGradeClampedToMaximum() {
        let profile = UserProfile(name: "Test", grade: 10)
        XCTAssertEqual(profile.grade, 7, "Grade should be clamped to maximum of 7")
    }

    func testCompleteLevel() {
        var profile = UserProfile(name: "Test", grade: 1)

        profile.completeLevel(1)

        XCTAssertTrue(profile.completedLevels.contains(1))
        XCTAssertEqual(profile.currentLevel, 2)
    }

    func testCompleteLevelAdvancesCurrentLevel() {
        var profile = UserProfile(name: "Test", grade: 1)

        profile.completeLevel(1)
        profile.completeLevel(2)

        XCTAssertEqual(profile.currentLevel, 3)
    }

    func testLevel1IsUnlockedByDefault() {
        let profile = UserProfile(name: "Test", grade: 1)
        XCTAssertTrue(profile.isLevelUnlocked(1))
    }

    func testLevel2IsLockedByDefault() {
        let profile = UserProfile(name: "Test", grade: 1)
        XCTAssertFalse(profile.isLevelUnlocked(2))
    }

    func testLevel2UnlockedAfterCompletingLevel1() {
        var profile = UserProfile(name: "Test", grade: 1)
        profile.completeLevel(1)
        XCTAssertTrue(profile.isLevelUnlocked(2))
    }

    func testCompletedLevelsPerGrade() {
        var profile = UserProfile(name: "Test", grade: 1)

        profile.completeLevel(1)
        XCTAssertTrue(profile.completedLevels.contains(1))

        profile.grade = 2
        XCTAssertTrue(profile.completedLevels.isEmpty)

        profile.completeLevel(1)
        profile.grade = 1
        XCTAssertTrue(profile.completedLevels.contains(1))
    }

    func testMaxLevelIsFifty() {
        var profile = UserProfile(name: "Test", grade: 1)

        for level in 1...50 {
            profile.completeLevel(level)
        }

        XCTAssertEqual(profile.currentLevel, 50)
    }
}

// MARK: - Word Tests
final class iOS_WordTests: XCTestCase {

    func testWordInitialization() {
        let word = Word(text: "apple", difficulty: 2)
        XCTAssertEqual(word.text, "apple")
        XCTAssertEqual(word.difficulty, 2)
    }

    func testWordHasUniqueId() {
        let word1 = Word(text: "apple", difficulty: 2)
        let word2 = Word(text: "apple", difficulty: 2)
        XCTAssertNotEqual(word1.id, word2.id, "Each word should have unique ID")
    }

    func testWordEquality() {
        let word1 = Word(text: "apple", difficulty: 2)
        let word2 = word1
        XCTAssertEqual(word1, word2)
    }
}

// MARK: - GameSession Tests
final class iOS_GameSessionTests: XCTestCase {

    func testGameSessionInitialization() {
        let words = [
            Word(text: "cat", difficulty: 1),
            Word(text: "dog", difficulty: 1),
            Word(text: "fish", difficulty: 1)
        ]

        let session = GameSession(level: 1, grade: 1, words: words)

        XCTAssertEqual(session.level, 1)
        XCTAssertEqual(session.grade, 1)
        XCTAssertEqual(session.correctCount, 0)
        XCTAssertNotNil(session.currentWord)
    }

    func testMarkCorrectAdvancesWord() {
        var words = [Word]()
        for i in 1...15 {
            words.append(Word(text: "word\(i)", difficulty: 1))
        }

        let session = GameSession(level: 1, grade: 1, words: words)
        session.markCorrect()

        XCTAssertEqual(session.correctCount, 1)
    }

    func testMarkIncorrectAdvancesWord() {
        var words = [Word]()
        for i in 1...15 {
            words.append(Word(text: "word\(i)", difficulty: 1))
        }

        let session = GameSession(level: 1, grade: 1, words: words)
        session.markIncorrect()

        XCTAssertEqual(session.correctCount, 0)
        XCTAssertEqual(session.incorrectCount, 1)
    }

    func testProgressCalculation() {
        var words = [Word]()
        for i in 1...15 {
            words.append(Word(text: "word\(i)", difficulty: 1))
        }

        let session = GameSession(level: 1, grade: 1, words: words)

        XCTAssertEqual(session.progress, 0.0)
        session.markCorrect()
        XCTAssertEqual(session.progress, 0.1)
    }

    func testIsCompleteWhenTenCorrect() {
        var words = [Word]()
        for i in 1...15 {
            words.append(Word(text: "word\(i)", difficulty: 1))
        }

        let session = GameSession(level: 1, grade: 1, words: words)

        for _ in 1...10 {
            session.markCorrect()
        }

        XCTAssertTrue(session.isComplete)
        XCTAssertEqual(session.progress, 1.0)
    }

    func testCurrentWordNilWhenExhausted() {
        let words = [
            Word(text: "cat", difficulty: 1),
            Word(text: "dog", difficulty: 1)
        ]

        let session = GameSession(level: 1, grade: 1, words: words)

        session.markCorrect()
        session.markCorrect()

        XCTAssertNil(session.currentWord)
    }
}

// MARK: - AppState Tests
@MainActor
final class iOS_AppStateTests: XCTestCase {

    func testCreateProfile() {
        let appState = AppState()

        appState.createProfile(name: "TestUser", grade: 3)

        XCTAssertNotNil(appState.profile)
        XCTAssertEqual(appState.profile?.name, "TestUser")
        XCTAssertEqual(appState.profile?.grade, 3)
    }

    func testNavigateToGame() {
        let appState = AppState()
        appState.createProfile(name: "Test", grade: 1)

        appState.navigateToGame(level: 5)

        if case .game(let level) = appState.currentScreen {
            XCTAssertEqual(level, 5)
        } else {
            XCTFail("Should be in game screen")
        }
    }

    func testNavigateToHome() {
        let appState = AppState()
        appState.createProfile(name: "Test", grade: 1)
        appState.navigateToGame(level: 1)

        appState.navigateToHome()

        if case .home = appState.currentScreen {
            // Success
        } else {
            XCTFail("Should be in home screen")
        }
    }

    func testNavigateToSettings() {
        let appState = AppState()
        appState.createProfile(name: "Test", grade: 1)

        appState.navigateToSettings()

        if case .settings = appState.currentScreen {
            // Success
        } else {
            XCTFail("Should be in settings screen")
        }
    }

    func testUpdateGrade() {
        let appState = AppState()
        appState.createProfile(name: "Test", grade: 1)

        appState.updateGrade(5)

        XCTAssertEqual(appState.profile?.grade, 5)
    }

    func testCompleteLevel() {
        let appState = AppState()
        appState.createProfile(name: "Test", grade: 1)

        appState.completeLevel(1)

        XCTAssertTrue(appState.profile?.isLevelCompleted(1) ?? false)
    }

    func testResetApp() {
        let appState = AppState()
        appState.createProfile(name: "Test", grade: 3)

        appState.resetApp()

        XCTAssertNil(appState.profile)
        if case .onboarding = appState.currentScreen {
            // Success
        } else {
            XCTFail("Should return to onboarding after reset")
        }
    }
}

// MARK: - SpeechService Tests
@MainActor
final class iOS_SpeechServiceValidationTests: XCTestCase {

    func testValidateSpellingExactMatch() {
        XCTAssertTrue(SpeechService.validateSpelling(userInput: "apple", correctWord: "apple"))
    }

    func testValidateSpellingCaseInsensitive() {
        XCTAssertTrue(SpeechService.validateSpelling(userInput: "APPLE", correctWord: "apple"))
    }

    func testValidateSpellingWithSpaces() {
        XCTAssertTrue(SpeechService.validateSpelling(userInput: "a p p l e", correctWord: "apple"))
    }

    func testValidateSpellingWithDashes() {
        XCTAssertTrue(SpeechService.validateSpelling(userInput: "a-p-p-l-e", correctWord: "apple"))
    }

    func testValidateSpellingIncorrect() {
        XCTAssertFalse(SpeechService.validateSpelling(userInput: "aple", correctWord: "apple"))
    }
}

// MARK: - WordBankService Tests
final class iOS_WordBankServiceTests: XCTestCase {

    func testGetWordsReturnsCorrectCount() {
        let service = WordBankService.shared
        let words = service.getWords(grade: 1, level: 1, count: 10)
        XCTAssertEqual(words.count, 10)
    }

    func testGetWordsReturnsUniqueWords() {
        let service = WordBankService.shared
        let words = service.getWords(grade: 1, level: 1, count: 15)
        let uniqueTexts = Set(words.map { $0.text })
        XCTAssertEqual(words.count, uniqueTexts.count)
    }

    func testGetWordsForDifferentGrades() {
        let service = WordBankService.shared

        let grade1Words = service.getWords(grade: 1, level: 1, count: 5)
        let grade5Words = service.getWords(grade: 5, level: 1, count: 5)

        XCTAssertEqual(grade1Words.count, 5)
        XCTAssertEqual(grade5Words.count, 5)
    }
}

// MARK: - StoreManager Tests
@MainActor
final class iOS_StoreManagerTests: XCTestCase {

    func testStoreManagerSingleton() {
        let manager1 = StoreManager.shared
        let manager2 = StoreManager.shared

        XCTAssertTrue(manager1 === manager2, "StoreManager should be a singleton")
    }

    func testFormattedPriceNotEmpty() {
        let manager = StoreManager.shared
        let price = manager.formattedPrice
        XCTAssertFalse(price.isEmpty, "Formatted price should not be empty")
    }

    func testPurchaseInProgressInitialState() {
        let manager = StoreManager.shared
        XCTAssertFalse(manager.purchaseInProgress)
    }
}

// MARK: - Encoding/Decoding Tests
final class iOS_EncodingDecodingTests: XCTestCase {

    func testUserProfileEncodeDecode() throws {
        var original = UserProfile(name: "TestUser", grade: 3)
        original.completeLevel(1)
        original.completeLevel(2)

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(UserProfile.self, from: data)

        XCTAssertEqual(decoded.name, original.name)
        XCTAssertEqual(decoded.grade, original.grade)
        XCTAssertEqual(decoded.completedLevels, original.completedLevels)
    }

    func testUserProfileMigrationFromOldFormat() throws {
        let oldFormatJSON = """
        {
            "name": "OldUser",
            "grade": 2,
            "completedLevels": [1, 2, 3],
            "currentLevel": 4
        }
        """

        let data = oldFormatJSON.data(using: .utf8)!
        let decoder = JSONDecoder()
        let profile = try decoder.decode(UserProfile.self, from: data)

        XCTAssertEqual(profile.name, "OldUser")
        XCTAssertEqual(profile.grade, 2)
        XCTAssertTrue(profile.completedLevels.contains(1))
        XCTAssertEqual(profile.currentLevel, 4)
    }
}

// MARK: - Edge Case Tests
@MainActor
final class iOS_EdgeCaseTests: XCTestCase {

    func testEmptyUserName() {
        let profile = UserProfile(name: "", grade: 1)
        XCTAssertEqual(profile.name, "")
    }

    func testVeryLongUserName() {
        let longName = String(repeating: "a", count: 1000)
        let profile = UserProfile(name: longName, grade: 1)
        XCTAssertEqual(profile.name, longName)
    }

    func testSpecialCharactersInName() {
        let specialName = "Test 🐝 User! @#$%"
        let profile = UserProfile(name: specialName, grade: 1)
        XCTAssertEqual(profile.name, specialName)
    }

    func testCompletingSameLevelTwice() {
        var profile = UserProfile(name: "Test", grade: 1)

        profile.completeLevel(1)
        let countAfterFirst = profile.completedLevels.count

        profile.completeLevel(1)
        let countAfterSecond = profile.completedLevels.count

        XCTAssertEqual(countAfterFirst, countAfterSecond)
    }

    func testEmptySpellingValidation() {
        XCTAssertFalse(SpeechService.validateSpelling(userInput: "", correctWord: "apple"))
    }

    func testWhitespaceOnlySpellingValidation() {
        XCTAssertFalse(SpeechService.validateSpelling(userInput: "   ", correctWord: "apple"))
    }
}

// MARK: - Performance Tests
final class iOS_PerformanceTests: XCTestCase {

    func testWordBankPerformance() {
        let service = WordBankService.shared

        measure {
            for grade in 1...7 {
                for level in 1...50 {
                    _ = service.getWords(grade: grade, level: level, count: 15)
                }
            }
        }
    }

    func testProfileOperationsPerformance() {
        measure {
            var profile = UserProfile(name: "PerfTest", grade: 3)
            for level in 1...50 {
                profile.completeLevel(level)
                _ = profile.isLevelUnlocked(level)
                _ = profile.isLevelCompleted(level)
            }
        }
    }
}
