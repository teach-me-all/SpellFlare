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
    case practiceMode(level: Int, words: [Word])
    case dailyChallenge(words: [Word])
    case settings
    case achievements
    case shop
    case friends
    case competitions
    case competitionLeaderboard(competitionId: String)
    case createCompetition
    case userProfile(userId: String, username: String)

    var analyticsName: String {
        switch self {
        case .onboarding:                   return "onboarding"
        case .profilePicker:                return "profile_picker"
        case .createProfile:                return "create_profile"
        case .home:                         return "home"
        case .game:                         return "game"
        case .practiceMode:                 return "practice_mode"
        case .dailyChallenge:               return "daily_challenge"
        case .settings:                     return "settings"
        case .achievements:                 return "achievements"
        case .shop:                         return "shop"
        case .friends:                      return "friends"
        case .competitions:                 return "competitions"
        case .competitionLeaderboard:       return "competition_leaderboard"
        case .createCompetition:            return "create_competition"
        case .userProfile:                  return "user_profile"
        }
    }

    static func == (lhs: AppScreen, rhs: AppScreen) -> Bool {
        switch (lhs, rhs) {
        case (.onboarding, .onboarding),
             (.profilePicker, .profilePicker),
             (.createProfile, .createProfile),
             (.home, .home),
             (.settings, .settings),
             (.achievements, .achievements),
             (.shop, .shop),
             (.friends, .friends),
             (.competitions, .competitions),
             (.createCompetition, .createCompetition):
            return true
        case let (.game(l1), .game(l2)):
            return l1 == l2
        case let (.practiceMode(l1, w1), .practiceMode(l2, w2)):
            return l1 == l2 && w1.map(\.text) == w2.map(\.text)
        case let (.dailyChallenge(w1), .dailyChallenge(w2)):
            return w1.map(\.text) == w2.map(\.text)
        case let (.competitionLeaderboard(id1), .competitionLeaderboard(id2)):
            return id1 == id2
        case let (.userProfile(u1, _), .userProfile(u2, _)):
            return u1 == u2
        default:
            return false
        }
    }
}

@MainActor
class AppState: ObservableObject {
    @Published var currentScreen: AppScreen = .onboarding {
        didSet {
            let elapsed = Int(Date().timeIntervalSince(screenEnteredAt))
            AnalyticsManager.shared.logScreenEngagement(screen: oldValue.analyticsName, durationSeconds: elapsed)
            AnalyticsManager.shared.logScreenView(screen: currentScreen.analyticsName)
            screenEnteredAt = Date()
        }
    }
    private var screenEnteredAt = Date()
    /// The screen to return to when navigateBack() is called (e.g. from UserProfileView)
    private(set) var previousScreen: AppScreen?
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

    /// Pending competition invite code from a deep link - consumed by CompetitionListView
    @Published var pendingInviteCode: String?

    /// Share sheet data for presenting share sheets (from Watch requests)
    @Published var shareSheetData: ShareSheetData?

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

        // Listen for share requests from Watch
        NotificationCenter.default.publisher(for: .presentShareSheet)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                self?.handleShareRequest(notification.userInfo)
            }
            .store(in: &cancellables)

        // Listen for push notification taps → deep-link into competition
        NotificationCenter.default.publisher(for: .navigateFromPushNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                let userInfo = notification.userInfo
                if let competitionId = userInfo?["competitionId"] as? String {
                    self?.navigateToLeaderboard(competitionId: competitionId)
                } else {
                    self?.navigateToCompetitions()
                }
            }
            .store(in: &cancellables)
    }

    private func handleShareRequest(_ userInfo: [AnyHashable: Any]?) {
        guard let userInfo = userInfo,
              let shareType = userInfo["shareType"] as? String else { return }

        var items: [Any] = []

        if shareType == "level" {
            let level = userInfo["level"] as? Int ?? 1
            let coinsEarned = userInfo["coinsEarned"] as? Int ?? 0

            let message = ShareService.shared.generateLevelMessage(level: level, coinsEarned: coinsEarned)
            items.append(message)

            if let image = ShareService.shared.generateLevelImage(level: level, didPass: true) {
                items.insert(image, at: 0)
            }
        }

        if let url = URL(string: ShareService.appStoreURL) {
            items.append(url)
        }

        if !items.isEmpty {
            shareSheetData = ShareSheetData(activityItems: items)
        }
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

            // Submit coins to active competition (batched, non-blocking)
            if coinsEarned > 0 {
                Task { CompetitionService.shared.recordCoinsEarned(coinsEarned) }
                AnalyticsManager.shared.logCoinsEarned(amount: coinsEarned, source: "game")
            }

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

            // Re-authenticate with Firebase for the new profile
            Task { try? await FirebaseManager.shared.signIn(for: newProfile.id) }
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

    func navigateToFriends() {
        currentScreen = .friends
    }

    func navigateToCompetitions() {
        currentScreen = .competitions
    }

    func navigateToLeaderboard(competitionId: String) {
        currentScreen = .competitionLeaderboard(competitionId: competitionId)
    }

    func navigateToCreateCompetition() {
        currentScreen = .createCompetition
    }

    func navigateToUserProfile(userId: String, username: String) {
        previousScreen = currentScreen
        currentScreen = .userProfile(userId: userId, username: username)
    }

    func navigateBack() {
        if let prev = previousScreen {
            currentScreen = prev
            previousScreen = nil
        } else {
            currentScreen = .competitions
        }
    }

    func navigateToPracticeMode(level: Int, words: [Word]) {
        currentScreen = .practiceMode(level: level, words: words)
    }

    func navigateToDailyChallenge() {
        guard let profile = profile else { return }
        let challengeWords = MistakePracticeService.shared.generateDailyChallenge(profile: profile)
        guard !challengeWords.isEmpty else { return }

        let words = challengeWords.map { Word(text: $0.text, difficulty: $0.difficulty) }
        currentScreen = .dailyChallenge(words: words)
    }

    /// Complete a level with mistakes tracking
    func completeLevelWithMistakes(_ level: Int, coinsEarned: Int, incorrectWords: [Word], score: Int = 0, correctCount: Int = 0, totalWords: Int = 0, firstTryCount: Int = 0) {
        // Record mistakes first
        if !incorrectWords.isEmpty, var currentProfile = profile {
            let grade = currentProfile.grade
            let incorrectWordData = incorrectWords.map { (text: $0.text, difficulty: $0.difficulty) }
            MistakePracticeService.shared.recordLevelCompletion(
                level: level,
                grade: grade,
                incorrectWords: incorrectWordData,
                profile: &currentProfile
            )
            profile = currentProfile
        }

        // Then complete level with coins
        completeLevelWithCoins(level, coinsEarned: coinsEarned, score: score, correctCount: correctCount, totalWords: totalWords, firstTryCount: firstTryCount)
    }

    /// Complete daily practice and award coins
    func completeDailyPractice() {
        guard var currentProfile = profile else { return }

        let (baseCoins, bonusCoins) = MistakePracticeService.shared.completeDailyPractice(profile: &currentProfile)
        let totalCoins = baseCoins + bonusCoins
        CoinsService.shared.awardCoins(totalCoins, to: &currentProfile)

        profile = currentProfile
        if !uiTestingMode {
            profileManager.saveProfile(currentProfile)
            phoneSyncHelper.pushLocalChanges()
        }
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
