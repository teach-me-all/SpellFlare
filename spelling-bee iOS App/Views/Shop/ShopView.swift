//
//  ShopView.swift
//  spelling-bee iOS App
//
//  Tab-based grid shop screen for purchasing cosmetic items with coins.
//

import SwiftUI

struct ShopView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedCategory: ShopCategory = .beeSkin
    @State private var purchaseItem: ShopItemDefinition?
    @State private var showPurchaseSheet = false
    @State private var showInsufficientCoins = false
    @State private var lastPurchasedItem: String?

    var profile: UserProfile? {
        appState.profile
    }

    var body: some View {
        ZStack {
            // Purple gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.35, green: 0.15, blue: 0.85),
                    Color(red: 0.45, green: 0.25, blue: 0.9),
                    Color(red: 0.4, green: 0.2, blue: 0.8)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Button {
                        appState.navigateToHome()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(Circle().fill(Color.white.opacity(0.2)))
                    }

                    Spacer()

                    Text("Coin Shop")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Spacer()

                    CoinsDisplayView(coins: profile?.totalCoins ?? 0)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)

                // Category tabs
                Picker("Category", selection: $selectedCategory) {
                    ForEach(ShopCategory.allCases, id: \.self) { category in
                        Text(category.rawValue).tag(category)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 20)
                .padding(.bottom, 16)

                // Items grid
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 16),
                        GridItem(.flexible(), spacing: 16)
                    ], spacing: 16) {
                        ForEach(ShopItemDefinitions.definitions(for: selectedCategory)) { item in
                            ShopItemCard(
                                item: item,
                                shopState: profile?.shopState ?? ShopState(),
                                totalCoins: profile?.totalCoins ?? 0,
                                isNewlyPurchased: lastPurchasedItem == item.id
                            ) {
                                handleItemTap(item)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
            }
        }
        .sheet(isPresented: $showPurchaseSheet) {
            if let item = purchaseItem {
                ShopPurchaseConfirmSheet(
                    item: item,
                    currentCoins: profile?.totalCoins ?? 0
                ) {
                    let result = appState.purchaseShopItem(item.id)
                    if result == .success {
                        lastPurchasedItem = item.id
                        // Clear highlight after delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            lastPurchasedItem = nil
                        }
                    }
                    showPurchaseSheet = false
                }
            }
        }
        .alert("Not Enough Coins", isPresented: $showInsufficientCoins) {
            Button("OK", role: .cancel) {}
        } message: {
            if let item = purchaseItem {
                Text("You need \(item.price) coins but only have \(profile?.totalCoins ?? 0). Keep spelling to earn more!")
            }
        }
    }

    private func handleItemTap(_ item: ShopItemDefinition) {
        let shopState = profile?.shopState ?? ShopState()

        if shopState.isOwned(item.id) {
            // Already owned - equip it
            _ = appState.equipShopItem(item.id)
        } else {
            // Not owned - try to purchase
            if (profile?.totalCoins ?? 0) >= item.price {
                purchaseItem = item
                showPurchaseSheet = true
            } else {
                purchaseItem = item
                showInsufficientCoins = true
            }
        }
    }
}

#Preview {
    ShopView()
        .environmentObject(AppState())
}
