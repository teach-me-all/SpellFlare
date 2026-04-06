//
//  CompetitionViewModel.swift
//  spelling-bee iOS App
//
//  Manages competition list state: loading, creating, and joining competitions.
//

import Foundation

@MainActor
class CompetitionViewModel: ObservableObject {
    @Published var myCompetitions: [Competition] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var showSocialOnboarding = false

    private let service = CompetitionService.shared
    private let auth = FirebaseManager.shared

    // MARK: - Loading

    func loadCompetitions() async {
        guard let uid = auth.currentUID else {
            showSocialOnboarding = true
            return
        }

        isLoading = true
        error = nil

        await service.loadActiveCompetition(uid: uid)

        isLoading = false
    }

    // MARK: - Creating

    func createPrivateCompetition(name: String, username: String, avatarIcon: String) async {
        guard let _ = auth.currentUID else {
            showSocialOnboarding = true
            return
        }

        isLoading = true
        error = nil

        do {
            _ = try await service.createPrivateCompetition(
                name: name,
                username: username,
                avatarIcon: avatarIcon
            )
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Joining

    func joinPublicMatchmaking(username: String, avatarIcon: String) async {
        guard let _ = auth.currentUID else {
            showSocialOnboarding = true
            return
        }

        isLoading = true
        error = nil

        do {
            try await service.joinPublicMatchmaking(username: username, avatarIcon: avatarIcon)
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    func joinByCode(_ code: String, username: String, avatarIcon: String) async {
        guard let _ = auth.currentUID else {
            showSocialOnboarding = true
            return
        }

        isLoading = true
        error = nil

        do {
            try await service.joinByInviteCode(code, username: username, avatarIcon: avatarIcon)
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    func leaveCompetition(id: String) async {
        isLoading = true
        error = nil

        do {
            try await service.leaveCompetition(id: id)
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Helpers

    var allCompetitions: [Competition] { service.allCompetitions }
    var isInCompetition: Bool { service.isInCompetition }
    var canJoinPublic: Bool { service.canJoinPublic }
    var canJoinPrivate: Bool { service.canJoinPrivate }

    /// The most recently joined competition (used to navigate to leaderboard after joining).
    var activeCompetition: Competition? { service.allCompetitions.last }

    func reportCompetitionCompleted(rank: Int, totalPlayers: Int, coinsEarned: Int) {
        AnalyticsManager.shared.logCompetitionCompleted(
            rank: rank,
            totalPlayers: totalPlayers,
            coinsEarned: coinsEarned
        )
    }
}
