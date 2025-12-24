//
//  SpeechService.swift
//  spelling-bee Watch App
//
//  Handles text-to-speech using AVSpeechSynthesizer.
//  Note: Speech recognition (Speech framework) is not available on watchOS.
//  User input is handled via SwiftUI's native dictation in TextField.
//

import Foundation
import AVFoundation

// Available voice options
struct VoiceOption: Identifiable, Equatable, Hashable {
    let id: String
    let name: String
    let language: String

    static let defaultVoice = VoiceOption(id: "com.apple.ttsbundle.Samantha-compact", name: "Samantha", language: "en-US")
}

@MainActor
class SpeechService: NSObject, ObservableObject {
    static let shared = SpeechService()

    // MARK: - Published State
    @Published var isSpeaking = false
    @Published var selectedVoice: VoiceOption = VoiceOption.defaultVoice {
        didSet {
            // Save to UserDefaults
            UserDefaults.standard.set(selectedVoice.id, forKey: "selectedVoiceId")
        }
    }
    @Published var availableVoices: [VoiceOption] = []

    // MARK: - Private Properties
    private let synthesizer = AVSpeechSynthesizer()

    // MARK: - Initialization
    override init() {
        super.init()
        synthesizer.delegate = self
        loadAvailableVoices()
        loadSavedVoice()
    }

    // MARK: - Voice Management

    private func loadAvailableVoices() {
        let voices = AVSpeechSynthesisVoice.speechVoices()

        // Premium/Enhanced voices that sound warm and natural (great for kids)
        let premiumVoices: Set<String> = [
            "ava", "zoe", "evan", "tom", "nicky", "reed", "rocko", "sandy",
            "grandma", "grandpa", "joelle", "jamie", "aaron", "liam"
        ]

        // Good quality standard voices as fallback
        let standardVoices: Set<String> = [
            "samantha", "alex", "victoria", "daniel", "moira", "tessa"
        ]

        // Fun novelty voices (optional, kids might like these)
        let noveltyVoices: Set<String> = [
            "superstar", "flo", "eddy", "grandma", "grandpa"
        ]

        let allowedVoices = premiumVoices.union(standardVoices).union(noveltyVoices)

        // Filter to allowed English voices and create options
        // Prefer premium quality voices
        availableVoices = voices
            .filter { $0.language.starts(with: "en") }
            .filter { allowedVoices.contains($0.name.lowercased()) }
            .map { voice in
                let displayName = voice.name
                return VoiceOption(id: voice.identifier, name: displayName, language: voice.language)
            }
            .sorted { v1, v2 in
                // Sort premium voices first, then by name
                let v1Premium = premiumVoices.contains(v1.name.lowercased())
                let v2Premium = premiumVoices.contains(v2.name.lowercased())
                if v1Premium && !v2Premium { return true }
                if !v1Premium && v2Premium { return false }
                return v1.name < v2.name
            }

        // Remove duplicates by name (keep first occurrence which is premium)
        var seen = Set<String>()
        availableVoices = availableVoices.filter { voice in
            if seen.contains(voice.name) {
                return false
            }
            seen.insert(voice.name)
            return true
        }

        // If no voices found, add a default
        if availableVoices.isEmpty {
            availableVoices = [VoiceOption.defaultVoice]
        }
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

    func previewVoiceWithWord(_ voice: VoiceOption, word: String?) {
        stopSpeaking()
        let text = word ?? "Hello, I am \(voice.name)"
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.9
        if let avVoice = AVSpeechSynthesisVoice(identifier: voice.id) {
            utterance.voice = avVoice
        }
        isSpeaking = true
        synthesizer.speak(utterance)
    }

    // MARK: - Text-to-Speech

    private func getSelectedAVVoice() -> AVSpeechSynthesisVoice? {
        if let voice = AVSpeechSynthesisVoice(identifier: selectedVoice.id) {
            return voice
        }
        return AVSpeechSynthesisVoice(language: "en-US")
    }

    /// Speaks a word clearly for spelling practice with a 1 second delay
    func speakWord(_ word: String) {
        stopSpeaking()
        isSpeaking = true

        // Add 1 second delay before speaking the word
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

    /// Spells out a word letter by letter
    func spellWord(_ word: String) {
        stopSpeaking()

        let letters = word.uppercased().map { String($0) }.joined(separator: ", ")
        let utterance = AVSpeechUtterance(string: letters)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.6 // Slower for letter spelling
        utterance.pitchMultiplier = 1.0
        utterance.voice = getSelectedAVVoice()

        isSpeaking = true
        synthesizer.speak(utterance)
    }

    /// Speaks feedback messages
    func speakFeedback(_ message: String) {
        stopSpeaking()

        let utterance = AVSpeechUtterance(string: message)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        utterance.pitchMultiplier = 1.1 // Slightly higher pitch for encouragement
        utterance.voice = getSelectedAVVoice()

        isSpeaking = true
        synthesizer.speak(utterance)
    }

    func stopSpeaking() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        isSpeaking = false
    }
}

// MARK: - AVSpeechSynthesizerDelegate
extension SpeechService: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
        }
    }
}

// MARK: - Spelling Validation Helper
extension SpeechService {
    /// Validates user's typed/dictated spelling against the correct word
    /// Handles common variations and normalizes input
    static func validateSpelling(userInput: String, correctWord: String) -> Bool {
        // Normalize both strings
        let normalizedInput = userInput
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")

        let normalizedCorrect = correctWord.lowercased()

        return normalizedInput == normalizedCorrect
    }
}
