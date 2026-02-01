//
//  WatchShopView.swift
//  SpellFlare Watch App
//
//  List-based shop screen for Apple Watch.
//

import SwiftUI

struct WatchShopView: View {
    @EnvironmentObject var appState: WatchAppState
    @EnvironmentObject var syncHelper: WatchSyncHelper

    @State private var showInsufficientAlert = false
    @State private var insufficientItemName = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                // Coins display
                HStack {
                    Spacer()
                    WatchCoinsDisplayView(coins: syncHelper.profile?.totalCoins ?? 0, compact: false)
                    Spacer()
                }
                .padding(.bottom, 4)

                // Sections
                ForEach(ShopCategory.allCases, id: \.self) { category in
                    Text(category.rawValue)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.cyan)
                        .padding(.horizontal, 8)
                        .padding(.top, category == .beeSkin ? 0 : 8)

                    ForEach(ShopItemDefinitions.definitions(for: category)) { item in
                        shopItemRow(item)
                    }
                }
            }
            .padding(.vertical, 8)
        }
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.4, green: 0.2, blue: 0.9),
                    Color(red: 0.3, green: 0.15, blue: 0.7)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .navigationTitle("Shop")
        .alert("Not Enough Coins", isPresented: $showInsufficientAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Keep spelling to earn more coins for \(insufficientItemName)!")
        }
    }

    @ViewBuilder
    private func shopItemRow(_ item: ShopItemDefinition) -> some View {
        let shopState = syncHelper.profile?.shopState ?? ShopState()
        let isOwned = shopState.isOwned(item.id)
        let isEquipped = shopState.equippedItem(for: item.category) == item.id
        let canAfford = (syncHelper.profile?.totalCoins ?? 0) >= item.price

        Button {
            handleTap(item, isOwned: isOwned, canAfford: canAfford)
        } label: {
            HStack(spacing: 8) {
                // Icon
                Image(systemName: ThemeService.shopIcon(for: item.id))
                    .font(.system(size: 14))
                    .foregroundColor(isEquipped ? .cyan : (isOwned ? .white : .yellow))
                    .frame(width: 24, height: 24)

                // Title
                VStack(alignment: .leading, spacing: 1) {
                    Text(item.title)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    Text(item.description)
                        .font(.system(size: 9))
                        .foregroundColor(.white.opacity(0.5))
                        .lineLimit(1)
                }

                Spacer()

                // Status
                if isEquipped {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.cyan)
                } else if isOwned {
                    Text("Equip")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white.opacity(0.7))
                } else if item.price == 0 {
                    Text("Free")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.green)
                } else {
                    HStack(spacing: 2) {
                        Image(systemName: "bitcoinsign.circle.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.yellow)
                        Text("\(item.price)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(canAfford ? .yellow : .white.opacity(0.4))
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isEquipped ? Color.white.opacity(0.15) : Color.white.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isEquipped ? Color.cyan.opacity(0.5) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 8)
        .opacity((!isOwned && !canAfford && item.price > 0) ? 0.5 : 1.0)
    }

    private func handleTap(_ item: ShopItemDefinition, isOwned: Bool, canAfford: Bool) {
        guard var profile = syncHelper.profile else { return }

        if isOwned {
            _ = ShopService.shared.equipItem(item.id, profile: &profile)
            saveAndSync(profile)
        } else if canAfford {
            let result = ShopService.shared.purchaseItem(item.id, profile: &profile)
            if result == .success {
                saveAndSync(profile)
            }
        } else {
            insufficientItemName = item.title
            showInsufficientAlert = true
        }
    }

    private func saveAndSync(_ profile: UserProfile) {
        syncHelper.profile = profile
        let syncable = SyncableProfile(profile: profile, deviceIdentifier: DeviceIdentifier.current, isWatchUnlocked: syncHelper.isWatchUnlocked)
        LocalCacheService.shared.saveSyncableProfile(syncable)
        syncHelper.hasPendingChanges = true
        syncHelper.retryPendingSync()
    }
}

#Preview {
    WatchShopView()
        .environmentObject(WatchAppState())
        .environmentObject(WatchSyncHelper.shared)
}
