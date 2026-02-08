//
//  DailyChallengeGameView.swift
//  spelling-bee iOS App
//
//  Game view for the daily practice challenge.
//

import SwiftUI

struct DailyChallengeGameView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = GameViewModel()
    @State private var showSentencePicker = false
    @State private var practiceCoinsEarned = 0

    let words: [Word]

    var body: some View {
        ZStack {
            // Background themed by equipped shop item
            LinearGradient(
                colors: ThemeService.backgroundColors(for: appState.profile?.shopState.equippedItem(for: .backgroundTheme)),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                PracticeGameHeader(
                    title: "Daily Challenge",
                    subtitle: "Practice Your Tricky Words",
                    viewModel: viewModel,
                    showSentencePicker: $showSentencePicker,
                    onExit: {
                        appState.navigateToHome()
                    }
                )

                Spacer()

                // Main content based on phase
                switch viewModel.phase {
                case .preAd:
                    ProgressView()
                case .presenting:
                    WordPresentationView(viewModel: viewModel, themeID: appState.profile?.shopState.equippedItem(for: .backgroundTheme))
                case .spelling:
                    SpellingInputView(viewModel: viewModel, themeID: appState.profile?.shopState.equippedItem(for: .backgroundTheme))
                case .feedback:
                    FeedbackView(viewModel: viewModel)
                case .levelComplete:
                    DailyChallengeCompleteView(
                        viewModel: viewModel,
                        coinsEarned: practiceCoinsEarned,
                        onHome: {
                            // Complete daily practice and award coins
                            appState.completeDailyPractice()
                            appState.navigateToHome()
                        }
                    )
                }

                Spacer()
            }
        }
        .sheet(isPresented: $showSentencePicker) {
            if let word = viewModel.currentWord {
                let sentences = WordBankService.shared.getSentences(for: word)
                SentencePickerSheet(
                    currentWord: word,
                    sentences: sentences
                )
            }
        }
        .onAppear {
            if let grade = appState.profile?.grade {
                viewModel.startDailyChallenge(words: words, grade: grade)
            }
        }
        .onDisappear {
            viewModel.cleanup()
        }
        .onChange(of: viewModel.phase) { newPhase in
            // Track practice results when feedback phase is shown
            if newPhase == .feedback, let word = viewModel.session?.words[safe: viewModel.totalAttempted - 1] {
                if var profile = appState.profile {
                    let wasCorrect = viewModel.feedbackType == .correct
                    let coins = MistakePracticeService.shared.recordPracticeResult(
                        wordText: word.text,
                        wasCorrect: wasCorrect,
                        profile: &profile
                    )
                    practiceCoinsEarned += coins
                    appState.profile = profile
                    appState.profileManager.saveProfile(profile)
                }
            }
        }
    }
}

// MARK: - Daily Challenge Complete View
struct DailyChallengeCompleteView: View {
    @ObservedObject var viewModel: GameViewModel
    let coinsEarned: Int
    let onHome: () -> Void

    @State private var iconScale: CGFloat = 0
    @State private var textOpacity: Double = 0
    @State private var buttonsOpacity: Double = 0
    @State private var showConfetti = false

    var body: some View {
        ZStack {
            // Confetti for good performance
            if viewModel.correctCount > 0 {
                ConfettiView(isActive: $showConfetti, colors: [.cyan, .yellow, .green, .purple])
            }

            VStack(spacing: 30) {
                Spacer()

                // Icon
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [.yellow, .orange.opacity(0.3)],
                                center: .center,
                                startRadius: 0,
                                endRadius: 80
                            )
                        )
                        .frame(width: 160, height: 160)
                        .scaleEffect(iconScale)

                    Text("🌟")
                        .font(.system(size: 80))
                        .scaleEffect(iconScale)
                }

                // Result text
                VStack(spacing: 12) {
                    Text("Daily Practice Complete!")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Text("\(viewModel.correctCount) out of \(viewModel.session?.totalWordsInGame ?? 0) correct")
                        .font(.title3)
                        .foregroundColor(.cyan)

                    if coinsEarned > 0 {
                        FloatingCoinsEarnedView(amount: coinsEarned + CoinsService.dailyPracticeBaseReward)
                            .padding(.top, 8)
                    }

                    // Mastery message
                    if viewModel.correctCount == viewModel.session?.totalWordsInGame {
                        Text("Amazing! Keep practicing daily!")
                            .font(.subheadline)
                            .foregroundColor(.green)
                            .padding(.top, 4)
                    }
                }
                .opacity(textOpacity)

                Spacer()

                // Home button
                Button(action: onHome) {
                    HStack(spacing: 4) {
                        Image(systemName: "house.fill")
                            .font(.system(size: 14))
                        Text("Done")
                            .font(.headline)
                    }
                    .foregroundColor(.purple)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
                .opacity(buttonsOpacity)
            }
        }
        .onAppear {
            animateResult()
        }
    }

    private func animateResult() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.5).delay(0.2)) {
            iconScale = 1.0
        }
        withAnimation(.easeIn(duration: 0.5).delay(0.5)) {
            textOpacity = 1.0
        }
        withAnimation(.easeIn(duration: 0.5).delay(0.8)) {
            buttonsOpacity = 1.0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            showConfetti = true
        }
    }
}

// MARK: - Array Safe Subscript
extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

struct DailyChallengeGameView_Previews: PreviewProvider {
    static var previews: some View {
        DailyChallengeGameView(
            words: [
                Word(text: "beautiful", difficulty: 4),
                Word(text: "necessary", difficulty: 5)
            ]
        )
        .environmentObject(AppState())
    }
}
