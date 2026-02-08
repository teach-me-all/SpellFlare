//
//  CoinsService.swift
//  Shared
//
//  Handles coins calculation and migration logic for the rewards system.
//

import Foundation

class CoinsService {
    static let shared = CoinsService()

    // MARK: - Mistake Practice Rewards
    static let practiceWordCoinReward = 5       // Per correct practice word
    static let dailyPracticeBaseReward = 25     // Completing daily practice
    static let weeklyPracticeBonusReward = 50   // 5 days of practice in a week
    static let masteryBonusReward = 10          // When a word is mastered (3 correct)

    private init() {}

    // MARK: - Coins Calculation

    /// Calculate coins earned based on wrong attempts during a level
    /// - Parameter wrongAttempts: Number of wrong attempts during the level
    /// - Returns: Coins to award (100 for perfect, 70 for 1-2 mistakes, 50 for 3+)
    func calculateCoins(wrongAttempts: Int) -> Int {
        switch wrongAttempts {
        case 0:
            return 100  // Perfect score
        case 1...2:
            return 70   // Minor mistakes
        default:
            return 50   // Multiple mistakes
        }
    }

    // MARK: - Migration

    /// Migrate existing progress to coins for users upgrading from pre-coins version
    /// Awards 100 coins per completed level retroactively
    /// - Parameter profile: The user profile to migrate (mutated in place)
    func migrateExistingProgress(profile: inout UserProfile) {
        guard !profile.coinsMigrationCompleted else {
            print("Coins migration already completed, skipping")
            return
        }

        var totalRetroactiveCoins = 0

        // Award 100 coins per completed level across all grades
        for (grade, levels) in profile.completedLevelsByGrade {
            let coinsForGrade = levels.count * 100
            totalRetroactiveCoins += coinsForGrade
            print("Grade \(grade): \(levels.count) completed levels = \(coinsForGrade) coins")
        }

        profile.totalCoins += totalRetroactiveCoins
        profile.coinsMigrationCompleted = true

        print("Coins migration completed: awarded \(totalRetroactiveCoins) retroactive coins")
        print("Total coins: \(profile.totalCoins)")
    }

    // MARK: - Award Coins

    /// Add coins to a profile
    /// - Parameters:
    ///   - amount: Number of coins to add
    ///   - profile: The profile to update (mutated in place)
    func awardCoins(_ amount: Int, to profile: inout UserProfile) {
        profile.totalCoins += amount
        print("Awarded \(amount) coins. New total: \(profile.totalCoins)")
    }
}
