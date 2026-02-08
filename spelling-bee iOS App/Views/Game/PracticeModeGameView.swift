//
//  PracticeModeGameView.swift
//  spelling-bee iOS App
//
//  Wrapper view for practicing specific mistake words from a level.
//

import SwiftUI

struct PracticeModeGameView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = GameViewModel()
    @State private var showSentencePicker = false

    let level: Int
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
                // Header with practice mode indicator
                PracticeGameHeader(
                    title: "Practice Mode",
                    subtitle: "Level \(level) Tricky Words",
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
                    // Practice mode skips ads, should not reach here
                    ProgressView()
                case .presenting:
                    WordPresentationView(viewModel: viewModel, themeID: appState.profile?.shopState.equippedItem(for: .backgroundTheme))
                case .spelling:
                    SpellingInputView(viewModel: viewModel, themeID: appState.profile?.shopState.equippedItem(for: .backgroundTheme))
                case .feedback:
                    FeedbackView(viewModel: viewModel)
                case .levelComplete:
                    PracticeCompleteView(
                        viewModel: viewModel,
                        level: level,
                        onHome: {
                            appState.navigateToHome()
                        },
                        onRetry: {
                            // Restart practice with same words
                            if let grade = appState.profile?.grade {
                                viewModel.startPracticeSession(words: words, level: level, grade: grade)
                            }
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
                viewModel.startPracticeSession(words: words, level: level, grade: grade)
            }
        }
        .onDisappear {
            viewModel.cleanup()
        }
    }
}

// MARK: - Practice Game Header
struct PracticeGameHeader: View {
    let title: String
    let subtitle: String
    @ObservedObject var viewModel: GameViewModel
    @Binding var showSentencePicker: Bool
    let onExit: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            // Top row
            HStack {
                Button(action: onExit) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.8))
                }

                Spacer()

                VStack(spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.cyan)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }

                Spacer()

                Text("\(viewModel.totalAttempted)/\(viewModel.session?.totalWordsInGame ?? 0)")
                    .font(.headline)
                    .foregroundColor(.cyan)
            }

            // Progress bar
            GeometryReader { geo in
                let barWidth = geo.size.width * 0.8
                let progressValue = viewModel.progress

                HStack {
                    Spacer()
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.white.opacity(0.2))
                            .frame(width: barWidth)

                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(
                                    colors: [.cyan, .white],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: barWidth * progressValue)
                            .animation(.easeOut(duration: 0.5), value: progressValue)
                    }
                    .frame(width: barWidth)
                    Spacer()
                }
            }
            .frame(height: 12)

            // Sentence selector
            Button {
                showSentencePicker = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "text.bubble.fill")
                        .font(.system(size: 14))
                    Text("Use in a sentence")
                        .font(.system(size: 14, weight: .medium))
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10))
                }
                .foregroundColor(.purple)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.9))
                .cornerRadius(20)
            }
        }
        .padding()
    }
}

// MARK: - Practice Complete View
struct PracticeCompleteView: View {
    @ObservedObject var viewModel: GameViewModel
    let level: Int
    let onHome: () -> Void
    let onRetry: () -> Void

    @State private var iconScale: CGFloat = 0
    @State private var textOpacity: Double = 0
    @State private var buttonsOpacity: Double = 0

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.cyan, .white.opacity(0.3)],
                            center: .center,
                            startRadius: 0,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)
                    .scaleEffect(iconScale)

                Text("🎯")
                    .font(.system(size: 80))
                    .scaleEffect(iconScale)
            }

            // Result text
            VStack(spacing: 8) {
                Text("Practice Complete!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text("\(viewModel.correctCount) out of \(viewModel.session?.totalWordsInGame ?? 0) correct")
                    .font(.title3)
                    .foregroundColor(.cyan)

                if viewModel.correctCount == viewModel.session?.totalWordsInGame {
                    Text("Perfect practice session!")
                        .font(.subheadline)
                        .foregroundColor(.green)
                        .padding(.top, 4)
                }
            }
            .opacity(textOpacity)

            Spacer()

            // Buttons
            VStack(spacing: 12) {
                Button(action: onHome) {
                    HStack(spacing: 4) {
                        Image(systemName: "house.fill")
                            .font(.system(size: 14))
                        Text("Home")
                            .font(.headline)
                    }
                    .foregroundColor(.purple)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                }

                if viewModel.correctCount < viewModel.session?.totalWordsInGame ?? 0 {
                    Button(action: onRetry) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 14))
                            Text("Practice Again")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(12)
                    }
                }
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
            .opacity(buttonsOpacity)
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
    }
}

struct PracticeModeGameView_Previews: PreviewProvider {
    static var previews: some View {
        PracticeModeGameView(
            level: 5,
            words: [
                Word(text: "beautiful", difficulty: 4),
                Word(text: "necessary", difficulty: 5)
            ]
        )
        .environmentObject(AppState())
    }
}
