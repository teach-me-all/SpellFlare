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
    @ObservedObject var viewModel: GameViewModel
    @Binding var showVoicePicker: Bool

    var body: some View {
        VStack(spacing: 6) {
            // Progress indicator with counter and voice button
            HStack {
                ProgressBar(progress: viewModel.progress)
                    .frame(height: 5)

                Text("\(viewModel.correctCount)/10")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.7))
                    .fixedSize()

                Button {
                    showVoicePicker = true
                } label: {
                    Image(systemName: "person.wave.2")
                        .font(.system(size: 10))
                }
                .buttonStyle(.plain)
                .foregroundColor(.cyan)
            }
            .padding(.horizontal, 8)
            .padding(.top, 4)

            Spacer()

            // Word indicator
            Text("🔊")
                .font(.system(size: 36))

            Text("Listen carefully!")
                .font(.caption2)
                .foregroundColor(.cyan)

            Spacer()

            // Action buttons - horizontal layout
            HStack(spacing: 6) {
                Button {
                    viewModel.repeatWord()
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .tint(.white)

                Button {
                    viewModel.startSpelling()
                } label: {
                    Text("Spell It!")
                        .font(.caption2)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.cyan)
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 4)
        }
    }
}

// MARK: - Spelling Input View
struct SpellingInputView: View {
    @ObservedObject var viewModel: GameViewModel
    @Binding var showVoicePicker: Bool
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 8) {
            // Progress with voice button
            HStack {
                ProgressBar(progress: viewModel.progress)
                    .frame(height: 6)

                Button {
                    showVoicePicker = true
                } label: {
                    Image(systemName: "person.wave.2")
                        .font(.system(size: 10))
                }
                .buttonStyle(.plain)
                .foregroundColor(.cyan)
            }
            .padding(.horizontal)

            Text("Type the spelling")
                .font(.caption)
                .foregroundColor(.cyan)

            // Text input with dictation support
            TextField("Spell here...", text: $viewModel.userSpelling)
                .textFieldStyle(.plain)
                .font(.system(.body, design: .monospaced))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(8)
                .background(Color.white.opacity(0.15))
                .foregroundColor(.white)
                .cornerRadius(8)
                .focused($isFocused)
                .padding(.horizontal)

            // Show current input
            if !viewModel.userSpelling.isEmpty {
                Text(viewModel.userSpelling.uppercased())
                    .font(.system(.caption, design: .monospaced))
                    .fontWeight(.bold)
                    .foregroundColor(.cyan)
            }

            Spacer()

            // Action buttons
            HStack(spacing: 8) {
                Button {
                    viewModel.repeatWord()
                } label: {
                    Image(systemName: "speaker.wave.2")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .tint(.white)

                Button {
                    viewModel.submitSpelling()
                } label: {
                    Text("Done")
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.cyan)
                .disabled(viewModel.userSpelling.isEmpty)
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .onAppear {
            isFocused = true
        }
    }
}

// MARK: - Progress Bar
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
