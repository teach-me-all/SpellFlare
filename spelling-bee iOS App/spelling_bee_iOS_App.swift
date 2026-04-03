//
//  spelling_bee_iOS_App.swift
//  spelling-bee iOS App
//
//  Main entry point for iOS spelling bee app.
//

import SwiftUI
import GoogleMobileAds
import FirebaseCore

// MARK: - UI Testing Configuration
struct UITestingConfig {
    static var isUITesting: Bool {
        ProcessInfo.processInfo.arguments.contains("UI_TESTING")
    }

    static var shouldResetState: Bool {
        ProcessInfo.processInfo.arguments.contains("RESET_STATE")
    }

    static var hasExistingProfile: Bool {
        ProcessInfo.processInfo.arguments.contains("EXISTING_PROFILE")
    }

    static var isAdsRemoved: Bool {
        ProcessInfo.processInfo.arguments.contains("ADS_REMOVED")
    }

    static var isAdsNotRemoved: Bool {
        ProcessInfo.processInfo.arguments.contains("ADS_NOT_REMOVED")
    }

    static var simulateLevelComplete: Bool {
        ProcessInfo.processInfo.arguments.contains("SIMULATE_LEVEL_COMPLETE") ||
        ProcessInfo.processInfo.arguments.contains("LEVEL_COMPLETE_TEST")
    }
}

@main
struct spelling_bee_iOS_App: App {
    @StateObject private var appState: AppState
    @StateObject private var storeManager: StoreManager
    @Environment(\.scenePhase) private var scenePhase

    init() {
        // Configure for UI testing if needed
        if UITestingConfig.isUITesting {
            // Configure StoreManager for UI testing
            let store = StoreManager(uiTestingMode: true, adsRemoved: UITestingConfig.isAdsRemoved)
            _storeManager = StateObject(wrappedValue: store)

            // Configure AppState for UI testing
            let state = AppState(uiTestingMode: true,
                                 resetState: UITestingConfig.shouldResetState,
                                 existingProfile: UITestingConfig.hasExistingProfile)
            _appState = StateObject(wrappedValue: state)
        } else {
            _storeManager = StateObject(wrappedValue: StoreManager.shared)
            _appState = StateObject(wrappedValue: AppState())
        }

        // Configure Firebase (must be before any Firebase usage)
        FirebaseApp.configure()

        // CRITICAL: Initialize Google Mobile Ads SDK at app launch
        // This must happen before any ad requests
        Task { @MainActor in
            AdManager.shared.initializeSDK()
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(storeManager)
                .onAppear {
                    // Pass UI testing config to appState if needed
                    if UITestingConfig.simulateLevelComplete {
                        appState.uiTestingSimulateLevelComplete = true
                    }
                }
                .onChange(of: scenePhase) { newPhase in
                    if newPhase == .active {
                        appState.onAppBecameActive()
                    } else if newPhase == .background {
                        // Flush any buffered competition coins before backgrounding
                        Task { await CompetitionService.shared.flushPendingCoins() }
                    }
                }
                .onOpenURL { url in
                    // Handle spellflare://join?code=XXXXXX deep links for competition invites
                    guard url.scheme == "spellflare",
                          url.host == "join",
                          let code = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                              .queryItems?.first(where: { $0.name == "code" })?.value
                    else { return }
                    appState.pendingInviteCode = code
                    appState.navigateToCompetitions()
                }
        }
    }
}
