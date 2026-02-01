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
        ShopItemDefinition(id: "bee_default", category: .beeSkin, title: "Classic Bee", description: "Your trusty spelling buddy!", iconName: "bee_default", price: 0, sortOrder: 0),
        ShopItemDefinition(id: "bee_super", category: .beeSkin, title: "Super Bee", description: "Zoom! Spell faster with super powers!", iconName: "bee_super", price: 800, sortOrder: 1),
        ShopItemDefinition(id: "bee_ninja", category: .beeSkin, title: "Ninja Bee", description: "Sneak through words like a shadow!", iconName: "bee_ninja", price: 1200, sortOrder: 2),
        ShopItemDefinition(id: "bee_astronaut", category: .beeSkin, title: "Astro Bee", description: "Blast off and spell among the stars!", iconName: "bee_astronaut", price: 1500, sortOrder: 3),
        ShopItemDefinition(id: "bee_royal", category: .beeSkin, title: "Royal Bee", description: "Rule the hive as the spelling champion!", iconName: "bee_royal", price: 2000, sortOrder: 4),
    ]

    // MARK: - Background Themes

    static let backgroundThemes: [ShopItemDefinition] = [
        ShopItemDefinition(id: "bg_default", category: .backgroundTheme, title: "Purple Dream", description: "The cool purple look you know and love!", iconName: "bg_default", price: 0, sortOrder: 0),
        ShopItemDefinition(id: "bg_space", category: .backgroundTheme, title: "Deep Space", description: "Float through galaxies while you spell!", iconName: "bg_space", price: 1000, sortOrder: 1),
        ShopItemDefinition(id: "bg_ocean", category: .backgroundTheme, title: "Ocean Wave", description: "Dive deep and ride the waves!", iconName: "bg_ocean", price: 1200, sortOrder: 2),
        ShopItemDefinition(id: "bg_candy", category: .backgroundTheme, title: "Candy Land", description: "Everything looks sweet and yummy!", iconName: "bg_candy", price: 1500, sortOrder: 3),
        ShopItemDefinition(id: "bg_forest", category: .backgroundTheme, title: "Enchanted Forest", description: "Spell under magical glowing trees!", iconName: "bg_forest", price: 1800, sortOrder: 4),
    ]

    // MARK: - Celebration Effects

    static let celebrationEffects: [ShopItemDefinition] = [
        ShopItemDefinition(id: "cel_default", category: .celebrationEffect, title: "Classic Confetti", description: "Party time with colorful confetti!", iconName: "cel_default", price: 0, sortOrder: 0),
        ShopItemDefinition(id: "cel_confetti", category: .celebrationEffect, title: "Gold Confetti", description: "Shine bright with golden sparkles!", iconName: "cel_confetti", price: 700, sortOrder: 1),
        ShopItemDefinition(id: "cel_fireworks", category: .celebrationEffect, title: "Fireworks", description: "BOOM! Light up the sky when you win!", iconName: "cel_fireworks", price: 1300, sortOrder: 2),
        ShopItemDefinition(id: "cel_rainbow", category: .celebrationEffect, title: "Rainbow Burst", description: "Paint the sky with every color!", iconName: "cel_rainbow", price: 1600, sortOrder: 3),
        ShopItemDefinition(id: "cel_stars", category: .celebrationEffect, title: "Shooting Stars", description: "Watch stars fly across the sky!", iconName: "cel_stars", price: 1900, sortOrder: 4),
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
