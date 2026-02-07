//
//  WatchPaywallView.swift
//  SpellFlare Watch App
//
//  Paywall shown when trying to access premium levels (6+) without purchase.
//

import SwiftUI

struct WatchPaywallView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        GeometryReader { geometry in
            let isSmallWatch = geometry.size.height < 180
            let isLargeWatch = geometry.size.height > 220
            let lockSize: CGFloat = isSmallWatch ? 30 : (isLargeWatch ? 50 : 40)
            let titleFont: CGFloat = isSmallWatch ? 13 : (isLargeWatch ? 18 : 15)
            let messageFont: CGFloat = isSmallWatch ? 10 : (isLargeWatch ? 13 : 12)
            let stepFont: CGFloat = isSmallWatch ? 9 : (isLargeWatch ? 12 : 10)
            let buttonFont: CGFloat = isSmallWatch ? 13 : (isLargeWatch ? 17 : 15)

            ScrollView {
                VStack(spacing: isSmallWatch ? 10 : 16) {
                    // Lock icon
                    Image(systemName: "lock.fill")
                        .font(.system(size: lockSize))
                        .foregroundColor(.yellow)

                    // Title
                    Text("Unlock All Levels")
                        .font(.system(size: titleFont, weight: .semibold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    // Message
                    Text("Purchase \"Unlock Watch\" on iPhone to access levels 6-50")
                        .font(.system(size: messageFont))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, isSmallWatch ? 4 : 8)

                    Spacer()
                        .frame(height: isSmallWatch ? 4 : 8)

                    // Instructions
                    VStack(alignment: .leading, spacing: isSmallWatch ? 4 : 8) {
                        HStack(spacing: isSmallWatch ? 4 : 8) {
                            Image(systemName: "1.circle.fill")
                                .font(.system(size: isSmallWatch ? 12 : 14))
                                .foregroundColor(.cyan)
                            Text("Open SpellFlare on iPhone")
                                .font(.system(size: stepFont))
                        }

                        HStack(spacing: isSmallWatch ? 4 : 8) {
                            Image(systemName: "2.circle.fill")
                                .font(.system(size: isSmallWatch ? 12 : 14))
                                .foregroundColor(.cyan)
                            Text("Go to Settings")
                                .font(.system(size: stepFont))
                        }

                        HStack(spacing: isSmallWatch ? 4 : 8) {
                            Image(systemName: "3.circle.fill")
                                .font(.system(size: isSmallWatch ? 12 : 14))
                                .foregroundColor(.cyan)
                            Text("Tap \"Unlock Watch Levels\"")
                                .font(.system(size: stepFont))
                        }
                    }
                    .foregroundColor(.white.opacity(0.8))

                    Spacer()
                        .frame(height: isSmallWatch ? 6 : 12)

                    // OK button
                    Button {
                        dismiss()
                    } label: {
                        Text("OK")
                            .font(.system(size: buttonFont, weight: .semibold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, isSmallWatch ? 8 : 10)
                            .background(Color.cyan)
                            .cornerRadius(isSmallWatch ? 8 : 10)
                    }
                    .buttonStyle(.plain)
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
}

#Preview {
    WatchPaywallView()
}
