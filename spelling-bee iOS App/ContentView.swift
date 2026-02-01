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
                case .home:
                    HomeView()
                case .game(let level):
                    GameView(level: level)
                        .id(level) // Force view recreation when level changes
                case .settings:
                    SettingsView()
                case .achievements:
                    AchievementsView()
                case .shop:
                    ShopView()
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
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AppState())
    }
}
