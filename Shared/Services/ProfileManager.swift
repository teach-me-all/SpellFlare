//
//  ProfileManager.swift
//  Shared
//
//  High-level multi-profile coordinator.
//

import Foundation
import Combine

@MainActor
class ProfileManager: ObservableObject {
    static let shared = ProfileManager()

    @Published var activeProfile: UserProfile?
    @Published var allProfiles: [ProfileMetadata] = []
    @Published var activeProfileID: UUID?

    private let store = ProfileStore.shared
    private let localCache = LocalCacheService.shared
    let maxProfiles = 4

    static let avatarOptions = ["🐝", "🦊", "🐸", "🐱", "🐶", "🦁", "🐼", "🐨", "🦋", "🐙", "🐢", "🦄", "🐰", "🐵", "🐧", "🐻"]

    private init() {
        allProfiles = store.loadAllMetadata()
        activeProfileID = store.activeProfileID
    }

    // MARK: - Migration from Single Profile

    func migrateFromSingleProfileIfNeeded() {
        guard !store.isMigrationCompleted else { return }

        // Check if old single-profile data exists
        if let existingSyncable = localCache.loadSyncableProfile() {
            let profile = existingSyncable.profile

            // Assign stable UUID if it was a default (migration case)
            // The decoder already assigns a UUID, so we keep it
            let metadata = ProfileMetadata(from: profile)

            // Save under new multi-profile scheme
            store.saveProfile(existingSyncable, for: profile.id)
            store.saveMetadata([metadata])
            store.activeProfileID = profile.id

            // Update local state
            allProfiles = [metadata]
            activeProfileID = profile.id
            activeProfile = profile

            print("Migrated single profile to multi-profile: \(profile.name) (\(profile.id))")
        }

        store.isMigrationCompleted = true
    }

    // MARK: - Load Active Profile

    func loadActiveProfile() -> UserProfile? {
        guard let id = store.activeProfileID,
              let syncable = store.loadProfile(for: id) else {
            return nil
        }
        activeProfile = syncable.profile
        activeProfileID = id
        return syncable.profile
    }

    // MARK: - Create Profile

    func createProfile(name: String, avatarIcon: String, grade: Int) -> UserProfile {
        let profile = UserProfile(name: name, grade: grade, avatarIcon: avatarIcon)
        let syncable = SyncableProfile(profile: profile, deviceIdentifier: DeviceIdentifier.current)

        store.saveProfile(syncable, for: profile.id)

        var metadata = allProfiles
        metadata.append(ProfileMetadata(from: profile))
        store.saveMetadata(metadata)
        allProfiles = metadata

        store.activeProfileID = profile.id
        activeProfileID = profile.id
        activeProfile = profile

        // Also save to LocalCacheService for backward compatibility
        localCache.saveSyncableProfile(syncable)

        return profile
    }

    // MARK: - Switch Profile

    func switchToProfile(id: UUID) -> UserProfile? {
        // Save current profile first
        saveActiveProfile()

        guard let syncable = store.loadProfile(for: id) else { return nil }

        store.activeProfileID = id
        activeProfileID = id
        activeProfile = syncable.profile

        // Update LocalCacheService so existing code paths work
        localCache.saveSyncableProfile(syncable)

        return syncable.profile
    }

    // MARK: - Delete Profile

    func deleteProfile(id: UUID) -> Bool {
        guard allProfiles.count > 0 else { return false }

        // Remove from store
        store.deleteProfile(for: id)

        // Remove from metadata
        var metadata = allProfiles
        metadata.removeAll { $0.id == id }
        store.saveMetadata(metadata)
        allProfiles = metadata

        // If deleting active profile, switch to next available
        if activeProfileID == id {
            if let next = metadata.first {
                _ = switchToProfile(id: next.id)
            } else {
                store.activeProfileID = nil
                activeProfileID = nil
                activeProfile = nil
                localCache.clearAll()
            }
        }

        return true
    }

    // MARK: - Save Active Profile

    func saveActiveProfile() {
        guard let profile = activeProfile, let id = activeProfileID else { return }

        var syncable: SyncableProfile
        if var existing = store.loadProfile(for: id) {
            existing.updateProfile(profile)
            syncable = existing
        } else {
            syncable = SyncableProfile(profile: profile, deviceIdentifier: DeviceIdentifier.current)
        }

        store.saveProfile(syncable, for: id)

        // Also update LocalCacheService for backward compat
        localCache.saveSyncableProfile(syncable)

        // Update metadata
        updateMetadata(for: profile)

        localCache.markPendingSync()
    }

    func saveProfile(_ profile: UserProfile) {
        activeProfile = profile

        var syncable: SyncableProfile
        if var existing = store.loadProfile(for: profile.id) {
            existing.updateProfile(profile)
            syncable = existing
        } else {
            syncable = SyncableProfile(profile: profile, deviceIdentifier: DeviceIdentifier.current)
        }

        store.saveProfile(syncable, for: profile.id)
        localCache.saveSyncableProfile(syncable)
        updateMetadata(for: profile)
        localCache.markPendingSync()
    }

    // MARK: - Helpers

    func canCreateMoreProfiles() -> Bool {
        allProfiles.count < maxProfiles
    }

    private func updateMetadata(for profile: UserProfile) {
        var metadata = allProfiles
        if let index = metadata.firstIndex(where: { $0.id == profile.id }) {
            metadata[index].name = profile.name
            metadata[index].avatarIcon = profile.avatarIcon
            metadata[index].grade = profile.grade
            store.saveMetadata(metadata)
            allProfiles = metadata
        }
    }

    func profileCount() -> Int {
        allProfiles.count
    }

    func hasMultipleProfiles() -> Bool {
        allProfiles.count > 1
    }
}
