//
//  WatchGameView.swift
//  SpellFlare Watch App
//
//  Main game screen containing word presentation, spelling, and feedback.
//

import SwiftUI

struct WatchGameView: View {
    @EnvironmentObject var appState: WatchAppState
    @EnvironmentObject var syncHelper: WatchSyncHelper
    @StateObject private var viewModel = WatchGameViewModel()

    let level: Int

    var body: some View {
        VStack(spacing: 0) {
            // Header with progress
            GameHeaderView(
                level: level,
                totalAttempted: viewModel.totalAttempted,
                progress: viewModel.progress,
                onExit: { appState.navigateToHome() }
            )

            Spacer()

            // Main content based on phase
            switch viewModel.phase {
            case .presenting:
                WordPresentingView(viewModel: viewModel)

            case .spelling:
                SpellingInputView(viewModel: viewModel)

            case .feedback:
                if viewModel.isLevelComplete {
                    // Level complete - transition to complete screen
                    Color.clear
                        .onAppear {
                            appState.showLevelComplete(
                                level: viewModel.completedLevel,
                                score: viewModel.finalScore,
                                coinsEarned: viewModel.coinsEarned,
                                didPass: viewModel.didPassLevel
                            )
                            // Only sync if user passed the level
                            if viewModel.didPassLevel {
                                syncHelper.sendLevelCompleted(
                                    level,
                                    coinsEarned: viewModel.coinsEarned,
                                    score: viewModel.finalScore,
                                    correctCount: viewModel.correctCount,
                                    totalWords: viewModel.session?.totalWordsInGame ?? 0,
                                    firstTryCount: viewModel.firstTryCount,
                                    durationSeconds: viewModel.sessionDurationSeconds
                                )
                            }
                        }
                } else {
                    FeedbackResultView(viewModel: viewModel)
                }
            }

            Spacer()
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
        .onAppear {
            let grade = syncHelper.profile?.grade ?? 1
            viewModel.startLevel(level: level, grade: grade)
            syncHelper.sendGameStarted()
        }
        .onDisappear {
            viewModel.cleanup()
        }
    }
}

// MARK: - Game Header
struct GameHeaderView: View {
    let level: Int
    let totalAttempted: Int
    let progress: Double
    let onExit: () -> Void

    var body: some View {
        HStack {
            // Exit button
            Button(action: onExit) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.white.opacity(0.6))
            }
            .buttonStyle(.plain)

            Spacer()

            // Level
            Text("Lvl \(level)")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))

            Spacer()

            // Score
            Text("\(totalAttempted)/10")
                .font(.caption)
                .foregroundColor(.cyan)
        }
        .padding(.horizontal)
        .padding(.top, 4)

        // Progress bar
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.white.opacity(0.2))
                    .frame(height: 4)

                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.cyan, .white],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geo.size.width * progress, height: 4)
            }
            .cornerRadius(2)
        }
        .frame(height: 4)
        .padding(.horizontal)
        .padding(.top, 4)
    }
}

// MARK: - Word Presenting View
struct WordPresentingView: View {
    @ObservedObject var viewModel: WatchGameViewModel
    @ObservedObject var audioService = WatchAudioService.shared
    @State private var showSentencePicker = false

    var body: some View {
        GeometryReader { geometry in
            let isSmallWatch = geometry.size.height < 180
            let isLargeWatch = geometry.size.height > 220
            let speakerSize: CGFloat = isSmallWatch ? 24 : (isLargeWatch ? 40 : 32)
            let repeatButtonSize: CGFloat = isSmallWatch ? 22 : (isLargeWatch ? 34 : 28)
            let buttonFont: CGFloat = isSmallWatch ? 9 : (isLargeWatch ? 13 : 11)
            let buttonPadding: CGFloat = isSmallWatch ? 8 : (isLargeWatch ? 12 : 10)

            VStack(spacing: isSmallWatch ? 4 : 8) {
                // Speaker icon with repeat button on the left
                HStack(spacing: isSmallWatch ? 8 : 12) {
                    // Repeat button (small, on left)
                    Button {
                        viewModel.repeatWord()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: isSmallWatch ? 11 : 14))
                            .foregroundColor(.white)
                            .frame(width: repeatButtonSize, height: repeatButtonSize)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(repeatButtonSize / 2)
                    }
                    .buttonStyle(.plain)

                    // Speaker animation
                    Image(systemName: audioService.isPlaying ? "speaker.wave.3.fill" : "speaker.fill")
                        .font(.system(size: speakerSize))
                        .foregroundColor(.cyan)
                }

                Text("Listen...")
                    .font(.system(size: isSmallWatch ? 10 : 12))
                    .foregroundColor(.white.opacity(0.7))

                // Action buttons: Sentence and Spell side by side
                HStack(spacing: isSmallWatch ? 4 : 6) {
                    // Sentence button
                    Button {
                        showSentencePicker = true
                    } label: {
                        HStack(spacing: 2) {
                            Image(systemName: "text.bubble")
                                .font(.system(size: buttonFont))
                            Text("Sentence")
                                .font(.system(size: buttonFont, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, buttonPadding)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(isSmallWatch ? 8 : 10)
                    }
                    .buttonStyle(.plain)

                    // Spell button
                    Button {
                        viewModel.startSpelling()
                    } label: {
                        HStack(spacing: 2) {
                            Image(systemName: "keyboard")
                                .font(.system(size: buttonFont))
                            Text("Spell")
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
                .padding(.horizontal, isSmallWatch ? 4 : 8)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .sheet(isPresented: $showSentencePicker) {
            if let word = viewModel.currentWord {
                WatchSentencePickerSheet(word: word)
            }
        }
    }
}

// MARK: - Spelling Input View
struct SpellingInputView: View {
    @ObservedObject var viewModel: WatchGameViewModel

    @State private var showKeyboardInput = false
    @State private var keyboardText = ""

    var body: some View {
        GeometryReader { geometry in
            let isSmallWatch = geometry.size.height < 180
            let isLargeWatch = geometry.size.height > 220
            let buttonFont: CGFloat = isSmallWatch ? 13 : (isLargeWatch ? 18 : 15)
            let labelFont: CGFloat = isSmallWatch ? 10 : (isLargeWatch ? 14 : 12)
            let hintFont: CGFloat = isSmallWatch ? 8 : (isLargeWatch ? 11 : 9)
            let buttonPadding: CGFloat = isSmallWatch ? 10 : (isLargeWatch ? 14 : 12)

            VStack(spacing: isSmallWatch ? 8 : 12) {
                // On watchOS, keyboard is the primary input method
                // Speech framework is not available on watchOS

                Text("Spell the word")
                    .font(.system(size: labelFont))
                    .foregroundColor(.white.opacity(0.7))

                // Primary action - Type spelling
                Button {
                    showKeyboardInput = true
                } label: {
                    HStack {
                        Image(systemName: "keyboard")
                        Text("Type Spelling")
                    }
                    .font(.system(size: buttonFont, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, buttonPadding)
                    .background(Color.cyan)
                    .cornerRadius(isSmallWatch ? 10 : 12)
                }
                .buttonStyle(.plain)

                Text("Use keyboard to spell")
                    .font(.system(size: hintFont))
                    .foregroundColor(.white.opacity(0.5))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .sheet(isPresented: $showKeyboardInput) {
            KeyboardInputSheet(
                text: $keyboardText,
                onSubmit: {
                    viewModel.submitSpelling(keyboardText)
                    showKeyboardInput = false
                    keyboardText = ""
                }
            )
        }
    }
}

// MARK: - Keyboard Input Sheet
struct KeyboardInputSheet: View {
    @Binding var text: String
    let onSubmit: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Text("Type spelling")
                .font(.headline)

            TextField("Spell here", text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 20, weight: .bold, design: .monospaced))
                .multilineTextAlignment(.center)
                .autocorrectionDisabled()

            Button("Submit") {
                onSubmit()
            }
            .disabled(text.isEmpty)
        }
        .padding()
    }
}

// MARK: - Feedback Result View
struct FeedbackResultView: View {
    @ObservedObject var viewModel: WatchGameViewModel

    var body: some View {
        GeometryReader { geometry in
            let isSmallWatch = geometry.size.height < 180
            let isLargeWatch = geometry.size.height > 220
            let iconSize: CGFloat = isSmallWatch ? 38 : (isLargeWatch ? 60 : 50)
            let wordFont: CGFloat = isSmallWatch ? 14 : (isLargeWatch ? 22 : 18)
            let labelFont: CGFloat = isSmallWatch ? 9 : (isLargeWatch ? 12 : 10)
            let buttonFont: CGFloat = isSmallWatch ? 10 : (isLargeWatch ? 14 : 12)
            let buttonPaddingH: CGFloat = isSmallWatch ? 10 : (isLargeWatch ? 16 : 12)
            let buttonPaddingV: CGFloat = isSmallWatch ? 5 : (isLargeWatch ? 8 : 6)

            VStack(spacing: isSmallWatch ? 8 : 12) {
                // Result icon
                if viewModel.feedbackType == .correct {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: iconSize))
                        .foregroundColor(.green)
                } else {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: iconSize))
                        .foregroundColor(.orange)
                }

                // Only show correct spelling after giving up
                if viewModel.hasGivenUp, let word = viewModel.lastAnsweredWord {
                    VStack(spacing: isSmallWatch ? 2 : 4) {
                        Text("Correct spelling:")
                            .font(.system(size: labelFont))
                            .foregroundColor(.white.opacity(0.7))
                        Text(word.text.uppercased())
                            .font(.system(size: wordFont, weight: .bold, design: .monospaced))
                            .foregroundColor(.cyan)
                    }
                }

                // Action buttons for incorrect answers
                if viewModel.feedbackType == .incorrect {
                    if viewModel.hasGivenUp {
                        // Show "Next" button after giving up
                        Button {
                            viewModel.proceedAfterGiveUp()
                        } label: {
                            Text("Next")
                                .font(.system(size: buttonFont))
                                .foregroundColor(.black)
                                .padding(.horizontal, isSmallWatch ? 16 : 20)
                                .padding(.vertical, buttonPaddingV + 2)
                                .background(Color.cyan)
                                .cornerRadius(isSmallWatch ? 6 : 8)
                        }
                        .buttonStyle(.plain)
                    } else {
                        // Show "Retry" and "Give Up" buttons
                        HStack(spacing: isSmallWatch ? 8 : 12) {
                            Button {
                                viewModel.retry()
                            } label: {
                                Text("Retry")
                                    .font(.system(size: buttonFont))
                                    .foregroundColor(.black)
                                    .padding(.horizontal, buttonPaddingH)
                                    .padding(.vertical, buttonPaddingV)
                                    .background(Color.cyan)
                                    .cornerRadius(isSmallWatch ? 6 : 8)
                            }
                            .buttonStyle(.plain)

                            Button {
                                viewModel.giveUp()
                            } label: {
                                Text("Give Up")
                                    .font(.system(size: buttonFont))
                                    .foregroundColor(.orange)
                                    .padding(.horizontal, buttonPaddingH)
                                    .padding(.vertical, buttonPaddingV)
                                    .background(Color.white.opacity(0.2))
                                    .cornerRadius(isSmallWatch ? 6 : 8)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

// MARK: - Sentence Picker Sheet
struct WatchSentencePickerSheet: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var audioService = WatchAudioService.shared
    @State private var playingSentenceNumber: Int? = nil
    let word: WatchWord

    private var sentences: [WatchWordSentence] {
        WatchWordBankService.shared.getSentences(for: word)
    }

    var body: some View {
        GeometryReader { geometry in
            let isSmallWatch = geometry.size.height < 180
            let isLargeWatch = geometry.size.height > 220
            let headerFont: CGFloat = isSmallWatch ? 13 : (isLargeWatch ? 18 : 15)
            let labelFont: CGFloat = isSmallWatch ? 12 : (isLargeWatch ? 16 : 14)
            let hintFont: CGFloat = isSmallWatch ? 9 : (isLargeWatch ? 13 : 11)
            let iconSize: CGFloat = isSmallWatch ? 16 : (isLargeWatch ? 24 : 20)
            let buttonFont: CGFloat = isSmallWatch ? 12 : (isLargeWatch ? 16 : 14)

            ScrollView {
                VStack(spacing: isSmallWatch ? 8 : 12) {
                    Text("Use in Sentence")
                        .font(.system(size: headerFont, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.top, isSmallWatch ? 4 : 8)

                    ForEach(sentences) { sentence in
                        Button {
                            playSentence(sentence)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(sentence.displayLabel)
                                        .font(.system(size: labelFont, weight: .medium))
                                        .foregroundColor(.white)
                                    Text("Tap to hear")
                                        .font(.system(size: hintFont))
                                        .foregroundColor(.white.opacity(0.6))
                                }
                                Spacer()
                                // Only show speaker icon on the sentence that's playing
                                if audioService.isPlaying && playingSentenceNumber == sentence.sentenceNumber {
                                    Image(systemName: "speaker.wave.2.fill")
                                        .font(.system(size: iconSize))
                                        .foregroundColor(.cyan)
                                } else {
                                    Image(systemName: "play.circle.fill")
                                        .font(.system(size: iconSize))
                                        .foregroundColor(.cyan)
                                }
                            }
                            .padding(.horizontal, isSmallWatch ? 8 : 12)
                            .padding(.vertical, isSmallWatch ? 8 : 10)
                            .background(Color.white.opacity(0.15))
                            .cornerRadius(isSmallWatch ? 8 : 10)
                        }
                        .buttonStyle(.plain)
                    }

                    Button {
                        dismiss()
                    } label: {
                        Text("Done")
                            .font(.system(size: buttonFont, weight: .medium))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, isSmallWatch ? 8 : 10)
                            .background(Color.cyan)
                            .cornerRadius(isSmallWatch ? 8 : 10)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, isSmallWatch ? 4 : 8)
                }
                .padding(.horizontal, isSmallWatch ? 8 : 12)
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

    private func playSentence(_ sentence: WatchWordSentence) {
        playingSentenceNumber = sentence.sentenceNumber
        audioService.playSentence(
            sentence.word,
            difficulty: sentence.difficulty,
            number: sentence.sentenceNumber
        ) {
            // Reset when playback completes
            playingSentenceNumber = nil
        }
    }
}

#Preview {
    WatchGameView(level: 1)
        .environmentObject(WatchAppState())
        .environmentObject(WatchSyncHelper.shared)
}
