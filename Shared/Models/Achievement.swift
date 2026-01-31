//
//  Achievement.swift
//  Shared
//
//  Data models for the hybrid achievements system.
//

import Foundation

// MARK: - Achievement Rarity

enum AchievementRarity: String, Codable, CaseIterable {
    case common, rare, epic, legendary
}

// MARK: - Achievement Category

enum AchievementCategory: String, Codable, CaseIterable {
    case streak     // Daily play streaks
    case coins      // Coin accumulation
    case levels     // Level completion milestones
    case grade      // Grade-specific completion
    case score      // Score-based achievements
    case skill      // Skill-based achievements (perfect levels, first-try, accuracy)
}

// MARK: - Achievement Section (display grouping)

enum AchievementSection: String, CaseIterable {
    case skill = "Skill"
    case streaks = "Streaks"
    case coinsAndProgress = "Coins & Progress"
    case grade = "Grade"
    case lifetime = "Lifetime"
    case monthly = "Monthly"
}

// MARK: - Achievement Definition

struct AchievementDefinition: Identifiable {
    let id: String
    let title: String
    let description: String
    let iconName: String          // SF Symbol name
    let coinReward: Int
    let isSeasonal: Bool          // true = resets monthly, false = lifetime
    let gameCenterID: String?     // nil for seasonal-only achievements
    let targetValue: Int          // Target to unlock (e.g., 3 for streak_3)
    let category: AchievementCategory
    let rarity: AchievementRarity
    let section: AchievementSection
}

// MARK: - Achievement Progress

struct AchievementProgress: Codable, Equatable {
    var currentValue: Int = 0
    var isUnlocked: Bool = false
    var unlockDate: Date?
    var coinsClaimed: Bool = false
    var gameCenterReported: Bool = false
    var seasonKey: String?        // e.g., "2026-01" for seasonal achievements
}

// MARK: - Achievement State

struct AchievementState: Codable, Equatable {
    /// Progress keyed by achievement ID
    var progress: [String: AchievementProgress] = [:]

    /// Dates the user was active (for streak calculation)
    var dailyActivityDates: [String] = [] // "yyyy-MM-dd" format

    /// Current consecutive day streak
    var currentStreakCount: Int = 0

    /// Longest streak ever achieved
    var longestStreakCount: Int = 0

    /// Last date the user played
    var lastActivityDate: String?  // "yyyy-MM-dd" format

    /// Monthly coins earned (seasonal tracking)
    var monthlyCoinsEarned: Int = 0
    var monthlyCoinsSeasonKey: String?  // "yyyy-MM"

    /// Weekly best score (seasonal tracking)
    var weeklyBestScore: Int = 0
    var weeklyBestScoreSeasonKey: String?  // "yyyy-MM"

    /// Queue of achievement IDs that were unlocked but not yet shown to user
    var pendingUnlockQueue: [String] = []

    /// Perfect levels completed (0 incorrect words)
    var perfectLevelCount: Int = 0

    /// Cumulative words spelled correctly on first attempt
    var firstTryCorrectWords: Int = 0

    /// Last 10 level accuracies (for rolling average)
    var recentLevelAccuracies: [Double] = []

    /// Highest monthly coin total ever recorded
    var bestMonthCoins: Int = 0
    var bestMonthCoinsKey: String?

    /// User played after missing 2+ days
    var hasReturnedAfterBreak: Bool = false

    // MARK: - Helpers

    static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = .current
        return f
    }()

    static let monthFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM"
        f.timeZone = .current
        return f
    }()

    static func currentDayKey() -> String {
        dateFormatter.string(from: Date())
    }

    static func currentMonthKey() -> String {
        monthFormatter.string(from: Date())
    }
}
