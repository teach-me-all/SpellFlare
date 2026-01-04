//
//  FeedbackView.swift
//  spelling-bee iOS App
//
//  Shows correct/incorrect feedback after spelling attempt.
//

import SwiftUI

struct FeedbackView: View {
    @ObservedObject var viewModel: GameViewModel
    @Binding var useKeyboardMode: Bool

    @State private var iconScale: CGFloat = 0
    @State private var textOpacity: Double = 0
    @State private var showParticles = false
    @State private var sadFaceOffset: CGFloat = 0
    @State private var spellingOpacity: Double = 0
    @State private var letterAnimations: [Bool] = []

    var isCorrect: Bool {
        viewModel.feedbackType == .correct
    }

    var correctWord: String {
        viewModel.currentWord?.text ?? ""
    }

    var body: some View {
        ZStack {
            // Success particles (confetti + flowers)
            if isCorrect {
                CelebrationParticlesView(isActive: $showParticles)
            } else {
                // Sad face with tears
                SadFaceOverlayView(isActive: $showParticles)
            }

            VStack(spacing: 24) {
                // Result icon
                ZStack {
                    Circle()
                        .fill(isCorrect ? Color.cyan.opacity(0.3) : Color.red.opacity(0.3))
                        .frame(width: 140, height: 140)

                    if isCorrect {
                        Text("🎉")
                            .font(.system(size: 70))
                            .scaleEffect(iconScale)
                    } else {
                        Text("😢")
                            .font(.system(size: 70))
                            .scaleEffect(iconScale)
                            .offset(y: sadFaceOffset)
                    }
                }

                // Feedback text
                Text(isCorrect ? "Correct!" : "Not quite...")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .opacity(textOpacity)

                // Show spelling only after giving up (not on retry screen)
                if !isCorrect && !correctWord.isEmpty && !viewModel.showRetryOption {
                    VStack(spacing: 12) {
                        Text("The correct spelling is:")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))

                        // Animated letter display
                        HStack(spacing: 4) {
                            ForEach(Array(correctWord.uppercased().enumerated()), id: \.offset) { index, letter in
                                Text(String(letter))
                                    .font(.system(size: 32, weight: .bold, design: .monospaced))
                                    .foregroundColor(.cyan)
                                    .scaleEffect(index < letterAnimations.count && letterAnimations[index] ? 1.0 : 0.5)
                                    .opacity(index < letterAnimations.count && letterAnimations[index] ? 1.0 : 0.0)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.15))
                        .cornerRadius(12)
                    }
                    .opacity(spellingOpacity)
                }

                // Actions for incorrect (retry option available)
                if viewModel.showRetryOption {
                    VStack(spacing: 12) {
                        // Show hint after 2 retries
                        if viewModel.shouldShowKeyboardHint {
                            Text("Trouble spelling the word? Try keyboard instead.")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.9))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                                .padding(.bottom, 4)
                        }

                        Button {
                            viewModel.retry()
                        } label: {
                            Label(
                                viewModel.shouldShowKeyboardHint ? "Speak Again" : "Try Again",
                                systemImage: viewModel.shouldShowKeyboardHint ? "mic.fill" : "arrow.counterclockwise"
                            )
                                .font(.headline)
                                .foregroundColor(.purple)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                        }

                        // Show keyboard option after 2 retries
                        if viewModel.shouldShowKeyboardHint {
                            Button {
                                useKeyboardMode = true
                                viewModel.switchToKeyboard()
                            } label: {
                                Label("Use Keyboard", systemImage: "keyboard")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.cyan)
                                    .cornerRadius(12)
                            }
                        }

                        Button {
                            viewModel.giveUp()
                        } label: {
                            Text("Continue")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 40)
                    .opacity(textOpacity)
                }
            }
        }
        .onAppear {
            animateFeedback()
        }
    }

    private func animateFeedback() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.1)) {
            iconScale = 1.0
        }

        withAnimation(.easeIn(duration: 0.4).delay(0.3)) {
            textOpacity = 1.0
        }

        // Trigger particles
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            showParticles = true
        }

        // Sad face wobble animation
        if !isCorrect {
            withAnimation(.easeInOut(duration: 0.3).repeatCount(3, autoreverses: true).delay(0.3)) {
                sadFaceOffset = -5
            }

            // Only show spelling animation after giving up (when retry option is NOT shown)
            if !viewModel.showRetryOption {
                // Animate spelling reveal
                withAnimation(.easeIn(duration: 0.3).delay(0.5)) {
                    spellingOpacity = 1.0
                }

                // Animate letters one by one
                letterAnimations = Array(repeating: false, count: correctWord.count)
                for i in 0..<correctWord.count {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.7 + Double(i) * 0.15) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            if i < letterAnimations.count {
                                letterAnimations[i] = true
                            }
                        }
                        // Speak each letter
                        let letter = String(Array(correctWord)[i])
                        SpeechService.shared.speakFeedback(letter.uppercased())
                    }
                }
            }
        }
    }
}

// MARK: - Celebration Particles (Confetti + Flowers)
struct CelebrationParticlesView: View {
    @Binding var isActive: Bool
    @State private var particles: [CelebrationParticle] = []

    let flowers = ["🌸", "🌺", "🌻", "🌷", "💐", "🌼", "🏵️", "💮"]
    let confettiColors: [Color] = [.yellow, .orange, .green, .blue, .pink, .purple, .red, .mint]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(particles) { particle in
                    if particle.isFlower {
                        Text(particle.emoji)
                            .font(.system(size: particle.size))
                            .position(particle.position)
                            .rotationEffect(.degrees(particle.rotation))
                            .opacity(particle.opacity)
                    } else {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(particle.color)
                            .frame(width: particle.size, height: particle.size * 0.6)
                            .position(particle.position)
                            .rotationEffect(.degrees(particle.rotation))
                            .opacity(particle.opacity)
                    }
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
        // Create flowers
        for i in 0..<15 {
            let particle = CelebrationParticle(
                id: i,
                isFlower: true,
                emoji: flowers.randomElement() ?? "🌸",
                color: .clear,
                size: CGFloat.random(in: 24...40),
                position: CGPoint(
                    x: CGFloat.random(in: 0...size.width),
                    y: -30
                ),
                rotation: Double.random(in: 0...360),
                opacity: 1.0
            )
            particles.append(particle)
        }

        // Create confetti
        for i in 15..<50 {
            let particle = CelebrationParticle(
                id: i,
                isFlower: false,
                emoji: "",
                color: confettiColors.randomElement() ?? .yellow,
                size: CGFloat.random(in: 8...16),
                position: CGPoint(
                    x: CGFloat.random(in: 0...size.width),
                    y: -30
                ),
                rotation: Double.random(in: 0...360),
                opacity: 1.0
            )
            particles.append(particle)
        }

        // Animate falling
        withAnimation(.easeOut(duration: 2.5)) {
            for i in particles.indices {
                particles[i].position = CGPoint(
                    x: particles[i].position.x + CGFloat.random(in: -50...50),
                    y: size.height + 50
                )
                particles[i].rotation = Double.random(in: 0...720)
                particles[i].opacity = 0
            }
        }

        // Cleanup
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            particles.removeAll()
        }
    }
}

struct CelebrationParticle: Identifiable {
    let id: Int
    let isFlower: Bool
    let emoji: String
    let color: Color
    let size: CGFloat
    var position: CGPoint
    var rotation: Double
    var opacity: Double
}

// MARK: - Sad Face Overlay
struct SadFaceOverlayView: View {
    @Binding var isActive: Bool
    @State private var tearDrops: [TearDrop] = []
    @State private var sadEmojis: [FloatingSadEmoji] = []

    let sadFaces = ["😢", "😿", "🥺", "😞", "💔"]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Floating sad emojis
                ForEach(sadEmojis) { emoji in
                    Text(emoji.emoji)
                        .font(.system(size: emoji.size))
                        .position(emoji.position)
                        .opacity(emoji.opacity)
                }

                // Tear drops
                ForEach(tearDrops) { tear in
                    Text("💧")
                        .font(.system(size: tear.size))
                        .position(tear.position)
                        .opacity(tear.opacity)
                }
            }
            .onChange(of: isActive) { active in
                if active {
                    createSadAnimation(in: geo.size)
                }
            }
        }
    }

    private func createSadAnimation(in size: CGSize) {
        // Create floating sad emojis around edges
        for i in 0..<8 {
            let emoji = FloatingSadEmoji(
                id: i,
                emoji: sadFaces.randomElement() ?? "😢",
                size: CGFloat.random(in: 30...50),
                position: CGPoint(
                    x: CGFloat.random(in: 0...size.width),
                    y: CGFloat.random(in: 0...size.height)
                ),
                opacity: 0
            )
            sadEmojis.append(emoji)
        }

        // Create tear drops falling
        for i in 0..<12 {
            let tear = TearDrop(
                id: i,
                size: CGFloat.random(in: 16...28),
                position: CGPoint(
                    x: CGFloat.random(in: 40...(size.width - 40)),
                    y: -20
                ),
                opacity: 0.8
            )
            tearDrops.append(tear)
        }

        // Animate sad emojis fading in
        withAnimation(.easeIn(duration: 0.5)) {
            for i in sadEmojis.indices {
                sadEmojis[i].opacity = 0.6
            }
        }

        // Animate tears falling
        withAnimation(.easeIn(duration: 2.0)) {
            for i in tearDrops.indices {
                tearDrops[i].position.y = size.height + 30
                tearDrops[i].opacity = 0
            }
        }

        // Fade out sad emojis
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeOut(duration: 0.5)) {
                for i in sadEmojis.indices {
                    sadEmojis[i].opacity = 0
                }
            }
        }

        // Cleanup
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            tearDrops.removeAll()
            sadEmojis.removeAll()
        }
    }
}

struct TearDrop: Identifiable {
    let id: Int
    let size: CGFloat
    var position: CGPoint
    var opacity: Double
}

struct FloatingSadEmoji: Identifiable {
    let id: Int
    let emoji: String
    let size: CGFloat
    var position: CGPoint
    var opacity: Double
}

struct FeedbackView_Previews: PreviewProvider {
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

            FeedbackView(viewModel: GameViewModel(), useKeyboardMode: .constant(false))
        }
    }
}
