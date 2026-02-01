//
//  ShopService.swift
//  Shared
//
//  Purchase and equip logic for the Coin Shop.
//

import Foundation

enum ShopPurchaseResult {
    case success
    case insufficientCoins
    case alreadyOwned
    case itemNotFound
}

class ShopService {
    static let shared = ShopService()

    private init() {}

    func purchaseItem(_ itemID: String, profile: inout UserProfile) -> ShopPurchaseResult {
        guard let definition = ShopItemDefinitions.definition(for: itemID) else {
            return .itemNotFound
        }

        if profile.shopState.isOwned(itemID) {
            return .alreadyOwned
        }

        if profile.totalCoins < definition.price {
            return .insufficientCoins
        }

        // Deduct coins
        profile.totalCoins -= definition.price

        // Add to purchased
        profile.shopState.purchase(itemID)

        // Auto-equip the purchased item
        profile.shopState.equip(itemID, category: definition.category)

        return .success
    }

    func equipItem(_ itemID: String, profile: inout UserProfile) -> Bool {
        guard let definition = ShopItemDefinitions.definition(for: itemID) else {
            return false
        }

        guard profile.shopState.isOwned(itemID) else {
            return false
        }

        profile.shopState.equip(itemID, category: definition.category)
        return true
    }

    func initializeDefaults(profile: inout UserProfile) {
        let defaults = ShopItemDefinitions.defaultItemIDs
        for itemID in defaults {
            profile.shopState.purchase(itemID)
        }
        // Equip defaults
        for category in ShopCategory.allCases {
            let defaultItem = ShopItemDefinitions.definitions(for: category).first { $0.price == 0 }
            if let defaultItem = defaultItem {
                profile.shopState.equip(defaultItem.id, category: category)
            }
        }
    }

    func migrateExistingProfile(profile: inout UserProfile) {
        guard !profile.shopMigrationCompleted else { return }
        initializeDefaults(profile: &profile)
        profile.shopMigrationCompleted = true
    }
}
