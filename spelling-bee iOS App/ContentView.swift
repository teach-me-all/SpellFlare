//
//  ContentView.swift
//  spelling-bee iOS App
//
//  Root navigation controller for the iOS app.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ZStack {
            Group {
                switch appState.currentScreen {
                case .onboarding:
                    OnboardingView()
                case .profilePicker:
                    ProfilePickerView()
                case .createProfile:
                    CreateProfileView()
                case .home:
                    HomeView()
                case .game(let level):
                    GameView(level: level)
                        .id(level) // Force view recreation when level changes
                case .practiceMode(let level, let words):
                    PracticeModeGameView(level: level, words: words)
                        .id("practice-\(level)-\(words.count)")
                case .dailyChallenge(let words):
                    DailyChallengeGameView(words: words)
                        .id("daily-\(words.count)")
                case .settings:
                    SettingsView()
                case .achievements:
                    AchievementsView()
                case .shop:
                    ShopView()
                case .friends:
                    FriendsView()
                case .competitions:
                    CompetitionListView()
                case .competitionLeaderboard(let id):
                    CompetitionLeaderboardView(competitionId: id)
                case .createCompetition:
                    CreateCompetitionView()
                }
            }
            .animation(.easeInOut(duration: 0.3), value: appState.currentScreen)

            // Achievement unlock overlay
            if let achievementID = appState.pendingAchievementUnlock {
                AchievementUnlockOverlay(achievementID: achievementID) {
                    appState.dismissAchievementUnlock()
                }
                .transition(.opacity)
                .zIndex(100)
            }
        }
        .sheet(item: $appState.shareSheetData) { data in
            ShareSheetView(activityItems: data.activityItems) {
                appState.shareSheetData = nil
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AppState())
    }
}
