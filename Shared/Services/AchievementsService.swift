//
//  AchievementsService.swift
//  Shared
//
//  Core engine for achievement progress tracking, unlock logic, streak tracking, and seasonal reset.
//

import Foundation

class AchievementsService {
    static let shared = AchievementsService()

    private init() {}

    // MARK: - Daily Activity & Streak

    /// Record that the user was active today. Updates streak count.
    /// Call on app launch and after level completion.
    func recordDailyActivity(profile: inout UserProfile) {
        let today = AchievementState.currentDayKey()

        // Already recorded today
        if profile.achievementState.lastActivityDate == today {
            return
        }

        let yesterday = AchievementState.dateFormatter.string(
            from: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        )

        if profile.achievementState.lastActivityDate == yesterday {
            // Consecutive day - increment streak
            profile.achievementState.currentStreakCount += 1
        } else if profile.achievementState.lastActivityDate != nil {
            // Streak broken - check if it was a break of 2+ days for "return after break"
            if let lastDate = profile.achievementState.lastActivityDate {
                let daysBetween = daysBetweenDateKeys(lastDate, today)
                if daysBetween >= 2 {
                    profile.achievementState.hasReturnedAfterBreak = true
                }
            }
            // Reset streak
            profile.achievementState.currentStreakCount = 1
        } else {
            // First ever activity
            profile.achievementState.currentStreakCount = 1
        }

        // Update longest streak
        if profile.achievementState.currentStreakCount > profile.achievementState.longestStreakCount {
            profile.achievementState.longestStreakCount = profile.achievementState.currentStreakCount
        }

        profile.achievementState.lastActivityDate = today

        // Add to activity dates
        if !profile.achievementState.dailyActivityDates.contains(today) {
            profile.achievementState.dailyActivityDates.append(today)
        }

        // Prune old activity dates (keep last 60 days)
        pruneActivityDates(profile: &profile)
    }

    private func daysBetweenDateKeys(_ fromKey: String, _ toKey: String) -> Int {
        guard let from = AchievementState.dateFormatter.date(from: fromKey),
              let to = AchievementState.dateFormatter.date(from: toKey) else { return 0 }
        return Calendar.current.dateComponents([.day], from: from, to: to).day ?? 0
    }

    private func pruneActivityDates(profile: inout UserProfile) {
        guard let cutoff = Calendar.current.date(byAdding: .day, value: -60, to: Date()) else { return }
        let cutoffKey = AchievementState.dateFormatter.string(from: cutoff)
        profile.achievementState.dailyActivityDates = profile.achievementState.dailyActivityDates.filter { $0 >= cutoffKey }
    }

    // MARK: - Seasonal Reset

    /// Check if seasonal achievements need to be reset for a new month.
    func checkSeasonalReset(profile: inout UserProfile) {
        let currentMonth = AchievementState.currentMonthKey()

        // Reset monthly coins tracking
        if profile.achievementState.monthlyCoinsSeasonKey != currentMonth {
            profile.achievementState.monthlyCoinsEarned = 0
            profile.achievementState.monthlyCoinsSeasonKey = currentMonth
        }

        // Reset weekly best score tracking
        if profile.achievementState.weeklyBestScoreSeasonKey != currentMonth {
            profile.achievementState.weeklyBestScore = 0
            profile.achievementState.weeklyBestScoreSeasonKey = currentMonth
        }

        // Reset seasonal achievement progress for new month
        for def in AchievementDefinitions.seasonal {
            if let progress = profile.achievementState.progress[def.id],
               progress.seasonKey != currentMonth {
                // Reset this seasonal achievement
                profile.achievementState.progress[def.id] = AchievementProgress(
                    currentValue: 0,
                    isUnlocked: false,
                    seasonKey: currentMonth
                )
            }
        }
    }

    // MARK: - Evaluate After Level Complete

    /// Evaluate all achievements after completing a level.
    /// Returns list of newly unlocked achievement IDs.
    @discardableResult
    func evaluateAfterLevelComplete(
        profile: inout UserProfile,
        coinsEarned: Int,
        score: Int = 0,
        correctCount: Int = 0,
        totalWords: Int = 0,
        firstTryCount: Int = 0
    ) -> [String] {
        let currentMonth = AchievementState.currentMonthKey()

        // Update monthly coins
        if profile.achievementState.monthlyCoinsSeasonKey == currentMonth {
            profile.achievementState.monthlyCoinsEarned += coinsEarned
        } else {
            profile.achievementState.monthlyCoinsEarned = coinsEarned
            profile.achievementState.monthlyCoinsSeasonKey = currentMonth
        }

        // Update weekly best score
        if profile.achievementState.weeklyBestScoreSeasonKey == currentMonth {
            profile.achievementState.weeklyBestScore = max(profile.achievementState.weeklyBestScore, score)
        } else {
            profile.achievementState.weeklyBestScore = score
            profile.achievementState.weeklyBestScoreSeasonKey = currentMonth
        }

        // Track perfect levels
        if totalWords > 0 && correctCount == totalWords {
            profile.achievementState.perfectLevelCount += 1
        }

        // Track first-try words (cumulative)
        profile.achievementState.firstTryCorrectWords += firstTryCount

        // Track accuracy (rolling last 10 levels)
        if totalWords > 0 {
            let accuracy = Double(correctCount) / Double(totalWords)
            profile.achievementState.recentLevelAccuracies.append(accuracy)
            // Keep only last 10
            if profile.achievementState.recentLevelAccuracies.count > 10 {
                profile.achievementState.recentLevelAccuracies = Array(
                    profile.achievementState.recentLevelAccuracies.suffix(10)
                )
            }
        }

        // Track best month coins
        if profile.achievementState.monthlyCoinsEarned > profile.achievementState.bestMonthCoins {
            profile.achievementState.bestMonthCoins = profile.achievementState.monthlyCoinsEarned
            profile.achievementState.bestMonthCoinsKey = currentMonth
        }

        // Record daily activity
        recordDailyActivity(profile: &profile)

        // Check seasonal reset
        checkSeasonalReset(profile: &profile)

        // Evaluate each achievement
        var newlyUnlocked: [String] = []

        for def in AchievementDefinitions.all {
            let currentProgress = profile.achievementState.progress[def.id] ?? AchievementProgress(
                seasonKey: def.isSeasonal ? currentMonth : nil
            )

            // Skip if already unlocked (and not reset)
            if currentProgress.isUnlocked {
                continue
            }

            // Calculate current value based on category
            let value = calculateValue(for: def, profile: profile)

            var updatedProgress = currentProgress
            updatedProgress.currentValue = value

            if def.isSeasonal {
                updatedProgress.seasonKey = currentMonth
            }

            // Check if newly unlocked
            if value >= def.targetValue {
                updatedProgress.isUnlocked = true
                updatedProgress.unlockDate = Date()
                newlyUnlocked.append(def.id)
            }

            profile.achievementState.progress[def.id] = updatedProgress
        }

        // Add newly unlocked to pending queue for UI display
        profile.achievementState.pendingUnlockQueue.append(contentsOf: newlyUnlocked)

        return newlyUnlocked
    }

    // MARK: - Retroactive Evaluation (first launch migration)

    /// Evaluate lifetime achievements based on existing progress.
    /// Called once when achievementsMigrationCompleted is false.
    @discardableResult
    func evaluateRetroactive(profile: inout UserProfile) -> [String] {
        var newlyUnlocked: [String] = []

        for def in AchievementDefinitions.lifetime {
            let currentProgress = profile.achievementState.progress[def.id] ?? AchievementProgress()

            if currentProgress.isUnlocked { continue }

            let value = calculateValue(for: def, profile: profile)
            var updatedProgress = currentProgress
            updatedProgress.currentValue = value

            if value >= def.targetValue {
                updatedProgress.isUnlocked = true
                updatedProgress.unlockDate = Date()
                newlyUnlocked.append(def.id)
            }

            profile.achievementState.progress[def.id] = updatedProgress
        }

        profile.achievementState.pendingUnlockQueue.append(contentsOf: newlyUnlocked)
        profile.achievementsMigrationCompleted = true

        return newlyUnlocked
    }

    // MARK: - Value Calculation

    private func calculateValue(for def: AchievementDefinition, profile: UserProfile) -> Int {
        switch def.id {
        // Skill achievements
        case "skill_perfect_5", "skill_perfect_20":
            return profile.achievementState.perfectLevelCount
        case "skill_first_try_50":
            return profile.achievementState.firstTryCorrectWords
        case "skill_accuracy_90", "grade_honor_roll":
            return rollingAccuracyPercent(profile: profile)

        // Streak achievements
        case "streak_1", "streak_3", "streak_7":
            return profile.achievementState.currentStreakCount
        case "streak_return":
            return profile.achievementState.hasReturnedAfterBreak ? 1 : 0
        case "gc_streak_30":
            return profile.achievementState.longestStreakCount

        // Coins achievements
        case "coins_1000", "coins_20000", "gc_coins_5000":
            return profile.totalCoins
        case "monthly_coins_500", "monthly_mvp":
            return profile.achievementState.monthlyCoinsEarned
        case "monthly_beat_best":
            // Unlocks when current monthly coins exceed previous best (from a different month)
            let currentMonth = AchievementState.currentMonthKey()
            if profile.achievementState.bestMonthCoinsKey != nil &&
               profile.achievementState.bestMonthCoinsKey != currentMonth &&
               profile.achievementState.monthlyCoinsEarned > profile.achievementState.bestMonthCoins {
                return 1
            }
            // Also check if current month IS the best and it beat a previous record
            if profile.achievementState.bestMonthCoinsKey == currentMonth &&
               profile.achievementState.bestMonthCoins > 0 {
                return 1
            }
            return 0

        // Level achievements
        case "levels_25", "levels_100", "gc_levels_25", "gc_levels_100":
            return profile.totalCompletedLevelsCount

        // Grade achievements
        case "grade_1_complete", "gc_grade1_complete":
            return profile.completedLevelsByGrade[1]?.count ?? 0
        case "grade_2_complete":
            return profile.completedLevelsByGrade[2]?.count ?? 0
        case "grade_3_complete":
            return profile.completedLevelsByGrade[3]?.count ?? 0
        case "grade_4_complete":
            return profile.completedLevelsByGrade[4]?.count ?? 0
        case "grade_5_complete":
            return profile.completedLevelsByGrade[5]?.count ?? 0
        case "grade_6_complete":
            return profile.completedLevelsByGrade[6]?.count ?? 0
        case "grade_7_complete":
            return profile.completedLevelsByGrade[7]?.count ?? 0
        case "grade_master":
            // Best grade completion count (any grade with all 50)
            return bestGradeCompletionCount(profile: profile)

        // Score achievements
        case "weekly_best":
            return profile.achievementState.weeklyBestScore

        default:
            return 0
        }
    }

    /// Calculate rolling accuracy as integer percentage (0-100) from last 10 levels.
    private func rollingAccuracyPercent(profile: UserProfile) -> Int {
        let accuracies = profile.achievementState.recentLevelAccuracies
        guard accuracies.count >= 10 else { return 0 }
        let average = accuracies.reduce(0.0, +) / Double(accuracies.count)
        return Int(average * 100)
    }

    /// Returns the highest level completion count across all grades.
    private func bestGradeCompletionCount(profile: UserProfile) -> Int {
        var best = 0
        for grade in 1...7 {
            let count = profile.completedLevelsByGrade[grade]?.count ?? 0
            if count > best {
                best = count
            }
        }
        return best
    }

    // MARK: - Pending Unlock Queue

    /// Pop the next pending unlock for UI display.
    /// Returns the achievement ID, or nil if queue is empty.
    func consumeNextUnlock(profile: inout UserProfile) -> String? {
        guard !profile.achievementState.pendingUnlockQueue.isEmpty else { return nil }
        return profile.achievementState.pendingUnlockQueue.removeFirst()
    }

    /// Claim coin reward for an achievement.
    func claimCoins(achievementID: String, profile: inout UserProfile) {
        guard var progress = profile.achievementState.progress[achievementID],
              progress.isUnlocked, !progress.coinsClaimed else { return }

        if let def = AchievementDefinitions.definition(for: achievementID) {
            profile.totalCoins += def.coinReward
            progress.coinsClaimed = true
            profile.achievementState.progress[achievementID] = progress
        }
    }

    /// Mark achievement as reported to Game Center.
    func markGameCenterReported(achievementID: String, profile: inout UserProfile) {
        guard var progress = profile.achievementState.progress[achievementID] else { return }
        progress.gameCenterReported = true
        profile.achievementState.progress[achievementID] = progress
    }

    /// Get all achievements that are unlocked but not yet reported to Game Center.
    func unreportedGameCenterAchievements(profile: UserProfile) -> [(AchievementDefinition, AchievementProgress)] {
        var results: [(AchievementDefinition, AchievementProgress)] = []

        for def in AchievementDefinitions.lifetime {
            guard def.gameCenterID != nil else { continue }
            if let progress = profile.achievementState.progress[def.id],
               progress.isUnlocked, !progress.gameCenterReported {
                results.append((def, progress))
            }
        }

        return results
    }

    /// Calculate progress percentage for an achievement (0.0 to 1.0).
    func progressFraction(for achievementID: String, profile: UserProfile) -> Double {
        guard let def = AchievementDefinitions.definition(for: achievementID) else { return 0 }
        let progress = profile.achievementState.progress[achievementID]
        let currentValue = progress?.currentValue ?? 0
        guard def.targetValue > 0 else { return 0 }
        return min(1.0, Double(currentValue) / Double(def.targetValue))
    }
}
