//
//  FirebaseManager.swift
//  spelling-bee iOS App
//
//  Manages Firebase Authentication and configuration.
//  Uses anonymous auth tied to UserProfile.id so each profile has its own social identity.
//

import Foundation
import FirebaseAuth

@MainActor
class FirebaseManager: ObservableObject {
    static let shared = FirebaseManager()

    @Published private(set) var currentUID: String?
    @Published private(set) var isSignedIn: Bool = false

    private init() {
        // Restore existing auth state on launch
        currentUID = Auth.auth().currentUser?.uid
        isSignedIn = currentUID != nil
    }

    // MARK: - Anonymous Sign-In

    /// Sign in anonymously and tie the Firebase UID to the given UserProfile ID.
    /// If a mapping already exists for this profile, restores or re-signs in silently.
    func signIn(for profileId: UUID) async throws {
        let key = "firebase_uid_\(profileId.uuidString)"

        // If already signed in with the right UID, nothing to do
        if let existingUID = UserDefaults.standard.string(forKey: key),
           let current = Auth.auth().currentUser,
           current.uid == existingUID {
            currentUID = existingUID
            isSignedIn = true
            return
        }

        // Sign in anonymously
        let result = try await Auth.auth().signInAnonymously()
        let uid = result.user.uid

        // Persist the mapping
        UserDefaults.standard.set(uid, forKey: key)

        currentUID = uid
        isSignedIn = true
    }

    /// Sign out and clear state (called when profile is deleted)
    func signOut() throws {
        try Auth.auth().signOut()
        currentUID = nil
        isSignedIn = false
    }

    /// Returns the Firebase UID for a given profile if one exists locally
    func cachedUID(for profileId: UUID) -> String? {
        let key = "firebase_uid_\(profileId.uuidString)"
        return UserDefaults.standard.string(forKey: key)
    }
}
