//
//  AchievementsView.swift
//  spelling-bee iOS App
//
//  Grid screen showing achievements organized by section with rarity indicators.
//

import SwiftUI

struct AchievementsView: View {
    @EnvironmentObject var appState: AppState

    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    @State private var selectedAchievement: AchievementDefinition?

    var body: some View {
        ZStack {
            // Purple gradient background matching HomeView
            LinearGradient(
                colors: [
                    Color(red: 0.4, green: 0.2, blue: 0.9),
                    Color(red: 0.5, green: 0.3, blue: 0.95),
                    Color(red: 0.45, green: 0.25, blue: 0.85)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Button {
                        appState.navigateToHome()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Home")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(.white)
                    }

                    Spacer()

                    Text("Achievements")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Spacer()

                    // Balance spacer for centering
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Home")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(.clear)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Daily Check-In
                        if let profile = appState.profile {
                            DailyCheckInCardView(profile: profile)
                        }

                        // Rarity legend
                        rarityLegend

                        // Sections
                        ForEach(AchievementSection.allCases, id: \.self) { section in
                            let defs = AchievementDefinitions.definitions(for: section)
                            if !defs.isEmpty {
                                achievementSection(section: section, definitions: defs)
                            }
                        }
                    }
                    .padding(.vertical, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .sheet(item: $selectedAchievement) { def in
            AchievementDetailSheet(
                definition: def,
                progress: appState.profile?.achievementState.progress[def.id],
                profile: appState.profile
            )
            .presentationDetents([.medium])
        }
    }

    // MARK: - Rarity Legend

    private var rarityLegend: some View {
        HStack(spacing: 16) {
            Spacer()
            ForEach(AchievementRarity.allCases, id: \.self) { rarity in
                HStack(spacing: 4) {
                    Circle()
                        .fill(RarityColors.borderColor(for: rarity))
                        .frame(width: 8, height: 8)
                    Text(RarityColors.rarityLabel(rarity))
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            Spacer()
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Section View

    @ViewBuilder
    private func achievementSection(section: AchievementSection, definitions: [AchievementDefinition]) -> some View {
        sectionHeader(title: section.rawValue, subtitle: sectionSubtitle(for: section))

        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(definitions) { def in
                AchievementBadge(
                    definition: def,
                    progress: appState.profile?.achievementState.progress[def.id],
                    profile: appState.profile
                )
                .onTapGesture {
                    selectedAchievement = def
                }
            }
        }
        .padding(.horizontal, 20)
    }

    private func sectionSubtitle(for section: AchievementSection) -> String {
        switch section {
        case .skill: return "Show off your spelling skills"
        case .streaks: return "Keep your daily streak going"
        case .coinsAndProgress: return "Milestones on your journey"
        case .grade: return "Master each grade level"
        case .lifetime: return "Synced to Game Center"
        case .monthly: return "Resets each month"
        }
    }

    private func sectionHeader(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Achievement Detail Sheet

struct AchievementDetailSheet: View {
    let definition: AchievementDefinition
    let progress: AchievementProgress?
    let profile: UserProfile?
    @Environment(\.dismiss) var dismiss
    @State private var showShareSheet = false

    var body: some View {
        VStack(spacing: 20) {
            // Icon with rarity styling
            ZStack {
                Circle()
                    .fill(isUnlocked
                        ? RarityColors.fillColor(for: definition.rarity, unlocked: true)
                        : Color.gray.opacity(0.15))
                    .frame(width: 80, height: 80)

                if isUnlocked {
                    Circle()
                        .stroke(
                            RarityColors.borderColor(for: definition.rarity),
                            lineWidth: RarityColors.borderWidth(for: definition.rarity)
                        )
                        .frame(width: 80, height: 80)
                }

                Image(systemName: definition.iconName)
                    .font(.system(size: 36))
                    .foregroundColor(isUnlocked
                        ? RarityColors.iconTint(for: definition.rarity, unlocked: true)
                        : .gray)
            }
            .padding(.top, 20)

            // Rarity pill
            Text(RarityColors.rarityLabel(definition.rarity))
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(RarityColors.borderColor(for: definition.rarity))
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(RarityColors.borderColor(for: definition.rarity).opacity(0.15))
                )

            // Title & description
            Text(definition.title)
                .font(.title2)
                .fontWeight(.bold)

            Text(definition.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            // Progress bar with rarity color
            VStack(spacing: 8) {
                ProgressView(value: progressFraction)
                    .tint(isUnlocked
                        ? RarityColors.progressTint(for: definition.rarity)
                        : RarityColors.progressTint(for: definition.rarity).opacity(0.5))

                HStack {
                    Text("\(currentValue)/\(definition.targetValue)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    if isUnlocked {
                        Label("Unlocked", systemImage: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }
            .padding(.horizontal, 40)

            // Coin reward
            HStack(spacing: 6) {
                Image(systemName: "bitcoinsign.circle.fill")
                    .foregroundColor(.yellow)
                Text("+\(definition.coinReward) coins")
                    .font(.subheadline)
                    .fontWeight(.medium)
                if progress?.coinsClaimed == true {
                    Text("(claimed)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            if definition.isSeasonal {
                Text("Resets monthly")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }

            Spacer()

            // Challenge Friends button (only for unlocked achievements)
            if isUnlocked {
                Button {
                    showShareSheet = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Challenge Friends")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(RarityColors.borderColor(for: definition.rarity))
                    .cornerRadius(10)
                }
                .padding(.horizontal, 40)
            }

            Button("Done") { dismiss() }
                .buttonStyle(.bordered)
                .padding(.bottom, 20)
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheetView(activityItems: shareItems) {
                showShareSheet = false
            }
        }
    }

    private var shareItems: [Any] {
        let message = ShareService.shared.generateAchievementMessage(title: definition.title, rarity: definition.rarity)
        let url = URL(string: ShareService.appStoreURL)!
        var items: [Any] = [message, url]
        if let image = ShareService.shared.generateShareImage(symbolName: definition.iconName, rarity: definition.rarity) {
            items.insert(image, at: 0)
        }
        return items
    }

    private var isUnlocked: Bool {
        progress?.isUnlocked ?? false
    }

    private var currentValue: Int {
        progress?.currentValue ?? 0
    }

    private var progressFraction: Double {
        guard let profile = profile else { return 0 }
        return AchievementsService.shared.progressFraction(for: definition.id, profile: profile)
    }
}

struct AchievementsView_Previews: PreviewProvider {
    static var previews: some View {
        AchievementsView()
            .environmentObject(AppState())
    }
}
