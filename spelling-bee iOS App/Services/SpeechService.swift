//
//  SpeechService.swift
//  spelling-bee iOS App
//
//  Handles text-to-speech and speech recognition on iOS.
//

import Foundation
import AVFoundation
import Speech

// Available voice options
struct VoiceOption: Identifiable, Equatable, Hashable {
    let id: String
    let name: String
    let language: String

    static let lisaAI = VoiceOption(
        id: "com.spellflare.lisa-ai",
        name: "Lisa (AI)",
        language: "en-US"
    )

    static let defaultVoice = lisaAI
}

@MainActor
class SpeechService: NSObject, ObservableObject {
    static let shared = SpeechService()

    // MARK: - Published State
    @Published var isSpeaking = false
    @Published var isListening = false
    @Published var recognizedText = ""
    @Published var speechAuthorizationStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined
    @Published var selectedVoice: VoiceOption = VoiceOption.defaultVoice {
        didSet {
            // Save to UserDefaults
            UserDefaults.standard.set(selectedVoice.id, forKey: "selectedVoiceId")
        }
    }
    @Published var availableVoices: [VoiceOption] = []

    // MARK: - Private Properties
    private let synthesizer = AVSpeechSynthesizer()
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private let audioService = AudioPlaybackService.shared
    private var currentDifficulty: Int = 1
    private var speechCompletionHandler: (() -> Void)?

    // MARK: - Initialization
    override init() {
        super.init()
        synthesizer.delegate = self
        requestSpeechAuthorization()
        loadAvailableVoices()
        loadSavedVoice()
    }

    // MARK: - Voice Management

    private func loadAvailableVoices() {
        // Only Lisa (AI) voice is available
        availableVoices = [VoiceOption.lisaAI]
    }

    private func loadSavedVoice() {
        if let savedId = UserDefaults.standard.string(forKey: "selectedVoiceId"),
           let voice = availableVoices.first(where: { $0.id == savedId }) {
            selectedVoice = voice
        } else if let firstVoice = availableVoices.first {
            selectedVoice = firstVoice
        }
    }

    func previewVoice(_ voice: VoiceOption) {
        previewVoiceWithWord(voice, word: nil)
    }

    func previewVoiceWithWord(_ voice: VoiceOption, word: String?, difficulty: Int? = nil) {
        stopSpeaking()
        let text = word ?? "Hello, I am \(voice.name)"

        if voice.id == "com.spellflare.lisa-ai" {
            audioService.setVoice("Lisa")
            isSpeaking = true
            if let word = word {
                let wordDifficulty = difficulty ?? currentDifficulty
                audioService.playWord(word, difficulty: wordDifficulty) {
                    self.isSpeaking = false
                }
            } else {
                // Speak the hello message with system voice for preview
                let utterance = AVSpeechUtterance(string: text)
                utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.9
                if let avVoice = AVSpeechSynthesisVoice(identifier: "com.apple.ttsbundle.Samantha-compact") {
                    utterance.voice = avVoice
                }
                isSpeaking = true
                synthesizer.speak(utterance)
            }
        } else {
            // Existing code for system voices
            let utterance = AVSpeechUtterance(string: text)
            utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.9
            if let avVoice = AVSpeechSynthesisVoice(identifier: voice.id) {
                utterance.voice = avVoice
            }
            isSpeaking = true
            synthesizer.speak(utterance)
        }
    }

    func setDifficulty(_ difficulty: Int) {
        currentDifficulty = difficulty
    }

    // MARK: - Authorization
    func requestSpeechAuthorization() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            Task { @MainActor in
                self?.speechAuthorizationStatus = status
            }
        }
    }

    // MARK: - Text-to-Speech

    private func getSelectedAVVoice() -> AVSpeechSynthesisVoice? {
        if let voice = AVSpeechSynthesisVoice(identifier: selectedVoice.id) {
            return voice
        }
        return AVSpeechSynthesisVoice(language: "en-US")
    }

    func speakWord(_ word: String, difficulty: Int? = nil) {
        stopSpeaking()

        // Use provided difficulty or fall back to currentDifficulty
        let wordDifficulty = difficulty ?? currentDifficulty

        // Check if Lisa(AI) is selected
        if selectedVoice.id == "com.spellflare.lisa-ai" {
            // Set the voice in AudioPlaybackService
            audioService.setVoice("Lisa")

            // Use pre-generated audio
            isSpeaking = true
            Task {
                try? await Task.sleep(nanoseconds: 1_000_000_000)  // Keep 1s delay
                await MainActor.run {
                    audioService.playWord(word, difficulty: wordDifficulty) {
                        self.isSpeaking = false
                    }
                }
            }
        } else {
            // Use AVSpeechSynthesizer (existing code)
            isSpeaking = true
            Task {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                await MainActor.run {
                    let utterance = AVSpeechUtterance(string: word)
                    utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.9 // 90% of original speed
                    utterance.pitchMultiplier = 1.0
                    utterance.voice = self.getSelectedAVVoice()
                    self.synthesizer.speak(utterance)
                }
            }
        }
    }

    func spellWord(_ word: String, difficulty: Int? = nil, completion: (() -> Void)? = nil) {
        stopSpeaking()

        // Use provided difficulty or fall back to currentDifficulty
        let wordDifficulty = difficulty ?? currentDifficulty

        if selectedVoice.id == "com.spellflare.lisa-ai" {
            audioService.setVoice("Lisa")
            isSpeaking = true
            audioService.playSpelling(word, difficulty: wordDifficulty) {
                self.isSpeaking = false
                completion?()
            }
        } else {
            // Existing AVSpeechSynthesizer code
            let letters = word.uppercased().map { String($0) }.joined(separator: ", ")
            let utterance = AVSpeechUtterance(string: letters)
            utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.6
            utterance.pitchMultiplier = 1.0
            utterance.voice = getSelectedAVVoice()

            // Store completion handler for delegate to call
            speechCompletionHandler = completion
            isSpeaking = true
            synthesizer.speak(utterance)
        }
    }

    func speakFeedback(_ message: String, completion: (() -> Void)? = nil) {
        stopSpeaking()

        if selectedVoice.id == "com.spellflare.lisa-ai" {
            audioService.setVoice("Lisa")
            isSpeaking = true
            audioService.playFeedback(message) {
                self.isSpeaking = false
                completion?()
            }
        } else {
            // Existing AVSpeechSynthesizer code
            let utterance = AVSpeechUtterance(string: message)
            utterance.rate = AVSpeechUtteranceDefaultSpeechRate
            utterance.pitchMultiplier = 1.1
            utterance.voice = getSelectedAVVoice()

            // Store completion handler for delegate to call
            speechCompletionHandler = completion
            isSpeaking = true
            synthesizer.speak(utterance)
        }
    }

    func stopSpeaking() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        audioService.stop()  // Also stop audio playback
        isSpeaking = false
        speechCompletionHandler = nil  // Clear any pending completion
    }

    // MARK: - Speech Recognition

    func startListening() {
        guard speechAuthorizationStatus == .authorized else {
            print("Speech recognition not authorized")
            return
        }

        // Stop speaking first - critical for real devices
        stopSpeaking()

        // Stop any existing listening session
        if isListening || audioEngine.isRunning {
            stopListeningInternal()
        }

        // Cancel any ongoing recognition task
        recognitionTask?.cancel()
        recognitionTask = nil

        recognizedText = ""

        // Pre-configure audio session before the delay
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: [])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Audio session pre-config failed: \(error)")
        }

        // Longer delay to ensure audio session is fully ready and avoid missing first letter
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.startRecognitionSession()
        }
    }

    /// Internal cleanup without resetting audio session (for use when starting new session)
    private func stopListeningInternal() {
        // Stop audio engine first
        if audioEngine.isRunning {
            audioEngine.stop()
        }

        // Remove any existing tap
        audioEngine.inputNode.removeTap(onBus: 0)

        // End and clear recognition request
        recognitionRequest?.endAudio()
        recognitionRequest = nil

        // Cancel and clear recognition task
        recognitionTask?.cancel()
        recognitionTask = nil

        isListening = false
    }

    private func startRecognitionSession() {
        // Audio session should already be configured from startListening()
        // but ensure it's set correctly
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: [])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Audio session setup failed: \(error)")
            return
        }

        // Configure audio engine first
        let inputNode = audioEngine.inputNode

        // Ensure any existing tap is removed (defensive, safe to call even if no tap exists)
        inputNode.removeTap(onBus: 0)

        // Get the native format of the input node
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        // Check if format is valid
        guard recordingFormat.sampleRate > 0 else {
            print("Invalid audio format - sample rate is 0")
            return
        }

        // Start audio engine FIRST to warm up the buffer before recognition starts
        audioEngine.prepare()
        do {
            try audioEngine.start()
            isListening = true
            print("Audio engine started - warming up buffer")
        } catch {
            print("Audio engine start failed: \(error)")
            return
        }

        // Small delay to let audio buffer warm up before starting recognition
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            guard let self = self, self.isListening else { return }

            // Create recognition request
            self.recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            guard let recognitionRequest = self.recognitionRequest else {
                print("Failed to create recognition request")
                self.stopListeningInternal()
                return
            }

            recognitionRequest.shouldReportPartialResults = true

            // Use on-device recognition if available (iOS 13+)
            if #available(iOS 13, *) {
                recognitionRequest.requiresOnDeviceRecognition = false
            }

            // Install tap on input node with buffer for responsive updates
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
                self?.recognitionRequest?.append(buffer)
            }

            // Start recognition task
            self.recognitionTask = self.speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
                Task { @MainActor in
                    guard let self = self else { return }

                    if let result = result {
                        let text = result.bestTranscription.formattedString
                        // Only update if we have text - don't clear with empty results
                        if !text.isEmpty {
                            self.recognizedText = text
                            print("Recognized: \(text)")
                        }
                    }

                    // Only stop on final result
                    if result?.isFinal == true {
                        print("Final result received")
                        // Don't call stopListening here - let user control when to stop
                    }

                    if let error = error as NSError? {
                        // Error code 1110 = no speech detected, 216 = request cancelled - these are normal
                        if error.code != 1110 && error.code != 216 {
                            print("Recognition error: \(error.localizedDescription) (code: \(error.code))")
                        }
                    }
                }
            }

            print("Speech recognition started successfully")
        }
    }

    func stopListening() {
        guard isListening || audioEngine.isRunning else { return }

        // Use the internal cleanup method
        stopListeningInternal()

        // Reset audio session for playback
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try? AVAudioSession.sharedInstance().setActive(true)
        }

        print("Speech recognition stopped")
    }
}

// MARK: - AVSpeechSynthesizerDelegate
extension SpeechService: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
            self.speechCompletionHandler?()
            self.speechCompletionHandler = nil
        }
    }
}

// MARK: - Spelling Validation
extension SpeechService {
    static func validateSpelling(userInput: String, correctWord: String) -> Bool {
        let normalizedInput = userInput
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")

        let normalizedCorrect = correctWord.lowercased()

        return normalizedInput == normalizedCorrect
    }
}
