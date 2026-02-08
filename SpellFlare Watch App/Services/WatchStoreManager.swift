//
//  WatchStoreManager.swift
//  SpellFlare Watch App
//
//  Manages In-App Purchases using StoreKit 2 for standalone Watch purchases.
//  Handles "Unlock Watch" non-consumable purchase directly on watchOS.
//

import Foundation
import StoreKit

@MainActor
class WatchStoreManager: ObservableObject {
    static let shared = WatchStoreManager()

    // MARK: - Product ID
    static let unlockWatchProductId = "unlock_watch"

    // MARK: - Debug Mode
    #if DEBUG
    private let debugMode = true
    #else
    private let debugMode = false
    #endif

    // MARK: - Published State
    @Published private(set) var isWatchUnlocked: Bool = false
    @Published private(set) var unlockWatchProduct: Product?
    @Published private(set) var purchaseInProgress: Bool = false
    @Published private(set) var purchaseError: String?
    @Published private(set) var isLoading: Bool = false

    // MARK: - Private Properties
    private var updateListenerTask: Task<Void, Error>?
    private let purchaseStateKey = "watch_store_isWatchUnlocked"

    // MARK: - Initialization

    init() {
        // Load persisted purchase state
        isWatchUnlocked = UserDefaults.standard.bool(forKey: purchaseStateKey)

        // Start listening for transaction updates
        updateListenerTask = listenForTransactions()

        // Check current entitlements on init
        Task {
            await checkEntitlements()
            await loadProducts()
        }
    }

    deinit {
        updateListenerTask?.cancel()
    }

    // MARK: - Load Products

    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let products = try await Product.products(for: [WatchStoreManager.unlockWatchProductId])
            if let product = products.first {
                unlockWatchProduct = product
                print("Loaded Watch product: \(product.displayName) - \(product.displayPrice)")
            }
        } catch {
            print("Failed to load Watch products: \(error)")
            purchaseError = "Unable to load products"
        }
    }

    // MARK: - Check Entitlements

    func checkEntitlements() async {
        var foundWatchUnlocked = false

        // Check all current entitlements
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if transaction.productID == WatchStoreManager.unlockWatchProductId {
                    foundWatchUnlocked = true
                }
            }
        }

        isWatchUnlocked = foundWatchUnlocked
        persistPurchaseState()

        // Sync to WatchSyncHelper so UI stays consistent
        if foundWatchUnlocked {
            WatchSyncHelper.shared.updatePurchaseState(isWatchUnlocked: true)
        }
    }

    // MARK: - Purchase Unlock Watch

    func purchaseUnlockWatch() async -> Bool {
        // Debug mode: simulate purchase without StoreKit
        if debugMode {
            purchaseInProgress = true
            purchaseError = nil
            try? await Task.sleep(nanoseconds: 500_000_000)
            isWatchUnlocked = true
            persistPurchaseState()
            purchaseInProgress = false
            WatchSyncHelper.shared.updatePurchaseState(isWatchUnlocked: true)
            return true
        }

        guard let product = unlockWatchProduct else {
            purchaseError = "Product not available"
            return false
        }

        purchaseInProgress = true
        purchaseError = nil

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    isWatchUnlocked = true
                    persistPurchaseState()
                    await transaction.finish()
                    purchaseInProgress = false
                    WatchSyncHelper.shared.updatePurchaseState(isWatchUnlocked: true)
                    return true
                } else {
                    purchaseError = "Verification failed"
                    purchaseInProgress = false
                    return false
                }

            case .userCancelled:
                purchaseInProgress = false
                return false

            case .pending:
                purchaseError = "Purchase pending"
                purchaseInProgress = false
                return false

            @unknown default:
                purchaseError = "Unknown error"
                purchaseInProgress = false
                return false
            }
        } catch {
            purchaseError = "Purchase failed"
            purchaseInProgress = false
            return false
        }
    }

    // MARK: - Restore Purchases

    func restorePurchases() async -> Bool {
        isLoading = true
        purchaseError = nil

        defer { isLoading = false }

        do {
            try await AppStore.sync()
            await checkEntitlements()
            return isWatchUnlocked
        } catch {
            purchaseError = "Restore failed"
            return false
        }
    }

    // MARK: - Set Unlocked from iPhone

    /// Called when iPhone notifies Watch of purchase
    func setUnlockedFromiPhone() {
        isWatchUnlocked = true
        persistPurchaseState()
    }

    // MARK: - Transaction Listener

    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await self.handleVerifiedTransaction(transaction)
                    await transaction.finish()
                }
            }
        }
    }

    private func handleVerifiedTransaction(_ transaction: Transaction) async {
        if transaction.productID == WatchStoreManager.unlockWatchProductId {
            await MainActor.run {
                self.isWatchUnlocked = true
                self.persistPurchaseState()
                WatchSyncHelper.shared.updatePurchaseState(isWatchUnlocked: true)
            }
        }
    }

    // MARK: - Persistence

    private func persistPurchaseState() {
        UserDefaults.standard.set(isWatchUnlocked, forKey: purchaseStateKey)
    }

    // MARK: - Formatted Price

    var formattedPrice: String {
        unlockWatchProduct?.displayPrice ?? "$0.99"
    }
}
