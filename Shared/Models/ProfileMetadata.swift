//
//  ProfileMetadata.swift
//  Shared
//
//  Lightweight profile identity for display in profile lists.
//

import Foundation

struct ProfileMetadata: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var avatarIcon: String
    var grade: Int
    var createdAt: Date

    init(id: UUID, name: String, avatarIcon: String, grade: Int, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.avatarIcon = avatarIcon
        self.grade = grade
        self.createdAt = createdAt
    }

    init(from profile: UserProfile) {
        self.id = profile.id
        self.name = profile.name
        self.avatarIcon = profile.avatarIcon
        self.grade = profile.grade
        self.createdAt = Date()
    }
}
