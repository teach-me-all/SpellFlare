//
//  WatchAchievementsView.swift
//  SpellFlare Watch App
//
//  List view showing achievement progress on Apple Watch.
//

import SwiftUI
#if os(watchOS)
import WatchKit
#endif

struct WatchAchievementsView: View {
    @EnvironmentObject var appState: WatchAppState
    @EnvironmentObject var syncHelper: WatchSyncHelper

    var body: some View {
        GeometryReader { geometry in
            let isSmallWatch = geometry.size.height < 180
            let isLargeWatch = geometry.size.height > 220
            let headerFont: CGFloat = isSmallWatch ? 13 : (isLargeWatch ? 18 : 15)
            let checkInDotSize: CGFloat = isSmallWatch ? 12 : (isLargeWatch ? 18 : 14)
            let sectionFont: CGFloat = isSmallWatch ? 12 : (isLargeWatch ? 16 : 13)

            ScrollView {
                VStack(alignment: .leading, spacing: isSmallWatch ? 8 : 12) {
                    // Header with back button
                    HStack {
                        Button {
                            appState.currentScreen = .home
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: headerFont, weight: .semibold))
                                .foregroundColor(.cyan)
                        }
                        .buttonStyle(.plain)

                        Spacer()

                        Text("Achievements")
                            .font(.system(size: headerFont, weight: .semibold))
                            .foregroundColor(.white)

                        Spacer()

                        // Balance spacer
                        Image(systemName: "chevron.left")
                            .font(.system(size: headerFont, weight: .semibold))
                            .foregroundColor(.clear)
                    }
                    .padding(.horizontal, isSmallWatch ? 6 : 8)

                    // Daily Check-In dots
                    if let profile = syncHelper.profile {
                        let status = DailyCheckInService.shared.weeklyStatus(profile: profile)
                        let count = DailyCheckInService.shared.weeklyCheckInCount(profile: profile)
                        VStack(spacing: isSmallWatch ? 4 : 6) {
                            HStack(spacing: 3) {
                                Image(systemName: "calendar")
                                    .font(.system(size: isSmallWatch ? 10 : (isLargeWatch ? 14 : 11)))
                                    .foregroundColor(.cyan)
                                Text("Check-In")
                                    .font(.system(size: isSmallWatch ? 11 : (isLargeWatch ? 14 : 12), weight: .semibold))
                                    .foregroundColor(.white)
                                Spacer()
                                Text("\(count)/5")
                                    .font(.system(size: isSmallWatch ? 10 : (isLargeWatch ? 13 : 11), weight: .bold))
                                    .foregroundColor(.cyan)
                            }

                            HStack(spacing: isSmallWatch ? 4 : (isLargeWatch ? 8 : 6)) {
                                ForEach(0..<7, id: \.self) { index in
                                    Circle()
                                        .fill(status[index] ? Color.cyan : Color.white.opacity(0.15))
                                        .frame(width: checkInDotSize, height: checkInDotSize)
                                        .overlay(
                                            status[index] ?
                                                Image(systemName: "checkmark")
                                                    .font(.system(size: isSmallWatch ? 6 : (isLargeWatch ? 10 : 8), weight: .bold))
                                                    .foregroundColor(.white)
                                                : nil
                                        )
                                }
                            }

                            if profile.weeklyBonusAwarded {
                                Text("Bonus earned!")
                                    .font(.system(size: isSmallWatch ? 9 : (isLargeWatch ? 12 : 10)))
                                    .foregroundColor(.yellow)
                            }
                        }
                        .padding(.horizontal, isSmallWatch ? 6 : 8)
                        .padding(.bottom, isSmallWatch ? 2 : 4)

                        // Daily Practice Section
                        dailyPracticeSection(profile: profile, isSmallWatch: isSmallWatch, isLargeWatch: isLargeWatch)
                    }

                    // Sections
                    ForEach(AchievementSection.allCases, id: \.self) { section in
                        let defs = AchievementDefinitions.definitions(for: section)
                        if !defs.isEmpty {
                            Text(section.rawValue)
                                .font(.system(size: sectionFont, weight: .bold))
                                .foregroundColor(watchSectionColor(section))
                                .padding(.horizontal, isSmallWatch ? 6 : 8)
                                .padding(.top, section == .skill ? 0 : (isSmallWatch ? 4 : 8))

                            ForEach(defs) { def in
                                achievementRow(def, isSmallWatch: isSmallWatch, isLargeWatch: isLargeWatch)
                            }
                        }
                    }
                }
                .padding(.vertical, isSmallWatch ? 4 : 8)
            }
        }
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.4, green: 0.2, blue: 0.9),
                    Color(red: 0.3, green: 0.15, blue: 0.7)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .toolbar(.hidden, for: .navigationBar)
    }

    @ViewBuilder
    private func achievementRow(_ def: AchievementDefinition, isSmallWatch: Bool, isLargeWatch: Bool) -> some View {
        let progress = syncHelper.profile?.achievementState.progress[def.id]
        let isUnlocked = progress?.isUnlocked ?? false
        let fraction = progressFraction(for: def)

        let iconSize: CGFloat = isSmallWatch ? 30 : (isLargeWatch ? 44 : 36)
        let iconFontSize: CGFloat = isSmallWatch ? 14 : (isLargeWatch ? 22 : 17)
        let titleFontSize: CGFloat = isSmallWatch ? 11 : (isLargeWatch ? 16 : 13)
        let rarityDotSize: CGFloat = isSmallWatch ? 4 : (isLargeWatch ? 7 : 5)
        let checkmarkSize: CGFloat = isSmallWatch ? 10 : (isLargeWatch ? 16 : 12)
        let strokeWidth: CGFloat = isSmallWatch ? 2 : (isLargeWatch ? 3 : 2.5)

        HStack(spacing: isSmallWatch ? 6 : (isLargeWatch ? 12 : 10)) {
            // Icon with rarity-colored ring
            ZStack {
                Circle()
                    .stroke(
                        isUnlocked ? watchRarityColor(def.rarity) : Color.white.opacity(0.15),
                        lineWidth: isUnlocked ? strokeWidth : 1
                    )
                    .frame(width: iconSize, height: iconSize)

                Image(systemName: def.iconName)
                    .font(.system(size: iconFontSize))
                    .foregroundColor(isUnlocked ? watchRarityColor(def.rarity) : .white.opacity(0.3))
            }
            .frame(width: iconSize)

            VStack(alignment: .leading, spacing: isSmallWatch ? 2 : (isLargeWatch ? 6 : 4)) {
                // Title row
                HStack {
                    Text(def.title)
                        .font(.system(size: titleFontSize, weight: .medium))
                        .foregroundColor(isUnlocked ? .white : .white.opacity(0.5))
                        .lineLimit(1)

                    // Rarity dot
                    Circle()
                        .fill(watchRarityColor(def.rarity))
                        .frame(width: rarityDotSize, height: rarityDotSize)

                    Spacer()

                    if isUnlocked {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: checkmarkSize))
                            .foregroundColor(.green)
                    }
                }

                // Progress bar with rarity tint
                ProgressView(value: fraction)
                    .tint(isUnlocked ? watchRarityColor(def.rarity) : watchRarityColor(def.rarity).opacity(0.5))
                    .scaleEffect(y: isLargeWatch ? 1.0 : 0.8)
            }
        }
        .padding(.horizontal, isSmallWatch ? 6 : 8)
        .padding(.vertical, isSmallWatch ? 3 : (isLargeWatch ? 6 : 4))
        .opacity(isUnlocked ? 1.0 : 0.7)
    }

    private func progressFraction(for def: AchievementDefinition) -> Double {
        guard let profile = syncHelper.profile else { return 0 }
        return AchievementsService.shared.progressFraction(for: def.id, profile: profile)
    }

    // MARK: - Daily Practice Section

    @ViewBuilder
    private func dailyPracticeSection(profile: UserProfile, isSmallWatch: Bool, isLargeWatch: Bool) -> some View {
        let hasPracticeWords = MistakePracticeService.shared.isDailyChallengeAvailable(profile: profile)
        let hasPracticedToday = MistakePracticeService.shared.hasDailyPracticeToday(profile: profile)
        let challengeWordCount = MistakePracticeService.shared.generateDailyChallenge(profile: profile).count
        let weeklyProgress = MistakePracticeService.shared.weeklyPracticeStatus(profile: profile)
        let weeklyCount = MistakePracticeService.shared.weeklyPracticeCount(profile: profile)

        VStack(spacing: isSmallWatch ? 6 : 10) {
            // Header
            HStack(spacing: 3) {
                Image(systemName: "target")
                    .font(.system(size: isSmallWatch ? 10 : (isLargeWatch ? 14 : 11)))
                    .foregroundColor(.orange)
                Text("Daily Practice")
                    .font(.system(size: isSmallWatch ? 11 : (isLargeWatch ? 14 : 12), weight: .semibold))
                    .foregroundColor(.white)
                Spacer()

                // Status
                if hasPracticedToday {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: isSmallWatch ? 12 : (isLargeWatch ? 16 : 14)))
                        .foregroundColor(.green)
                } else if hasPracticeWords {
                    Text("\(challengeWordCount)")
                        .font(.system(size: isSmallWatch ? 10 : (isLargeWatch ? 13 : 11), weight: .bold))
                        .foregroundColor(.orange)
                }
            }

            // Weekly progress dots
            HStack(spacing: isSmallWatch ? 4 : (isLargeWatch ? 8 : 6)) {
                ForEach(0..<7, id: \.self) { index in
                    let isCompleted = index < weeklyProgress.count && weeklyProgress[index]
                    Circle()
                        .fill(isCompleted ? Color.orange : Color.white.opacity(0.15))
                        .frame(
                            width: isSmallWatch ? 10 : (isLargeWatch ? 16 : 12),
                            height: isSmallWatch ? 10 : (isLargeWatch ? 16 : 12)
                        )
                        .overlay(
                            isCompleted ?
                                Image(systemName: "checkmark")
                                    .font(.system(size: isSmallWatch ? 5 : (isLargeWatch ? 9 : 7), weight: .bold))
                                    .foregroundColor(.white)
                                : nil
                        )
                }
            }

            // Status text
            if hasPracticedToday {
                Text("Done for today!")
                    .font(.system(size: isSmallWatch ? 9 : (isLargeWatch ? 12 : 10)))
                    .foregroundColor(.green)
            } else if hasPracticeWords {
                HStack(spacing: 4) {
                    Text("\(challengeWordCount) words")
                        .font(.system(size: isSmallWatch ? 9 : (isLargeWatch ? 12 : 10)))
                        .foregroundColor(.white.opacity(0.7))
                    if weeklyCount >= 4 {
                        Text("+ Bonus!")
                            .font(.system(size: isSmallWatch ? 8 : (isLargeWatch ? 11 : 9)))
                            .foregroundColor(.yellow)
                    }
                }
            } else {
                Text("No words to practice")
                    .font(.system(size: isSmallWatch ? 9 : (isLargeWatch ? 12 : 10)))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .padding(.horizontal, isSmallWatch ? 6 : 8)
        .padding(.vertical, isSmallWatch ? 6 : 10)
        .background(Color.white.opacity(0.08))
        .cornerRadius(isSmallWatch ? 8 : 12)
        .padding(.horizontal, isSmallWatch ? 6 : 8)
        .padding(.top, isSmallWatch ? 4 : 8)
    }

    // MARK: - Watch Rarity Helpers

    private func watchRarityColor(_ rarity: AchievementRarity) -> Color {
        switch rarity {
        case .common: return .yellow
        case .rare: return .orange
        case .epic: return .purple
        case .legendary: return Color(red: 1.0, green: 0.84, blue: 0.0)
        }
    }

    private func watchRarityLabel(_ rarity: AchievementRarity) -> String {
        switch rarity {
        case .common: return "C"
        case .rare: return "R"
        case .epic: return "E"
        case .legendary: return "L"
        }
    }

    private func watchSectionColor(_ section: AchievementSection) -> Color {
        switch section {
        case .skill: return .cyan
        case .streaks: return .orange
        case .coinsAndProgress: return .yellow
        case .grade: return .green
        case .lifetime: return .purple
        case .monthly: return .cyan
        }
    }
}

#Preview {
    WatchAchievementsView()
        .environmentObject(WatchAppState())
        .environmentObject(WatchSyncHelper.shared)
}
