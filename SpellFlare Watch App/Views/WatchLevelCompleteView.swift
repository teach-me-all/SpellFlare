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

    let level: Int
    let score: Int
    let coinsEarned: Int
    let didPass: Bool

    @State private var showConfetti = false

    var body: some View {
        VStack(spacing: 12) {
            // Celebration icon (only show for pass)
            if didPass {
                ZStack {
                    // Stars animation
                    ForEach(0..<5, id: \.self) { index in
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                            .offset(
                                x: showConfetti ? CGFloat.random(in: -40...40) : 0,
                                y: showConfetti ? CGFloat.random(in: -30...30) : 0
                            )
                            .opacity(showConfetti ? 1 : 0)
                            .animation(
                                .easeOut(duration: 0.8).delay(Double(index) * 0.1),
                                value: showConfetti
                            )
                    }

                    Image(systemName: "trophy.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.yellow)
                }
            } else {
                // Sad face for fail
                Text("😢")
                    .font(.system(size: 40))
            }

            // Title
            Text("Level \(level)")
                .font(.headline)
                .foregroundColor(didPass ? .cyan : .orange)

            if didPass {
                Text("Complete!")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                // Coins earned
                WatchCoinsEarnedView(amount: coinsEarned)
            } else {
                Text("Not Passed")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.orange)

                Text("Too many give ups.\nTry again!")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }

            Spacer()
                .frame(height: 8)

            // Action buttons - side by side
            HStack(spacing: 8) {
                // Home button
                Button {
                    appState.navigateToHome()
                } label: {
                    HStack(spacing: 2) {
                        Image(systemName: "house.fill")
                            .font(.system(size: 10))
                        Text("Home")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)

                if didPass {
                    // Next Level button (only if passed)
                    Button {
                        appState.startNextLevel(after: level)
                    } label: {
                        HStack(spacing: 2) {
                            Text("Next")
                                .font(.system(size: 12, weight: .medium))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 10))
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.cyan)
                        .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                } else {
                    // Try Again button (if failed)
                    Button {
                        appState.startGame(level: level)
                    } label: {
                        HStack(spacing: 2) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 10))
                            Text("Try Again")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.cyan)
                        .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding()
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
