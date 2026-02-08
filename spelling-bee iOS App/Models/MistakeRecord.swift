//
//  MistakeRecord.swift
//  spelling-bee iOS App
//
//  Models for tracking spelling mistakes and daily practice challenges.
//

import Foundation

/// Tracks a word that was spelled incorrectly across practice sessions
struct MistakeRecord: Codable, Equatable, Identifiable {
    let id: UUID
    let wordText: String
    let difficulty: Int
    let grade: Int
    let level: Int
    let dateRecorded: Date
    var mistakeCount: Int           // Accumulates across occurrences
    var correctCount: Int           // Correct in daily practice
    var lastMistakeDate: Date
    var lastCorrectDate: Date?
    var isMastered: Bool            // True after 3 correct daily practices

    init(wordText: String, difficulty: Int, grade: Int, level: Int) {
        self.id = UUID()
        self.wordText = wordText
        self.difficulty = difficulty
        self.grade = grade
        self.level = level
        self.dateRecorded = Date()
        self.mistakeCount = 1
        self.correctCount = 0
        self.lastMistakeDate = Date()
        self.lastCorrectDate = nil
        self.isMastered = false
    }
}

/// Tracks mistake state for a specific level
struct LevelMistakeState: Codable, Equatable {
    var mistakeWords: [String]      // Words from last completion
    var lastCompletionDate: Date

    init(mistakeWords: [String] = [], lastCompletionDate: Date = Date()) {
        self.mistakeWords = mistakeWords
        self.lastCompletionDate = lastCompletionDate
    }
}

/// Tracks daily practice challenge state
struct DailyPracticeState: Codable, Equatable {
    var lastPracticeDate: Date?
    var weeklyPracticeDates: [Date]
    var weeklyBonusAwarded: Bool
    var currentSeasonKey: String?   // "yyyy-ww" for weekly reset

    init() {
        self.lastPracticeDate = nil
        self.weeklyPracticeDates = []
        self.weeklyBonusAwarded = false
        self.currentSeasonKey = nil
    }
}
