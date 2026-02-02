//
//  WatchHomeView.swift
//  SpellFlare Watch App
//
//  Home screen with level selection and progress display.
//

import SwiftUI

struct WatchHomeView: View {
    @EnvironmentObject var appState: WatchAppState
    @EnvironmentObject var syncHelper: WatchSyncHelper

    @State private var selectedLevel: Int = 1
    @State private var showPaywall = false

    var body: some View {
        GeometryReader { geometry in
            let isSmallWatch = geometry.size.height < 180
            let ringSize: CGFloat = isSmallWatch ? 70 : 90
            let levelFontSize: CGFloat = isSmallWatch ? 22 : 28
            let buttonPadding: CGFloat = isSmallWatch ? 6 : 10

            VStack(spacing: isSmallWatch ? 2 : 4) {
                // Header with profile indicator, settings, shop, achievements, and coins
                HStack {
                    // Active profile avatar
                    Text(syncHelper.profile?.avatarIcon ?? "🐝")
                        .font(.system(size: isSmallWatch ? 16 : 18))

                    // Settings button
                    Button {
                        appState.navigateToSettings()
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: isSmallWatch ? 16 : 18))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .buttonStyle(.plain)

                    // Shop button
                    Button {
                        appState.navigateToShop()
                    } label: {
                        Image(systemName: "cart.fill")
                            .font(.system(size: isSmallWatch ? 15 : 17))
                            .foregroundColor(.cyan)
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    // Achievements button
                    Button {
                        appState.navigateToAchievements()
                    } label: {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: isSmallWatch ? 15 : 17))
                            .foregroundColor(.yellow)
                    }
                    .buttonStyle(.plain)

                    // Coins display
                    WatchCoinsDisplayView(coins: syncHelper.profile?.totalCoins ?? 0, compact: isSmallWatch)
                }
                .padding(.horizontal, 8)
                .padding(.top, isSmallWatch ? 2 : 4)

                // Weekly check-in dots
                if let profile = syncHelper.profile {
                    let status = DailyCheckInService.shared.weeklyStatus(profile: profile)
                    HStack(spacing: 4) {
                        ForEach(0..<7, id: \.self) { index in
                            Circle()
                                .fill(status[index] ? Color.cyan : Color.white.opacity(0.2))
                                .frame(width: isSmallWatch ? 5 : 6, height: isSmallWatch ? 5 : 6)
                        }
                    }
                }

                Spacer(minLength: 0)

                // Level selection with progress ring
                ZStack {
                    // Progress ring
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: isSmallWatch ? 5 : 6)
                        .frame(width: ringSize, height: ringSize)

                    Circle()
                        .trim(from: 0, to: progressForCurrentGrade)
                        .stroke(
                            LinearGradient(
                                colors: [.cyan, .white],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: isSmallWatch ? 5 : 6, lineCap: .round)
                        )
                        .frame(width: ringSize, height: ringSize)
                        .rotationEffect(.degrees(-90))

                    // Level button
                    Button {
                        startLevelWithGating(currentLevel)
                    } label: {
                        VStack(spacing: 1) {
                            Text("Level")
                                .font(.system(size: isSmallWatch ? 9 : 11))
                                .foregroundColor(.white.opacity(0.7))

                            Text("\(currentLevel)")
                                .font(.system(size: levelFontSize, weight: .bold))
                                .foregroundColor(.white)

                            // Lock indicator for gated levels
                            if currentLevel > 5 && !syncHelper.isWatchUnlocked {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: isSmallWatch ? 8 : 10))
                                    .foregroundColor(.yellow)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }

                // Grade indicator
                Text("Grade \(syncHelper.profile?.grade ?? 1)")
                    .font(.system(size: isSmallWatch ? 10 : 11))
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.top, 1)

                Spacer(minLength: 0)

                // Start button
                Button {
                    startLevelWithGating(currentLevel)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "play.fill")
                            .font(.system(size: isSmallWatch ? 11 : 14))
                        Text("Start")
                            .font(.system(size: isSmallWatch ? 13 : 16, weight: .semibold))
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, buttonPadding)
                    .background(Color.cyan)
                    .cornerRadius(isSmallWatch ? 8 : 10)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 8)

                // Completed levels count
                HStack(spacing: 4) {
                    Text("\(completedLevelsCount)/50")
                        .font(.system(size: isSmallWatch ? 9 : 11))
                        .foregroundColor(.white.opacity(0.6))

                    if !syncHelper.isWatchUnlocked && currentLevel > 5 {
                        Image(systemName: "lock.fill")
                            .font(.system(size: isSmallWatch ? 7 : 9))
                            .foregroundColor(.yellow)
                    }
                }
                .padding(.top, 1)
                .padding(.bottom, isSmallWatch ? 2 : 4)
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
        .onAppear {
            selectedLevel = currentLevel
        }
        .sheet(isPresented: $showPaywall) {
            WatchPaywallView()
        }
    }

    // MARK: - Level Gating

    private func startLevelWithGating(_ level: Int) {
        // Gate levels 6+ for non-premium users
        if level > 5 && !syncHelper.isWatchUnlocked {
            showPaywall = true
            return
        }
        appState.startGame(level: level)
    }

    // MARK: - Computed Properties

    private var currentLevel: Int {
        syncHelper.profile?.currentLevel ?? 1
    }

    private var completedLevelsCount: Int {
        syncHelper.profile?.completedLevels.count ?? 0
    }

    private var progressForCurrentGrade: Double {
        Double(completedLevelsCount) / 50.0
    }
}

#Preview {
    WatchHomeView()
        .environmentObject(WatchAppState())
        .environmentObject(WatchSyncHelper.shared)
}
