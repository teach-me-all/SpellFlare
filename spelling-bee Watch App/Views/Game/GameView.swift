//
//  GameView.swift
//  spelling-bee Watch App
//
//  Main gameplay screen with word presentation and spelling.
//

import SwiftUI

struct GameView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = GameViewModel()
    @State private var showVoicePicker = false

    let level: Int

    var body: some View {
        VStack {
            switch viewModel.phase {
            case .presenting:
                WordPresentationView(viewModel: viewModel, showVoicePicker: $showVoicePicker)
            case .spelling:
                SpellingInputView(viewModel: viewModel, showVoicePicker: $showVoicePicker)
            case .feedback:
                FeedbackView(viewModel: viewModel)
            case .levelComplete:
                LevelCompleteView(viewModel: viewModel, level: level)
            }
        }
        .onAppear {
            if let grade = appState.profile?.grade {
                viewModel.startLevel(level: level, grade: grade)
            }
        }
        .onDisappear {
            viewModel.cleanup()
        }
        .sheet(isPresented: $showVoicePicker) {
            VoicePickerSheet(currentWord: viewModel.currentWord?.text)
        }
    }
}

// MARK: - Voice Picker Sheet
struct VoicePickerSheet: View {
    @ObservedObject var speechService = SpeechService.shared
    @Environment(\.dismiss) var dismiss
    let currentWord: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                Text("Choose Voice")
                    .font(.headline)
                    .foregroundColor(.cyan)
                    .padding(.top)

                ForEach(speechService.availableVoices) { voice in
                    Button {
                        speechService.selectedVoice = voice
                        speechService.previewVoiceWithWord(voice, word: currentWord)
                    } label: {
                        HStack {
                            Text(voice.name)
                                .font(.caption)
                                .foregroundColor(.white)

                            Spacer()

                            if voice == speechService.selectedVoice {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.cyan)
                                    .font(.caption)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            voice == speechService.selectedVoice
                                ? Color.cyan.opacity(0.2)
                                : Color.white.opacity(0.1)
                        )
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }

                Button {
                    dismiss()
                } label: {
                    Text("Done")
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.cyan)
                .padding(.top, 8)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
    }
}

// MARK: - Word Presentation View
struct WordPresentationView: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject var viewModel: GameViewModel
    @Binding var showVoicePicker: Bool

    var body: some View {
        VStack(spacing: 2) {
            // Top row with back button and counter
            HStack {
                Button {
                    viewModel.cleanup()
                    appState.navigateToHome()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.7))
                }
                .buttonStyle(.plain)

                Spacer()

                Text("\(viewModel.correctCount)/10")
                    .font(.system(size: 9))
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.horizontal, 8)
            .padding(.top, 2)

            // Turtle progress bar
            TurtleProgressBar(progress: viewModel.progress)
                .frame(height: 14)
                .padding(.horizontal, 8)

            // Voice selector with hint
            VStack(spacing: 1) {
                Button {
                    showVoicePicker = true
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "speaker.wave.2")
                            .font(.system(size: 8))
                        Text(String(SpeechService.shared.selectedVoice.name.prefix(5)))
                            .font(.system(size: 8))
                    }
                    .foregroundColor(.purple)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)

                Text("Change if unclear")
                    .font(.system(size: 9))
                    .foregroundColor(.white.opacity(0.5))
            }

            Spacer()

            // Word indicator
            Text("🔊")
                .font(.system(size: 28))

            Text("Listen carefully!")
                .font(.system(size: 10))
                .foregroundColor(.cyan)

            Spacer()

            // Action buttons - compact horizontal layout
            HStack(spacing: 4) {
                Button {
                    viewModel.repeatWord()
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 12))
                }
                .buttonStyle(.bordered)
                .tint(.white)

                Button {
                    viewModel.startSpelling()
                } label: {
                    Text("Spell It!")
                        .font(.system(size: 11))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.cyan)
            }
            .padding(.horizontal, 6)
            .padding(.bottom, 2)
        }
    }
}

// MARK: - Spelling Input View
struct SpellingInputView: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject var viewModel: GameViewModel
    @Binding var showVoicePicker: Bool
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 2) {
            // Top row with back button
            HStack {
                Button {
                    viewModel.cleanup()
                    appState.navigateToHome()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                }
                .buttonStyle(.plain)

                Spacer()

                // Voice selector
                Button {
                    showVoicePicker = true
                } label: {
                    HStack(spacing: 2) {
                        Image(systemName: "speaker.wave.2")
                            .font(.system(size: 8))
                        Text(String(SpeechService.shared.selectedVoice.name.prefix(4)))
                            .font(.system(size: 8))
                    }
                    .foregroundColor(.purple)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 6)
            .padding(.top, 2)

            // Turtle progress bar
            TurtleProgressBar(progress: viewModel.progress)
                .frame(height: 12)
                .padding(.horizontal, 6)

            Text("Type the spelling")
                .font(.system(size: 9))
                .foregroundColor(.cyan)

            // Text input with dictation support
            TextField("Spell here...", text: $viewModel.userSpelling)
                .textFieldStyle(.plain)
                .font(.system(size: 14, design: .monospaced))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(5)
                .background(Color.white.opacity(0.15))
                .foregroundColor(.white)
                .cornerRadius(6)
                .focused($isFocused)
                .padding(.horizontal, 6)

            // Show current input
            if !viewModel.userSpelling.isEmpty {
                Text(viewModel.userSpelling.uppercased())
                    .font(.system(size: 10, design: .monospaced))
                    .fontWeight(.bold)
                    .foregroundColor(.cyan)
            }

            Spacer()

            // Action buttons - compact
            HStack(spacing: 4) {
                Button {
                    viewModel.repeatWord()
                } label: {
                    Image(systemName: "speaker.wave.2")
                        .font(.system(size: 11))
                }
                .buttonStyle(.bordered)
                .tint(.white)

                Button {
                    viewModel.submitSpelling()
                } label: {
                    Text("Done")
                        .font(.system(size: 11))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.cyan)
                .disabled(viewModel.userSpelling.isEmpty)
            }
            .padding(.horizontal, 6)
            .padding(.bottom, 2)
        }
        .onAppear {
            isFocused = true
        }
    }
}

// MARK: - Turtle Progress Bar
struct TurtleProgressBar: View {
    let progress: Double

    var body: some View {
        GeometryReader { geo in
            let barWidth = geo.size.width * 0.8
            let turtleOffset = barWidth * progress

            HStack {
                Spacer()
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.2))
                        .frame(width: barWidth, height: 6)

                    // Progress fill
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [.cyan, .white],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: barWidth * progress, height: 6)
                        .animation(.easeOut(duration: 0.5), value: progress)

                    // Turtle indicator (flipped to face right)
                    Text("🐢")
                        .font(.system(size: 12))
                        .scaleEffect(x: -1, y: 1)
                        .offset(x: turtleOffset - 6, y: -2)
                        .animation(.easeOut(duration: 0.5), value: progress)
                }
                .frame(width: barWidth)
                Spacer()
            }
        }
    }
}

// MARK: - Progress Bar (Legacy)
struct ProgressBar: View {
    let progress: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.white.opacity(0.2))

                RoundedRectangle(cornerRadius: 3)
                    .fill(
                        LinearGradient(
                            colors: [.cyan, .white],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geo.size.width * progress)
                    .animation(.easeOut(duration: 0.3), value: progress)
            }
        }
    }
}

struct GameView_Previews: PreviewProvider {
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

            GameView(level: 1)
                .environmentObject(AppState())
        }
    }
}
