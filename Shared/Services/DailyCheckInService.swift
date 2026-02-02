//
//  DailyCheckInService.swift
//  Shared
//
//  Manages daily check-in rewards and weekly bonus tracking.
//

import Foundation

class DailyCheckInService {
    static let shared = DailyCheckInService()

    private let calendar = Calendar.current
    private let dailyReward = 50
    private let weeklyBonusReward = 50
    private let weeklyCheckInThreshold = 5

    private init() {}

    /// Whether the user has already checked in today
    func hasCheckedInToday(profile: UserProfile) -> Bool {
        guard let lastDate = profile.lastCheckInDate else { return false }
        return calendar.isDateInToday(lastDate)
    }

    /// Perform a daily check-in. Returns (baseCoins, bonusCoins) awarded.
    /// Returns (0, 0) if already checked in today.
    func performCheckIn(profile: inout UserProfile) -> (baseCoins: Int, bonusCoins: Int) {
        guard !hasCheckedInToday(profile: profile) else {
            return (0, 0)
        }

        let now = Date()

        // Reset weekly data if we're in a new week
        if let lastDate = profile.lastCheckInDate, !calendar.isDate(lastDate, equalTo: now, toGranularity: .weekOfYear) {
            profile.weeklyCheckInDates = []
            profile.weeklyBonusAwarded = false
        }

        // Record check-in
        profile.lastCheckInDate = now
        profile.weeklyCheckInDates.append(now)

        var bonusCoins = 0

        // Check for weekly bonus
        if profile.weeklyCheckInDates.count >= weeklyCheckInThreshold && !profile.weeklyBonusAwarded {
            bonusCoins = weeklyBonusReward
            profile.weeklyBonusAwarded = true
        }

        return (baseCoins: dailyReward, bonusCoins: bonusCoins)
    }

    /// Returns 7 booleans representing each day of the current week (Mon-Sun).
    /// true = checked in on that day, false = not yet.
    func weeklyStatus(profile: UserProfile) -> [Bool] {
        let now = Date()
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: now) else {
            return Array(repeating: false, count: 7)
        }

        var result: [Bool] = []
        for dayOffset in 0..<7 {
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: weekInterval.start) else {
                result.append(false)
                continue
            }
            let checkedIn = profile.weeklyCheckInDates.contains { date in
                calendar.isDate(date, inSameDayAs: day)
            }
            result.append(checkedIn)
        }
        return result
    }

    /// Number of check-ins this week
    func weeklyCheckInCount(profile: UserProfile) -> Int {
        let now = Date()
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: now) else {
            return 0
        }
        return profile.weeklyCheckInDates.filter { $0 >= weekInterval.start && $0 < weekInterval.end }.count
    }
}
