//
//  DailyCheckInCardView.swift
//  spelling-bee iOS App
//
//  Weekly check-in tracker card shown on the home screen.
//

import SwiftUI

struct DailyCheckInCardView: View {
    let profile: UserProfile

    private let service = DailyCheckInService.shared
    private let weekdayLabels = ["M", "T", "W", "T", "F", "S", "S"]

    var body: some View {
        let status = service.weeklyStatus(profile: profile)
        let count = service.weeklyCheckInCount(profile: profile)
        let bonusEarned = profile.weeklyBonusAwarded

        VStack(spacing: 12) {
            // Header
            HStack {
                Image(systemName: "calendar")
                    .font(.system(size: 16))
                    .foregroundColor(.cyan)
                Text("Daily Check-In")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
                Text("\(count)/5")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.cyan)
            }

            // Weekday circles
            HStack(spacing: 0) {
                ForEach(0..<7, id: \.self) { index in
                    VStack(spacing: 4) {
                        ZStack {
                            Circle()
                                .fill(status[index] ? Color.cyan : Color.white.opacity(0.15))
                                .frame(width: 32, height: 32)

                            if status[index] {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }

                        Text(weekdayLabels[index])
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .frame(maxWidth: .infinity)
                }
            }

            // Footer text
            Text(bonusEarned ? "Weekly bonus earned!" : "Check in 5 days this week to earn a 50-coin bonus!")
                .font(.system(size: 12))
                .foregroundColor(bonusEarned ? .yellow : .white.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .padding(16)
        .background(Color.white.opacity(0.12))
        .cornerRadius(16)
        .padding(.horizontal, 20)
    }
}
