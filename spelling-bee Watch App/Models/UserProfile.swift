//
//  UserProfile.swift
//  spelling-bee Watch App
//

import Foundation

struct UserProfile: Codable, Equatable {
    var name: String
    var grade: Int // 1-7
    // Track completed levels per grade: [grade: Set<level>]
    var completedLevelsByGrade: [Int: Set<Int>]
    var currentLevelByGrade: [Int: Int]

    init(name: String, grade: Int) {
        self.name = name
        self.grade = max(1, min(7, grade))
        self.completedLevelsByGrade = [:]
        self.currentLevelByGrade = [:]
        // Initialize all grades with level 1
        for g in 1...7 {
            currentLevelByGrade[g] = 1
            completedLevelsByGrade[g] = []
        }
    }

    // Computed property for current grade's completed levels
    var completedLevels: Set<Int> {
        return completedLevelsByGrade[grade] ?? []
    }

    // Computed property for current grade's current level
    var currentLevel: Int {
        return currentLevelByGrade[grade] ?? 1
    }

    mutating func completeLevel(_ level: Int) {
        // Complete level for current grade only
        if completedLevelsByGrade[grade] == nil {
            completedLevelsByGrade[grade] = []
        }
        completedLevelsByGrade[grade]?.insert(level)

        let current = currentLevelByGrade[grade] ?? 1
        if level >= current && level < 50 {
            currentLevelByGrade[grade] = level + 1
        }
    }

    func isLevelUnlocked(_ level: Int) -> Bool {
        let current = currentLevelByGrade[grade] ?? 1
        let completed = completedLevelsByGrade[grade] ?? []
        return level <= current || completed.contains(level)
    }

    func isLevelCompleted(_ level: Int) -> Bool {
        return completedLevelsByGrade[grade]?.contains(level) ?? false
    }

    // Migration from old format
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        grade = try container.decode(Int.self, forKey: .grade)

        // Try to decode new format first
        if let levelsByGrade = try? container.decode([Int: Set<Int>].self, forKey: .completedLevelsByGrade) {
            completedLevelsByGrade = levelsByGrade
        } else if let oldCompletedLevels = try? container.decode(Set<Int>.self, forKey: .completedLevels) {
            // Migration: old format had completedLevels as Set<Int>
            completedLevelsByGrade = [grade: oldCompletedLevels]
        } else {
            completedLevelsByGrade = [:]
        }

        if let currentByGrade = try? container.decode([Int: Int].self, forKey: .currentLevelByGrade) {
            currentLevelByGrade = currentByGrade
        } else if let oldCurrentLevel = try? container.decode(Int.self, forKey: .currentLevel) {
            // Migration: old format had currentLevel as Int
            currentLevelByGrade = [grade: oldCurrentLevel]
        } else {
            currentLevelByGrade = [:]
        }

        // Ensure all grades are initialized
        for g in 1...7 {
            if currentLevelByGrade[g] == nil {
                currentLevelByGrade[g] = 1
            }
            if completedLevelsByGrade[g] == nil {
                completedLevelsByGrade[g] = []
            }
        }
    }

    private enum CodingKeys: String, CodingKey {
        case name, grade, completedLevelsByGrade, currentLevelByGrade, completedLevels, currentLevel
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(grade, forKey: .grade)
        try container.encode(completedLevelsByGrade, forKey: .completedLevelsByGrade)
        try container.encode(currentLevelByGrade, forKey: .currentLevelByGrade)
    }
}
