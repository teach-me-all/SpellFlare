//
//  ShopItem.swift
//  Shared
//
//  Data models for the Coin Shop system.
//

import Foundation

enum ShopCategory: String, Codable, CaseIterable {
    case beeSkin = "Bee Skins"
    case backgroundTheme = "Backgrounds"
    case celebrationEffect = "Celebrations"
}

struct ShopItemDefinition: Identifiable {
    let id: String
    let category: ShopCategory
    let title: String
    let description: String
    let iconName: String       // SF Symbol or emoji
    let price: Int             // 0 = free default
    let sortOrder: Int
}

struct ShopState: Codable, Equatable {
    var purchasedItems: Set<String> = []
    var equippedItems: [String: String] = [:]  // category rawValue -> item ID

    func isOwned(_ itemID: String) -> Bool {
        purchasedItems.contains(itemID)
    }

    func equippedItem(for category: ShopCategory) -> String? {
        equippedItems[category.rawValue]
    }

    mutating func purchase(_ itemID: String) {
        purchasedItems.insert(itemID)
    }

    mutating func equip(_ itemID: String, category: ShopCategory) {
        equippedItems[category.rawValue] = itemID
    }
}
