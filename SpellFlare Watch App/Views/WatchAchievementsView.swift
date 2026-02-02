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
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                // Header with back button
                HStack {
                    Button {
                        appState.currentScreen = .home
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.headline)
                            .foregroundColor(.cyan)
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Text("Achievements")
                        .font(.headline)
                        .foregroundColor(.white)

                    Spacer()

                    // Balance spacer
                    Image(systemName: "chevron.left")
                        .font(.headline)
                        .foregroundColor(.clear)
                }
                .padding(.horizontal, 8)

                // Daily Check-In dots
                if let profile = syncHelper.profile {
                    let status = DailyCheckInService.shared.weeklyStatus(profile: profile)
                    let count = DailyCheckInService.shared.weeklyCheckInCount(profile: profile)
                    VStack(spacing: 6) {
                        HStack(spacing: 3) {
                            Image(systemName: "calendar")
                                .font(.system(size: 11))
                                .foregroundColor(.cyan)
                            Text("Check-In")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                            Spacer()
                            Text("\(count)/5")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.cyan)
                        }

                        HStack(spacing: 6) {
                            ForEach(0..<7, id: \.self) { index in
                                Circle()
                                    .fill(status[index] ? Color.cyan : Color.white.opacity(0.15))
                                    .frame(width: 14, height: 14)
                                    .overlay(
                                        status[index] ?
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 8, weight: .bold))
                                                .foregroundColor(.white)
                                            : nil
                                    )
                            }
                        }

                        if profile.weeklyBonusAwarded {
                            Text("Bonus earned!")
                                .font(.system(size: 10))
                                .foregroundColor(.yellow)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.bottom, 4)
                }

                // Sections
                ForEach(AchievementSection.allCases, id: \.self) { section in
                    let defs = AchievementDefinitions.definitions(for: section)
                    if !defs.isEmpty {
                        Text(section.rawValue)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(watchSectionColor(section))
                            .padding(.horizontal, 8)
                            .padding(.top, section == .skill ? 0 : 8)

                        ForEach(defs) { def in
                            achievementRow(def)
                        }
                    }
                }
            }
            .padding(.vertical, 8)
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
    private func achievementRow(_ def: AchievementDefinition) -> some View {
        let progress = syncHelper.profile?.achievementState.progress[def.id]
        let isUnlocked = progress?.isUnlocked ?? false
        let fraction = progressFraction(for: def)

        HStack(spacing: 10) {
            // Icon with rarity-colored ring
            ZStack {
                Circle()
                    .stroke(
                        isUnlocked ? watchRarityColor(def.rarity) : Color.white.opacity(0.15),
                        lineWidth: isUnlocked ? 2.5 : 1
                    )
                    .frame(width: 36, height: 36)

                Image(systemName: def.iconName)
                    .font(.system(size: 17))
                    .foregroundColor(isUnlocked ? watchRarityColor(def.rarity) : .white.opacity(0.3))
            }
            .frame(width: 36)

            VStack(alignment: .leading, spacing: 4) {
                // Title row
                HStack {
                    Text(def.title)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(isUnlocked ? .white : .white.opacity(0.5))

                    // Rarity dot
                    Circle()
                        .fill(watchRarityColor(def.rarity))
                        .frame(width: 5, height: 5)

                    Spacer()

                    if isUnlocked {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.green)
                    }
                }

                // Progress bar with rarity tint
                ProgressView(value: fraction)
                    .tint(isUnlocked ? watchRarityColor(def.rarity) : watchRarityColor(def.rarity).opacity(0.5))
                    .scaleEffect(y: 0.8)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .opacity(isUnlocked ? 1.0 : 0.7)
    }

    private func progressFraction(for def: AchievementDefinition) -> Double {
        guard let profile = syncHelper.profile else { return 0 }
        return AchievementsService.shared.progressFraction(for: def.id, profile: profile)
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
