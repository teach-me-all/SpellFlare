//
//  ContentView.swift
//  SpellFlare Watch App
//
//  Root navigation view for the Watch app.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: WatchAppState
    @EnvironmentObject var syncHelper: WatchSyncHelper

    var body: some View {
        Group {
            switch appState.currentScreen {
            case .loading:
                LoadingView()

            case .home:
                WatchHomeView()

            case .settings:
                WatchSettingsView()

            case .game(let level):
                WatchGameView(level: level)
                    .id(level)  // Force recreation when level changes

            case .levelComplete(let level, let score, let coinsEarned, let didPass):
                WatchLevelCompleteView(level: level, score: score, coinsEarned: coinsEarned, didPass: didPass)
            }
        }
        .onAppear {
            // Check if profile is already loaded on appear
            if syncHelper.profile != nil && appState.currentScreen == .loading {
                appState.currentScreen = .home
            }
        }
        .onChange(of: syncHelper.profile) { oldValue, newValue in
            if newValue != nil && appState.currentScreen == .loading {
                appState.currentScreen = .home
            }
        }
    }
}

// MARK: - Loading View
struct LoadingView: View {
    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
                .progressViewStyle(.circular)
                .tint(.cyan)

            Text("Loading...")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
}

#Preview {
    ContentView()
        .environmentObject(WatchAppState())
        .environmentObject(WatchSyncHelper.shared)
}
