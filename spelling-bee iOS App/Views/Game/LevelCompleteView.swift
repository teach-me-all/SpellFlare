//
//  LevelCompleteView.swift
//  spelling-bee iOS App
//
//  Celebration screen shown when a level is completed.
//  Shows ads after test completion (if not purchased Remove Ads).
//

import SwiftUI

struct LevelCompleteView: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject var viewModel: GameViewModel
    @ObservedObject var adManager = AdManager.shared
    @ObservedObject var storeManager = StoreManager.shared

    let level: Int

    @State private var showConfetti = false
    @State private var iconScale: CGFloat = 0
    @State private var textOpacity: Double = 0
    @State private var buttonsOpacity: Double = 0
    @State private var showAd = false
    @State private var pendingAction: (() -> Void)?

    var body: some View {
        ZStack {
            // Confetti background (only for pass)
            if viewModel.didPassLevel {
                ConfettiView(isActive: $showConfetti)
            }

            VStack(spacing: 30) {
                Spacer()

                // Icon - Star for pass, Sad face for fail
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: viewModel.didPassLevel ? [.cyan, .white.opacity(0.3)] : [.orange, .white.opacity(0.3)],
                                center: .center,
                                startRadius: 0,
                                endRadius: 80
                            )
                        )
                        .frame(width: 160, height: 160)
                        .scaleEffect(iconScale)

                    Text(viewModel.didPassLevel ? "⭐" : "😢")
                        .font(.system(size: 80))
                        .scaleEffect(iconScale)
                }

                // Result text
                VStack(spacing: 8) {
                    Text("Level \(level)")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    if viewModel.didPassLevel {
                        Text("Complete!")
                            .font(.title)
                            .foregroundColor(.cyan)

                        Text("\(viewModel.correctCount) words spelled correctly!")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.top, 8)

                        // Coins earned animation
                        FloatingCoinsEarnedView(amount: viewModel.coinsEarned)
                            .padding(.top, 12)
                    } else {
                        Text("Not Passed")
                            .font(.title)
                            .foregroundColor(.orange)

                        Text("You gave up on too many words.\nTry again to pass this level!")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.top, 8)
                    }
                }
                .opacity(textOpacity)

                Spacer()

                // Buttons
                HStack(spacing: 12) {
                    Button {
                        handleNavigation {
                            if viewModel.didPassLevel {
                                appState.completeLevelWithCoins(level, coinsEarned: viewModel.coinsEarned)
                            }
                            appState.navigateToHome()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "house.fill")
                                .font(.system(size: 14))
                            Text("Home")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(12)
                    }

                    if viewModel.didPassLevel {
                        // Next level button (only if passed and not last level)
                        if level < 50 {
                            Button {
                                handleNavigation {
                                    appState.completeLevelWithCoins(level, coinsEarned: viewModel.coinsEarned)
                                    appState.navigateToGame(level: level + 1)
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Text("Next")
                                        .font(.headline)
                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 14))
                                }
                                .foregroundColor(.purple)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                            }
                        }
                    } else {
                        // Try Again button (if failed)
                        Button {
                            handleNavigation {
                                appState.navigateToGame(level: level)
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 14))
                                Text("Try Again")
                                    .font(.headline)
                            }
                            .foregroundColor(.purple)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                        }
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
                .opacity(buttonsOpacity)
            }
        }
        .onAppear {
            animateResult()
            // Notify ad manager that test was completed
            adManager.onTestCompleted()
        }
        .fullScreenCover(isPresented: $showAd) {
            PostTestAdView(onDismiss: {
                showAd = false
                // Execute the pending navigation action
                if let action = pendingAction {
                    action()
                    pendingAction = nil
                }
            })
        }
    }

    private func handleNavigation(action: @escaping () -> Void) {
        // Check if we should show an ad before navigating
        if adManager.shouldShowAd && !storeManager.isAdsRemoved {
            pendingAction = action
            showAd = true
        } else {
            // No ad needed, navigate directly
            action()
        }
    }

    private func animateResult() {
        // Icon bounce in
        withAnimation(.spring(response: 0.6, dampingFraction: 0.5).delay(0.2)) {
            iconScale = 1.0
        }

        // Text fade in
        withAnimation(.easeIn(duration: 0.5).delay(0.5)) {
            textOpacity = 1.0
        }

        // Buttons fade in
        withAnimation(.easeIn(duration: 0.5).delay(0.8)) {
            buttonsOpacity = 1.0
        }

        // Confetti (only for pass)
        if viewModel.didPassLevel {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showConfetti = true
            }
        }
    }
}

// MARK: - Confetti View
struct ConfettiView: View {
    @Binding var isActive: Bool
    @State private var particles: [ConfettiParticle] = []

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(particles) { particle in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(particle.color)
                        .frame(width: particle.size.width, height: particle.size.height)
                        .position(particle.position)
                        .rotationEffect(.degrees(particle.rotation))
                        .opacity(particle.opacity)
                }
            }
            .onChange(of: isActive) { active in
                if active {
                    createParticles(in: geo.size)
                }
            }
        }
    }

    private func createParticles(in size: CGSize) {
        let colors: [Color] = [.yellow, .cyan, .green, .blue, .pink, .purple, .red, .white]

        for i in 0..<40 {
            let particle = ConfettiParticle(
                id: i,
                color: colors.randomElement() ?? .yellow,
                size: CGSize(
                    width: CGFloat.random(in: 8...16),
                    height: CGFloat.random(in: 8...16)
                ),
                position: CGPoint(x: size.width / 2, y: -20),
                rotation: Double.random(in: 0...360),
                opacity: 1.0
            )
            particles.append(particle)
        }

        // Animate particles falling
        withAnimation(.easeOut(duration: 2.0)) {
            for i in particles.indices {
                particles[i].position = CGPoint(
                    x: CGFloat.random(in: 0...size.width),
                    y: size.height + 50
                )
                particles[i].rotation = Double.random(in: 0...720)
                particles[i].opacity = 0
            }
        }

        // Clean up
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            particles.removeAll()
        }
    }
}

struct ConfettiParticle: Identifiable {
    let id: Int
    let color: Color
    let size: CGSize
    var position: CGPoint
    var rotation: Double
    var opacity: Double
}

struct LevelCompleteView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.4, green: 0.2, blue: 0.9),
                    Color(red: 0.5, green: 0.3, blue: 0.95)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            LevelCompleteView(viewModel: GameViewModel(), level: 1)
                .environmentObject(AppState())
        }
    }
}
