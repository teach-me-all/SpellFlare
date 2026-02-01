//
//  LocalCacheService.swift
//  Shared
//
//  Manages local UserDefaults cache with pending sync tracking.
//

import Foundation

class LocalCacheService {
    static let shared = LocalCacheService()

    private let defaults = UserDefaults.standard

    // Keys
    private let syncableProfileKey = "syncableProfile"
    private let pendingSyncKey = "pendingSync"
    private let lastSyncDateKey = "lastSyncDate"
    private let cloudRecordIDKey = "cloudRecordID"

    // Legacy keys for migration
    private let legacyiOSKey = "userProfile_iOS"
    private let legacyWatchKey = "user_profile"

    private init() {}

    // MARK: - SyncableProfile Storage

    func saveSyncableProfile(_ syncableProfile: SyncableProfile) {
        if let encoded = try? JSONEncoder().encode(syncableProfile) {
            defaults.set(encoded, forKey: syncableProfileKey)
        }
    }

    func loadSyncableProfile() -> SyncableProfile? {
        guard let data = defaults.data(forKey: syncableProfileKey) else {
            return migrateFromLegacy()
        }
        return try? JSONDecoder().decode(SyncableProfile.self, from: data)
    }

    // MARK: - Pending Sync Tracking

    var hasPendingSync: Bool {
        get { defaults.bool(forKey: pendingSyncKey) }
        set { defaults.set(newValue, forKey: pendingSyncKey) }
    }

    func markPendingSync() {
        hasPendingSync = true
    }

    func clearPendingSync() {
        hasPendingSync = false
        lastSyncDate = Date()
    }

    // MARK: - Last Sync Date

    var lastSyncDate: Date? {
        get { defaults.object(forKey: lastSyncDateKey) as? Date }
        set { defaults.set(newValue, forKey: lastSyncDateKey) }
    }

    // MARK: - Cloud Record ID

    var cloudRecordID: String? {
        get { defaults.string(forKey: cloudRecordIDKey) }
        set { defaults.set(newValue, forKey: cloudRecordIDKey) }
    }

    // MARK: - Migration from Legacy Format

    private func migrateFromLegacy() -> SyncableProfile? {
        // Try iOS legacy key first
        if let data = defaults.data(forKey: legacyiOSKey),
           let profile = try? JSONDecoder().decode(UserProfile.self, from: data) {
            let syncable = SyncableProfile(profile: profile, deviceIdentifier: DeviceIdentifier.current)
            saveSyncableProfile(syncable)
            defaults.removeObject(forKey: legacyiOSKey)
            markPendingSync()
            return syncable
        }

        // Try watchOS legacy key
        if let data = defaults.data(forKey: legacyWatchKey),
           let profile = try? JSONDecoder().decode(UserProfile.self, from: data) {
            let syncable = SyncableProfile(profile: profile, deviceIdentifier: DeviceIdentifier.current)
            saveSyncableProfile(syncable)
            defaults.removeObject(forKey: legacyWatchKey)
            markPendingSync()
            return syncable
        }

        return nil
    }

    // MARK: - Convenience Methods

    func saveProfile(_ profile: UserProfile) {
        var syncable: SyncableProfile
        if var existing = loadSyncableProfile() {
            existing.updateProfile(profile)
            syncable = existing
        } else {
            syncable = SyncableProfile(profile: profile, deviceIdentifier: DeviceIdentifier.current)
        }
        saveSyncableProfile(syncable)
        markPendingSync()
    }

    func loadProfile() -> UserProfile? {
        return loadSyncableProfile()?.profile
    }

    // MARK: - Multi-Profile Support

    func saveProfileData(_ syncable: SyncableProfile, for id: UUID) {
        let key = "profile_\(id.uuidString)"
        if let data = try? JSONEncoder().encode(syncable) {
            defaults.set(data, forKey: key)
        }
    }

    func loadProfileData(for id: UUID) -> SyncableProfile? {
        let key = "profile_\(id.uuidString)"
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(SyncableProfile.self, from: data)
    }

    func deleteProfileData(for id: UUID) {
        let key = "profile_\(id.uuidString)"
        defaults.removeObject(forKey: key)
    }

    // MARK: - Reset

    func clearAll() {
        defaults.removeObject(forKey: syncableProfileKey)
        defaults.removeObject(forKey: pendingSyncKey)
        defaults.removeObject(forKey: lastSyncDateKey)
        defaults.removeObject(forKey: cloudRecordIDKey)
    }
}
