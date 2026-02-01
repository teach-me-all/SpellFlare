//
//  AppState.swift
//  spelling-bee iOS App
//
//  Global application state and navigation.
//

import Foundation
import SwiftUI
import Combine

enum AppScreen: Equatable {
    case onboarding
    case home
    case game(level: Int)
    case settings
    case achievements
    case shop
}

@MainActor
class AppState: ObservableObject {
    @Published var currentScreen: AppScreen = .onboarding
    @Published var profile: UserProfile?
    @Published private(set) var syncStatus: SyncStatus = .idle

    // MARK: - UI Testing Properties
    /// When true, GameViewModel should simulate immediate level completion
    var uiTestingSimulateLevelComplete: Bool = false
    private let uiTestingMode: Bool

    /// Currently showing achievement unlock overlay
    @Published var pendingAchievementUnlock: String?

    private let persistence = PersistenceService.shared
    private let phoneSyncHelper = PhoneSyncHelper.shared
    private let gameCenterService = GameCenterService.shared
    private let achievementsService = AchievementsService.shared
    private var cancellables = Set<AnyCancellable>()

    /// Standard initializer for production use
    init() {
        self.uiTestingMode = false
        setupSyncObserver()
        loadProfile()

        // Authenticate with Game Center for cloud backup
        Task {
            await gameCenterService.authenticate()
        }
    }

    /// UI Testing initializer - allows configuring initial state
    /// - Parameters:
    ///   - uiTestingMode: When true, uses test configuration instead of persistence
    ///   - resetState: When true, shows onboarding (fresh state)
    ///   - existingProfile: When true, creates a test profile and goes to home
    init(uiTestingMode: Bool, resetState: Bool, existingProfile: Bool) {
        self.uiTestingMode = uiTestingMode

        if uiTestingMode {
            if resetState {
                // Fresh state - show onboarding
                currentScreen = .onboarding
                profile = nil
            } else if existingProfile {
                // Create a test profile
                profile = UserProfile(name: "TestUser", grade: 3)
                currentScreen = .home
            } else {
                // Default: try to load existing profile
                loadProfile()
            }
        } else {
            setupSyncObserver()
            loadProfile()
        }
    }

    private func setupSyncObserver() {
        phoneSyncHelper.$syncStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.syncStatus = status
            }
            .store(in: &cancellables)
    }

    func loadProfile() {
        // Skip persistence in UI testing mode
        if uiTestingMode {
            return
        }

        if var savedProfile = persistence.loadProfile() {
            // Run coins migration for existing users
            if !savedProfile.coinsMigrationCompleted {
                CoinsService.shared.migrateExistingProgress(profile: &savedProfile)
                persistence.saveProfile(savedProfile)
            }
            // Run achievements migration for existing users
            if !savedProfile.achievementsMigrationCompleted {
                achievementsService.evaluateRetroactive(profile: &savedProfile)
                persistence.saveProfile(savedProfile)
            }
            // Run shop migration for existing users
            if !savedProfile.shopMigrationCompleted {
                ShopService.shared.migrateExistingProfile(profile: &savedProfile)
                persistence.saveProfile(savedProfile)
            }
            // Record daily activity and check seasonal reset
            achievementsService.recordDailyActivity(profile: &savedProfile)
            achievementsService.checkSeasonalReset(profile: &savedProfile)
            persistence.saveProfile(savedProfile)
            profile = savedProfile
            currentScreen = .home
        } else {
            currentScreen = .onboarding
        }
    }

    func createProfile(name: String, grade: Int) {
        let newProfile = UserProfile(name: name, grade: grade)
        profile = newProfile
        if !uiTestingMode {
            persistence.saveProfile(newProfile)
            phoneSyncHelper.pushLocalChanges()
        }
        currentScreen = .home
    }

    func updateGrade(_ grade: Int) {
        profile?.grade = grade
        if let profile = profile, !uiTestingMode {
            persistence.saveProfile(profile)
            phoneSyncHelper.pushLocalChanges()
        }
    }

    func completeLevel(_ level: Int) {
        profile?.completeLevel(level)
        if let profile = profile, !uiTestingMode {
            persistence.saveProfile(profile)
            phoneSyncHelper.pushLocalChanges()
        }
    }

    /// Award coins to the user and save profile
    /// - Parameter amount: Number of coins to award
    func awardCoins(_ amount: Int) {
        guard var currentProfile = profile else { return }
        CoinsService.shared.awardCoins(amount, to: &currentProfile)
        profile = currentProfile
        if !uiTestingMode {
            persistence.saveProfile(currentProfile)
            phoneSyncHelper.pushLocalChanges()
        }
    }

    /// Complete a level and award coins in one operation
    /// - Parameters:
    ///   - level: The level completed
    ///   - coinsEarned: Coins to award for this level
    func completeLevelWithCoins(_ level: Int, coinsEarned: Int, score: Int = 0, correctCount: Int = 0, totalWords: Int = 0, firstTryCount: Int = 0) {
        profile?.completeLevel(level)
        if var currentProfile = profile {
            CoinsService.shared.awardCoins(coinsEarned, to: &currentProfile)

            // Evaluate achievements
            let newlyUnlocked = achievementsService.evaluateAfterLevelComplete(
                profile: &currentProfile, coinsEarned: coinsEarned, score: score,
                correctCount: correctCount, totalWords: totalWords, firstTryCount: firstTryCount
            )

            // Claim coins for newly unlocked achievements
            for id in newlyUnlocked {
                achievementsService.claimCoins(achievementID: id, profile: &currentProfile)
            }

            profile = currentProfile
            if !uiTestingMode {
                persistence.saveProfile(currentProfile)
                phoneSyncHelper.pushLocalChanges()

                // Report GC achievements and backup to cloud
                Task {
                    self.reportUnreportedAchievements()
                    await gameCenterService.backupCurrentProfile()
                }

                // Show first pending unlock overlay
                showNextAchievementUnlock()
            }
        }
    }

    func navigateToHome() {
        currentScreen = .home
    }

    func navigateToGame(level: Int) {
        currentScreen = .game(level: level)
    }

    func navigateToSettings() {
        currentScreen = .settings
    }

    func navigateToAchievements() {
        currentScreen = .achievements
    }

    func navigateToShop() {
        currentScreen = .shop
    }

    // MARK: - Shop Methods

    func purchaseShopItem(_ itemID: String) -> ShopPurchaseResult {
        guard var currentProfile = profile else { return .itemNotFound }
        let result = ShopService.shared.purchaseItem(itemID, profile: &currentProfile)
        if result == .success {
            profile = currentProfile
            if !uiTestingMode {
                persistence.saveProfile(currentProfile)
                phoneSyncHelper.pushLocalChanges()
            }
        }
        return result
    }

    func equipShopItem(_ itemID: String) -> Bool {
        guard var currentProfile = profile else { return false }
        let result = ShopService.shared.equipItem(itemID, profile: &currentProfile)
        if result {
            profile = currentProfile
            if !uiTestingMode {
                persistence.saveProfile(currentProfile)
                phoneSyncHelper.pushLocalChanges()
            }
        }
        return result
    }

    func resetApp() {
        guard var currentProfile = profile else { return }

        // Reset only level progress, preserve everything else
        for g in 1...7 {
            currentProfile.completedLevelsByGrade[g] = []
            currentProfile.currentLevelByGrade[g] = 1
        }

        profile = currentProfile
        if !uiTestingMode {
            persistence.saveProfile(currentProfile)
            phoneSyncHelper.pushLocalChanges()
        }
        currentScreen = .home
    }

    // MARK: - Sync Triggers

    func onAppBecameActive() {
        guard !uiTestingMode else { return }
        phoneSyncHelper.syncOnAppear()

        // Record daily activity
        if var currentProfile = profile {
            achievementsService.recordDailyActivity(profile: &currentProfile)
            achievementsService.checkSeasonalReset(profile: &currentProfile)
            profile = currentProfile
            persistence.saveProfile(currentProfile)
        }

        // Reload profile after sync
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // Wait 0.5s for sync
            await MainActor.run {
                if let syncedProfile = persistence.loadProfile() {
                    self.profile = syncedProfile
                }
            }

            // Try to restore from Game Center if better data available
            if await gameCenterService.restoreAndApplyIfBetter() {
                await MainActor.run {
                    if let restoredProfile = persistence.loadProfile() {
                        self.profile = restoredProfile
                        print("Applied Game Center cloud profile")
                    }
                }
            }

            // Retry unreported GC achievements
            await MainActor.run {
                self.reportUnreportedAchievements()
            }
        }
    }

    // MARK: - Achievement Helpers

    /// Report any unlocked achievements that haven't been sent to Game Center.
    private func reportUnreportedAchievements() {
        guard var currentProfile = profile else { return }

        let unreported = achievementsService.unreportedGameCenterAchievements(profile: currentProfile)
        for (def, _) in unreported {
            if let gcID = def.gameCenterID {
                gameCenterService.reportAchievement(identifier: gcID)
                achievementsService.markGameCenterReported(achievementID: def.id, profile: &currentProfile)
            }
        }

        if !unreported.isEmpty {
            profile = currentProfile
            persistence.saveProfile(currentProfile)
        }
    }

    /// Show the next pending achievement unlock overlay.
    func showNextAchievementUnlock() {
        guard var currentProfile = profile else { return }
        if let nextID = achievementsService.consumeNextUnlock(profile: &currentProfile) {
            profile = currentProfile
            persistence.saveProfile(currentProfile)
            pendingAchievementUnlock = nextID
        } else {
            pendingAchievementUnlock = nil
        }
    }

    /// Dismiss current achievement unlock and show next if any.
    func dismissAchievementUnlock() {
        pendingAchievementUnlock = nil
        // Show next after a brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.showNextAchievementUnlock()
        }
    }
}
