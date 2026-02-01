//
//  ProfileStore.swift
//  Shared
//
//  Low-level multi-profile persistence using UserDefaults.
//

import Foundation

class ProfileStore {
    static let shared = ProfileStore()

    private let defaults = UserDefaults.standard

    // Keys
    private let metadataListKey = "profileMetadataList"
    private let activeProfileIDKey = "activeProfileID"
    private let migrationCompletedKey = "multiProfileMigrationCompleted"

    private init() {}

    // MARK: - Profile Data (SyncableProfile per UUID)

    private func profileKey(for id: UUID) -> String {
        "profile_\(id.uuidString)"
    }

    func saveProfile(_ syncable: SyncableProfile, for id: UUID) {
        if let data = try? JSONEncoder().encode(syncable) {
            defaults.set(data, forKey: profileKey(for: id))
        }
    }

    func loadProfile(for id: UUID) -> SyncableProfile? {
        guard let data = defaults.data(forKey: profileKey(for: id)) else { return nil }
        return try? JSONDecoder().decode(SyncableProfile.self, from: data)
    }

    func deleteProfile(for id: UUID) {
        defaults.removeObject(forKey: profileKey(for: id))
    }

    // MARK: - Metadata List

    func loadAllMetadata() -> [ProfileMetadata] {
        guard let data = defaults.data(forKey: metadataListKey) else { return [] }
        return (try? JSONDecoder().decode([ProfileMetadata].self, from: data)) ?? []
    }

    func saveMetadata(_ metadata: [ProfileMetadata]) {
        if let data = try? JSONEncoder().encode(metadata) {
            defaults.set(data, forKey: metadataListKey)
        }
    }

    // MARK: - Active Profile ID

    var activeProfileID: UUID? {
        get {
            guard let str = defaults.string(forKey: activeProfileIDKey) else { return nil }
            return UUID(uuidString: str)
        }
        set {
            defaults.set(newValue?.uuidString, forKey: activeProfileIDKey)
        }
    }

    // MARK: - Migration Flag

    var isMigrationCompleted: Bool {
        get { defaults.bool(forKey: migrationCompletedKey) }
        set { defaults.set(newValue, forKey: migrationCompletedKey) }
    }

    // MARK: - Clear All

    func clearAll() {
        let metadata = loadAllMetadata()
        for meta in metadata {
            deleteProfile(for: meta.id)
        }
        defaults.removeObject(forKey: metadataListKey)
        defaults.removeObject(forKey: activeProfileIDKey)
        defaults.removeObject(forKey: migrationCompletedKey)
    }
}
