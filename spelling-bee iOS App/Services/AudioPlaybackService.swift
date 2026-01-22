import AVFoundation

@MainActor
class AudioPlaybackService: NSObject, ObservableObject, AVAudioPlayerDelegate {
    static let shared = AudioPlaybackService()

    @Published var isPlaying = false
    private var audioPlayer: AVAudioPlayer?
    private var completionHandler: (() -> Void)?
    private var currentVoice: String = "Lisa"  // Default voice

    private override init() {
        super.init()
    }

    // MARK: - Public Methods

    /// Set the current AI voice to use
    func setVoice(_ voiceName: String) {
        currentVoice = voiceName
    }

    /// Play word pronunciation
    func playWord(_ word: String, difficulty: Int, completion: (() -> Void)? = nil) {
        let path = "Audio/\(currentVoice)/words/difficulty_\(difficulty)/\(word.lowercased())"
        playAudioFile(path, completion: completion)
    }

    /// Play letter-by-letter spelling
    func playSpelling(_ word: String, difficulty: Int, completion: (() -> Void)? = nil) {
        let path = "Audio/\(currentVoice)/spelling/difficulty_\(difficulty)/\(word.lowercased())_spelled"
        playAudioFile(path, completion: completion)
    }

    /// Play single letter
    func playLetter(_ letter: String, completion: (() -> Void)? = nil) {
        let path = "Audio/\(currentVoice)/letters/\(letter.lowercased())"
        playAudioFile(path, completion: completion)
    }

    /// Play feedback message
    func playFeedback(_ message: String, completion: (() -> Void)? = nil) {
        let filename = mapFeedbackToFile(message)
        let path = "Audio/\(currentVoice)/feedback/\(filename)"
        playAudioFile(path, completion: completion)
    }

    /// Play sentence audio
    func playSentence(_ word: String, difficulty: Int, sentenceNumber: Int, completion: (() -> Void)? = nil) {
        let path = "Audio/\(currentVoice)/sentences/difficulty_\(difficulty)/\(word.lowercased())_sentence\(sentenceNumber)"
        playAudioFile(path, completion: completion)
    }

    /// Stop current playback
    func stop() {
        audioPlayer?.stop()
        isPlaying = false
        completionHandler = nil
    }

    // MARK: - Private Methods

    private func playAudioFile(_ resourcePath: String, completion: (() -> Void)?) {
        // Split path into subdirectory and filename
        let components = resourcePath.split(separator: "/")
        let filename = String(components.last ?? "")
        let subdirectory = components.dropLast().joined(separator: "/")

        // Try to load audio file from bundle (try both WAV and MP3)
        var url: URL?
        if subdirectory.isEmpty {
            url = Bundle.main.url(forResource: filename, withExtension: "wav")
            if url == nil {
                url = Bundle.main.url(forResource: filename, withExtension: "mp3")
            }
        } else {
            url = Bundle.main.url(forResource: filename, withExtension: "wav", subdirectory: subdirectory)
            if url == nil {
                url = Bundle.main.url(forResource: filename, withExtension: "mp3", subdirectory: subdirectory)
            }
        }

        guard let audioURL = url else {
            completion?()
            return
        }

        do {
            // Configure audio session for playback
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)

            // Create and configure audio player
            audioPlayer = try AVAudioPlayer(contentsOf: audioURL)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()

            // Store completion handler
            completionHandler = completion

            // Start playback
            audioPlayer?.play()
            isPlaying = true
        } catch {
            completion?()
        }
    }

    private func mapFeedbackToFile(_ message: String) -> String {
        let normalized = message.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        // Success messages
        if normalized.contains("great job") { return "success/great_job" }
        if normalized.contains("excellent") { return "success/excellent" }
        if normalized.contains("you got it") { return "success/you_got_it" }
        if normalized.contains("perfect") { return "success/perfect" }
        if normalized.contains("amazing") { return "success/amazing" }
        if normalized.contains("wonderful") { return "success/wonderful" }

        // Encouragement messages
        if normalized.contains("nice try") { return "encouragement/nice_try" }
        if normalized.contains("almost there") { return "encouragement/almost_there" }
        if normalized.contains("keep trying") { return "encouragement/keep_trying" }
        if normalized.contains("don't give up") || normalized.contains("dont give up") {
            return "encouragement/dont_give_up"
        }

        // System messages
        if normalized.contains("correct spelling") { return "system/correct_spelling_is" }
        if normalized.contains("completed the level") { return "system/level_complete" }

        // Default fallback
        return "success/great_job"
    }

    // MARK: - AVAudioPlayerDelegate

    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            self.isPlaying = false
            self.completionHandler?()
            self.completionHandler = nil
        }
    }
}
