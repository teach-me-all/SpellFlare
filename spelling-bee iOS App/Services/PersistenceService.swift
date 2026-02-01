//
//  PersistenceService.swift
//  spelling-bee iOS App
//
//  Handles local data persistence, delegating to ProfileManager for multi-profile support.
//

import Foundation

@MainActor
class PersistenceService {
    static let shared = PersistenceService()

    private let localCache = LocalCacheService.shared

    func saveProfile(_ profile: UserProfile) {
        ProfileManager.shared.saveProfile(profile)
    }

    func loadProfile() -> UserProfile? {
        return ProfileManager.shared.loadActiveProfile()
    }

    func deleteProfile() {
        if let id = ProfileManager.shared.activeProfileID {
            _ = ProfileManager.shared.deleteProfile(id: id)
        }
        localCache.clearAll()
    }
}
