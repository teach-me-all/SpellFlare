//
//  AchievementDefinitions.swift
//  Shared
//
//  Static registry of all achievement definitions.
//

import Foundation

enum AchievementDefinitions {

    // MARK: - Skill Achievements (NEW)

    static let skillPerfect5 = AchievementDefinition(
        id: "skill_perfect_5",
        title: "Buzzing Beginner",
        description: "Complete 5 levels with no mistakes",
        iconName: "target",
        coinReward: 75,
        isSeasonal: false,
        gameCenterID: nil,
        targetValue: 5,
        category: .skill,
        rarity: .common,
        section: .skill
    )

    static let skillPerfect20 = AchievementDefinition(
        id: "skill_perfect_20",
        title: "Precision Pro",
        description: "Complete 20 levels with no mistakes",
        iconName: "scope",
        coinReward: 250,
        isSeasonal: false,
        gameCenterID: nil,
        targetValue: 20,
        category: .skill,
        rarity: .rare,
        section: .skill
    )

    static let skillFirstTry50 = AchievementDefinition(
        id: "skill_first_try_50",
        title: "Lightning Listener",
        description: "Spell 50 words correctly on your first try",
        iconName: "bolt.fill",
        coinReward: 200,
        isSeasonal: false,
        gameCenterID: nil,
        targetValue: 50,
        category: .skill,
        rarity: .rare,
        section: .skill
    )

    static let skillAccuracy90 = AchievementDefinition(
        id: "skill_accuracy_90",
        title: "Sharp as a Stinger",
        description: "Maintain 90% accuracy over your last 10 levels",
        iconName: "chart.line.uptrend.xyaxis",
        coinReward: 300,
        isSeasonal: false,
        gameCenterID: nil,
        targetValue: 90,
        category: .skill,
        rarity: .epic,
        section: .skill
    )

    // MARK: - Streak Achievements (existing + new)

    static let streak1 = AchievementDefinition(
        id: "streak_1",
        title: "First Buzz",
        description: "Practice spelling for 1 day",
        iconName: "flame",
        coinReward: 25,
        isSeasonal: true,
        gameCenterID: nil,
        targetValue: 1,
        category: .streak,
        rarity: .common,
        section: .streaks
    )

    static let streak3 = AchievementDefinition(
        id: "streak_3",
        title: "Buzz Builder",
        description: "Practice spelling 3 days in a row",
        iconName: "flame.fill",
        coinReward: 50,
        isSeasonal: true,
        gameCenterID: nil,
        targetValue: 3,
        category: .streak,
        rarity: .common,
        section: .streaks
    )

    static let streak7 = AchievementDefinition(
        id: "streak_7",
        title: "Hive Habit Hero",
        description: "Practice spelling 7 days in a row",
        iconName: "flame.circle.fill",
        coinReward: 150,
        isSeasonal: true,
        gameCenterID: nil,
        targetValue: 7,
        category: .streak,
        rarity: .rare,
        section: .streaks
    )

    static let streakReturn = AchievementDefinition(
        id: "streak_return",
        title: "Back to the Hive",
        description: "Return to practice after a break",
        iconName: "arrow.uturn.backward.circle.fill",
        coinReward: 50,
        isSeasonal: false,
        gameCenterID: nil,
        targetValue: 1,
        category: .streak,
        rarity: .common,
        section: .streaks
    )

    // MARK: - Coins & Progress (existing + new)

    static let coins1000 = AchievementDefinition(
        id: "coins_1000",
        title: "Coin Collector",
        description: "Accumulate 1,000 total coins",
        iconName: "circle.fill",
        coinReward: 50,
        isSeasonal: false,
        gameCenterID: nil,
        targetValue: 1000,
        category: .coins,
        rarity: .common,
        section: .coinsAndProgress
    )

    static let coins20000 = AchievementDefinition(
        id: "coins_20000",
        title: "Honey Hoarder",
        description: "Accumulate 20,000 total coins",
        iconName: "dollarsign.circle.fill",
        coinReward: 1000,
        isSeasonal: false,
        gameCenterID: nil,
        targetValue: 20000,
        category: .coins,
        rarity: .legendary,
        section: .coinsAndProgress
    )

    static let levels25 = AchievementDefinition(
        id: "levels_25",
        title: "Word Explorer",
        description: "Complete 25 levels across all grades",
        iconName: "map.fill",
        coinReward: 100,
        isSeasonal: false,
        gameCenterID: nil,
        targetValue: 25,
        category: .levels,
        rarity: .common,
        section: .coinsAndProgress
    )

    static let levels100 = AchievementDefinition(
        id: "levels_100",
        title: "Hive Champion",
        description: "Complete 100 levels across all grades",
        iconName: "crown.fill",
        coinReward: 500,
        isSeasonal: false,
        gameCenterID: nil,
        targetValue: 100,
        category: .levels,
        rarity: .epic,
        section: .coinsAndProgress
    )

    // MARK: - Grade Completion (NEW)

    static let grade1Complete = AchievementDefinition(
        id: "grade_1_complete",
        title: "Grade 1 Star",
        description: "Complete all 50 levels in Grade 1",
        iconName: "star.fill",
        coinReward: 200,
        isSeasonal: false,
        gameCenterID: nil,
        targetValue: 50,
        category: .grade,
        rarity: .common,
        section: .grade
    )

    static let grade2Complete = AchievementDefinition(
        id: "grade_2_complete",
        title: "Grade 2 Star",
        description: "Complete all 50 levels in Grade 2",
        iconName: "star.circle.fill",
        coinReward: 300,
        isSeasonal: false,
        gameCenterID: nil,
        targetValue: 50,
        category: .grade,
        rarity: .rare,
        section: .grade
    )

    static let gradeHonorRoll = AchievementDefinition(
        id: "grade_honor_roll",
        title: "Honor Roll Hero",
        description: "Achieve 90% accuracy over your last 10 levels",
        iconName: "medal.fill",
        coinReward: 400,
        isSeasonal: false,
        gameCenterID: nil,
        targetValue: 90,
        category: .skill,
        rarity: .epic,
        section: .grade
    )

    static let gradeMaster = AchievementDefinition(
        id: "grade_master",
        title: "Master of the Hive",
        description: "Complete all 50 levels in any grade",
        iconName: "rosette",
        coinReward: 750,
        isSeasonal: false,
        gameCenterID: nil,
        targetValue: 50,
        category: .grade,
        rarity: .legendary,
        section: .grade
    )

    // MARK: - Lifetime / Game Center (existing, renamed)

    static let gcLevels25 = AchievementDefinition(
        id: "gc_levels_25",
        title: "Pathfinder of Words",
        description: "Complete 25 levels across all grades",
        iconName: "trophy.fill",
        coinReward: 200,
        isSeasonal: false,
        gameCenterID: "gc_levels_25",
        targetValue: 25,
        category: .levels,
        rarity: .rare,
        section: .lifetime
    )

    static let gcLevels100 = AchievementDefinition(
        id: "gc_levels_100",
        title: "Spelling Champion",
        description: "Complete 100 levels across all grades",
        iconName: "trophy.circle.fill",
        coinReward: 500,
        isSeasonal: false,
        gameCenterID: "gc_levels_100",
        targetValue: 100,
        category: .levels,
        rarity: .legendary,
        section: .lifetime
    )

    static let gcCoins5000 = AchievementDefinition(
        id: "gc_coins_5000",
        title: "Golden Hive Member",
        description: "Accumulate 5,000 total coins",
        iconName: "banknote.fill",
        coinReward: 300,
        isSeasonal: false,
        gameCenterID: "gc_coins_5000",
        targetValue: 5000,
        category: .coins,
        rarity: .epic,
        section: .lifetime
    )

    static let gcStreak30 = AchievementDefinition(
        id: "gc_streak_30",
        title: "Guardian of the Hive",
        description: "Achieve a 30-day play streak",
        iconName: "calendar.badge.checkmark",
        coinReward: 500,
        isSeasonal: false,
        gameCenterID: "gc_streak_30",
        targetValue: 30,
        category: .streak,
        rarity: .legendary,
        section: .lifetime
    )

    static let gcGrade1Complete = AchievementDefinition(
        id: "gc_grade1_complete",
        title: "Foundations Master",
        description: "Complete all 50 levels in Grade 1",
        iconName: "graduationcap.fill",
        coinReward: 400,
        isSeasonal: false,
        gameCenterID: "gc_grade1_complete",
        targetValue: 50,
        category: .grade,
        rarity: .rare,
        section: .lifetime
    )

    // MARK: - Seasonal / Monthly (existing + new, renamed)

    static let monthlyCoins500 = AchievementDefinition(
        id: "monthly_coins_500",
        title: "Monthly Honey Maker",
        description: "Earn 500 coins in one month",
        iconName: "bitcoinsign.circle.fill",
        coinReward: 100,
        isSeasonal: true,
        gameCenterID: nil,
        targetValue: 500,
        category: .coins,
        rarity: .rare,
        section: .monthly
    )

    static let weeklyBest = AchievementDefinition(
        id: "weekly_best",
        title: "Season Star Speller",
        description: "Get a perfect score on any level this month",
        iconName: "star.circle.fill",
        coinReward: 75,
        isSeasonal: true,
        gameCenterID: nil,
        targetValue: 10,
        category: .score,
        rarity: .epic,
        section: .monthly
    )

    static let monthlyBeatBest = AchievementDefinition(
        id: "monthly_beat_best",
        title: "New Personal Best!",
        description: "Beat your best monthly coin total",
        iconName: "arrow.up.circle.fill",
        coinReward: 150,
        isSeasonal: true,
        gameCenterID: nil,
        targetValue: 1,
        category: .coins,
        rarity: .rare,
        section: .monthly
    )

    static let monthlyMVP = AchievementDefinition(
        id: "monthly_mvp",
        title: "Hive MVP",
        description: "Earn 2,000 coins in a single month",
        iconName: "sparkles",
        coinReward: 500,
        isSeasonal: true,
        gameCenterID: nil,
        targetValue: 2000,
        category: .coins,
        rarity: .legendary,
        section: .monthly
    )

    // MARK: - Collections

    static let all: [AchievementDefinition] = [
        // Skill
        skillPerfect5, skillPerfect20, skillFirstTry50, skillAccuracy90,
        // Streaks
        streak1, streak3, streak7, streakReturn,
        // Coins & Progress
        coins1000, coins20000, levels25, levels100,
        // Grade
        grade1Complete, grade2Complete, gradeHonorRoll, gradeMaster,
        // Lifetime (Game Center)
        gcLevels25, gcLevels100, gcCoins5000, gcStreak30, gcGrade1Complete,
        // Monthly
        monthlyCoins500, weeklyBest, monthlyBeatBest, monthlyMVP
    ]

    static let seasonal: [AchievementDefinition] = all.filter { $0.isSeasonal }

    static let lifetime: [AchievementDefinition] = all.filter { !$0.isSeasonal }

    static func definition(for id: String) -> AchievementDefinition? {
        all.first { $0.id == id }
    }

    static func definitions(for section: AchievementSection) -> [AchievementDefinition] {
        all.filter { $0.section == section }
    }
}
