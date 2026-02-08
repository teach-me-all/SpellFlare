//
//  WatchSyncHelper.swift
//  SpellFlare Watch App
//
//  Handles WatchConnectivity sync between Watch and iPhone.
//

import Foundation
import WatchConnectivity

@MainActor
class WatchSyncHelper: NSObject, ObservableObject {
    static let shared = WatchSyncHelper()

    // MARK: - Published State
    @Published var profile: UserProfile?
    @Published var isPhoneReachable = false
    @Published var lastSyncDate: Date?
    @Published var hasPendingChanges = false
    @Published var isWatchUnlocked: Bool = false  // Premium state synced from iPhone
    @Published var activeProfileID: UUID?  // Active profile ID from iPhone

    // MARK: - Private Properties
    private var session: WCSession?

    // MARK: - Initialization
    override init() {
        super.init()

        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }

        // Load local profile
        loadLocalProfile()
    }

    // MARK: - Profile Management

    /// Request profile from iPhone
    func requestProfile() {
        guard let session = session, session.isReachable else {
            print("iPhone not reachable, using local profile")
            loadLocalProfile()
            return
        }

        session.sendMessage(["type": "requestProfile"], replyHandler: { [weak self] response in
            Task { @MainActor in
                self?.handleProfileResponse(response)
            }
        }, errorHandler: { [weak self] error in
            print("Failed to request profile: \(error)")
            Task { @MainActor in
                self?.loadLocalProfile()
            }
        })
    }

    private func handleProfileResponse(_ response: [String: Any]) {
        guard let data = response["profile"] as? Data else {
            print("Invalid profile response")
            loadLocalProfile()
            return
        }

        do {
            let syncable = try JSONDecoder().decode(SyncableProfile.self, from: data)
            self.profile = syncable.profile
            self.isWatchUnlocked = syncable.isWatchUnlocked
            LocalCacheService.shared.saveSyncableProfile(syncable)
            savePremiumState(syncable.isWatchUnlocked)
            // Extract active profile ID if present
            if let idString = response["activeProfileID"] as? String, let id = UUID(uuidString: idString) {
                self.activeProfileID = id
                saveActiveProfileID(id)
            }
            self.lastSyncDate = Date()
            print("Profile synced from iPhone: \(syncable.profile.name), premium: \(syncable.isWatchUnlocked)")
        } catch {
            print("Failed to decode profile: \(error)")
            loadLocalProfile()
        }
    }

    /// Load profile from local storage
    private func loadLocalProfile() {
        if let syncable = LocalCacheService.shared.loadSyncableProfile() {
            var loadedProfile = syncable.profile
            self.isWatchUnlocked = syncable.isWatchUnlocked

            // Daily check-in on app launch
            let checkInReward = DailyCheckInService.shared.performCheckIn(profile: &loadedProfile)
            if checkInReward.baseCoins > 0 {
                loadedProfile.totalCoins += checkInReward.baseCoins + checkInReward.bonusCoins
                let updated = SyncableProfile(profile: loadedProfile, deviceIdentifier: DeviceIdentifier.current, isWatchUnlocked: syncable.isWatchUnlocked)
                LocalCacheService.shared.saveSyncableProfile(updated)
            }

            self.profile = loadedProfile
            print("Loaded local profile: \(loadedProfile.name), premium: \(syncable.isWatchUnlocked)")
        } else {
            // Create default profile for standalone mode
            let defaultProfile = UserProfile(name: "Player", grade: 1)
            self.profile = defaultProfile
            let syncable = SyncableProfile(profile: defaultProfile, deviceIdentifier: DeviceIdentifier.current)
            LocalCacheService.shared.saveSyncableProfile(syncable)
            print("Created default profile")
        }
        // Also load persisted premium state and active profile ID
        loadPremiumState()
        loadActiveProfileID()
    }

    // MARK: - Premium State Persistence

    private let premiumKey = "watch_isWatchUnlocked"
    private let activeProfileIDKey = "watch_activeProfileID"

    /// Save premium state to UserDefaults for persistence
    private func savePremiumState(_ isWatchUnlocked: Bool) {
        UserDefaults.standard.set(isWatchUnlocked, forKey: premiumKey)
        print("Saved premium state: \(isWatchUnlocked)")
    }

    /// Load premium state from UserDefaults
    private func loadPremiumState() {
        let savedPremium = UserDefaults.standard.bool(forKey: premiumKey)
        if savedPremium {
            self.isWatchUnlocked = savedPremium
            print("Loaded persisted premium state: \(savedPremium)")
        }
    }

    /// Save active profile ID to UserDefaults
    private func saveActiveProfileID(_ id: UUID) {
        UserDefaults.standard.set(id.uuidString, forKey: activeProfileIDKey)
    }

    /// Load active profile ID from UserDefaults
    private func loadActiveProfileID() {
        if let str = UserDefaults.standard.string(forKey: activeProfileIDKey),
           let id = UUID(uuidString: str) {
            self.activeProfileID = id
        }
    }

    // MARK: - Level Completion

    /// Called when a level is completed on the Watch
    func sendLevelCompleted(_ level: Int, coinsEarned: Int = 0, score: Int = 0, correctCount: Int = 0, totalWords: Int = 0, firstTryCount: Int = 0) {
        guard var currentProfile = self.profile else { return }

        // Update local profile
        currentProfile.completeLevel(level)

        // Evaluate achievements
        let newlyUnlocked = AchievementsService.shared.evaluateAfterLevelComplete(
            profile: &currentProfile, coinsEarned: coinsEarned, score: score,
            correctCount: correctCount, totalWords: totalWords, firstTryCount: firstTryCount
        )
        for id in newlyUnlocked {
            AchievementsService.shared.claimCoins(achievementID: id, profile: &currentProfile)
        }

        self.profile = currentProfile

        // Save locally
        let syncable = SyncableProfile(profile: currentProfile, deviceIdentifier: DeviceIdentifier.current)
        LocalCacheService.shared.saveSyncableProfile(syncable)

        // Send to iPhone if reachable
        guard let session = session, session.isReachable else {
            hasPendingChanges = true
            print("iPhone not reachable, saved locally")
            return
        }

        guard let data = try? JSONEncoder().encode(syncable) else { return }

        session.sendMessage([
            "type": "levelCompleted",
            "profile": data
        ], replyHandler: { [weak self] _ in
            Task { @MainActor in
                self?.hasPendingChanges = false
                self?.lastSyncDate = Date()
                print("Level completion synced to iPhone")
            }
        }, errorHandler: { [weak self] error in
            print("Failed to sync level completion: \(error)")
            Task { @MainActor in
                self?.hasPendingChanges = true
            }
        })
    }

    // MARK: - Share Request

    /// Send a share request to iPhone to present share sheet
    /// - Parameters:
    ///   - type: Share type ("level" or "achievement")
    ///   - level: The level number (for level shares)
    ///   - grade: The current grade
    ///   - coinsEarned: Coins earned (for level shares)
    func sendShareRequest(type: String, level: Int, grade: Int, coinsEarned: Int) {
        guard let session = session, session.isReachable else {
            print("iPhone not reachable for share request")
            return
        }

        let message: [String: Any] = [
            "type": "shareRequest",
            "shareType": type,
            "level": level,
            "grade": grade,
            "coinsEarned": coinsEarned
        ]

        session.sendMessage(message, replyHandler: nil) { error in
            print("Failed to send share request: \(error)")
        }
    }

    // MARK: - Practice Completion

    /// Called when a practice session (level practice or daily) is completed on Watch
    func sendPracticeCompleted(isDailyChallenge: Bool = false) {
        guard let currentProfile = self.profile else { return }

        // Save locally
        let syncable = SyncableProfile(profile: currentProfile, deviceIdentifier: DeviceIdentifier.current)
        LocalCacheService.shared.saveSyncableProfile(syncable)

        // Send to iPhone if reachable
        guard let session = session, session.isReachable else {
            hasPendingChanges = true
            print("iPhone not reachable, saved practice locally")
            return
        }

        guard let data = try? JSONEncoder().encode(syncable) else { return }

        let messageType = isDailyChallenge ? "dailyPracticeCompleted" : "practiceLevelCompleted"
        session.sendMessage([
            "type": messageType,
            "profile": data
        ], replyHandler: { [weak self] _ in
            Task { @MainActor in
                self?.hasPendingChanges = false
                self?.lastSyncDate = Date()
                print("Practice completion synced to iPhone")
            }
        }, errorHandler: { [weak self] error in
            print("Failed to sync practice completion: \(error)")
            Task { @MainActor in
                self?.hasPendingChanges = true
            }
        })
    }

    // MARK: - Grade Update (Watch → iPhone not supported, view only)

    /// Update grade locally (standalone mode only)
    func updateGradeLocally(_ grade: Int) {
        guard var currentProfile = self.profile else { return }
        currentProfile.grade = grade
        self.profile = currentProfile

        let syncable = SyncableProfile(profile: currentProfile, deviceIdentifier: DeviceIdentifier.current)
        LocalCacheService.shared.saveSyncableProfile(syncable)
        hasPendingChanges = true
    }

    // MARK: - Pending Sync

    /// Retry pending changes when phone becomes reachable
    func retryPendingSync() {
        guard hasPendingChanges, let profile = profile else { return }
        guard let session = session, session.isReachable else { return }

        let syncable = SyncableProfile(profile: profile, deviceIdentifier: DeviceIdentifier.current)
        guard let data = try? JSONEncoder().encode(syncable) else { return }

        session.sendMessage([
            "type": "profileUpdated",
            "profile": data
        ], replyHandler: { [weak self] _ in
            Task { @MainActor in
                self?.hasPendingChanges = false
                self?.lastSyncDate = Date()
                print("Pending sync completed")
            }
        }, errorHandler: { error in
            print("Pending sync failed: \(error)")
        })
    }
}

// MARK: - WCSessionDelegate
extension WatchSyncHelper: WCSessionDelegate {

    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Task { @MainActor in
            self.isPhoneReachable = session.isReachable
            print("WCSession activated, reachable: \(session.isReachable)")

            if session.isReachable {
                self.requestProfile()
                self.retryPendingSync()
            }
        }
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            self.isPhoneReachable = session.isReachable
            print("Reachability changed: \(session.isReachable)")

            if session.isReachable {
                self.retryPendingSync()
            }
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        Task { @MainActor in
            self.handleReceivedMessage(message)
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        Task { @MainActor in
            self.handleReceivedMessage(message)
            replyHandler(["status": "received"])
        }
    }

    private func handleReceivedMessage(_ message: [String: Any]) {
        guard let type = message["type"] as? String else { return }

        switch type {
        case "profileUpdated":
            if let data = message["profile"] as? Data,
               let syncable = try? JSONDecoder().decode(SyncableProfile.self, from: data) {
                self.profile = syncable.profile
                self.isWatchUnlocked = syncable.isWatchUnlocked
                LocalCacheService.shared.saveSyncableProfile(syncable)
                savePremiumState(syncable.isWatchUnlocked)
                if let idString = message["activeProfileID"] as? String, let id = UUID(uuidString: idString) {
                    self.activeProfileID = id
                    saveActiveProfileID(id)
                }
                self.lastSyncDate = Date()
                print("Profile updated from iPhone, premium: \(syncable.isWatchUnlocked)")
            }

        case "gradeChanged":
            if let data = message["profile"] as? Data,
               let syncable = try? JSONDecoder().decode(SyncableProfile.self, from: data) {
                self.profile = syncable.profile
                self.isWatchUnlocked = syncable.isWatchUnlocked
                LocalCacheService.shared.saveSyncableProfile(syncable)
                savePremiumState(syncable.isWatchUnlocked)
                if let idString = message["activeProfileID"] as? String, let id = UUID(uuidString: idString) {
                    self.activeProfileID = id
                    saveActiveProfileID(id)
                }
                print("Grade changed from iPhone: \(syncable.profile.grade), premium: \(syncable.isWatchUnlocked)")
            }

        default:
            print("Unknown message type: \(type)")
        }
    }
}
