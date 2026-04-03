//
//  PhoneSyncHelper.swift
//  spelling-bee iOS App
//
//  Handles phone-to-watch sync via WatchConnectivity.
//

import Foundation
import WatchConnectivity
import Combine

@MainActor
class PhoneSyncHelper: NSObject, ObservableObject {
    static let shared = PhoneSyncHelper()

    @Published private(set) var isWatchReachable = false
    @Published private(set) var syncStatus: SyncStatus = .idle

    private let session: WCSession
    private let localCache = LocalCacheService.shared

    private override init() {
        self.session = WCSession.default
        super.init()

        if WCSession.isSupported() {
            session.delegate = self
            session.activate()
        }
    }

    // MARK: - Sync Methods

    /// Called when app becomes active - request profile from Watch if needed
    func syncOnAppear() {
        guard session.isReachable else {
            syncStatus = .idle
            return
        }

        syncStatus = .syncing

        // Request profile from Watch to merge
        session.sendMessage(
            ["action": "requestProfile"],
            replyHandler: { [weak self] reply in
                Task { @MainActor in
                    self?.handleProfileReply(reply)
                }
            },
            errorHandler: { [weak self] error in
                Task { @MainActor in
                    print("Watch sync error: \(error)")
                    self?.syncStatus = .error(error.localizedDescription)
                }
            }
        )
    }

    private func handleProfileReply(_ reply: [String: Any]) {
        if let profileData = reply["profile"] as? Data,
           let remoteProfile = try? JSONDecoder().decode(SyncableProfile.self, from: profileData) {

            // Merge with local
            if let local = localCache.loadSyncableProfile() {
                let merged = SyncableProfile.merge(local: local, remote: remoteProfile)
                localCache.saveSyncableProfile(merged)

                // If local was newer, send it to Watch
                if merged.lastModified == local.lastModified {
                    sendProfileToWatch(local)
                }
            } else {
                // No local profile, use remote
                localCache.saveSyncableProfile(remoteProfile)
            }

            syncStatus = .success
        } else if reply["noProfile"] as? Bool == true {
            // Watch has no profile, send ours if we have one
            if let local = localCache.loadSyncableProfile() {
                sendProfileToWatch(local)
            }
            syncStatus = .success
        } else {
            syncStatus = .idle
        }
    }

    /// Send profile to Watch
    func sendProfileToWatch(_ profile: SyncableProfile) {
        guard session.isReachable else { return }

        guard let data = try? JSONEncoder().encode(profile) else { return }

        var message: [String: Any] = ["action": "profileUpdated", "profile": data]
        if let activeID = ProfileManager.shared.activeProfileID {
            message["activeProfileID"] = activeID.uuidString
        }

        session.sendMessage(
            message,
            replyHandler: nil,
            errorHandler: { error in
                print("Failed to send profile to Watch: \(error)")
            }
        )
    }

    /// Sync Watch unlock state after purchase
    func syncWatchUnlockState() {
        guard session.isReachable else {
            print("Watch not reachable, cannot sync Watch unlock state")
            return
        }

        // Get current profile and update with Watch unlock state
        let isWatchUnlocked = StoreManager.shared.isWatchUnlocked
        if let local = localCache.loadSyncableProfile() {
            var updatedProfile = local
            updatedProfile.isWatchUnlocked = isWatchUnlocked
            updatedProfile.lastModified = Date()

            // Save locally and send to Watch
            localCache.saveSyncableProfile(updatedProfile)

            guard let data = try? JSONEncoder().encode(updatedProfile) else { return }

            // Send profile update
            session.sendMessage(
                ["action": "profileUpdated", "profile": data],
                replyHandler: nil,
                errorHandler: { error in
                    print("Failed to sync Watch unlock state via profile: \(error)")
                }
            )

            // Also send direct purchase state update for WatchStoreManager
            session.sendMessage(
                ["type": "purchaseStateUpdated", "isWatchUnlocked": isWatchUnlocked],
                replyHandler: nil,
                errorHandler: { error in
                    print("Failed to sync purchase state to Watch: \(error)")
                }
            )

            print("Watch unlock state synced: \(isWatchUnlocked)")
        }
    }

    /// Called after local profile changes - push to Watch
    func pushLocalChanges() {
        if var local = localCache.loadSyncableProfile(), session.isReachable {
            // Always update Watch unlock state before pushing
            local.isWatchUnlocked = StoreManager.shared.isWatchUnlocked
            localCache.saveSyncableProfile(local)
            sendProfileToWatch(local)
        }
    }

    /// Send grade change notification to Watch
    func notifyGradeChanged(_ profile: SyncableProfile) {
        guard session.isReachable else { return }

        guard let data = try? JSONEncoder().encode(profile) else { return }

        session.sendMessage(
            ["type": "gradeChanged", "profile": data],
            replyHandler: nil,
            errorHandler: { error in
                print("Failed to notify Watch of grade change: \(error)")
            }
        )
    }
}

// MARK: - WCSessionDelegate

extension PhoneSyncHelper: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Task { @MainActor in
            isWatchReachable = session.isReachable
        }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {
        // Required for iOS
    }

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        // Required for iOS - reactivate session
        session.activate()
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            isWatchReachable = session.isReachable
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        Task { @MainActor in
            handleReceivedMessage(message)
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        Task { @MainActor in
            handleReceivedMessage(message, replyHandler: replyHandler)
        }
    }

    @MainActor
    private func handleReceivedMessage(_ message: [String: Any], replyHandler: (([String: Any]) -> Void)? = nil) {
        // Support both "action" (legacy) and "type" (new Watch app) keys
        let messageType = (message["action"] as? String) ?? (message["type"] as? String)

        guard let type = messageType else {
            print("Unknown message format: \(message)")
            return
        }

        switch type {
        case "requestSync", "requestProfile":
            // Watch is requesting our profile
            if let local = localCache.loadSyncableProfile(),
               let data = try? JSONEncoder().encode(local) {
                var reply: [String: Any] = ["profile": data]
                if let activeID = ProfileManager.shared.activeProfileID {
                    reply["activeProfileID"] = activeID.uuidString
                }
                replyHandler?(reply)
                print("Sent profile to Watch: \(local.profile.name)")
            } else {
                replyHandler?(["noProfile": true])
                print("No profile to send to Watch")
            }

        case "updateProfile", "profileUpdated":
            // Watch pushed an updated profile
            if let profileData = message["profile"] as? Data,
               let remoteProfile = try? JSONDecoder().decode(SyncableProfile.self, from: profileData) {

                if let local = localCache.loadSyncableProfile() {
                    let merged = SyncableProfile.merge(local: local, remote: remoteProfile)
                    localCache.saveSyncableProfile(merged)
                    print("Merged profile from Watch: \(merged.profile.name)")

                    // Notify observers that profile changed
                    NotificationCenter.default.post(
                        name: .profileUpdatedFromWatch,
                        object: nil,
                        userInfo: ["profile": merged.profile]
                    )
                } else {
                    localCache.saveSyncableProfile(remoteProfile)
                    print("Saved new profile from Watch: \(remoteProfile.profile.name)")
                }
            }

        case "levelCompleted":
            // Watch completed a level - update local profile
            if let profileData = message["profile"] as? Data,
               let remoteProfile = try? JSONDecoder().decode(SyncableProfile.self, from: profileData) {

                if let local = localCache.loadSyncableProfile() {
                    let merged = SyncableProfile.merge(local: local, remote: remoteProfile)
                    localCache.saveSyncableProfile(merged)
                    print("Level completion from Watch: \(merged.profile.name)")

                    // Notify observers that progress changed
                    NotificationCenter.default.post(
                        name: .profileUpdatedFromWatch,
                        object: nil,
                        userInfo: ["profile": merged.profile]
                    )
                } else {
                    localCache.saveSyncableProfile(remoteProfile)
                }
            }

        case "gradeChanged":
            // Grade changed on iPhone - this is handled by sendProfileToWatch
            // Nothing to do here as this is an outgoing message type
            break

        case "shareRequest":
            // Watch wants to share - post notification for AppState to handle
            NotificationCenter.default.post(
                name: .presentShareSheet,
                object: nil,
                userInfo: message
            )

        case "practiceLevelCompleted", "dailyPracticeCompleted":
            // Watch completed a practice session - update local profile
            if let profileData = message["profile"] as? Data,
               let remoteProfile = try? JSONDecoder().decode(SyncableProfile.self, from: profileData) {

                if let local = localCache.loadSyncableProfile() {
                    let merged = SyncableProfile.merge(local: local, remote: remoteProfile)
                    localCache.saveSyncableProfile(merged)
                    print("Practice completion from Watch: \(merged.profile.name)")

                    NotificationCenter.default.post(
                        name: .profileUpdatedFromWatch,
                        object: nil,
                        userInfo: ["profile": merged.profile]
                    )
                } else {
                    localCache.saveSyncableProfile(remoteProfile)
                }
            }

        case "watchPurchaseCompleted":
            // Watch made a purchase - verify and update local state
            if let isUnlocked = message["isWatchUnlocked"] as? Bool, isUnlocked {
                print("Watch reported purchase completed, verifying entitlements...")
                Task {
                    await StoreManager.shared.checkEntitlements()
                    print("Entitlements verified after Watch purchase notification")
                }
            }

        case "competitionCoins":
            // Watch completed a level - proxy coins earned to active competition
            if let amount = message["amount"] as? Int, amount > 0 {
                Task { CompetitionService.shared.recordCoinsEarned(amount) }
            }

        case "analyticsEvent":
            // Watch proxies analytics events through iPhone (Watch has no Firebase SDK)
            guard let eventName = message["event"] as? String else { break }
            switch eventName {
            case "coins_earned":
                if let amount = message["amount"] as? Int, let source = message["source"] as? String {
                    AnalyticsManager.shared.logCoinsEarned(amount: amount, source: source)
                }
            case "game_started":
                AnalyticsManager.shared.logGameStarted()
            case "game_completed":
                let coins = message["coins_earned"] as? Int ?? 0
                let duration = message["duration_seconds"] as? Int ?? 0
                AnalyticsManager.shared.logGameCompleted(coinsEarned: coins, durationSeconds: duration)
            case "competition_joined":
                if let competitionId = message["competition_id"] as? String,
                   let type = message["type"] as? String {
                    AnalyticsManager.shared.logCompetitionJoined(competitionId: competitionId, type: type)
                }
            default:
                break
            }

        default:
            print("Unhandled message type: \(type)")
        }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let profileUpdatedFromWatch = Notification.Name("profileUpdatedFromWatch")
    static let presentShareSheet = Notification.Name("presentShareSheet")
}
