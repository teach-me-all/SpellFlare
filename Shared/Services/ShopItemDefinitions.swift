//
//  ShopItemDefinitions.swift
//  Shared
//
//  Static registry of all 15 shop items across 3 categories.
//

import Foundation

enum ShopItemDefinitions {

    // MARK: - Bee Skins

    static let beeSkins: [ShopItemDefinition] = [
        ShopItemDefinition(id: "bee_default", category: .beeSkin, title: "Classic Bee", description: "The original spelling bee", iconName: "bee_default", price: 0, sortOrder: 0),
        ShopItemDefinition(id: "bee_super", category: .beeSkin, title: "Super Bee", description: "A bee with super powers", iconName: "bee_super", price: 800, sortOrder: 1),
        ShopItemDefinition(id: "bee_ninja", category: .beeSkin, title: "Ninja Bee", description: "Silent but deadly speller", iconName: "bee_ninja", price: 1200, sortOrder: 2),
        ShopItemDefinition(id: "bee_astronaut", category: .beeSkin, title: "Astro Bee", description: "Spelling in space", iconName: "bee_astronaut", price: 1500, sortOrder: 3),
        ShopItemDefinition(id: "bee_royal", category: .beeSkin, title: "Royal Bee", description: "The queen of spelling", iconName: "bee_royal", price: 2000, sortOrder: 4),
    ]

    // MARK: - Background Themes

    static let backgroundThemes: [ShopItemDefinition] = [
        ShopItemDefinition(id: "bg_default", category: .backgroundTheme, title: "Purple Dream", description: "The classic purple look", iconName: "bg_default", price: 0, sortOrder: 0),
        ShopItemDefinition(id: "bg_space", category: .backgroundTheme, title: "Deep Space", description: "Among the stars", iconName: "bg_space", price: 1000, sortOrder: 1),
        ShopItemDefinition(id: "bg_ocean", category: .backgroundTheme, title: "Ocean Wave", description: "Under the sea vibes", iconName: "bg_ocean", price: 1200, sortOrder: 2),
        ShopItemDefinition(id: "bg_candy", category: .backgroundTheme, title: "Candy Land", description: "Sweet and colorful", iconName: "bg_candy", price: 1500, sortOrder: 3),
        ShopItemDefinition(id: "bg_forest", category: .backgroundTheme, title: "Enchanted Forest", description: "Magical woodland", iconName: "bg_forest", price: 1800, sortOrder: 4),
    ]

    // MARK: - Celebration Effects

    static let celebrationEffects: [ShopItemDefinition] = [
        ShopItemDefinition(id: "cel_default", category: .celebrationEffect, title: "Classic Confetti", description: "Colorful paper confetti", iconName: "cel_default", price: 0, sortOrder: 0),
        ShopItemDefinition(id: "cel_confetti", category: .celebrationEffect, title: "Gold Confetti", description: "Fancy gold celebration", iconName: "cel_confetti", price: 700, sortOrder: 1),
        ShopItemDefinition(id: "cel_fireworks", category: .celebrationEffect, title: "Fireworks", description: "Explosive celebration", iconName: "cel_fireworks", price: 1300, sortOrder: 2),
        ShopItemDefinition(id: "cel_rainbow", category: .celebrationEffect, title: "Rainbow Burst", description: "All the colors", iconName: "cel_rainbow", price: 1600, sortOrder: 3),
        ShopItemDefinition(id: "cel_stars", category: .celebrationEffect, title: "Shooting Stars", description: "Reach for the stars", iconName: "cel_stars", price: 1900, sortOrder: 4),
    ]

    // MARK: - Accessors

    static var all: [ShopItemDefinition] {
        beeSkins + backgroundThemes + celebrationEffects
    }

    static func definitions(for category: ShopCategory) -> [ShopItemDefinition] {
        switch category {
        case .beeSkin: return beeSkins
        case .backgroundTheme: return backgroundThemes
        case .celebrationEffect: return celebrationEffects
        }
    }

    static func definition(for itemID: String) -> ShopItemDefinition? {
        all.first { $0.id == itemID }
    }

    static var defaultItemIDs: Set<String> {
        Set(all.filter { $0.price == 0 }.map { $0.id })
    }
}
