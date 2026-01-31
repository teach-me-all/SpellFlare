//
//  AchievementUnlockOverlay.swift
//  spelling-bee iOS App
//
//  Full-screen overlay shown when an achievement is unlocked.
//

import SwiftUI

struct AchievementUnlockOverlay: View {
    let achievementID: String
    let onDismiss: () -> Void

    @State private var showConfetti = false
    @State private var badgeScale: CGFloat = 0
    @State private var textOpacity: Double = 0
    @State private var coinOpacity: Double = 0
    @State private var glowOpacity: Double = 0
    @State private var glowScale: CGFloat = 1.0
    @State private var sparkleRotation: Double = 0

    private var definition: AchievementDefinition? {
        AchievementDefinitions.definition(for: achievementID)
    }

    private var rarity: AchievementRarity {
        definition?.rarity ?? .common
    }

    private var autoDismissDelay: Double {
        rarity == .legendary ? 4.0 : 3.0
    }

    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            // Confetti (for all rarities, more for legendary)
            ConfettiView(isActive: $showConfetti)

            VStack(spacing: 24) {
                Spacer()

                // "Achievement Unlocked" label
                Text("Achievement Unlocked!")
                    .font(.headline)
                    .foregroundColor(RarityColors.borderColor(for: rarity))
                    .opacity(textOpacity)

                // Badge icon with rarity-based visuals
                if let def = definition {
                    ZStack {
                        // Glow ring for rare+
                        if rarity != .common {
                            Circle()
                                .fill(RarityColors.borderColor(for: rarity).opacity(0.2))
                                .frame(width: 150, height: 150)
                                .scaleEffect(glowScale)
                                .opacity(glowOpacity)
                                .blur(radius: 10)
                        }

                        // Sparkle ring for epic+
                        if rarity == .epic || rarity == .legendary {
                            ForEach(0..<8, id: \.self) { i in
                                Image(systemName: "sparkle")
                                    .font(.system(size: 12))
                                    .foregroundColor(RarityColors.borderColor(for: rarity))
                                    .offset(y: -75)
                                    .rotationEffect(.degrees(Double(i) * 45 + sparkleRotation))
                                    .opacity(glowOpacity * 0.8)
                            }
                        }

                        // Badge background
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        RarityColors.borderColor(for: rarity),
                                        RarityColors.fillColor(for: rarity, unlocked: true)
                                    ],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 70
                                )
                            )
                            .frame(width: 120, height: 120)

                        // Rarity border
                        Circle()
                            .stroke(
                                RarityColors.borderColor(for: rarity),
                                lineWidth: RarityColors.borderWidth(for: rarity) * 1.5
                            )
                            .frame(width: 120, height: 120)

                        Image(systemName: def.iconName)
                            .font(.system(size: 50))
                            .foregroundColor(.white)
                    }
                    .scaleEffect(badgeScale)

                    // Title
                    Text(def.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .opacity(textOpacity)

                    Text(def.description)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .opacity(textOpacity)

                    // Rarity label
                    Text(RarityColors.rarityLabel(rarity))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(RarityColors.borderColor(for: rarity))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(RarityColors.borderColor(for: rarity).opacity(0.2))
                        )
                        .opacity(textOpacity)

                    // Coin reward
                    FloatingCoinsEarnedView(amount: def.coinReward)
                        .opacity(coinOpacity)
                }

                Spacer()

                // Tap to dismiss
                Text("Tap to continue")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
                    .opacity(textOpacity)
                    .padding(.bottom, 40)
            }
        }
        .onAppear {
            animateIn()
            DispatchQueue.main.asyncAfter(deadline: .now() + autoDismissDelay) {
                onDismiss()
            }
        }
    }

    private func animateIn() {
        let springResponse: Double
        switch rarity {
        case .common:
            springResponse = 0.3
        case .rare:
            springResponse = 0.5
        case .epic, .legendary:
            springResponse = 0.6
        }

        // Badge spring animation
        withAnimation(.spring(response: springResponse, dampingFraction: 0.6).delay(0.1)) {
            badgeScale = 1.0
        }

        // Text fade in
        withAnimation(.easeIn(duration: 0.4).delay(0.3)) {
            textOpacity = 1.0
        }

        // Coin animation
        withAnimation(.easeIn(duration: 0.4).delay(0.6)) {
            coinOpacity = 1.0
        }

        // Glow pulse for rare+
        if rarity != .common {
            withAnimation(.easeIn(duration: 0.5).delay(0.2)) {
                glowOpacity = 1.0
            }
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true).delay(0.5)) {
                glowScale = 1.15
            }
        }

        // Sparkle rotation for epic+
        if rarity == .epic || rarity == .legendary {
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false).delay(0.3)) {
                sparkleRotation = 360
            }
        }

        // Confetti
        let confettiDelay: Double = rarity == .legendary ? 0.1 : 0.2
        DispatchQueue.main.asyncAfter(deadline: .now() + confettiDelay) {
            showConfetti = true
        }
    }
}
