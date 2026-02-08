//
//  WatchPaywallView.swift
//  SpellFlare Watch App
//
//  Paywall shown when trying to access premium levels (6+) without purchase.
//  Supports direct purchase on Watch via StoreKit 2.
//

import SwiftUI

struct WatchPaywallView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var storeManager = WatchStoreManager.shared
    @EnvironmentObject var syncHelper: WatchSyncHelper

    @State private var showingSuccess = false

    var body: some View {
        GeometryReader { geometry in
            let isSmallWatch = geometry.size.height < 180
            let isLargeWatch = geometry.size.height > 220
            let lockSize: CGFloat = isSmallWatch ? 30 : (isLargeWatch ? 50 : 40)
            let titleFont: CGFloat = isSmallWatch ? 13 : (isLargeWatch ? 18 : 15)
            let messageFont: CGFloat = isSmallWatch ? 10 : (isLargeWatch ? 13 : 12)
            let buttonFont: CGFloat = isSmallWatch ? 13 : (isLargeWatch ? 17 : 15)

            ScrollView {
                VStack(spacing: isSmallWatch ? 10 : 16) {
                    // Already unlocked state
                    if syncHelper.isWatchUnlocked || storeManager.isWatchUnlocked {
                        unlockedContent(
                            isSmallWatch: isSmallWatch,
                            lockSize: lockSize,
                            titleFont: titleFont,
                            messageFont: messageFont,
                            buttonFont: buttonFont
                        )
                    } else {
                        // Locked state - show purchase UI
                        lockedContent(
                            isSmallWatch: isSmallWatch,
                            isLargeWatch: isLargeWatch,
                            lockSize: lockSize,
                            titleFont: titleFont,
                            messageFont: messageFont,
                            buttonFont: buttonFont
                        )
                    }
                }
                .padding(isSmallWatch ? 8 : 12)
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
    }

    // MARK: - Unlocked Content

    @ViewBuilder
    private func unlockedContent(
        isSmallWatch: Bool,
        lockSize: CGFloat,
        titleFont: CGFloat,
        messageFont: CGFloat,
        buttonFont: CGFloat
    ) -> some View {
        Image(systemName: "checkmark.seal.fill")
            .font(.system(size: lockSize))
            .foregroundColor(.green)

        Text("All Levels Unlocked!")
            .font(.system(size: titleFont, weight: .semibold))
            .foregroundColor(.white)
            .multilineTextAlignment(.center)

        Text("Enjoy all 50 levels")
            .font(.system(size: messageFont))
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)

        Spacer()
            .frame(height: isSmallWatch ? 8 : 16)

        Button {
            dismiss()
        } label: {
            Text("Continue")
                .font(.system(size: buttonFont, weight: .semibold))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, isSmallWatch ? 8 : 10)
                .background(Color.green)
                .cornerRadius(isSmallWatch ? 8 : 10)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Locked Content

    @ViewBuilder
    private func lockedContent(
        isSmallWatch: Bool,
        isLargeWatch: Bool,
        lockSize: CGFloat,
        titleFont: CGFloat,
        messageFont: CGFloat,
        buttonFont: CGFloat
    ) -> some View {
        // Lock icon
        Image(systemName: "lock.fill")
            .font(.system(size: lockSize))
            .foregroundColor(.yellow)

        // Title
        Text("Unlock All Levels")
            .font(.system(size: titleFont, weight: .semibold))
            .foregroundColor(.white)
            .multilineTextAlignment(.center)

        // Message with price
        Text("Access levels 6-50 for just \(storeManager.formattedPrice)")
            .font(.system(size: messageFont))
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, isSmallWatch ? 4 : 8)

        // Error message
        if let error = storeManager.purchaseError {
            Text(error)
                .font(.system(size: isSmallWatch ? 9 : 10))
                .foregroundColor(.red)
                .multilineTextAlignment(.center)
        }

        Spacer()
            .frame(height: isSmallWatch ? 6 : 12)

        // Buy Now button
        Button {
            Task {
                let success = await storeManager.purchaseUnlockWatch()
                if success {
                    dismiss()
                }
            }
        } label: {
            HStack(spacing: 6) {
                if storeManager.purchaseInProgress {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .black))
                        .scaleEffect(isSmallWatch ? 0.6 : 0.8)
                } else {
                    Text("Buy Now")
                }
                if !storeManager.purchaseInProgress {
                    Text(storeManager.formattedPrice)
                        .opacity(0.8)
                }
            }
            .font(.system(size: buttonFont, weight: .semibold))
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, isSmallWatch ? 8 : 10)
            .background(Color.cyan)
            .cornerRadius(isSmallWatch ? 8 : 10)
        }
        .buttonStyle(.plain)
        .disabled(storeManager.purchaseInProgress || storeManager.isLoading)

        // Restore button
        Button {
            Task {
                let success = await storeManager.restorePurchases()
                if success {
                    dismiss()
                }
            }
        } label: {
            Text("Restore Purchase")
                .font(.system(size: isSmallWatch ? 11 : 13))
                .foregroundColor(.cyan)
        }
        .buttonStyle(.plain)
        .disabled(storeManager.purchaseInProgress || storeManager.isLoading)
        .padding(.top, isSmallWatch ? 4 : 8)

        // Dismiss button
        Button {
            dismiss()
        } label: {
            Text("Not Now")
                .font(.system(size: isSmallWatch ? 10 : 12))
                .foregroundColor(.white.opacity(0.6))
        }
        .buttonStyle(.plain)
        .padding(.top, isSmallWatch ? 2 : 4)
    }
}

#Preview {
    WatchPaywallView()
        .environmentObject(WatchSyncHelper.shared)
}
