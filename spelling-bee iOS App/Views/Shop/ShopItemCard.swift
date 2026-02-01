//
//  ShopItemCard.swift
//  spelling-bee iOS App
//
//  Individual item card for the shop grid.
//

import SwiftUI

struct ShopItemCard: View {
    let item: ShopItemDefinition
    let shopState: ShopState
    let totalCoins: Int
    let isNewlyPurchased: Bool
    let onTap: () -> Void

    private var isOwned: Bool { shopState.isOwned(item.id) }
    private var isEquipped: Bool { shopState.equippedItem(for: item.category) == item.id }
    private var canAfford: Bool { totalCoins >= item.price }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 10) {
                // Item icon
                ZStack {
                    Circle()
                        .fill(iconBackground)
                        .frame(width: 56, height: 56)

                    Image(systemName: ThemeService.shopIcon(for: item.id))
                        .font(.system(size: 24))
                        .foregroundColor(iconForeground)
                }
                .scaleEffect(isNewlyPurchased ? 1.15 : 1.0)
                .animation(.spring(response: 0.4, dampingFraction: 0.5), value: isNewlyPurchased)

                // Title
                Text(item.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)

                // Description
                Text(item.description)
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.6))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)

                // Status badge
                statusBadge
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 8)
            .background(cardBackground)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isEquipped ? Color.cyan : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .opacity((!isOwned && !canAfford && item.price > 0) ? 0.6 : 1.0)
    }

    @ViewBuilder
    private var statusBadge: some View {
        if isEquipped {
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 12))
                Text("Equipped")
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundColor(.cyan)
        } else if isOwned {
            Text("Equip")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white.opacity(0.8))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Capsule().fill(Color.white.opacity(0.2)))
        } else if item.price == 0 {
            Text("Free")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.green)
        } else {
            HStack(spacing: 4) {
                Image(systemName: "bitcoinsign.circle.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.yellow, .orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Text("\(item.price)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(canAfford ? .yellow : .white.opacity(0.5))
            }
        }
    }

    private var iconBackground: Color {
        if isEquipped {
            return Color.cyan.opacity(0.3)
        } else if isOwned {
            return Color.white.opacity(0.2)
        } else {
            return Color.white.opacity(0.1)
        }
    }

    private var iconForeground: Color {
        if isEquipped {
            return .cyan
        } else if isOwned {
            return .white
        } else if canAfford {
            return .yellow
        } else {
            return .white.opacity(0.4)
        }
    }

    private var cardBackground: Color {
        if isEquipped {
            return Color.white.opacity(0.15)
        } else if isOwned {
            return Color.white.opacity(0.1)
        } else {
            return Color.white.opacity(0.08)
        }
    }
}
