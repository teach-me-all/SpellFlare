//
//  GameViewModel.swift
//  spelling-bee iOS App
//
//  Manages gameplay state, word progression, and scoring.
//

import Foundation
import SwiftUI

enum GamePhase {
    case preAd          // 5-second ad before test starts
    case presenting
    case spelling
    case feedback
    case levelComplete
}

enum FeedbackType {
    case correct
    case incorrect
}

@MainActor
class GameViewModel: ObservableObject {
    // MARK: - Published State
    @Published var phase: GamePhase = .preAd
    @Published var session: GameSession?
    @Published var feedbackType: FeedbackType?
    @Published var showRetryOption = false
    @Published var userSpelling = ""
    @Published var showPreTestAd = false

    // MARK: - Retry Tracking
    @Published var currentWordRetryCount: Int = 0
    @Published var hasSeenKeyboardHint: Bool = false

    // MARK: - Coins Tracking
    @Published var levelWrongAttempts: Int = 0  // Total wrong attempts for the entire level

    // MARK: - Give Up Animation State
    @Published var isSpellingOut = false
    @Published var currentSpellingLetters: [String] = []
    @Published var animatedLetterIndex: Int = 0
    @Published var hasGivenUp = false  // Track if user gave up (to show Next button)
    @Published var givenUpWord: Word?  // Store the word user gave up on (for display after index advances)

    // MARK: - Services
    private let speechService = SpeechService.shared
    private let wordBank = WordBankService.shared

    // MARK: - Pending level info for after ad
    private var pendingLevel: Int = 1
    private var pendingGrade: Int = 1

    // MARK: - Computed Properties
    var currentWord: Word? {
        session?.currentWord
    }

    var correctCount: Int {
        session?.correctCount ?? 0
    }

    var totalAttempted: Int {
        session?.totalAttempted ?? 0
    }

    var progress: Double {
        session?.progress ?? 0
    }

    var isLevelComplete: Bool {
        session?.isComplete ?? false
    }

    /// User passes the level if they didn't give up on more than 5 words
    var didPassLevel: Bool {
        let incorrectWords = session?.incorrectCount ?? 0
        return incorrectWords <= 5
    }

    var shouldShowKeyboardHint: Bool {
        currentWordRetryCount >= 2 && !hasSeenKeyboardHint
    }

    /// Coins earned for this level based on incorrect words (wrong or given up)
    /// Returns 0 if user didn't pass the level
    var coinsEarned: Int {
        guard didPassLevel else { return 0 }
        let incorrectWords = session?.incorrectCount ?? 0
        return CoinsService.shared.calculateCoins(wrongAttempts: incorrectWords)
    }

    // MARK: - Game Flow

    func startLevel(level: Int, grade: Int) {
        pendingLevel = level
        pendingGrade = grade

        // Check if we should show pre-test ad
        if AdManager.shared.adsEnabled {
            phase = .preAd
            showPreTestAd = true
        } else {
            // No ads, start directly
            beginActualTest()
        }
    }

    /// Called after pre-test ad is dismissed to start the actual test
    func onPreTestAdDismissed() {
        showPreTestAd = false
        beginActualTest()
    }

    /// Actually starts the test with words
    private func beginActualTest() {
        let words = wordBank.getWords(grade: pendingGrade, level: pendingLevel, count: 15)
        session = GameSession(level: pendingLevel, grade: pendingGrade, words: words)

        // Reset level wrong attempts for coins tracking
        levelWrongAttempts = 0

        // Set difficulty for audio playback
        let difficulty = min(pendingGrade + (pendingLevel - 1) / 10, 12)
        speechService.setDifficulty(difficulty)

        phase = .presenting
        presentCurrentWord()
    }

    func presentCurrentWord() {
        guard let word = currentWord else {
            checkLevelCompletion()
            return
        }

        // Reset retry tracking for new word
        currentWordRetryCount = 0
        hasSeenKeyboardHint = false

        phase = .presenting
        speechService.speakWord(word.text, difficulty: word.difficulty)
    }

    func repeatWord() {
        guard let word = currentWord else { return }
        speechService.speakWord(word.text, difficulty: word.difficulty)
    }

    func startSpelling() {
        phase = .spelling
        userSpelling = ""
    }

    func submitSpelling() {
        print("🔴 GameViewModel.submitSpelling() called")
        print("🔴 Current phase: \(phase)")
        print("🔴 Current word: \(currentWord?.text ?? "nil")")
        print("🔴 User spelling: '\(userSpelling)'")

        guard let word = currentWord else {
            print("❌ No current word, returning")
            return
        }

        let isCorrect = SpeechService.validateSpelling(userInput: userSpelling, correctWord: word.text)
        print("🔴 Validation result: \(isCorrect ? "CORRECT" : "INCORRECT")")

        if isCorrect {
            print("✅ Calling handleCorrectAnswer()")
            handleCorrectAnswer()
        } else {
            print("❌ Calling handleIncorrectAnswer()")
            handleIncorrectAnswer()
        }

        print("🔴 After handling answer, phase is now: \(phase)")
    }

    private func handleCorrectAnswer() {
        session?.markCorrect()
        feedbackType = .correct
        phase = .feedback

        let encouragements = [
            "Great job!",
            "Excellent!",
            "You got it!",
            "Perfect!",
            "Amazing!",
            "Wonderful!"
        ]
        speechService.speakFeedback(encouragements.randomElement() ?? "Correct!")

        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            await MainActor.run {
                self.advanceToNextWord()
            }
        }
    }

    private func handleIncorrectAnswer() {
        feedbackType = .incorrect
        phase = .feedback
        showRetryOption = true

        // Increment retry count and level wrong attempts for coins
        currentWordRetryCount += 1
        levelWrongAttempts += 1

        let encouragements = [
            "Nice try!",
            "Almost there!",
            "Keep trying!",
            "Don't give up!"
        ]
        speechService.speakFeedback(encouragements.randomElement() ?? "Try again!")
    }

    func retry() {
        showRetryOption = false
        userSpelling = ""

        // Mark hint acknowledged if shown
        if shouldShowKeyboardHint {
            hasSeenKeyboardHint = true
        }

        phase = .presenting
        presentCurrentWord()
    }

    func switchToKeyboard() {
        showRetryOption = false
        userSpelling = ""
        hasSeenKeyboardHint = true
        phase = .spelling
    }

    func trackRecordingCancellation() {
        currentWordRetryCount += 1
    }

    func giveUp() {
        guard let word = currentWord else { return }

        // Store the word BEFORE marking incorrect (which advances the index)
        givenUpWord = word

        // Mark as incorrect immediately so word count updates
        session?.markIncorrect()

        showRetryOption = false
        isSpellingOut = true
        hasGivenUp = false  // Will be set to true after animation completes

        // Prepare letters array from the stored word
        let letters = word.text.uppercased().map { String($0) }
        currentSpellingLetters = letters
        animatedLetterIndex = 0

        // Safety timeout - ensure hasGivenUp gets set even if animation fails
        // Estimate: feedback (2s) + 0.3s delay + letters (1s each incl delay) + 2s buffer
        let timeoutDuration = 3.0 + Double(letters.count) * 1.2 + 2.0
        DispatchQueue.main.asyncAfter(deadline: .now() + timeoutDuration) { [weak self] in
            guard let self = self else { return }
            // If still spelling out, force completion
            if self.isSpellingOut {
                self.isSpellingOut = false
                self.hasGivenUp = true
            }
        }

        // First, speak feedback then spell word
        speechService.speakFeedback("The correct spelling is") { [weak self] in
            guard let self = self else { return }
            // Use DispatchQueue for consistent main thread execution
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.spellWordWithLetterAnimation(letters: letters)
            }
        }
    }

    /// Called when user taps "Next" after giving up - advances to next word
    func proceedAfterGiveUp() {
        hasGivenUp = false
        isSpellingOut = false
        currentSpellingLetters = []
        animatedLetterIndex = 0
        givenUpWord = nil
        advanceToNextWord()
    }

    private func spellWordWithLetterAnimation(letters: [String]) {
        let audioService = AudioPlaybackService.shared

        // Play each letter sequentially with animation
        func playNextLetter(index: Int) {
            guard index < letters.count else {
                // All letters done - show "Next" button
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.isSpellingOut = false
                    self.hasGivenUp = true
                }
                return
            }

            // Animate this letter appearing
            animatedLetterIndex = index

            // Play letter audio
            let letter = letters[index]
            audioService.playLetter(letter) {
                // After this letter's audio finishes, play next
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    playNextLetter(index: index + 1)
                }
            }
        }

        playNextLetter(index: 0)
    }

    private func advanceToNextWord() {
        showRetryOption = false
        feedbackType = nil
        userSpelling = ""

        // Reset retry tracking
        currentWordRetryCount = 0
        hasSeenKeyboardHint = false

        if isLevelComplete {
            phase = .levelComplete
            speechService.speakFeedback("Congratulations! You completed the level!")
        } else if currentWord != nil {
            phase = .presenting
            presentCurrentWord()
        } else {
            phase = .levelComplete
        }
    }

    private func checkLevelCompletion() {
        if isLevelComplete {
            phase = .levelComplete
        }
    }

    var completedLevel: Int {
        session?.level ?? 0
    }

    func cleanup() {
        speechService.stopSpeaking()
        speechService.stopListening()

        // Reset animation state
        isSpellingOut = false
        currentSpellingLetters = []
        animatedLetterIndex = 0
        givenUpWord = nil
        hasGivenUp = false
    }
}
