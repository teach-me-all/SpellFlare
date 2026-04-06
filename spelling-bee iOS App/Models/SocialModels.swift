//
//  SocialModels.swift
//  spelling-bee iOS App
//
//  Data models for the social competition system.
//

import Foundation

// MARK: - Competition

enum CompetitionType: String, Codable {
    case `private`
    case `public`
}

enum CompetitionStatus: String, Codable {
    case waiting
    case active
    case completed
}

struct Competition: Codable, Identifiable, Equatable {
    let id: String
    var name: String
    var type: CompetitionType
    var status: CompetitionStatus
    var startTime: Date
    var endTime: Date
    var createdBy: String
    var maxPlayers: Int
    var inviteCode: String
    var participantCount: Int

    var timeRemaining: TimeInterval {
        max(0, endTime.timeIntervalSinceNow)
    }

    var daysRemaining: Int {
        Int(ceil(timeRemaining / 86400))
    }

    var isActive: Bool { status == .active }
    var isWaiting: Bool { status == .waiting }
    var isCompleted: Bool { status == .completed }

    /// Returns a human-readable status string with exact local times.
    var statusLabel: String {
        let formatter = DateFormatter()
        switch status {
        case .waiting:
            formatter.dateFormat = "MMM d 'at' h:mm a"
            let timeStr = formatter.string(from: startTime)
            if startTime.timeIntervalSinceNow <= 0 {
                return "Starting \(timeStr) · Waiting for players"
            }
            return "Starts \(timeStr)"
        case .active:
            formatter.dateFormat = "MMM d 'at' h:mm a"
            let endStr = formatter.string(from: endTime)
            return "Ends \(endStr)"
        case .completed:
            return "Ended"
        }
    }
}

// MARK: - Leaderboard

struct LeaderboardEntry: Codable, Identifiable, Equatable {
    let id: String       // userId
    var username: String
    var avatarIcon: String
    var coinsEarned: Int
    var rank: Int
    var isCurrentUser: Bool
}

// MARK: - Friends

enum FriendStatus: String, Codable {
    case pendingSent = "pending_sent"
    case pendingReceived = "pending_received"
    case accepted
}

struct Friend: Codable, Identifiable, Equatable {
    let id: String       // friendUID
    var username: String
    var avatarIcon: String
    var status: FriendStatus
}

struct UserSearchResult: Codable, Identifiable, Equatable {
    let id: String       // userId
    var username: String
    var avatarIcon: String
}

// MARK: - Rewards

struct CompetitionReward: Codable, Identifiable, Equatable {
    let id: String
    var competitionId: String
    var competitionName: String
    var rank: Int
    var totalParticipants: Int
    var rewardType: String
    var coinsAmount: Int
    var claimed: Bool
}

// MARK: - Competition History

struct CompetitionHistoryEntry: Identifiable {
    let id: String              // competition ID
    let name: String
    let type: CompetitionType
    let endTime: Date
    let totalParticipants: Int
    let myCoinsEarned: Int
    let myFinalRank: Int?       // nil until backend stores it on competition end
}

// MARK: - Watch Competition Status (lightweight, for WatchConnectivity)

struct WatchCompetitionStatus: Codable {
    var competitionName: String?
    var myRank: Int?
    var myCoins: Int
    var totalParticipants: Int
    var daysRemaining: Int
    var isActive: Bool

    static let none = WatchCompetitionStatus(
        competitionName: nil, myRank: nil,
        myCoins: 0, totalParticipants: 0,
        daysRemaining: 0, isActive: false
    )
}

// MARK: - Social User (Firestore users/{userId} doc)

struct SocialUser: Codable {
    var username: String
    var avatarIcon: String
    var profileId: String
    var totalCoins: Int
    var fcmToken: String?
}
