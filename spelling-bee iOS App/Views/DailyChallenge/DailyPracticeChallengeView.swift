//
//  DailyPracticeChallengeView.swift
//  spelling-bee iOS App
//
//  Entry point for the daily practice challenge feature.
//

import SwiftUI

struct DailyPracticeChallengeView: View {
    @EnvironmentObject var appState: AppState
    let profile: UserProfile

    private var hasPracticeWords: Bool {
        MistakePracticeService.shared.isDailyChallengeAvailable(profile: profile)
    }

    private var hasPracticedToday: Bool {
        MistakePracticeService.shared.hasDailyPracticeToday(profile: profile)
    }

    private var challengeWordCount: Int {
        MistakePracticeService.shared.generateDailyChallenge(profile: profile).count
    }

    private var weeklyProgress: [Bool] {
        MistakePracticeService.shared.weeklyPracticeStatus(profile: profile)
    }

    private var weeklyCount: Int {
        MistakePracticeService.shared.weeklyPracticeCount(profile: profile)
    }

    var body: some View {
        VStack(spacing: 16) {
            // Card header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Daily Practice")
                        .font(.headline)
                        .foregroundColor(.white)

                    if hasPracticedToday {
                        Text("Completed today!")
                            .font(.caption)
                            .foregroundColor(.green)
                    } else if hasPracticeWords {
                        Text("\(challengeWordCount) words to practice")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    } else {
                        Text("No words to practice")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }

                Spacer()

                // Status icon
                if hasPracticedToday {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                } else if hasPracticeWords {
                    Image(systemName: "target")
                        .font(.title2)
                        .foregroundColor(.cyan)
                } else {
                    Image(systemName: "star.fill")
                        .font(.title2)
                        .foregroundColor(.yellow)
                }
            }

            // Weekly progress indicator
            WeeklyProgressIndicator(progress: weeklyProgress)

            // Reward preview
            if hasPracticeWords && !hasPracticedToday {
                HStack(spacing: 8) {
                    Image(systemName: "star.circle.fill")
                        .foregroundColor(.yellow)
                    Text("+\(CoinsService.dailyPracticeBaseReward) coins")
                        .font(.caption.bold())
                        .foregroundColor(.yellow)

                    if weeklyCount >= 4 {
                        Text("+ Weekly Bonus!")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }

            // Action button
            Button {
                if hasPracticeWords && !hasPracticedToday {
                    appState.navigateToDailyChallenge()
                }
            } label: {
                HStack {
                    if hasPracticedToday {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14))
                        Text("Done for today")
                    } else if hasPracticeWords {
                        Image(systemName: "play.fill")
                            .font(.system(size: 14))
                        Text("Start Practice")
                    } else {
                        Image(systemName: "star.fill")
                            .font(.system(size: 14))
                        Text("Great job!")
                    }
                }
                .font(.subheadline.bold())
                .foregroundColor(buttonForegroundColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(buttonBackgroundColor)
                .cornerRadius(10)
            }
            .disabled(hasPracticedToday || !hasPracticeWords)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.15))
        )
        .padding(.horizontal, 20)
    }

    private var buttonBackgroundColor: Color {
        if hasPracticedToday {
            return Color.green.opacity(0.3)
        } else if hasPracticeWords {
            return Color.cyan
        } else {
            return Color.yellow.opacity(0.3)
        }
    }

    private var buttonForegroundColor: Color {
        if hasPracticedToday || !hasPracticeWords {
            return .white.opacity(0.6)
        }
        return .white
    }
}

// MARK: - Weekly Progress Indicator
struct WeeklyProgressIndicator: View {
    let progress: [Bool]

    private let dayLabels = ["M", "T", "W", "T", "F", "S", "S"]

    private func isCompleted(at index: Int) -> Bool {
        guard index < progress.count else { return false }
        return progress[index]
    }

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<7, id: \.self) { index in
                VStack(spacing: 4) {
                    Circle()
                        .fill(isCompleted(at: index) ? Color.cyan : Color.white.opacity(0.2))
                        .frame(width: 24, height: 24)
                        .overlay(
                            isCompleted(at: index) ?
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                                : nil
                        )

                    Text(dayLabels[index])
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
        }
    }
}


struct DailyPracticeChallengeView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.4, green: 0.2, blue: 0.9),
                    Color(red: 0.5, green: 0.3, blue: 0.95)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            DailyPracticeChallengeView(profile: UserProfile(name: "Test", grade: 3))
                .environmentObject(AppState())
        }
    }
}
