//
//  AdManager.swift
//  spelling-bee iOS App
//
//  Manages advertisement display logic for kids app compliance.
//  Ads are ONLY shown after test completion, never during gameplay.
//  Uses non-personalized ads only - no tracking or profiling.
//

import Foundation
import SwiftUI

@MainActor
class AdManager: ObservableObject {
    static let shared = AdManager()

    // MARK: - Published State
    @Published var shouldShowAd: Bool = false
    @Published var isAdLoaded: Bool = false
    @Published var isShowingAd: Bool = false

    // MARK: - Private Properties
    private var testsCompletedSinceLastAd: Int = 0
    private let testsBeforeAd: Int = 1  // Show ad after every completed test
    private var hasShownAdThisSession: Bool = false

    // MARK: - Dependencies
    private var storeManager: StoreManager { StoreManager.shared }

    // MARK: - Ad Display Logic

    /// Call this when a test is completed to determine if an ad should be shown
    func onTestCompleted() {
        // Don't show ads if user purchased "Remove Ads"
        guard !storeManager.isAdsRemoved else {
            shouldShowAd = false
            return
        }

        testsCompletedSinceLastAd += 1

        // Show ad after completing required number of tests
        if testsCompletedSinceLastAd >= testsBeforeAd {
            shouldShowAd = true
            testsCompletedSinceLastAd = 0
        }
    }

    /// Call this when the ad has been shown or dismissed
    func onAdDismissed() {
        shouldShowAd = false
        isShowingAd = false
        hasShownAdThisSession = true
    }

    /// Call this to skip showing the ad (e.g., if ad failed to load)
    func skipAd() {
        shouldShowAd = false
        isShowingAd = false
    }

    /// Check if ads should be shown (respects purchase state)
    var adsEnabled: Bool {
        !storeManager.isAdsRemoved
    }

    // MARK: - Placeholder Ad Content
    // In production, replace with actual ad SDK (e.g., Google AdMob with child-directed treatment)

    /// Simulates loading an ad
    func loadAd() async {
        // Simulate ad loading delay
        try? await Task.sleep(nanoseconds: 500_000_000)
        isAdLoaded = true
    }

    /// Prepares for showing an ad
    func prepareToShowAd() {
        guard shouldShowAd && !storeManager.isAdsRemoved else { return }
        isShowingAd = true
    }
}

// MARK: - Placeholder Ad View (Replace with actual ad SDK)
struct PlaceholderAdView: View {
    @ObservedObject var adManager = AdManager.shared
    @ObservedObject var storeManager = StoreManager.shared
    let onDismiss: () -> Void

    @State private var countdown: Int = 5
    @State private var canSkip: Bool = false

    var body: some View {
        ZStack {
            // Background
            Color.black.opacity(0.9)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer()

                // Ad label
                Text("Advertisement")
                    .font(.caption)
                    .foregroundColor(.gray)

                // Placeholder ad content
                VStack(spacing: 16) {
                    Text("🐝")
                        .font(.system(size: 60))

                    Text("SpellFlare")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Text("Keep practicing to become a spelling champion!")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .padding(30)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.4, green: 0.2, blue: 0.9),
                                    Color(red: 0.5, green: 0.3, blue: 0.95)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .padding(.horizontal, 20)

                Spacer()

                // Skip/Close button
                if canSkip {
                    Button {
                        adManager.onAdDismissed()
                        onDismiss()
                    } label: {
                        Text("Continue")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.cyan)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 40)
                } else {
                    Text("Continue in \(countdown)...")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }

                // Remove Ads option (behind parent gate in actual implementation)
                if storeManager.removeAdsProduct != nil {
                    Text("Parents: Remove ads for \(storeManager.formattedPrice)")
                        .font(.caption)
                        .foregroundColor(.gray.opacity(0.7))
                        .padding(.bottom, 20)
                }
            }
        }
        .onAppear {
            startCountdown()
        }
    }

    private func startCountdown() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if countdown > 1 {
                countdown -= 1
            } else {
                timer.invalidate()
                canSkip = true
            }
        }
    }
}

// MARK: - Pre-Test Ad View (Shown before test starts)
struct PreTestAdView: View {
    @ObservedObject var storeManager = StoreManager.shared
    let level: Int
    let onDismiss: () -> Void

    @State private var countdown: Int = 5
    @State private var canStart: Bool = false

    var body: some View {
        ZStack {
            // Purple gradient background matching the game
            LinearGradient(
                colors: [
                    Color(red: 0.3, green: 0.1, blue: 0.7),
                    Color(red: 0.4, green: 0.2, blue: 0.8)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                // Ad label
                Text("Advertisement")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))

                // Ad content card
                VStack(spacing: 20) {
                    // Bee mascot
                    Text("🐝")
                        .font(.system(size: 70))

                    Text("Get Ready!")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Text("Level \(level) is about to begin")
                        .font(.headline)
                        .foregroundColor(.cyan)

                    Text("Practice makes perfect!\nListen carefully and spell each word.")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                .padding(30)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.white.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 24)

                Spacer()

                // Start button or countdown
                VStack(spacing: 16) {
                    if canStart {
                        Button {
                            onDismiss()
                        } label: {
                            HStack {
                                Image(systemName: "play.fill")
                                Text("Start Test")
                            }
                            .font(.headline)
                            .foregroundColor(.purple)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal, 40)
                    } else {
                        // Countdown circle
                        ZStack {
                            Circle()
                                .stroke(Color.white.opacity(0.2), lineWidth: 4)
                                .frame(width: 60, height: 60)

                            Circle()
                                .trim(from: 0, to: CGFloat(countdown) / 5.0)
                                .stroke(Color.cyan, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                                .frame(width: 60, height: 60)
                                .rotationEffect(.degrees(-90))
                                .animation(.linear(duration: 1), value: countdown)

                            Text("\(countdown)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }

                        Text("Starting soon...")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.6))
                    }

                    // Remove Ads hint
                    if storeManager.removeAdsProduct != nil {
                        Text("Parents: Remove ads in Settings")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.4))
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            startCountdown()
        }
    }

    private func startCountdown() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if countdown > 1 {
                countdown -= 1
            } else {
                timer.invalidate()
                canStart = true
            }
        }
    }
}
