//
//  CompetitionService.swift
//  spelling-bee iOS App
//
//  Manages competition CRUD and coin batching.
//  Supports 1 public + up to 4 private competitions simultaneously.
//  Coins are accumulated locally and flushed to Firebase in batches
//  (on level completion timer expiry or app backgrounding) to minimize Firestore writes.
//

import Foundation
import FirebaseFirestore
import FirebaseFunctions

@MainActor
class CompetitionService: ObservableObject {
    static let shared = CompetitionService()

    // MARK: - Published State

    /// All competitions the user is currently enrolled in (active or waiting).
    @Published private(set) var allCompetitions: [Competition] = []

    // MARK: - Slot Limits

    static let maxPublic = 1
    static let maxPrivate = 4

    var publicCompetitions: [Competition] { allCompetitions.filter { $0.type == .public } }
    var privateCompetitions: [Competition] { allCompetitions.filter { $0.type == .private } }

    /// Convenience: first public competition (there can only be one).
    var activeCompetition: Competition? { publicCompetitions.first ?? privateCompetitions.first }

    var isInCompetition: Bool { !allCompetitions.isEmpty }
    var canJoinPublic: Bool { publicCompetitions.count < Self.maxPublic }
    var canJoinPrivate: Bool { privateCompetitions.count < Self.maxPrivate }

    // MARK: - Coin Batching

    /// Coins earned locally that haven't been flushed to Firestore yet.
    /// Published so the leaderboard can show them immediately (optimistic update).
    @Published private(set) var localPendingCoins: Int = 0
    private var batchTimer: Timer?
    private let batchInterval: TimeInterval = 30

    // MARK: - Dependencies

    private let db = Firestore.firestore()
    private let functions = Functions.functions()
    private let auth = FirebaseManager.shared

    private init() {}

    // MARK: - Competition Lifecycle

    func createPrivateCompetition(name: String, username: String, avatarIcon: String) async throws -> Competition {
        guard let uid = auth.currentUID else {
            throw CompetitionError.notAuthenticated
        }
        guard canJoinPrivate else {
            throw CompetitionError.tooManyCompetitions
        }

        let inviteCode = generateInviteCode()
        let startTime = Date()
        let endTime = startTime.addingTimeInterval(7 * 24 * 3600)

        let data: [String: Any] = [
            "type": "private",
            "name": name,
            "status": "waiting",
            "startTime": Timestamp(date: startTime),
            "endTime": Timestamp(date: endTime),
            "createdBy": uid,
            "maxPlayers": 10,
            "inviteCode": inviteCode,
            "participantCount": 0,
            "rewardsDistributed": false
        ]

        let ref = try await db.collection("competitions").addDocument(data: data)

        // Join as first participant
        let participant: [String: Any] = [
            "userId": uid,
            "username": username,
            "avatarIcon": avatarIcon,
            "coinsEarned": 0,
            "joinedAt": Timestamp(date: Date()),
            "lastUpdatedAt": Timestamp(date: Date())
        ]
        try await ref.collection("participants").document(uid).setData(participant)
        try await ref.updateData(["participantCount": FieldValue.increment(Int64(1))])

        let competition = Competition(
            id: ref.documentID,
            name: name,
            type: .private,
            status: .waiting,
            startTime: startTime,
            endTime: endTime,
            createdBy: uid,
            maxPlayers: 10,
            inviteCode: inviteCode,
            participantCount: 1
        )

        allCompetitions.append(competition)
        AnalyticsManager.shared.logCompetitionCreated(type: "private")
        AnalyticsManager.shared.logCompetitionJoined(competitionId: competition.id, type: "private")
        return competition
    }

    func joinPublicMatchmaking(username: String, avatarIcon: String) async throws {
        guard auth.currentUID != nil else {
            throw CompetitionError.notAuthenticated
        }
        guard canJoinPublic else {
            throw CompetitionError.alreadyInPublicCompetition
        }

        let callable = functions.httpsCallable("joinPublicMatchmaking")
        let result = try await callable.call(["username": username, "avatarIcon": avatarIcon])

        guard let data = result.data as? [String: Any],
              let competitionId = data["competitionId"] as? String else {
            throw CompetitionError.invalidResponse
        }

        await loadAndAppendCompetition(id: competitionId, replacingType: .public)
        AnalyticsManager.shared.logCompetitionJoined(competitionId: competitionId, type: "public")
    }

    func joinByInviteCode(_ code: String, username: String, avatarIcon: String) async throws {
        guard auth.currentUID != nil else {
            throw CompetitionError.notAuthenticated
        }
        guard canJoinPrivate else {
            throw CompetitionError.tooManyCompetitions
        }

        let callable = functions.httpsCallable("joinByInviteCode")
        let result = try await callable.call([
            "inviteCode": code.uppercased(),
            "username": username,
            "avatarIcon": avatarIcon
        ])

        guard let data = result.data as? [String: Any],
              let competitionId = data["competitionId"] as? String else {
            throw CompetitionError.invalidResponse
        }

        await loadAndAppendCompetition(id: competitionId, replacingType: nil)
        AnalyticsManager.shared.logCompetitionJoined(competitionId: competitionId, type: "private")
    }

    func leaveCompetition(id: String) async throws {
        guard let uid = auth.currentUID else { return }

        let leaving = allCompetitions.first { $0.id == id }

        let batch = db.batch()
        let participantRef = db
            .collection("competitions").document(id)
            .collection("participants").document(uid)
        batch.deleteDocument(participantRef)
        let compRef = db.collection("competitions").document(id)
        batch.updateData(["participantCount": FieldValue.increment(Int64(-1))], forDocument: compRef)
        try await batch.commit()

        allCompetitions.removeAll { $0.id == id }

        if let comp = leaving {
            AnalyticsManager.shared.logCompetitionLeft(
                competitionId: id,
                type: comp.type == .public ? "public" : "private",
                coinsEarned: localPendingCoins
            )
        }
    }

    // MARK: - Loading

    /// Load all of the user's active/waiting competitions on app start.
    func loadActiveCompetition(uid: String) async {
        do {
            let participantSnaps = try await db
                .collectionGroup("participants")
                .whereField("userId", isEqualTo: uid)
                .getDocuments()

            var competitions: [Competition] = []
            for pDoc in participantSnaps.documents {
                guard let compRef = pDoc.reference.parent.parent else { continue }
                let compSnap = try await compRef.getDocument()
                guard let data = compSnap.data(),
                      let status = data["status"] as? String,
                      status == "active" || status == "waiting" else { continue }

                if let comp = Competition(from: compSnap) {
                    competitions.append(comp)
                }
            }
            allCompetitions = competitions
        } catch {
            print("CompetitionService: failed to load competitions: \(error)")
        }
    }

    private func loadAndAppendCompetition(id: String, replacingType: CompetitionType?) async {
        do {
            let snap = try await db.collection("competitions").document(id).getDocument()
            if let comp = Competition(from: snap) {
                if let type = replacingType {
                    allCompetitions.removeAll { $0.type == type }
                } else {
                    allCompetitions.removeAll { $0.id == id }
                }
                allCompetitions.append(comp)
            }
        } catch {
            print("CompetitionService: failed to load competition \(id): \(error)")
        }
    }

    // MARK: - Coin Batching

    /// Called when the user earns coins. Accumulates locally; flushes to all active competitions.
    func recordCoinsEarned(_ amount: Int) {
        guard isInCompetition, amount > 0 else { return }
        localPendingCoins += amount

        batchTimer?.invalidate()
        batchTimer = Timer.scheduledTimer(withTimeInterval: batchInterval, repeats: false) { [weak self] _ in
            Task { @MainActor in
                await self?.flushPendingCoins()
            }
        }
    }

    /// Flush accumulated coins to all active competitions.
    func flushPendingCoins() async {
        let activeComps = allCompetitions.filter { $0.isActive }
        guard !activeComps.isEmpty, localPendingCoins > 0, auth.currentUID != nil else { return }

        let delta = localPendingCoins
        localPendingCoins = 0
        batchTimer?.invalidate()
        batchTimer = nil

        for comp in activeComps {
            do {
                let callable = functions.httpsCallable("submitCompetitionCoins")
                _ = try await callable.call(["competitionId": comp.id, "delta": delta])
                AnalyticsManager.shared.logCoinsSubmitted(amount: delta, competitionId: comp.id)
            } catch {
                // Return coins to pending on first failure
                localPendingCoins += delta
                print("CompetitionService: failed to flush coins for \(comp.id): \(error)")
                return
            }
        }
    }

    // MARK: - Watch Integration

    func activeCompetitionStatus() -> WatchCompetitionStatus {
        guard let comp = allCompetitions.first(where: { $0.isActive }) ?? allCompetitions.first else {
            return .none
        }
        return WatchCompetitionStatus(
            competitionName: comp.name,
            myRank: nil,
            myCoins: 0,
            totalParticipants: comp.participantCount,
            daysRemaining: comp.daysRemaining,
            isActive: comp.isActive
        )
    }

    // MARK: - History

    func loadCompetitionHistory(uid: String) async -> [CompetitionHistoryEntry] {
        do {
            let participantSnaps = try await db
                .collectionGroup("participants")
                .whereField("userId", isEqualTo: uid)
                .getDocuments()

            var entries: [CompetitionHistoryEntry] = []
            for pDoc in participantSnaps.documents {
                guard let compRef = pDoc.reference.parent.parent else { continue }
                let compSnap = try await compRef.getDocument()
                guard let data = compSnap.data(),
                      let status = data["status"] as? String,
                      status == "completed",
                      let name = data["name"] as? String,
                      let typeStr = data["type"] as? String,
                      let type_ = CompetitionType(rawValue: typeStr),
                      let endTs = data["endTime"] as? Timestamp,
                      let participantCount = data["participantCount"] as? Int
                else { continue }

                let pData = pDoc.data()
                let coinsEarned = pData["coinsEarned"] as? Int ?? 0
                let finalRank = pData["finalRank"] as? Int

                entries.append(CompetitionHistoryEntry(
                    id: compSnap.documentID,
                    name: name,
                    type: type_,
                    endTime: endTs.dateValue(),
                    totalParticipants: participantCount,
                    myCoinsEarned: coinsEarned,
                    myFinalRank: finalRank
                ))
            }
            return entries.sorted { $0.endTime > $1.endTime }
        } catch {
            print("CompetitionService: failed to load history: \(error)")
            return []
        }
    }

    // MARK: - Rewards

    func fetchUnclaimedRewards(uid: String) async throws -> [CompetitionReward] {
        let snap = try await db
            .collection("rewards")
            .document(uid)
            .collection("earned")
            .whereField("claimed", isEqualTo: false)
            .getDocuments()

        return snap.documents.compactMap { CompetitionReward(from: $0) }
    }

    func claimReward(_ reward: CompetitionReward, uid: String) async throws {
        let ref = db
            .collection("rewards")
            .document(uid)
            .collection("earned")
            .document(reward.id)
        try await ref.updateData(["claimed": true])
    }

    // MARK: - Helpers

    private func generateInviteCode() -> String {
        let chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        return String((0..<6).map { _ in chars.randomElement()! })
    }
}

// MARK: - Errors

enum CompetitionError: LocalizedError {
    case notAuthenticated
    case invalidResponse
    case competitionFull
    case competitionEnded
    case invalidCode
    case alreadyInPublicCompetition
    case tooManyCompetitions

    var errorDescription: String? {
        switch self {
        case .notAuthenticated: return "Please set up your username to join competitions."
        case .invalidResponse: return "An unexpected error occurred. Please try again."
        case .competitionFull: return "This competition is full."
        case .competitionEnded: return "This competition has already ended."
        case .invalidCode: return "Invalid invite code."
        case .alreadyInPublicCompetition: return "You're already in a public competition."
        case .tooManyCompetitions: return "You can be in up to 4 private competitions at a time."
        }
    }
}

// MARK: - Firestore Parsing Extensions

extension Competition {
    init?(from snapshot: DocumentSnapshot) {
        guard let data = snapshot.data(),
              let name = data["name"] as? String,
              let typeStr = data["type"] as? String,
              let type_ = CompetitionType(rawValue: typeStr),
              let statusStr = data["status"] as? String,
              let status = CompetitionStatus(rawValue: statusStr),
              let startTs = data["startTime"] as? Timestamp,
              let endTs = data["endTime"] as? Timestamp,
              let createdBy = data["createdBy"] as? String,
              let maxPlayers = data["maxPlayers"] as? Int,
              let inviteCode = data["inviteCode"] as? String,
              let participantCount = data["participantCount"] as? Int
        else { return nil }

        self.id = snapshot.documentID
        self.name = name
        self.type = type_
        self.status = status
        self.startTime = startTs.dateValue()
        self.endTime = endTs.dateValue()
        self.createdBy = createdBy
        self.maxPlayers = maxPlayers
        self.inviteCode = inviteCode
        self.participantCount = participantCount
    }
}

extension CompetitionReward {
    init?(from snapshot: DocumentSnapshot) {
        guard let data = snapshot.data(),
              let competitionId = data["competitionId"] as? String,
              let competitionName = data["competitionName"] as? String,
              let rank = data["rank"] as? Int,
              let total = data["totalParticipants"] as? Int,
              let rewardType = data["rewardType"] as? String,
              let coinsAmount = data["coinsAmount"] as? Int,
              let claimed = data["claimed"] as? Bool
        else { return nil }

        self.id = snapshot.documentID
        self.competitionId = competitionId
        self.competitionName = competitionName
        self.rank = rank
        self.totalParticipants = total
        self.rewardType = rewardType
        self.coinsAmount = coinsAmount
        self.claimed = claimed
    }
}
