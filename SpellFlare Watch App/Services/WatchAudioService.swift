//
//  WatchAudioService.swift
//  SpellFlare Watch App
//
//  Audio playback service for watchOS using AVAudioPlayer with TTS fallback.
//

import Foundation
import AVFoundation
import WatchKit

// MARK: - Feedback Types
enum WatchFeedbackAudioType {
    case correct
    case incorrect
    case levelComplete

    var folder: String {
        switch self {
        case .correct: return "success"
        case .incorrect: return "encouragement"
        case .levelComplete: return "system"
        }
    }

    var files: [String] {
        switch self {
        case .correct:
            return ["great_job", "excellent", "perfect", "amazing", "wonderful", "you_got_it"]
        case .incorrect:
            return ["nice_try", "keep_trying", "almost_there", "dont_give_up"]
        case .levelComplete:
            return ["level_complete"]
        }
    }

    var randomFile: String {
        files.randomElement() ?? files[0]
    }
}

@MainActor
class WatchAudioService: ObservableObject {
    static let shared = WatchAudioService()

    @Published var isPlaying = false

    private var player: AVAudioPlayer?
    private var completionHandler: (() -> Void)?
    private let synthesizer = AVSpeechSynthesizer()

    // MARK: - Initialization
    init() {
        configureAudioSession()
    }

    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)
        } catch {
            print("Audio session configuration failed: \(error)")
        }
    }

    // MARK: - Word Playback
    func playWord(_ word: String, difficulty: Int, completion: (() -> Void)? = nil) {
        let path = "Audio/Lisa/words/difficulty_\(difficulty)/\(word.lowercased())"
        play(path: path, fallbackText: word, completion: completion)
    }

    // MARK: - Spelling Playback
    func playSpelling(_ word: String, difficulty: Int, completion: (() -> Void)? = nil) {
        let path = "Audio/Lisa/spelling/difficulty_\(difficulty)/\(word.lowercased())_spelled"
        // Spell out the word letter by letter for TTS fallback
        let spelled = word.map { String($0) }.joined(separator: ", ")
        play(path: path, fallbackText: spelled, completion: completion)
    }

    // MARK: - Letter Playback
    func playLetter(_ letter: String, completion: (() -> Void)? = nil) {
        // Watch app has letters at Audio/letters/ (no Lisa subdirectory)
        let path = "Audio/letters/\(letter.lowercased())"
        play(path: path, fallbackText: letter, completion: completion)
    }

    // MARK: - Sentence Playback
    func playSentence(_ word: String, difficulty: Int, number: Int, completion: (() -> Void)? = nil) {
        let path = "Audio/Lisa/sentences/difficulty_\(difficulty)/\(word.lowercased())_sentence\(number)"
        play(path: path, fallbackText: nil, completion: completion)
    }

    // MARK: - Feedback Playback
    func playFeedback(_ type: WatchFeedbackAudioType, completion: (() -> Void)? = nil) {
        let file = type.randomFile
        // Watch app has feedback at Audio/feedback/ (no Lisa subdirectory)
        let path = "Audio/feedback/\(type.folder)/\(file)"
        // Generate TTS fallback text from file name
        let fallback = file.replacingOccurrences(of: "_", with: " ")
        play(path: path, fallbackText: fallback, completion: completion)
    }

    // MARK: - Core Playback
    private func play(path: String, fallbackText: String? = nil, completion: (() -> Void)?) {
        stop()

        // Try .wav first, then .mp3
        guard let url = findAudioFile(path: path) else {
            print("Audio not found: \(path), using TTS fallback")
            // Use TTS as fallback if we have text
            if let text = fallbackText {
                speakWithTTS(text: text, completion: completion)
            } else {
                // No fallback text, just play haptic
                WKInterfaceDevice.current().play(.notification)
                completion?()
            }
            return
        }

        do {
            // Re-configure audio session before playback
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)

            player = try AVAudioPlayer(contentsOf: url)
            player?.prepareToPlay()

            completionHandler = completion
            isPlaying = true

            player?.play()

            // Schedule completion callback
            if let duration = player?.duration {
                DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.1) { [weak self] in
                    self?.handlePlaybackComplete()
                }
            }

        } catch {
            print("Playback error: \(error)")
            // Try TTS fallback on error
            if let text = fallbackText {
                speakWithTTS(text: text, completion: completion)
            } else {
                WKInterfaceDevice.current().play(.notification)
                completion?()
            }
        }
    }

    // MARK: - Text-to-Speech Fallback
    private func speakWithTTS(text: String, completion: (() -> Void)?) {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)
        } catch {
            print("TTS audio session error: \(error)")
        }

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.9
        utterance.pitchMultiplier = 1.0

        completionHandler = completion
        isPlaying = true

        synthesizer.speak(utterance)

        // Estimate duration and schedule completion
        let estimatedDuration = Double(text.count) * 0.08 + 0.5
        DispatchQueue.main.asyncAfter(deadline: .now() + estimatedDuration) { [weak self] in
            self?.handlePlaybackComplete()
        }
    }

    private func findAudioFile(path: String) -> URL? {
        // Split path into subdirectory and filename
        let components = path.split(separator: "/")
        let filename = String(components.last ?? "")
        let subdirectory = components.dropLast().joined(separator: "/")

        // Try .wav first, then .mp3
        if subdirectory.isEmpty {
            if let url = Bundle.main.url(forResource: filename, withExtension: "wav") {
                return url
            }
            if let url = Bundle.main.url(forResource: filename, withExtension: "mp3") {
                return url
            }
        } else {
            if let url = Bundle.main.url(forResource: filename, withExtension: "wav", subdirectory: subdirectory) {
                return url
            }
            if let url = Bundle.main.url(forResource: filename, withExtension: "mp3", subdirectory: subdirectory) {
                return url
            }
        }
        return nil
    }

    private func handlePlaybackComplete() {
        isPlaying = false
        let handler = completionHandler
        completionHandler = nil
        handler?()
    }

    // MARK: - Stop
    func stop() {
        player?.stop()
        player = nil
        synthesizer.stopSpeaking(at: .immediate)
        isPlaying = false
        completionHandler = nil
    }

    // MARK: - Haptic Feedback
    func playHaptic(_ type: WKHapticType) {
        WKInterfaceDevice.current().play(type)
    }

    func playSuccessHaptic() {
        WKInterfaceDevice.current().play(.success)
    }

    func playFailureHaptic() {
        WKInterfaceDevice.current().play(.failure)
    }
}
