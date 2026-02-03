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
    case profilePicker
    case createProfile
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

    /// Pending daily check-in reward to show animation
    @Published var pendingCheckInReward: (baseCoins: Int, bonusCoins: Int)?

    private let persistence = PersistenceService.shared
    private let phoneSyncHelper = PhoneSyncHelper.shared
    private let gameCenterService = GameCenterService.shared
    private let achievementsService = AchievementsService.shared
    let profileManager = ProfileManager.shared
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

        // Run multi-profile migration if needed
        profileManager.migrateFromSingleProfileIfNeeded()

        // Try loading active profile from ProfileManager
        if var savedProfile = profileManager.loadActiveProfile() {
            runMigrations(&savedProfile)

            // Daily check-in on app launch
            let checkInReward = DailyCheckInService.shared.performCheckIn(profile: &savedProfile)
            if checkInReward.baseCoins > 0 {
                CoinsService.shared.awardCoins(checkInReward.baseCoins + checkInReward.bonusCoins, to: &savedProfile)
                profileManager.saveProfile(savedProfile)
                pendingCheckInReward = checkInReward
            }

            profile = savedProfile
            currentScreen = .home
        } else if profileManager.allProfiles.count > 0 {
            // Profiles exist but none active - show picker
            currentScreen = .profilePicker
        } else {
            currentScreen = .onboarding
        }
    }

    private func runMigrations(_ savedProfile: inout UserProfile) {
        // Run coins migration for existing users
        if !savedProfile.coinsMigrationCompleted {
            CoinsService.shared.migrateExistingProgress(profile: &savedProfile)
        }
        // Run achievements migration for existing users
        if !savedProfile.achievementsMigrationCompleted {
            achievementsService.evaluateRetroactive(profile: &savedProfile)
        }
        // Run shop migration for existing users
        if !savedProfile.shopMigrationCompleted {
            ShopService.shared.migrateExistingProfile(profile: &savedProfile)
        }
        // Record daily activity and check seasonal reset
        achievementsService.recordDailyActivity(profile: &savedProfile)
        achievementsService.checkSeasonalReset(profile: &savedProfile)
        profileManager.saveProfile(savedProfile)
    }

    func createProfile(name: String, grade: Int, avatarIcon: String = "🐝") {
        if uiTestingMode {
            let newProfile = UserProfile(name: name, grade: grade, avatarIcon: avatarIcon)
            profile = newProfile
            currentScreen = .home
            return
        }
        let newProfile = profileManager.createProfile(name: name, avatarIcon: avatarIcon, grade: grade)
        profile = newProfile
        phoneSyncHelper.pushLocalChanges()
        currentScreen = .home
    }

    func updateGrade(_ grade: Int) {
        profile?.grade = grade
        if let profile = profile, !uiTestingMode {
            profileManager.saveProfile(profile)
            phoneSyncHelper.pushLocalChanges()
        }
    }

    func completeLevel(_ level: Int) {
        profile?.completeLevel(level)
        if let profile = profile, !uiTestingMode {
            profileManager.saveProfile(profile)
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
            profileManager.saveProfile(currentProfile)
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
                profileManager.saveProfile(currentProfile)
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

    // MARK: - Profile Management

    func switchProfile(to id: UUID) {
        guard !uiTestingMode else { return }
        // Save current first
        if let current = profile {
            profileManager.saveProfile(current)
        }
        if var newProfile = profileManager.switchToProfile(id: id) {
            runMigrations(&newProfile)

            // Daily check-in for switched profile
            let checkInReward = DailyCheckInService.shared.performCheckIn(profile: &newProfile)
            if checkInReward.baseCoins > 0 {
                CoinsService.shared.awardCoins(checkInReward.baseCoins + checkInReward.bonusCoins, to: &newProfile)
                profileManager.saveProfile(newProfile)
                pendingCheckInReward = checkInReward
            }

            profile = newProfile
            phoneSyncHelper.pushLocalChanges()
            currentScreen = .home
        }
    }

    func createNewProfile(name: String, avatarIcon: String, grade: Int) {
        let newProfile = profileManager.createProfile(name: name, avatarIcon: avatarIcon, grade: grade)
        profile = newProfile
        if !uiTestingMode {
            phoneSyncHelper.pushLocalChanges()
        }
        currentScreen = .home
    }

    func deleteProfile(id: UUID) {
        guard !uiTestingMode else { return }

        // Delete cloud backup
        Task {
            await gameCenterService.deleteProfileBackup(id: id)
        }

        _ = profileManager.deleteProfile(id: id)

        if profileManager.allProfiles.isEmpty {
            profile = nil
            currentScreen = .onboarding
        } else if profileManager.activeProfileID != nil {
            profile = profileManager.activeProfile
            currentScreen = .home
        } else {
            currentScreen = .profilePicker
        }
    }

    func showProfilePicker() {
        currentScreen = .profilePicker
    }

    func showCreateProfile() {
        currentScreen = .createProfile
    }

    // MARK: - Navigation

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
                profileManager.saveProfile(currentProfile)
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
                profileManager.saveProfile(currentProfile)
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
            profileManager.saveProfile(currentProfile)
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
            profileManager.saveProfile(currentProfile)
        }

        // Reload profile after sync
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // Wait 0.5s for sync
            await MainActor.run {
                if let syncedProfile = self.profileManager.loadActiveProfile() {
                    self.profile = syncedProfile
                }
            }

            // Try to restore from Game Center if better data available
            if await gameCenterService.restoreAndApplyIfBetter() {
                await MainActor.run {
                    if let restoredProfile = self.profileManager.loadActiveProfile() {
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
            profileManager.saveProfile(currentProfile)
        }
    }

    /// Show the next pending achievement unlock overlay.
    func showNextAchievementUnlock() {
        guard var currentProfile = profile else { return }
        if let nextID = achievementsService.consumeNextUnlock(profile: &currentProfile) {
            profile = currentProfile
            profileManager.saveProfile(currentProfile)
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
