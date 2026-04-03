//
//  CompetitionService.swift
//  spelling-bee iOS App
//
//  Manages competition CRUD and coin batching.
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
    @Published private(set) var activeCompetition: Competition?
    @Published private(set) var myRankInActiveCompetition: Int?
    @Published private(set) var myCoinsInActiveCompetition: Int = 0

    var isInCompetition: Bool { activeCompetition != nil }

    // MARK: - Coin Batching
    private var pendingCoins: Int = 0
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

        activeCompetition = competition
        AnalyticsManager.shared.logCompetitionCreated(type: "private")
        AnalyticsManager.shared.logCompetitionJoined(competitionId: competition.id, type: "private")
        return competition
    }

    func joinPublicMatchmaking(username: String, avatarIcon: String) async throws {
        guard auth.currentUID != nil else {
            throw CompetitionError.notAuthenticated
        }

        let callable = functions.httpsCallable("joinPublicMatchmaking")
        let result = try await callable.call(["username": username, "avatarIcon": avatarIcon])

        guard let data = result.data as? [String: Any],
              let competitionId = data["competitionId"] as? String else {
            throw CompetitionError.invalidResponse
        }

        await loadCompetition(id: competitionId)
        AnalyticsManager.shared.logCompetitionJoined(competitionId: competitionId, type: "public")
    }

    func joinByInviteCode(_ code: String, username: String, avatarIcon: String) async throws {
        guard auth.currentUID != nil else {
            throw CompetitionError.notAuthenticated
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

        await loadCompetition(id: competitionId)
        AnalyticsManager.shared.logCompetitionJoined(competitionId: competitionId, type: "private")
    }

    func leaveCompetition() async throws {
        guard let competition = activeCompetition,
              let uid = auth.currentUID else { return }

        // Remove participant doc and decrement count
        let batch = db.batch()
        let participantRef = db
            .collection("competitions")
            .document(competition.id)
            .collection("participants")
            .document(uid)
        batch.deleteDocument(participantRef)
        let compRef = db.collection("competitions").document(competition.id)
        batch.updateData(["participantCount": FieldValue.increment(Int64(-1))], forDocument: compRef)
        try await batch.commit()

        activeCompetition = nil
        myRankInActiveCompetition = nil
        myCoinsInActiveCompetition = 0
    }

    // MARK: - Loading

    /// Load the user's active competition on app start
    func loadActiveCompetition(uid: String) async {
        do {
            // Query for competitions where user is a participant and competition is active/waiting
            // We check the participants subcollection via a collectionGroup query
            let participantSnaps = try await db
                .collectionGroup("participants")
                .whereField(FieldPath.documentID(), isEqualTo: uid)
                .getDocuments()

            for pDoc in participantSnaps.documents {
                guard let compRef = pDoc.reference.parent.parent else { continue }
                let compSnap = try await compRef.getDocument()
                guard let data = compSnap.data(),
                      let status = data["status"] as? String,
                      status == "active" || status == "waiting" else { continue }

                if let comp = Competition(from: compSnap) {
                    activeCompetition = comp
                    // Update my coins from participant doc
                    if let coins = pDoc.data()["coinsEarned"] as? Int {
                        myCoinsInActiveCompetition = coins
                    }
                    return
                }
            }
        } catch {
            print("CompetitionService: failed to load active competition: \(error)")
        }
    }

    private func loadCompetition(id: String) async {
        do {
            let snap = try await db.collection("competitions").document(id).getDocument()
            if let comp = Competition(from: snap) {
                activeCompetition = comp
            }
        } catch {
            print("CompetitionService: failed to load competition \(id): \(error)")
        }
    }

    // MARK: - Coin Batching

    /// Called when the user earns coins. Accumulates locally; flushes via timer or background.
    func recordCoinsEarned(_ amount: Int) {
        guard isInCompetition, amount > 0 else { return }
        pendingCoins += amount

        // Reset 30-second flush timer
        batchTimer?.invalidate()
        batchTimer = Timer.scheduledTimer(withTimeInterval: batchInterval, repeats: false) { [weak self] _ in
            Task { @MainActor in
                await self?.flushPendingCoins()
            }
        }
    }

    /// Flush accumulated coins to Firebase. Called on timer, app backgrounding, or explicit request.
    func flushPendingCoins() async {
        guard let competition = activeCompetition,
              competition.isActive,
              pendingCoins > 0,
              auth.currentUID != nil else { return }

        let delta = pendingCoins
        pendingCoins = 0
        batchTimer?.invalidate()
        batchTimer = nil

        do {
            let callable = functions.httpsCallable("submitCompetitionCoins")
            try await callable.call([
                "competitionId": competition.id,
                "delta": delta
            ])
            // Update local display
            myCoinsInActiveCompetition += delta
            AnalyticsManager.shared.logCoinsSubmitted(amount: delta, competitionId: competition.id)
        } catch {
            // Return coins to pending on failure so they can be retried
            pendingCoins += delta
            print("CompetitionService: failed to flush coins: \(error)")
        }
    }

    // MARK: - Watch Integration

    func activeCompetitionStatus() -> WatchCompetitionStatus {
        guard let comp = activeCompetition else { return .none }
        return WatchCompetitionStatus(
            competitionName: comp.name,
            myRank: myRankInActiveCompetition,
            myCoins: myCoinsInActiveCompetition,
            totalParticipants: comp.participantCount,
            daysRemaining: comp.daysRemaining,
            isActive: comp.isActive
        )
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

    var errorDescription: String? {
        switch self {
        case .notAuthenticated: return "Please set up your username to join competitions."
        case .invalidResponse: return "An unexpected error occurred. Please try again."
        case .competitionFull: return "This competition is full."
        case .competitionEnded: return "This competition has already ended."
        case .invalidCode: return "Invalid invite code."
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
