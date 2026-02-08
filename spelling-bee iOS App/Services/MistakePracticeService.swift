//
//  MistakePracticeService.swift
//  spelling-bee iOS App
//
//  Manages mistake tracking and daily practice challenges.
//

import Foundation

class MistakePracticeService {
    static let shared = MistakePracticeService()

    private let calendar = Calendar.current
    private let masteryThreshold = 3  // Correct answers needed to master a word

    private init() {}

    // MARK: - Level Completion Recording

    /// Record mistakes from a level completion
    /// - Parameters:
    ///   - level: The level completed
    ///   - grade: The grade of the level
    ///   - incorrectWords: Words the user got wrong (as Word objects)
    ///   - profile: The user profile to update
    func recordLevelCompletion(level: Int, grade: Int, incorrectWords: [(text: String, difficulty: Int)], profile: inout UserProfile) {
        // Update level mistake state
        let mistakeTexts = incorrectWords.map { $0.text }
        let state = LevelMistakeState(mistakeWords: mistakeTexts, lastCompletionDate: Date())

        if profile.levelMistakesByGrade[grade] == nil {
            profile.levelMistakesByGrade[grade] = [:]
        }
        profile.levelMistakesByGrade[grade]?[level] = state

        // Update/create mistake records for each word
        for word in incorrectWords {
            if let index = profile.mistakeRecords.firstIndex(where: { $0.wordText.lowercased() == word.text.lowercased() && $0.grade == grade }) {
                // Word already tracked - increment mistake count
                profile.mistakeRecords[index].mistakeCount += 1
                profile.mistakeRecords[index].lastMistakeDate = Date()
                // Reset mastery if they got it wrong again
                if profile.mistakeRecords[index].isMastered {
                    profile.mistakeRecords[index].isMastered = false
                    profile.mistakeRecords[index].correctCount = 0
                }
            } else {
                // New mistake record
                let record = MistakeRecord(
                    wordText: word.text,
                    difficulty: word.difficulty,
                    grade: grade,
                    level: level
                )
                profile.mistakeRecords.append(record)
            }
        }
    }

    // MARK: - Level Mistakes Query

    /// Check if a level has recorded mistakes
    func hasLevelMistakes(level: Int, grade: Int, profile: UserProfile) -> Bool {
        guard let gradeStates = profile.levelMistakesByGrade[grade],
              let state = gradeStates[level] else {
            return false
        }
        return !state.mistakeWords.isEmpty
    }

    /// Get mistake words for a specific level
    /// Returns Word objects for practice
    func getMistakeWordsForLevel(level: Int, grade: Int, profile: UserProfile) -> [(text: String, difficulty: Int)] {
        guard let gradeStates = profile.levelMistakesByGrade[grade],
              let state = gradeStates[level] else {
            return []
        }

        // Look up difficulties from mistake records, fallback to grade-based difficulty
        return state.mistakeWords.map { wordText in
            if let record = profile.mistakeRecords.first(where: { $0.wordText.lowercased() == wordText.lowercased() && $0.grade == grade }) {
                return (text: wordText, difficulty: record.difficulty)
            }
            // Fallback difficulty calculation
            let difficulty = min(grade + (level - 1) / 10, 12)
            return (text: wordText, difficulty: difficulty)
        }
    }

    /// Get count of mistake words for a level
    func mistakeCountForLevel(level: Int, grade: Int, profile: UserProfile) -> Int {
        guard let gradeStates = profile.levelMistakesByGrade[grade],
              let state = gradeStates[level] else {
            return 0
        }
        return state.mistakeWords.count
    }

    // MARK: - Daily Challenge

    /// Check if daily challenge is available (has words to practice)
    func isDailyChallengeAvailable(profile: UserProfile) -> Bool {
        // Need at least one non-mastered mistake word
        return profile.mistakeRecords.contains { !$0.isMastered }
    }

    /// Check if user has already done daily practice today
    func hasDailyPracticeToday(profile: UserProfile) -> Bool {
        guard let lastDate = profile.dailyPracticeState.lastPracticeDate else {
            return false
        }
        return calendar.isDateInToday(lastDate)
    }

    /// Generate words for daily challenge (3-10 words)
    /// Prioritizes: frequent mistakes, recent mistakes, not mastered
    func generateDailyChallenge(profile: UserProfile) -> [(text: String, difficulty: Int)] {
        let nonMastered = profile.mistakeRecords.filter { !$0.isMastered }
        guard !nonMastered.isEmpty else { return [] }

        // Score each word: higher score = higher priority
        let now = Date()
        let scoredWords = nonMastered.map { record -> (record: MistakeRecord, score: Int) in
            var score = record.mistakeCount * 3

            // Bonus for recent mistakes (within last 7 days)
            let daysSinceMistake = calendar.dateComponents([.day], from: record.lastMistakeDate, to: now).day ?? 0
            if daysSinceMistake <= 7 {
                score += 5
            }

            // Slight penalty for words with some correct answers (but not mastered)
            score -= record.correctCount

            return (record: record, score: max(score, 1))
        }

        // Sort by score descending
        let sorted = scoredWords.sorted { $0.score > $1.score }

        // Take 3-10 words
        let targetCount = min(max(3, sorted.count), 10)
        let selected = Array(sorted.prefix(targetCount))

        return selected.map { (text: $0.record.wordText, difficulty: $0.record.difficulty) }
    }

    /// Record result of practicing a single word in daily challenge
    /// Returns coins earned (including mastery bonus if applicable)
    func recordPracticeResult(wordText: String, wasCorrect: Bool, profile: inout UserProfile) -> Int {
        guard let index = profile.mistakeRecords.firstIndex(where: { $0.wordText.lowercased() == wordText.lowercased() }) else {
            return 0
        }

        var coinsEarned = 0

        if wasCorrect {
            profile.mistakeRecords[index].correctCount += 1
            profile.mistakeRecords[index].lastCorrectDate = Date()
            coinsEarned += CoinsService.practiceWordCoinReward

            // Check for mastery
            if profile.mistakeRecords[index].correctCount >= masteryThreshold && !profile.mistakeRecords[index].isMastered {
                profile.mistakeRecords[index].isMastered = true
                coinsEarned += CoinsService.masteryBonusReward
            }
        } else {
            // Got it wrong again - increment mistake count, reset progress
            profile.mistakeRecords[index].mistakeCount += 1
            profile.mistakeRecords[index].lastMistakeDate = Date()
            profile.mistakeRecords[index].correctCount = 0
        }

        return coinsEarned
    }

    /// Complete daily practice session
    /// Returns (baseCoins, bonusCoins) - bonusCoins > 0 if weekly bonus awarded
    func completeDailyPractice(profile: inout UserProfile) -> (baseCoins: Int, bonusCoins: Int) {
        let now = Date()

        // Check for weekly reset
        let currentWeekKey = weekKey(for: now)
        if profile.dailyPracticeState.currentSeasonKey != currentWeekKey {
            profile.dailyPracticeState.weeklyPracticeDates = []
            profile.dailyPracticeState.weeklyBonusAwarded = false
            profile.dailyPracticeState.currentSeasonKey = currentWeekKey
        }

        // Record today's practice
        profile.dailyPracticeState.lastPracticeDate = now
        profile.dailyPracticeState.weeklyPracticeDates.append(now)

        var bonusCoins = 0

        // Check for weekly bonus (5 days of practice)
        if profile.dailyPracticeState.weeklyPracticeDates.count >= 5 && !profile.dailyPracticeState.weeklyBonusAwarded {
            bonusCoins = CoinsService.weeklyPracticeBonusReward
            profile.dailyPracticeState.weeklyBonusAwarded = true
        }

        return (baseCoins: CoinsService.dailyPracticeBaseReward, bonusCoins: bonusCoins)
    }

    /// Get count of practice days this week
    func weeklyPracticeCount(profile: UserProfile) -> Int {
        let now = Date()
        let currentWeekKey = weekKey(for: now)

        guard profile.dailyPracticeState.currentSeasonKey == currentWeekKey else {
            return 0
        }

        return profile.dailyPracticeState.weeklyPracticeDates.count
    }

    /// Returns 7 booleans representing each day of the current week (Mon-Sun)
    func weeklyPracticeStatus(profile: UserProfile) -> [Bool] {
        let now = Date()
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: now) else {
            return Array(repeating: false, count: 7)
        }

        let currentWeekKey = weekKey(for: now)
        guard profile.dailyPracticeState.currentSeasonKey == currentWeekKey else {
            return Array(repeating: false, count: 7)
        }

        var result: [Bool] = []
        for dayOffset in 0..<7 {
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: weekInterval.start) else {
                result.append(false)
                continue
            }
            let practiced = profile.dailyPracticeState.weeklyPracticeDates.contains { date in
                calendar.isDate(date, inSameDayAs: day)
            }
            result.append(practiced)
        }
        return result
    }

    // MARK: - Helpers

    private func weekKey(for date: Date) -> String {
        let year = calendar.component(.yearForWeekOfYear, from: date)
        let week = calendar.component(.weekOfYear, from: date)
        return "\(year)-\(String(format: "%02d", week))"
    }

    /// Clear level mistakes (e.g., after successful replay with no mistakes)
    func clearLevelMistakes(level: Int, grade: Int, profile: inout UserProfile) {
        profile.levelMistakesByGrade[grade]?[level] = nil
    }

    /// Get total non-mastered mistake count
    func totalPracticeWordsCount(profile: UserProfile) -> Int {
        return profile.mistakeRecords.filter { !$0.isMastered }.count
    }

    /// Get mastered words count
    func masteredWordsCount(profile: UserProfile) -> Int {
        return profile.mistakeRecords.filter { $0.isMastered }.count
    }
}
