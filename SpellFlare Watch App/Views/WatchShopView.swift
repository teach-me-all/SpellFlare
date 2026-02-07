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
        GeometryReader { geometry in
            let isSmallWatch = geometry.size.height < 180
            let isLargeWatch = geometry.size.height > 220
            let headerFont: CGFloat = isSmallWatch ? 13 : (isLargeWatch ? 18 : 15)
            let sectionFont: CGFloat = isSmallWatch ? 11 : (isLargeWatch ? 15 : 13)

            ScrollView {
                VStack(alignment: .leading, spacing: isSmallWatch ? 8 : 12) {
                    // Header with back button
                    HStack {
                        Button {
                            appState.currentScreen = .home
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: headerFont, weight: .semibold))
                                .foregroundColor(.cyan)
                        }
                        .buttonStyle(.plain)

                        Spacer()

                        Text("Shop")
                            .font(.system(size: headerFont, weight: .semibold))
                            .foregroundColor(.white)

                        Spacer()

                        // Balance spacer
                        Image(systemName: "chevron.left")
                            .font(.system(size: headerFont, weight: .semibold))
                            .foregroundColor(.clear)
                    }
                    .padding(.horizontal, isSmallWatch ? 6 : 8)

                    // Coins display
                    HStack {
                        Spacer()
                        WatchCoinsDisplayView(coins: syncHelper.profile?.totalCoins ?? 0, compact: isSmallWatch)
                        Spacer()
                    }
                    .padding(.bottom, isSmallWatch ? 2 : 4)

                    // Sections
                    ForEach(ShopCategory.allCases, id: \.self) { category in
                        Text(category.rawValue)
                            .font(.system(size: sectionFont, weight: .bold))
                            .foregroundColor(.cyan)
                            .padding(.horizontal, isSmallWatch ? 6 : 8)
                            .padding(.top, category == .beeSkin ? 0 : (isSmallWatch ? 4 : 8))

                        ForEach(ShopItemDefinitions.definitions(for: category)) { item in
                            shopItemRow(item, isSmallWatch: isSmallWatch, isLargeWatch: isLargeWatch)
                        }
                    }
                }
                .padding(.vertical, isSmallWatch ? 4 : 8)
            }
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
        .toolbar(.hidden, for: .navigationBar)
        .alert("Not Enough Coins", isPresented: $showInsufficientAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Keep spelling to earn more coins for \(insufficientItemName)!")
        }
    }

    @ViewBuilder
    private func shopItemRow(_ item: ShopItemDefinition, isSmallWatch: Bool, isLargeWatch: Bool) -> some View {
        let shopState = syncHelper.profile?.shopState ?? ShopState()
        let isOwned = shopState.isOwned(item.id)
        let isEquipped = shopState.equippedItem(for: item.category) == item.id
        let canAfford = (syncHelper.profile?.totalCoins ?? 0) >= item.price

        let iconSize: CGFloat = isSmallWatch ? 12 : (isLargeWatch ? 18 : 14)
        let iconFrameSize: CGFloat = isSmallWatch ? 20 : (isLargeWatch ? 30 : 24)
        let titleFont: CGFloat = isSmallWatch ? 10 : (isLargeWatch ? 14 : 12)
        let descFont: CGFloat = isSmallWatch ? 8 : (isLargeWatch ? 11 : 9)
        let statusFont: CGFloat = isSmallWatch ? 9 : (isLargeWatch ? 12 : 10)

        Button {
            handleTap(item, isOwned: isOwned, canAfford: canAfford)
        } label: {
            HStack(spacing: isSmallWatch ? 6 : 8) {
                // Icon
                Image(systemName: ThemeService.shopIcon(for: item.id))
                    .font(.system(size: iconSize))
                    .foregroundColor(isEquipped ? .cyan : (isOwned ? .white : .yellow))
                    .frame(width: iconFrameSize, height: iconFrameSize)

                // Title
                VStack(alignment: .leading, spacing: 1) {
                    Text(item.title)
                        .font(.system(size: titleFont, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    Text(item.description)
                        .font(.system(size: descFont))
                        .foregroundColor(.white.opacity(0.5))
                        .lineLimit(1)
                }

                Spacer()

                // Status
                if isEquipped {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: iconSize))
                        .foregroundColor(.cyan)
                } else if isOwned {
                    Text("Equip")
                        .font(.system(size: statusFont, weight: .semibold))
                        .foregroundColor(.white.opacity(0.7))
                } else if item.price == 0 {
                    Text("Free")
                        .font(.system(size: statusFont, weight: .semibold))
                        .foregroundColor(.green)
                } else {
                    HStack(spacing: 2) {
                        Image(systemName: "bitcoinsign.circle.fill")
                            .font(.system(size: isSmallWatch ? 9 : (isLargeWatch ? 12 : 10)))
                            .foregroundColor(.yellow)
                        Text("\(item.price)")
                            .font(.system(size: isSmallWatch ? 10 : (isLargeWatch ? 13 : 11), weight: .bold))
                            .foregroundColor(canAfford ? .yellow : .white.opacity(0.4))
                    }
                }
            }
            .padding(.horizontal, isSmallWatch ? 6 : 8)
            .padding(.vertical, isSmallWatch ? 4 : 6)
            .background(
                RoundedRectangle(cornerRadius: isSmallWatch ? 6 : 8)
                    .fill(isEquipped ? Color.white.opacity(0.15) : Color.white.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: isSmallWatch ? 6 : 8)
                    .stroke(isEquipped ? Color.cyan.opacity(0.5) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, isSmallWatch ? 6 : 8)
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
