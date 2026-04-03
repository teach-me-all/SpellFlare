//
//  AnalyticsManager.swift
//  spelling-bee iOS App
//
//  Centralized Firebase Analytics wrapper. All event names and parameters
//  are defined here to keep them consistent across the codebase.
//

import Foundation
import FirebaseAnalytics

// MARK: - Event Name Constants

enum SpellFlareEvent {
    // Gameplay
    static let gameStarted = "game_started"
    static let gameCompleted = "game_completed"

    // Competition
    static let competitionCreated = "competition_created"
    static let competitionJoined = "competition_joined"
    static let competitionCompleted = "competition_completed"

    // Leaderboard
    static let leaderboardViewed = "leaderboard_viewed"

    // Social
    static let friendAdded = "friend_added"
    static let inviteSent = "invite_sent"
    static let inviteAccepted = "invite_accepted"

    // Economy
    static let coinsEarned = "coins_earned"
    static let coinsSubmitted = "coins_submitted"

    // Rank behavior
    static let rankImproved = "rank_improved"
    static let rankDropped = "rank_dropped"
}

// MARK: - Manager

final class AnalyticsManager {
    static let shared = AnalyticsManager()
    private init() {}

    // MARK: - Core

    func logEvent(_ name: String, params: [String: Any]? = nil) {
        Analytics.logEvent(name, parameters: params)
    }

    // MARK: - Gameplay

    func logGameStarted() {
        logEvent(SpellFlareEvent.gameStarted)
    }

    func logGameCompleted(coinsEarned: Int, durationSeconds: Int) {
        logEvent(SpellFlareEvent.gameCompleted, params: [
            "coins_earned": coinsEarned,
            "duration_seconds": durationSeconds
        ])
    }

    // MARK: - Competition

    func logCompetitionCreated(type: String) {
        logEvent(SpellFlareEvent.competitionCreated, params: ["type": type])
    }

    func logCompetitionJoined(competitionId: String, type: String) {
        logEvent(SpellFlareEvent.competitionJoined, params: [
            "competition_id": competitionId,
            "type": type
        ])
    }

    func logCompetitionCompleted(rank: Int, totalPlayers: Int, coinsEarned: Int) {
        logEvent(SpellFlareEvent.competitionCompleted, params: [
            "rank": rank,
            "total_players": totalPlayers,
            "coins_earned": coinsEarned
        ])
    }

    // MARK: - Leaderboard

    func logLeaderboardViewed(competitionId: String) {
        logEvent(SpellFlareEvent.leaderboardViewed, params: ["competition_id": competitionId])
    }

    // MARK: - Social

    func logFriendAdded() {
        logEvent(SpellFlareEvent.friendAdded)
    }

    func logInviteSent() {
        logEvent(SpellFlareEvent.inviteSent)
    }

    func logInviteAccepted() {
        logEvent(SpellFlareEvent.inviteAccepted)
    }

    // MARK: - Economy

    func logCoinsEarned(amount: Int, source: String) {
        logEvent(SpellFlareEvent.coinsEarned, params: [
            "amount": amount,
            "source": source
        ])
    }

    func logCoinsSubmitted(amount: Int, competitionId: String) {
        logEvent(SpellFlareEvent.coinsSubmitted, params: [
            "amount": amount,
            "competition_id": competitionId
        ])
    }

    // MARK: - Rank Behavior

    func logRankImproved() {
        logEvent(SpellFlareEvent.rankImproved)
    }

    func logRankDropped() {
        logEvent(SpellFlareEvent.rankDropped)
    }
}
