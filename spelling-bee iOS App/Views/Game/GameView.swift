//
//  GameView.swift
//  spelling-bee iOS App
//
//  Main gameplay screen with word presentation and spelling.
//

import SwiftUI

struct GameView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = GameViewModel()
    @State private var showSentencePicker = false

    let level: Int

    var body: some View {
        ZStack {
            // Purple Gradient Background
            LinearGradient(
                colors: [
                    Color(red: 0.4, green: 0.2, blue: 0.9),
                    Color(red: 0.5, green: 0.3, blue: 0.95),
                    Color(red: 0.45, green: 0.25, blue: 0.85)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                GameHeader(
                    level: level,
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
                    // Show loading indicator while ad is displayed
                    VStack(spacing: 20) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                        Text("Loading...")
                            .foregroundColor(.white.opacity(0.7))
                    }
                case .presenting:
                    WordPresentationView(viewModel: viewModel)
                case .spelling:
                    SpellingInputView(viewModel: viewModel)
                case .feedback:
                    FeedbackView(viewModel: viewModel)
                case .levelComplete:
                    LevelCompleteView(viewModel: viewModel, level: level)
                }

                Spacer()

                // Banner ad at bottom
                BannerAdView()
                    .frame(maxWidth: .infinity)
                    .background(Color.black.opacity(0.05))
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
        .fullScreenCover(isPresented: $viewModel.showPreTestAd) {
            PreTestAdView(level: level) {
                viewModel.onPreTestAdDismissed()
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
    }
}

// MARK: - Sentence Picker Sheet
struct SentencePickerSheet: View {
    @ObservedObject var audioService = AudioPlaybackService.shared
    @Environment(\.dismiss) var dismiss

    let currentWord: Word?
    let sentences: [WordSentence]

    var body: some View {
        NavigationStack {
            List {
                ForEach(sentences) { sentence in
                    Button {
                        playSentence(sentence)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(sentence.displayLabel)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text("Tap to hear")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Button {
                                playSentence(sentence)
                            } label: {
                                Image(systemName: "play.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.purple)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Choose Sentence")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func playSentence(_ sentence: WordSentence) {
        audioService.playSentence(
            sentence.word,
            difficulty: sentence.difficulty,
            sentenceNumber: sentence.sentenceNumber
        )
    }
}

// MARK: - Game Header
struct GameHeader: View {
    let level: Int
    @ObservedObject var viewModel: GameViewModel
    @Binding var showSentencePicker: Bool
    let onExit: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            // Top row with exit, level, and score
            HStack {
                Button(action: onExit) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.8))
                }

                Spacer()

                Text("Level \(level)")
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()

                Text("\(viewModel.correctCount)/10")
                    .font(.headline)
                    .foregroundColor(.cyan)
            }

            // Progress bar with turtle (80% width)
            GeometryReader { geo in
                let barWidth = geo.size.width * 0.8
                let turtleOffset = barWidth * viewModel.progress

                HStack {
                    Spacer()
                    ZStack(alignment: .leading) {
                        // Background track
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.white.opacity(0.2))
                            .frame(width: barWidth)

                        // Progress fill
                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(
                                    colors: [.cyan, .white],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: barWidth * viewModel.progress)
                            .animation(.easeOut(duration: 0.5), value: viewModel.progress)

                        // Turtle indicator (flipped to face right)
                        Text("🐢")
                            .font(.system(size: 20))
                            .scaleEffect(x: -1, y: 1)
                            .offset(x: turtleOffset - 10)
                            .animation(.easeOut(duration: 0.5), value: viewModel.progress)
                    }
                    .frame(width: barWidth)
                    Spacer()
                }
            }
            .frame(height: 24)

            // Sentence selector with hint
            VStack(spacing: 4) {
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

                Text("Use the word in a sentence")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding()
    }
}

// MARK: - Spelling State Machine
enum SpellingState {
    case waitingForFirstLetter  // Ignore everything except valid letters
    case spellingMode           // Process everything as spelling
}

// MARK: - Word Presentation View
struct WordPresentationView: View {
    @ObservedObject var viewModel: GameViewModel
    @ObservedObject var speechService = SpeechService.shared
    @State private var isRecording = false
    @State private var pulseAnimation = false
    @State private var useKeyboard = false
    @State private var keyboardInput = ""
    @FocusState private var isKeyboardFocused: Bool
    @State private var spellingState: SpellingState = .waitingForFirstLetter
    @State private var displayedSpelling = ""  // What we show in UI
    @State private var textAtTransition = ""  // Text we had when transitioning to spelling mode

    var body: some View {
        VStack(spacing: 20) {
            // Fixed header section at top
            VStack(spacing: 15) {
                Text(useKeyboard ? "Type the spelling below" : "Listen carefully!")
                    .font(.title2)
                    .foregroundColor(.white.opacity(0.8))

                ZStack {
                    // Center-aligned main button (mic or keyboard icon)
                    if !useKeyboard {
                        Button {
                            toggleRecording()
                        } label: {
                            ZStack {
                                if isRecording {
                                    Circle()
                                        .fill(Color.red.opacity(0.3))
                                        .frame(width: 140, height: 140)
                                        .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                                        .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: pulseAnimation)
                                }

                                Circle()
                                    .fill(Color.white.opacity(0.1))
                                    .frame(width: 120, height: 120)

                                Circle()
                                    .fill(Color.white.opacity(0.15))
                                    .frame(width: 90, height: 90)

                                Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(isRecording ? .red : .cyan)
                            }
                        }
                        .onChange(of: isRecording) { newValue in
                            pulseAnimation = newValue
                        }
                    } else {
                        // Show keyboard icon in keyboard mode (centered)
                        Image(systemName: "keyboard")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                            .padding(.vertical, 30)
                    }

                    // Keyboard toggle button (positioned to the RIGHT of center button)
                    HStack {
                        Spacer()
                        Button {
                            toggleInputMode()
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: useKeyboard ? "mic.fill" : "keyboard")
                                    .font(.system(size: 24))
                                    .foregroundColor(.white.opacity(0.9))
                                    .frame(width: 50, height: 50)
                                    .background(Color.white.opacity(0.2))
                                    .cornerRadius(10)

                                Text(useKeyboard ? "Mic" : "Type")
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                        .offset(x: -40)  // Position to right of center button
                    }
                }

                if !useKeyboard {
                    VStack(spacing: 4) {
                        Text(isRecording ? "Listening..." : "Spell it")
                            .font(.headline)
                            .foregroundColor(isRecording ? .red : .white)

                        Text("Please spell letter by letter")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
            .frame(height: 240)  // Fixed height to prevent layout shift

            // Dynamic content area with fixed minimum height
            VStack(spacing: 12) {
                // Keyboard hint (show after 2 cancellations)
                if viewModel.shouldShowKeyboardHint && !useKeyboard {
                    VStack(spacing: 10) {
                        Text("Trouble spelling out loud?")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))

                        Button {
                            useKeyboard = true
                            viewModel.hasSeenKeyboardHint = true
                            isKeyboardFocused = true
                        } label: {
                            Label("Use Keyboard Instead", systemImage: "keyboard")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(Color.green)
                                .cornerRadius(10)
                        }
                    }
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
                    .transition(.scale.combined(with: .opacity))
                }

                // Keyboard input mode
                if useKeyboard {
                    VStack(spacing: 12) {
                        Text("Type the spelling:")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))

                        TextField("Type here...", text: $keyboardInput)
                            .textFieldStyle(.plain)
                            .font(.system(size: 24, weight: .medium))
                            .multilineTextAlignment(.center)
                            .padding()
                            .background(Color.white.opacity(0.9))
                            .cornerRadius(12)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .focused($isKeyboardFocused)

                        if !keyboardInput.isEmpty {
                            Text(keyboardInput.uppercased())
                                .font(.system(size: 23, weight: .bold, design: .monospaced))
                                .foregroundColor(.cyan)
                                .tracking(4)
                        }
                    }
                    .padding(.horizontal, 20)
                } else {
                    // Show recognized text (mic mode)
                    if !displayedSpelling.isEmpty {
                        VStack(spacing: 8) {
                            Text("Heard:")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))

                            Text(displayedSpelling.uppercased())
                                .font(.system(size: 23, weight: .bold, design: .monospaced))
                                .foregroundColor(.cyan)
                                .tracking(4)
                                .padding()
                                .background(Color.white.opacity(0.15))
                                .cornerRadius(12)
                        }
                    }
                }

                // Letter display during give-up animation
                if viewModel.isSpellingOut {
                    VStack(spacing: 12) {
                        Text("The correct spelling is:")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))

                        // Animated letters
                        HStack(spacing: 4) {
                            ForEach(Array(viewModel.currentSpellingLetters.enumerated()), id: \.offset) { index, letter in
                                Text(letter)
                                    .font(.system(size: 31, weight: .bold, design: .monospaced))
                                    .foregroundColor(.cyan)
                                    .scaleEffect(index <= viewModel.animatedLetterIndex ? 1.0 : 0.5)
                                    .opacity(index <= viewModel.animatedLetterIndex ? 1.0 : 0.3)
                                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: viewModel.animatedLetterIndex)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.15))
                        .cornerRadius(12)
                    }
                }
            }
            .frame(minHeight: 100)  // Reduced minimum height

            Spacer()
                .frame(maxHeight: 20)  // Limited spacer height to move buttons up

            VStack(spacing: 16) {
                // Two-button layout: Repeat + Give Up
                HStack(spacing: 16) {
                    Button {
                        viewModel.repeatWord()
                    } label: {
                        Label("Repeat", systemImage: "speaker.wave.3.fill")
                            .font(.headline)
                            .foregroundColor(.purple)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white.opacity(0.9))
                            .cornerRadius(12)
                    }
                    .disabled(viewModel.isSpellingOut)

                    Button {
                        if isRecording {
                            speechService.stopListening()
                            isRecording = false
                        }
                        viewModel.giveUp()
                    } label: {
                        Label("Give Up", systemImage: "xmark.circle")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange)
                            .cornerRadius(12)
                    }
                    .disabled(viewModel.isSpellingOut)
                }

                // Submit button (show based on mode)
                if (useKeyboard && !keyboardInput.isEmpty) || (!useKeyboard && !displayedSpelling.isEmpty && !isRecording) {
                    Button(action: {
                        print("🔵 ====== SUBMIT BUTTON TAPPED ======")
                        print("🔵 useKeyboard: \(useKeyboard)")
                        print("🔵 keyboardInput: '\(keyboardInput)'")
                        print("🔵 displayedSpelling: '\(displayedSpelling)'")
                        print("🔵 spellingState: \(spellingState)")
                        print("🔵 viewModel.phase: \(viewModel.phase)")
                        print("🔵 Current word: '\(viewModel.currentWord?.text ?? "nil")'")

                        // Stop recording if active
                        if isRecording {
                            speechService.stopListening()
                            isRecording = false
                        }

                        submitSpelling()

                        print("🔵 ====== AFTER SUBMIT ======")
                    }) {
                        HStack {
                            Spacer()
                            Text("Submit")
                                .font(.headline)
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        .foregroundColor(.white)
                        .padding(.vertical, 16)
                        .background(Color.cyan)
                        .cornerRadius(12)
                    }
                    .contentShape(Rectangle())  // Make entire button area tappable
                }
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 60)  // Add space for ad banner at bottom
        }
        .onAppear {
            speechService.recognizedText = ""
            isRecording = false
            useKeyboard = false
            keyboardInput = ""
            spellingState = .waitingForFirstLetter
            displayedSpelling = ""
            textAtTransition = ""
        }
        .onDisappear {
            if isRecording {
                speechService.stopListening()
                isRecording = false
            }
            isKeyboardFocused = false
        }
        .onChange(of: speechService.recognizedText) { newText in
            processSpeechRecognition(newText)
        }
        .onChange(of: viewModel.currentWord?.text) { _ in
            // Reset state when moving to next word
            speechService.recognizedText = ""
            keyboardInput = ""
            isRecording = false
            spellingState = .waitingForFirstLetter
            displayedSpelling = ""
            textAtTransition = ""
            // Don't reset useKeyboard - keep user's preference
        }
    }

    private func toggleInputMode() {
        if isRecording {
            speechService.stopListening()
            isRecording = false
        }

        useKeyboard.toggle()

        if useKeyboard {
            keyboardInput = ""
            speechService.recognizedText = ""
            // Set focus after a small delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isKeyboardFocused = true
            }
        } else {
            isKeyboardFocused = false
            keyboardInput = ""
        }
    }

    private func toggleRecording() {
        if isRecording {
            // User is stopping recording
            let hadRecognizedText = !displayedSpelling.isEmpty
            speechService.stopListening()
            isRecording = false

            // Track cancellation if they stopped without any text
            if !hadRecognizedText {
                viewModel.trackRecordingCancellation()
            }
        } else {
            // Starting fresh recording
            speechService.recognizedText = ""
            displayedSpelling = ""
            spellingState = .waitingForFirstLetter  // Reset state machine
            textAtTransition = ""  // Clear saved transition text
            speechService.startListening()
            isRecording = true
        }
    }

    // MARK: - State Machine Logic

    /// Process speech recognition through state machine
    private func processSpeechRecognition(_ text: String) {
        switch spellingState {
        case .waitingForFirstLetter:
            // Try to extract letters starting from first valid letter
            if let spellingPortion = extractSpellingFromText(text) {
                // Found first letter! Transition to spelling mode
                spellingState = .spellingMode

                // Save the text at transition point (everything BEFORE the first letter)
                // Find where spelling portion starts in the original text
                if let range = text.range(of: spellingPortion, options: [.caseInsensitive, .backwards]) {
                    textAtTransition = String(text[..<range.lowerBound])
                } else {
                    textAtTransition = ""
                }

                let parsed = parseSpelledLetters(spellingPortion)
                displayedSpelling = parsed
                print("✅ First letter detected, switching to spelling mode")
                print("   Original text: '\(text)'")
                print("   Text at transition: '\(textAtTransition)'")
                print("   Spelling portion: '\(spellingPortion)'")
                print("   Parsed: '\(parsed)'")
            } else {
                // Not a valid letter yet, keep waiting silently
                print("⏳ Waiting for first letter, ignoring: '\(text)'")
            }

        case .spellingMode:
            // We're locked in - only process NEW text added after transition
            // Remove the prefix that existed when we transitioned
            var newText = text
            if !textAtTransition.isEmpty && text.hasPrefix(textAtTransition) {
                newText = String(text.dropFirst(textAtTransition.count))
            }

            // Trim any leading whitespace from new text
            newText = newText.trimmingCharacters(in: .whitespaces)

            if !newText.isEmpty {
                let parsed = parseSpelledLetters(newText)
                displayedSpelling = parsed
                print("📝 Spelling mode:")
                print("   Full text: '\(text)'")
                print("   Prefix removed: '\(textAtTransition)'")
                print("   New text only: '\(newText)'")
                print("   Parsed: '\(parsed)'")
            } else {
                print("📝 Spelling mode: No new text yet")
            }
        }
    }

    /// Extract only the spelling portion from text (starting from first valid letter)
    /// Returns nil if no valid letters found
    private func extractSpellingFromText(_ text: String) -> String? {
        let cleaned = text.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let words = cleaned.components(separatedBy: .whitespaces)

        // Phonetic mappings - exact matches
        let phoneticMap: [String: String] = [
            "AY": "A", "EI": "A",
            "BE": "B", "BEE": "B",
            "CE": "C", "SEE": "C", "SEA": "C",
            "DE": "D", "DEE": "D",
            "EE": "E",
            "EF": "F", "EFF": "F",
            "GE": "G", "GEE": "G", "JEE": "G",
            "AITCH": "H", "ETCH": "H", "EITCH": "H",
            "EYE": "I", "AI": "I",
            "JAY": "J", "JA": "J",
            "KAY": "K", "KA": "K", "CAY": "K",
            "EL": "L", "ELL": "L",
            "EM": "M",
            "EN": "N",
            "OH": "O", "OWE": "O",
            "PE": "P", "PEE": "P",
            "CUE": "Q", "QUE": "Q", "QUEUE": "Q",
            "AR": "R", "ARE": "R",
            "ES": "S", "ESS": "S",
            "TE": "T", "TEE": "T",
            "YOU": "U", "YU": "U", "YEW": "U",
            "VE": "V", "VEE": "V",
            "DOUBLE": "W", "DOUBLE-U": "W", "DOUBLEU": "W", "DOUBLEYOU": "W",
            "EX": "X",
            "WHY": "Y", "WI": "Y", "WYE": "Y",
            "ZE": "Z", "ZED": "Z", "ZEE": "Z"
        ]

        // Letter prefixes - words that START with these indicate that letter
        let letterPrefixes: [String: String] = [
            "EX": "E",      // "EXTRA", "EXTRAORDIN" → starts with E
            "EH": "E",      // Alternative pronunciation
            "AR": "R",      // "ART" might be R+T
            "ES": "S",      // "EST" might be S+T
        ]

        // Find the index of the first valid letter
        for (index, word) in words.enumerated() {
            let trimmed = word.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty { continue }

            // Check if it's a single letter (highest priority)
            if trimmed.count == 1, trimmed.first?.isLetter == true {
                let spellingWords = Array(words[index...])
                print("   🔍 Found single letter '\(trimmed)' at index \(index)")
                return spellingWords.joined(separator: " ")
            }

            // Check if it's an exact phonetic match
            if phoneticMap[trimmed] != nil {
                let spellingWords = Array(words[index...])
                print("   🔍 Found phonetic '\(trimmed)' at index \(index)")
                return spellingWords.joined(separator: " ")
            }

            // Check if word STARTS WITH a known letter prefix
            // Only match if word is SHORT (max 8 chars) to avoid matching full words like "EXTRAORDINARY"
            for (prefix, _) in letterPrefixes {
                if trimmed.hasPrefix(prefix) && trimmed.count > prefix.count && trimmed.count <= 8 {
                    // This word starts with a letter sound and is short enough to be a letter
                    let spellingWords = Array(words[index...])
                    print("   🔍 Found prefix '\(prefix)' in '\(trimmed)' (len=\(trimmed.count)) at index \(index)")
                    return spellingWords.joined(separator: " ")
                }
            }
        }

        return nil
    }

    private func submitSpelling() {
        print("🟢 ====== submitSpelling() FUNCTION CALLED ======")

        guard viewModel.currentWord != nil else {
            print("❌ ERROR: No current word!")
            return
        }

        let spelling: String

        if useKeyboard {
            // Keyboard mode - accept input as-is
            spelling = keyboardInput.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            print("🟢 Keyboard mode - raw input: '\(keyboardInput)'")
            print("🟢 Keyboard mode - cleaned spelling: '\(spelling)'")
        } else {
            // Mic mode - use the displayed spelling (already processed by state machine)
            spelling = displayedSpelling.lowercased()
            print("🟢 Mic mode - displayed spelling: '\(displayedSpelling)'")
            print("🟢 Mic mode - final spelling: '\(spelling)'")
        }

        print("🟢 Final spelling to submit: '\(spelling)'")
        print("🟢 Expected word: '\(viewModel.currentWord?.text ?? "nil")'")
        print("🟢 Setting viewModel.userSpelling = '\(spelling)'")

        viewModel.userSpelling = spelling

        print("🟢 Calling viewModel.submitSpelling()...")
        viewModel.submitSpelling()
        print("🟢 Returned from viewModel.submitSpelling()")

        // Clear inputs after submission
        print("🟢 Clearing inputs...")
        keyboardInput = ""
        speechService.recognizedText = ""
        displayedSpelling = ""
        spellingState = .waitingForFirstLetter  // Reset for next word
        textAtTransition = ""  // Clear saved transition text
        print("🟢 ====== submitSpelling() FUNCTION COMPLETE ======")
    }

    private func parseSpelledLetters(_ text: String) -> String {
        let cleaned = text
            .uppercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)

        print("   🔍 parseSpelledLetters input: '\(text)'")
        print("   🔍 cleaned: '\(cleaned)'")

        if cleaned.isEmpty {
            return ""
        }

        let hasSpaces = cleaned.contains(" ") || cleaned.contains(",") || cleaned.contains(".")

        if !hasSpaces {
            print("   🔍 No spaces detected, returning as-is: '\(cleaned.lowercased())'")
            return cleaned.lowercased()
        }

        let separatorCleaned = cleaned
            .replacingOccurrences(of: ",", with: " ")
            .replacingOccurrences(of: ".", with: " ")

        let components = separatorCleaned.components(separatedBy: .whitespaces)

        // Letter prefixes - for when speech recognition outputs partial words
        let letterPrefixes: [String: String] = [
            "EX": "E",      // "EXTRA", "EXTRAORDIN" → E
            "EH": "E",      // Alternative E pronunciation
            "AR": "R",      // "ART" → R
            "ES": "S",      // "EST" → S
        ]

        let letters = components.compactMap { component -> String? in
            let trimmed = component.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty { return nil }

            if trimmed.count == 1 && trimmed.first?.isLetter == true {
                return trimmed
            }

            // Phonetic mappings (exact matches)
            switch trimmed {
            case "AY", "EI": return "A"
            case "BE", "BEE": return "B"
            case "CE", "SEE", "SEA": return "C"
            case "DE", "DEE": return "D"
            case "EE": return "E"
            case "EF", "EFF": return "F"
            case "GE", "GEE", "JEE": return "G"
            case "AITCH", "ETCH", "EITCH": return "H"
            case "EYE", "AI": return "I"
            case "JAY", "JA": return "J"
            case "KAY", "KA", "CAY": return "K"
            case "EL", "ELL": return "L"
            case "EM": return "M"
            case "EN": return "N"
            case "OH", "OWE": return "O"
            case "PE", "PEE": return "P"
            case "CUE", "QUE", "QUEUE": return "Q"
            case "AR", "ARE": return "R"
            case "ES", "ESS": return "S"
            case "TE", "TEE": return "T"
            case "YOU", "YU", "YEW": return "U"
            case "VE", "VEE": return "V"
            case "DOUBLE-U", "DOUBLEU", "DOUBLEYOU", "DOUBLE": return "W"
            case "EX": return "X"
            case "WHY", "WI", "WYE": return "Y"
            case "ZE", "ZED", "ZEE": return "Z"
            default:
                // Check if word starts with a letter prefix (max 8 chars)
                if trimmed.count <= 8 {
                    for (prefix, letter) in letterPrefixes {
                        if trimmed.hasPrefix(prefix) && trimmed.count > prefix.count {
                            print("   🔍 Prefix match in parser: '\(trimmed)' → '\(letter)'")
                            return letter
                        }
                    }
                }
                return nil
            }
        }

        if letters.isEmpty {
            print("   🔍 No letters parsed, returning cleaned: '\(cleaned.lowercased())'")
            return cleaned.lowercased()
        }

        let result = letters.joined().lowercased()
        print("   🔍 Parsed letters: \(letters) → '\(result)'")
        return result
    }
}

// MARK: - Spelling Input View
struct SpellingInputView: View {
    @ObservedObject var viewModel: GameViewModel
    @ObservedObject var speechService = SpeechService.shared
    @State private var isRecording = false
    @State private var pulseAnimation = false
    @State private var useKeyboard = false
    @State private var keyboardInput = ""
    @FocusState private var isKeyboardFocused: Bool
    @State private var hasRecordedInThisAttempt = false

    var body: some View {
        VStack(spacing: 16) {
            // Input mode toggle
            Picker("Input Mode", selection: $useKeyboard) {
                Label("Voice", systemImage: "mic.fill").tag(false)
                Label("Keyboard", systemImage: "keyboard").tag(true)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 30)

            // Show keyboard hint after 2 cancellations in voice mode
            if viewModel.shouldShowKeyboardHint && !useKeyboard {
                VStack(spacing: 12) {
                    Text("Trouble spelling the word? Try keyboard instead.")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                    Button {
                        useKeyboard = true
                        viewModel.hasSeenKeyboardHint = true
                    } label: {
                        Label("Use Keyboard", systemImage: "keyboard")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.cyan)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 30)
                }
            }

            if useKeyboard {
                // Keyboard input mode
                keyboardInputView
            } else {
                // Voice input mode
                voiceInputView
            }

            Spacer()

            // Action buttons
            HStack(spacing: 16) {
                Button {
                    viewModel.repeatWord()
                } label: {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.title2)
                        .foregroundColor(.purple)
                        .frame(width: 60, height: 50)
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(12)
                }

                Button {
                    submitSpelling()
                } label: {
                    Text("Submit")
                        .font(.headline)
                        .foregroundColor(currentInput.isEmpty ? .white.opacity(0.5) : .purple)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(currentInput.isEmpty ? Color.white.opacity(0.2) : Color.cyan)
                        .cornerRadius(12)
                }
                .disabled(currentInput.isEmpty)
            }
            .padding(.horizontal, 30)
        }
        .onAppear {
            // Clear previous recognized text when starting a new word
            speechService.recognizedText = ""
            keyboardInput = ""
            isRecording = false
            hasRecordedInThisAttempt = false

            // Always start with speech recognition mode for each new word
            useKeyboard = false
        }
        .onDisappear {
            if isRecording {
                speechService.stopListening()
            }
        }
    }

    // Current input based on mode
    var currentInput: String {
        useKeyboard ? keyboardInput : parseSpelledLetters(speechService.recognizedText)
    }

    // MARK: - Keyboard Input View
    var keyboardInputView: some View {
        VStack(spacing: 20) {
            Text("Type the spelling")
                .font(.title2)
                .foregroundColor(.white.opacity(0.8))

            TextField("Type here...", text: $keyboardInput)
                .font(.system(size: 28, weight: .medium, design: .monospaced))
                .multilineTextAlignment(.center)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding()
                .background(Color.white.opacity(0.15))
                .foregroundColor(.white)
                .cornerRadius(12)
                .focused($isKeyboardFocused)
                .padding(.horizontal, 30)

            if !keyboardInput.isEmpty {
                Text(keyboardInput.uppercased())
                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                    .foregroundColor(.cyan)
                    .tracking(4)
            }
        }
        .onAppear {
            isKeyboardFocused = true
        }
    }

    // MARK: - Voice Input View
    var voiceInputView: some View {
        VStack(spacing: 20) {
            Text("Spell the word out loud")
                .font(.title2)
                .foregroundColor(.white.opacity(0.8))

            Text("Say each letter: A, B, C...")
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))

            // Microphone button
            Button {
                toggleRecording()
            } label: {
                ZStack {
                    if isRecording {
                        Circle()
                            .fill(Color.red.opacity(0.3))
                            .frame(width: 140, height: 140)
                            .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: pulseAnimation)
                    }

                    Circle()
                        .fill(isRecording ? Color.red : Color.white)
                        .frame(width: 100, height: 100)

                    Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                        .font(.system(size: 40))
                        .foregroundColor(isRecording ? .white : .purple)
                }
            }
            .onChange(of: isRecording) { newValue in
                pulseAnimation = newValue
            }

            Text(isRecording ? "Listening..." : "Tap to speak")
                .font(.headline)
                .foregroundColor(isRecording ? .red : .white)

            if !speechService.recognizedText.isEmpty {
                VStack(spacing: 8) {
                    Text("Heard:")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))

                    Text(parseSpelledLetters(speechService.recognizedText).uppercased())
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                        .foregroundColor(.cyan)
                        .tracking(4)
                        .padding()
                        .background(Color.white.opacity(0.15))
                        .cornerRadius(12)
                }
            }
        }
    }

    // MARK: - Actions

    private func toggleRecording() {
        if isRecording {
            // User is stopping/canceling recording
            speechService.stopListening()
            isRecording = false

            // If user started recording and then canceled, count as retry
            if hasRecordedInThisAttempt && !speechService.recognizedText.isEmpty {
                viewModel.trackRecordingCancellation()
            }
        } else {
            // User is starting recording
            speechService.recognizedText = ""
            speechService.startListening()
            isRecording = true
            hasRecordedInThisAttempt = true
        }
    }

    private func submitSpelling() {
        if isRecording {
            speechService.stopListening()
            isRecording = false
        }

        if useKeyboard {
            viewModel.userSpelling = keyboardInput
        } else {
            viewModel.userSpelling = parseSpelledLetters(speechService.recognizedText)
        }
        viewModel.submitSpelling()
    }

    /// Parses spoken text into the spelled word
    /// Handles: "P E T", "pet", "P. E. T.", "pee ee tee", etc.
    private func parseSpelledLetters(_ text: String) -> String {
        let cleaned = text
            .uppercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // If it's empty, return empty
        if cleaned.isEmpty {
            return ""
        }

        // If it looks like a word with no spaces (e.g., "PET"), just return it as-is
        // This handles when speech recognition combines letters into a word
        let hasSpaces = cleaned.contains(" ") || cleaned.contains(",") || cleaned.contains(".")

        if !hasSpaces {
            // It's a single word like "PET" - return it directly
            return cleaned.lowercased()
        }

        // Otherwise, try to parse individual letters
        let separatorCleaned = cleaned
            .replacingOccurrences(of: ",", with: " ")
            .replacingOccurrences(of: ".", with: " ")

        let components = separatorCleaned.components(separatedBy: .whitespaces)
        let letters = components.compactMap { component -> String? in
            let trimmed = component.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty { return nil }

            // Single letter
            if trimmed.count == 1 && trimmed.first?.isLetter == true {
                return trimmed
            }

            // Handle phonetic letter names
            switch trimmed {
            case "AY", "EI": return "A"
            case "BE", "BEE": return "B"
            case "CE", "SEE", "SEA": return "C"
            case "DE", "DEE": return "D"
            case "EE": return "E"
            case "EF", "EFF": return "F"
            case "GE", "GEE", "JEE": return "G"
            case "AITCH", "ETCH", "EITCH": return "H"
            case "EYE", "AI": return "I"
            case "JAY", "JA": return "J"
            case "KAY", "KA", "CAY": return "K"
            case "EL", "ELL": return "L"
            case "EM": return "M"
            case "EN": return "N"
            case "OH", "OWE": return "O"
            case "PE", "PEE": return "P"
            case "CUE", "QUE", "QUEUE": return "Q"
            case "AR", "ARE": return "R"
            case "ES", "ESS": return "S"
            case "TE", "TEE": return "T"
            case "YOU", "YU", "YEW": return "U"
            case "VE", "VEE": return "V"
            case "DOUBLE-U", "DOUBLEU", "DOUBLEYOU", "DOUBLE": return "W"
            case "EX": return "X"
            case "WHY", "WI", "WYE": return "Y"
            case "ZE", "ZED", "ZEE": return "Z"
            default:
                // If it's a short word, might be a letter name we don't recognize
                // Return nil to skip it
                return nil
            }
        }

        // If we got letters, join them; otherwise return the original cleaned text
        if letters.isEmpty {
            return cleaned.lowercased()
        }

        return letters.joined().lowercased()
    }
}

struct GameView_Previews: PreviewProvider {
    static var previews: some View {
        GameView(level: 1)
            .environmentObject(AppState())
    }
}
