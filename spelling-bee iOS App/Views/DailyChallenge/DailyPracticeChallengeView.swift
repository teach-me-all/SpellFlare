//
//  DailyPracticeChallengeView.swift
//  spelling-bee iOS App
//
//  Compact daily practice challenge card for home screen.
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
        Button {
            if hasPracticeWords && !hasPracticedToday {
                appState.navigateToDailyChallenge()
            }
        } label: {
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(iconBackground)
                        .frame(width: 40, height: 40)

                    Image(systemName: iconName)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(iconColor)
                }

                // Title and status
                VStack(alignment: .leading, spacing: 2) {
                    Text("Daily Practice")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)

                    Text(statusText)
                        .font(.system(size: 12))
                        .foregroundColor(statusColor)
                }

                Spacer()

                // Weekly dots (compact)
                HStack(spacing: 4) {
                    ForEach(0..<7, id: \.self) { index in
                        Circle()
                            .fill(weeklyProgress.indices.contains(index) && weeklyProgress[index]
                                  ? Color.orange : Color.white.opacity(0.2))
                            .frame(width: 8, height: 8)
                    }
                }

                // Action indicator
                if hasPracticedToday {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.green)
                } else if hasPracticeWords {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.cyan)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.12))
            )
        }
        .buttonStyle(.plain)
        .disabled(hasPracticedToday || !hasPracticeWords)
        .padding(.horizontal, 20)
    }

    private var iconName: String {
        if hasPracticedToday {
            return "checkmark"
        } else if hasPracticeWords {
            return "target"
        } else {
            return "star.fill"
        }
    }

    private var iconBackground: Color {
        if hasPracticedToday {
            return Color.green.opacity(0.2)
        } else if hasPracticeWords {
            return Color.orange.opacity(0.2)
        } else {
            return Color.yellow.opacity(0.2)
        }
    }

    private var iconColor: Color {
        if hasPracticedToday {
            return .green
        } else if hasPracticeWords {
            return .orange
        } else {
            return .yellow
        }
    }

    private var statusText: String {
        if hasPracticedToday {
            return "Done for today!"
        } else if hasPracticeWords {
            return "\(challengeWordCount) words · +\(CoinsService.dailyPracticeBaseReward) coins"
        } else {
            return "No mistakes to practice"
        }
    }

    private var statusColor: Color {
        if hasPracticedToday {
            return .green
        } else if hasPracticeWords {
            return .white.opacity(0.7)
        } else {
            return .white.opacity(0.5)
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

            VStack {
                DailyPracticeChallengeView(profile: UserProfile(name: "Test", grade: 3))
                    .environmentObject(AppState())
            }
        }
    }
}
