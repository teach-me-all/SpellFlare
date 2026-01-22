//
//  WatchGameViewModel.swift
//  SpellFlare Watch App
//
//  Manages game session state for the Watch app.
//

import SwiftUI

// MARK: - Game Phase
enum WatchGamePhase {
    case presenting     // Word is being spoken
    case spelling       // User is spelling
    case feedback       // Showing correct/incorrect
}

// MARK: - Feedback Type
enum WatchFeedbackType {
    case correct
    case incorrect
}

// MARK: - Word Model (Watch-specific, lightweight)
struct WatchWord: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let difficulty: Int
}

// MARK: - Game Session
class WatchGameSession {
    let level: Int
    let grade: Int
    private(set) var words: [WatchWord]
    private(set) var currentIndex: Int = 0
    private(set) var correctCount: Int = 0
    private(set) var incorrectCount: Int = 0
    let totalWordsInGame = 10

    init(level: Int, grade: Int, words: [WatchWord]) {
        self.level = level
        self.grade = grade
        self.words = words
    }

    var currentWord: WatchWord? {
        guard currentIndex < words.count else { return nil }
        return words[currentIndex]
    }

    /// Total words attempted (correct + incorrect/given up)
    var totalAttempted: Int {
        correctCount + incorrectCount
    }

    /// Game is complete after 10 words are attempted
    var isComplete: Bool {
        totalAttempted >= totalWordsInGame || currentIndex >= words.count
    }

    /// Progress based on total words attempted
    var progress: Double {
        Double(totalAttempted) / Double(totalWordsInGame)
    }

    func markCorrect() {
        correctCount += 1
        currentIndex += 1
    }

    func markIncorrect() {
        incorrectCount += 1
        currentIndex += 1
    }
}

// MARK: - Game View Model
@MainActor
class WatchGameViewModel: ObservableObject {
    // MARK: - Published State
    @Published var phase: WatchGamePhase = .presenting
    @Published var session: WatchGameSession?
    @Published var feedbackType: WatchFeedbackType?
    @Published var userSpelling = ""
    @Published var retryCount = 0
    @Published var lastAnsweredWord: WatchWord?  // Store word for feedback display
    @Published var hasGivenUp = false  // Track if user gave up (to show correct spelling and Next button)

    // MARK: - Coins Tracking
    @Published var levelWrongAttempts: Int = 0  // Total wrong attempts for coins calculation

    // MARK: - Services
    private let audioService = WatchAudioService.shared
    private let wordBank = WatchWordBankService.shared

    // MARK: - Computed Properties
    var currentWord: WatchWord? {
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

    /// Coins earned for this level based on incorrect words (wrong or given up)
    /// Returns 0 if user didn't pass the level
    var coinsEarned: Int {
        guard didPassLevel else { return 0 }
        let incorrectWords = session?.incorrectCount ?? 0
        return CoinsService.shared.calculateCoins(wrongAttempts: incorrectWords)
    }

    // MARK: - Game Flow
    func startLevel(level: Int, grade: Int) {
        let words = wordBank.getWords(grade: grade, level: level, count: 15)
        session = WatchGameSession(level: level, grade: grade, words: words)

        // Reset coins tracking
        levelWrongAttempts = 0

        phase = .presenting
        presentCurrentWord()
    }

    func presentCurrentWord() {
        guard let word = currentWord else {
            checkLevelCompletion()
            return
        }

        retryCount = 0
        phase = .presenting

        // Play word audio
        audioService.playWord(word.text, difficulty: word.difficulty)
    }

    func repeatWord() {
        guard let word = currentWord else { return }
        audioService.playWord(word.text, difficulty: word.difficulty)
    }

    func startSpelling() {
        phase = .spelling
        userSpelling = ""
    }

    func submitSpelling(_ spelling: String) {
        userSpelling = spelling

        guard let word = currentWord else { return }

        let isCorrect = validateSpelling(spelling, correctWord: word.text)

        if isCorrect {
            handleCorrectAnswer()
        } else {
            handleIncorrectAnswer()
        }
    }

    private func validateSpelling(_ input: String, correctWord: String) -> Bool {
        let normalizedInput = input
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")

        let normalizedCorrect = correctWord.lowercased()

        return normalizedInput == normalizedCorrect
    }

    private func handleCorrectAnswer() {
        // Store the word before advancing index
        lastAnsweredWord = currentWord
        session?.markCorrect()
        feedbackType = .correct
        phase = .feedback

        audioService.playFeedback(.correct)

        // Auto-advance after delay
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            await MainActor.run {
                self.advanceToNextWord()
            }
        }
    }

    private func handleIncorrectAnswer() {
        // Store the word for display
        lastAnsweredWord = currentWord
        feedbackType = .incorrect
        phase = .feedback
        retryCount += 1
        levelWrongAttempts += 1  // Track for coins

        audioService.playFeedback(.incorrect)
    }

    func retry() {
        feedbackType = nil
        userSpelling = ""
        lastAnsweredWord = nil
        hasGivenUp = false
        phase = .presenting
        presentCurrentWord()
    }

    func giveUp() {
        // Store the word BEFORE marking incorrect (which advances the index)
        // lastAnsweredWord was already set in handleIncorrectAnswer(), but let's ensure it's set
        if lastAnsweredWord == nil {
            lastAnsweredWord = currentWord
        }

        // Mark as incorrect immediately so word count updates
        session?.markIncorrect()

        // Show the correct spelling - don't advance yet
        hasGivenUp = true
        // Play the word so user can hear correct pronunciation
        if let word = lastAnsweredWord {
            audioService.playWord(word.text, difficulty: word.difficulty)
        }
    }

    /// Called when user taps "Next" after giving up - advances to next word
    func proceedAfterGiveUp() {
        hasGivenUp = false
        advanceToNextWord()
    }

    private func advanceToNextWord() {
        feedbackType = nil
        userSpelling = ""
        lastAnsweredWord = nil
        hasGivenUp = false

        if isLevelComplete {
            phase = .feedback  // Will trigger level complete screen
        } else if currentWord != nil {
            phase = .presenting
            presentCurrentWord()
        }
    }

    private func checkLevelCompletion() {
        if isLevelComplete {
            phase = .feedback
        }
    }

    func cleanup() {
        audioService.stop()
    }

    var completedLevel: Int {
        session?.level ?? 0
    }

    var finalScore: Int {
        session?.correctCount ?? 0
    }
}
