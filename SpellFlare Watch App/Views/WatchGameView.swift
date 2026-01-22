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
                                syncHelper.sendLevelCompleted(level)
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
        VStack(spacing: 8) {
            // Speaker icon with repeat button on the left
            HStack(spacing: 12) {
                // Repeat button (small, on left)
                Button {
                    viewModel.repeatWord()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .frame(width: 28, height: 28)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(14)
                }
                .buttonStyle(.plain)

                // Speaker animation
                Image(systemName: audioService.isPlaying ? "speaker.wave.3.fill" : "speaker.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.cyan)
            }

            Text("Listen...")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))

            // Action buttons: Sentence and Spell side by side
            HStack(spacing: 6) {
                // Sentence button
                Button {
                    showSentencePicker = true
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "text.bubble")
                            .font(.system(size: 11))
                        Text("Sentence")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)

                // Spell button
                Button {
                    viewModel.startSpelling()
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "keyboard")
                            .font(.system(size: 11))
                        Text("Spell")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.cyan)
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 8)
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
        VStack(spacing: 12) {
            // On watchOS, keyboard is the primary input method
            // Speech framework is not available on watchOS

            Text("Spell the word")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))

            // Primary action - Type spelling
            Button {
                showKeyboardInput = true
            } label: {
                HStack {
                    Image(systemName: "keyboard")
                    Text("Type Spelling")
                }
                .font(.headline)
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.cyan)
                .cornerRadius(12)
            }
            .buttonStyle(.plain)

            Text("Use keyboard to spell")
                .font(.caption2)
                .foregroundColor(.white.opacity(0.5))
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
        VStack(spacing: 12) {
            // Result icon
            if viewModel.feedbackType == .correct {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.green)
            } else {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.orange)
            }

            // Only show correct spelling after giving up
            if viewModel.hasGivenUp, let word = viewModel.lastAnsweredWord {
                VStack(spacing: 4) {
                    Text("Correct spelling:")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                    Text(word.text.uppercased())
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
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
                            .font(.caption)
                            .foregroundColor(.black)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(Color.cyan)
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                } else {
                    // Show "Retry" and "Give Up" buttons
                    HStack(spacing: 12) {
                        Button {
                            viewModel.retry()
                        } label: {
                            Text("Retry")
                                .font(.caption)
                                .foregroundColor(.black)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.cyan)
                                .cornerRadius(8)
                        }
                        .buttonStyle(.plain)

                        Button {
                            viewModel.giveUp()
                        } label: {
                            Text("Give Up")
                                .font(.caption)
                                .foregroundColor(.orange)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
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
        ScrollView {
            VStack(spacing: 12) {
                Text("Use in Sentence")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.top, 8)

                ForEach(sentences) { sentence in
                    Button {
                        playSentence(sentence)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(sentence.displayLabel)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white)
                                Text("Tap to hear")
                                    .font(.system(size: 11))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            Spacer()
                            // Only show speaker icon on the sentence that's playing
                            if audioService.isPlaying && playingSentenceNumber == sentence.sentenceNumber {
                                Image(systemName: "speaker.wave.2.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.cyan)
                            } else {
                                Image(systemName: "play.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.cyan)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.15))
                        .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                }

                Button {
                    dismiss()
                } label: {
                    Text("Done")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.cyan)
                        .cornerRadius(10)
                }
                .buttonStyle(.plain)
                .padding(.top, 8)
            }
            .padding(.horizontal, 12)
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
