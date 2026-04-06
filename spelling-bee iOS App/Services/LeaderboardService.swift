//
//  LeaderboardService.swift
//  spelling-bee iOS App
//
//  Fetches competition leaderboards from Firestore with local caching.
//  No real-time listeners - pull-to-refresh + 60-second auto-refresh in views.
//

import Foundation
import FirebaseFirestore

class LeaderboardService {
    static let shared = LeaderboardService()

    private let db = Firestore.firestore()
    private let cacheTTL: TimeInterval = 60

    // Cache: competitionId → (entries, fetchedAt, lastDocument for pagination)
    private var cache: [String: CacheEntry] = [:]

    private struct CacheEntry {
        let entries: [LeaderboardEntry]
        let fetchedAt: Date
        let lastDocument: DocumentSnapshot?
    }

    private init() {}

    // MARK: - Fetch

    func fetchLeaderboard(
        competitionId: String,
        currentUID: String,
        pageSize: Int = 50,
        forceRefresh: Bool = false
    ) async throws -> [LeaderboardEntry] {
        // Return cached result if still fresh
        if !forceRefresh,
           let cached = cache[competitionId],
           Date().timeIntervalSince(cached.fetchedAt) < cacheTTL {
            return cached.entries
        }

        let snap = try await db
            .collection("competitions")
            .document(competitionId)
            .collection("participants")
            .order(by: "coinsEarned", descending: true)
            .limit(to: pageSize)
            .getDocuments()

        let entries = snap.documents.enumerated().compactMap { index, doc -> LeaderboardEntry? in
            guard let username = doc.data()["username"] as? String,
                  let avatarIcon = doc.data()["avatarIcon"] as? String,
                  let coins = doc.data()["coinsEarned"] as? Int
            else { return nil }

            return LeaderboardEntry(
                id: doc.documentID,
                username: username,
                avatarIcon: avatarIcon,
                coinsEarned: coins,
                rank: index + 1,
                isCurrentUser: doc.documentID == currentUID
            )
        }

        let lastDocument = snap.documents.last
        cache[competitionId] = CacheEntry(
            entries: entries,
            fetchedAt: Date(),
            lastDocument: lastDocument
        )

        return entries
    }

    /// Load the next page after the last fetched document
    func fetchNextPage(
        competitionId: String,
        currentUID: String,
        pageSize: Int = 50
    ) async throws -> [LeaderboardEntry] {
        guard let lastDocument = cache[competitionId]?.lastDocument else {
            // No previous fetch, start from beginning
            return try await fetchLeaderboard(
                competitionId: competitionId,
                currentUID: currentUID,
                pageSize: pageSize
            )
        }

        let currentCount = cache[competitionId]?.entries.count ?? 0

        let snap = try await db
            .collection("competitions")
            .document(competitionId)
            .collection("participants")
            .order(by: "coinsEarned", descending: true)
            .start(afterDocument: lastDocument)
            .limit(to: pageSize)
            .getDocuments()

        let newEntries = snap.documents.enumerated().compactMap { index, doc -> LeaderboardEntry? in
            guard let username = doc.data()["username"] as? String,
                  let avatarIcon = doc.data()["avatarIcon"] as? String,
                  let coins = doc.data()["coinsEarned"] as? Int
            else { return nil }

            return LeaderboardEntry(
                id: doc.documentID,
                username: username,
                avatarIcon: avatarIcon,
                coinsEarned: coins,
                rank: currentCount + index + 1,
                isCurrentUser: doc.documentID == currentUID
            )
        }

        // Append to cache
        if let existing = cache[competitionId] {
            let combined = existing.entries + newEntries
            cache[competitionId] = CacheEntry(
                entries: combined,
                fetchedAt: existing.fetchedAt,
                lastDocument: snap.documents.last ?? existing.lastDocument
            )
            return newEntries
        }

        return newEntries
    }

    /// Fetch the rank for a specific user (used to pin user's row when outside top 50)
    func fetchUserEntry(
        competitionId: String,
        uid: String
    ) async throws -> LeaderboardEntry? {
        let doc = try await db
            .collection("competitions")
            .document(competitionId)
            .collection("participants")
            .document(uid)
            .getDocument()

        guard doc.exists,
              let username = doc.data()?["username"] as? String,
              let avatarIcon = doc.data()?["avatarIcon"] as? String,
              let coins = doc.data()?["coinsEarned"] as? Int
        else { return nil }

        // Compute rank by counting users with more coins
        let higherSnap = try await db
            .collection("competitions")
            .document(competitionId)
            .collection("participants")
            .whereField("coinsEarned", isGreaterThan: coins)
            .count
            .getAggregation(source: .server)

        let rank = (higherSnap.count as? Int ?? 0) + 1

        return LeaderboardEntry(
            id: uid,
            username: username,
            avatarIcon: avatarIcon,
            coinsEarned: coins,
            rank: rank,
            isCurrentUser: true
        )
    }

    func invalidateCache(for competitionId: String) {
        cache.removeValue(forKey: competitionId)
    }

    func invalidateAll() {
        cache.removeAll()
    }
}
