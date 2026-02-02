//
//  UserProfile.swift
//  Shared
//
//  User profile data model - shared across iOS and watchOS.
//

import Foundation

struct UserProfile: Codable, Equatable, Identifiable {
    var id: UUID
    var name: String
    var avatarIcon: String
    var grade: Int // 1-7
    // Track completed levels per grade: [grade: Set<level>]
    var completedLevelsByGrade: [Int: Set<Int>]
    var currentLevelByGrade: [Int: Int]

    // Coins system
    var totalCoins: Int = 0
    var coinsMigrationCompleted: Bool = false

    // Achievements system
    var achievementState: AchievementState = AchievementState()
    var achievementsMigrationCompleted: Bool = false

    // Shop system
    var shopState: ShopState = ShopState()
    var shopMigrationCompleted: Bool = false

    // Daily check-in system
    var lastCheckInDate: Date? = nil
    var weeklyCheckInDates: [Date] = []
    var weeklyBonusAwarded: Bool = false

    init(name: String, grade: Int, id: UUID = UUID(), avatarIcon: String = "🐝") {
        self.id = id
        self.name = name
        self.avatarIcon = avatarIcon
        self.grade = max(1, min(7, grade))
        self.completedLevelsByGrade = [:]
        self.currentLevelByGrade = [:]
        self.totalCoins = 0
        self.coinsMigrationCompleted = false
        self.achievementState = AchievementState()
        self.achievementsMigrationCompleted = false
        self.shopState = ShopState()
        self.shopMigrationCompleted = false
        self.lastCheckInDate = nil
        self.weeklyCheckInDates = []
        self.weeklyBonusAwarded = false
        // Initialize all grades with level 1
        for g in 1...7 {
            currentLevelByGrade[g] = 1
            completedLevelsByGrade[g] = []
        }
    }

    // Computed property for total completed levels across all grades
    var totalCompletedLevelsCount: Int {
        completedLevelsByGrade.values.reduce(0) { $0 + $1.count }
    }

    // Computed property for current grade's completed levels
    var completedLevels: Set<Int> {
        return completedLevelsByGrade[grade] ?? []
    }

    // Computed property for current grade's current level
    var currentLevel: Int {
        return currentLevelByGrade[grade] ?? 1
    }

    mutating func completeLevel(_ level: Int) {
        // Complete level for current grade only
        if completedLevelsByGrade[grade] == nil {
            completedLevelsByGrade[grade] = []
        }
        completedLevelsByGrade[grade]?.insert(level)

        let current = currentLevelByGrade[grade] ?? 1
        if level >= current && level < 50 {
            currentLevelByGrade[grade] = level + 1
        }
    }

    func isLevelUnlocked(_ level: Int) -> Bool {
        let current = currentLevelByGrade[grade] ?? 1
        let completed = completedLevelsByGrade[grade] ?? []
        return level <= current || completed.contains(level)
    }

    func isLevelCompleted(_ level: Int) -> Bool {
        return completedLevelsByGrade[grade]?.contains(level) ?? false
    }

    // Migration from old format - supports both iOS and watchOS legacy keys
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? container.decode(UUID.self, forKey: .id)) ?? UUID()
        name = try container.decode(String.self, forKey: .name)
        avatarIcon = (try? container.decode(String.self, forKey: .avatarIcon)) ?? "🐝"
        grade = try container.decode(Int.self, forKey: .grade)

        // Try to decode new format first
        if let levelsByGrade = try? container.decode([Int: Set<Int>].self, forKey: .completedLevelsByGrade) {
            completedLevelsByGrade = levelsByGrade
        } else if let oldCompletedLevels = try? container.decode(Set<Int>.self, forKey: .completedLevels) {
            // Migration: watchOS old format had completedLevels as Set<Int>
            completedLevelsByGrade = [grade: oldCompletedLevels]
        } else if let oldCompletedLevels = try? container.decode(Set<Int>.self, forKey: .completedLevelsByGrade) {
            // Migration: iOS old format stored Set<Int> under completedLevelsByGrade key
            completedLevelsByGrade = [grade: oldCompletedLevels]
        } else {
            completedLevelsByGrade = [:]
        }

        if let currentByGrade = try? container.decode([Int: Int].self, forKey: .currentLevelByGrade) {
            currentLevelByGrade = currentByGrade
        } else if let oldCurrentLevel = try? container.decode(Int.self, forKey: .currentLevel) {
            // Migration: watchOS old format had currentLevel as Int
            currentLevelByGrade = [grade: oldCurrentLevel]
        } else if let oldCurrentLevel = try? container.decode(Int.self, forKey: .currentLevelByGrade) {
            // Migration: iOS old format stored Int under currentLevelByGrade key
            currentLevelByGrade = [grade: oldCurrentLevel]
        } else {
            currentLevelByGrade = [:]
        }

        // Ensure all grades are initialized
        for g in 1...7 {
            if currentLevelByGrade[g] == nil {
                currentLevelByGrade[g] = 1
            }
            if completedLevelsByGrade[g] == nil {
                completedLevelsByGrade[g] = []
            }
        }

        // Migration for coins - use defaults if not present
        totalCoins = (try? container.decode(Int.self, forKey: .totalCoins)) ?? 0
        coinsMigrationCompleted = (try? container.decode(Bool.self, forKey: .coinsMigrationCompleted)) ?? false

        // Migration for achievements - use defaults if not present
        achievementState = (try? container.decode(AchievementState.self, forKey: .achievementState)) ?? AchievementState()
        achievementsMigrationCompleted = (try? container.decode(Bool.self, forKey: .achievementsMigrationCompleted)) ?? false

        // Migration for shop - use defaults if not present
        shopState = (try? container.decode(ShopState.self, forKey: .shopState)) ?? ShopState()
        shopMigrationCompleted = (try? container.decode(Bool.self, forKey: .shopMigrationCompleted)) ?? false

        // Migration for daily check-in - use defaults if not present
        lastCheckInDate = try? container.decode(Date.self, forKey: .lastCheckInDate)
        weeklyCheckInDates = (try? container.decode([Date].self, forKey: .weeklyCheckInDates)) ?? []
        weeklyBonusAwarded = (try? container.decode(Bool.self, forKey: .weeklyBonusAwarded)) ?? false
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, avatarIcon, grade, completedLevelsByGrade, currentLevelByGrade, completedLevels, currentLevel
        case totalCoins, coinsMigrationCompleted
        case achievementState, achievementsMigrationCompleted
        case shopState, shopMigrationCompleted
        case lastCheckInDate, weeklyCheckInDates, weeklyBonusAwarded
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(avatarIcon, forKey: .avatarIcon)
        try container.encode(grade, forKey: .grade)
        try container.encode(completedLevelsByGrade, forKey: .completedLevelsByGrade)
        try container.encode(currentLevelByGrade, forKey: .currentLevelByGrade)
        try container.encode(totalCoins, forKey: .totalCoins)
        try container.encode(coinsMigrationCompleted, forKey: .coinsMigrationCompleted)
        try container.encode(achievementState, forKey: .achievementState)
        try container.encode(achievementsMigrationCompleted, forKey: .achievementsMigrationCompleted)
        try container.encode(shopState, forKey: .shopState)
        try container.encode(shopMigrationCompleted, forKey: .shopMigrationCompleted)
        try container.encodeIfPresent(lastCheckInDate, forKey: .lastCheckInDate)
        try container.encode(weeklyCheckInDates, forKey: .weeklyCheckInDates)
        try container.encode(weeklyBonusAwarded, forKey: .weeklyBonusAwarded)
    }
}
