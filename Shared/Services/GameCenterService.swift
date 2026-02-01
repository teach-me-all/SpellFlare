//
//  GameCenterService.swift
//  Shared
//
//  Handles Game Center authentication and cloud save/restore for profile backup.
//

import Foundation
import GameKit

@MainActor
class GameCenterService: ObservableObject {
    static let shared = GameCenterService()

    // MARK: - Published State
    @Published private(set) var isAuthenticated = false
    @Published private(set) var authenticationError: String?
    @Published private(set) var isSaving = false
    @Published private(set) var isRestoring = false

    // MARK: - Private Properties
    private let savedGameNameLegacy = "SpellingBeeProfile"

    private func savedGameName(for profileID: UUID) -> String {
        "SpellingBeeProfile_\(profileID.uuidString)"
    }

    private init() {}

    // MARK: - Authentication

    /// Authenticate the local player with Game Center
    /// Call this at app launch
    func authenticate() async {
        GKLocalPlayer.local.authenticateHandler = { [weak self] viewController, error in
            Task { @MainActor in
                if let error = error {
                    self?.authenticationError = error.localizedDescription
                    self?.isAuthenticated = false
                    print("Game Center auth error: \(error.localizedDescription)")
                    return
                }

                if viewController != nil {
                    // Game Center will show its own UI for sign-in
                    // The authenticateHandler will be called again after user completes
                    print("Game Center requires user sign-in")
                    return
                }

                if GKLocalPlayer.local.isAuthenticated {
                    self?.isAuthenticated = true
                    self?.authenticationError = nil
                    print("Game Center authenticated: \(GKLocalPlayer.local.displayName)")
                } else {
                    self?.isAuthenticated = false
                    print("Game Center not authenticated")
                }
            }
        }
    }

    // MARK: - Achievement Reporting

    /// Report a completed achievement to Game Center (fire-and-forget).
    func reportAchievement(identifier: String) {
        guard isAuthenticated else { return }

        Task {
            do {
                let achievement = GKAchievement(identifier: identifier)
                achievement.percentComplete = 100.0
                achievement.showsCompletionBanner = false
                try await GKAchievement.report([achievement])
                print("Game Center achievement reported: \(identifier)")
            } catch {
                print("Failed to report GC achievement \(identifier): \(error.localizedDescription)")
            }
        }
    }

    /// Report progressive achievement to Game Center.
    func reportAchievementProgress(identifier: String, percentComplete: Double) {
        guard isAuthenticated else { return }

        Task {
            do {
                let achievement = GKAchievement(identifier: identifier)
                achievement.percentComplete = percentComplete
                achievement.showsCompletionBanner = false
                try await GKAchievement.report([achievement])
                print("Game Center achievement progress: \(identifier) = \(percentComplete)%")
            } catch {
                print("Failed to report GC progress \(identifier): \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Cloud Save

    /// Save profile to Game Center cloud
    /// - Parameter profile: The syncable profile to save
    func saveToCloud(profile: SyncableProfile) async {
        guard isAuthenticated else {
            print("Cannot save to cloud: not authenticated")
            return
        }

        isSaving = true
        defer { isSaving = false }

        do {
            // Encode profile to JSON data
            let data = try JSONEncoder().encode(profile)

            // Save to Game Center using per-profile name
            let gameName = savedGameName(for: profile.profile.id)
            try await GKLocalPlayer.local.saveGameData(data, withName: gameName)

            print("Profile saved to Game Center cloud")
            print("  - Name: \(profile.profile.name)")
            print("  - Coins: \(profile.profile.totalCoins)")
            print("  - Completed levels: \(profile.profile.totalCompletedLevelsCount)")
        } catch {
            print("Failed to save to Game Center: \(error.localizedDescription)")
        }
    }

    // MARK: - Cloud Restore

    /// Restore profile from Game Center cloud for a specific profile ID
    /// Falls back to legacy save name if per-profile save not found
    func restoreFromCloud(profileID: UUID? = nil) async -> SyncableProfile? {
        guard isAuthenticated else {
            print("Cannot restore from cloud: not authenticated")
            return nil
        }

        isRestoring = true
        defer { isRestoring = false }

        do {
            let savedGames = try await GKLocalPlayer.local.fetchSavedGames()

            // Try per-profile save first
            var savedGame: GKSavedGame?
            if let id = profileID {
                let name = savedGameName(for: id)
                savedGame = savedGames.first(where: { $0.name == name })
            }

            // Fall back to legacy save
            if savedGame == nil {
                savedGame = savedGames.first(where: { $0.name == savedGameNameLegacy })
            }

            guard let game = savedGame else {
                print("No saved game found in Game Center")
                return nil
            }

            let data = try await game.loadData()
            let profile = try JSONDecoder().decode(SyncableProfile.self, from: data)

            print("Profile restored from Game Center cloud")
            print("  - Name: \(profile.profile.name)")
            print("  - Coins: \(profile.profile.totalCoins)")
            print("  - Completed levels: \(profile.profile.totalCompletedLevelsCount)")

            return profile
        } catch {
            print("Failed to restore from Game Center: \(error.localizedDescription)")
            return nil
        }
    }

    /// Restore all profiles from Game Center cloud
    func restoreAllProfiles() async -> [SyncableProfile] {
        guard isAuthenticated else { return [] }

        do {
            let savedGames = try await GKLocalPlayer.local.fetchSavedGames()
            var profiles: [SyncableProfile] = []

            for game in savedGames where game.name?.hasPrefix("SpellingBeeProfile") == true {
                do {
                    let data = try await game.loadData()
                    let profile = try JSONDecoder().decode(SyncableProfile.self, from: data)
                    profiles.append(profile)
                } catch {
                    print("Failed to decode saved game \(game.name ?? "unknown"): \(error)")
                }
            }

            print("Restored \(profiles.count) profiles from Game Center")
            return profiles
        } catch {
            print("Failed to fetch saved games: \(error)")
            return []
        }
    }

    // MARK: - Delete Cloud Save

    /// Delete saved game from Game Center cloud
    func deleteCloudSave() async {
        guard isAuthenticated else { return }

        do {
            let savedGames = try await GKLocalPlayer.local.fetchSavedGames()
            for savedGame in savedGames where savedGame.name?.hasPrefix("SpellingBeeProfile") == true {
                if let name = savedGame.name {
                    try await GKLocalPlayer.local.deleteSavedGames(withName: name)
                    print("Deleted Game Center cloud save: \(name)")
                }
            }
        } catch {
            print("Failed to delete cloud save: \(error.localizedDescription)")
        }
    }

    /// Delete cloud save for a specific profile
    func deleteProfileBackup(id: UUID) async {
        guard isAuthenticated else { return }

        let name = savedGameName(for: id)
        do {
            try await GKLocalPlayer.local.deleteSavedGames(withName: name)
            print("Deleted Game Center cloud save for profile \(id)")
        } catch {
            print("Failed to delete cloud save for profile \(id): \(error)")
        }
    }

    // MARK: - Conflict Resolution

    /// Resolve conflicts between local and cloud profiles
    /// - Parameters:
    ///   - local: Local profile
    ///   - cloud: Cloud profile
    /// - Returns: The merged/resolved profile
    func resolveConflict(local: SyncableProfile, cloud: SyncableProfile) -> SyncableProfile {
        // Use the profile with more progress (more completed levels)
        // If tied, use the one with more coins
        // If still tied, use the most recently modified

        let localLevels = local.profile.totalCompletedLevelsCount
        let cloudLevels = cloud.profile.totalCompletedLevelsCount

        if localLevels != cloudLevels {
            let winner = localLevels > cloudLevels ? local : cloud
            print("Conflict resolved: using profile with more levels (\(max(localLevels, cloudLevels)))")
            return winner
        }

        let localCoins = local.profile.totalCoins
        let cloudCoins = cloud.profile.totalCoins

        if localCoins != cloudCoins {
            let winner = localCoins > cloudCoins ? local : cloud
            print("Conflict resolved: using profile with more coins (\(max(localCoins, cloudCoins)))")
            return winner
        }

        // Use most recent
        let winner = local.lastModified > cloud.lastModified ? local : cloud
        print("Conflict resolved: using most recent profile")
        return winner
    }
}

// MARK: - AppState Integration Extension
extension GameCenterService {

    /// Convenience method to backup current profile
    func backupCurrentProfile() async {
        guard let profile = LocalCacheService.shared.loadSyncableProfile() else {
            print("No profile to backup")
            return
        }
        await saveToCloud(profile: profile)
    }

    /// Convenience method to restore and apply cloud profile if better
    /// - Returns: True if cloud profile was applied
    func restoreAndApplyIfBetter() async -> Bool {
        let profileID = ProfileManager.shared.activeProfileID
        guard let cloudProfile = await restoreFromCloud(profileID: profileID) else {
            return false
        }

        guard let localProfile = LocalCacheService.shared.loadSyncableProfile() else {
            // No local profile, use cloud
            LocalCacheService.shared.saveSyncableProfile(cloudProfile)
            return true
        }

        // Resolve conflict
        let resolved = resolveConflict(local: localProfile, cloud: cloudProfile)

        // If cloud won, apply it
        if resolved.lastModified == cloudProfile.lastModified {
            LocalCacheService.shared.saveSyncableProfile(cloudProfile)
            return true
        }

        return false
    }
}
