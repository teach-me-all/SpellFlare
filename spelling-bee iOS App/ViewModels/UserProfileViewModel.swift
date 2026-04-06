//
//  UserProfileViewModel.swift
//  spelling-bee iOS App
//
//  Loads a user's public profile: Firestore user doc + completed competition history.
//

import Foundation
import FirebaseFirestore

@MainActor
class UserProfileViewModel: ObservableObject {
    @Published var username: String
    @Published var avatarIcon: String = "🐝"
    @Published var totalCoins: Int = 0
    @Published var history: [CompetitionHistoryEntry] = []
    @Published var isLoading = false
    @Published var error: String?

    private let userId: String
    private let db = Firestore.firestore()

    init(userId: String, username: String) {
        self.userId = userId
        self.username = username
    }

    // MARK: - Computed stats

    var totalCompetitions: Int { history.count }

    var bestRank: Int? { history.compactMap(\.myFinalRank).min() }

    var totalCoinsEarned: Int { history.reduce(0) { $0 + $1.myCoinsEarned } }

    var badges: [ProfileBadge] {
        var result: [ProfileBadge] = []

        if let best = bestRank {
            if best == 1 { result.append(.init(icon: "🥇", label: "Champion")) }
            else if best <= 3 { result.append(.init(icon: "🥈", label: "Top 3")) }
            else if best <= 10 { result.append(.init(icon: "🏅", label: "Top 10")) }
        }

        if totalCompetitions >= 10 { result.append(.init(icon: "🏆", label: "Veteran")) }
        else if totalCompetitions >= 5 { result.append(.init(icon: "⚡️", label: "Active")) }
        else if totalCompetitions >= 1 { result.append(.init(icon: "🌟", label: "Competitor")) }

        if totalCoinsEarned >= 5000 { result.append(.init(icon: "💰", label: "Rich")) }
        else if totalCoinsEarned >= 1000 { result.append(.init(icon: "💵", label: "Earner")) }

        if totalCoins >= 2000 { result.append(.init(icon: "🐝", label: "Bee Master")) }

        return result
    }

    // MARK: - Load

    func load() async {
        isLoading = true
        defer { isLoading = false }

        async let userTask = fetchUserDoc()
        async let historyTask = CompetitionService.shared.loadCompetitionHistory(uid: userId)

        let (user, hist) = await (userTask, historyTask)

        if let user {
            avatarIcon = user.avatarIcon
            totalCoins = user.totalCoins
            // Keep the username passed in — it's already correct
        }
        history = hist
    }

    private func fetchUserDoc() async -> SocialUser? {
        do {
            let doc = try await db.collection("users").document(userId).getDocument()
            guard let data = doc.data() else { return nil }
            return SocialUser(
                username: data["username"] as? String ?? username,
                avatarIcon: data["avatarIcon"] as? String ?? "🐝",
                profileId: data["profileId"] as? String ?? "",
                totalCoins: data["totalCoins"] as? Int ?? 0,
                fcmToken: data["fcmToken"] as? String
            )
        } catch {
            return nil
        }
    }
}

// MARK: - Badge model

struct ProfileBadge: Identifiable {
    let id = UUID()
    let icon: String
    let label: String
}
