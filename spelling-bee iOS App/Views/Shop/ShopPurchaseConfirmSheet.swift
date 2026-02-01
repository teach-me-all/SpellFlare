//
//  ShopPurchaseConfirmSheet.swift
//  spelling-bee iOS App
//
//  Purchase confirmation sheet with animation.
//

import SwiftUI

struct ShopPurchaseConfirmSheet: View {
    let item: ShopItemDefinition
    let currentCoins: Int
    let onPurchase: () -> Void

    @Environment(\.dismiss) var dismiss
    @State private var iconScale: CGFloat = 0.5
    @State private var showDetails = false

    var body: some View {
        VStack(spacing: 24) {
            // Item preview
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.cyan.opacity(0.3), .purple.opacity(0.1)],
                            center: .center,
                            startRadius: 0,
                            endRadius: 60
                        )
                    )
                    .frame(width: 100, height: 100)

                Image(systemName: ThemeService.shopIcon(for: item.id))
                    .font(.system(size: 40))
                    .foregroundColor(.cyan)
            }
            .scaleEffect(iconScale)
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                    iconScale = 1.0
                }
                withAnimation(.easeIn(duration: 0.3).delay(0.2)) {
                    showDetails = true
                }
            }

            // Item info
            VStack(spacing: 8) {
                Text(item.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                Text(item.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .opacity(showDetails ? 1 : 0)

            // Price breakdown
            VStack(spacing: 12) {
                HStack {
                    Text("Price")
                        .foregroundColor(.secondary)
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "bitcoinsign.circle.fill")
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.yellow, .orange],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        Text("\(item.price)")
                            .fontWeight(.bold)
                    }
                }

                Divider()

                HStack {
                    Text("Your Balance")
                        .foregroundColor(.secondary)
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "bitcoinsign.circle.fill")
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.yellow, .orange],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        Text("\(currentCoins)")
                            .fontWeight(.bold)
                    }
                }

                HStack {
                    Text("After Purchase")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(currentCoins - item.price)")
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .opacity(showDetails ? 1 : 0)

            Spacer()

            // Buttons
            VStack(spacing: 12) {
                Button {
                    onPurchase()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "cart.fill")
                        Text("Buy for \(item.price) coins")
                            .fontWeight(.bold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [.purple, .cyan],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(14)
                }

                Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(.secondary)
            }
            .opacity(showDetails ? 1 : 0)
        }
        .padding(24)
        .presentationDetents([.medium])
    }
}
