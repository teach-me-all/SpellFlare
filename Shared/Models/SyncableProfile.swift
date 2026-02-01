//
//  SyncableProfile.swift
//  Shared
//
//  Wraps UserProfile with CloudKit metadata for sync.
//

import Foundation
import CloudKit
#if os(iOS)
import UIKit
#elseif os(watchOS)
import WatchKit
#endif

struct SyncableProfile: Codable, Equatable {
    var profile: UserProfile
    var lastModified: Date
    var deviceIdentifier: String
    var schemaVersion: Int
    var isWatchUnlocked: Bool  // Sync premium state to Watch

    static let currentSchemaVersion = 5
    static let recordType = "UserProfile"

    init(profile: UserProfile, deviceIdentifier: String, isWatchUnlocked: Bool = false) {
        self.profile = profile
        self.lastModified = Date()
        self.deviceIdentifier = deviceIdentifier
        self.schemaVersion = Self.currentSchemaVersion
        self.isWatchUnlocked = isWatchUnlocked
    }

    init(profile: UserProfile, lastModified: Date, deviceIdentifier: String, schemaVersion: Int, isWatchUnlocked: Bool = false) {
        self.profile = profile
        self.lastModified = lastModified
        self.deviceIdentifier = deviceIdentifier
        self.schemaVersion = schemaVersion
        self.isWatchUnlocked = isWatchUnlocked
    }

    // Custom decoder to handle migration from older versions without isWatchUnlocked
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        profile = try container.decode(UserProfile.self, forKey: .profile)
        lastModified = try container.decode(Date.self, forKey: .lastModified)
        deviceIdentifier = try container.decode(String.self, forKey: .deviceIdentifier)
        schemaVersion = try container.decode(Int.self, forKey: .schemaVersion)
        // Default to false if not present (migration from schema v1)
        isWatchUnlocked = (try? container.decode(Bool.self, forKey: .isWatchUnlocked)) ?? false
    }

    private enum CodingKeys: String, CodingKey {
        case profile, lastModified, deviceIdentifier, schemaVersion, isWatchUnlocked
    }

    mutating func updateProfile(_ profile: UserProfile) {
        self.profile = profile
        self.lastModified = Date()
    }

    // MARK: - CloudKit Conversion

    func toCKRecord(recordID: CKRecord.ID? = nil) -> CKRecord {
        let id = recordID ?? CKRecord.ID(recordName: UUID().uuidString)
        let record = CKRecord(recordType: Self.recordType, recordID: id)

        record["profileID"] = profile.id.uuidString as CKRecordValue
        record["name"] = profile.name as CKRecordValue
        record["avatarIcon"] = profile.avatarIcon as CKRecordValue
        record["grade"] = profile.grade as CKRecordValue
        record["lastModified"] = lastModified as CKRecordValue
        record["deviceIdentifier"] = deviceIdentifier as CKRecordValue
        record["schemaVersion"] = schemaVersion as CKRecordValue
        record["isWatchUnlocked"] = isWatchUnlocked as CKRecordValue
        record["totalCoins"] = profile.totalCoins as CKRecordValue

        // Encode dictionaries as JSON data
        if let completedData = try? JSONEncoder().encode(profile.completedLevelsByGrade) {
            record["completedLevelsByGrade"] = completedData as CKRecordValue
        }

        if let currentData = try? JSONEncoder().encode(profile.currentLevelByGrade) {
            record["currentLevelByGrade"] = currentData as CKRecordValue
        }

        if let shopData = try? JSONEncoder().encode(profile.shopState) {
            record["shopState"] = shopData as CKRecordValue
        }

        return record
    }

    static func from(record: CKRecord) -> SyncableProfile? {
        guard let name = record["name"] as? String,
              let grade = record["grade"] as? Int,
              let lastModified = record["lastModified"] as? Date,
              let deviceIdentifier = record["deviceIdentifier"] as? String,
              let schemaVersion = record["schemaVersion"] as? Int else {
            return nil
        }

        var completedLevelsByGrade: [Int: Set<Int>] = [:]
        var currentLevelByGrade: [Int: Int] = [:]

        if let completedData = record["completedLevelsByGrade"] as? Data {
            completedLevelsByGrade = (try? JSONDecoder().decode([Int: Set<Int>].self, from: completedData)) ?? [:]
        }

        if let currentData = record["currentLevelByGrade"] as? Data {
            currentLevelByGrade = (try? JSONDecoder().decode([Int: Int].self, from: currentData)) ?? [:]
        }

        // Get isWatchUnlocked and totalCoins (default to false/0 for migration)
        let isWatchUnlocked = record["isWatchUnlocked"] as? Bool ?? false
        let totalCoins = record["totalCoins"] as? Int ?? 0

        // Decode shop state
        var shopState = ShopState()
        if let shopData = record["shopState"] as? Data {
            shopState = (try? JSONDecoder().decode(ShopState.self, from: shopData)) ?? ShopState()
        }

        // Reconstruct UserProfile
        let profileUUID: UUID
        if let idString = record["profileID"] as? String, let parsed = UUID(uuidString: idString) {
            profileUUID = parsed
        } else {
            profileUUID = UUID()
        }
        let avatarIcon = record["avatarIcon"] as? String ?? "🐝"

        var profile = UserProfile(name: name, grade: grade, id: profileUUID, avatarIcon: avatarIcon)
        profile.completedLevelsByGrade = completedLevelsByGrade
        profile.currentLevelByGrade = currentLevelByGrade
        profile.totalCoins = totalCoins
        profile.shopState = shopState

        // Ensure all grades are initialized
        for g in 1...7 {
            if profile.currentLevelByGrade[g] == nil {
                profile.currentLevelByGrade[g] = 1
            }
            if profile.completedLevelsByGrade[g] == nil {
                profile.completedLevelsByGrade[g] = []
            }
        }

        return SyncableProfile(
            profile: profile,
            lastModified: lastModified,
            deviceIdentifier: deviceIdentifier,
            schemaVersion: schemaVersion,
            isWatchUnlocked: isWatchUnlocked
        )
    }

    // MARK: - Conflict Resolution

    func shouldOverwrite(_ other: SyncableProfile) -> Bool {
        // Most recent wins
        return self.lastModified > other.lastModified
    }

    static func merge(local: SyncableProfile, remote: SyncableProfile) -> SyncableProfile {
        // Simple strategy: most recent wins
        if local.lastModified > remote.lastModified {
            return local
        } else {
            return remote
        }
    }
}

// MARK: - Device Identifier Helper

enum DeviceIdentifier {
    static var current: String {
        #if os(iOS)
        return UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        #elseif os(watchOS)
        return WKInterfaceDevice.current().identifierForVendor?.uuidString ?? UUID().uuidString
        #else
        return UUID().uuidString
        #endif
    }
}
