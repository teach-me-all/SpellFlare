//
//  WatchLevelCompleteView.swift
//  SpellFlare Watch App
//
//  Level completion celebration screen.
//

import SwiftUI
import WatchKit

struct WatchLevelCompleteView: View {
    @EnvironmentObject var appState: WatchAppState
    @ObservedObject var syncHelper = WatchSyncHelper.shared

    let level: Int
    let score: Int
    let coinsEarned: Int
    let didPass: Bool

    @State private var showConfetti = false
    @State private var showShareAlert = false

    var body: some View {
        GeometryReader { geometry in
            let isSmallWatch = geometry.size.height < 180
            let isLargeWatch = geometry.size.height > 220
            let trophySize: CGFloat = isSmallWatch ? 30 : (isLargeWatch ? 50 : 40)
            let titleFont: CGFloat = isSmallWatch ? 13 : (isLargeWatch ? 18 : 15)
            let subtitleFont: CGFloat = isSmallWatch ? 14 : (isLargeWatch ? 20 : 17)
            let buttonFont: CGFloat = isSmallWatch ? 10 : (isLargeWatch ? 14 : 12)
            let buttonIconSize: CGFloat = isSmallWatch ? 8 : (isLargeWatch ? 12 : 10)
            let buttonPadding: CGFloat = isSmallWatch ? 8 : (isLargeWatch ? 12 : 10)

            VStack(spacing: isSmallWatch ? 8 : 12) {
                // Celebration icon (only show for pass)
                if didPass {
                    ZStack {
                        // Stars animation
                        ForEach(0..<5, id: \.self) { index in
                            Image(systemName: "star.fill")
                                .font(.system(size: isSmallWatch ? 8 : 12))
                                .foregroundColor(.yellow)
                                .offset(
                                    x: showConfetti ? CGFloat.random(in: isSmallWatch ? -30...30 : -40...40) : 0,
                                    y: showConfetti ? CGFloat.random(in: isSmallWatch ? -20...20 : -30...30) : 0
                                )
                                .opacity(showConfetti ? 1 : 0)
                                .animation(
                                    .easeOut(duration: 0.8).delay(Double(index) * 0.1),
                                    value: showConfetti
                                )
                        }

                        Image(systemName: "trophy.fill")
                            .font(.system(size: trophySize))
                            .foregroundColor(.yellow)
                    }
                } else {
                    // Sad face for fail
                    Text("😢")
                        .font(.system(size: trophySize))
                }

                // Title
                Text("Level \(level)")
                    .font(.system(size: titleFont, weight: .semibold))
                    .foregroundColor(didPass ? .cyan : .orange)

                if didPass {
                    Text("Complete!")
                        .font(.system(size: subtitleFont, weight: .bold))
                        .foregroundColor(.white)

                    // Coins earned
                    WatchCoinsEarnedView(amount: coinsEarned)
                } else {
                    Text("Not Passed")
                        .font(.system(size: subtitleFont, weight: .bold))
                        .foregroundColor(.orange)

                    Text("Too many give ups.\nTry again!")
                        .font(.system(size: isSmallWatch ? 9 : (isLargeWatch ? 12 : 10)))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }

                Spacer()
                    .frame(height: isSmallWatch ? 4 : 8)

                // Action buttons - side by side
                HStack(spacing: isSmallWatch ? 6 : 8) {
                    // Home button
                    Button {
                        appState.navigateToHome()
                    } label: {
                        HStack(spacing: 2) {
                            Image(systemName: "house.fill")
                                .font(.system(size: buttonIconSize))
                            Text("Home")
                                .font(.system(size: buttonFont, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, buttonPadding)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(isSmallWatch ? 8 : 10)
                    }
                    .buttonStyle(.plain)

                    // Share button (only if passed)
                    if didPass {
                        Button {
                            if syncHelper.isPhoneReachable {
                                syncHelper.sendShareRequest(
                                    type: "level",
                                    level: level,
                                    grade: syncHelper.profile?.grade ?? 1,
                                    coinsEarned: coinsEarned
                                )
                            } else {
                                showShareAlert = true
                            }
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: buttonIconSize + 2, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: isSmallWatch ? 32 : 38, height: isSmallWatch ? 32 : 38)
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(isSmallWatch ? 8 : 10)
                        }
                        .buttonStyle(.plain)
                    }

                    if didPass {
                        // Next Level button (only if passed)
                        Button {
                            appState.startNextLevel(after: level)
                        } label: {
                            HStack(spacing: 2) {
                                Text("Next")
                                    .font(.system(size: buttonFont, weight: .medium))
                                Image(systemName: "arrow.right")
                                    .font(.system(size: buttonIconSize))
                            }
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, buttonPadding)
                            .background(Color.cyan)
                            .cornerRadius(isSmallWatch ? 8 : 10)
                        }
                        .buttonStyle(.plain)
                    } else {
                        // Try Again button (if failed)
                        Button {
                            appState.startGame(level: level)
                        } label: {
                            HStack(spacing: 2) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: buttonIconSize))
                                Text("Retry")
                                    .font(.system(size: buttonFont, weight: .medium))
                            }
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, buttonPadding)
                            .background(Color.cyan)
                            .cornerRadius(isSmallWatch ? 8 : 10)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(isSmallWatch ? 8 : 12)
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
        .alert("Share on iPhone", isPresented: $showShareAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Open SpellFlare on your iPhone to share!")
        }
        .onAppear {
            if didPass {
                // Play success haptic
                WKInterfaceDevice.current().play(.success)

                // Trigger confetti animation
                withAnimation {
                    showConfetti = true
                }

                // Play celebration audio
                WatchAudioService.shared.playFeedback(.levelComplete)
            } else {
                // Play failure haptic
                WKInterfaceDevice.current().play(.failure)
            }
        }
    }
}

#Preview("Pass") {
    WatchLevelCompleteView(level: 5, score: 8, coinsEarned: 100, didPass: true)
        .environmentObject(WatchAppState())
}

#Preview("Fail") {
    WatchLevelCompleteView(level: 5, score: 4, coinsEarned: 0, didPass: false)
        .environmentObject(WatchAppState())
}
