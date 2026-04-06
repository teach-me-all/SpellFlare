//
//  FriendsService.swift
//  spelling-bee iOS App
//
//  Manages the friends system: search, send/accept/reject requests, fetch friend list.
//

import Foundation
import FirebaseFirestore
import FirebaseFunctions

class FriendsService {
    static let shared = FriendsService()

    private let db = Firestore.firestore()

    private init() {}

    // MARK: - Search

    /// Search for a user by exact username match
    func searchUser(username: String) async throws -> UserSearchResult? {
        guard !username.isEmpty else { return nil }
        guard await FirebaseManager.shared.isSignedIn else { return nil }

        let snap = try await db
            .collection("users")
            .whereField("username", isEqualTo: username)
            .limit(to: 1)
            .getDocuments()

        guard let doc = snap.documents.first else { return nil }
        let data = doc.data()

        return UserSearchResult(
            id: doc.documentID,
            username: data["username"] as? String ?? username,
            avatarIcon: data["avatarIcon"] as? String ?? "🐝"
        )
    }

    // MARK: - Friend Requests

    /// Send a friend request. Creates two documents atomically (one for each party).
    func sendFriendRequest(
        from myUID: String,
        myUsername: String,
        myAvatarIcon: String,
        to targetUID: String,
        targetUsername: String,
        targetAvatarIcon: String
    ) async throws {
        let batch = db.batch()
        let now = Timestamp(date: Date())

        // My side: pending_sent
        let myRef = db
            .collection("friends").document(myUID)
            .collection("list").document(targetUID)
        batch.setData([
            "status": "pending_sent",
            "username": targetUsername,
            "avatarIcon": targetAvatarIcon,
            "createdAt": now
        ], forDocument: myRef)

        // Their side: pending_received
        let theirRef = db
            .collection("friends").document(targetUID)
            .collection("list").document(myUID)
        batch.setData([
            "status": "pending_received",
            "username": myUsername,
            "avatarIcon": myAvatarIcon,
            "createdAt": now
        ], forDocument: theirRef)

        try await batch.commit()
        AnalyticsManager.shared.logFriendAdded()
    }

    /// Accept a pending friend request. Updates both sides to "accepted".
    func acceptFriendRequest(myUID: String, fromUID: String) async throws {
        let batch = db.batch()

        let myRef = db
            .collection("friends").document(myUID)
            .collection("list").document(fromUID)
        batch.updateData(["status": "accepted"], forDocument: myRef)

        let theirRef = db
            .collection("friends").document(fromUID)
            .collection("list").document(myUID)
        batch.updateData(["status": "accepted"], forDocument: theirRef)

        try await batch.commit()
        AnalyticsManager.shared.logInviteAccepted()
    }

    /// Reject or cancel a friend request. Deletes both sides.
    func rejectFriendRequest(myUID: String, fromUID: String) async throws {
        let batch = db.batch()

        let myRef = db
            .collection("friends").document(myUID)
            .collection("list").document(fromUID)
        batch.deleteDocument(myRef)

        let theirRef = db
            .collection("friends").document(fromUID)
            .collection("list").document(myUID)
        batch.deleteDocument(theirRef)

        try await batch.commit()
    }

    /// Remove an existing friend. Deletes both sides.
    func removeFriend(myUID: String, friendUID: String) async throws {
        let batch = db.batch()

        let myRef = db
            .collection("friends").document(myUID)
            .collection("list").document(friendUID)
        batch.deleteDocument(myRef)

        let theirRef = db
            .collection("friends").document(friendUID)
            .collection("list").document(myUID)
        batch.deleteDocument(theirRef)

        try await batch.commit()
    }

    // MARK: - Fetching

    func fetchAcceptedFriends(uid: String) async throws -> [Friend] {
        let snap = try await db
            .collection("friends").document(uid)
            .collection("list")
            .whereField("status", isEqualTo: "accepted")
            .getDocuments()

        return snap.documents.compactMap { Friend(from: $0) }
    }

    func fetchPendingRequests(uid: String) async throws -> [Friend] {
        let snap = try await db
            .collection("friends").document(uid)
            .collection("list")
            .whereField("status", isEqualTo: "pending_received")
            .getDocuments()

        return snap.documents.compactMap { Friend(from: $0) }
    }

    // MARK: - User Profile

    /// Set or update the social user profile (username, avatar)
    func setUserProfile(uid: String, username: String, avatarIcon: String, profileId: UUID) async throws {
        let callable = Functions.functions().httpsCallable("setUsername")
        _ = try await callable.call(["username": username, "avatarIcon": avatarIcon])

        // Also write profileId to user doc for device-profile linkage
        try await db.collection("users").document(uid).setData([
            "profileId": profileId.uuidString,
            "avatarIcon": avatarIcon
        ], merge: true)
    }

    /// Check if a username is already taken (for real-time availability display)
    func isUsernameTaken(_ username: String, excludingUID: String) async throws -> Bool {
        guard username.count >= 3 else { return false }
        guard await FirebaseManager.shared.isSignedIn else { return false }

        let snap = try await db
            .collection("users")
            .whereField("username", isEqualTo: username)
            .limit(to: 1)
            .getDocuments()

        guard let doc = snap.documents.first else { return false }
        return doc.documentID != excludingUID
    }
}

// MARK: - Firestore Parsing

extension Friend {
    init?(from snapshot: DocumentSnapshot) {
        guard let data = snapshot.data(),
              let statusStr = data["status"] as? String,
              let status = FriendStatus(rawValue: statusStr),
              let username = data["username"] as? String
        else { return nil }

        self.id = snapshot.documentID
        self.username = username
        self.avatarIcon = data["avatarIcon"] as? String ?? "🐝"
        self.status = status
    }
}
