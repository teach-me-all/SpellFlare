//
//  LeaderboardViewModel.swift
//  spelling-bee iOS App
//
//  Manages leaderboard data with auto-refresh and pagination.
//

import Foundation

@MainActor
class LeaderboardViewModel: ObservableObject {
    @Published var entries: [LeaderboardEntry] = []
    @Published var pinnedUserEntry: LeaderboardEntry?   // Shown at top if user is outside top 50
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var hasMore = true
    @Published var error: String?

    private let service = LeaderboardService.shared
    private let auth = FirebaseManager.shared
    private var refreshTimer: Timer?
    private var competitionId: String?
    private var lastKnownRank: Int?

    // MARK: - Fetch

    func loadLeaderboard(competitionId: String, forceRefresh: Bool = false) async {
        let isFirstLoad = self.competitionId == nil
        self.competitionId = competitionId
        guard let uid = auth.currentUID else { return }

        isLoading = true
        error = nil

        do {
            let fetched = try await service.fetchLeaderboard(
                competitionId: competitionId,
                currentUID: uid,
                forceRefresh: forceRefresh
            )
            entries = fetched
            hasMore = fetched.count >= 50

            // Fetch user's own rank if they're not in the top 50
            let userEntry: LeaderboardEntry?
            if !fetched.contains(where: { $0.isCurrentUser }) {
                userEntry = try await service.fetchUserEntry(
                    competitionId: competitionId,
                    uid: uid
                )
                pinnedUserEntry = userEntry
            } else {
                userEntry = fetched.first(where: { $0.isCurrentUser })
                pinnedUserEntry = nil
            }

            // Track rank changes on refresh (not on first load)
            if !isFirstLoad, let newRank = userEntry?.rank, let oldRank = lastKnownRank {
                if newRank < oldRank {
                    AnalyticsManager.shared.logRankImproved()
                } else if newRank > oldRank {
                    AnalyticsManager.shared.logRankDropped()
                }
            }
            lastKnownRank = userEntry?.rank

        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false

        // Log leaderboard_viewed on first load
        if isFirstLoad {
            AnalyticsManager.shared.logLeaderboardViewed(competitionId: competitionId)
        }
    }

    func loadNextPage() async {
        guard let competitionId, !isLoadingMore, hasMore else { return }
        guard let uid = auth.currentUID else { return }

        isLoadingMore = true

        do {
            let newEntries = try await service.fetchNextPage(
                competitionId: competitionId,
                currentUID: uid
            )
            entries.append(contentsOf: newEntries)
            hasMore = newEntries.count >= 50
        } catch {
            self.error = error.localizedDescription
        }

        isLoadingMore = false
    }

    // MARK: - Auto-Refresh

    func startAutoRefresh() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, let id = self.competitionId else { return }
                await self.loadLeaderboard(competitionId: id, forceRefresh: true)
            }
        }
    }

    func stopAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
}
